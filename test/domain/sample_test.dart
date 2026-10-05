import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

void main() {
  const coords = ColorCoordinates(lightness: 58, a: 24, b: 30);
  const other = ColorCoordinates(lightness: 20, a: 0, b: -5);
  const measured = Provenance(ProvenanceTier.measured);

  group('EvidencePoint', () {
    test('equal when coordinates and source match', () {
      // One built at runtime (non-const) so the const constructor is covered.
      // ignore: prefer_const_constructors
      final a = EvidencePoint(coordinates: coords, source: 'spectro');
      const b = EvidencePoint(coordinates: coords, source: 'spectro');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('unequal when coordinates differ', () {
      expect(
        const EvidencePoint(coordinates: coords, source: 'spectro'),
        isNot(equals(const EvidencePoint(coordinates: other, source: 'spectro'))),
      );
    });

    test('unequal when source differs', () {
      expect(
        const EvidencePoint(coordinates: coords, source: 'spectro'),
        isNot(equals(const EvidencePoint(coordinates: coords, source: 'peer'))),
      );
    });

    test('unequal to a non-EvidencePoint object', () {
      const point = EvidencePoint(coordinates: coords, source: 'spectro');
      // ignore: unrelated_type_equality_checks
      final isEqual = point == 'x';
      expect(isEqual, isFalse);
    });

    test('toString reports source and coordinates', () {
      expect(
        const EvidencePoint(coordinates: coords, source: 'spectro').toString(),
        'EvidencePoint(spectro: ColorCoordinates(L 58.0, a 24.0, b 30.0))',
      );
    });
  });

  group('Sample defaults', () {
    test('name null, not just-captured, empty evidence by default', () {
      const sample = Sample(coordinates: coords, provenance: measured);
      expect(sample.name, isNull);
      expect(sample.justCaptured, isFalse);
      expect(sample.evidence, isEmpty);
    });
  });

  group('Sample.copyWith', () {
    const sample = Sample(
      coordinates: coords,
      provenance: measured,
      name: 'Warm Terracotta',
      justCaptured: true,
      evidence: [EvidencePoint(coordinates: coords, source: 'spectro')],
    );

    test('with no arguments returns an equal-valued copy', () {
      final copy = sample.copyWith();
      expect(copy.coordinates, coords);
      expect(copy.provenance, measured);
      expect(copy.name, 'Warm Terracotta');
      expect(copy.justCaptured, isTrue);
      expect(copy.evidence, sample.evidence);
    });

    test('replaces every field when given', () {
      const newProv = Provenance(ProvenanceTier.confirmed);
      final copy = sample.copyWith(
        coordinates: other,
        provenance: newProv,
        name: 'Deep Olive Green',
        justCaptured: false,
        evidence: const [],
      );
      expect(copy.coordinates, other);
      expect(copy.provenance, newProv);
      expect(copy.name, 'Deep Olive Green');
      expect(copy.justCaptured, isFalse);
      expect(copy.evidence, isEmpty);
    });
  });

  group('Sample.toString', () {
    test('named, just-captured sample', () {
      const sample = Sample(
        coordinates: coords,
        provenance: measured,
        name: 'Warm Terracotta',
        justCaptured: true,
      );
      expect(
        sample.toString(),
        'Sample(Warm Terracotta, ColorCoordinates(L 58.0, a 24.0, b 30.0), '
        'Measured, just-captured)',
      );
    });

    test('unnamed, not-just-captured sample', () {
      const sample = Sample(coordinates: coords, provenance: measured);
      expect(
        sample.toString(),
        'Sample((unnamed), ColorCoordinates(L 58.0, a 24.0, b 30.0), Measured)',
      );
    });
  });
}
