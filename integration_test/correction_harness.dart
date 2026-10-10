// Acceptance-suite harness for bs-05 Mix-correction loop (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures, scenes and independent reference the
// AC tests (ITEST-2, ITEST-3) are written against. The suite drives the *real*
// assembled app through the single production `buildApp` entry with the bs-05
// correction entry (D-9): a `CorrectionEntry(target, currentMix)`, the owned
// `PaletteSource` (the paints a correction can add) and a `FakeCaptureSource`
// configured to a ground-truth scene (the swatch the loop photographs). Only
// infrastructure is faked — the camera scene (`FakeCaptureSource`), the TTS sink
// (`FakeSpeech`) and the vibrator (`FakeHaptics`); no colour, mixing or ΔE00 math
// is faked. The real capture path, `CorrectionEngine`, `MixingEngine.forward`,
// `deltaE00`, controller, screen, routing, `Provenance` and `SampleSource` are
// exercised, and a scenario's ΔE00 is graded against [referenceDeltaE00], an
// independent CIEDE2000 so AC-2 never grades the impl against itself.
//
// The pending gate (all 10 ACs → owning phase) lives in `bs05/pending.dart`
// (seeded in LOOP-1); this harness re-exports it so an AC test imports only this
// file.
//
// Fixture identifiers mirror the plan's `SAMPLE_*` / `RECIPE_*` / `PALETTE_*` /
// `SCENE_*` names, and the AC catalogue references them verbatim, so this file
// opts out of lowerCamelCase for them.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/correction/correction_controller.dart';
import 'package:paint_color_assistant/correction/correction_read_endpoint.dart';
import 'package:paint_color_assistant/correction/correction_state.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

import 'fakes/fake_capture_source.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate and the fakes so an AC test only needs to import
// this harness.
export 'bs05/pending.dart';
export 'fakes/fake_capture_source.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// Samples and paint masstones are stored in canonical CIELAB (the domain's
// single source of truth). A fixture whose plan shape is given in CIELCh carries
// the exact polar form of that chroma/hue in a*/b* (a* = C·cos h, b* = C·sin h),
// since CIELCh is the polar form of CIELAB a*/b* by definition.
// ---------------------------------------------------------------------------

/// "Deep Olive Green" — the target the painter is correcting toward, reused from
/// bs-04's retargeted olive: CIELAB from CIELCh L 42 / C 24 / h 93° = (42,
/// −1.2561, 23.9671). The primary target. Drives AC-1, AC-2, AC-3, AC-4, AC-7,
/// AC-9, AC-10.
const Sample SAMPLE_DEEP_OLIVE = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -1.2561, b: 23.9671),
  provenance: Provenance(ProvenanceTier.estimated),
);

// --- Paints (masstone CIELAB + medium) — the owned "My paints", reused from
// bs-04 (same five paints and coordinates) ---------------------------------

/// Titanium White (acrylic) — a near-neutral high-lightness masstone; the paint
/// a "too dark" correction adds (AC-4).
const Paint PAINT_TITANIUM_WHITE = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
  pigmentIndex: 'PW6',
);

/// Yellow Ochre (acrylic) — a muted yellow earth; the paint a "needs more
/// yellow" trace correction adds (AC-5).
const Paint PAINT_YELLOW_OCHRE = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
  pigmentIndex: 'PY43',
);

/// Ivory Black (acrylic) — a very dark near-neutral.
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

/// Venetian Red (acrylic) — an earthy red.
const Paint PAINT_VENETIAN_RED = Paint(
  id: 'pr101',
  name: 'Venetian Red',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 40, a: 32, b: 26),
  pigmentIndex: 'PR101',
);

/// "My paints" — the owned acrylic palette the correction's additions are drawn
/// from (D-3): Titanium White, Yellow Ochre, Ivory Black, Ultramarine Blue and
/// Venetian Red, reused from bs-04. Drives AC-4, AC-5.
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

/// The current mix the painter made toward [SAMPLE_DEEP_OLIVE] — a bs-04 [Recipe]
/// over [PALETTE_MY_PAINTS] whose parts the correction search perturbs (AC-4,
/// AC-5). A warm olive built mostly from Yellow Ochre with Ivory Black for depth
/// and a little Titanium White; its [Recipe.predictedColor] is the *real*
/// [SubtractiveMixingEngine] forward prediction of these parts (not a hand-picked
/// colour), and its [Recipe.deltaE00] the independent reference distance of that
/// prediction from the target, so the fixture is self-consistent with the shipped
/// forward model the correction rides.
final Recipe RECIPE_DEEP_OLIVE = _buildCurrentMix();

/// The parts-by-volume of [RECIPE_DEEP_OLIVE] (shares summing to 1).
const Map<String, double> _deepOliveParts = {
  'py43': 0.55, // Yellow Ochre
  'pbk9': 0.25, // Ivory Black
  'pw6': 0.20, // Titanium White
};

Recipe _buildCurrentMix() {
  const engine = SubtractiveMixingEngine();
  final byPaint = <Paint, double>{
    for (final paint in PALETTE_MY_PAINTS.paints)
      if (_deepOliveParts.containsKey(paint.id))
        paint: _deepOliveParts[paint.id]!,
  };
  final predicted = engine.forward(byPaint);
  final components = [
    for (final paint in PALETTE_MY_PAINTS.paints)
      if (_deepOliveParts.containsKey(paint.id))
        RecipeComponent(paint: paint, partsFraction: _deepOliveParts[paint.id]!),
  ];
  return Recipe(
    medium: PaintMedium.acrylic,
    components: components,
    predictedColor: predicted,
    deltaE00: referenceDeltaE00(predicted, SAMPLE_DEEP_OLIVE.coordinates),
  );
}

// ---------------------------------------------------------------------------
// Scenes
//
// A scene is the ground-truth colour the painter's physical swatch really is;
// the correction loop photographs it through the injected [FakeCaptureSource]
// and reads it back as a *measured* [Sample] whose coordinates are (within the
// software source's sRGB round-trip) the scene's [SceneSpec.groundTruth]. Each
// scene's geometry relative to [SAMPLE_DEEP_OLIVE] is pinned by a guard in
// `correction_test.dart` against [referenceDeltaE00], so no scenario reasons
// about a scene whose distance it never checks.
// ---------------------------------------------------------------------------

/// A swatch read too dark and shifted toward green (CIELAB from CIELCh L 36 /
/// C 30 / h 114° = (36, −12.202, 27.406)): L 6 below the target (too dark by 6)
/// and hue 114° vs the target's 93° (toward green), ≈ ΔE00 10 off — a
/// comfortably "noticeably off" reading. Drives AC-1, AC-2, AC-3, AC-4, AC-7.
const SceneSpec SCENE_OFF = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 36, a: -12.202, b: 27.406),
);

/// A swatch read within ΔE00 2 of the target (≈ 0.96): the within-tolerance
/// case where no correction is offered, and the discriminating control for AC-2's
/// verdict (a close reading must read "very close", not "noticeably off"). Drives
/// AC-6; the AC-2 control.
const SceneSpec SCENE_CLOSE = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 42.5, a: -1.0, b: 22.3),
);

/// A swatch read one correction-step better than [SCENE_OFF] (the painter applied
/// the correction): ≈ ΔE00 5 — plainly closer than [SCENE_OFF] yet still beyond
/// tolerance, so a re-photograph shows a smaller ΔE / better verdict than before.
/// Drives AC-8.
const SceneSpec SCENE_CLOSER = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 39, a: -6.0, b: 25.5),
);

/// A swatch read slightly short of the target's yellow (b 18.5 vs the target's
/// 24.0), ≈ ΔE00 2.8 off — a small gap whose best correction is a sub-trace amount
/// of Yellow Ochre, rendered "a touch of". Drives AC-5.
const SceneSpec SCENE_OCHRE_TRACE = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 42, a: -1.3, b: 18.5),
);

/// The within-tolerance ΔE00 the "very close" / no-correction case sits inside
/// (D-6; the literal is confirmed via G-4). Used only to pin the scene geometry
/// in the fixture guards — the engine's own tolerance verdict is CORRECT-4's.
const double kToleranceDeltaE00 = 2.0;

// ---------------------------------------------------------------------------
// Independent reference ΔE00
//
// A standalone CIEDE2000 (Sharma, Wu & Dalal 2005) the AC tests grade the
// product's `deltaE00` against, so AC-2 never checks the implementation against
// itself. Validated against Sharma et al.'s published test data (see
// correction_test.dart's reference guard). This is test-only reference code; the
// shipped metric is `lib/compare/difference.dart`'s `deltaE00`.
// ---------------------------------------------------------------------------

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// The CIEDE2000 colour difference ΔE00 between [a] and [b] (reference, D-10).
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

/// A driver over the assembled app for one correction scenario.
///
/// Holds the injected [source] (the fake camera the scene was built into, so a
/// Then can reconfigure it for a re-photograph — AC-8) and the recording [speech]
/// sink (so AC-7 can read what was spoken), and exposes the `when…` actions the
/// painter takes on the Correction screen, plus [controller] / [state] read seams
/// over the live [CorrectionReadEndpoint] for the Thens the rendered UI does not
/// surface directly (the photographed swatch, the difference, the correction, the
/// within-tolerance flag, the promoted provenance).
///
/// The screen's controls are inert in the SCREEN-1 shell; each `when…` drives the
/// real control and names the behaviour phase that wires it, so an AC test written
/// now fails cleanly at the red baseline (on a Then, or a Given precondition
/// naming the owner) rather than panicking. A disabled control absorbs no pointer,
/// so each tap passes `warnIfMissed: false`.
class CorrectionHarness {
  CorrectionHarness(this.tester, {required this.source, required this.speech});

  /// The widget tester driving the real Correction UI surface.
  final WidgetTester tester;

  /// The fake capture source the scene was built into (its ground truth; a Then
  /// can swap its scene for the re-photograph — AC-8).
  final FakeCaptureSource source;

  /// The recording speech sink injected into the app (AC-7).
  final FakeSpeech speech;

  /// The live correction controller behind the screen, read through the
  /// acceptance [CorrectionReadEndpoint] the home screen wraps its subtree in.
  CorrectionController get controller => tester
      .widget<CorrectionReadEndpoint>(
        find.byKey(CorrectionReadEndpoint.endpointKey),
      )
      .controller;

  /// The current observable correction state (target, current mix, photographed
  /// swatch, difference, correction, saved provenance).
  CorrectionState get state => controller.state;

  /// Checks the mix: photographs the swatch (E26) and compares it to the target
  /// (AC-1).
  ///
  /// The check control is inert until LOOP-3 wires [CorrectionController.checkMix]
  /// to it; until then the tap is a no-op (disabled control), so an AC test fails
  /// cleanly on its Then (the state does not move) rather than panicking.
  Future<void> whenCheck() async {
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Check my mix'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Re-photographs the swatch (E28) and re-checks it against the target (AC-8).
  ///
  /// Inert until LOOP-5 wires [CorrectionController.rephotograph]; a test stages
  /// the better scene on [source] before calling this (the painter adjusted the
  /// mix), then asserts the difference improved.
  Future<void> whenRephotograph() async {
    await tester.tap(
      find.widgetWithText(TextButton, 'Re-photograph swatch'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Speaks the difference and the paints to add as one utterance (E27, AC-7).
  ///
  /// Inert until LOOP-4 wires [CorrectionController.speakCorrection]; until then
  /// nothing is appended to [speech], so AC-7 fails cleanly on its utterance Then.
  Future<void> whenSpeakCorrection() async {
    await tester.tap(
      find.widgetWithText(TextButton, 'Speak correction'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Saves the mix as confirmed (E29), promoting the target's provenance (AC-9).
  ///
  /// Inert until LOOP-6 wires [CorrectionController.saveConfirmed]; until then the
  /// state's saved provenance stays null, so AC-9 fails cleanly on its promotion
  /// Then.
  Future<void> whenSaveConfirmed() async {
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Save confirmed mix'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }
}

/// Opens the Correction screen in the fully assembled app, correcting
/// [currentMix] toward [target] with the swatch photographed from [scene].
///
/// Builds the real app via the production `buildApp` entry with the correction
/// entry wired (D-9): a [FakeCaptureSource] over [scene] is the camera, the
/// [palette] is the owned paints a correction can add, [catalogue] seeds the
/// saved-sample store a confirmed mix is persisted to and read back from
/// (AC-9/AC-10), the platform sinks are faked and colour-science is the real
/// `ColorScienceImpl`. Defaults correct [RECIPE_DEEP_OLIVE] toward
/// [SAMPLE_DEEP_OLIVE] over [PALETTE_MY_PAINTS] from [SCENE_OFF]. Returns a
/// [CorrectionHarness] over the booted app.
Future<CorrectionHarness> givenCorrection(
  WidgetTester tester, {
  Sample target = SAMPLE_DEEP_OLIVE,
  Recipe? currentMix,
  PaintPalette palette = PALETTE_MY_PAINTS,
  SceneSpec scene = SCENE_OFF,
  List<Sample> catalogue = const [],
}) async {
  // Open a *fresh* app each time. A repeated `givenCorrection` in one test (a
  // scenario that opens one scene then its control scene) would otherwise reuse
  // the previous `CorrectionHomeScreen` State — whose `late final`
  // CorrectionController is built once — so the screen would keep the first
  // scenario's controller, scene and target. Unmounting the prior tree first
  // disposes that State, so the next pump builds a new controller over these deps.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final source = FakeCaptureSource(scene);
  final speech = FakeSpeech();
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: FakeHaptics(),
    captureSource: source,
    sampleSource: InMemorySampleSource(samples: catalogue),
    paletteSource: InMemoryPaletteSource(catalogue: [palette]),
    correctionEntry:
        CorrectionEntry(target: target, currentMix: currentMix ?? RECIPE_DEEP_OLIVE),
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return CorrectionHarness(tester, source: source, speech: speech);
}
