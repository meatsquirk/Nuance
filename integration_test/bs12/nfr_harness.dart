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

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';

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
  MixingEngine mixingEngine = const SubtractiveMixingEngine(),
  ConfusionCheck confusionCheck = const DichromatConfusionCheck(),
  CaptureSource? captureSource,
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
        // Entry precedence (see buildApp): capture source → Capture; comparison
        // entry → Comparison; recipes entry → Recipes; palette entry → Palette;
        // else Readout on the initial sample.
        captureSource: flow == NfrFlow.capture ? source : null,
        comparisonEntry:
            flow == NfrFlow.comparison ? const ComparisonEntry() : null,
        recipesEntry: flow == NfrFlow.recipes
            ? const RecipesEntry(target: nfrRecipeTarget)
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
