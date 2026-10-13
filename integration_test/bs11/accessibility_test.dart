// Acceptance suite for bs-11 Accessibility conformance.
//
// CONF-1 (scaffold) laid the pending gate (`bs11/pending.dart`, all 10
// automated ACs pending). ITEST-1 adds the bs-11 harness
// (`accessibility_harness.dart`: the Given/When/Then vocabulary, the real-screen
// sweep subjects and the control fixtures, over the reusable
// `runConformanceCheck`) and here:
//   * pending-gate guards (never pending) so the gate cannot pass vacuously —
//     it holds exactly the 10 automated ACs, each owned by a real behaviour
//     phase, with the two manual ACs (AC-10/AC-12) deliberately absent; and
//   * a never-pending smoke suite proving the shells wire end to end — every
//     screen `buildApp` opens on `main` launches through the one production
//     entry and the reusable conformance check runs over it, the compliant
//     reference renders and checks, and every control fixture renders.
// ITEST-2/3 register one *pending* `acTestWidgets` per AC; the behaviour phases
// un-pend each by deleting its row in `bs11/pending.dart` and implementing its
// check rule.
//
// Default `flutter test integration_test/bs11/accessibility_test.dart -d <udid>`
// skips pending ACs; `--dart-define=BS11_RUN_PENDING=true` runs them (red
// baseline / un-pend run). A booted device udid is mandatory — without `-d` the
// run executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'accessibility_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-11 pending gate (scaffold guard)', () {
    test('pending map is exactly the 10 automated ACs (shrinks as they land)',
        () {
      // Seeded with the 10 automated ACs in CONF-1; each behaviour phase
      // deletes its AC's row in `bs11/pending.dart` as it un-pends it, so this
      // set shrinks by one per delivered AC. Nothing is un-pended yet at
      // ITEST-1. AC-10 and AC-12 are pure-manual gates (D-2) and never enter the
      // gate, so the automated set is AC-1..AC-9 plus AC-11.
      const expected = {
        'AC-1', 'AC-2', 'AC-3', 'AC-4', 'AC-5',
        'AC-6', 'AC-7', 'AC-8', 'AC-9', 'AC-11',
      };
      expect(pendingACs.keys.toSet(), expected);
      expect(pendingACs, hasLength(10));
    });

    test('the two manual ACs are absent from the automated gate (D-2)', () {
      // AC-10 (manual eyes-free walkthrough) and AC-12 (on-device VoiceOver vs
      // TalkBack parity) have no code and no automated test — they are closed by
      // user acceptance at SIGNOFF-1 (G-3/G-4), never skipped-then-run here.
      expect(pendingACs.containsKey('AC-10'), isFalse);
      expect(pendingACs.containsKey('AC-12'), isFalse);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-11 '
              'behaviour phase',
        );
      }
    });

    test('a pending AC skips in default mode and runs in run-pending mode', () {
      // The gate drives `testWidgets`' native `skip`: a still-pending AC's body
      // never runs in the default pass (it would assert un-built behaviour), but
      // does run under `--dart-define=BS11_RUN_PENDING=true` (the red-baseline
      // run). Both directions use the explicit [forceRunPending] so the guard is
      // deterministic in either ambient mode.
      for (final ac in pendingACs.keys) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending and must skip in the default run');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac must run in the run-pending run');
      }
      // An AC absent from the map (un-pended, or a manual AC) always runs, in
      // either mode.
      for (final ac in const ['AC-10', 'AC-12', 'AC-999']) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNull);
        expect(pendingSkipReason(ac, forceRunPending: true), isNull);
      }
      // The ambient path (used by acTestWidgets) agrees with the current mode.
      expect(
        pendingSkipReason('AC-1'),
        pendingSkipReason('AC-1', forceRunPending: runPending),
      );
    });
  });

  group('bs-11 harness fixtures (ITEST-1 guard)', () {
    test('the sweep covers all six buildApp screens, named uniquely', () {
      // The six `home:` branches of `buildApp` on `main` — the sweep subjects
      // (D-1). Fails if an entry were dropped or duplicated.
      expect(realScreens, hasLength(6));
      final names = realScreens.map((s) => s.name).toList();
      expect(names.toSet(), hasLength(6), reason: 'screen names must be unique');
      expect(
        names.toSet(),
        {'Readout', 'Capture', 'Comparison', 'Recipes', 'Correction', 'Palette'},
      );
    });

    test('the control fixtures are the seven discriminating controls', () {
      // Each control exists only to make a rule's "fails on its control"
      // assertion non-vacuous. Fails if one were dropped or duplicated.
      expect(controlFixtures, hasLength(7));
      final names = controlFixtures.map((c) => c.name).toList();
      expect(names.toSet(), hasLength(7), reason: 'control names must be unique');
      expect(names.toSet(), {
        'control_lowContrast',
        'control_smallTarget',
        'control_bareDot',
        'control_unlabelled',
        'control_autoDismiss',
        'control_overflow200',
        'control_partialFail',
      });
    });
  });

  group('bs-11 shells wired end to end (ITEST-1 smoke)', () {
    testWidgets(
      'every real screen opens through buildApp and the check runs over it',
      (tester) async {
        // Proves the production assembly opens each screen and the reusable
        // conformance check (D-3) runs over the opened subtree — the harness is
        // wired to the real app and the shells, not a bespoke one. The GATE-1
        // stub returns an empty result (no rule has run), so this asserts a
        // result is produced, not that it passes — an assertion that stays true
        // when GATE-3 populates the result.
        for (final realScreen in realScreens) {
          await givenScreen(tester, realScreen);
          expect(
            realScreen.screen,
            findsOneWidget,
            reason: '${realScreen.name} did not open through buildApp',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${realScreen.name} threw while opening',
          );
          final result =
              await whenCheckedForConformance(tester, realScreen.screen);
          expect(
            result,
            isA<ConformanceResult>(),
            reason: 'the check did not run over ${realScreen.name}',
          );
        }
      },
    );

    testWidgets('the compliant reference renders and the check runs over it',
        (tester) async {
      await givenCompliantReference(tester);
      expect(compliantReferenceFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
      final result =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      expect(result, isA<ConformanceResult>());
    });

    testWidgets('every control fixture renders', (tester) async {
      for (final fixture in controlFixtures) {
        await givenControl(tester, fixture);
        expect(
          fixture.subtree,
          findsOneWidget,
          reason: '${fixture.name} did not render',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '${fixture.name} threw while rendering',
        );
      }
    });
  });
}
