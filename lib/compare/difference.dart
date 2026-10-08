import 'dart:math' as math;

import '../domain/color_coordinates.dart';
import '../domain/sample.dart';

/// Comparison colour science: the relational difference between two samples
/// (the DIFF module behind AC-4, AC-5 and AC-6).
///
/// The overall difference is **CIEDE2000 ΔE00** (D-2) — the same tested metric
/// used elsewhere, promoted to product code behind [compare] rather than
/// re-derived ad hoc. The relational statement is phrased in **LCh space**
/// (D-3): ΔL\* → the lightness line, ΔC\*ab → the saturation line and Δh° → the
/// hue line, each naming a direction and magnitude (or "Same …" when the
/// rounded delta is zero). This is distinct from bs-01's single-sample
/// `decompose`, which is unchanged.
///
/// DIFF-2 fills the overall difference — the CIEDE2000 [_deltaE00] and its
/// plain-language [_verdictBand] (AC-4). The three LCh dimension lines remain
/// DIFF-3 placeholders (AC-5, AC-6).

/// The relational comparison of two [Sample]s.
///
/// Carries the overall [deltaE00] (D-2; AC-4) with its plain-language [verdict]
/// band (AC-4), and the three LCh decomposition lines — [lightness], the
/// [saturation] (chroma) line and [hue] (D-3; AC-5, AC-6).
class Comparison {
  const Comparison({
    required this.deltaE00,
    required this.verdict,
    required this.lightness,
    required this.saturation,
    required this.hue,
  });

  /// CIEDE2000 ΔE00 between the two samples (D-2; AC-4).
  final double deltaE00;

  /// The plain-language verdict band for [deltaE00] (AC-4), e.g. "clearly
  /// different".
  final String verdict;

  /// The lightness line of the LCh decomposition (D-3; AC-5/AC-6), e.g.
  /// "Lighter by 12" or "Same lightness".
  final String lightness;

  /// The saturation (chroma) line of the LCh decomposition (D-3; AC-5/AC-6),
  /// e.g. "Less saturated by 9" or "Same saturation".
  final String saturation;

  /// The hue line of the LCh decomposition (D-3; AC-5/AC-6), e.g. "Hue shifted
  /// 18 degrees toward yellow" or "Same hue".
  final String hue;

  @override
  bool operator ==(Object other) =>
      other is Comparison &&
      other.deltaE00 == deltaE00 &&
      other.verdict == verdict &&
      other.lightness == lightness &&
      other.saturation == saturation &&
      other.hue == hue;

  @override
  int get hashCode =>
      Object.hash(deltaE00, verdict, lightness, saturation, hue);

  @override
  String toString() =>
      'Comparison(ΔE00 $deltaE00, $verdict; $lightness, $saturation, $hue)';
}

/// Compares sample [a] against sample [b], returning their overall difference
/// and relational decomposition (AC-4, AC-5, AC-6).
///
/// The overall [Comparison.deltaE00] / [Comparison.verdict] are real (DIFF-2);
/// the three LCh lines are DIFF-3 placeholders until that phase lands.
Comparison compare(Sample a, Sample b) {
  final delta = _deltaE00(a, b);
  return Comparison(
    deltaE00: delta,
    verdict: _verdictBand(delta),
    lightness: _lightnessLine(a, b),
    saturation: _saturationLine(a, b),
    hue: _hueLine(a, b),
  );
}

/// The plain-language verdict band edges for a ΔE00 value (AC-4), in ascending
/// order. Each entry pairs the exclusive upper bound of a band with the word
/// shown for a ΔE00 below it; a value at or above the last bound is
/// [_verdictAbove]. Perceptual guide (D-2): ΔE00 ≈ 1 is a just-noticeable
/// difference, so below 1 reads as no visible difference; the upper bands mark
/// a small, an obvious and a very large separation.
const List<(double, String)> _verdictBands = [
  (1.0, 'no visible difference'),
  (3.0, 'barely different'),
  (10.0, 'slightly different'),
  (50.0, 'clearly different'),
];

/// The verdict for a ΔE00 at or above the largest [_verdictBands] bound.
const String _verdictAbove = 'very different';

/// The plain-language verdict band for a ΔE00 value (AC-4).
///
/// At least two bands, so the verdict tracks the distance rather than being a
/// constant string (the DIFF-2 augmentation on `TestAC04` proves this with a
/// nearer control pair that reads a lower band).
String _verdictBand(double deltaE00) {
  for (final (bound, word) in _verdictBands) {
    if (deltaE00 < bound) return word;
  }
  return _verdictAbove;
}

/// CIEDE2000 ΔE00 between [a] and [b] (D-2; AC-4).
///
/// The shipped colour-difference metric, implementing Sharma, Wu & Dalal (2005)
/// over the samples' canonical CIELAB coordinates. The acceptance suite grades
/// it against an independent reference implementation
/// (`integration_test/comparison_harness.dart`'s `referenceDeltaE00`), so the
/// product is never checked against itself.
double _deltaE00(Sample a, Sample b) =>
    deltaE00(a.coordinates, b.coordinates);

/// CIEDE2000 ΔE00 between two CIELAB coordinates [a] and [b] (D-2).
///
/// The one shipped colour-difference metric over raw coordinates — the same
/// CIEDE2000 [compare] uses. Exposed so the confusion detector (CVD-2) can judge
/// a pair's distance — both normally and after the dichromat projection — with
/// this single tested metric rather than a second ad-hoc copy.
double deltaE00(ColorCoordinates a, ColorCoordinates b) => _ciede2000(a, b);

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// CIEDE2000 colour difference between two CIELAB coordinates (D-2).
double _ciede2000(ColorCoordinates x, ColorCoordinates y) {
  const kL = 1.0, kC = 1.0, kH = 1.0;
  final l1 = x.lightness, a1 = x.a, b1 = x.b;
  final l2 = y.lightness, a2 = y.a, b2 = y.b;

  final c1 = math.sqrt(a1 * a1 + b1 * b1);
  final c2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar = (c1 + c2) / 2.0;

  final cBar7 = math.pow(cBar, 7).toDouble();
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25.0, 7))));

  final a1p = (1 + g) * a1;
  final a2p = (1 + g) * a2;

  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);

  double h1p = (a1p == 0 && b1 == 0) ? 0.0 : _deg(math.atan2(b1, a1p));
  if (h1p < 0) h1p += 360.0;
  double h2p = (a2p == 0 && b2 == 0) ? 0.0 : _deg(math.atan2(b2, a2p));
  if (h2p < 0) h2p += 360.0;

  final dLp = l2 - l1;
  final dCp = c2p - c1p;

  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0.0;
  } else {
    final diff = h2p - h1p;
    if (diff.abs() <= 180) {
      dhp = diff;
    } else if (diff > 180) {
      dhp = diff - 360;
    } else {
      dhp = diff + 360;
    }
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_rad(dhp / 2.0));

  final lBarp = (l1 + l2) / 2.0;
  final cBarp = (c1p + c2p) / 2.0;

  double hBarp;
  if (c1p * c2p == 0) {
    hBarp = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarp = (h1p + h2p) / 2.0;
  } else if (h1p + h2p < 360) {
    hBarp = (h1p + h2p + 360) / 2.0;
  } else {
    hBarp = (h1p + h2p - 360) / 2.0;
  }

  final t = 1 -
      0.17 * math.cos(_rad(hBarp - 30)) +
      0.24 * math.cos(_rad(2 * hBarp)) +
      0.32 * math.cos(_rad(3 * hBarp + 6)) -
      0.20 * math.cos(_rad(4 * hBarp - 63));

  final dTheta = 30 * math.exp(-math.pow((hBarp - 275) / 25.0, 2).toDouble());
  final cBarp7 = math.pow(cBarp, 7).toDouble();
  final rc = 2 * math.sqrt(cBarp7 / (cBarp7 + math.pow(25.0, 7)));
  final rt = -rc * math.sin(_rad(2 * dTheta));

  final sl = 1 +
      (0.015 * math.pow(lBarp - 50, 2)) /
          math.sqrt(20 + math.pow(lBarp - 50, 2));
  final sc = 1 + 0.045 * cBarp;
  final sh = 1 + 0.015 * cBarp * t;

  final termL = dLp / (kL * sl);
  final termC = dCp / (kC * sc);
  final termH = dHp / (kH * sh);

  return math.sqrt(
      termL * termL + termC * termC + termH * termH + rt * termC * termH);
}

/// The LCh lightness line, ΔL\* in words (D-3). Stub — filled by DIFF-3 (AC-5).
String _lightnessLine(Sample a, Sample b) => '';

/// The LCh saturation line, ΔC\*ab in words (D-3). Stub — filled by DIFF-3
/// (AC-5).
String _saturationLine(Sample a, Sample b) => '';

/// The LCh hue line, Δh° in words with a direction family (D-3). Stub — filled
/// by DIFF-3 (AC-5, AC-6).
String _hueLine(Sample a, Sample b) => '';
