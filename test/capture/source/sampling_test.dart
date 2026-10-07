import 'package:color_models/color_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/sampling.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

// Render a sampled CIELAB colour back to sRGB (same library the sampler uses)
// so the tests can compare it against the known frame pixels.
RgbColor _toRgb(ColorCoordinates lab) =>
    LabColor(lab.lightness, lab.a, lab.b).toRgbColor();

int _l1(RgbColor c, int r, int g, int b) =>
    (c.red - r).abs() + (c.green - g).abs() + (c.blue - b).abs();

/// A uniform [w]×[h] frame of one [pixel].
Frame _uniform(Pixel pixel, {int w = 16, int h = 16}) =>
    Frame(width: w, height: h, pixels: List<Pixel>.filled(w * h, pixel));

void main() {
  // The 8-bit CIELAB round-trip (sRGB → Lab → sRGB) is near-exact; this bound
  // covers its rounding without masking the averages the tests check.
  const tol = 9;

  test('default sampling radius is 5 px', () {
    expect(kDefaultSamplingRadiusPx, 5);
  });

  test('samplePoint returns the single pixel colour', () {
    final frame = _uniform(const Pixel(200, 120, 40));
    final sampled = _toRgb(samplePoint(frame, 8, 8));
    expect(_l1(sampled, 200, 120, 40), lessThan(tol));
  });

  test('sampleAreaAverage over a uniform disc returns that colour', () {
    final frame = _uniform(const Pixel(60, 140, 210));
    final sampled = _toRgb(sampleAreaAverage(frame, 8, 8, radiusPx: 5));
    expect(_l1(sampled, 60, 140, 210), lessThan(tol));
  });

  test('sampleAreaAverage is the mean over the disc, not a point read', () {
    // A row [100,100,200,100,100]; the radius-2 disc at the centre spans the
    // whole row (the out-of-row rows are skipped by the bounds guard), so the
    // average is (100·4 + 200) / 5 = 120 — not the 200 a point read returns.
    final frame = Frame(
      width: 5,
      height: 1,
      pixels: const [
        Pixel(100, 100, 100),
        Pixel(100, 100, 100),
        Pixel(200, 200, 200),
        Pixel(100, 100, 100),
        Pixel(100, 100, 100),
      ],
    );
    final avg = _toRgb(sampleAreaAverage(frame, 2, 0, radiusPx: 2));
    expect(_l1(avg, 120, 120, 120), lessThan(tol));
    final point = _toRgb(samplePoint(frame, 2, 0));
    expect(_l1(point, 200, 200, 200), lessThan(tol));
  });

  test('sampleAreaAverage clamps the disc to the frame bounds at an edge', () {
    // At the left edge (x=0) the radius-2 disc only reaches x=0,1,2 — the out of
    // bounds columns are skipped — averaging (100+100+200)/3 ≈ 133.
    final frame = Frame(
      width: 5,
      height: 1,
      pixels: const [
        Pixel(100, 100, 100),
        Pixel(100, 100, 100),
        Pixel(200, 200, 200),
        Pixel(100, 100, 100),
        Pixel(100, 100, 100),
      ],
    );
    final avg = _toRgb(sampleAreaAverage(frame, 0, 0, radiusPx: 2));
    expect(_l1(avg, 133, 133, 133), lessThan(tol));
  });

  test('sampleAreaAverage excludes pixels outside the disc radius', () {
    // A 3×3 frame: centre + the 4 edge-adjacent pixels are 100, the 4 corners
    // are 200. A radius-1 disc includes only the plus (dx²+dy² ≤ 1), so the
    // corners are excluded and the average is 100 — not pulled toward 200.
    final frame = Frame(
      width: 3,
      height: 3,
      pixels: const [
        Pixel(200, 200, 200), Pixel(100, 100, 100), Pixel(200, 200, 200),
        Pixel(100, 100, 100), Pixel(100, 100, 100), Pixel(100, 100, 100),
        Pixel(200, 200, 200), Pixel(100, 100, 100), Pixel(200, 200, 200),
      ],
    );
    final avg = _toRgb(sampleAreaAverage(frame, 1, 1, radiusPx: 1));
    expect(_l1(avg, 100, 100, 100), lessThan(tol));
  });

  test('averageFrames takes the per-pixel mean across frames', () {
    final frames = [
      _uniform(const Pixel(100, 100, 100), w: 2, h: 2),
      _uniform(const Pixel(200, 200, 200), w: 2, h: 2),
    ];
    final mean = averageFrames(frames);
    expect(mean.width, 2);
    expect(mean.height, 2);
    expect(mean.pixels, everyElement(const Pixel(150, 150, 150)));
  });

  test('sampleFromPhoto is deferred to SOURCE-3', () {
    final frame = _uniform(const Pixel(10, 20, 30));
    expect(() => sampleFromPhoto(frame, 0, 0), throwsUnimplementedError);
  });
}
