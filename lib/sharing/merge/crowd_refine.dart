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
/// The estimate reuses bs-13's source-agnostic clustering rule (robust central
/// estimate, outliers discarded); bs-14 adds no new estimator (D-6). The tier is
/// derived by bs-13's [ProvenanceDerivation.tierFor], which ignores
/// [EvidenceKind.peerContributed], so the crowd can refine the coordinates but
/// never raise the user-facing provenance.
///
/// This is the MERGE-1 shell: it wires the derivation and freezes the signature
/// but performs no recompute — [refine] returns [current] unchanged, with the
/// tier derived from the evidence (Estimated for peer-contributed points).
/// MERGE-3 computes the robust central estimate over the clustered records;
/// MERGE-4 proves the never-promote invariant and augments it.
class CrowdRefine {
  /// Creates a refiner over bs-13's [derivation].
  const CrowdRefine({this.derivation = const ProvenanceDerivation()});

  /// The frozen bs-13 derivation that supplies the tier rule.
  final ProvenanceDerivation derivation;

  /// Refines a mapping whose stored value is [current] and whose evidence log is
  /// [evidence], keeping its stored [fallback] tier when nothing promotes it.
  ///
  /// Shell: returns [current] unchanged with the tier derived by the frozen
  /// bs-13 rule — peer-contributed evidence never contributes, so the tier stays
  /// at [fallback] (Estimated). MERGE-3 replaces the value with the robust
  /// central estimate of the clustered records (outliers discarded).
  RefineResult refine(
    ColorCoordinates current,
    List<EvidencePoint> evidence, {
    ProvenanceTier fallback = ProvenanceTier.estimated,
  }) {
    return RefineResult(
      value: current,
      tier: derivation.tierFor(evidence, fallback: fallback),
    );
  }
}
