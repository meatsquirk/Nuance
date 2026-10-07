import 'package:color_models/color_models.dart';

import '../../domain/color_coordinates.dart';
import 'frame.dart';

/// The default sampling radius, in pixels (D-7). Area-average sampling covers
/// the disc of this radius unless the painter picks another.
const int kDefaultSamplingRadiusPx = 5;

/// Converts a raw device [pixel] (sRGB 8-bit channels) to canonical CIELAB.
///
/// Reuses the established `color_models` library (plan D-2) — the same library
/// bs-01's colour-science delegates to for the inverse (CIELAB→sRGB) direction —
/// so no colour maths is hand-rolled here. The `ColorScience` interface exposes
/// only CIELAB→X conversions and these sampling functions take no `ColorScience`,
/// so the sRGB→CIELAB step is taken directly against the shared library.
ColorCoordinates _pixelToLab(Pixel pixel) {
  final lab = RgbColor(pixel.r, pixel.g, pixel.b).toLabColor();
  return ColorCoordinates(
    lightness: lab.lightness.toDouble(),
    a: lab.chromaticityA.toDouble(),
    b: lab.chromaticityB.toDouble(),
  );
}

/// The per-channel mean [Pixel] over the disc of [radiusPx] centred on
/// ([cx], [cy]) of [frame] — a true pixel average, clamped to the frame bounds.
///
/// Every pixel whose squared distance from the centre is within `radiusPx²` is
/// included; pixels outside the frame are skipped. The centre pixel is always
/// included (it is in bounds), so the disc is never empty.
Pixel _averagePixel(Frame frame, int cx, int cy, int radiusPx) {
  final r2 = radiusPx * radiusPx;
  var sumR = 0;
  var sumG = 0;
  var sumB = 0;
  var count = 0;
  for (var dy = -radiusPx; dy <= radiusPx; dy++) {
    final y = cy + dy;
    if (y < 0 || y >= frame.height) continue;
    for (var dx = -radiusPx; dx <= radiusPx; dx++) {
      final x = cx + dx;
      if (x < 0 || x >= frame.width) continue;
      if (dx * dx + dy * dy > r2) continue;
      final p = frame.pixelAt(x, y);
      sumR += p.r;
      sumG += p.g;
      sumB += p.b;
      count++;
    }
  }
  return Pixel(
    (sumR / count).round(),
    (sumG / count).round(),
    (sumB / count).round(),
  );
}

/// Samples the colour of a single pixel at ([x], [y]) of [frame], as canonical
/// CIELAB.
ColorCoordinates samplePoint(Frame frame, int x, int y) =>
    _pixelToLab(frame.pixelAt(x, y));

/// Samples the colour at ([x], [y]) of [frame] as the average over the disc of
/// [radiusPx] (default [kDefaultSamplingRadiusPx]), as canonical CIELAB.
///
/// The raw device pixels over the disc are averaged, then that mean pixel is
/// converted once to CIELAB — a true pixel average, not a single-pixel read.
ColorCoordinates sampleAreaAverage(
  Frame frame,
  int x,
  int y, {
  int radiusPx = kDefaultSamplingRadiusPx,
}) =>
    _pixelToLab(_averagePixel(frame, x, y, radiusPx));

/// Samples the colour at ([x], [y]) of an imported photo [image] as the average
/// over the disc of [radiusPx] (default [kDefaultSamplingRadiusPx]), as
/// canonical CIELAB.
///
/// Signature only — decoding and sampling land in SOURCE-3 (AC-9).
ColorCoordinates sampleFromPhoto(
  Frame image,
  int x,
  int y, {
  int radiusPx = kDefaultSamplingRadiusPx,
}) {
  throw UnimplementedError('sampleFromPhoto: behaviour lands in SOURCE-3');
}

/// Averages several [frames] into one frame, pixel by pixel — the primitive a
/// committed reading settles over (spec AC-11).
///
/// The input frames must share dimensions (the generated live feed does); the
/// result takes its shape and colour space from the first frame. Consumed by
/// CAPTURE-6's multi-frame commit.
Frame averageFrames(List<Frame> frames) {
  final first = frames.first;
  final n = frames.length;
  final pixels = <Pixel>[];
  for (var i = 0; i < first.pixels.length; i++) {
    var sumR = 0;
    var sumG = 0;
    var sumB = 0;
    for (final frame in frames) {
      final p = frame.pixels[i];
      sumR += p.r;
      sumG += p.g;
      sumB += p.b;
    }
    pixels.add(Pixel((sumR / n).round(), (sumG / n).round(), (sumB / n).round()));
  }
  return Frame(
    width: first.width,
    height: first.height,
    pixels: pixels,
    colorSpace: first.colorSpace,
  );
}
