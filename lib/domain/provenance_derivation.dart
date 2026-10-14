import 'provenance.dart';
import 'sample.dart';

/// Derives the provenance tier a value should show from the origins of the
/// evidence behind it, and appends new evidence without ever dropping the old
/// (SI D9: "a value's shown tier is derived from its evidence").
///
/// **Shell stub (PROV-1).** The real precedence by origin —
/// `photographedSwatch` → Confirmed · `instrumentMeasured` → Measured ·
/// `solverCalculated` → Calculated · `llmSeed` → Estimated, with
/// [EvidenceKind.opinion] never contributing (AC-7/AC-9/AC-10) — lands in
/// PROV-2. Until then [tierFor] returns the caller's [fallback] unchanged, so
/// no existing flow's behaviour shifts. The seam (signatures, append-only
/// contract) is frozen here for the acceptance suite and PROV-2/PROV-3.
class ProvenanceDerivation {
  /// Const so the single shared instance is behaviour-free.
  const ProvenanceDerivation();

  /// The tier derived from [evidence].
  ///
  /// Shell: returns [fallback] (the value's currently stored tier) unchanged.
  /// PROV-2 replaces the body with the origin precedence; the signature is
  /// stable — callers pass the stored tier as [fallback] for the empty /
  /// opinion-only case, which must still carry a tier.
  ProvenanceTier tierFor(
    List<EvidencePoint> evidence, {
    ProvenanceTier fallback = ProvenanceTier.estimated,
  }) {
    return fallback;
  }

  /// Append-only: returns [evidence] followed by [point], preserving order and
  /// dropping nothing (SI D9). There is deliberately no remove or replace. The
  /// re-derivation that this enables (promotion on a measured swatch) is
  /// PROV-2/PROV-3; this is the pure append the shell freezes.
  List<EvidencePoint> appendEvidence(
    List<EvidencePoint> evidence,
    EvidencePoint point,
  ) {
    return [...evidence, point];
  }
}
