// bs-12 AC-16 CONTROL fixture — a planted *offender* (ITEST-2).
//
// This file deliberately computes a colour-space conversion and a CIEDE2000
// (ΔE00) directly, bypassing the two colour authorities (`ColorScience` /
// `lib/color_science/conversions.dart` for conversions, `deltaE00` in
// `lib/compare/difference.dart` for ΔE). It exists ONLY so the AC-16 source
// guard can prove it discriminates: the GUARD-6 scan, pointed at this fixtures
// directory, MUST list this file as a `ruleStrayConversion` offender (the Lab→XYZ
// maths) and a `ruleStrayDeltaE` offender (the CIEDE2000 maths).
//
// It lives under `integration_test/nfr/fixtures/controls/`, NOT under `lib/`, so
// the real AC-16 sweep over `lib/` never sees it — the invariant stays clean.
// It is never imported; the guard reads it as text. Keep it self-contained (no
// import of the real authorities — that is the whole point) and analyze-clean.
//
// Test-support only — no `lib/` product code (D-7).

import 'dart:math' as math;

/// A stray Lab→XYZ conversion computed outside the colour authority.
///
/// This is exactly the kind of maths that must live only behind
/// `ColorScience` / `conversions.dart`; computing it here is the AC-16
/// `ruleStrayConversion` violation the guard must catch.
List<double> strayLabToXyz(double l, double a, double b) {
  final fy = (l + 16.0) / 116.0;
  final fx = fy + a / 500.0;
  final fz = fy - b / 200.0;
  double inv(double t) =>
      t * t * t > 0.008856 ? t * t * t : (t - 16.0 / 116.0) / 7.787;
  // D65 reference white.
  final x = 95.047 * inv(fx);
  final y = 100.0 * inv(fy);
  final z = 108.883 * inv(fz);
  return <double>[x, y, z];
}

/// A stray CIEDE2000 computed outside the ΔE authority (`deltaE00`).
///
/// A second copy of the colour-difference maths is the AC-16 `ruleStrayDeltaE`
/// violation — every feature must route through the single `deltaE00`.
double strayDeltaE00(
  double l1,
  double a1,
  double b1,
  double l2,
  double a2,
  double b2,
) {
  final c1 = math.sqrt(a1 * a1 + b1 * b1);
  final c2 = math.sqrt(a2 * a2 + b2 * b2);
  final meanC = (c1 + c2) / 2.0;
  final g = 0.5 *
      (1.0 - math.sqrt(math.pow(meanC, 7) / (math.pow(meanC, 7) + math.pow(25.0, 7))));
  final a1p = (1.0 + g) * a1;
  final a2p = (1.0 + g) * a2;
  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);
  final dLp = l2 - l1;
  final dCp = c2p - c1p;
  final dhp = 2.0 * math.sqrt(c1p * c2p) * math.sin((b2 - b1) / 2.0);
  return math.sqrt(dLp * dLp + dCp * dCp + dhp * dhp);
}
