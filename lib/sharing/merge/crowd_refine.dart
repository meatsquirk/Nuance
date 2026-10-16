import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../domain/color_coordinates.dart';
import '../../domain/provenance.dart';
import '../../domain/provenance_derivation.dart';
import '../../domain/sample.dart';

/// The outcome of a crowd-refinement pass over one mapping (bs-14 MERGE-1).
///
/// Carries the (possibly refined) [value] and the [tier] it derives to. The
/// tier is read from the mapping's evidence by bs-13's rule, so peer-contributed
/// evidence — which never contributes to the tier — leaves it at the stored
/// fallback: a crowd-refined estimate stays Estimated and is never promoted to
/// Confirmed (AC-9; SI D2).
@immutable
class RefineResult {
  /// Creates a result from a refined [value] and its derived [tier].
  const RefineResult({required this.value, required this.tier});

  /// The mapping's value after refinement (unchanged in the shell).
  final ColorCoordinates value;

  /// The tier derived from the mapping's evidence — never above Estimated for
  /// peer-contributed evidence (AC-9).
  final ProvenanceTier tier;

  @override
  bool operator ==(Object other) =>
      other is RefineResult && other.value == value && other.tier == tier;

  @override
  int get hashCode => Object.hash(value, tier);

  @override
  String toString() => 'RefineResult($value, ${tier.name})';
}

/// Recomputes an Estimated mapping's value from the clustered peer-contributed
/// evidence behind it, discarding outliers (bs-14 AC-8 / AC-11) — and never
/// promoting the tier above Estimated (AC-9; SI D2).
///
/// The value is recomputed as the **robust central estimate** of the mapping's
/// peer-contributed evidence: outliers are discarded by a standard MAD rule
/// (Iglewicz–Hoaglin modified z-score on each point's distance from the
/// coordinate-wise median) and the estimate is the mean of the surviving
/// cluster — never the plain mean of everything (which an outlier would pull
/// off) and never the stale stored value (which ignores the crowd). bs-14
/// reuses bs-13's evidence model (append-only, source-tagged `EvidencePoint`s —
/// D-6); the estimator itself lives here, since bs-13 exposes a tier rule
/// ([ProvenanceDerivation.tierFor]) but no central-estimate rule to reuse.
///
/// The tier is derived by bs-13's [ProvenanceDerivation.tierFor], which ignores
/// [EvidenceKind.peerContributed], so the crowd can refine the coordinates but
/// never raise the user-facing provenance: a refined value stays at its stored
/// [ProvenanceTier.estimated] fallback.
class CrowdRefine {
  /// Creates a refiner over bs-13's [derivation].
  const CrowdRefine({this.derivation = const ProvenanceDerivation()});

  /// The frozen bs-13 derivation that supplies the tier rule.
  final ProvenanceDerivation derivation;

  /// The modified-z-score threshold above which a point is a statistical
  /// outlier (Iglewicz & Hoaglin's recommended 3.5).
  static const double _outlierThreshold = 3.5;

  /// The modified z-score's consistency constant (0.6745 ≈ the 0.75 quantile of
  /// the standard normal), so the MAD estimates the standard deviation.
  static const double _madConsistency = 0.6745;

  /// Refines a mapping whose stored value is [current] and whose evidence log is
  /// [evidence], keeping its stored [fallback] tier when nothing promotes it.
  ///
  /// When the mapping carries peer-contributed evidence, [value] is recomputed
  /// as the robust central estimate of those records (outliers discarded, AC-8 /
  /// AC-11); with no peer-contributed evidence the stored [current] stands. The
  /// tier is always derived by the frozen bs-13 rule over the full [evidence] —
  /// peer-contributed points never contribute, so the tier stays at [fallback]
  /// (Estimated), and the crowd never promotes a value (AC-9).
  RefineResult refine(
    ColorCoordinates current,
    List<EvidencePoint> evidence, {
    ProvenanceTier fallback = ProvenanceTier.estimated,
  }) {
    final List<ColorCoordinates> crowd = <ColorCoordinates>[
      for (final EvidencePoint point in evidence)
        if (point.kind == EvidenceKind.peerContributed) point.coordinates,
    ];
    return RefineResult(
      value: crowd.isEmpty ? current : _robustCentralEstimate(crowd),
      tier: derivation.tierFor(evidence, fallback: fallback),
    );
  }

  /// The robust central estimate of [points] (at least one): the mean of the
  /// cluster that remains once statistical outliers are discarded.
  ///
  /// With one or two points there is nothing a robust rule can single out, so
  /// the plain mean stands. Otherwise each point's distance from the
  /// coordinate-wise median is scored by the modified z-score; a point past
  /// [_outlierThreshold] is dropped, and the estimate is the mean of the rest.
  /// The median point always scores zero, so at least it survives — the mean is
  /// never taken over an empty set.
  ColorCoordinates _robustCentralEstimate(List<ColorCoordinates> points) {
    if (points.length <= 2) return _mean(points);

    final ColorCoordinates centre = _coordinateWiseMedian(points);
    final List<double> distances = <double>[
      for (final ColorCoordinates p in points) _distance(p, centre),
    ];
    final double medianDistance = _median(distances);
    final double mad = _median(<double>[
      for (final double d in distances) (d - medianDistance).abs(),
    ]);

    final List<ColorCoordinates> inliers = <ColorCoordinates>[];
    for (var i = 0; i < points.length; i++) {
      final double score = mad == 0
          ? 0.0
          : _madConsistency * (distances[i] - medianDistance) / mad;
      if (score <= _outlierThreshold) inliers.add(points[i]);
    }
    return _mean(inliers);
  }

  /// The arithmetic mean of [points] (at least one) on each CIELAB axis.
  ColorCoordinates _mean(List<ColorCoordinates> points) {
    var l = 0.0, a = 0.0, b = 0.0;
    for (final ColorCoordinates p in points) {
      l += p.lightness;
      a += p.a;
      b += p.b;
    }
    final int n = points.length;
    return ColorCoordinates(lightness: l / n, a: a / n, b: b / n);
  }

  /// The coordinate-wise median of [points] (at least one) — the per-axis median
  /// of L, a and b independently. A robust centre an outlier cannot drag off.
  ColorCoordinates _coordinateWiseMedian(List<ColorCoordinates> points) =>
      ColorCoordinates(
        lightness:
            _median(<double>[for (final p in points) p.lightness]),
        a: _median(<double>[for (final p in points) p.a]),
        b: _median(<double>[for (final p in points) p.b]),
      );

  /// The median of [values] (at least one): the middle of the sorted values, or
  /// the mean of the two middle values when the count is even.
  double _median(List<double> values) {
    final List<double> sorted = List<double>.of(values)..sort();
    final int n = sorted.length;
    final int mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// The Euclidean distance between two CIELAB points.
  double _distance(ColorCoordinates x, ColorCoordinates y) {
    final double dl = x.lightness - y.lightness;
    final double da = x.a - y.a;
    final double db = x.b - y.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }
}
