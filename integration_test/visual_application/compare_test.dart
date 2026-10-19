// bs-18 acceptance suite — Compare-flow AC (ITEST-3): AC-6 the comparison
// controls and rows as design-system components (owner FLOW-1).
//
// Pumps the real surfaces through the harness and reads the design-system
// treatment off the pumped tree. Pending; red at baseline (no
// PillButton/SpeakButton/SurfaceCard on either surface).
//
// DISCOVERED SCOPE NOTE — flagged for the ITEST-5 / G-2 review (see ITEST.md):
// the scenario names "Compare as A", "Compare as B" and "Find mixing recipes"
// as Compare-screen controls, but in the shipped app those three actions live
// on the READOUT screen's ActionsBar (`lib/readout/actions_bar.dart`:
// compareAKey / compareBKey / recipesKey) — NOT on the ComparisonScreen, whose
// own actions are "Speak whole comparison" / "Open readout for A|B". The Compare
// screen carries the difference / statement regions and the comparison speak
// action. This test reads the three named A/B/recipes actions on the Readout
// (`pumpShell`) and the diff / statement / speak on the Compare screen
// (`pumpScreen(compare)`), so it covers all four Then clauses on the REAL
// controls. The readout actions live in `lib/readout/**` (READ module), while
// FLOW-1 owns `lib/compare/**`; the reviewer must decide at G-2 which phase
// swaps the readout ActionsBar actions (expand FLOW-1's file ownership, or add
// them to READ-3 / an augmentation). This is a plan-ownership gap, not a test
// weakness — the test states the AC faithfully.
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/compare/difference_region.dart';
import 'package:paint_color_assistant/compare/statement_region.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-6 — Compare controls + rows as design-system components (owner FLOW-1)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-6',
      'TestAC06_Compare: the A/B compare actions are pills, find-recipes the '
      'ink-filled primary pill, the difference & statement regions sit in '
      'surface cards, and the comparison speak action is the SpeakButton FAB',
      (tester) async {
    // GIVEN the Readout (the shell's opening Capture body) renders the three
    // named compare / recipe actions — the scenario's "Compare as A/B" and
    // "Find mixing recipes" (they live on the Readout ActionsBar; header note).
    final shell = await pumpShell(tester);
    for (final key in const <Key>[
      ActionsBar.compareAKey,
      ActionsBar.compareBKey,
      ActionsBar.recipesKey,
    ]) {
      expect(find.byKey(key), findsOneWidget,
          reason: 'Given: the $key action renders on the readout');
    }

    // WHEN the comparison controls render (the pump settles).

    // THEN "Compare as A" and "Compare as B" render as design-system pills (the
    // wireframe's outline / secondary weight), not the ad-hoc OutlinedButtons
    // they are today (rejects an A/B action left ad-hoc).
    expectPill(tester, ActionsBar.compareAKey,
        reason: 'Compare as A renders as a PillButton');
    expectPill(tester, ActionsBar.compareBKey,
        reason: 'Compare as B renders as a PillButton');

    // THEN "Find mixing recipes" renders as the ink-filled PRIMARY pill — a
    // PillButton.primary wraps a FilledButton (rejects an outline/secondary pill
    // or an ad-hoc button for the call-to-action).
    expectPill(tester, ActionsBar.recipesKey,
        reason: 'Find mixing recipes renders as a PillButton');
    expect(
      subtreeHas<FilledButton>(tester, find.byKey(ActionsBar.recipesKey)),
      isTrue,
      reason: 'Find mixing recipes is the ink-filled primary pill',
    );
    expect(shell.pillButtons, findsWidgets,
        reason: 'the readout carries design-system pills, not just ad-hoc buttons');

    // GIVEN the Compare screen open on the fixture comparison — its difference,
    // statement and speak controls render.
    final compare = await pumpScreen(tester, VisualScreen.compare);
    expect(find.byKey(DifferenceRegion.regionKey), findsOneWidget,
        reason: 'Given: the difference region renders');
    expect(find.byKey(StatementRegion.regionKey), findsOneWidget,
        reason: 'Given: the statement region renders');

    // THEN the difference and statement regions each sit in a surface card
    // (rejects a region left as a bare Column).
    for (final key in const <Key>[
      DifferenceRegion.regionKey,
      StatementRegion.regionKey,
    ]) {
      expect(
        find.ancestor(of: find.byKey(key), matching: find.byType(SurfaceCard)),
        findsOneWidget,
        reason: 'the $key region sits inside a SurfaceCard',
      );
    }

    // THEN the comparison speak action renders as the round accent floating
    // speak button (rejects leaving it an ad-hoc TextButton).
    expect(compare.speakButtons, findsWidgets,
        reason: 'the comparison speak action renders as a SpeakButton FAB');
  });
}
