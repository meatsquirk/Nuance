import '../domain/color_coordinates.dart';
import '../domain/sample.dart';
import 'color_science.dart';
import 'conversions.dart' as conv;
import 'decomposition.dart' as decomposition;
import 'naming.dart' as naming;
import 'words.dart' as words;

/// The production [ColorScience] implementation.
///
/// Behaviour is filled in against this same class across the COLOR enablers:
///
/// * COLOR-2 — [toSRGB], [toHex], [toCIELCh], [toMunsell], [toCIELAB],
///   [lightness], [grayscaleOf] (colour-space conversions), delegating to the
///   pure functions in `conversions.dart` (`color_models` for sRGB/CIELAB/
///   CIELCh and a bundled calibrated Munsell table — D-2);
/// * COLOR-3 — [nearestName] (naming), [valueWord] / [temperatureWord]
///   (words) and [decompose] (spoken decomposition), delegating to
///   `naming.dart`, `words.dart` and `decomposition.dart`.
///
/// Both enablers have landed, so every member now delegates to its pure
/// conversion/derivation function.
///
/// Registered into `buildApp` by CORE-3 (registration is deferred out of the
/// shell — D-7); construction stays `const`.
class ColorScienceImpl implements ColorScience {
  const ColorScienceImpl();

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
  String nearestName(ColorCoordinates lab) => naming.nearestColorName(lab);

  @override
  String valueWord(double lightness) => words.valueWord(lightness);

  @override
  String temperatureWord(double hue) => words.temperatureWord(hue);

  @override
  String decompose(Sample sample) => decomposition.decompose(sample);
}
