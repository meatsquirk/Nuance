import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';

import '../../domain/color_coordinates.dart';
import 'capture_source.dart';
import 'frame.dart';
import 'frame_conversion.dart';

/// A seam over the camera plugin's frame delivery (bs-19 CAM-3).
///
/// Lets [CameraCaptureSource]'s live-feed wiring run on the host: the shipped
/// [PluginCameraDevice] drives a real `CameraController`, while a unit test
/// injects a fake that pushes scripted [CameraImage]s. [start] begins delivery,
/// invoking [onImage] for each buffer the device produces; [stop] ends delivery
/// and releases the device. Keeping the plugin behind this interface is why the
/// frame-stream conversion and release logic below are fully covered while only
/// the concrete platform calls (verified on-device at sign-off, plan D-5) are
/// exempt.
abstract class CameraDevice {
  /// Begins frame delivery, calling [onImage] with each [CameraImage].
  Future<void> start(void Function(CameraImage image) onImage);

  /// Stops frame delivery and releases the device.
  Future<void> stop();
}

/// The native [CaptureSource] over the device camera (bs-19 SOURCE-2).
///
/// Wraps the official Flutter `camera` plugin (through the [CameraDevice] seam)
/// so the Capture live view reads real frames instead of the deterministic
/// software feed. CAM-3 lands the live feed: [frames] starts the device on
/// first listen, converts each delivered `CameraImage` through
/// `frame_conversion.dart`, and releases the device when the subscription ends.
/// The remaining members stay inert on this skeleton until their phase lands:
///
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
/// recorded in local state until the real controls land, so the controller's
/// reflections stay honest.
class CameraCaptureSource implements CaptureSource {
  /// Creates the camera source over [device] (defaulting to the shipped
  /// [PluginCameraDevice]).
  ///
  /// Construction is cheap and device-free: the default [PluginCameraDevice]
  /// acquires nothing until [frames] is listened to, so the source can be built
  /// in a host unit test and the plugin is touched only when a live feed is
  /// actually opened on a real device.
  CameraCaptureSource({CameraDevice? device})
      : _device = device ?? PluginCameraDevice();

  final CameraDevice _device;

  CaptureLocks _locks = const CaptureLocks();
  ImportedPhoto? _importedPhoto;
  bool _torchOn = false;

  @override
  CaptureSourceKind get kind => CaptureSourceKind.camera;

  @override
  Stream<Frame> get frames {
    late final StreamController<Frame> controller;
    controller = StreamController<Frame>(
      onListen: () async {
        await _device.start((image) {
          if (!controller.isClosed) {
            controller.add(frameFromCameraImage(image));
          }
        });
      },
      onCancel: () async {
        await _device.stop();
      },
    );
    return controller.stream;
  }

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

/// The shipped [CameraDevice] over the Flutter `camera` plugin.
///
/// Selects the first available camera, initialises a processed-pipeline
/// controller in the platform's native image format (YUV420 on Android,
/// BGRA8888 on iOS — the two layouts `frame_conversion.dart` decodes), and
/// streams its images. Its body is the only genuinely device-bound code in this
/// module: the `camera` plugin's platform channels cannot run under
/// `flutter-tester`, so it is verified by the on-device walkthrough at sign-off
/// (plan D-5) and exempted from the host coverage gate, while the wiring that
/// consumes it ([CameraCaptureSource.frames]) stays fully covered through the
/// [CameraDevice] seam.
class PluginCameraDevice implements CameraDevice {
  CameraController? _controller;

  // coverage:ignore-start
  @override
  Future<void> start(void Function(CameraImage image) onImage) async {
    final cameras = await availableCameras();
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    await controller.initialize();
    await controller.startImageStream(onImage);
    _controller = controller;
  }
  // coverage:ignore-end

  // coverage:ignore-start
  @override
  Future<void> stop() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.stopImageStream();
    await controller.dispose();
    _controller = null;
  }
  // coverage:ignore-end
}
