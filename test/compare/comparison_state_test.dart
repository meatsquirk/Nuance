import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/comparison_state.dart';
import 'package:paint_color_assistant/compare/difference.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

const _a = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);
const _b = Sample(
  name: 'Raw Sienna Light',
  coordinates: ColorCoordinates(lightness: 70, a: 12.5, b: 21.65),
  provenance: Provenance(ProvenanceTier.measured),
);
const _comparison = Comparison(
  deltaE00: 13.1,
  verdict: 'clearly different',
  lightness: 'Lighter by 12',
  saturation: 'Less saturated by 9',
  hue: 'Hue shifted 18 degrees toward yellow',
);

void main() {
  group('ComparisonState', () {
    test('defaults to two empty slots and no reading', () {
      const state = ComparisonState();
      expect(state.slotA, isNull);
      expect(state.slotB, isNull);
      expect(state.comparison, isNull);
      expect(state.confusable, isFalse);
      expect(state.hasBothSlots, isFalse);
    });

    test('hasBothSlots is true only when both slots carry a sample', () {
      expect(const ComparisonState(slotA: _a).hasBothSlots, isFalse);
      expect(const ComparisonState(slotB: _b).hasBothSlots, isFalse);
      expect(const ComparisonState(slotA: _a, slotB: _b).hasBothSlots, isTrue);
    });

    test('carries a derived reading and confusion flag', () {
      const state = ComparisonState(
        slotA: _a,
        slotB: _b,
        comparison: _comparison,
        confusable: true,
      );
      expect(state.comparison, _comparison);
      expect(state.confusable, isTrue);
    });

    test('value equality: equal fields compare equal', () {
      const x = ComparisonState(slotA: _a, slotB: _b, comparison: _comparison);
      const y = ComparisonState(slotA: _a, slotB: _b, comparison: _comparison);
      expect(x, y);
      expect(x.hashCode, y.hashCode);
    });

    test('value equality: a differing field compares unequal', () {
      const base = ComparisonState(slotA: _a, slotB: _b);
      expect(base == const ComparisonState(slotA: _a), isFalse);
      expect(base == const ComparisonState(slotA: _a, slotB: _b, confusable: true),
          isFalse);
      // ignore: unrelated_type_equality_checks
      expect(base == Object(), isFalse);
    });

    test('toString names the slots, the reading and the confusion flag', () {
      expect(const ComparisonState().toString(),
          'ComparisonState(A: (empty), B: (empty), no comparison)');
      expect(
        const ComparisonState(
          slotA: _a,
          slotB: _b,
          comparison: _comparison,
          confusable: true,
        ).toString(),
        contains('confusable'),
      );
      expect(
        const ComparisonState(slotA: _a, slotB: _b, comparison: _comparison)
            .toString(),
        contains('Warm Terracotta'),
      );
    });
  });
}
