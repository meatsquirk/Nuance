import 'dart:async';

import '../../domain/color_coordinates.dart';
import 'capture_source.dart';
import 'frame.dart';

/// A deterministic description of what a [SoftwareCaptureSource] is looking at.
///
/// Tests (and the non-native default source) build a source from one of these:
/// the [groundTruth] colour the scene really is, its [lighting], whether the
/// camera [canLock], whether a reference card is in view, optional per-frame
/// [noise], and an optional explicit [frames] list to replay. Frame generation
/// from [groundTruth] + [noise] is deferred to SOURCE-2; this shell replays
/// [frames] when given and holds the rest for the behaviour phases to consume.
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

  /// Per-frame noise amplitude. Consumed by SOURCE-2's frame generation.
  final double noise;

  /// An explicit frame list to replay, or null to use generated frames
  /// (generation lands in SOURCE-2).
  final List<Frame>? frames;
}

/// The deterministic, non-native [CaptureSource] bs-02 ships, built from a
/// [SceneSpec].
///
/// This is the SOURCE-1 skeleton: it exposes the scene's lighting and
/// reference-card presence, records lock requests, and replays any explicit
/// frames from the scene. Generating a live feed from the ground-truth colour
/// (with [SceneSpec.noise]) and emitting the real stability signal are deferred
/// to SOURCE-2.
class SoftwareCaptureSource implements CaptureSource {
  SoftwareCaptureSource(this.scene);

  /// The scene this source renders.
  final SceneSpec scene;

  CaptureLocks _locks = const CaptureLocks();

  @override
  Stream<Frame> get frames =>
      Stream<Frame>.fromIterable(scene.frames ?? const <Frame>[]);

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
  void lockExposure() => _locks = _locks.copyWith(exposure: true);

  @override
  void lockWhiteBalance() => _locks = _locks.copyWith(whiteBalance: true);

  @override
  void lockFocus() => _locks = _locks.copyWith(focus: true);
}
