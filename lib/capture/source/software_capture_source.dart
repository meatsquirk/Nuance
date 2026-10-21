import 'dart:async';

import 'package:color_models/color_models.dart';

import '../../domain/color_coordinates.dart';
import 'capture_source.dart';
import 'frame.dart';
import 'sampling.dart';

/// Number of frames the generated live feed emits before it terminates.
///
/// Tied to [kStabilityFrameTarget] so the feed carries enough frames for the
/// multi-frame commit to average over (AC-11); a finite count so a test's
/// `pumpAndSettle` drains the feed and returns rather than hanging.
const int _kGeneratedFrameCount = kStabilityFrameTarget;

/// Side length (px) of a generated feed frame — large enough that the default
/// and widest sampling discs (up to 21 px radius) fit around the centre.
const int _kGeneratedFrameSize = 64;

/// Which platform's capture pipeline a [SceneSpec] models (plan D-7).
///
/// Two configs (Android / iOS) can carry different pre-normalization raw yet
/// the same ground truth, so AC-10 can assert the committed sample is
/// platform-agnostic. The shell only names the knob; SOURCE-4 drives the
/// platform-specific raw offset through [SceneSpec.rawColorShift].
enum CapturePlatform {
  /// The Android (CameraX) pipeline.
  android,

  /// The iOS (AVFoundation) pipeline.
  ios,
}

/// A deterministic description of what a [SoftwareCaptureSource] is looking at.
///
/// Tests (and the non-native default source) build a source from one of these:
/// the [groundTruth] colour the scene really is, its [lighting], whether the
/// camera [canLock], whether a reference card is in view, optional per-frame
/// [noise], and an optional explicit [frames] list to replay. When [frames] is
/// null the source generates a live feed from [groundTruth] + [noise]
/// (SOURCE-2). The remaining knobs ([torchAvailable], [torchColorShift],
/// [supportsWideGamut], [supportsRaw], [platform], [rawColorShift]) configure
/// the bs-09 capabilities and default off so the existing bs-02..bs-06 scenes
/// are unaffected; the behaviour they drive lands in SOURCE-2/3/4 and
/// CAPTURE-3.
class SceneSpec {
  const SceneSpec({
    required this.groundTruth,
    this.lighting = Lighting.adequate,
    this.canLock = true,
    this.referenceCardPresent = false,
    this.noise = 0.0,
    this.frames,
    this.torchAvailable = false,
    this.torchColorShift = 0.0,
    this.supportsWideGamut = false,
    this.supportsRaw = false,
    this.platform = CapturePlatform.android,
    this.rawColorShift = 0.0,
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

  /// Whether this device has a torch to light (AC-1, AC-2). Consumed by the
  /// torch controls in SOURCE-2 / CAPTURE-3.
  final bool torchAvailable;

  /// How far lighting the torch biases the reading from [groundTruth] (AC-2):
  /// the torch's colour temperature shifts the measured colour, which the
  /// CAPTURE-3 warning is about. Zero leaves the reading unbiased.
  final double torchColorShift;

  /// Whether this device can capture in a wide gamut (Display P3) (AC-6).
  /// Surfaced through [SoftwareCaptureSource.supportsWideGamut]; drives the
  /// colour-space selection in SOURCE-2.
  final bool supportsWideGamut;

  /// Whether this device can capture in RAW (AC-7). Surfaced through
  /// [SoftwareCaptureSource.supportsRaw]; drives RAW capture in SOURCE-3.
  final bool supportsRaw;

  /// Which platform's pipeline this scene models (AC-10). Paired with
  /// [rawColorShift] so two platforms can carry different pre-normalization raw
  /// yet normalize to the same ground truth (SOURCE-4).
  final CapturePlatform platform;

  /// The platform-specific offset applied to the raw reading *before*
  /// normalization (AC-10): normalization against the card must remove it so
  /// both platforms land on the identical CIELAB. Zero leaves the raw reading
  /// at ground truth. Driven in SOURCE-4.
  final double rawColorShift;
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

  /// The colour space this device captures in, after selecting the widest it
  /// offers with a fallback to the standard space (AC-6, AC-8): a wide-gamut
  /// device captures in — and tags — Display P3; every other device falls back
  /// to sRGB. The generated feed is rendered in this space and [colorSpace]
  /// reports it, so a committed `Sample` records the gamut it was measured in.
  FrameColorSpace get _captureFrameSpace =>
      scene.supportsWideGamut ? FrameColorSpace.displayP3 : FrameColorSpace.srgb;

  CaptureLocks _locks = const CaptureLocks();

  @override
  CaptureSourceKind get kind => CaptureSourceKind.software;

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
    // Render the ground truth in the device's capture space: encode it as sRGB
    // (color_models), then rotate it into the capture space (identity for sRGB,
    // Display P3 on a wide-gamut device) so the feed is a genuine buffer in that
    // space — sampling then converts it back honestly (SOURCE-2).
    final space = _captureFrameSpace;
    final base =
        encodeFromSrgb(Pixel(truth.red, truth.green, truth.blue), space);
    const n = _kGeneratedFrameCount;
    return List<Frame>.generate(n, (i) {
      // Antisymmetric offset in [-noise, +noise]: offsets for frame i and
      // (n-1-i) are exact negatives, so the per-pixel mean over the feed is the
      // ground-truth colour. Applied in the capture space, where sampling reads.
      final offset = (scene.noise * (2 * i - (n - 1)) / (n - 1)).round();
      final pixel = Pixel(
        (base.r + offset).clamp(0, 255),
        (base.g + offset).clamp(0, 255),
        (base.b + offset).clamp(0, 255),
      );
      return Frame(
        width: _kGeneratedFrameSize,
        height: _kGeneratedFrameSize,
        pixels: List<Pixel>.filled(
          _kGeneratedFrameSize * _kGeneratedFrameSize,
          pixel,
        ),
        colorSpace: space,
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

  bool _torchOn = false;

  @override
  bool get torchOn => _torchOn;

  @override
  void turnTorchOn() => _torchOn = true;

  @override
  void turnTorchOff() => _torchOn = false;

  @override
  bool get supportsWideGamut => scene.supportsWideGamut;

  @override
  bool get supportsRaw => scene.supportsRaw;

  // SOURCE-2: [colorSpace] reports the space the feed is actually captured in —
  // Display P3 on a wide-gamut device, the sRGB fallback otherwise (AC-6, AC-8)
  // — mapped from the frame space via [CaptureColorSpace.ofFrame]. A RAW-capable
  // device captures in the widest space it offers, so its [colorSpace] is the
  // same Display P3 the wide-gamut selection already yields (SCENE_RAW is
  // wide-gamut); processed-vs-RAW is carried orthogonally by [captureMode].
  @override
  CaptureColorSpace get colorSpace =>
      CaptureColorSpace.ofFrame(_captureFrameSpace);

  // SOURCE-3: a RAW-capable device captures unprocessed frames (AC-7) — RAW in
  // the widest space it offers; every other device stays on the processed
  // (sRGB/JPEG-style) pipeline. The controller stamps this onto the committed
  // `Sample.captureMode`.
  @override
  CaptureMode get captureMode =>
      scene.supportsRaw ? CaptureMode.raw : CaptureMode.processed;
}
