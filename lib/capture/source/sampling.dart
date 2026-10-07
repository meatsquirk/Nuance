import '../../domain/color_coordinates.dart';
import 'frame.dart';

/// The default sampling radius, in pixels (D-7). Area-average sampling covers
/// the disc of this radius unless the painter picks another.
const int kDefaultSamplingRadiusPx = 5;

/// Samples the colour of a single pixel at ([x], [y]) of [frame], as canonical
/// CIELAB.
///
/// Signature only — the pixel read and sRGB→CIELAB conversion land in SOURCE-2.
ColorCoordinates samplePoint(Frame frame, int x, int y) {
  throw UnimplementedError('samplePoint: behaviour lands in SOURCE-2');
}

/// Samples the colour at ([x], [y]) of [frame] as the average over the disc of
/// [radiusPx] (default [kDefaultSamplingRadiusPx]), as canonical CIELAB.
///
/// Signature only — the disc average and conversion land in SOURCE-2.
ColorCoordinates sampleAreaAverage(
  Frame frame,
  int x,
  int y, {
  int radiusPx = kDefaultSamplingRadiusPx,
}) {
  throw UnimplementedError('sampleAreaAverage: behaviour lands in SOURCE-2');
}

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
/// Signature only — the per-pixel mean lands in SOURCE-2 (consumed by
/// CAPTURE-6's multi-frame commit).
Frame averageFrames(List<Frame> frames) {
  throw UnimplementedError('averageFrames: behaviour lands in SOURCE-2');
}
