import 'provenance.dart';
import 'sample.dart';

/// Derives the provenance tier a value should show from the origins of the
/// evidence behind it, and appends new evidence without ever dropping the old
/// (SI D9: "a value's shown tier is derived from its evidence").
///
/// **Tier by origin (PROV-2).** The strongest contributing origin wins, by the
/// precedence `photographedSwatch` → Confirmed · `instrumentMeasured` →
/// Measured · `solverCalculated` → Calculated · `llmSeed` → Estimated. A
/// single-origin value therefore derives exactly its spec tier (AC-7); a mixed
/// set derives the best contributing origin (this is what promotes an estimate
/// on a measured swatch — PROV-3/AC-9). [EvidenceKind.opinion] contributes
/// nothing to the tier (AC-10), and when no origin contributes the value keeps
/// its stored tier (the [tierFor] `fallback`). The append-only contract and the
/// signatures are the ones the PROV-1 shell froze.
class ProvenanceDerivation {
  /// Const so the single shared instance is behaviour-free.
  const ProvenanceDerivation();

  /// The tier derived from [evidence] by origin precedence.
  ///
  /// The strongest contributing origin present wins: a photographed/measured
  /// own swatch → Confirmed, else an instrument measurement → Measured, else a
  /// solver calculation → Calculated, else an LLM seed → Estimated. Opinions
  /// never contribute. When nothing contributes (an empty list, or opinions
  /// only) the value keeps its stored tier, passed as [fallback] — every stored
  /// value carries a tier, so the derived tier is never absent.
  ProvenanceTier tierFor(
    List<EvidencePoint> evidence, {
    ProvenanceTier fallback = ProvenanceTier.estimated,
  }) {
    bool has(EvidenceKind kind) => evidence.any((e) => e.kind == kind);
    if (has(EvidenceKind.photographedSwatch)) return ProvenanceTier.confirmed;
    if (has(EvidenceKind.instrumentMeasured)) return ProvenanceTier.measured;
    if (has(EvidenceKind.solverCalculated)) return ProvenanceTier.calculated;
    if (has(EvidenceKind.llmSeed)) return ProvenanceTier.estimated;
    return fallback;
  }

  /// Append-only: returns [evidence] followed by [point], preserving order and
  /// dropping nothing (SI D9). There is deliberately no remove or replace, so a
  /// value's evidence log is monotonic. The promotion this enables (re-deriving
  /// the tier after appending a measured swatch) is PROV-3; this is the pure
  /// append the PROV-1 shell froze, carried green here (AC-8).
  List<EvidencePoint> appendEvidence(
    List<EvidencePoint> evidence,
    EvidencePoint point,
  ) {
    return [...evidence, point];
  }

  /// The full, user-facing qualifier for [tier] — the spec's exact phrasing
  /// ("Estimated — not yet verified", "Confirmed — you measured this"). Measured
  /// and Calculated carry no qualifier, so their plain [Provenance.label]
  /// stands. This is the only place the qualifier text lives; the existing
  /// [Provenance.label] is unchanged, so the bs-01/bs-06/bs-10 display layer is
  /// untouched.
  String qualifier(ProvenanceTier tier) {
    final label = Provenance(tier).label;
    switch (tier) {
      case ProvenanceTier.measured:
      case ProvenanceTier.calculated:
        return label;
      case ProvenanceTier.estimated:
        return '$label — not yet verified';
      case ProvenanceTier.confirmed:
        return '$label — you measured this';
    }
  }
}
