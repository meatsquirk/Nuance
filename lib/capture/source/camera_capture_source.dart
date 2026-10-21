import 'dart:async';

import '../../domain/color_coordinates.dart';
import 'capture_source.dart';
import 'frame.dart';

/// The native [CaptureSource] over the device camera (bs-19 SOURCE-2).
///
/// Wraps the official Flutter `camera` plugin so the Capture live view reads
/// real frames instead of the deterministic software feed. This is the **CAM-2
/// shell**: every [CaptureSource] member is present but inert and device-free —
/// construction is cheap, [frames] and [stability] are empty, and no plugin or
/// platform call is made. The behaviour lands phase by phase on this skeleton:
///
/// - CAM-3 wires [frames] to the plugin's image stream, converting each
///   `CameraImage` through `frame_conversion.dart`.
/// - CAM-5 wires [lockExposure] / [lockWhiteBalance] / [lockFocus] and reflects
///   [locks] from the real controller's AE · AWB · AF state.
/// - CAM-6 wires [turnTorchOn] / [turnTorchOff] and [torchOn] to the device
///   torch.
/// - CAM-7 releases and re-initialises the controller across the app lifecycle.
///
/// The inert defaults follow plan D-6: calibration stays deferred, so
/// [normaliseAgainstCard] returns its argument unchanged; the source reports the
/// standard sRGB [colorSpace] and the [CaptureMode.processed] pipeline, and does
/// not yet claim wide-gamut or RAW capability. Lock and torch requests are
/// recorded in local state (as the interface documents the shell doing) until
/// the real controls land, so the controller's reflections stay honest.
class CameraCaptureSource implements CaptureSource {
  /// Creates the inert camera-source shell (CAM-2).
  ///
  /// Cheap and device-free: the `CameraController` the real source wraps is
  /// acquired in CAM-3, not here, so construction never touches the platform
  /// and the source can be built in a host unit test.
  CameraCaptureSource();

  CaptureLocks _locks = const CaptureLocks();
  ImportedPhoto? _importedPhoto;
  bool _torchOn = false;

  @override
  CaptureSourceKind get kind => CaptureSourceKind.camera;

  @override
  Stream<Frame> get frames => const Stream<Frame>.empty();

  @override
  CaptureLocks get locks => _locks;

  @override
  Stream<StabilityReading> get stability => const Stream<StabilityReading>.empty();

  @override
  Lighting get lighting => Lighting.adequate;

  @override
  bool get referenceCardPresent => false;

  @override
  ColorCoordinates normaliseAgainstCard(ColorCoordinates raw) => raw;

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

  @override
  bool get torchOn => _torchOn;

  @override
  void turnTorchOn() => _torchOn = true;

  @override
  void turnTorchOff() => _torchOn = false;

  @override
  bool get supportsWideGamut => false;

  @override
  bool get supportsRaw => false;

  @override
  CaptureColorSpace get colorSpace => CaptureColorSpace.srgb;

  @override
  CaptureMode get captureMode => CaptureMode.processed;
}
