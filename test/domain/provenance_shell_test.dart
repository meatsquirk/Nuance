import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/provenance_derivation.dart';
import 'package:paint_color_assistant/domain/provenance_read_endpoint.dart';
import 'package:paint_color_assistant/domain/sample.dart';

/// PROV-1 shell: the derivation + read-endpoint seams are wired and
/// behaviour-neutral. Real precedence/promotion lands in PROV-2/PROV-3.
void main() {
  const coords = ColorCoordinates(lightness: 58, a: 24, b: 30);
  const measured = EvidencePoint(
    coordinates: coords,
    source: 'spectro',
    kind: EvidenceKind.instrumentMeasured,
  );
  const swatch = EvidencePoint(
    coordinates: coords,
    source: 'own swatch',
    kind: EvidenceKind.photographedSwatch,
  );

  group('ProvenanceDerivation (shell stub)', () {
    // Runtime (non-const) construction so the const constructor is covered.
    // ignore: prefer_const_constructors
    final derivation = ProvenanceDerivation();

    test('tierFor returns the default fallback (estimated) unchanged', () {
      expect(derivation.tierFor(const [measured]), ProvenanceTier.estimated);
    });

    test('tierFor returns an explicit fallback unchanged', () {
      expect(
        derivation.tierFor(const [measured], fallback: ProvenanceTier.measured),
        ProvenanceTier.measured,
      );
    });

    test('appendEvidence appends in order, dropping nothing', () {
      final grown = derivation.appendEvidence(const [measured], swatch);
      expect(grown, [measured, swatch]);
    });

    test('appendEvidence onto an empty list yields the single point', () {
      expect(derivation.appendEvidence(const [], measured), [measured]);
    });
  });

  group('ProvenanceReadEndpoint (observation seam)', () {
    test('exposes the evidence list and the derived tier', () {
      const sample = Sample(
        coordinates: coords,
        provenance: Provenance(ProvenanceTier.measured),
        evidence: [measured],
      );
      const endpoint = ProvenanceReadEndpoint(sample);
      expect(endpoint.evidence, const [measured]);
      // Shell: derivation falls back to the stored tier.
      expect(endpoint.derivedTier, ProvenanceTier.measured);
    });
  });
}
