// Acceptance suite for bs-04 Mixing recipes.
//
// ITEST-1 lands the harness scaffold here: a never-pending smoke test proving
// the shells wire end to end (the real app boots to the Recipes screen and
// renders every region), plus guard tests so the scaffold cannot pass vacuously
// — the pending map must cover exactly the 12 ACs each owned by a real
// behaviour phase, the fake must record, the fixtures must carry the
// coordinates their scenarios assume (incl. a genuinely out-of-gamut control and
// an all-oil palette), and the independent reference ΔE00 must match Sharma et
// al.'s published CIEDE2000 test data.
//
// ITEST-2 and ITEST-3 register one *pending* `acTestWidgets` per AC in this
// file; the behaviour phases un-pend each by deleting its row in
// `bs04/pending.dart`. Default `flutter test integration_test/recipes_test.dart`
// skips pending ACs; `--dart-define=BS04_RUN_PENDING=true` runs them.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/recipes/controls_region.dart';
import 'package:paint_color_assistant/recipes/gamut_banner.dart';
import 'package:paint_color_assistant/recipes/recipe_list_region.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';
import 'package:paint_color_assistant/recipes/recipe_state.dart';
import 'package:paint_color_assistant/recipes/target_region.dart';

import 'recipes_harness.dart';

double _chroma(ColorCoordinates c) => math.sqrt(c.a * c.a + c.b * c.b);

double _hueDeg(ColorCoordinates c) {
  var h = math.atan2(c.b, c.a) * 180.0 / math.pi;
  if (h < 0) h += 360.0;
  return h;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to the Recipes screen showing every region',
    (tester) async {
      final harness = await givenRecipes(tester);

      // Booted to the Recipes route over the injected catalogue / palette.
      expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
      expect(find.byKey(RecipeReadEndpoint.endpointKey), findsOneWidget);

      // Every region anchor the AC finders and behaviour phases rely on.
      expect(find.byKey(TargetRegion.regionKey), findsOneWidget);
      expect(find.byKey(ControlsRegion.regionKey), findsOneWidget);
      expect(find.byKey(RecipeListRegion.regionKey), findsOneWidget);
      expect(find.byKey(GamutBanner.regionKey), findsOneWidget);

      // The target render the Readout → recipes handoff (bs-01 AC-11) relies on.
      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);

      // Opened mixing toward the injected target, over the selected palette,
      // with no recipes solved yet, wet mode, no manual error, nothing spoken.
      expect(harness.state.target, SAMPLE_DEEP_OLIVE);
      expect(harness.state.selectedPalette, PALETTE_MY_PAINTS);
      expect(harness.state.recipes, isEmpty);
      expect(harness.state.hasRecipes, isFalse);
      expect(harness.state.mode, MixMode.wet);
      expect(harness.state.manualError, isNull);
      expect(harness.speech.utterances, isEmpty);
    },
  );

  group('pending gate', () {
    // Un-pended by the behaviour phases so far: none yet — ITEST-1 seeds all 12
    // pending. Each behaviour phase adds its AC here as it deletes the row in
    // `bs04/pending.dart`: RECIPE-3 → AC-1, AC-2; ENGINE-2 → AC-3, AC-4;
    // ENGINE-3 → AC-5, AC-6; ENGINE-4 → AC-7, AC-8; ENGINE-5 → AC-9; ENGINE-6 →
    // AC-10; RECIPE-4 → AC-11, AC-12.
    const unpended = <String>{};

    test(
      'pending map is the exact complement of the un-pended ACs across all 12, '
      'each owned by a real behaviour phase',
      () {
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
      },
    );

    test(
        'the gate skips every pending AC by default and runs it in run-pending '
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

  group('fakes record what the app drives them with', () {
    test('FakeSpeech appends each utterance in order', () async {
      final speech = FakeSpeech();
      await speech.speak('first');
      await speech.speak('second');
      expect(speech.utterances, ['first', 'second']);
    });
  });

  group('fixtures carry the coordinates their scenarios assume', () {
    test('the catalogue lists the named saved samples', () {
      expect(
        CATALOGUE.map((s) => s.name).toList(),
        containsAll(<String>[
          'Deep Olive Green',
          'Warm Sand',
          'Vivid Turquoise',
        ]),
      );
      expect(CATALOGUE.length, 3);
    });

    test('Deep Olive Green recovers its C 28 / h 108 (AC-1 render)', () {
      // AC-1 renders "L 42, C 28, h 108"; the target derives C/h from a*/b*, so
      // the fixture must carry those polar values.
      expect(SAMPLE_DEEP_OLIVE.coordinates.lightness, 42);
      expect(_chroma(SAMPLE_DEEP_OLIVE.coordinates), closeTo(28, 0.05));
      expect(_hueDeg(SAMPLE_DEEP_OLIVE.coordinates), closeTo(108, 0.1));
    });

    test('"My paints" lists the five named paints (AC-3 names three)', () {
      expect(
        PALETTE_MY_PAINTS.paints.map((p) => p.name).toList(),
        containsAll(<String>[
          'Titanium White',
          'Yellow Ochre',
          'Ivory Black',
          'Ultramarine Blue',
          'Venetian Red',
        ]),
      );
      expect(PALETTE_MY_PAINTS.paints.length, 5);
    });

    test('Vivid Turquoise is a genuine out-of-gamut control for "My paints" '
        '(AC-9)', () {
      // AC-9 needs a target the earthy palette cannot reach: a strongly green
      // (a* ≪ 0), high-chroma colour. No "My paints" paint sits on the green
      // side, so no mix of them can produce it — the engine must say OUT OF
      // GAMUT, not invent a recipe. (The exact gamut verdict is the engine's,
      // graded in ENGINE-5; here we pin the fixture geometry the control needs.)
      expect(SAMPLE_VIVID_TURQUOISE.coordinates.a, lessThan(-20),
          reason: 'the turquoise must be strongly green (a* ≪ 0)');
      expect(_chroma(SAMPLE_VIVID_TURQUOISE.coordinates), greaterThan(35),
          reason: 'the turquoise must be high-chroma');
      for (final paint in PALETTE_MY_PAINTS.paints) {
        expect(paint.masstone.a, greaterThan(-5),
            reason: '${paint.name} is not on the green side, so the palette '
                'cannot reach a strongly green target');
      }
    });

    test('the oil fixtures are all oil so the AC-10 recipe is an oil mix', () {
      // AC-10's wet→dry transform is per-medium (D-11) and recipes never span
      // media, so the AC-10 palette must be entirely one medium.
      for (final paint in PALETTE_OIL.paints) {
        expect(paint.medium.name, 'oil',
            reason: '${paint.name} must be oil for the AC-10 drying transform');
      }
      expect(PALETTE_OIL.paints, isNotEmpty);
      expect(SAMPLE_OIL_TARGET.name, 'Studio Olive');
    });
  });

  group('referenceDeltaE00 matches Sharma et al. published CIEDE2000 data', () {
    // The independent authority AC-5 grades the product's ΔE00 against; a wrong
    // reference (CIE76 / CIE94 / a sign slip in the hue-rotation term) fails
    // these. Published pairs from Sharma, Wu & Dalal (2005).
    const cases = <List<double>>[
      // L1, a1, b1, L2, a2, b2, expected ΔE00
      [50, 2.6772, -79.7751, 50, 0, -82.7485, 2.0425],
      [50, -1.3802, -84.2814, 50, 0, -82.7485, 1.0000],
      [50, 0, 0, 50, -1, 2, 2.3669],
      [50, 2.4900, -0.0010, 50, -2.4900, 0.0009, 7.1792],
      [2.0776, 0.0795, -1.1350, 0.9033, -0.0636, -0.5514, 0.9082],
    ];

    test('each published pair', () {
      for (final c in cases) {
        final got = referenceDeltaE00(
          ColorCoordinates(lightness: c[0], a: c[1], b: c[2]),
          ColorCoordinates(lightness: c[3], a: c[4], b: c[5]),
        );
        expect(got, closeTo(c[6], 1e-3),
            reason: 'ΔE00 for $c should be ${c[6]}');
      }
    });

    test('a sample compared with itself is zero', () {
      expect(
        referenceDeltaE00(
          SAMPLE_DEEP_OLIVE.coordinates,
          SAMPLE_DEEP_OLIVE.coordinates,
        ),
        closeTo(0, 1e-9),
      );
    });
  });

  // =========================================================================
  // ITEST-2 — AC tests for AC-1, AC-2, AC-3, AC-11, AC-12
  // (target selection / manual entry / palette constraint / speak).
  //
  // One *pending* acTestWidgets per AC: skipped in the default run, executed
  // under --dart-define=BS04_RUN_PENDING=true, un-pended by its owning
  // behaviour phase (AC-1/2 → RECIPE-3; AC-3 → ENGINE-2; AC-11/12 → RECIPE-4).
  // Each drives the real assembled app through `recipes_harness.dart` and
  // asserts through the public surface (rendered text + the RecipeReadEndpoint
  // state seam + the FakeSpeech log). ITEST-3 appends AC-4..AC-10 below this
  // group — keep the two groups disjoint.
  // =========================================================================
  group('ITEST-2 — AC-1, AC-2, AC-3, AC-11, AC-12', () {
    acTestWidgets('AC-1', 'TestAC01_ChooseSavedTarget — a saved sample is set '
        'as the target at its L/C/h', (tester) async {
      // Given: the painter has a saved sample "Deep Olive Green" at L 42, C 28,
      // h 108, and is currently mixing toward a *different* saved target so the
      // choice is observable (control: the reading can change).
      final harness = await givenRecipes(tester, target: SAMPLE_WARM_SAND);
      expect(
        harness.controller.savedSamples.map((s) => s.name),
        contains('Deep Olive Green'),
        reason: 'the catalogue must offer the "Deep Olive Green" saved sample',
      );
      expect(harness.state.target, SAMPLE_WARM_SAND,
          reason: 'control: opened on a different target before the choice');
      expect(find.text('Recipe target: Warm Sand'), findsOneWidget);

      // When: the painter chooses "Deep Olive Green" as the recipe target.
      await harness.whenChooseSavedTarget('Deep Olive Green');

      // Then: "Deep Olive Green" at L 42, C 28, h 108 is the target — both the
      // observable state and the rendered target line.
      expect(harness.state.target, SAMPLE_DEEP_OLIVE);
      expect(harness.state.target.coordinates.lightness, 42);
      expect(_chroma(harness.state.target.coordinates), closeTo(28, 0.05));
      expect(_hueDeg(harness.state.target.coordinates), closeTo(108, 0.1));
      expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
    });

    acTestWidgets('AC-2', 'TestAC02_ManualTargetRefused — an out-of-range '
        'manual lightness is refused and the target is kept', (tester) async {
      // Given: the painter is setting a target by hand, with a known target
      // already set and no manual error outstanding.
      final harness = await givenRecipes(tester);
      expect(harness.state.target, SAMPLE_DEEP_OLIVE,
          reason: 'a known target is set before any manual entry');
      expect(harness.state.manualError, isNull,
          reason: 'no manual error before any manual entry');

      // Control: a *valid* manual target (L 50, in CIELAB's 0..100 range) IS
      // accepted and becomes the target — so the kept-target assertion below
      // separates range validation from an inert/reject-all handler that would
      // keep the target whatever is entered (G3/G5).
      await harness.whenEnterManualTarget(50, 0, 0);
      expect(harness.state.manualError, isNull,
          reason: 'a valid in-range manual target is accepted (no error)');
      expect(harness.state.target.coordinates.lightness, closeTo(50, 1e-9),
          reason: 'the accepted manual entry moves the target to L 50');
      expect(harness.state.target.coordinates.a, closeTo(0, 1e-9));
      expect(harness.state.target.coordinates.b, closeTo(0, 1e-9));
      final kept = harness.state.target;
      expect(kept, isNot(SAMPLE_DEEP_OLIVE),
          reason: 'the valid entry genuinely changed the target (control)');

      // When: the painter enters a lightness of 140 (out of CIELAB's 0..100).
      await harness.whenEnterManualTarget(140, 0, 0);

      // Then: the entry is refused as out of range (a manual error is raised),
      // and the previously set (valid L 50) target is kept unchanged — an
      // out-of-range value is rejected where the valid one was accepted.
      expect(harness.state.manualError, isNotNull,
          reason: 'L 140 is out of range and must be refused');
      expect(harness.state.target, kept,
          reason: 'the refused out-of-range entry must keep the valid target '
              'set just before it, not replace or clear it');
    });

    acTestWidgets('AC-3', 'TestAC03_PaletteConstrained — every returned recipe '
        'uses only paints from the selected palette', (tester) async {
      // Given: the selected palette is "My paints" (which contains Titanium
      // White, Yellow Ochre and Ivory Black, among others) and the target is
      // "Deep Olive Green", which that palette can mix.
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(harness.state.selectedPalette, PALETTE_MY_PAINTS);
      final paletteNames =
          PALETTE_MY_PAINTS.paints.map((p) => p.name).toSet();
      expect(
        paletteNames,
        containsAll(<String>['Titanium White', 'Yellow Ochre', 'Ivory Black']),
        reason: 'the Given names these three paints in "My paints"',
      );

      // When: the recipes are solved (ENGINE-2 solves over the selected palette
      // on open) — precondition naming the owner so the red baseline is clean.
      expect(harness.state.recipes, isNotEmpty,
          reason: 'the solve must return recipes to constrain (ENGINE-2)');

      // Then: every component of every returned recipe is a paint from the
      // selected palette — asserted by paint id for every recipe, every part.
      final paletteIds = PALETTE_MY_PAINTS.paints.map((p) => p.id).toSet();
      for (final recipe in harness.state.recipes) {
        for (final component in recipe.components) {
          expect(
            paletteIds,
            contains(component.paint.id),
            reason: '${component.paint.name} (${component.paint.id}) is not in '
                '"My paints" — recipes must use only the selected palette',
          );
        }
      }
    });

    acTestWidgets('AC-11', 'TestAC11_SpeakTarget — the spoken target states its '
        'name and L, C and hue', (tester) async {
      // Given: the target is "Deep Olive Green" at L 42, C 28, h 108, and
      // nothing has been spoken yet.
      final harness = await givenRecipes(tester, target: SAMPLE_DEEP_OLIVE);
      expect(harness.state.target, SAMPLE_DEEP_OLIVE);
      expect(harness.state.target.coordinates.lightness, 42);
      expect(_chroma(harness.state.target.coordinates), closeTo(28, 0.05));
      expect(_hueDeg(harness.state.target.coordinates), closeTo(108, 0.1));
      expect(harness.speech.utterances, isEmpty,
          reason: 'nothing spoken before the painter asks (control)');

      // When: the painter asks to speak the target.
      await harness.whenSpeakTarget();

      // Then: exactly one utterance states the target's name and its L, C and
      // hue (42 / 28 / 108) — a wrong value or an omitted field fails here.
      expect(harness.speech.utterances, hasLength(1),
          reason: 'speaking the target emits one utterance (RECIPE-4 E23)');
      final spoken = harness.speech.utterances.single;
      expect(spoken, contains('Deep Olive Green'));
      expect(spoken, contains('42'), reason: 'states the lightness (L 42)');
      expect(spoken, contains('28'), reason: 'states the chroma (C 28)');
      expect(spoken, contains('108'), reason: 'states the hue (h 108)');
    });

    acTestWidgets('AC-12', 'TestAC12_SpeakRecipe — the spoken recipe states '
        'each paint and its parts', (tester) async {
      // Given: a recipe is shown for the target over "My paints" (the engine
      // solves on open; the spec pins an illustrative Yellow Ochre/Ivory Black
      // recipe, but end-to-end we speak the actual top recipe), and nothing has
      // been spoken yet.
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(harness.state.recipes, isNotEmpty,
          reason: 'a recipe must be shown to speak it (ENGINE-2 list)');
      expect(harness.speech.utterances, isEmpty,
          reason: 'nothing spoken before the painter asks (control)');
      final recipe = harness.state.recipes.first;

      // When: the painter asks to speak that (top) recipe.
      await harness.whenSpeakRecipe(0);

      // Then: one utterance states each paint in the recipe and its parts — an
      // impl that drops a paint, or names paints without parts, fails here.
      expect(harness.speech.utterances, hasLength(1),
          reason: 'speaking a recipe emits one utterance (RECIPE-4 E25)');
      final spoken = harness.speech.utterances.single;
      for (final component in recipe.components) {
        expect(spoken, contains(component.paint.name),
            reason: 'the spoken recipe must state every paint by name');
      }
      expect(spoken.toLowerCase(), contains('part'),
          reason: 'the spoken recipe must state the paints as parts');
    });
  });

  // =========================================================================
  // ITEST-3 — AC tests for AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10
  // (solve / verdict / rank / trace / muddying / gamut / wet-dry).
  //
  // A disjoint append below the ITEST-2 group (same file): one *pending*
  // acTestWidgets per AC, skipped in the default run and executed under
  // --dart-define=BS04_RUN_PENDING=true, un-pended by its owning behaviour phase
  // (AC-4 → ENGINE-2; AC-5/AC-6 → ENGINE-3; AC-7/AC-8 → ENGINE-4; AC-9 →
  // ENGINE-5; AC-10 → ENGINE-6). Each drives the real assembled app through
  // `recipes_harness.dart` and asserts through the public surface (the
  // RecipeReadEndpoint state seam + rendered region text).
  //
  // G-4 (resolved 2026-10-08 by the spec author: the pinned L/C/h are
  // illustrative and the ACs assert behavioural properties — D-13; v1 subtractive
  // engine D-2; gamut ΔE00 > 5 D-10; trace ~2% D-12): AC-5 and AC-10 are written
  // against behavioural properties (a small ΔE00 + the "very close" verdict; a
  // real wet→dry shift), never the spec's illustrative predicted L/C/h. The
  // engine's ΔE00 is graded against the independent `referenceDeltaE00`, never
  // against itself.
  // =========================================================================
  group('ITEST-3 — AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-10', () {
    // The trace cutoff (D-12 ~2%; G-4) and the in-gamut ceiling (D-10 ΔE00 ≤ 5;
    // G-4) the AC-7 / AC-9 scenarios reason about — mirror MixOptions' defaults.
    const traceThreshold = 0.02;
    const gamutThreshold = 5.0;

    acTestWidgets('AC-4', 'TestAC04_TopRecipes — three to five recipes, each with '
        'its parts by volume and predicted colour', (tester) async {
      // Given: the target is "Deep Olive Green" and "My paints" can mix it.
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );

      // When: the recipes are solved on open (ENGINE-2) — precondition naming
      // the owner so the red baseline fails cleanly (the stub returns none).
      expect(harness.state.recipes, isNotEmpty,
          reason: 'the solve must return recipes (ENGINE-2)');
      final recipes = harness.state.recipes;

      // Then: between three and five candidate recipes are listed.
      expect(recipes.length, inInclusiveRange(3, 5),
          reason: 'the search returns the top three to five recipes');

      // And each recipe shows its paints as parts by volume and a predicted
      // colour: every recipe lists components with positive parts that (by
      // volume) sum to one, and a plausible CIELAB predicted colour.
      for (final recipe in recipes) {
        expect(recipe.components, isNotEmpty,
            reason: 'a recipe lists the paints it combines');
        for (final c in recipe.components) {
          expect(c.partsFraction, greaterThan(0),
              reason: '${c.paint.name} must carry a positive parts share');
        }
        final sum =
            recipe.components.fold<double>(0, (s, c) => s + c.partsFraction);
        expect(sum, closeTo(1.0, 1e-6),
            reason: 'parts by volume are shares that sum to 1');
        expect(recipe.predictedColor.lightness, inInclusiveRange(0, 100),
            reason: 'a recipe shows a plausible predicted CIELAB colour');
      }

      // And the rendered list surfaces the top recipe's paints by name (the
      // card-per-recipe body ENGINE-2 builds under the recipe-list region).
      for (final c in recipes.first.components) {
        expect(
          find.descendant(
            of: find.byKey(RecipeListRegion.regionKey),
            matching: find.textContaining(c.paint.name),
          ),
          findsWidgets,
          reason: 'the recipe list renders ${c.paint.name}',
        );
      }
    });

    acTestWidgets('AC-5', 'TestAC05_CloseVerdict — a close recipe states a small '
        'ΔE00 (vs the independent reference) with the verdict "very close"',
        (tester) async {
      // Given: a close recipe exists for "Deep Olive Green" over "My paints"
      // (the spec pins an illustrative Yellow Ochre/Ivory Black mix at L 42.6,
      // C 27.1, h 106 — G-4: illustrative, so this asserts behavioural
      // properties, not those literals).
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(harness.state.recipes, isNotEmpty,
          reason: 'the solve must return a recipe to verdict (ENGINE-2)');
      final best = harness.state.recipes.first;

      // Then: the recipe states its ΔE00 from the target — and the product's
      // ΔE00 equals the *independent* CIEDE2000 reference computed from the
      // recipe's own predicted colour, so AC-5 never grades the engine against
      // itself.
      expect(
        best.deltaE00,
        closeTo(
          referenceDeltaE00(best.predictedColor, SAMPLE_DEEP_OLIVE.coordinates),
          0.5,
        ),
        reason: 'the stated ΔE00 matches the independent reference',
      );

      // And it is genuinely close — in gamut (ΔE00 ≤ the out-of-gamut ceiling) —
      // and carries the plain verdict "very close" (the spec pins that phrase).
      expect(best.deltaE00, lessThanOrEqualTo(gamutThreshold),
          reason: 'a "very close" recipe is in gamut');
      expect(best.verdict, isNotNull,
          reason: 'each recipe carries a plain verdict (ENGINE-3)');
      expect(best.verdict!.toLowerCase(), contains('very close'),
          reason: 'a close recipe carries the verdict "very close"');

      // And the verdict renders in the recipe-list card.
      expect(
        find.descendant(
          of: find.byKey(RecipeListRegion.regionKey),
          matching: find.textContaining('very close'),
        ),
        findsWidgets,
        reason: 'the recipe list renders the "very close" verdict',
      );

      // LIMITED (augmentation owned by ENGINE-3): a single close recipe cannot
      // show the verdict *tracks* distance — a constant "very close" would pass.
      // ENGINE-3 adds a farther recipe asserting a different, worse verdict band.
    });

    acTestWidgets('AC-6', 'TestAC06_PreferFewer — a cleaner mix is never ranked '
        'below a similar-ΔE mix that uses more paints', (tester) async {
      // Given: the solve returns the ordered candidate recipes for "Deep Olive
      // Green" over "My paints".
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(harness.state.recipes.length, greaterThanOrEqualTo(2),
          reason: 'at least two recipes are needed to compare ranking '
              '(ENGINE-2 solve; ENGINE-3 ordering)');
      final recipes = harness.state.recipes;

      // Then: the ordering prefers fewer paints — for every pair ranked i<j at a
      // *similar* ΔE00, the earlier (better-ranked) recipe uses no more paints
      // than the later one. A solver that ranks a muddier four-paint mix above a
      // cleaner two-paint mix at a similar ΔE fails here.
      const similarDeltaE = 1.5;
      for (var i = 0; i < recipes.length; i++) {
        for (var j = i + 1; j < recipes.length; j++) {
          if ((recipes[i].deltaE00 - recipes[j].deltaE00).abs() <=
              similarDeltaE) {
            expect(
              recipes[i].components.length,
              lessThanOrEqualTo(recipes[j].components.length),
              reason: 'at a similar ΔE00 the higher-ranked recipe '
                  '(#${i + 1}) must not use more paints than #${j + 1}',
            );
          }
        }
      }

      // LIMITED (augmentation owned by ENGINE-3): the invariant above rejects a
      // mis-ordering but is only exercised where a similar-ΔE pair of differing
      // paint counts exists. ENGINE-3 constructs the decisive two-paint /
      // four-paint similar-ΔE pair and asserts the two-paint mix ranks above.
    });

    acTestWidgets('AC-7', 'TestAC07_TraceTouchOf — a sub-two-percent component is '
        'expressed as "a touch of" with a technique note, not a measured part',
        (tester) async {
      // Given: a recipe whose component share is under ~2% by volume (D-12; G-4
      // confirmed ~2%). The solve produces the recipes (ENGINE-2) and ENGINE-4
      // flags the trace.
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(harness.state.recipes, isNotEmpty,
          reason: 'the solve must return recipes to trace (ENGINE-2)');

      // A trace component must exist to exercise the rule (ENGINE-4) — any
      // component whose share is below the trace threshold.
      final traceComponents = [
        for (final r in harness.state.recipes)
          for (final c in r.components)
            if (c.partsFraction < traceThreshold) c,
      ];
      expect(traceComponents, isNotEmpty,
          reason: 'a recipe must carry a sub-2% trace component (ENGINE-4)');

      // Then: a trace component is flagged and carries a static technique note,
      // and a non-trace component is NOT flagged (so the flag is not constant).
      for (final c in traceComponents) {
        expect(c.isTrace, isTrue,
            reason: '${c.paint.name} at ${c.partsFraction} is a trace');
        expect(c.techniqueNote, isNotNull,
            reason: 'a trace component carries a static technique note (D-12)');
        expect(c.techniqueNote, isNotEmpty);
      }
      final measured = [
        for (final r in harness.state.recipes)
          for (final c in r.components)
            if (c.partsFraction >= traceThreshold) c,
      ];
      for (final c in measured) {
        expect(c.isTrace, isFalse,
            reason: '${c.paint.name} at ${c.partsFraction} is a measured part, '
                'not a trace');
      }

      // And the trace renders as "a touch of" in the recipe-list card.
      expect(
        find.descendant(
          of: find.byKey(RecipeListRegion.regionKey),
          matching: find.textContaining('a touch of'),
        ),
        findsWidgets,
        reason: 'a trace component renders as "a touch of" (AC-7)',
      );

      // LIMITED (augmentation owned by ENGINE-4): the decisive case is a recipe
      // whose *Titanium White* is the sub-2% trace (the spec names it). ENGINE-4
      // constructs/guarantees that recipe and asserts its measured-part form is
      // absent for the traced paint.
    });

    acTestWidgets('AC-8', 'TestAC08_MuddyingFlag — a complementary-crossing mix is '
        'flagged as muddying, a non-crossing one is not', (tester) async {
      // Given: the solve returns candidate recipes, some of which cross a
      // complementary hue pair (D-9; "My paints" holds both earthy greens/yellows
      // and Venetian Red, so a crossing mix is reachable).
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(harness.state.recipes, isNotEmpty,
          reason: 'the solve must return recipes to flag (ENGINE-2)');
      final recipes = harness.state.recipes;

      // A crossing recipe and a non-crossing control must both exist, so the
      // flag is proven to track the crossing rather than being constant
      // (ENGINE-4 sets the flag).
      final muddying = recipes.where((r) => r.muddying).toList();
      final clean = recipes.where((r) => !r.muddying).toList();
      expect(muddying, isNotEmpty,
          reason: 'a complementary-crossing recipe must be flagged (ENGINE-4)');
      expect(clean, isNotEmpty,
          reason: 'a non-crossing control must be present and unflagged '
              '(so the flag is not constant-true)');

      // Then: the muddying recipe renders a "liable to muddy" flag in its card.
      expect(
        find.descendant(
          of: find.byKey(RecipeListRegion.regionKey),
          matching: find.textContaining('muddy'),
        ),
        findsWidgets,
        reason: 'a crossing recipe is flagged as liable to muddy (AC-8)',
      );

      // LIMITED (augmentation owned by ENGINE-4): a decisive case pins a *known*
      // complementary-crossing recipe (a green mix crossing Venetian Red) flagged
      // and a known non-crossing recipe unflagged, once the engine output is
      // known.
    });

    acTestWidgets('AC-9', 'TestAC09_OutOfGamut — an unreachable target is marked '
        'OUT OF GAMUT and the nearest mix is offered as nearest, not a match',
        (tester) async {
      // Given: the target "Vivid Turquoise" cannot be mixed from "My paints"
      // (a strongly-green high-chroma colour no palette paint can reach — the
      // ITEST-1 fixture guard proves the geometry).
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_VIVID_TURQUOISE,
        palette: PALETTE_MY_PAINTS,
      );

      // When the recipes are solved (on open), Then the target is marked
      // "OUT OF GAMUT" in the banner (ENGINE-5) — the red baseline fails here:
      // the shell keeps the banner hidden.
      expect(
        find.descendant(
          of: find.byKey(GamutBanner.regionKey),
          matching: find.text('OUT OF GAMUT'),
        ),
        findsOneWidget,
        reason: 'an out-of-gamut target is marked OUT OF GAMUT (ENGINE-5)',
      );

      // And a nearest possible mix is offered, flagged as the nearest, never as
      // a match — every offered recipe is marked out-of-gamut (not a match) and
      // exceeds the in-gamut ceiling.
      expect(harness.state.recipes, isNotEmpty,
          reason: 'the nearest possible mix is still offered');
      for (final r in harness.state.recipes) {
        expect(r.outOfGamut, isTrue,
            reason: 'the nearest mix is offered as nearest, not as a match');
        expect(r.deltaE00, greaterThan(gamutThreshold),
            reason: 'the best achievable mix exceeds the in-gamut ceiling');
      }

      // Control: an in-gamut target ("Deep Olive Green") is NOT marked out of
      // gamut — the banner is not constant-on. (At the red baseline both the
      // banner and the recipes are inert, so this control passes while the
      // assertion above fails — a clean red baseline.)
      final inGamut = await givenRecipes(
        tester,
        target: SAMPLE_DEEP_OLIVE,
        palette: PALETTE_MY_PAINTS,
      );
      expect(
        find.descendant(
          of: find.byKey(GamutBanner.regionKey),
          matching: find.text('OUT OF GAMUT'),
        ),
        findsNothing,
        reason: 'an in-gamut target shows no OUT OF GAMUT banner (control)',
      );
      for (final r in inGamut.state.recipes) {
        expect(r.outOfGamut, isFalse,
            reason: 'an in-gamut recipe is a match, not a nearest-only');
      }
    });

    acTestWidgets('AC-10', 'TestAC10_WetDry — switching to the dry prediction '
        'shifts the predicted colour', (tester) async {
      // Given: a recipe predicts a wet colour for an oil target over the all-oil
      // palette (AC-10's recipe is oil; the drying transform is per-medium, D-11).
      // G-4: illustrative wet L 42.6/C 27.1/h 106 → dry L 41.2/C 26.4/h 107; this
      // asserts the behavioural property (dry ≠ wet), not those literals.
      final harness = await givenRecipes(
        tester,
        target: SAMPLE_OIL_TARGET,
        palette: PALETTE_OIL,
      );
      expect(harness.state.recipes, isNotEmpty,
          reason: 'a recipe must be shown to predict dry (ENGINE-2)');
      expect(harness.state.mode, MixMode.wet,
          reason: 'control: the prediction opens wet');
      final wet = harness.state.recipes.first.predictedColor;

      // When: the painter switches to the dry prediction (E24 toggle).
      await harness.whenToggleWetDry();

      // Then: the mode is dry and the predicted colour has shifted — a real
      // wet→dry change, not a no-op (the shell's inert toggle fails here).
      expect(harness.state.mode, MixMode.dry,
          reason: 'the wet/dry toggle switches to dry (ENGINE-6)');
      final dry = harness.state.recipes.first.predictedColor;
      expect(dry, isNot(wet),
          reason: 'the dry prediction differs from the wet prediction');
      expect(referenceDeltaE00(wet, dry), greaterThan(0),
          reason: 'the wet→dry shift is a real colour change');
    });
  });
}
