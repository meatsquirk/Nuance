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

  /// Promotes a value by recording the painter's own measured [swatch], the
  /// enforced promotion rule (AC-9; SI D9).
  ///
  /// With an Estimated value, when the painter records a swatch *of their own
  /// mix* for it — photographed or read with an instrument, both the same
  /// self-confirmation — the value may be promoted to "Confirmed — you measured
  /// this". Recording a swatch of one's own mix is a self-confirmation whatever
  /// device captured it, so [swatch] is appended as an
  /// [EvidenceKind.photographedSwatch] point (keeping its measured
  /// [EvidencePoint.coordinates] and [EvidencePoint.source]) and the tier is
  /// re-derived with [tierFor]. An Estimated value whose only prior evidence is
  /// an LLM seed therefore becomes Confirmed; because it rides on [tierFor], the
  /// earlier evidence is retained (append-only) and never lowers the result.
  ///
  /// This is distinct from a generic instrument reading of some reference, which
  /// derives only Measured ([tierFor], AC-7): it is recording *your own* swatch
  /// that confirms, which is this method — so an own swatch captured by
  /// instrument promotes just as a photographed one does. The self-confirmation
  /// *flow* that captures the swatch is bs-05/capture (D-3); bs-13 owns this
  /// enforced rule. Opinions are never a swatch, so a value given only opinions
  /// is never routed here and never promoted (AC-10).
  ({List<EvidencePoint> evidence, ProvenanceTier tier}) promoteWithOwnSwatch(
    List<EvidencePoint> evidence,
    EvidencePoint swatch, {
    ProvenanceTier fallback = ProvenanceTier.estimated,
  }) {
    final confirmation = EvidencePoint(
      coordinates: swatch.coordinates,
      source: swatch.source,
      kind: EvidenceKind.photographedSwatch,
    );
    final appended = appendEvidence(evidence, confirmation);
    return (evidence: appended, tier: tierFor(appended, fallback: fallback));
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
