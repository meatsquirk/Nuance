// Harness tests for the bs-01 acceptance suite (ITEST-1).
//
// Two jobs, both never pending:
//   1. a smoke test proving the shells wire end to end — the real app assembled
//      through `buildApp` boots to the Readout route and renders every region
//      the AC finders anchor on;
//   2. guard tests over the pending gate and the recording fakes, so the
//      scaffold can't pass vacuously (the pending map must cover exactly the 12
//      ACs, each owned by a real behaviour phase; the fakes must actually
//      record).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/provenance_region.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';
import 'package:paint_color_assistant/readout/temperature_line.dart';
import 'package:paint_color_assistant/readout/value_region.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to a Readout showing every region',
    (tester) async {
      final harness = await givenReadoutOf(tester, SAMPLE_TERRACOTTA);

      // Booted to the Readout route with the injected fixture loaded.
      expect(find.text('Readout'), findsOneWidget); // app-bar title
      expect(find.text(SAMPLE_TERRACOTTA.name!), findsOneWidget);

      // Every region and action-bar control anchor is rendered.
      expect(find.byKey(NameHeader.headerKey), findsOneWidget);
      expect(find.byKey(ValueRegion.regionKey), findsOneWidget);
      expect(find.byKey(ValueRegion.grayscaleKey), findsOneWidget);
      expect(find.byKey(TemperatureLine.lineKey), findsOneWidget);
      expect(find.byKey(SpaceSelector.selectorKey), findsOneWidget);
      expect(find.byKey(SpaceSelector.valuesKey), findsOneWidget);
      expect(find.byKey(ProvenanceRegion.regionKey), findsOneWidget);
      expect(find.byKey(ActionsBar.barKey), findsOneWidget);
      expect(find.byKey(ActionsBar.speakKey), findsOneWidget);
      expect(find.byKey(ActionsBar.compareAKey), findsOneWidget);
      expect(find.byKey(ActionsBar.compareBKey), findsOneWidget);
      expect(find.byKey(ActionsBar.recipesKey), findsOneWidget);
      expect(find.byKey(ActionsBar.acknowledgeKey), findsOneWidget);

      // Opening the readout alone speaks nothing and fires no haptic.
      expect(harness.speech.utterances, isEmpty);
      expect(harness.haptics.confirmations, 0);
    },
  );

  group('pending gate', () {
    // ACs whose behaviour has landed (un-pended) and so are no longer in the
    // pending map. This set grows one behaviour phase at a time; the pending map
    // is its exact complement across the 12 ACs. READOUT-2 un-pended AC-1/AC-2;
    // READOUT-3 un-pended AC-3/AC-4; READOUT-4 un-pended AC-5; READOUT-5
    // un-pended AC-6/AC-7; READOUT-6 un-pended AC-9/AC-10/AC-11; A11Y-2 un-pended
    // AC-8/AC-12 — the final phase, so every AC is now un-pended.
    const unpended = {
      'AC-1', 'AC-2', 'AC-3', 'AC-4', 'AC-5', 'AC-6', 'AC-7', // earlier phases
      'AC-9', 'AC-10', 'AC-11', // READOUT-6
      'AC-8', 'AC-12', // A11Y-2 (this phase)
    };

    test('pending map is the exact complement of the un-pended ACs across all 12, '
        'each owned by a real behaviour phase', () {
      for (var n = 1; n <= 12; n++) {
        final ac = 'AC-$n';
        expect(
          pendingACs.containsKey(ac),
          !unpended.contains(ac),
          reason: unpended.contains(ac)
              ? '$ac is un-pended and must not be in the pending map'
              : '$ac must still have a pending entry',
        );
      }
      expect(pendingACs.length, 12 - unpended.length);
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} names unknown phase "${entry.value}"',
        );
      }
    });

    test('with every AC un-pended, the gate runs each one in both modes', () {
      // The feature is fully built: no AC is pending, so the gate admits every
      // one in either mode — the fully open end state. This fails if an AC were
      // re-pended, or if the gate inverted to skip an un-pended AC.
      expect(pendingACs, isEmpty,
          reason: 'A11Y-2 un-pended the final ACs; nothing stays pending');
      for (var n = 1; n <= 12; n++) {
        final ac = 'AC-$n';
        expect(pendingSkipReason(ac, forceRunPending: false), isNull,
            reason: '$ac is un-pended and must run even in default mode');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac must run in run-pending mode');
      }
      // An AC absent from the map also always runs, in either mode.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
      // The ambient path (used by acTestWidgets) agrees with the current mode.
      expect(
        pendingSkipReason('AC-8'),
        pendingSkipReason('AC-8', forceRunPending: runPending),
      );
    });
  });

  group('fakes record what the app drives them with', () {
    test('FakeSpeech appends each utterance in order', () async {
      final speech = FakeSpeech();
      await speech.speak('first');
      await speech.speak('second');
      expect(speech.utterances, ['first', 'second']);
    });

    test('FakeHaptics counts confirmation pulses', () async {
      final haptics = FakeHaptics();
      expect(haptics.confirmations, 0);
      await haptics.confirm();
      await haptics.confirm();
      expect(haptics.confirmations, 2);
    });
  });
}
