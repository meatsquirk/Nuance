import '../domain/color_coordinates.dart';
import '../domain/sample.dart';

/// An sRGB colour as 8-bit red/green/blue channels (0–255).
///
/// The displayable triplet derived from a sample's canonical CIELAB colour; the
/// hex string is produced separately by [ColorScience.toHex]. Conversion
/// behaviour lands in COLOR-2 — this is only the shape the readout and the
/// acceptance tests consume (AC-5).
class SRGBColor {
  const SRGBColor({required this.red, required this.green, required this.blue});

  /// Red channel, 0–255.
  final int red;

  /// Green channel, 0–255.
  final int green;

  /// Blue channel, 0–255.
  final int blue;

  @override
  bool operator ==(Object other) =>
      other is SRGBColor &&
      other.red == red &&
      other.green == green &&
      other.blue == blue;

  @override
  int get hashCode => Object.hash(red, green, blue);

  @override
  String toString() => 'SRGBColor($red, $green, $blue)';
}

/// A colour in cylindrical CIELCh — [lightness] (L\*), [chroma] (C\*) and [hue]
/// angle in degrees — the derived view AC-5 shows for the LCh space.
class CIELCh {
  const CIELCh({
    required this.lightness,
    required this.chroma,
    required this.hue,
  });

  /// CIELCh L\* — perceptual lightness, nominally 0 (black) to 100 (white).
  final double lightness;

  /// CIELCh C\* — chroma (distance from the neutral axis).
  final double chroma;

  /// CIELCh h — hue angle in degrees (0–360).
  final double hue;

  @override
  bool operator ==(Object other) =>
      other is CIELCh &&
      other.lightness == lightness &&
      other.chroma == chroma &&
      other.hue == hue;

  @override
  int get hashCode => Object.hash(lightness, chroma, hue);

  @override
  String toString() => 'CIELCh(L $lightness, C $chroma, h $hue)';
}

/// A colour in Munsell notation: a [hue] string (e.g. "10R"), a [value]
/// (Munsell lightness, 0–10) and a [chroma]. [notation] renders the familiar
/// "10R 5.5/6" form AC-5 shows for the Munsell space, and AC-1 reads the value
/// from.
class MunsellColor {
  const MunsellColor({
    required this.hue,
    required this.value,
    required this.chroma,
  });

  /// The Munsell hue, e.g. "10R".
  final String hue;

  /// The Munsell value (lightness), 0 (black) to 10 (white).
  final double value;

  /// The Munsell chroma (colour strength).
  final double chroma;

  /// The combined Munsell notation, e.g. `10R 5.5/6`.
  String get notation => '$hue $value/$chroma';

  @override
  bool operator ==(Object other) =>
      other is MunsellColor &&
      other.hue == hue &&
      other.value == value &&
      other.chroma == chroma;

  @override
  int get hashCode => Object.hash(hue, value, chroma);

  @override
  String toString() => 'MunsellColor($notation)';
}

/// Derives every presentable form of a sample's colour from its canonical
/// CIELAB coordinates: the other colour spaces (AC-5), the prominent lightness
/// and grayscale preview (AC-1), the plain-language name (AC-3), the value and
/// temperature words (AC-2, AC-4) and the spoken decomposition (AC-8).
///
/// Kept behind this interface so the conversions library (D-2, `color_models`,
/// whose `LabColor` drives the sRGB / CIELAB / CIELCh maths) stays swappable
/// (SI D4 maintainability). Implemented by [ColorScienceImpl]: behaviour lands
/// in COLOR-2 (conversions, [lightness], [grayscaleOf]) and COLOR-3
/// ([nearestName], [valueWord], [temperatureWord], [decompose]).
abstract interface class ColorScience {
  /// The sample colour as an sRGB triplet.
  SRGBColor toSRGB(ColorCoordinates lab);

  /// The sample colour as a `#RRGGBB` hex string.
  String toHex(ColorCoordinates lab);

  /// The sample colour in cylindrical CIELCh.
  CIELCh toCIELCh(ColorCoordinates lab);

  /// The sample colour in Munsell notation (including the Munsell value).
  MunsellColor toMunsell(ColorCoordinates lab);

  /// The sample colour in CIELAB (the canonical view).
  ColorCoordinates toCIELAB(ColorCoordinates lab);

  /// The perceptual lightness (CIELAB L\*) of the sample.
  double lightness(ColorCoordinates lab);

  /// The grayscale preview of the sample — its lightness shown as a neutral.
  SRGBColor grayscaleOf(ColorCoordinates lab);

  /// The nearest plain-language (ISCC-NBS) colour name for the sample.
  String nearestName(ColorCoordinates lab);

  /// A plain-language value word (e.g. "middle value") for a lightness.
  String valueWord(double lightness);

  /// A plain-language temperature word (e.g. "warm") for a hue angle.
  String temperatureWord(double hue);

  /// A spoken relational statement decomposing the whole sample readout
  /// (name, value, temperature, hue in words, chroma, hue angle) for AC-8.
  String decompose(Sample sample);
}
