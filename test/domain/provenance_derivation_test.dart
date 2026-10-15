import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/provenance_derivation.dart';
import 'package:paint_color_assistant/domain/provenance_read_endpoint.dart';
import 'package:paint_color_assistant/domain/sample.dart';

/// PROV-2: `tierFor` derives a value's tier from the origins of its evidence by
/// precedence, opinions never contribute, and when nothing contributes the
/// stored tier stands. The append-only add (frozen in the PROV-1 shell) and the
/// read endpoint are carried green here. (The AC-7 acceptance test lives in
/// `integration_test/bs13/dataset_test.dart`; this is the unit coverage.)
void main() {
  const coords = ColorCoordinates(lightness: 58, a: 24, b: 30);
  const measured = EvidencePoint(
    coordinates: coords,
    source: 'spectro',
    kind: EvidenceKind.instrumentMeasured,
  );
  const solver = EvidencePoint(
    coordinates: coords,
    source: 'mix-solver',
    kind: EvidenceKind.solverCalculated,
  );
  const seed = EvidencePoint(
    coordinates: coords,
    source: 'llm-seed',
    kind: EvidenceKind.llmSeed,
  );
  const swatch = EvidencePoint(
    coordinates: coords,
    source: 'own swatch',
    kind: EvidenceKind.photographedSwatch,
  );
  const opinion = EvidencePoint(
    coordinates: coords,
    source: 'opinion',
    kind: EvidenceKind.opinion,
  );

  group('ProvenanceDerivation.tierFor — tier by origin', () {
    // Runtime (non-const) construction so the const constructor is covered.
    // ignore: prefer_const_constructors
    final derivation = ProvenanceDerivation();

    test('a photographed swatch derives Confirmed', () {
      expect(derivation.tierFor(const [swatch]), ProvenanceTier.confirmed);
    });

    test('an instrument measurement derives Measured', () {
      expect(derivation.tierFor(const [measured]), ProvenanceTier.measured);
    });

    test('a solver calculation derives Calculated', () {
      expect(derivation.tierFor(const [solver]), ProvenanceTier.calculated);
    });

    test('an LLM seed derives Estimated', () {
      expect(derivation.tierFor(const [seed]), ProvenanceTier.estimated);
    });

    test('no contributing origin keeps the stored tier (the fallback)', () {
      // Empty evidence, and opinion-only, both fall back to the stored tier —
      // a non-default fallback proves the answer is the fallback, not a constant.
      expect(derivation.tierFor(const [], fallback: ProvenanceTier.calculated),
          ProvenanceTier.calculated);
      expect(
          derivation.tierFor(const [opinion], fallback: ProvenanceTier.measured),
          ProvenanceTier.measured);
      // The default fallback is Estimated.
      expect(derivation.tierFor(const [opinion]), ProvenanceTier.estimated);
    });

    test('precedence: the strongest contributing origin wins in a mixed set',
        () {
      // A swatch beats everything (drives AC-9 promotion).
      expect(derivation.tierFor(const [seed, opinion, swatch]),
          ProvenanceTier.confirmed);
      // Without a swatch, an instrument measurement beats solver + seed.
      expect(derivation.tierFor(const [seed, solver, measured]),
          ProvenanceTier.measured);
      // Without measured/swatch, the solver beats a seed.
      expect(
          derivation.tierFor(const [seed, solver]), ProvenanceTier.calculated);
    });

    test('an opinion alongside a stronger origin does not lower the tier', () {
      // Opinion is inert, not negative: a seed + opinion is still Estimated, and
      // a measurement + opinion is still Measured.
      expect(
          derivation.tierFor(const [seed, opinion]), ProvenanceTier.estimated);
      expect(derivation.tierFor(const [measured, opinion]),
          ProvenanceTier.measured);
    });
  });

  group('ProvenanceDerivation.qualifier — full user-facing qualifier', () {
    const derivation = ProvenanceDerivation();

    test('Estimated and Confirmed carry the spec qualifier', () {
      expect(derivation.qualifier(ProvenanceTier.estimated),
          'Estimated — not yet verified');
      expect(derivation.qualifier(ProvenanceTier.confirmed),
          'Confirmed — you measured this');
    });

    test('Measured and Calculated carry no qualifier (plain label)', () {
      expect(derivation.qualifier(ProvenanceTier.measured), 'Measured');
      expect(derivation.qualifier(ProvenanceTier.calculated), 'Calculated');
    });
  });

  group('ProvenanceDerivation.appendEvidence — append-only', () {
    const derivation = ProvenanceDerivation();

    test('appends in order, dropping nothing', () {
      final grown = derivation.appendEvidence(const [measured], swatch);
      expect(grown, [measured, swatch]);
    });

    test('appending onto an empty list yields the single point', () {
      expect(derivation.appendEvidence(const [], measured), [measured]);
    });
  });

  group('ProvenanceReadEndpoint surfaces the derived tier', () {
    test('a value stored Estimated but backed by a measurement reads Measured',
        () {
      const sample = Sample(
        coordinates: coords,
        provenance: Provenance(ProvenanceTier.estimated),
        evidence: [measured],
      );
      const endpoint = ProvenanceReadEndpoint(sample);
      expect(endpoint.evidence, const [measured]);
      expect(endpoint.derivedTier, ProvenanceTier.measured);
    });

    test('with no contributing evidence the stored tier stands', () {
      const sample = Sample(
        coordinates: coords,
        provenance: Provenance(ProvenanceTier.calculated),
        evidence: [opinion],
      );
      const endpoint = ProvenanceReadEndpoint(sample);
      expect(endpoint.derivedTier, ProvenanceTier.calculated);
    });
  });
}
