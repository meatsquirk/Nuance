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
    test('covers exactly the 12 ACs, each owned by a real behaviour phase', () {
      expect(pendingACs.length, 12);
      for (var n = 1; n <= 12; n++) {
        expect(
          pendingACs.containsKey('AC-$n'),
          isTrue,
          reason: 'AC-$n must have a pending entry',
        );
      }
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} names unknown phase "${entry.value}"',
        );
      }
    });

    test('skips a pending AC by default; runs it under BS01_RUN_PENDING', () {
      // Assert both modes deterministically (override the ambient env), so this
      // run exercises both branches and an inverted gate fails either way.
      // AC-1 is pending (present in the map).
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An un-pended AC (absent from the map) always runs, in either mode.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
      // The ambient path (used by acTestWidgets) agrees with the current mode.
      expect(
        pendingSkipReason('AC-1'),
        pendingSkipReason('AC-1', forceRunPending: runPending),
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
