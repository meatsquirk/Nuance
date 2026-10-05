import '../domain/color_coordinates.dart';
import '../domain/sample.dart';
import 'color_science.dart';

/// Placeholder [ColorScience] implementation for the shell stage (COLOR-1).
///
/// Every method throws [UnimplementedError]: COLOR-1 only declares the interface
/// and wires the conversions dependency (D-2, `color_models` — its `LabColor`
/// will drive the sRGB / CIELAB / CIELCh maths). The behaviour is filled in
/// later against this same class:
///
/// * COLOR-2 — [toSRGB], [toHex], [toCIELCh], [toMunsell], [toCIELAB],
///   [lightness], [grayscaleOf];
/// * COLOR-3 — [nearestName], [valueWord], [temperatureWord], [decompose].
///
/// Registered into `buildApp` by CORE-3 (registration is deferred out of this
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
  String nearestName(ColorCoordinates lab) =>
      _pending('nearestName', 'COLOR-3');

  @override
  String valueWord(double lightness) => _pending('valueWord', 'COLOR-3');

  @override
  String temperatureWord(double hue) => _pending('temperatureWord', 'COLOR-3');

  @override
  String decompose(Sample sample) => _pending('decompose', 'COLOR-3');
}
