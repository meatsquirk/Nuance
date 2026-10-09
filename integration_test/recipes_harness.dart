// Acceptance-suite harness for bs-04 Mixing recipes (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and independent reference the AC
// tests (ITEST-2, ITEST-3) are written against. The suite drives the *real*
// assembled app through the single production `buildApp` entry with the bs-04
// recipes entry (D-6): an injected `SampleSource` catalogue (the target picker),
// a `PaletteSource` (the owned paints) and the real `SubtractiveMixingEngine`.
// Only the platform speech sink is faked (bs-01's `FakeSpeech`); no colour,
// mixing or ΔE00 math is faked — the real engine (forward + inverse + verdict +
// trace + muddying + gamut + wet/dry) is exercised, and a scenario's expected
// ΔE00 is checked against [referenceDeltaE00], an independent CIEDE2000 so AC-5
// never grades the impl against itself.
//
// The pending gate (all 12 ACs → owning phase) lives in `bs04/pending.dart`
// (scaffolded in RECIPE-1); ITEST-1 seeds it with the 12 ACs and this harness
// re-exports it so an AC test imports only this file.
//
// Fixture identifiers mirror the plan's `SAMPLE_*` / `PALETTE_*` / `CATALOGUE`
// names, and the AC catalogue references them verbatim, so this file opts out of
// lowerCamelCase for them.
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/controls_region.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_controller.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';
import 'package:paint_color_assistant/recipes/recipe_state.dart';

import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate and the fakes so an AC test only needs to import
// this harness.
export 'bs04/pending.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// Samples and paint masstones are stored in canonical CIELAB (the domain's
// single source of truth). A fixture whose plan shape is given in CIELCh carries
// the exact polar form of that chroma/hue in a*/b* (a* = C·cos h, b* = C·sin h),
// since CIELCh is the polar form of CIELAB a*/b* by definition. Values are the
// ones pinned in the master plan's fixture table, rounded so C/h recover
// (C 28, h 108° etc.).
// ---------------------------------------------------------------------------

/// "Deep Olive Green" — CIELAB from CIELCh L 42 / C 28 / h 108° = (42, −8.65,
/// 26.63). The primary target. Drives AC-1, AC-4, AC-5, AC-6, AC-11.
const Sample SAMPLE_DEEP_OLIVE = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -8.65, b: 26.63),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Warm Sand" — a second named saved sample so the target picker (E22) lists
/// more than one choice (AC-1 chooses by name from a catalogue of several). A
/// light muted yellow (CIELCh L 78 / C 24 / h 80° = (78, 4.17, 23.63)).
const Sample SAMPLE_WARM_SAND = Sample(
  name: 'Warm Sand',
  coordinates: ColorCoordinates(lightness: 78, a: 4.17, b: 23.63),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Vivid Turquoise" — a high-chroma green-cyan unreachable from the earthy
/// [PALETTE_MY_PAINTS]. **Out-of-gamut control** (AC-9): CIELAB (72, −38, −14) —
/// strongly green (a\* ≪ 0) where no palette paint sits, so the best achievable
/// mix cannot match it and the engine must say so rather than invent a recipe.
const Sample SAMPLE_VIVID_TURQUOISE = Sample(
  name: 'Vivid Turquoise',
  coordinates: ColorCoordinates(lightness: 72, a: -38, b: -14),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Deep Umber" — the AC-7 trace fixture. A dark warm near-neutral (CIELAB
/// (33, 0, 12)) whose best mix over [PALETTE_MY_PAINTS] is Yellow Ochre + Ivory
/// Black with **only a touch of Titanium White** (≈ 1.4% by volume), so the
/// top recipe carries a genuine sub-2% Titanium White trace — the spec's named
/// trace paint (AC-7 / D-12) — rather than a measured part.
const Sample SAMPLE_DEEP_UMBER = Sample(
  name: 'Deep Umber',
  coordinates: ColorCoordinates(lightness: 33, a: 0, b: 12),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Studio Olive (oil)" — the AC-10 wet/dry target. A muted warm olive
/// (CIELAB (55, 6, 20)) reachable from the oil [PALETTE_OIL], so a recipe exists
/// whose predicted colour the per-medium drying transform (D-11) can shift.
const Sample SAMPLE_OIL_TARGET = Sample(
  name: 'Studio Olive',
  coordinates: ColorCoordinates(lightness: 55, a: 6, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);

/// The saved samples the recipes target picker (E22) lists — the catalogue
/// injected into every scenario. AC-1 chooses from this list by name.
const List<Sample> CATALOGUE = [
  SAMPLE_DEEP_OLIVE,
  SAMPLE_WARM_SAND,
  SAMPLE_VIVID_TURQUOISE,
];

// --- Paints (masstone CIELAB + medium, D-3) --------------------------------

/// Titanium White (acrylic) — a near-neutral high-lightness masstone.
const Paint PAINT_TITANIUM_WHITE = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
  pigmentIndex: 'PW6',
);

/// Yellow Ochre (acrylic) — a muted yellow earth (named in AC-3, AC-12).
const Paint PAINT_YELLOW_OCHRE = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
  pigmentIndex: 'PY43',
);

/// Ivory Black (acrylic) — a very dark near-neutral (named in AC-3, AC-12).
const Paint PAINT_IVORY_BLACK = Paint(
  id: 'pbk9',
  name: 'Ivory Black',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 16, a: 0, b: 1),
  pigmentIndex: 'PBk9',
);

/// Ultramarine Blue (acrylic) — a deep red-shade blue (the palette's only cool).
const Paint PAINT_ULTRAMARINE = Paint(
  id: 'pb29',
  name: 'Ultramarine Blue',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 30, a: 18, b: -52),
  pigmentIndex: 'PB29',
);

/// Venetian Red (acrylic) — an earthy red, the AC-8 complementary partner to a
/// green mix.
const Paint PAINT_VENETIAN_RED = Paint(
  id: 'pr101',
  name: 'Venetian Red',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 40, a: 32, b: 26),
  pigmentIndex: 'PR101',
);

/// "My paints" — the owned acrylic palette the solver is constrained to (D-5).
/// Titanium White, Yellow Ochre, Ivory Black (named in AC-3), Ultramarine Blue
/// and Venetian Red: enough to mix the earthy [SAMPLE_DEEP_OLIVE], to *cross*
/// complements (AC-8) and to *fail* to reach [SAMPLE_VIVID_TURQUOISE] (AC-9).
const PaintPalette PALETTE_MY_PAINTS = PaintPalette(
  name: 'My paints',
  paints: [
    PAINT_TITANIUM_WHITE,
    PAINT_YELLOW_OCHRE,
    PAINT_IVORY_BLACK,
    PAINT_ULTRAMARINE,
    PAINT_VENETIAN_RED,
  ],
);

// --- Oil palette (AC-10 wet/dry) -------------------------------------------

/// Titanium White in oil — AC-10's drying transform is per-medium (D-11).
const Paint PAINT_TITANIUM_WHITE_OIL = Paint(
  id: 'pw6-oil',
  name: 'Titanium White',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
  pigmentIndex: 'PW6',
);

/// Yellow Ochre in oil.
const Paint PAINT_YELLOW_OCHRE_OIL = Paint(
  id: 'py43-oil',
  name: 'Yellow Ochre',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
  pigmentIndex: 'PY43',
);

/// Ivory Black in oil.
const Paint PAINT_IVORY_BLACK_OIL = Paint(
  id: 'pbk9-oil',
  name: 'Ivory Black',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 16, a: 0, b: 1),
  pigmentIndex: 'PBk9',
);

/// An all-oil palette so the AC-10 recipe is an oil mix the drying transform
/// (D-11) applies to; recipes never span media.
const PaintPalette PALETTE_OIL = PaintPalette(
  name: 'Oils',
  paints: [
    PAINT_TITANIUM_WHITE_OIL,
    PAINT_YELLOW_OCHRE_OIL,
    PAINT_IVORY_BLACK_OIL,
  ],
);

// ---------------------------------------------------------------------------
// Independent reference ΔE00
//
// A standalone CIEDE2000 (Sharma, Wu & Dalal 2005) the AC tests grade the
// product's `deltaE00` against, so AC-5 never checks the implementation against
// itself. Validated against Sharma et al.'s published test data (see
// recipes_test.dart's reference guard). This is test-only reference code; the
// shipped metric is `lib/compare/difference.dart`'s `deltaE00`.
// ---------------------------------------------------------------------------

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// The CIEDE2000 colour difference ΔE00 between [a] and [b] (reference, D-2).
double referenceDeltaE00(ColorCoordinates a, ColorCoordinates b) {
  const kL = 1.0, kC = 1.0, kH = 1.0;
  final l1 = a.lightness, a1 = a.a, b1 = a.b;
  final l2 = b.lightness, a2 = b.a, b2 = b.b;

  final c1 = math.sqrt(a1 * a1 + b1 * b1);
  final c2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar = (c1 + c2) / 2.0;

  final cBar7 = math.pow(cBar, 7).toDouble();
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + math.pow(25.0, 7))));

  final a1p = (1 + g) * a1;
  final a2p = (1 + g) * a2;

  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);

  double h1p = (a1p == 0 && b1 == 0) ? 0.0 : _deg(math.atan2(b1, a1p));
  if (h1p < 0) h1p += 360.0;
  double h2p = (a2p == 0 && b2 == 0) ? 0.0 : _deg(math.atan2(b2, a2p));
  if (h2p < 0) h2p += 360.0;

  final dLp = l2 - l1;
  final dCp = c2p - c1p;

  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0.0;
  } else {
    final diff = h2p - h1p;
    if (diff.abs() <= 180) {
      dhp = diff;
    } else if (diff > 180) {
      dhp = diff - 360;
    } else {
      dhp = diff + 360;
    }
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_rad(dhp / 2.0));

  final lBarp = (l1 + l2) / 2.0;
  final cBarp = (c1p + c2p) / 2.0;

  double hBarp;
  if (c1p * c2p == 0) {
    hBarp = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarp = (h1p + h2p) / 2.0;
  } else if (h1p + h2p < 360) {
    hBarp = (h1p + h2p + 360) / 2.0;
  } else {
    hBarp = (h1p + h2p - 360) / 2.0;
  }

  final t = 1 -
      0.17 * math.cos(_rad(hBarp - 30)) +
      0.24 * math.cos(_rad(2 * hBarp)) +
      0.32 * math.cos(_rad(3 * hBarp + 6)) -
      0.20 * math.cos(_rad(4 * hBarp - 63));

  final dTheta = 30 * math.exp(-math.pow((hBarp - 275) / 25.0, 2).toDouble());
  final cBarp7 = math.pow(cBarp, 7).toDouble();
  final rc = 2 * math.sqrt(cBarp7 / (cBarp7 + math.pow(25.0, 7)));
  final rt = -rc * math.sin(_rad(2 * dTheta));

  final sl = 1 +
      (0.015 * math.pow(lBarp - 50, 2)) /
          math.sqrt(20 + math.pow(lBarp - 50, 2));
  final sc = 1 + 0.045 * cBarp;
  final sh = 1 + 0.015 * cBarp * t;

  final termL = dLp / (kL * sl);
  final termC = dCp / (kC * sc);
  final termH = dHp / (kH * sh);

  return math.sqrt(
      termL * termL + termC * termC + termH * termH + rt * termC * termH);
}

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one recipes scenario.
///
/// Holds the recording speech sink the scenario injected (so AC-11/AC-12 can
/// read what was spoken) and exposes the `when…` actions the painter takes on
/// the Recipes screen, plus [controller] / [state] read seams over the live
/// [RecipeReadEndpoint] for the Thens the rendered UI does not surface directly
/// (the target, the selected palette, the ordered recipes with their ΔE00 /
/// verdict / flags, the wet/dry mode, the manual-entry error).
///
/// The screen's controls are inert in the SCREEN-1 shell; each `when…` drives
/// the real control and names the behaviour phase that wires it, so an AC test
/// written now fails cleanly at the red baseline (on a Then, or a Given
/// precondition naming the owner) rather than panicking.
class RecipesHarness {
  RecipesHarness(this.tester, {required this.speech});

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app (AC-11, AC-12).
  final FakeSpeech speech;

  /// The live recipe controller behind the screen, read through the acceptance
  /// [RecipeReadEndpoint] the home screen wraps its subtree in.
  RecipeController get controller => tester
      .widget<RecipeReadEndpoint>(find.byKey(RecipeReadEndpoint.endpointKey))
      .controller;

  /// The current observable recipe state (target, palette, recipes, mode,
  /// manual error).
  RecipeState get state => controller.state;

  /// Opens the target selector affordance (E22) without choosing, so a test can
  /// assert what it offers before picking. Inert until RECIPE-3; a disabled
  /// control absorbs no pointer, so `warnIfMissed` is off.
  Future<void> whenOpenTargetSelector() async {
    await tester.tap(
      find.widgetWithText(TextButton, 'Choose target'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Chooses the saved sample named [name] as the target (E22 → picker).
  ///
  /// Opens the selector and taps the catalogue entry for [name]. Until RECIPE-3
  /// drives the picker over [RecipeController.savedSamples] the control is inert
  /// and the picker never opens, so the precondition fails cleanly (naming the
  /// owner) rather than tapping an entry that is not in the tree.
  Future<void> whenChooseSavedTarget(String name) async {
    await whenOpenTargetSelector();
    expect(
      find.text(name),
      findsWidgets,
      reason: 'the target picker must list "$name" to choose it (RECIPE-3 E22)',
    );
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  /// Enters a manual CIELAB target [l]/[a]/[b] by hand (E22, AC-2).
  ///
  /// The manual-entry form is built by RECIPE-3; until then the precondition
  /// names the owner rather than entering into fields that do not exist. ITEST-2
  /// refines the field interaction to RECIPE-3's shipped form if it differs.
  Future<void> whenEnterManualTarget(double l, double a, double b) async {
    await whenOpenTargetSelector();
    final fields = find.byType(TextField);
    expect(
      fields,
      findsAtLeastNWidgets(3),
      reason: 'manual target entry needs L/a/b CIELAB fields (RECIPE-3 E22)',
    );
    await tester.enterText(fields.at(0), '$l');
    await tester.enterText(fields.at(1), '$a');
    await tester.enterText(fields.at(2), '$b');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  /// Switches the wet/dry prediction toggle to "Dry" (E24, AC-10).
  ///
  /// Inert until ENGINE-6; the disabled [SegmentedButton] absorbs no pointer, so
  /// `warnIfMissed` is off.
  Future<void> whenToggleWetDry() async {
    await tester.tap(
      find.descendant(
        of: find.byKey(ControlsRegion.regionKey),
        matching: find.text('Dry'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Asks to speak the target (E23, AC-11). Inert until RECIPE-4.
  Future<void> whenSpeakTarget() async {
    await tester.tap(
      find.widgetWithText(TextButton, 'Speak target'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Asks to speak the recipe at [index] in the list (E25, AC-12).
  ///
  /// A recipe must be shown (the list is filled by ENGINE-2) and the per-recipe
  /// speak control wired by RECIPE-4; until then the precondition names the
  /// owner. Inert control ⇒ `warnIfMissed` off.
  Future<void> whenSpeakRecipe(int index) async {
    final controls = find.widgetWithText(TextButton, 'Speak recipe');
    expect(
      controls,
      findsAtLeastNWidgets(index + 1),
      reason: 'a recipe must be shown to speak it (ENGINE-2 list; RECIPE-4 E25)',
    );
    await tester.tap(controls.at(index), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Opens the Recipes screen in the fully assembled app, mixing toward [target].
///
/// Builds the real app via the production `buildApp` entry with the recipes
/// entry wired (D-6): the [catalogue] saved samples, the [palette] owned paints
/// and the [mixingEngine] injected, the speech sink faked and the real
/// `ColorScienceImpl`. Defaults mix toward [SAMPLE_DEEP_OLIVE] over
/// [PALETTE_MY_PAINTS] with the shipped [SubtractiveMixingEngine]. Returns a
/// [RecipesHarness] over the booted app.
Future<RecipesHarness> givenRecipes(
  WidgetTester tester, {
  Sample target = SAMPLE_DEEP_OLIVE,
  List<Sample> catalogue = CATALOGUE,
  PaintPalette palette = PALETTE_MY_PAINTS,
  MixingEngine mixingEngine = const SubtractiveMixingEngine(),
}) async {
  final speech = FakeSpeech();
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: FakeHaptics(),
    sampleSource: InMemorySampleSource(samples: catalogue),
    paletteSource: InMemoryPaletteSource(catalogue: [palette]),
    mixingEngine: mixingEngine,
    recipesEntry: RecipesEntry(target: target),
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return RecipesHarness(tester, speech: speech);
}
