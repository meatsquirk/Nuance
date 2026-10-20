// bs-18 acceptance suite — Recipes-screen AC (ITEST-3): AC-7 the recipes as
// cards with mono notes and pill actions (owner FLOW-2).
//
// Pumps the real Recipes screen (`pumpScreen(recipes)`, mixing toward the
// fixture's reachable target so the engine returns ranked recipe cards) and
// reads the design-system treatment off the pumped tree. Pending; red at
// baseline (recipe rows are Material `Card`s, actions are ad-hoc `TextButton`s).
//
// SCOPE NOTES for the ITEST-5 / G-2 review (see ITEST.md):
//  - No "ranked by" note exists in `lib/` today (grep-confirmed), so this test
//    cannot anchor on it; whether FLOW-2 introduces such a note is a G-2
//    decision, not something the acceptance test can presuppose.
//  - The out-of-gamut note (GamutBanner marker) renders only for an out-of-gamut
//    target; the harness pumps the fixture's REACHABLE target (so the banner is
//    collapsed here). Asserting the out-of-gamut-note style would be vacuous on
//    this pump, so it is flagged as a FLOW-2 augmentation candidate rather than
//    asserted. The test asserts the two solid, discriminating facts: recipe rows
//    render as surface cards (old Material Card rows absent) and recipe actions
//    render as design-system controls (not ad-hoc TextButtons).
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/recipes/gamut_banner.dart';
import 'package:paint_color_assistant/recipes/recipe_list_region.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-7 — Recipes as cards with pill actions (owner FLOW-2)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-7',
      'TestAC07_Recipes: each recipe renders in a surface card and its actions '
      'render as design-system controls, not ad-hoc Card/TextButton rows',
      (tester) async {
    // GIVEN the Recipes screen open mixing toward the fixture's reachable target
    // — the recipe list renders at least one recipe card.
    await pumpScreen(tester, VisualScreen.recipes);
    expect(find.byKey(RecipeListRegion.regionKey), findsOneWidget,
        reason: 'Given: the recipe list region renders');
    final firstCard = find.byKey(RecipeListRegion.cardKey(0));
    expect(firstCard, findsOneWidget,
        reason: 'Given: at least one recipe card renders for the reachable target');

    // WHEN the recipe list renders.

    // THEN the recipe sits in a surface card (rejects a recipe row left as a
    // bare / Material Card row).
    expect(
      find.ancestor(of: firstCard, matching: find.byType(SurfaceCard)),
      findsOneWidget,
      reason: 'the recipe row sits inside a SurfaceCard',
    );

    // THEN no recipe row is a Material Card any more (the superseded ad-hoc row
    // absent — the Recipes screen is fully ad-hoc today, so this discriminates
    // a no-op swap).
    expect(
      find.descendant(
        of: find.byKey(RecipeListRegion.regionKey),
        matching: find.byType(Card),
      ),
      findsNothing,
      reason: 'recipe rows are no longer Material Cards',
    );

    // THEN the recipe actions render as design-system controls — a SpeakButton
    // (the per-recipe "Speak recipe") or a PillButton — not the ad-hoc
    // TextButton they are today (rejects a recipe action left ad-hoc).
    expect(
      find.descendant(of: firstCard, matching: find.byType(TextButton)),
      findsNothing,
      reason: 'the recipe card carries no ad-hoc TextButton action',
    );
    final hasSpeak = find
        .descendant(of: firstCard, matching: find.byType(SpeakButton))
        .evaluate()
        .isNotEmpty;
    final hasPill = find
        .descendant(of: firstCard, matching: find.byType(PillButton))
        .evaluate()
        .isNotEmpty;
    expect(hasSpeak || hasPill, isTrue,
        reason: 'the recipe action is a design-system SpeakButton or PillButton');

    // THEN the "ranked by" note renders in the design-system mono style — a
    // [MonoLabel], not an ad-hoc styled `Text` (rejects a note hardcoded). The
    // note is present whenever recipes are, so it reads on the reachable pump.
    final rankedNote = find.byKey(RecipeListRegion.rankedNoteKey);
    expect(rankedNote, findsOneWidget, reason: 'the "ranked by" note renders');
    expect(tester.widget(rankedNote), isA<MonoLabel>(),
        reason: 'the "ranked by" note is a design-system MonoLabel');
  });

  // AC-7 augmentation (FLOW-2) — the out-of-gamut note in the design-system
  // mono style. The reachable target above leaves the banner collapsed, so this
  // pumps the fixture's out-of-gamut target over the same palette (the engine
  // marks it unreachable) and asserts the banner marker renders through
  // [MonoLabel] — closing the catalogue's "notes hardcoded" Reject the
  // authoring phase (ITEST-3) could not reach.
  acTestWidgets('AC-7',
      'TestAC07_Recipes (out-of-gamut): the out-of-gamut note renders in the '
      'design-system mono style over the same palette',
      (tester) async {
    // GIVEN the Recipes screen open mixing toward the fixture's out-of-gamut
    // target — the gamut banner is shown (not collapsed).
    await pumpRecipes(tester, target: recipesForTarget.outOfGamutTarget);
    final banner = find.byKey(GamutBanner.regionKey);
    expect(banner, findsOneWidget, reason: 'Given: the gamut banner anchor');
    expect(
      find.descendant(of: banner, matching: find.text(GamutBanner.markerText)),
      findsOneWidget,
      reason: 'Given: the out-of-gamut target shows the OUT OF GAMUT marker',
    );

    // WHEN the note renders.

    // THEN the out-of-gamut marker renders through a design-system [MonoLabel]
    // (rejects the marker left as an ad-hoc styled `Text`).
    expect(
      find.descendant(of: banner, matching: find.byType(MonoLabel)),
      findsOneWidget,
      reason: 'the out-of-gamut marker is a design-system MonoLabel',
    );

    // AND the "ranked by" note still renders as a MonoLabel for the
    // nearest-possible recipes an out-of-gamut target still yields.
    final rankedNote = find.byKey(RecipeListRegion.rankedNoteKey);
    expect(rankedNote, findsOneWidget, reason: 'the "ranked by" note renders');
    expect(tester.widget(rankedNote), isA<MonoLabel>(),
        reason: 'the "ranked by" note is a design-system MonoLabel');
  });
}
