import '../domain/color_coordinates.dart';
import '../domain/sample.dart';
import 'color_science.dart';
import 'decomposition.dart' as decomposition;
import 'naming.dart' as naming;
import 'words.dart' as words;

/// The production [ColorScience] implementation.
///
/// Behaviour is filled in against this same class across the COLOR enablers:
///
/// * COLOR-2 — [toSRGB], [toHex], [toCIELCh], [toMunsell], [toCIELAB],
///   [lightness], [grayscaleOf] (conversions, via `color_models`);
/// * COLOR-3 — [nearestName] (naming), [valueWord] / [temperatureWord]
///   (words) and [decompose] (spoken decomposition), delegating to
///   `naming.dart`, `words.dart` and `decomposition.dart`.
///
/// Members whose enabler has not landed yet throw [UnimplementedError] via
/// [_pending], naming the phase that fills them.
///
/// Registered into `buildApp` by CORE-3 (registration is deferred out of the
/// shell — D-7).
class ColorScienceImpl implements ColorScience {
  const ColorScienceImpl();

  /// Signals that [member] is not built yet and names the phase that builds it.
  static Never _pending(String member, String phase) =>
      throw UnimplementedError('ColorScience.$member is implemented in $phase.');

  @override
  SRGBColor toSRGB(ColorCoordinates lab) => _pending('toSRGB', 'COLOR-2');

  @override
  String toHex(ColorCoordinates lab) => _pending('toHex', 'COLOR-2');

  @override
  CIELCh toCIELCh(ColorCoordinates lab) => _pending('toCIELCh', 'COLOR-2');

  @override
  MunsellColor toMunsell(ColorCoordinates lab) =>
      _pending('toMunsell', 'COLOR-2');

  @override
  ColorCoordinates toCIELAB(ColorCoordinates lab) =>
      _pending('toCIELAB', 'COLOR-2');

  @override
  double lightness(ColorCoordinates lab) => _pending('lightness', 'COLOR-2');

  @override
  SRGBColor grayscaleOf(ColorCoordinates lab) =>
      _pending('grayscaleOf', 'COLOR-2');

  @override
  String nearestName(ColorCoordinates lab) => naming.nearestColorName(lab);

  @override
  String valueWord(double lightness) => words.valueWord(lightness);

  @override
  String temperatureWord(double hue) => words.temperatureWord(hue);

  @override
  String decompose(Sample sample) => decomposition.decompose(sample);
}
