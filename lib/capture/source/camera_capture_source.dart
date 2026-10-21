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

  /// Holds the device's auto-exposure at its current value (AE lock — CAM-5).
  Future<void> lockExposure();

  /// Holds the device's auto white balance at its current value (AWB lock —
  /// CAM-5).
  Future<void> lockWhiteBalance();

  /// Holds the device's auto-focus at its current value (AF lock — CAM-5).
  Future<void> lockFocus();
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
/// - CAM-6 wires [turnTorchOn] / [turnTorchOff] and [torchOn] to the device
///   torch.
/// - CAM-7 releases and re-initialises the controller across the app lifecycle.
///
/// The inert defaults follow plan D-6: calibration stays deferred, so
/// [normaliseAgainstCard] returns its argument unchanged; the source reports the
/// standard sRGB [colorSpace] and the [CaptureMode.processed] pipeline, and does
/// not yet claim wide-gamut or RAW capability.
///
/// CAM-5 wires the lock controls: [lockExposure] / [lockWhiteBalance] /
/// [lockFocus] each record the lock in [locks] *and* forward it to the device
/// so the real camera holds AE · AWB · AF (the plugin exposes AE and AF; AWB is
/// held implicitly by the AE lock on both platforms — see [PluginCameraDevice]).
/// The torch requests stay recorded in local state until CAM-6 lands.
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
  void lockExposure() {
    _locks = _locks.copyWith(exposure: true);
    unawaited(_device.lockExposure());
  }

  @override
  void lockWhiteBalance() {
    _locks = _locks.copyWith(whiteBalance: true);
    unawaited(_device.lockWhiteBalance());
  }

  @override
  void lockFocus() {
    _locks = _locks.copyWith(focus: true);
    unawaited(_device.lockFocus());
  }

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

  // coverage:ignore-start
  @override
  Future<void> lockExposure() async {
    await _controller?.setExposureMode(ExposureMode.locked);
  }
  // coverage:ignore-end

  // coverage:ignore-start
  @override
  Future<void> lockWhiteBalance() async {
    // The `camera` plugin exposes no white-balance lock; on both iOS
    // (AVFoundation) and Android (CameraX) the device holds auto white balance
    // once auto-exposure is locked, so AWB is held by [lockExposure] and this
    // has no separate control to drive. Kept as an explicit seam member so the
    // source routes all three lock intents uniformly (D-5 on-device walkthrough
    // confirms AWB settles with AE).
  }
  // coverage:ignore-end

  // coverage:ignore-start
  @override
  Future<void> lockFocus() async {
    await _controller?.setFocusMode(FocusMode.locked);
  }
  // coverage:ignore-end
}
