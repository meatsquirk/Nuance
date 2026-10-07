/// A single captured frame: a colour buffer tagged with its colour space.
///
/// A [CaptureSource] yields a stream of these (SI D2). Sampling (see
/// `sampling.dart`) reads pixels out of a frame and averages them; the pixel
/// values are raw device channels in the frame's [colorSpace], converted to
/// canonical CIELAB by the sampling layer (bs-01 color-science) — this model
/// holds the buffer only, no conversion behaviour.
library;

/// The colour space a [Frame]'s pixel channels are expressed in.
///
/// Sampling converts from this space to canonical CIELAB; which space the
/// device delivered is recorded so the conversion is correct (SOURCE-2).
enum FrameColorSpace {
  /// Standard sRGB (the common camera / gallery default).
  srgb,

  /// Display P3 (wide-gamut capture on capable devices).
  displayP3,
}

/// A single sRGB-style pixel: three 8-bit channels (0–255).
///
/// Held by a [Frame]'s buffer. The channels are raw device values in the
/// frame's [FrameColorSpace]; conversion to CIELAB is the sampling layer's job.
class Pixel {
  const Pixel(this.r, this.g, this.b);

  /// Red channel, 0–255.
  final int r;

  /// Green channel, 0–255.
  final int g;

  /// Blue channel, 0–255.
  final int b;

  @override
  bool operator ==(Object other) =>
      other is Pixel && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'Pixel($r, $g, $b)';
}

/// A row-major colour buffer of [width] × [height] [Pixel]s, tagged with the
/// [colorSpace] its channels are expressed in.
///
/// Frames are compared through the colours sampled out of them, not
/// structurally, so this class deliberately keeps identity equality.
class Frame {
  const Frame({
    required this.width,
    required this.height,
    required this.pixels,
    this.colorSpace = FrameColorSpace.srgb,
  });

  /// Buffer width in pixels.
  final int width;

  /// Buffer height in pixels.
  final int height;

  /// The pixels, row-major: index `y * width + x`.
  final List<Pixel> pixels;

  /// The colour space the pixel channels are expressed in.
  final FrameColorSpace colorSpace;

  /// The pixel at column [x], row [y] (row-major lookup).
  Pixel pixelAt(int x, int y) => pixels[y * width + x];

  @override
  String toString() =>
      'Frame(${width}x$height, ${colorSpace.name}, ${pixels.length} px)';
}
