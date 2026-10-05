/// A colour expressed in canonical CIELAB — the single source of truth for a
/// sample's colour.
///
/// All other colour spaces (sRGB, CIELCh, Munsell, …) are *derived* from these
/// L\*, a\*, b\* values by the `ColorScience` layer (COLOR module). This class
/// only holds the canonical coordinates; conversion behaviour is deferred to the
/// COLOR behaviour phases.
class ColorCoordinates {
  const ColorCoordinates({
    required this.lightness,
    required this.a,
    required this.b,
  });

  /// CIELAB L\* — perceptual lightness, nominally 0 (black) to 100 (white).
  final double lightness;

  /// CIELAB a\* — the green(−)/red(+) axis.
  final double a;

  /// CIELAB b\* — the blue(−)/yellow(+) axis.
  final double b;

  @override
  bool operator ==(Object other) =>
      other is ColorCoordinates &&
      other.lightness == lightness &&
      other.a == a &&
      other.b == b;

  @override
  int get hashCode => Object.hash(lightness, a, b);

  @override
  String toString() => 'ColorCoordinates(L $lightness, a $a, b $b)';
}
