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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/widgets/accessible_notice.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';
import 'package:paint_color_assistant/widgets/status_badge.dart';

import 'accessibility_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-11 pending gate (scaffold guard)', () {
    test('pending map holds exactly the still-pending automated ACs (shrinks as they land)',
        () {
      // Seeded with the 10 automated ACs in CONF-1; each behaviour phase
      // deletes its AC's row in `bs11/pending.dart` as it un-pends it, so this
      // set shrinks by one per delivered AC. **A11Y-2 un-pended AC-5** (AA
      // contrast), **A11Y-3 un-pended AC-4** (48dp tap targets) and **A11Y-4
      // un-pended AC-3** (200% font scaling), so the still-pending set is now the
      // other seven. AC-10 and AC-12 are pure-manual gates (D-2) and never enter
      // the gate.
      const expected = {
        'AC-1', 'AC-2',
        'AC-6', 'AC-7', 'AC-8', 'AC-9', 'AC-11',
      };
      expect(pendingACs.keys.toSet(), expected);
      expect(pendingACs, hasLength(7));
      // AC-5, AC-4 and AC-3 are delivered — they must no longer be pending.
      expect(pendingACs.containsKey('AC-5'), isFalse,
          reason: 'AC-5 was un-pended by A11Y-2');
      expect(pendingACs.containsKey('AC-4'), isFalse,
          reason: 'AC-4 was un-pended by A11Y-3');
      expect(pendingACs.containsKey('AC-3'), isFalse,
          reason: 'AC-3 was un-pended by A11Y-4');
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

  // -------------------------------------------------------------------------
  // ITEST-2 — AC tests: the structural rules (AC-1, AC-2, AC-4, AC-5, AC-6).
  //
  // Each is registered *pending* via [acTestWidgets]: skipped in the default
  // run, executed under `--dart-define=BS11_RUN_PENDING=true` (the red
  // baseline), un-pended by its owning behaviour phase (A11Y-2..6) deleting its
  // row in `bs11/pending.dart`. Every test runs its rule's outcome in the
  // aggregate [ConformanceResult] over the reusable `runConformanceCheck`
  // (D-3): the rule must **pass on every real screen and on `compliantReference`
  // (the SI-mandated sweep, D-1), and fail on its discriminating control** — so
  // a rule that always passes (ignores the violation) fails the control, and a
  // real screen that leaks the violation fails the sweep (G5). At the red
  // baseline `runConformanceCheck` is the GATE-1 stub returning
  // `ConformanceResult.empty`, so every rule outcome is absent and each test
  // fails on its first Then (the sweep's positive assertion).
  // -------------------------------------------------------------------------
  group('bs-11 acceptance criteria — structural rules (ITEST-2)', () {
    acTestWidgets('AC-1', 'every colour-coded element carries a non-colour cue',
        (tester) async {
      // Scenario: Every colour-coded element carries a non-colour cue.
      // Then (sweep, D-1): the colour-cue rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through the production `buildApp`.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        // When: the colour-cue check runs over the screen.
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: every colour-coded element on it carries a label/icon/pattern/
        // number — the rule holds (A11Y-5 makes this true).
        expect(result.outcomeFor(ConformanceRuleId.colourCue)?.pass, isTrue,
            reason: '${realScreen.name}: a colour-coded element lacks a '
                'non-colour cue');
      }
      // Given: the compliant reference shows a colour-coded element (ColorChip).
      await givenCompliantReference(tester);
      expect(
          find.descendant(
              of: compliantReferenceFinder, matching: find.byType(ColorChip)),
          findsOneWidget,
          reason: 'Given: reference shows a colour-coded ColorChip');
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      // Then: the rule passes on the fully-compliant reference.
      expect(refResult.outcomeFor(ConformanceRuleId.colourCue)?.pass, isTrue,
          reason: 'the compliant reference must pass the colour-cue rule');
      // Control (G5): a bare colour dot with no text/icon fails the rule — the
      // discriminating case that rejects a rule which never flags anything.
      await givenControl(tester, control_bareDot);
      expect(control_bareDot.subtree, findsOneWidget,
          reason: 'Given: the bare colour dot is rendered');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_bareDot.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.colourCue),
          reason: 'control_bareDot shows colour with no cue — the rule must '
              'flag it');
    });

    acTestWidgets('AC-2', 'a status is never rendered as a bare colour dot',
        (tester) async {
      // Scenario: A status is never rendered as a bare colour dot.
      // Then (sweep): the no-bare-dot rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through `buildApp`.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        // When: the no-bare-dot rule runs over the screen.
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: no status is a bare colour dot — the rule holds (A11Y-5).
        expect(result.outcomeFor(ConformanceRuleId.noBareDot)?.pass, isTrue,
            reason: '${realScreen.name}: a status is drawn as a bare colour '
                'dot');
      }
      // Given: the reference renders its status via StatusBadge (text + icon).
      await givenCompliantReference(tester);
      expect(
          find.descendant(
              of: compliantReferenceFinder, matching: find.byType(StatusBadge)),
          findsOneWidget,
          reason: 'Given: reference shows a status as a StatusBadge, not a dot');
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      // Then: the rule passes on the reference (status carries text/icon).
      expect(refResult.outcomeFor(ConformanceRuleId.noBareDot)?.pass, isTrue,
          reason: 'a text/icon status must pass the no-bare-dot rule');
      // Control (G5): a status drawn as a bare coloured dot fails the rule.
      await givenControl(tester, control_bareDot);
      expect(control_bareDot.subtree, findsOneWidget,
          reason: 'Given: the bare colour dot is rendered');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_bareDot.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.noBareDot),
          reason: 'control_bareDot is a bare coloured dot — the rule must flag '
              'it');
    });

    acTestWidgets('AC-4', 'interactive targets meet the 48dp minimum',
        (tester) async {
      // Scenario: Interactive targets meet the minimum size.
      // Then (sweep): the tap-target rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through `buildApp`.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        // When: the targets are measured by the tap-target rule.
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: each interactive target is ≥ 48dp — the rule holds (A11Y-3).
        expect(result.outcomeFor(ConformanceRuleId.tapTarget48)?.pass, isTrue,
            reason: '${realScreen.name}: an interactive target is below 48dp');
      }
      // Given: the reference shows an interactive target (a 48dp IconButton).
      await givenCompliantReference(tester);
      expect(
          find.descendant(
              of: compliantReferenceFinder, matching: find.byType(IconButton)),
          findsOneWidget,
          reason: 'Given: reference shows an interactive target');
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      // Then: the rule passes on the reference (its target is 48dp).
      expect(refResult.outcomeFor(ConformanceRuleId.tapTarget48)?.pass, isTrue,
          reason: 'a 48dp target must pass the tap-target rule');
      // Control (G5): a 24dp target fails the rule — rejects a rule that never
      // applies the 48dp guideline.
      await givenControl(tester, control_smallTarget);
      expect(control_smallTarget.subtree, findsOneWidget,
          reason: 'Given: the 24dp target is rendered');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_smallTarget.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.tapTarget48),
          reason: 'control_smallTarget is 24dp — the rule must flag it');
    });

    acTestWidgets('AC-5', 'text meets the WCAG 2.2 AA contrast floor',
        (tester) async {
      // Scenario: Text meets the high-contrast floor.
      // Then (sweep): the contrast rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through `buildApp` and reads the app
        // theme (G2) — so the contrast comes from the shipped ColorScheme, not
        // an ad-hoc ThemeData a test could over-tune. A11Y-2 tunes that one
        // theme to AA; this Given pins that it is the single source.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        expect(Theme.of(tester.element(realScreen.screen)).colorScheme,
            AppTheme.light().colorScheme,
            reason: 'Given: ${realScreen.name} uses the app theme (G2)');
        // When: contrast is measured against the background.
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: text meets WCAG 2.2 AA contrast — the rule holds (A11Y-2).
        expect(result.outcomeFor(ConformanceRuleId.contrastAA)?.pass, isTrue,
            reason: '${realScreen.name}: text is below the AA contrast floor');
      }
      // Given: the reference reads the same app theme.
      await givenCompliantReference(tester);
      expect(Theme.of(tester.element(compliantReferenceFinder)).colorScheme,
          AppTheme.light().colorScheme,
          reason: 'Given: reference uses the app theme');
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      // Then: the rule passes on the reference.
      expect(refResult.outcomeFor(ConformanceRuleId.contrastAA)?.pass, isTrue,
          reason: 'the compliant reference must pass the contrast rule');
      // Control (G5): ~1.6:1 grey-on-white text fails the rule — rejects a
      // rule that never applies the contrast guideline.
      await givenControl(tester, control_lowContrast);
      expect(control_lowContrast.subtree, findsOneWidget,
          reason: 'Given: the low-contrast text is rendered');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_lowContrast.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.contrastAA),
          reason: 'control_lowContrast is below 4.5:1 — the rule must flag it');
    });

    acTestWidgets('AC-6', 'every control exposes a meaningful screen-reader label',
        (tester) async {
      // Scenario: Every control exposes a meaningful screen-reader label.
      // Then (sweep): the labelled-control rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through `buildApp`.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        // When: each control is read by the screen reader (the rule traverses
        // the semantics tree).
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: every interactive node carries a meaningful label — the rule
        // holds (A11Y-6).
        expect(result.outcomeFor(ConformanceRuleId.meaningfulLabel)?.pass, isTrue,
            reason: '${realScreen.name}: a control has no meaningful label');
      }
      // Given: the reference shows a labelled control (IconButton w/ tooltip).
      await givenCompliantReference(tester);
      expect(
          find.descendant(
              of: compliantReferenceFinder, matching: find.byType(IconButton)),
          findsOneWidget,
          reason: 'Given: reference shows an interactive control');
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      // Then: the rule passes on the reference (its control is labelled).
      expect(refResult.outcomeFor(ConformanceRuleId.meaningfulLabel)?.pass, isTrue,
          reason: 'a labelled control must pass the labelled-control rule');
      // Control (G5): an IconButton with no tooltip/label fails the rule.
      await givenControl(tester, control_unlabelled);
      expect(control_unlabelled.subtree, findsOneWidget,
          reason: 'Given: the unlabelled control is rendered');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_unlabelled.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.meaningfulLabel),
          reason: 'control_unlabelled has no semantic label — the rule must '
              'flag it');
    });
  });

  // -------------------------------------------------------------------------
  // ITEST-3 — AC tests: scaling, eyes-free, timing, gate, floor
  //           (AC-3, AC-7, AC-8, AC-9, AC-11).
  //
  // Each is registered *pending* via [acTestWidgets] (skipped by default; run
  // under `--dart-define=BS11_RUN_PENDING=true`), un-pended by its owning
  // behaviour phase deleting its row in `bs11/pending.dart`:
  //   AC-3  → A11Y-4 (200% scaling)     AC-8  → A11Y-7 (no time limit)
  //   AC-7  → GATE-2 (eyes-free driver)  AC-9  → GATE-3 (acceptanceDecision)
  //   AC-11 → GATE-4 (recordedLevel)
  //
  // Red baseline (the GATE-1 stubs): `runConformanceCheck` returns
  // `ConformanceResult.empty` (every rule outcome absent), `eyesFreeComplete`
  // throws `UnimplementedError`, and `acceptanceDecision`/`recordedLevel` throw
  // `UnimplementedError`. So AC-3/AC-8 fail on their first positive **Then**
  // (a null rule outcome); AC-7 fails at the **When** (the driver stub throws,
  // its message naming GATE-2); AC-9/AC-11 fail at a **Given precondition** that
  // cannot hold until every sub-rule exists (its reason naming GATE-3/GATE-4) —
  // the honest limit that makes AC-9/AC-11 *B pending* at this phase.
  // -------------------------------------------------------------------------
  group('bs-11 acceptance criteria — scaling, eyes-free, timing, gate, floor '
      '(ITEST-3)', () {
    acTestWidgets('AC-3', 'the layout survives 200% font scaling without breaking',
        (tester) async {
      // Scenario: System font scaling to 200% does not break the layout.
      // The 200%-scale pump + overflow detection live inside the scaling rule
      // (A11Y-4: re-render at textScaler 2.0, then flag any Row/Column whose
      // children exceed its bounds), so — as for the contrast/target rules in
      // ITEST-2 — the test runs the reusable check over the *unscaled* subject
      // and reads the `fontScale200` outcome. (`whenScaledTo` stays available
      // for A11Y-4's own rule-level tests; pre-scaling here would surface a raw
      // RenderFlex overflow before the check could measure it, dirtying the
      // baseline.)
      // Then (sweep, D-1): the scaling rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through the production `buildApp`.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        // When: the scaling check runs over the screen (scales to 200%
        // internally and watches for overflow).
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: the layout survives 200% without clipping — the rule holds
        // (A11Y-4 fixes the layouts + authors the rule).
        expect(result.outcomeFor(ConformanceRuleId.fontScale200)?.pass, isTrue,
            reason: '${realScreen.name}: the layout clips or overflows at 200%');
      }
      // Given: the compliant reference lays out cleanly at any scale.
      await givenCompliantReference(tester);
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      // Then: the rule passes on the reference.
      expect(refResult.outcomeFor(ConformanceRuleId.fontScale200)?.pass, isTrue,
          reason: 'the compliant reference must survive 200% scaling');
      // Control (G5): a fixed-height column of text lines that overflows once
      // the text doubles fails the rule — rejects a rule that never applies the
      // 200% check.
      await givenControl(tester, control_overflow200);
      expect(control_overflow200.subtree, findsOneWidget,
          reason: 'Given: the fixed-height column is rendered');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_overflow200.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.fontScale200),
          reason: 'control_overflow200 clips at 200% — the rule must flag it');
    });

    acTestWidgets('AC-7', 'a core task completes eyes-free under the screen reader',
        (tester) async {
      // Scenario: An eyes-free walkthrough completes under the screen reader.
      // The driver finds each control by its *semantic label* and activates it
      // via `SemanticsAction`, never by key/type/coordinate (D-6) — so a green
      // run proves the task is operable by a screen-reader user.
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      // Given: the app is launched to a core task (Readout of a fixture sample)
      // with semantics active, and the task's entry control is present *by its
      // label* ("Speak this readout" — the label GATE-2's driver activates).
      final readout = realScreens.firstWhere((s) => s.name == 'Readout');
      await givenScreen(tester, readout);
      expect(readout.screen, findsOneWidget,
          reason: 'Given: Readout opened through buildApp');
      expect(find.bySemanticsLabel('Speak this readout'), findsOneWidget,
          reason: 'Given: the task entry control is present by its label');

      // When: the task is performed using only semantic labels + actions.
      final completed =
          await whenCompletedEyesFree(tester, steps: const ['Speak this readout']);
      // Then: the task reaches its terminal state (observed via the read
      // endpoint inside the driver) — GATE-2 makes this true.
      expect(completed, isTrue,
          reason: 'the core task must complete eyes-free via semantic labels');

      // Control (G5): the same driver, given a required step whose label is not
      // exposed on any control, cannot progress — rejects a driver that falls
      // back to coordinates / widget position rather than semantics (D-6).
      final blocked = await whenCompletedEyesFree(
        tester,
        steps: const ['__no control exposes this label__'],
      );
      expect(blocked, isFalse,
          reason: 'a step with no semantic label must not be reachable — an '
              'eyes-free driver cannot use coordinates (D-6)');
    });

    acTestWidgets('AC-8', 'nothing auto-dismisses or imposes a time limit',
        (tester) async {
      // Scenario: No interaction imposes a time limit and nothing auto-dismisses.
      // Then (sweep): the no-timeout rule passes on every real screen.
      for (final realScreen in realScreens) {
        // Given: the screen is shown through `buildApp`.
        await givenScreen(tester, realScreen);
        expect(realScreen.screen, findsOneWidget,
            reason: 'Given: ${realScreen.name} opened through buildApp');
        // When: the no-timeout rule runs over the screen.
        final result = await whenCheckedForConformance(tester, realScreen.screen);
        // Then: nothing on it is on an auto-dismiss timer — the rule holds
        // (A11Y-7).
        expect(result.outcomeFor(ConformanceRuleId.noTimeout)?.pass, isTrue,
            reason: '${realScreen.name}: something imposes a time limit');
      }

      // Given: the reference shows an `AccessibleNotice` (never auto-dismisses),
      // confirmed present before the settle point.
      await givenCompliantReference(tester);
      expect(
          find.descendant(
              of: compliantReferenceFinder,
              matching: find.byType(AccessibleNotice)),
          findsOneWidget,
          reason: 'Given: the reference shows an AccessibleNotice');
      // When (settle point, G3): the painter waits well past any default
      // auto-dismiss window (the SnackBar default is 4s) without acting.
      await whenWaited(tester, const Duration(seconds: 10));
      // Then: the notice is *still present after the advance* — nothing was
      // dismissed on a timer — and the no-timeout rule passes.
      expect(
          find.descendant(
              of: compliantReferenceFinder,
              matching: find.byType(AccessibleNotice)),
          findsOneWidget,
          reason: 'the AccessibleNotice must persist past the settle point');
      final refResult =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      expect(refResult.outcomeFor(ConformanceRuleId.noTimeout)?.pass, isTrue,
          reason: 'a notice that never auto-dismisses must pass the rule');

      // Control (G3/G5): `control_autoDismiss`'s standard SnackBar *is gone*
      // after the same advance — proving the reading can change (so the
      // reference's persistence is a real observation, not a stuck frame) and
      // that the rule flags a timer-dismissed notice.
      await givenControl(tester, control_autoDismiss);
      expect(find.text('Auto-dismissing notice'), findsOneWidget,
          reason: 'Given: the auto-dismissing SnackBar is shown first');
      await whenWaited(tester, const Duration(seconds: 10));
      expect(find.text('Auto-dismissing notice'), findsNothing,
          reason: 'control: the SnackBar must auto-dismiss after the advance');
      final ctrlResult =
          await whenCheckedForConformance(tester, control_autoDismiss.subtree);
      expect(ctrlResult.failing, contains(ConformanceRuleId.noTimeout),
          reason: 'control_autoDismiss imposes a timer — the rule must flag it');
    });

    acTestWidgets(
        'AC-9', 'a feature failing the automated check is not accepted',
        (tester) async {
      // Scenario: A feature failing the automated check is not accepted.
      // *B pending GATE-3*: the aggregate `acceptanceDecision` cannot
      // discriminate until every sub-rule exists (A11Y-2..7 + GATE-2) and
      // GATE-3 composes them — so at this phase the Given below cannot hold
      // (the stub result is empty). GATE-3 un-pends and closes the augmentation
      // (ITEST *Test augmentations* → TestAC09).

      // Given: `control_partialFail` run through the check yields a result with
      // ≥1 FAILING rule and ≥1 PASSING rule (a genuinely partial result) —
      // asserted through the public check surface. Not satisfiable until GATE-3
      // populates the aggregate; the reason names it.
      await givenControl(tester, control_partialFail);
      final partial =
          await whenCheckedForConformance(tester, control_partialFail.subtree);
      expect(partial.failing, isNotEmpty,
          reason: 'Given (needs GATE-3 + the sub-rules A11Y-2..7/GATE-2): '
              'control_partialFail must have ≥1 failing rule');
      final anyPassing = ConformanceRuleId.values
          .any((id) => partial.outcomeFor(id)?.pass == true);
      expect(anyPassing, isTrue,
          reason: 'Given (needs GATE-3 + the sub-rules): control_partialFail '
              'must have ≥1 passing rule, so the result is genuinely partial');

      // When: the feature is reviewed for acceptance.
      final decision = acceptanceDecision(partial);
      // Then: a partially-failing result is NOT accepted (rejects a decision
      // that accepts it, or that inspects only one rule).
      expect(decision, AcceptanceDecision.notAccepted,
          reason: 'any failing rule ⇒ the build is not accepted');

      // Control (G5): a fully-passing result (the compliant reference) ⇒
      // accepted — so the decision is not a constant "notAccepted".
      await givenCompliantReference(tester);
      final full =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      expect(full.passed, isTrue,
          reason: 'Given (needs every rule): the reference passes every rule');
      expect(acceptanceDecision(full), AcceptanceDecision.accepted,
          reason: 'a fully-passing result ⇒ accepted');
    });

    acTestWidgets('AC-11', 'WCAG 2.2 AA is the recorded accepted floor',
        (tester) async {
      // Scenario: WCAG 2.2 AA is the accepted floor.
      // *B pending GATE-4*: `recordedLevel` is stubbed until GATE-4, and a
      // fully-passing result needs every sub-rule — so the Given cannot hold
      // yet; its reason names GATE-4. GATE-4 un-pends, pins the thresholds to
      // the WCAG 2.2 AA constants (D-5) and closes the augmentation (TestAC11).

      // Given: a fully-passing `ConformanceResult` (the compliant reference,
      // asserted `passed == true`). Not satisfiable until every rule lands.
      await givenCompliantReference(tester);
      final passing =
          await whenCheckedForConformance(tester, compliantReferenceFinder);
      expect(passing.passed, isTrue,
          reason: 'Given (needs every rule + GATE-4): the reference must pass '
              'every rule so its recorded level can be AA');

      // When: its compliance level is recorded.
      final level = recordedLevel(passing);
      // Then: it meets at least WCAG 2.2 AA.
      expect(level, WcagLevel.aa22,
          reason: 'a fully-passing result records WCAG 2.2 AA');

      // Control (G5): a failing result records BELOW AA — rejects recording AA
      // for a result that did not pass every rule.
      await givenControl(tester, control_partialFail);
      final failing =
          await whenCheckedForConformance(tester, control_partialFail.subtree);
      expect(failing.passed, isFalse,
          reason: 'Given: control_partialFail does not pass every rule');
      expect(recordedLevel(failing), WcagLevel.below,
          reason: 'a result that fails a rule records below AA, never AA');
    });
  });
}
