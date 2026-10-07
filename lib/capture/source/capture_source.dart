import 'dart:async';

import 'frame.dart';

/// The number of settled frames a reading needs before it counts as stable
/// ("STABLE 12/12" — spec AC-4). The source emits progress toward this target
/// as [StabilityReading]s.
const int kStabilityFrameTarget = 12;

/// How well lit the scene is, as assessed by a [CaptureSource].
///
/// Poor lighting downgrades the stated accuracy rather than refusing the
/// reading (spec AC-6); a committed [Lighting.low] capture is marked
/// approximate.
enum Lighting {
  /// Enough light to capture at the normal accuracy tier.
  adequate,

  /// Too little light — the reading will be downgraded to approximate.
  low,
}

/// Which of exposure, white balance and focus are currently locked.
///
/// Locking all three settles the reading (spec AC-4, "AE · AWB · AF LOCKED").
/// The source exposes the current locks so the controller can reflect them.
class CaptureLocks {
  const CaptureLocks({
    this.exposure = false,
    this.whiteBalance = false,
    this.focus = false,
  });

  /// Whether auto-exposure is locked (AE).
  final bool exposure;

  /// Whether auto white balance is locked (AWB).
  final bool whiteBalance;

  /// Whether auto-focus is locked (AF).
  final bool focus;

  /// True once exposure, white balance and focus are all locked.
  bool get allLocked => exposure && whiteBalance && focus;

  /// Returns a copy with the given locks replaced.
  CaptureLocks copyWith({bool? exposure, bool? whiteBalance, bool? focus}) {
    return CaptureLocks(
      exposure: exposure ?? this.exposure,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      focus: focus ?? this.focus,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CaptureLocks &&
      other.exposure == exposure &&
      other.whiteBalance == whiteBalance &&
      other.focus == focus;

  @override
  int get hashCode => Object.hash(exposure, whiteBalance, focus);

  @override
  String toString() =>
      'CaptureLocks(AE $exposure, AWB $whiteBalance, AF $focus)';
}

/// How settled the reading is: [settledFrames] of [requiredFrames] gathered.
///
/// The source emits these as its stability signal; the controller formats them
/// as "SETTLING 6/12" / "STABLE 12/12" (that text lives on the capture state,
/// not here).
class StabilityReading {
  const StabilityReading({
    required this.settledFrames,
    this.requiredFrames = kStabilityFrameTarget,
  });

  /// Frames gathered so far toward a stable reading.
  final int settledFrames;

  /// Frames needed for the reading to count as stable.
  final int requiredFrames;

  /// True once enough frames have settled.
  bool get isStable => settledFrames >= requiredFrames;

  @override
  bool operator ==(Object other) =>
      other is StabilityReading &&
      other.settledFrames == settledFrames &&
      other.requiredFrames == requiredFrames;

  @override
  int get hashCode => Object.hash(settledFrames, requiredFrames);

  @override
  String toString() => 'StabilityReading($settledFrames/$requiredFrames)';
}

/// A gallery photo imported into the source to sample from (AC-9).
///
/// Carries the already-decoded [image] and the painter's chosen sample point
/// ([pointX], [pointY]) on it. The source holds the most recently imported one
/// (see [CaptureSource.importedPhoto]); the controller reads it to sample point
/// P of the photograph instead of the live camera feed.
class ImportedPhoto {
  const ImportedPhoto({
    required this.image,
    required this.pointX,
    required this.pointY,
  });

  /// The decoded gallery image to sample.
  final Frame image;

  /// The sample point's column (0-based) on [image].
  final int pointX;

  /// The sample point's row (0-based) on [image].
  final int pointY;
}

/// A source of capture frames and the camera controls over them (SI D2).
///
/// Yields a live stream of [Frame]s, exposes exposure / white-balance / focus
/// locking with a [stability] signal, assesses the scene [lighting], reports
/// whether a reference card is in view, and holds any gallery photo imported to
/// sample from ([importedPhoto]). Platform-native implementations
/// (CameraX / AVFoundation) live outside this Dart build; bs-02 ships
/// `SoftwareCaptureSource` as the deterministic default and the base the test
/// `FakeCaptureSource` configures.
abstract class CaptureSource {
  /// The live feed of frames.
  Stream<Frame> get frames;

  /// Which of exposure, white balance and focus are currently locked.
  CaptureLocks get locks;

  /// The stability signal: progress toward a settled reading.
  Stream<StabilityReading> get stability;

  /// The scene's current lighting assessment.
  Lighting get lighting;

  /// Whether a reference card is present in the frame (enables calibration).
  bool get referenceCardPresent;

  /// The gallery photo most recently imported to sample from, or null when none
  /// has been imported (the painter is reading the live feed). Set via
  /// [importPhoto]; read by the controller when the painter samples from an
  /// imported photo (AC-9).
  ImportedPhoto? get importedPhoto;

  /// Imports [photo] into the source so a later sample reads point P of it
  /// instead of the live feed (AC-9).
  void importPhoto(ImportedPhoto photo);

  /// Locks auto-exposure (AE).
  void lockExposure();

  /// Locks auto white balance (AWB).
  void lockWhiteBalance();

  /// Locks auto-focus (AF).
  void lockFocus();
}
