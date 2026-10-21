import 'package:camera/camera.dart';

import 'frame.dart';

/// Target longest-side of a converted [Frame], in pixels (plan D-4).
///
/// Matches the software feed's frame size so both sources hand the sampling
/// layer buffers of the same order of magnitude. A device buffer larger than
/// this is nearest-neighbour downsampled by an integer step so sampling the
/// reticle disc stays cheap; a smaller one is kept at its own size.
const int _targetLongestSide = 64;

/// Converts a plugin [CameraImage] into a canonical [Frame] (bs-19 SOURCE-2).
///
/// The [CameraCaptureSource] feeds each frame its image stream delivers through
/// here before sampling reads it, so the two platform buffer layouts become one
/// RGB [Frame] the sampling layer already understands:
///
/// - **iOS** delivers a single BGRA8888 plane (`ImageFormatGroup.bgra8888`):
///   four bytes per pixel in B, G, R, A order, read through the plane's own
///   `bytesPerRow` / `bytesPerPixel` strides — an exact RGB mapping.
/// - **Android** delivers YUV420 planes (`ImageFormatGroup.yuv420`): a
///   full-resolution Y plane and 2×2-subsampled U/V planes, decoded as
///   **full-range BT.601** (JFIF) — the inverse of the forward matrix the AC-2
///   fixture encodes — again honouring each plane's strides. Only 8-bit
///   rounding separates the round-trip from the source colour.
///
/// The result is tagged [FrameColorSpace.srgb] (plan D-6: the camera source
/// reports the processed sRGB pipeline) and downsampled toward
/// [_targetLongestSide] for sampling cost (D-4). An unsupported format throws
/// rather than return a wrong buffer.
Frame frameFromCameraImage(CameraImage image) {
  switch (image.format.group) {
    case ImageFormatGroup.bgra8888:
      return _fromBgra8888(image);
    case ImageFormatGroup.yuv420:
      return _fromYuv420(image);
    // ignore: no_default_cases
    default:
      throw ArgumentError.value(
        image.format.group,
        'image.format.group',
        'bs-19 frame conversion supports only BGRA8888 (iOS) and YUV420 '
            '(Android); got',
      );
  }
}

/// Converts an iOS BGRA8888 single-plane buffer to an RGB [Frame] (exact).
Frame _fromBgra8888(CameraImage image) {
  final plane = image.planes.first;
  final bytes = plane.bytes;
  final rowStride = plane.bytesPerRow;
  final pixelStride = plane.bytesPerPixel ?? 4;
  return _downsample(image.width, image.height, (x, y) {
    final i = y * rowStride + x * pixelStride;
    // Bytes are B, G, R, A; the Frame pixel is R, G, B.
    return Pixel(bytes[i + 2], bytes[i + 1], bytes[i]);
  });
}

/// Converts an Android YUV420 buffer to an RGB [Frame] (full-range BT.601).
Frame _fromYuv420(CameraImage image) {
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  final yRow = yPlane.bytesPerRow;
  final uRow = uPlane.bytesPerRow;
  final vRow = vPlane.bytesPerRow;
  final uPixel = uPlane.bytesPerPixel ?? 1;
  final vPixel = vPlane.bytesPerPixel ?? 1;
  return _downsample(image.width, image.height, (x, y) {
    final yValue = yPlane.bytes[y * yRow + x].toDouble();
    // U and V are 2×2-subsampled: one chroma sample per 2×2 luma block.
    final cx = x >> 1;
    final cy = y >> 1;
    final u = uPlane.bytes[cy * uRow + cx * uPixel] - 128.0;
    final v = vPlane.bytes[cy * vRow + cx * vPixel] - 128.0;
    // Full-range (JFIF) BT.601 inverse of the fixture's forward matrix.
    final r = yValue + 1.402 * v;
    final g = yValue - 0.344136 * u - 0.714136 * v;
    final b = yValue + 1.772 * u;
    return Pixel(_clampByte(r), _clampByte(g), _clampByte(b));
  });
}

/// Builds a [Frame] of [srcWidth]×[srcHeight] (or a downsampled grid of it),
/// reading each output pixel's source colour from [colourAt].
///
/// The step is the integer factor that brings the longest side down to
/// [_targetLongestSide]; a buffer already at or below it keeps step 1. Output
/// dimensions are `src ~/ step` (at least 1), so every sampled `(x, y)` stays
/// inside the source buffer without a per-pixel bounds clamp.
Frame _downsample(
  int srcWidth,
  int srcHeight,
  Pixel Function(int x, int y) colourAt,
) {
  final longest = srcWidth > srcHeight ? srcWidth : srcHeight;
  final step = (longest + _targetLongestSide - 1) ~/ _targetLongestSide;
  final effectiveStep = step < 1 ? 1 : step;
  final outWidth = _outDim(srcWidth, effectiveStep);
  final outHeight = _outDim(srcHeight, effectiveStep);
  final pixels = List<Pixel>.generate(
    outWidth * outHeight,
    (index) {
      final ox = index % outWidth;
      final oy = index ~/ outWidth;
      return colourAt(ox * effectiveStep, oy * effectiveStep);
    },
  );
  return Frame(
    width: outWidth,
    height: outHeight,
    pixels: pixels,
    colorSpace: FrameColorSpace.srgb,
  );
}

/// The output dimension for a [src] side downsampled by [step] (at least 1).
int _outDim(int src, int step) {
  final n = src ~/ step;
  return n < 1 ? 1 : n;
}

/// Rounds [value] to the nearest 0–255 byte.
int _clampByte(double value) => value.round().clamp(0, 255);
