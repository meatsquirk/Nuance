import 'dart:async';

import 'package:color_models/color_models.dart';

import '../../domain/color_coordinates.dart';
import 'capture_source.dart';
import 'frame.dart';

/// Number of frames the generated live feed emits before it terminates.
///
/// Tied to [kStabilityFrameTarget] so the feed carries enough frames for the
/// multi-frame commit to average over (AC-11); a finite count so a test's
/// `pumpAndSettle` drains the feed and returns rather than hanging.
const int _kGeneratedFrameCount = kStabilityFrameTarget;

/// Side length (px) of a generated feed frame — large enough that the default
/// and widest sampling discs (up to 21 px radius) fit around the centre.
const int _kGeneratedFrameSize = 64;

/// A deterministic description of what a [SoftwareCaptureSource] is looking at.
///
/// Tests (and the non-native default source) build a source from one of these:
/// the [groundTruth] colour the scene really is, its [lighting], whether the
/// camera [canLock], whether a reference card is in view, optional per-frame
/// [noise], and an optional explicit [frames] list to replay. When [frames] is
/// null the source generates a live feed from [groundTruth] + [noise]
/// (SOURCE-2).
class SceneSpec {
  const SceneSpec({
    required this.groundTruth,
    this.lighting = Lighting.adequate,
    this.canLock = true,
    this.referenceCardPresent = false,
    this.noise = 0.0,
    this.frames,
  });

  /// The canonical CIELAB colour the scene actually is (ΔE is measured to this).
  final ColorCoordinates groundTruth;

  /// How well lit the scene is.
  final Lighting lighting;

  /// Whether this source supports locking exposure / white balance / focus.
  /// Held for SOURCE-2 / CAPTURE-3; the shell's lock controls record the lock
  /// regardless.
  final bool canLock;

  /// Whether a reference card is present in the frame.
  final bool referenceCardPresent;

  /// Per-frame noise amplitude for the generated feed (SOURCE-2): the frames
  /// vary within ±[noise] of the ground-truth sRGB channels, averaging back to
  /// it over the feed.
  final double noise;

  /// An explicit frame list to replay, or null to use a feed generated from
  /// [groundTruth] + [noise] (SOURCE-2).
  final List<Frame>? frames;
}

/// The deterministic, non-native [CaptureSource] bs-02 ships, built from a
/// [SceneSpec].
///
/// It exposes the scene's lighting and reference-card presence, records lock
/// requests, and yields the live feed: the scene's explicit frames, or a feed
/// generated from the ground-truth colour (with [SceneSpec.noise]) when none are
/// given (SOURCE-2). The stability signal remains the SOURCE-1 placeholder —
/// the real settling signal lands with the lock/settle behaviour in CAPTURE-3.
class SoftwareCaptureSource implements CaptureSource {
  SoftwareCaptureSource(this.scene);

  /// The scene this source renders.
  final SceneSpec scene;

  CaptureLocks _locks = const CaptureLocks();

  @override
  Stream<Frame> get frames => Stream<Frame>.fromIterable(_feed());

  /// The live feed: the scene's explicit frames when it carries them, otherwise
  /// a feed generated from [SceneSpec.groundTruth] and [SceneSpec.noise].
  List<Frame> _feed() => scene.frames ?? _generatedFeed();

  /// Generates [_kGeneratedFrameCount] frames from the scene's ground truth.
  ///
  /// With no noise every frame is the ground-truth colour; with noise the frames
  /// vary by a symmetric per-frame offset whose mean over the feed is exactly the
  /// ground truth, so [averageFrames] over the feed recovers it (AC-11).
  List<Frame> _generatedFeed() {
    final truth = LabColor(
      scene.groundTruth.lightness,
      scene.groundTruth.a,
      scene.groundTruth.b,
    ).toRgbColor();
    final baseR = truth.red;
    final baseG = truth.green;
    final baseB = truth.blue;
    const n = _kGeneratedFrameCount;
    return List<Frame>.generate(n, (i) {
      // Antisymmetric offset in [-noise, +noise]: offsets for frame i and
      // (n-1-i) are exact negatives, so the per-pixel mean over the feed is the
      // ground-truth colour.
      final offset = (scene.noise * (2 * i - (n - 1)) / (n - 1)).round();
      final pixel = Pixel(
        (baseR + offset).clamp(0, 255),
        (baseG + offset).clamp(0, 255),
        (baseB + offset).clamp(0, 255),
      );
      return Frame(
        width: _kGeneratedFrameSize,
        height: _kGeneratedFrameSize,
        pixels: List<Pixel>.filled(
          _kGeneratedFrameSize * _kGeneratedFrameSize,
          pixel,
        ),
      );
    });
  }

  @override
  CaptureLocks get locks => _locks;

  @override
  Stream<StabilityReading> get stability =>
      Stream<StabilityReading>.empty();

  @override
  Lighting get lighting => scene.lighting;

  @override
  bool get referenceCardPresent => scene.referenceCardPresent;

  @override
  ColorCoordinates normaliseAgainstCard(ColorCoordinates raw) {
    // Deterministic source: the reference card under controlled lighting
    // recovers the scene's true colour, so normalising removes the whole
    // camera drift and the corrected reading is the ground truth (ΔE00 0, well
    // inside the calibrated tier's ΔE00 3). A native source instead derives a
    // real colour-correction transform from the card's patches and applies it
    // to [raw]; this build ships only the software source.
    return scene.groundTruth;
  }

  ImportedPhoto? _importedPhoto;

  @override
  ImportedPhoto? get importedPhoto => _importedPhoto;

  @override
  void importPhoto(ImportedPhoto photo) => _importedPhoto = photo;

  @override
  void lockExposure() => _locks = _locks.copyWith(exposure: true);

  @override
  void lockWhiteBalance() => _locks = _locks.copyWith(whiteBalance: true);

  @override
  void lockFocus() => _locks = _locks.copyWith(focus: true);
}
