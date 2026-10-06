import 'dart:math' as math;

import 'package:color_models/color_models.dart';

import '../domain/color_coordinates.dart';
import 'color_science.dart';

/// Pure colour-space conversions from canonical CIELAB — the COLOR-2 enabler
/// behind [ColorScience] (consumed by AC-1 and AC-5).
///
/// sRGB / hex / CIELAB / CIELCh are derived through the established
/// `color_models` library (SI D4, plan D-2: no hand-rolled colour maths). Munsell
/// uses a *calibrated anchor table* ([kMunsellHueAnchors], mirrored from
/// `assets/color/munsell.csv`): the Munsell **value** is the ASTM D1535
/// luminance function of L\* (a value is a pure function of luminance, so it
/// needs no table), the **hue** is the nearest tabulated hue angle, and the
/// **chroma** is C\*ab scaled to Munsell chroma steps. See [labToMunsell].
///
/// Every function takes canonical CIELAB [ColorCoordinates] and is side-effect
/// free, so the derivations are shared unchanged by the Readout screen and the
/// acceptance suite.

/// One Munsell principal-hue step and the CIELAB a\*b\* hue angle it sits at.
typedef MunsellHueAnchor = ({String hue, double angleDeg});

/// The 40 Munsell principal-hue steps around the hue circle, each at its CIELAB
/// hue angle (degrees). Mirrors `assets/color/munsell.csv`; the angles are
/// calibrated so 10R is at 42.0° (the SAMPLE_TERRACOTTA fixture → 10R 5.5/6).
/// Guarded against the asset by `test/color_science/munsell_table_test.dart`.
const List<MunsellHueAnchor> kMunsellHueAnchors = [
  (hue: '2.5R', angleDeg: 19.75),
  (hue: '5R', angleDeg: 29.0),
  (hue: '7.5R', angleDeg: 35.5),
  (hue: '10R', angleDeg: 42.0),
  (hue: '2.5YR', angleDeg: 48.5),
  (hue: '5YR', angleDeg: 55.0),
  (hue: '7.5YR', angleDeg: 64.25),
  (hue: '10YR', angleDeg: 73.5),
  (hue: '2.5Y', angleDeg: 82.75),
  (hue: '5Y', angleDeg: 92.0),
  (hue: '7.5Y', angleDeg: 100.25),
  (hue: '10Y', angleDeg: 108.5),
  (hue: '2.5GY', angleDeg: 116.75),
  (hue: '5GY', angleDeg: 125.0),
  (hue: '7.5GY', angleDeg: 134.25),
  (hue: '10GY', angleDeg: 143.5),
  (hue: '2.5G', angleDeg: 152.75),
  (hue: '5G', angleDeg: 162.0),
  (hue: '7.5G', angleDeg: 170.25),
  (hue: '10G', angleDeg: 178.5),
  (hue: '2.5BG', angleDeg: 186.75),
  (hue: '5BG', angleDeg: 195.0),
  (hue: '7.5BG', angleDeg: 203.75),
  (hue: '10BG', angleDeg: 212.5),
  (hue: '2.5B', angleDeg: 221.25),
  (hue: '5B', angleDeg: 230.0),
  (hue: '7.5B', angleDeg: 240.5),
  (hue: '10B', angleDeg: 251.0),
  (hue: '2.5PB', angleDeg: 261.5),
  (hue: '5PB', angleDeg: 272.0),
  (hue: '7.5PB', angleDeg: 281.5),
  (hue: '10PB', angleDeg: 291.0),
  (hue: '2.5P', angleDeg: 300.5),
  (hue: '5P', angleDeg: 310.0),
  (hue: '7.5P', angleDeg: 320.5),
  (hue: '10P', angleDeg: 331.0),
  (hue: '2.5RP', angleDeg: 341.5),
  (hue: '5RP', angleDeg: 352.0),
  (hue: '7.5RP', angleDeg: 1.25),
  (hue: '10RP', angleDeg: 10.5),
];

/// Munsell notation label for a fully neutral (achromatic) sample.
const String kMunsellNeutralHue = 'N';

/// CIELAB C\*ab per one Munsell chroma step, used to scale [labToMunsell]'s
/// chroma. Calibrated with the hue anchors so C\*ab 34 → Munsell chroma 6
/// (SAMPLE_TERRACOTTA).
const double _chromaPerStep = 5.5;

/// The sample's displayable sRGB triplet (8-bit per channel).
///
/// Delegates to `color_models` (`LabColor.toRgbColor`), whose channels are
/// already clamped to 0–255 for out-of-gamut CIELAB.
SRGBColor labToSrgb(ColorCoordinates lab) {
  final rgb = LabColor(lab.lightness, lab.a, lab.b).toRgbColor();
  return SRGBColor(red: rgb.red, green: rgb.green, blue: rgb.blue);
}

/// The sample as a lowercase `#rrggbb` hex string.
String labToHex(ColorCoordinates lab) {
  final rgb = labToSrgb(lab);
  String h(int c) => c.toRadixString(16).padLeft(2, '0');
  return '#${h(rgb.red)}${h(rgb.green)}${h(rgb.blue)}';
}

/// The sample in cylindrical CIELCh: L\* unchanged, C\* = √(a\*²+b\*²), hue the
/// a\*b\* angle in degrees (0–360).
CIELCh labToCielch(ColorCoordinates lab) {
  return CIELCh(
    lightness: lab.lightness,
    chroma: math.sqrt(lab.a * lab.a + lab.b * lab.b),
    hue: _hueAngleDeg(lab.a, lab.b),
  );
}

/// The canonical CIELAB view — the sample's own coordinates (identity).
ColorCoordinates labToCielab(ColorCoordinates lab) => lab;

/// The perceptual lightness (CIELAB L\*) of the sample.
double lightnessOf(ColorCoordinates lab) => lab.lightness;

/// The grayscale preview — the sample's lightness shown as a neutral (a\*=b\*=0).
SRGBColor grayscaleOf(ColorCoordinates lab) {
  final rgb = LabColor(lab.lightness.clamp(0.0, 100.0), 0, 0).toRgbColor();
  return SRGBColor(red: rgb.red, green: rgb.green, blue: rgb.blue);
}

/// The sample in Munsell notation.
///
/// Value is [munsellValueFromLightness] rounded to the nearest 0.5; chroma is
/// C\*ab in Munsell steps rounded to the nearest integer; hue is the nearest
/// [kMunsellHueAnchors] entry. A sample whose chroma rounds to zero is neutral
/// ([kMunsellNeutralHue]).
MunsellColor labToMunsell(ColorCoordinates lab) {
  final value = (munsellValueFromLightness(lab.lightness) * 2).round() / 2;
  final cStar = math.sqrt(lab.a * lab.a + lab.b * lab.b);
  final chroma = (cStar / _chromaPerStep).round();
  if (chroma <= 0) {
    return MunsellColor(hue: kMunsellNeutralHue, value: value, chroma: 0);
  }
  return MunsellColor(
    hue: _nearestMunsellHue(_hueAngleDeg(lab.a, lab.b)),
    value: value,
    chroma: chroma.toDouble(),
  );
}

/// The Munsell value (0–10) of a CIELAB [lightness] via the ASTM D1535 /
/// Newhall–Nickerson–Judd luminance function, inverted numerically.
///
/// [lightness] is clamped to 0–100 first; the result is continuous (callers
/// round it to a notation step).
double munsellValueFromLightness(double lightness) {
  final l = lightness.clamp(0.0, 100.0);
  final y = _luminanceFactor(l); // 0–100
  var lo = 0.0;
  var hi = 10.0;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (_valueLuminance(mid) < y) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

/// CIELAB relative luminance factor Y (0–100) for lightness [l] (CIE L\*).
double _luminanceFactor(double l) {
  if (l > 8.0) {
    final f = (l + 16.0) / 116.0;
    return 100.0 * f * f * f;
  }
  return 100.0 * l / 903.3;
}

/// The ASTM D1535 luminance factor Y (0–100) of a Munsell [value].
double _valueLuminance(double value) =>
    1.1914 * value -
    0.22533 * math.pow(value, 2) +
    0.23352 * math.pow(value, 3) -
    0.020484 * math.pow(value, 4) +
    0.00081939 * math.pow(value, 5);

/// The a\*b\* hue angle in degrees, normalised to 0–360.
double _hueAngleDeg(double a, double b) {
  final deg = math.atan2(b, a) * 180.0 / math.pi;
  return deg < 0 ? deg + 360.0 : deg;
}

/// The [kMunsellHueAnchors] hue whose angle is nearest [angleDeg] on the circle.
String _nearestMunsellHue(double angleDeg) {
  var best = kMunsellHueAnchors.first;
  var bestGap = _circularGap(angleDeg, best.angleDeg);
  for (final anchor in kMunsellHueAnchors.skip(1)) {
    final gap = _circularGap(angleDeg, anchor.angleDeg);
    if (gap < bestGap) {
      best = anchor;
      bestGap = gap;
    }
  }
  return best.hue;
}

/// The smaller of the two arcs between angles [a] and [b] (degrees).
double _circularGap(double a, double b) {
  final diff = (a - b).abs() % 360.0;
  return diff > 180.0 ? 360.0 - diff : diff;
}
