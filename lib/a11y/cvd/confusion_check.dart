import 'dart:math' as math;

import '../../compare/difference.dart';
import '../../domain/color_coordinates.dart';
import 'cvd_profile.dart';

/// Decides whether two colours are **confusable** for a given colour-vision
/// profile — the seam behind the comparison's confusion warning (AC-7, AC-8).
///
/// One [ConfusionCheck] is injected app-wide (registered in `buildApp`) so the
/// detector's model lives behind this interface rather than in the comparison
/// screen — the same architectural seam bs-01 uses for `Speech`/`Haptics`. A
/// pair is confusable when it looks **identical to the painter** yet is
/// **clearly different to normal vision**: formally (D-5) the ΔE00 between the
/// two colours *after* the profile's dichromat projection falls below a small
/// threshold while their normal ΔE00 is clearly-different.
///
/// The shipped detector ([DichromatConfusionCheck], CVD-2) is a documented
/// dichromat projection (Viénot 1999 / Brettel–Viénot–Mollon LMS, D-4);
/// **bs-08/bs-10** (display simulation, daltonization) reuse that projection
/// ([projectDichromat]) behind this same interface. [NoopConfusionCheck] stays
/// as the inert option that disables detection.
abstract interface class ConfusionCheck {
  /// Whether colours [a] and [b] are confusable for profile [profile] (D-5).
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile);
}

/// The default [ConfusionCheck]: never flags a pair.
///
/// Wires confusion detection into the assembled app (`AppDependencies`) while
/// the real projection is still unbuilt, so the comparison runs end to end with
/// the detector present but inert. CVD-2 replaces this with the dichromat
/// projection; until then no pair is ever flagged confusable.
class NoopConfusionCheck implements ConfusionCheck {
  const NoopConfusionCheck();

  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile) {
    // Intentionally inert: no projection yet (filled in CVD-2).
    return false;
  }
}

/// The canonical confusion-warning message (AC-7).
///
/// One copy shown by the comparison's confusion region (CVD-2) and spoken as
/// part of the whole comparison (CVD-3), so the on-screen and spoken warnings
/// never drift. Phrased per AC-7: the pair looks *identical* to the painter yet
/// is clearly *different* to others.
const String confusionWarningMessage =
    'These two look identical to you, but are clearly different to others.';

/// The shipped [ConfusionCheck]: a dichromat-projection confusion detector
/// (CVD-2, D-4/D-5).
///
/// A pair is *confusable* when it collapses under the painter's dichromat
/// projection yet stays clearly different to normal vision (D-5):
/// 1. its **normal** ΔE00 is at least [_clearlyDifferentThreshold] — others can
///    tell the two apart (otherwise a "…but clearly different to others"
///    warning would be false); and
/// 2. its ΔE00 **after** [projectDichromat] (how the painter sees each colour)
///    is below [_identicalThreshold] — the painter cannot.
///
/// Both distances use the one shipped CIEDE2000 metric
/// ([deltaE00]); the projection is the Viénot 1999 / Brettel–Viénot–Mollon LMS
/// simulation and lives behind this interface so **bs-08/bs-10** (display
/// simulation, daltonization) reuse it rather than re-derive it. The thresholds
/// sit on the AC-4 verdict bands: a projected ΔE00 below 3 is at most "barely
/// different" to the painter (effectively identical), while a normal ΔE00 of
/// 10+ is "clearly different" to others.
class DichromatConfusionCheck implements ConfusionCheck {
  /// Creates the shipped dichromat-projection detector.
  const DichromatConfusionCheck();

  /// Projected ΔE00 below this ⇒ the pair looks identical to the painter (D-5).
  static const double _identicalThreshold = 3.0;

  /// Normal ΔE00 at or above this ⇒ the pair is clearly different to others.
  static const double _clearlyDifferentThreshold = 10.0;

  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile) {
    if (deltaE00(a, b) < _clearlyDifferentThreshold) return false;
    final projected = deltaE00(
      projectDichromat(a, profile),
      projectDichromat(b, profile),
    );
    return projected < _identicalThreshold;
  }
}

/// How colour [c] appears to a painter with colour-vision [profile] — the
/// Viénot 1999 / Brettel–Viénot–Mollon dichromat simulation (D-4).
///
/// CIELAB → XYZ (D65) → linear sRGB → LMS (Viénot's matrix) → project the
/// missing cone onto the plane of the surviving two → back to CIELAB. The plane
/// is chosen by [CvdProfile.type] (protan drops the L cone, deutan the M, tritan
/// the S). [CvdProfile.severity] blends between the original colour (0) and the
/// full dichromat projection (1), so a partial deficiency sees a partly
/// collapsed colour; bs-03's default profile is a full dichromat (severity 1),
/// the clearest case (D-4), and **bs-07** populates the measured severity.
///
/// Exposed (not private to [DichromatConfusionCheck]) so **bs-08/bs-10** reuse
/// this one projection. The acceptance harness verifies the deutan fixtures
/// against its *own* independent projection, so this shipped one is never graded
/// against itself (AC-7).
ColorCoordinates projectDichromat(ColorCoordinates c, CvdProfile profile) {
  final lms = _mul(_rgb2lms, _mul(_xyz2rgb, _labToXyz(c)));
  final projectedLms = _mul(_planeFor(profile.type), lms);
  final s = profile.severity;
  final blended = <double>[
    for (var i = 0; i < 3; i++) lms[i] + s * (projectedLms[i] - lms[i]),
  ];
  return _xyzToLab(_mul(_rgb2xyz, _mul(_lms2rgb, blended)));
}

/// The LMS projection plane for dichromacy [type] (Viénot 1999).
///
/// Each drops one cone's response onto the plane spanned by the other two: the
/// row for the missing cone reconstructs it from the survivors, the others pass
/// through.
List<List<double>> _planeFor(CvdType type) {
  switch (type) {
    case CvdType.protan:
      return _protanLms;
    case CvdType.deutan:
      return _deutanLms;
    case CvdType.tritan:
      return _tritanLms;
  }
}

// --- Colour-space machinery for [projectDichromat] (Viénot 1999) ------------

// CIELAB (D65) ↔ XYZ, 0..1 scale.
const double _xn = 0.95047, _yn = 1.0, _zn = 1.08883;

List<double> _labToXyz(ColorCoordinates c) {
  final fy = (c.lightness + 16) / 116;
  final fx = fy + c.a / 500;
  final fz = fy - c.b / 200;
  double inv(double t) {
    final t3 = t * t * t;
    return t3 > 0.008856 ? t3 : (t - 16 / 116) / 7.787;
  }

  return [_xn * inv(fx), _yn * inv(fy), _zn * inv(fz)];
}

ColorCoordinates _xyzToLab(List<double> xyz) {
  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  final fx = f(xyz[0] / _xn), fy = f(xyz[1] / _yn), fz = f(xyz[2] / _zn);
  return ColorCoordinates(
    lightness: 116 * fy - 16,
    a: 500 * (fx - fy),
    b: 200 * (fy - fz),
  );
}

List<double> _mul(List<List<double>> m, List<double> v) => [
      for (final row in m) row[0] * v[0] + row[1] * v[1] + row[2] * v[2],
    ];

List<List<double>> _inv3(List<List<double>> m) {
  final a = m[0][0], b = m[0][1], c = m[0][2];
  final d = m[1][0], e = m[1][1], f = m[1][2];
  final g = m[2][0], h = m[2][1], i = m[2][2];
  final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  return [
    [(e * i - f * h) / det, (c * h - b * i) / det, (b * f - c * e) / det],
    [(f * g - d * i) / det, (a * i - c * g) / det, (c * d - a * f) / det],
    [(d * h - e * g) / det, (b * g - a * h) / det, (a * e - b * d) / det],
  ];
}

// Linear sRGB (D65) ↔ XYZ.
const List<List<double>> _rgb2xyz = [
  [0.4124564, 0.3575761, 0.1804375],
  [0.2126729, 0.7151522, 0.0721750],
  [0.0193339, 0.1191920, 0.9503041],
];

// Viénot 1999 LMS from linear sRGB, and the single-plane cone drops in that LMS
// space for each dichromacy (the standard Viénot/BVM coefficients).
const List<List<double>> _rgb2lms = [
  [17.8824, 43.5161, 4.11935],
  [3.45565, 27.1554, 3.86714],
  [0.0299566, 0.184309, 1.46709],
];
const List<List<double>> _protanLms = [
  [0.0, 2.02344, -2.52581],
  [0.0, 1.0, 0.0],
  [0.0, 0.0, 1.0],
];
const List<List<double>> _deutanLms = [
  [1.0, 0.0, 0.0],
  [0.494207, 0.0, 1.24827],
  [0.0, 0.0, 1.0],
];
const List<List<double>> _tritanLms = [
  [1.0, 0.0, 0.0],
  [0.0, 1.0, 0.0],
  [-0.395913, 0.801109, 0.0],
];

final List<List<double>> _xyz2rgb = _inv3(_rgb2xyz);
final List<List<double>> _lms2rgb = _inv3(_rgb2lms);
