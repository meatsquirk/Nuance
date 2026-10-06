import '../domain/color_coordinates.dart';
import '../domain/sample.dart';
import 'color_science.dart';
import 'conversions.dart' as conv;

/// The [ColorScience] implementation.
///
/// The colour-space conversions ([toSRGB], [toHex], [toCIELCh], [toMunsell],
/// [toCIELAB], [lightness], [grayscaleOf]) delegate to the pure functions in
/// `conversions.dart` (COLOR-2; `color_models` for sRGB/CIELAB/CIELCh and a
/// bundled calibrated Munsell table — D-2). The plain-language derivations
/// ([nearestName], [valueWord], [temperatureWord], [decompose]) are still
/// pending COLOR-3.
///
/// Registered into `buildApp` by CORE-3 (D-7); construction stays `const`.
class ColorScienceImpl implements ColorScience {
  const ColorScienceImpl();

  /// Signals that [member] is not built yet and names the phase that builds it.
  static Never _pending(String member, String phase) =>
      throw UnimplementedError('ColorScience.$member is implemented in $phase.');

  @override
  SRGBColor toSRGB(ColorCoordinates lab) => conv.labToSrgb(lab);

  @override
  String toHex(ColorCoordinates lab) => conv.labToHex(lab);

  @override
  CIELCh toCIELCh(ColorCoordinates lab) => conv.labToCielch(lab);

  @override
  MunsellColor toMunsell(ColorCoordinates lab) => conv.labToMunsell(lab);

  @override
  ColorCoordinates toCIELAB(ColorCoordinates lab) => conv.labToCielab(lab);

  @override
  double lightness(ColorCoordinates lab) => conv.lightnessOf(lab);

  @override
  SRGBColor grayscaleOf(ColorCoordinates lab) => conv.grayscaleOf(lab);

  @override
  String nearestName(ColorCoordinates lab) =>
      _pending('nearestName', 'COLOR-3');

  @override
  String valueWord(double lightness) => _pending('valueWord', 'COLOR-3');

  @override
  String temperatureWord(double hue) => _pending('temperatureWord', 'COLOR-3');

  @override
  String decompose(Sample sample) => _pending('decompose', 'COLOR-3');
}
