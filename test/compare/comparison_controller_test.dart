import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/compare/comparison_controller.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

/// Records the samples [toReadout] is asked to route to, so a test can prove
/// which slot's sample [ComparisonController.openReadout] opens (AC-10/AC-11).
class _RecordingRouter extends AppRouter {
  _RecordingRouter();

  final List<Sample> readoutCalls = [];

  @override
  Route<void> toReadout(Sample sample) {
    readoutCalls.add(sample);
    return super.toReadout(sample);
  }
}

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
  AppRouter router = const AppRouter(),
  Sample? initialA,
  Sample? initialB,
}) =>
    ComparisonController(
      sampleSource: sampleSource,
      confusionCheck: const NoopConfusionCheck(),
      profile: const CvdProfile(type: CvdType.deutan),
      router: router,
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

  group('ComparisonController selection (COMPARE-3)', () {
    test('selectA places the sample in slot A and notifies (AC-1)', () {
      final c = _controller();
      var notified = 0;
      c.addListener(() => notified++);

      c.selectA(_a);

      expect(c.state.slotA, same(_a));
      expect(c.state.slotB, isNull);
      // One slot ⇒ still no reading, so the AC-12 invite stays.
      expect(c.state.comparison, isNull);
      expect(c.state.hasBothSlots, isFalse);
      expect(notified, 1);
    });

    test('selectB places the sample in slot B and notifies (AC-2)', () {
      final c = _controller();
      var notified = 0;
      c.addListener(() => notified++);

      c.selectB(_b);

      expect(c.state.slotB, same(_b));
      expect(c.state.slotA, isNull);
      expect(c.state.comparison, isNull);
      expect(notified, 1);
    });

    test('selecting B after A keeps A and derives the pair (AC-2)', () {
      final c = _controller();
      c.selectA(_a);
      c.selectB(_b);

      expect(c.state.slotA, same(_a));
      expect(c.state.slotB, same(_b));
      expect(c.state.hasBothSlots, isTrue);
      // Both slots ⇒ the pair is read through DIFF's compare.
      expect(c.state.comparison, isNotNull);
    });

    test('selecting A after B keeps B (B pick does not land in A)', () {
      final c = _controller();
      c.selectB(_b);
      c.selectA(_a);

      expect(c.state.slotA, same(_a));
      expect(c.state.slotB, same(_b));
    });
  });

  group('ComparisonController swap (COMPARE-5)', () {
    test('exchanges both slots, re-derives the pair, and notifies (AC-3)', () {
      final c = _controller(initialA: _a, initialB: _b);
      final before = c.state.comparison;
      expect(before, isNotNull);
      var notified = 0;
      c.addListener(() => notified++);

      c.swap();

      // The two samples trade slots...
      expect(c.state.slotA, same(_b));
      expect(c.state.slotB, same(_a));
      // ...the pair is re-read for the swapped direction (B→A, not the old
      // A→B — rejects a swap that relabels the slots but leaves the reading)...
      expect(c.state.comparison, isNotNull);
      expect(c.state.comparison, isNot(equals(before)));
      // ...and the screen / read endpoint are notified once.
      expect(notified, 1);
    });

    test('with one slot set moves the lone sample and keeps no reading', () {
      final c = _controller(initialA: _a);
      expect(c.state.slotA, same(_a));
      expect(c.state.slotB, isNull);

      c.swap();

      expect(c.state.slotA, isNull);
      expect(c.state.slotB, same(_a));
      // Still only one slot filled ⇒ no reading (the AC-12 invite stays).
      expect(c.state.comparison, isNull);
    });
  });

  group('ComparisonController open readout (COMPARE-6)', () {
    test('sampleIn returns the sample in each slot, null when empty', () {
      final c = _controller(initialA: _a, initialB: _b);
      expect(c.sampleIn(ComparisonSlot.a), same(_a));
      expect(c.sampleIn(ComparisonSlot.b), same(_b));

      final empty = _controller();
      expect(empty.sampleIn(ComparisonSlot.a), isNull);
      expect(empty.sampleIn(ComparisonSlot.b), isNull);
    });

    test('slotFilled is true only for a slot that holds a sample', () {
      final c = _controller(initialA: _a);
      expect(c.slotFilled(ComparisonSlot.a), isTrue);
      expect(c.slotFilled(ComparisonSlot.b), isFalse);
    });

    test('openReadout(a) routes to the Readout for slot A (AC-10)', () {
      final router = _RecordingRouter();
      final c = _controller(router: router, initialA: _a, initialB: _b);

      final route = c.openReadout(ComparisonSlot.a);

      // Opens the sample in slot A — not slot B (rejects an impl that always
      // opens one fixed slot; AC-11's test proves the B side).
      expect(router.readoutCalls, [same(_a)]);
      expect(route, isA<Route<void>>());
    });

    test('openReadout(b) routes to the Readout for slot B (AC-11)', () {
      final router = _RecordingRouter();
      final c = _controller(router: router, initialA: _a, initialB: _b);

      final route = c.openReadout(ComparisonSlot.b);

      expect(router.readoutCalls, [same(_b)]);
      expect(route, isA<Route<void>>());
    });
  });
}
