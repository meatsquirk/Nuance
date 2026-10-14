// bs-12 non-functional-requirements acceptance harness (ITEST-1).
//
// The Given/When/Then vocabulary and fixtures the bs-12 AC tests (ITEST-2,
// ITEST-3) are written against, layered over the reusable NFR guards in
// `integration_test/nfr/` (the GUARD + QUALITY shells) and the pending gate in
// `integration_test/bs12/pending.dart`.
//
// bs-12 is a *cross-cutting* feature: its ACs are verified over every feature
// merged on `main` at the branch point (bs-01..09 + bs-07 + bs-08), all
// assembled through the single production `buildApp` entry (D-7). So, unlike a
// single-feature harness that opens one screen, this one can launch `buildApp`
// into **each core flow** ([NfrFlow]) — the flows the offline / privacy guards
// sweep (capture, readout, compare, recipe search, save project + export, which
// both live on the Palette / Projects screen). Only the platform sinks
// ([Speech], [Haptics]) are faked; the real `ColorScienceImpl`, engines,
// `deltaE00` and capture controller are assembled, and the swap doubles
// ([swap_harness]) are injected through `AppDependencies` to prove the seams.
// No colour math is faked (D-7).
//
// ITEST-1 builds this vocabulary + a never-pending smoke test (`nfr_test.dart`)
// proving the shells are wired; ITEST-2/3 register the per-AC *pending* tests
// via [acTestWidgets]; the behaviour phases un-pend each AC.
//
// This is test-support only — no `lib/` product code (D-7). Fixture identifiers
// mirror the plan's names, so this file opts out of lowerCamelCase for them.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/palette/projects_region.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_controller.dart';
import 'package:paint_color_assistant/projects/project_read_endpoint.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_controller.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';
import 'package:paint_color_assistant/recipes/recipe_state.dart';
import 'package:paint_color_assistant/store/source_photo_store.dart';

import '../fakes/fake_capture_source.dart';
import '../fakes/fake_haptics.dart';
import '../fakes/fake_speech.dart';

// Re-export everything an AC test needs, so it imports this harness alone:
// the pending gate (`acTestWidgets`), the platform fakes, and the reusable NFR
// guards (offline / source / swap, accuracy / perf / synthetic set). The guard
// and quality modules are re-exported without a local import because the
// harness itself references none of their symbols directly — the AC tests do.
export '../fakes/fake_capture_source.dart';
export '../fakes/fake_haptics.dart';
export '../fakes/fake_speech.dart';
export '../nfr/guards/offline_guard.dart';
export '../nfr/guards/source_guard.dart';
export '../nfr/guards/swap_harness.dart';
export '../nfr/quality/accuracy_harness.dart';
export '../nfr/quality/perf_harness.dart';
export '../nfr/quality/synthetic_accuracy_set.dart';
export 'pending.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// The target colour a recipe-search flow ([NfrFlow.recipes]) opens mixing
/// toward — a reachable mid earth, so the real engine returns candidates.
const Sample nfrRecipeTarget = Sample(
  name: 'Warm Earth',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

/// The scene a [NfrFlow.capture] flow photographs — a deterministic
/// [SoftwareCaptureSource] scene with a known ground-truth colour (no colour or
/// sampling maths faked; only the frame feed).
const SceneSpec nfrCaptureScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
);

/// Builds the recording [FakeCaptureSource] a capture / correction flow reads.
FakeCaptureSource nfrCaptureSource() => FakeCaptureSource(nfrCaptureScene);

// --- AC-9 poor-condition scenes (reliability downgrade) ---------------------
//
// Each scene isolates one of the three poor conditions AC-9 names, over the
// same ground truth, so a committed reading can be observed for the honest
// downgrade. The trustworthy scene is the positive control: well lit, a
// reference card in view, and (once the painter locks) nothing to downgrade.

/// A well-lit scene with a reference card in view (AC-9 positive control). A
/// reading taken here — locked, then calibrated against the card — is
/// trustworthy and must stay calibrated (never downgraded).
const SceneSpec nfrTrustworthyScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
  referenceCardPresent: true,
);

/// A dimly lit scene (AC-9 low-light condition), card in view so the reading
/// would otherwise calibrate — the downgrade must come from the lighting.
const SceneSpec nfrLowLightScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
  lighting: Lighting.low,
  referenceCardPresent: true,
);

/// A well-lit scene with a reference card (AC-9 unlocked-exposure condition):
/// the condition is produced by committing *without* locking AE/AWB/AF, so the
/// reading has not settled and must be downgraded.
const SceneSpec nfrUnlockedScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
  referenceCardPresent: true,
);

/// A well-lit scene with **no** reference card in view (AC-9 missing-card
/// condition): the reading cannot be calibrated and must be labelled
/// approximate, never returned as trustworthy.
const SceneSpec nfrMissingCardScene = SceneSpec(
  groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
);

/// A small owned acrylic palette the recipe solver is constrained to, so a
/// [NfrFlow.recipes] launch returns real candidates toward [nfrRecipeTarget]
/// (the default [InMemoryPaletteSource] is empty). Mirrors the bs-04 "My paints"
/// palette; all local, no network.
const PaintPalette nfrPalette = PaintPalette(
  name: 'My paints',
  paints: <Paint>[
    Paint(
      id: 'pw6',
      name: 'Titanium White',
      medium: PaintMedium.acrylic,
      masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
      pigmentIndex: 'PW6',
    ),
    Paint(
      id: 'py43',
      name: 'Yellow Ochre',
      medium: PaintMedium.acrylic,
      masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
      pigmentIndex: 'PY43',
    ),
    Paint(
      id: 'pbk9',
      name: 'Ivory Black',
      medium: PaintMedium.acrylic,
      masstone: ColorCoordinates(lightness: 16, a: 0, b: 1),
      pigmentIndex: 'PBk9',
    ),
    Paint(
      id: 'pb29',
      name: 'Ultramarine Blue',
      medium: PaintMedium.acrylic,
      masstone: ColorCoordinates(lightness: 30, a: 18, b: -52),
      pigmentIndex: 'PB29',
    ),
    Paint(
      id: 'pr101',
      name: 'Venetian Red',
      medium: PaintMedium.acrylic,
      masstone: ColorCoordinates(lightness: 40, a: 32, b: 26),
      pigmentIndex: 'PR101',
    ),
  ],
);

/// The repo-relative directory holding the planted *offender* control fixtures
/// (ITEST-2), outside `lib/` so the real source sweep never sees them.
///
/// AC-7 / AC-8 / AC-16 / AC-17 point a source-guard rule at this root and assert
/// the planted offender is flagged — the discriminating control. The real
/// invariant sweep uses the default [kDefaultSourceRoots] (`lib/`).
const String kControlFixturesRoot = 'integration_test/nfr/fixtures/controls';

/// A project with one saved sample, seeded into a [NfrFlow.palette] launch so
/// AC-6 can open and export it (save + export are the Palette/Projects flow's
/// core functions). Carried through the local [InMemoryProjectSource], never a
/// network source.
const Project nfrSeededProject = Project(
  id: 'nfr-project-1',
  name: 'Offline Study',
  size: '16×20 in',
  samples: <Sample>[
    Sample(
      name: 'Warm Earth',
      coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
      provenance: Provenance(ProvenanceTier.measured),
    ),
  ],
);

// ---------------------------------------------------------------------------
// Core flows
// ---------------------------------------------------------------------------

/// A core flow the NFR guards sweep, selecting which screen [givenTheApp] opens
/// `buildApp` on (via its `AppDependencies` entry — the one production
/// assembly path, D-7).
///
/// These are the flows the offline (AC-1/2) and privacy (AC-6) guards run under
/// a network block, and the perf flows (AC-3 capture settle, AC-4 recipe
/// search). "Save project" and "export" both live on [palette] (the Palette /
/// Projects screen), so the six core functions map onto these five entries.
enum NfrFlow {
  /// bs-01 Readout on the injected initial sample (the default entry).
  readout,

  /// bs-02 Capture — a reading committed from the injected capture source.
  capture,

  /// bs-03 Comparison over the sample source.
  comparison,

  /// bs-04 Recipe search mixing toward [nfrRecipeTarget].
  recipes,

  /// bs-06 Palette / Projects — save project and export both live here.
  palette,
}

/// A driver over the assembled app launched into one [NfrFlow].
///
/// Holds the booted [tester] and the recording platform sinks the NFR Thens
/// read ([speech], [haptics]). ITEST-2/3 add the per-flow `when…` actions and
/// read-endpoint observations; ITEST-1 exposes only the launch + [settle], the
/// vocabulary the smoke test proves is wired.
class NfrHarness {
  NfrHarness(
    this.tester, {
    required this.flow,
    required this.speech,
    required this.haptics,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The core flow the app was launched into.
  final NfrFlow flow;

  /// The recording speech sink injected into the app.
  final FakeSpeech speech;

  /// The recording haptics sink injected into the app.
  final FakeHaptics haptics;

  /// Pumps until the UI is idle (no fixed sleeps — the acceptance grade rule).
  Future<void> settle() => tester.pumpAndSettle();

  // -------------------------------------------------------------------------
  // Read-endpoint observations (terminal state, through the acceptance seams)
  // -------------------------------------------------------------------------

  /// The live capture controller, read through [CaptureReadEndpoint].
  ///
  /// `skipOffstage: false` because a commit pushes Readout over the still-mounted
  /// Capture route, so the endpoint stays observable after the commit.
  CaptureController get captureController => tester
      .widget<CaptureReadEndpoint>(
        find.byKey(CaptureReadEndpoint.endpointKey, skipOffstage: false),
      )
      .controller;

  /// The current observable capture state (its committed reading, settling, …).
  CaptureState get captureState => captureController.state;

  /// The live recipe controller, read through [RecipeReadEndpoint].
  RecipeController get recipeController => tester
      .widget<RecipeReadEndpoint>(find.byKey(RecipeReadEndpoint.endpointKey))
      .controller;

  /// The current observable recipe state (its ranked candidates, out-of-gamut).
  RecipeState get recipeState => recipeController.state;

  /// The live project controller, read through [ProjectReadEndpoint].
  ProjectController get projectController => tester
      .widget<ProjectReadEndpoint>(find.byKey(ProjectReadEndpoint.endpointKey))
      .controller;

  // -------------------------------------------------------------------------
  // When-actions (through the real UI surface — never into components)
  // -------------------------------------------------------------------------

  Future<void> _tap(Key key, {bool warnIfMissed = true}) async {
    await tester.tap(find.byKey(key), warnIfMissed: warnIfMissed);
    await tester.pumpAndSettle();
  }

  /// The poor-capture conditions in effect at the live source (AC-9), read
  /// through the capture controller — the honest downgrade *inputs* the
  /// reliability fix (QUALITY-2) acts on. Empty in the trustworthy case.
  Set<AccuracyDowngradeReason> get activeDowngradeReasons =>
      captureController.activeDowngradeReasons;

  /// Locks AE/AWB/AF on the Capture screen (jumps stability to STABLE 12/12).
  Future<void> whenLockCapture() => _tap(CaptureControls.lockKey);

  /// Normalises the reading against the reference card and upgrades the stated
  /// accuracy to calibrated (E17) — a no-op when no card is in view.
  Future<void> whenCalibrate() => _tap(CaptureControls.calibrateKey);

  /// Commits the averaged reading on the Capture screen (E20).
  Future<void> whenCommitCapture() => _tap(CaptureControls.captureKey);

  /// Captures a committed reading end to end: lock, then commit. Leaves the
  /// committed [Sample] observable on [captureState].
  Future<void> whenCaptureCommittedReading() async {
    await whenLockCapture();
    await whenCommitCapture();
  }

  /// Opens the project named [name] in the Palette/Projects flow (switch to the
  /// Projects view, then tap its row) and exports it to the device. Leaves the
  /// produced PDF bytes observable on [projectController]'s `lastExport`.
  Future<void> whenOpenAndExportProject(String name) async {
    // Switch the view selector (E31) to Projects.
    await tester.tap(
      find.descendant(
        of: find.byKey(PaletteScreen.viewSelectorKey),
        matching: find.widgetWithText(TextButton, 'Projects'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    // Open the named project's row (scrolled into view — the rows can sit below
    // the test viewport).
    final row = find.descendant(
      of: find.byKey(ProjectsRegion.regionKey),
      matching: find.text(name),
    );
    await tester.ensureVisible(row.first);
    await tester.pumpAndSettle();
    await tester.tap(row.first);
    await tester.pumpAndSettle();
    // Export the opened project (E34).
    await tester.tap(find.byKey(ProjectsRegion.exportKey), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

/// Launches the Palette/Projects flow with [nfrSeededProject] already saved in a
/// local [InMemoryProjectSource], and [pdfShareSink] as the only (on-device)
/// export destination — the AC-6 setup (save + export with nothing off-device).
Future<NfrHarness> givenPaletteWithSeededProject(
  WidgetTester tester, {
  PdfShareSink? pdfShareSink,
}) =>
    givenTheApp(
      tester,
      flow: NfrFlow.palette,
      projectSource:
          const InMemoryProjectSource(catalogue: <Project>[nfrSeededProject]),
      pdfShareSink: pdfShareSink,
    );

// ---------------------------------------------------------------------------
// Swap doubles (AC-14 / AC-15)
// ---------------------------------------------------------------------------

/// A recording alternate [MixingEngine] (AC-14).
///
/// Proves the mixing-engine seam: injected via `AppDependencies.mixingEngine`,
/// it delegates to the shipped [SubtractiveMixingEngine] (so callers get correct
/// results through the interface) while counting the interface calls. A recipe
/// caller that reaches the engine only through [MixingEngine] drives this
/// alternate; [inverseCalls] stays 0 if no caller is exercised through it (the
/// ITEST-2 baseline — GUARD-5 extends the swap harness to drive the callers).
class RecordingMixingEngine implements MixingEngine {
  RecordingMixingEngine([this._delegate = const SubtractiveMixingEngine()]);

  final MixingEngine _delegate;

  /// How many times a caller invoked [inverse] (recipe search) through the seam.
  int inverseCalls = 0;

  /// How many times a caller invoked [forward] (mix preview) through the seam.
  int forwardCalls = 0;

  @override
  ColorCoordinates forward(Map<Paint, double> partsByVolume, {bool dry = false}) {
    forwardCalls++;
    return _delegate.forward(partsByVolume, dry: dry);
  }

  @override
  List<Recipe> inverse(Sample target, PaintPalette palette, MixOptions opts) {
    inverseCalls++;
    return _delegate.inverse(target, palette, opts);
  }
}

/// A recording alternate [ConfusionCheck] (AC-15, the CVD-model seam).
///
/// Injected via `AppDependencies.confusionCheck`, it delegates to the shipped
/// [DichromatConfusionCheck] while counting the interface calls. A CVD caller
/// (onboarding / compare / display) that reaches the model only through
/// [ConfusionCheck] drives this alternate; [confusableCalls] stays 0 if no
/// caller is exercised through it (the ITEST-2 baseline — GUARD-5 drives them).
class RecordingConfusionCheck implements ConfusionCheck {
  RecordingConfusionCheck([this._delegate = const DichromatConfusionCheck()]);

  final ConfusionCheck _delegate;

  /// How many times a caller invoked [confusable] through the seam.
  int confusableCalls = 0;

  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile) {
    confusableCalls++;
    return _delegate.confusable(a, b, profile);
  }
}

/// Launches the real assembled app (`buildApp`) into [flow] and returns a
/// driver over it.
///
/// The platform sinks are faked ([FakeSpeech] / [FakeHaptics]); the real
/// `ColorScienceImpl` is injected. [mixingEngine] and [confusionCheck] default
/// to the shipped implementations and are overridden by the swap doubles for
/// AC-14 / AC-15; [captureSource], when omitted for a [NfrFlow.capture] flow, is
/// the recording [nfrCaptureSource]. Each flow is opened through its
/// `AppDependencies` entry, exactly as production and the per-feature harnesses
/// enter it, so a guard that sweeps "every core flow" exercises the real path.
///
/// To run a scenario under the offline guard, wrap the whole body (this launch
/// and the subsequent actions) in `runUnderNetworkBlock` so the block stays
/// installed while the flow is driven.
Future<NfrHarness> givenTheApp(
  WidgetTester tester, {
  NfrFlow flow = NfrFlow.readout,
  Sample recipeTarget = nfrRecipeTarget,
  MixingEngine mixingEngine = const SubtractiveMixingEngine(),
  ConfusionCheck confusionCheck = const DichromatConfusionCheck(),
  CaptureSource? captureSource,
  PaletteSource paletteSource =
      const InMemoryPaletteSource(catalogue: <PaintPalette>[nfrPalette]),
  ProjectSource projectSource = const InMemoryProjectSource(),
  SourcePhotoStore? sourcePhotoStore,
  PdfShareSink? pdfShareSink,
}) async {
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final source = captureSource ??
      (flow == NfrFlow.capture ? nfrCaptureSource() : null);
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        mixingEngine: mixingEngine,
        confusionCheck: confusionCheck,
        paletteSource: paletteSource,
        projectSource: projectSource,
        sourcePhotoStore: sourcePhotoStore,
        pdfShareSink: pdfShareSink,
        // Entry precedence (see buildApp): capture source → Capture; comparison
        // entry → Comparison; recipes entry → Recipes; palette entry → Palette;
        // else Readout on the initial sample.
        captureSource: flow == NfrFlow.capture ? source : null,
        comparisonEntry:
            flow == NfrFlow.comparison ? const ComparisonEntry() : null,
        recipesEntry: flow == NfrFlow.recipes
            ? RecipesEntry(target: recipeTarget)
            : null,
        paletteEntry: flow == NfrFlow.palette ? const PaletteEntry() : null,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return NfrHarness(
    tester,
    flow: flow,
    speech: speech,
    haptics: haptics,
  );
}
