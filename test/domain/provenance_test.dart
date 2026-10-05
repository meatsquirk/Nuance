import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/provenance.dart';

void main() {
  group('Provenance.label', () {
    test('maps every tier to its user-facing label', () {
      expect(const Provenance(ProvenanceTier.measured).label, 'Measured');
      expect(const Provenance(ProvenanceTier.calculated).label, 'Calculated');
      expect(const Provenance(ProvenanceTier.estimated).label, 'Estimated');
      expect(const Provenance(ProvenanceTier.confirmed).label, 'Confirmed');
    });
  });

  group('equality and hashCode', () {
    test('equal when tier and note match', () {
      const a = Provenance(ProvenanceTier.estimated, note: 'seeded');
      const b = Provenance(ProvenanceTier.estimated, note: 'seeded');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when tier differs', () {
      expect(
        const Provenance(ProvenanceTier.measured),
        isNot(equals(const Provenance(ProvenanceTier.estimated))),
      );
    });

    test('unequal when note differs', () {
      expect(
        const Provenance(ProvenanceTier.estimated, note: 'a'),
        isNot(equals(const Provenance(ProvenanceTier.estimated, note: 'b'))),
      );
    });

    test('unequal to a non-Provenance object', () {
      // ignore: unrelated_type_equality_checks
      expect(const Provenance(ProvenanceTier.measured) == 'Measured', isFalse);
    });
  });

  group('toString', () {
    test('omits the note when absent', () {
      expect(
        const Provenance(ProvenanceTier.measured).toString(),
        'Provenance(Measured)',
      );
    });

    test('includes the note when present', () {
      expect(
        const Provenance(ProvenanceTier.estimated, note: 'seeded').toString(),
        'Provenance(Estimated, seeded)',
      );
    });
  });
}
