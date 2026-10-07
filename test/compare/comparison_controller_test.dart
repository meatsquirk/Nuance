import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/compare/comparison_controller.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
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

ComparisonController _controller({
  SampleSource sampleSource = const InMemorySampleSource(),
  Sample? initialA,
  Sample? initialB,
}) =>
    ComparisonController(
      sampleSource: sampleSource,
      confusionCheck: const NoopConfusionCheck(),
      profile: const CvdProfile(type: CvdType.deutan),
      initialA: initialA,
      initialB: initialB,
    );

void main() {
  group('ComparisonController derivation', () {
    test('starts with two empty slots and no reading', () {
      final c = _controller();
      expect(c.state.slotA, isNull);
      expect(c.state.slotB, isNull);
      expect(c.state.comparison, isNull);
      expect(c.state.confusable, isFalse);
      expect(c.state.hasBothSlots, isFalse);
    });

    test('with only one slot set there is still no reading (AC-12)', () {
      final c = _controller(initialA: _a);
      expect(c.state.slotA, same(_a));
      expect(c.state.slotB, isNull);
      expect(c.state.comparison, isNull);
      expect(c.state.confusable, isFalse);
    });

    test('with both slots set it derives the pair via DIFF + CVD', () {
      final c = _controller(initialA: _a, initialB: _b);
      expect(c.state.slotA, same(_a));
      expect(c.state.slotB, same(_b));
      expect(c.state.hasBothSlots, isTrue);
      // DIFF's compare returns a (placeholder) reading for the pair...
      expect(c.state.comparison, isNotNull);
      // ...and the inert CVD detector flags nothing yet.
      expect(c.state.confusable, isFalse);
    });
  });

  group('ComparisonController catalogue', () {
    test('exposes an empty catalogue by default', () {
      expect(_controller().savedSamples, isEmpty);
    });

    test('exposes the injected catalogue to the picker', () {
      final c = _controller(
        sampleSource: const InMemorySampleSource(samples: [_a, _b]),
      );
      expect(c.savedSamples, [_a, _b]);
    });
  });

  group('ComparisonController deferred actions', () {
    test('selectA is deferred to COMPARE-3', () {
      expect(() => _controller().selectA(_a), throwsUnimplementedError);
    });

    test('selectB is deferred to COMPARE-3', () {
      expect(() => _controller().selectB(_b), throwsUnimplementedError);
    });

    test('swap is deferred to COMPARE-5', () {
      expect(() => _controller().swap(), throwsUnimplementedError);
    });

    test('openReadout is deferred to COMPARE-6', () {
      expect(
        () => _controller().openReadout(ComparisonSlot.a),
        throwsUnimplementedError,
      );
    });
  });
}
