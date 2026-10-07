import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/sampling.dart';

void main() {
  final frame = Frame(
    width: 1,
    height: 1,
    pixels: const [Pixel(10, 20, 30)],
  );

  test('default sampling radius is 5 px', () {
    expect(kDefaultSamplingRadiusPx, 5);
  });

  test('samplePoint is deferred to SOURCE-2', () {
    expect(() => samplePoint(frame, 0, 0), throwsUnimplementedError);
  });

  test('sampleAreaAverage is deferred to SOURCE-2', () {
    expect(() => sampleAreaAverage(frame, 0, 0), throwsUnimplementedError);
    expect(
      () => sampleAreaAverage(frame, 0, 0, radiusPx: 21),
      throwsUnimplementedError,
    );
  });

  test('sampleFromPhoto is deferred to SOURCE-3', () {
    expect(() => sampleFromPhoto(frame, 0, 0), throwsUnimplementedError);
  });

  test('averageFrames is deferred to SOURCE-2', () {
    expect(() => averageFrames([frame]), throwsUnimplementedError);
  });
}
