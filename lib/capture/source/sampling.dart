import 'dart:math' as math;

import 'package:color_models/color_models.dart';

import '../../domain/color_coordinates.dart';
import 'frame.dart';

/// The default sampling radius, in pixels (D-7). Area-average sampling covers
/// the disc of this radius unless the painter picks another.
const int kDefaultSamplingRadiusPx = 5;

// --- Colour-space conversion (SOURCE-2) ------------------------------------
//
// sRGB and Display P3 share the same D65 white point and the same transfer
// curve; they differ only in the primaries, i.e. a single linear-RGB matrix
// (plan D-2, D-7). So converting a wide-gamut (Display P3) frame honestly is
// the sRGB path with one extra linear step: decode the P3 gamma, rotate P3
// linear RGB into sRGB linear RGB, re-encode the gamma, and hand the result to
// the shared `color_models` sRGB→CIELAB path. Reading a P3 buffer as if it were
// sRGB (the SOURCE-1 assumption these functions replace) skips that rotation
// and drifts the measured colour.

/// Display P3 → sRGB, in linear-light RGB, both D65 (ASTC / standard matrix).
const List<List<double>> _p3ToSrgbLinear = [
  [1.2249401762805598, -0.2249401762805601, 0.0],
  [-0.04205697751617889, 1.0420569775161788, 0.0],
  [-0.01963755459033535, -0.07863604555063188, 1.0982736001409672],
];

/// sRGB → Display P3, in linear-light RGB (the inverse of [_p3ToSrgbLinear]):
/// used to render a wide-gamut capture's frames (the encode side).
const List<List<double>> _srgbToP3Linear = [
  [0.822461971910123, 0.177538028089877, 0.0],
  [0.033194216253880, 0.966805783746120, 0.0],
  [0.017082632024306, 0.072397439360779, 0.910519928614916],
];

/// The sRGB/Display-P3 electro-optical transfer: 8-bit-factored channel →
/// linear light. Matches `color_models`' own sRGB linearisation exactly so the
/// sRGB path is unchanged.
double _linearize(double v) => v <= 0.04045
    ? v / 12.92
    : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

/// The inverse transfer: linear light → 8-bit-factored channel.
double _encodeGamma(double v) => v <= 0.0031308
    ? v * 12.92
    : (1.055 * math.pow(v, 1.0 / 2.4) - 0.055).toDouble();

int _toChannel8(double factored) => (factored * 255).round().clamp(0, 255);

/// Applies the linear-RGB [matrix] to a factored-linear RGB triple.
List<double> _applyMatrix(List<List<double>> matrix, List<double> rgb) => [
      matrix[0][0] * rgb[0] + matrix[0][1] * rgb[1] + matrix[0][2] * rgb[2],
      matrix[1][0] * rgb[0] + matrix[1][1] * rgb[1] + matrix[1][2] * rgb[2],
      matrix[2][0] * rgb[0] + matrix[2][1] * rgb[1] + matrix[2][2] * rgb[2],
    ];

/// Rotates [pixel]'s channels from [from] into [to] primaries (identity when
/// the two spaces match): gamma-decode, apply the linear matrix, gamma-encode.
Pixel _rotatePrimaries(
  Pixel pixel,
  List<List<double>> matrix,
) {
  final linear = _applyMatrix(matrix, [
    _linearize(pixel.r / 255),
    _linearize(pixel.g / 255),
    _linearize(pixel.b / 255),
  ]);
  return Pixel(
    _toChannel8(_encodeGamma(linear[0])),
    _toChannel8(_encodeGamma(linear[1])),
    _toChannel8(_encodeGamma(linear[2])),
  );
}

/// Re-expresses an sRGB [pixel] in [space]'s channels (identity for sRGB).
///
/// The feed renders a capture by encoding its ground-truth colour as sRGB and
/// then, on a wide-gamut device, rotating it into Display P3 so the buffer the
/// source yields is a genuine P3 buffer (SOURCE-2) — not sRGB bits mislabelled.
Pixel encodeFromSrgb(Pixel pixel, FrameColorSpace space) => switch (space) {
      FrameColorSpace.srgb => pixel,
      FrameColorSpace.displayP3 => _rotatePrimaries(pixel, _srgbToP3Linear),
    };

/// Converts a raw device [pixel] expressed in [space] to canonical CIELAB.
///
/// Reuses the established `color_models` library (plan D-2) — the same library
/// bs-01's colour-science delegates to for the inverse (CIELAB→sRGB) direction —
/// for the sRGB→CIELAB leg; a Display P3 pixel is first rotated into sRGB
/// primaries ([_p3ToSrgbLinear]) so the wide-gamut capture converts honestly
/// rather than being read as if it were sRGB (SOURCE-2).
ColorCoordinates _pixelToLab(Pixel pixel, FrameColorSpace space) {
  final srgb = switch (space) {
    FrameColorSpace.srgb => pixel,
    FrameColorSpace.displayP3 => _rotatePrimaries(pixel, _p3ToSrgbLinear),
  };
  final lab = RgbColor(srgb.r, srgb.g, srgb.b).toLabColor();
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
    _pixelToLab(frame.pixelAt(x, y), frame.colorSpace);

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
    _pixelToLab(_averagePixel(frame, x, y, radiusPx), frame.colorSpace);

/// Samples the colour at ([x], [y]) of an imported photo [image] as the average
/// over the disc of [radiusPx] (default [kDefaultSamplingRadiusPx]), as
/// canonical CIELAB (AC-9).
///
/// The photo arrives already decoded as a [Frame] (the import flow decodes the
/// gallery image into one), so sampling it is the same pure area-average as a
/// live-feed read — taken here over the imported pixels at the chosen point P,
/// not the frame centre. Reading point P is what distinguishes an imported
/// sample from a live-camera one.
ColorCoordinates sampleFromPhoto(
  Frame image,
  int x,
  int y, {
  int radiusPx = kDefaultSamplingRadiusPx,
}) =>
    sampleAreaAverage(image, x, y, radiusPx: radiusPx);

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
