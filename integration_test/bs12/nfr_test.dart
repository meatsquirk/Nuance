// bs-12 non-functional-requirements acceptance suite (ITEST-1..3).
//
// ITEST-1 lands the harness scaffold here: a never-pending smoke test proving
// the shells wire end to end — the real app (`buildApp`) launches into each
// core flow, and every reusable NFR guard / harness returns a populated result
// — plus guard tests so the scaffold cannot pass vacuously (the pending map
// must cover exactly the 16 automatable ACs, each owned by a real behaviour
// phase, and the fixtures / authority lists must carry what their ACs assume).
//
// ITEST-2 and ITEST-3 register one *pending* `acTestWidgets` per AC in this
// file; the behaviour phases (GUARD-3..6, QUALITY-2..5) un-pend each by deleting
// its row in `bs12/pending.dart`. Default
// `flutter test integration_test/bs12/nfr_test.dart -d <booted-udid>` skips
// pending ACs; `--dart-define=BS12_RUN_PENDING=true` runs them (the red
// baseline). A booted `-d` is mandatory — without it the run executes zero
// tests and exits 0 (a false green).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';

import 'nfr_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The home screen `buildApp` opens on for each core flow (buildApp's entry
  // precedence). The smoke test asserts each launch reaches its screen, proving
  // the one assembly path enters every flow the NFR guards sweep.
  final flowHome = <NfrFlow, Type>{
    NfrFlow.readout: ReadoutScreen,
    NfrFlow.capture: CaptureHomeScreen,
    NfrFlow.comparison: ComparisonHomeScreen,
    NfrFlow.recipes: RecipesHomeScreen,
    NfrFlow.palette: PaletteHomeScreen,
  };

  for (final flow in NfrFlow.values) {
    testWidgets(
      'smoke: buildApp launches into the ${flow.name} flow',
      (tester) async {
        final harness = await givenTheApp(tester, flow: flow);

        // The one production assembly reaches this flow's screen.
        expect(
          find.byType(flowHome[flow]!),
          findsOneWidget,
          reason: 'buildApp must open the ${flow.name} flow on '
              '${flowHome[flow]}',
        );
        // A real MaterialApp was assembled (the full app, not a bare screen),
        // and the faked platform sinks are inert until a flow drives them.
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(harness.flow, flow);
        expect(harness.speech.utterances, isEmpty);
        expect(harness.haptics.confirmations, 0);
      },
    );
  }

  group('the reusable guards and harnesses are wired', () {
    testWidgets('offline guard runs a body and refuses any network touch',
        (tester) async {
      final sink = NetworkAttemptSink();

      // A body that touches nothing completes and returns its value.
      final value = await runUnderNetworkBlock(() async => 'done', sink: sink);
      expect(value, 'done');

      // A body that opens an HttpClient is refused, fast and visibly.
      await expectLater(
        runUnderNetworkBlock(() async => HttpClient(), sink: sink),
        throwsA(isA<NetworkBlockedException>()),
      );

      // The GUARD-2 sink is inert (GUARD-3 wires the increment); until then no
      // attempt is recorded even though one was refused.
      expect(sink.attempts, 0);
    });

    test('source guard exposes every rule scan over populated authorities', () {
      // The GUARD-2 stubs report no offenders; GUARD-4/6 fill the real scans.
      expect(conversionOffenders(), isEmpty);
      expect(deltaEOffenders(), isEmpty);
      expect(platformOffenders(), isEmpty);
      expect(forbiddenDependencies(), isEmpty);
      expect(offDeviceSenders(), isEmpty);

      // The authorities and allow-lists the scans judge against are configured
      // — an empty offender list means "invariant holds", not "nothing to
      // check".
      expect(conversionAuthorityFiles, contains('lib/color_science/conversions.dart'));
      expect(conversionAuthorityFiles.length, 3);
      expect(deltaEAuthorityFiles, contains('lib/compare/difference.dart'));
      expect(nativeCaptureSeam, 'lib/capture/source/');
      expect(forbiddenDependencyNames, contains('firebase_analytics'));
      expect(forbiddenDependencyNames, contains('sentry'));
    });

    test('accuracy harness grades the seed set within bound by the reference ΔE',
        () {
      const harness = AccuracyHarness();
      final grades = harness.gradeAll();

      // One populated grade per seed sample, each within its condition's bound.
      expect(grades.length, syntheticAccuracySet.length);
      expect(grades.length, 3);
      for (final grade in grades) {
        expect(
          grade.withinBound,
          isTrue,
          reason: '${grade.sampleId} seed must sit inside ΔE00 '
              '${grade.maxDeltaE} (was ${grade.deltaE})',
        );
      }
      expect(
        grades.map((g) => g.sampleId).toSet(),
        syntheticAccuracySet.map((s) => s.id).toSet(),
      );

      // The seed set covers all three accuracy conditions.
      expect(
        syntheticAccuracySet.map((s) => s.condition).toSet(),
        AccuracyCondition.values.toSet(),
      );
    });

    test('perf harness measures a body against its budget', () async {
      const harness = PerfHarness();
      final probe = await harness.measure(
        'smoke',
        kCaptureSettleCiBudget,
        () async {},
      );
      expect(probe.label, 'smoke');
      expect(probe.budget, kCaptureSettleCiBudget);
      expect(probe.withinBudget, isTrue);

      // The AC-4 candidate-count bound discriminates 3–5 from outside it.
      expect(isTopCandidateCount(kMinTopCandidates), isTrue);
      expect(isTopCandidateCount(kMaxTopCandidates), isTrue);
      expect(isTopCandidateCount(kMinTopCandidates - 1), isFalse);
      expect(isTopCandidateCount(kMaxTopCandidates + 1), isFalse);
    });

    test('synthetic gamut targets carry one in-gamut control and one out', () {
      final inGamut = syntheticGamutTargets.where((t) => t.inGamut);
      final outOfGamut = syntheticGamutTargets.where((t) => !t.inGamut);
      expect(inGamut.length, 1, reason: 'AC-13 positive control');
      expect(outOfGamut.length, 1, reason: 'AC-13 out-of-gamut target');
    });

    testWidgets('swap harness pumps the real app through the injection seam',
        (tester) async {
      // Both swap seams default to the shipped implementations; GUARD-5 passes
      // recording alternates. ITEST-1 only proves the real app assembles through
      // the helper.
      await pumpAppWithSwaps(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('pending gate', () {
    // The 16 automatable ACs (AC-5 is pure-manual, D-3, never in the gate). All
    // 16 are pending at ITEST-1; each behaviour phase deletes its row in
    // `bs12/pending.dart` as it un-pends that AC.
    final expectedPending = <String>{
      'AC-1', 'AC-2', 'AC-3', 'AC-4', // AC-5 is manual — absent
      'AC-6', 'AC-7', 'AC-8', 'AC-9', 'AC-10', 'AC-11', 'AC-12', 'AC-13',
      'AC-14', 'AC-15', 'AC-16', 'AC-17',
    };

    test('the pending map is exactly the 16 automatable ACs, each owned by a '
        'real behaviour phase', () {
      expect(pendingACs.keys.toSet(), expectedPending);
      expect(pendingACs.length, 16);

      // AC-5 (live-preview frame rate) is pure-manual and must never enter the
      // gate.
      expect(pendingACs.containsKey('AC-5'), isFalse);

      // Every key is a real AC id and every owner is a real behaviour phase.
      final acId = RegExp(r'^AC-\d+$');
      for (final entry in pendingACs.entries) {
        expect(acId.hasMatch(entry.key), isTrue,
            reason: '"${entry.key}" is not an AC id');
        expect(behaviorPhases, contains(entry.value),
            reason: '${entry.key} names unknown phase "${entry.value}"');
      }
    });

    test('the gate skips every pending AC by default and runs it in run-pending '
        'mode', () {
      for (final ac in pendingACs.keys) {
        expect(
          pendingSkipReason(ac, forceRunPending: false),
          isNotNull,
          reason: '$ac is pending and must be skipped in the default run',
        );
        expect(
          pendingSkipReason(ac, forceRunPending: true),
          isNull,
          reason: '$ac must execute in run-pending mode (the red baseline)',
        );
      }
      // An AC absent from the map always runs, in either mode — the un-pended
      // end state each behaviour phase moves its AC toward.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
      // The ambient path (used by acTestWidgets) agrees with the current mode.
      expect(
        pendingSkipReason('AC-1'),
        pendingSkipReason('AC-1', forceRunPending: runPending),
      );
    });
  });

  group('the platform fakes record what the app drives them with', () {
    test('FakeSpeech appends each utterance in order', () async {
      final speech = FakeSpeech();
      await speech.speak('first');
      await speech.speak('second');
      expect(speech.utterances, ['first', 'second']);
    });

    test('FakeHaptics counts each confirmation', () async {
      final haptics = FakeHaptics();
      await haptics.confirm();
      await haptics.confirm();
      expect(haptics.confirmations, 2);
    });
  });
}
