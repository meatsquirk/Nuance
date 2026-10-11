import '../../color_science/words.dart' show hueFamilyWord;

/// Plain-language phrasing for how a checked mix differs from its target — the
/// verdict band (D-4) and the value-leading decomposition (D-5) the
/// `SubtractiveCorrectionEngine` reads out (bs-05 AC-2/AC-3).
///
/// Pure functions of CIELAB primitives (a lightness gap, a hue angle), so the
/// engine and the difference region share them unchanged — bs-05 owns this band
/// (it does not import bs-03's or bs-04's). CORRECT-2 lands the beyond-tolerance
/// verdict and the value/hue readings; CORRECT-4 adds the within-tolerance "very
/// close" branch when it wires the tolerance short-circuit.

/// The plain-language verdict for a checked mix's perceptual distance [deltaE00]
/// (D-4, G-4b).
///
/// CORRECT-2 lands the beyond-tolerance band: every reading the engine produces
/// here is outside tolerance, so the mix reads "noticeably off". CORRECT-4 adds
/// the within-tolerance "very close" branch keyed on the ΔE00 tolerance;
/// threading [deltaE00] now keeps that extension to this body, not the call site.
String verdictFor(double deltaE00) {
  return 'noticeably off';
}

/// The leading value reading (D-5): how the mixed lightness [mixedLightness]
/// differs from the [targetLightness], as "too dark by N" (the mix is darker),
/// "too light by N" (lighter), or "matched on value" when the gap rounds to
/// zero. N is the rounded L\* gap.
///
/// Value leads the decomposition for a CVD painter, who reads lightness more
/// reliably than hue (D-5): a lower L\* than the target is "too dark", a higher
/// one "too light".
String valueReadingFor(double targetLightness, double mixedLightness) {
  final gap = (targetLightness - mixedLightness).round();
  if (gap > 0) return 'too dark by $gap';
  if (gap < 0) return 'too light by ${-gap}';
  return 'matched on value';
}

/// The hue reading (D-5): how the mixed hue [mixedHueDeg] has shifted from the
/// [targetHueDeg], as `shifted toward <family>` naming the hue family the mix
/// now reads as, or "hue on target" when the shift is negligible.
///
/// The signed hue delta decides whether there is a shift to state; its
/// destination family is the [hueFamilyWord] of the mixed hue (red through
/// magenta).
String hueReadingFor(double mixedHueDeg, double targetHueDeg) {
  final shift = _signedHueDelta(mixedHueDeg, targetHueDeg);
  if (shift.abs() < _hueShiftEpsilonDeg) return 'hue on target';
  return 'shifted toward ${hueFamilyWord(mixedHueDeg)}';
}

/// Below this many degrees of hue shift the mix is read as "hue on target"
/// rather than shifted — a hair of rounding noise is not a hue error.
const double _hueShiftEpsilonDeg = 1.0;

/// The signed shortest-arc hue delta from [b] to [a] (degrees, in (−180, 180]):
/// positive when [a] is counter-clockwise (a higher hue angle) of [b].
double _signedHueDelta(double a, double b) {
  final d = (a - b) % 360.0; // [0, 360)
  return d > 180.0 ? d - 360.0 : d; // (−180, 180]
}
