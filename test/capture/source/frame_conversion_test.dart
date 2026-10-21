import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/frame_conversion.dart';

// CAM-3 unit coverage for the CameraImage → Frame conversion. The AC-2
// acceptance test (integration_test/live_camera/preview_test.dart) pins the
// behaviour; these tests exercise every branch of the conversion on the host.

int _clampByte(num v) => v.round().clamp(0, 255).toInt();
int _yOf(Pixel p) => _clampByte(0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
int _uOf(Pixel p) =>
    _clampByte(-0.168736 * p.r - 0.331264 * p.g + 0.5 * p.b + 128);
int _vOf(Pixel p) =>
    _clampByte(0.5 * p.r - 0.418688 * p.g - 0.081312 * p.b + 128);

int _l1(Pixel a, Pixel b) =>
    (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs();

/// A [width]×[height] iOS BGRA8888 [CameraImage], every pixel [colour].
CameraImage _bgra(Pixel colour, {int width = 16, int height = 16}) {
  final bytes = Uint8List(width * height * 4);
  for (var i = 0; i < width * height; i++) {
    bytes[i * 4 + 0] = colour.b;
    bytes[i * 4 + 1] = colour.g;
    bytes[i * 4 + 2] = colour.r;
    bytes[i * 4 + 3] = 255;
  }
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.bgra8888, raw: 1111970369),
      width: width,
      height: height,
      planes: [
        CameraImagePlane(
          bytes: bytes,
          bytesPerRow: width * 4,
          bytesPerPixel: 4,
          width: width,
          height: height,
        ),
      ],
    ),
  );
}

/// A 16×16 Android YUV420 [CameraImage] of the uniform [colour] (full-range).
CameraImage _yuv(Pixel colour) {
  const w = 16, h = 16;
  final y = _yOf(colour), u = _uOf(colour), v = _vOf(colour);
  final yPlane = Uint8List(w * h)..fillRange(0, w * h, y);
  final cw = w ~/ 2, ch = h ~/ 2;
  final uPlane = Uint8List(cw * ch)..fillRange(0, cw * ch, u);
  final vPlane = Uint8List(cw * ch)..fillRange(0, cw * ch, v);
  return CameraImage.fromPlatformInterface(
    CameraImageData(
      format: const CameraImageFormat(ImageFormatGroup.yuv420, raw: 35),
      width: w,
      height: h,
      planes: [
        CameraImagePlane(
            bytes: yPlane, bytesPerRow: w, bytesPerPixel: 1, width: w, height: h),
        CameraImagePlane(
            bytes: uPlane, bytesPerRow: cw, bytesPerPixel: 1, width: cw, height: ch),
        CameraImagePlane(
            bytes: vPlane, bytesPerRow: cw, bytesPerPixel: 1, width: cw, height: ch),
      ],
    ),
  );
}

/// A [CameraImage] in an unsupported format (single JPEG plane).
CameraImage _jpeg() => CameraImage.fromPlatformInterface(
      CameraImageData(
        format: const CameraImageFormat(ImageFormatGroup.jpeg, raw: 256),
        width: 4,
        height: 4,
        planes: [CameraImagePlane(bytes: Uint8List(16), bytesPerRow: 4)],
      ),
    );

const Pixel _cyan = Pixel(0, 170, 200);
const Pixel _orange = Pixel(220, 120, 20);

void main() {
  group('frameFromCameraImage', () {
    test('BGRA8888 maps B,G,R,A bytes to an exact RGB frame', () {
      final frame = frameFromCameraImage(_bgra(_cyan));
      expect(frame.colorSpace, FrameColorSpace.srgb);
      final centre = frame.pixelAt(frame.width ~/ 2, frame.height ~/ 2);
      expect(centre, _cyan, reason: 'the BGRA buffer reproduces the colour');
      // Rejects a BGR↔RGB channel swap.
      expect(centre, isNot(Pixel(_cyan.b, _cyan.g, _cyan.r)));
    });

    test('YUV420 decodes full-range BT.601 within 8-bit rounding', () {
      final centre = () {
        final f = frameFromCameraImage(_yuv(_cyan));
        return f.pixelAt(f.width ~/ 2, f.height ~/ 2);
      }();
      expect(_l1(centre, _cyan), lessThanOrEqualTo(12),
          reason: 'round-trips the colour within quantisation');
    });

    test('distinct colours convert to distinct pixels (not a constant)', () {
      final a = frameFromCameraImage(_bgra(_cyan));
      final b = frameFromCameraImage(_bgra(_orange));
      final pa = a.pixelAt(a.width ~/ 2, a.height ~/ 2);
      final pb = b.pixelAt(b.width ~/ 2, b.height ~/ 2);
      expect(pa, _cyan);
      expect(pb, _orange);
      expect(_l1(pa, pb), greaterThan(100));
    });

    test('a large buffer is downsampled toward the 64px target', () {
      // 128×64 → longest 128 → step 2 → 64×32 output; still reproduces colour.
      final frame = frameFromCameraImage(_bgra(_orange, width: 128, height: 64));
      expect(frame.width, 64);
      expect(frame.height, 32);
      expect(frame.pixelAt(frame.width ~/ 2, frame.height ~/ 2), _orange);
    });

    test('an unsupported format is rejected rather than mis-decoded', () {
      expect(() => frameFromCameraImage(_jpeg()), throwsArgumentError);
    });
  });
}
