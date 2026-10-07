import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';

void main() {
  group('Pixel', () {
    test('equal when all channels match', () {
      // One built non-const so the const constructor is covered at runtime.
      // ignore: prefer_const_constructors
      final a = Pixel(10, 20, 30);
      const b = Pixel(10, 20, 30);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when a channel differs', () {
      expect(const Pixel(10, 20, 30), isNot(equals(const Pixel(10, 20, 31))));
    });

    test('unequal to a non-Pixel object', () {
      const pixel = Pixel(10, 20, 30);
      // ignore: unrelated_type_equality_checks
      final isEqual = pixel == 'x';
      expect(isEqual, isFalse);
    });

    test('toString reports the channels', () {
      expect(const Pixel(10, 20, 30).toString(), 'Pixel(10, 20, 30)');
    });
  });

  group('Frame', () {
    final pixels = const [
      Pixel(0, 0, 0),
      Pixel(1, 1, 1),
      Pixel(2, 2, 2),
      Pixel(3, 3, 3),
    ];

    test('defaults to sRGB colour space', () {
      final frame = Frame(width: 2, height: 2, pixels: pixels);
      expect(frame.colorSpace, FrameColorSpace.srgb);
      expect(frame.width, 2);
      expect(frame.height, 2);
      expect(frame.pixels, pixels);
    });

    test('carries an explicit wide-gamut colour space', () {
      final frame = Frame(
        width: 2,
        height: 2,
        pixels: pixels,
        colorSpace: FrameColorSpace.displayP3,
      );
      expect(frame.colorSpace, FrameColorSpace.displayP3);
    });

    test('pixelAt reads row-major', () {
      final frame = Frame(width: 2, height: 2, pixels: pixels);
      expect(frame.pixelAt(0, 0), const Pixel(0, 0, 0));
      expect(frame.pixelAt(1, 0), const Pixel(1, 1, 1));
      expect(frame.pixelAt(0, 1), const Pixel(2, 2, 2));
      expect(frame.pixelAt(1, 1), const Pixel(3, 3, 3));
    });

    test('toString reports size, space and pixel count', () {
      final frame = Frame(width: 2, height: 2, pixels: pixels);
      expect(frame.toString(), 'Frame(2x2, srgb, 4 px)');
    });
  });
}
