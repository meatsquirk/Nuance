import 'dart:async';

import '../../domain/color_coordinates.dart';
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

/// The colour space a [CaptureSource] is capturing in (SI D2, plan D-2).
///
/// A *capture-level* tag, distinct from a single [Frame]'s [FrameColorSpace]
/// buffer tag: it is the space the source captures in *now* (after any
/// wide-gamut → sRGB fallback), the value the controller stamps onto the
/// committed `Sample.colorSpace`.
///
/// **SOURCE-1 decision (D-2):** rather than rename `FrameColorSpace`, a separate
/// `CaptureColorSpace` is introduced and [ofFrame] maps a frame's buffer tag
/// onto it. The two value sets coincide today (`{srgb, displayP3}`) but model
/// different things — a frame tag describes one decoded buffer, this describes
/// the source's current capture state — and `Sample.colorSpace` must not depend
/// on the frame-buffer enum. `displayP3` is the widest space offered and tags
/// both wide-gamut and the widest RAW capture; processed-vs-RAW is carried
/// orthogonally by [CaptureMode].
enum CaptureColorSpace {
  /// Standard sRGB — the device default and the narrower fallback (AC-8).
  srgb,

  /// Display P3 — wide-gamut capture, and the widest space RAW capture uses.
  displayP3;

  /// The capture-level space corresponding to a frame's buffer [space].
  ///
  /// Used from SOURCE-2 on, where the source's [CaptureSource.colorSpace]
  /// reflects the space its frames were actually captured in.
  static CaptureColorSpace ofFrame(FrameColorSpace space) => switch (space) {
        FrameColorSpace.srgb => CaptureColorSpace.srgb,
        FrameColorSpace.displayP3 => CaptureColorSpace.displayP3,
      };
}

/// Whether a [CaptureSource] is delivering processed frames or RAW (AC-7).
enum CaptureMode {
  /// The device's processed pipeline (the sRGB/JPEG-style default).
  processed,

  /// RAW capture, where the device supports it — the widest space, unprocessed.
  raw,
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

  /// Normalises a [raw] reading against the reference card in view, returning
  /// the colour corrected toward ground truth (AC-8).
  ///
  /// A phone camera does not measure colour — it applies its own auto white
  /// balance — so an uncalibrated reading drifts from the real colour. A
  /// reference card of known patches lets the source measure that drift and
  /// remove it, landing the result within the calibrated tier's ΔE00 of ground
  /// truth (SI D2: the `CaptureSource` returns a *normalised* sample). Called
  /// by the controller only while [referenceCardPresent]; the correction is the
  /// source's to compute because only it observes the card.
  ColorCoordinates normaliseAgainstCard(ColorCoordinates raw);

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

  /// Whether the camera torch (the flash LED held on) is currently lit (AC-1,
  /// AC-2).
  ///
  /// The torch is a capture *illuminant*, distinct from the ambient
  /// [lighting] assessment: turning it on floods the scene with the LED's light
  /// so a reading can be taken in the dark. Controller-level concerns — the
  /// colour-temperature warning string and the `litByTorch` stamp on the
  /// committed sample — live on the capture state (CAPTURE-3), not here; the
  /// source holds only the on/off state and the controls below.
  bool get torchOn;

  /// Lights the torch (AC-1, AC-2). Behaviour lands in SOURCE-2/CAPTURE-3; the
  /// shell records the state.
  void turnTorchOn();

  /// Extinguishes the torch (AC-1, AC-2).
  void turnTorchOff();

  /// Whether the device can capture in a wide gamut (Display P3) rather than
  /// only sRGB (AC-6).
  ///
  /// The source captures in the widest space it offers and falls back to the
  /// narrower one otherwise (SOURCE-2); this reports the capability, while
  /// [colorSpace] reports the space actually in use after any fallback.
  bool get supportsWideGamut;

  /// Whether the device can capture in RAW (AC-7).
  ///
  /// When true the source may capture unprocessed frames in the widest space
  /// ([captureMode] == [CaptureMode.raw]); otherwise it stays on the processed
  /// pipeline (SOURCE-3).
  bool get supportsRaw;

  /// The colour space the source is capturing in now, after any wide-gamut →
  /// sRGB fallback (AC-6, AC-8).
  ///
  /// The controller stamps this onto the committed `Sample.colorSpace` so a
  /// reading records the gamut it was measured in. SOURCE-2 derives it from the
  /// device's capability; the shell reports the sRGB default.
  CaptureColorSpace get colorSpace;

  /// Whether the source is delivering processed frames or RAW (AC-7).
  ///
  /// The shell reports [CaptureMode.processed]; SOURCE-3 switches RAW-capable
  /// devices to [CaptureMode.raw].
  CaptureMode get captureMode;
}
