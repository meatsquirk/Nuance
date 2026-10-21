import 'package:camera/camera.dart';

import 'frame.dart';

/// Converts a plugin [CameraImage] into a canonical [Frame] (bs-19 SOURCE-2).
///
/// The [CameraCaptureSource] feeds each frame its image stream delivers through
/// here before sampling reads it, so the two platform buffer layouts become one
/// RGB [Frame] the sampling layer already understands:
///
/// - **Android** delivers YUV420 planes (`ImageFormatGroup.yuv420`);
/// - **iOS** delivers a single BGRA8888 plane (`ImageFormatGroup.bgra8888`).
///
/// This is the **CAM-2 shell**: the signature is fixed here, but the real
/// channel-order and value-range conversion (downsampled for sampling cost per
/// plan D-4, with golden-buffer unit tests) lands in CAM-3. Until then the stub
/// refuses to run rather than return a wrong buffer — nothing calls it yet, as
/// the camera source's [CameraCaptureSource.frames] stream is empty in the
/// shell and the app still runs on the software source.
Frame frameFromCameraImage(CameraImage image) =>
    throw UnimplementedError('CameraImage → Frame conversion lands in CAM-3');
