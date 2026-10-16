import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/merge/crowd_refine.dart';

EvidencePoint _peer(String source) => EvidencePoint(
      coordinates: const ColorCoordinates(lightness: 42, a: 3, b: -2),
      source: source,
      kind: EvidenceKind.peerContributed,
    );

void main() {
  group('RefineResult', () {
    const value = ColorCoordinates(lightness: 50, a: 10, b: -5);

    test('carries its value and tier', () {
      final result =
          RefineResult(value: value, tier: ProvenanceTier.estimated);
      expect(result.value, value);
      expect(result.tier, ProvenanceTier.estimated);
    });

    test('is value-equal and hashes by value and tier', () {
      final a = RefineResult(value: value, tier: ProvenanceTier.estimated);
      final sameAsA =
          RefineResult(value: value, tier: ProvenanceTier.estimated);
      final tierChanged =
          RefineResult(value: value, tier: ProvenanceTier.confirmed);
      final valueChanged = RefineResult(
        value: const ColorCoordinates(lightness: 1, a: 1, b: 1),
        tier: ProvenanceTier.estimated,
      );
      expect(a, sameAsA);
      expect(a.hashCode, sameAsA.hashCode);
      expect(a, isNot(tierChanged));
      expect(a, isNot(valueChanged));
      expect(a, isNot('not a RefineResult'));
    });

    test('toString names its value and tier', () {
      final result =
          RefineResult(value: value, tier: ProvenanceTier.estimated);
      expect(result.toString(), startsWith('RefineResult('));
      expect(result.toString(), contains('estimated'));
    });
  });

  group('CrowdRefine (shell)', () {
    const current = ColorCoordinates(lightness: 55, a: 4, b: 7);

    test('refine returns the current value unchanged', () {
      final refine = CrowdRefine();
      final result = refine.refine(current, [_peer('peer-1'), _peer('peer-2')]);
      expect(result.value, current);
      expect(refine.derivation, isNotNull);
    });

    test('peer-contributed evidence never promotes the tier (stays estimated)',
        () {
      final refine = CrowdRefine();
      final result = refine.refine(current, [_peer('peer-1')]);
      expect(result.tier, ProvenanceTier.estimated);
    });

    test('empty evidence keeps the explicit fallback tier', () {
      final refine = CrowdRefine();
      final result = refine.refine(
        current,
        const [],
        fallback: ProvenanceTier.calculated,
      );
      expect(result.tier, ProvenanceTier.calculated);
    });
  });
}
