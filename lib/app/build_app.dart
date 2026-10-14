import 'dart:async';

import 'package:flutter/material.dart';

import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import '../a11y/haptics.dart';
import '../a11y/repeatable_speech.dart';
import '../a11y/speech.dart';
import '../capture/capture_controller.dart';
import '../capture/capture_read_endpoint.dart';
import '../capture/capture_state.dart';
import '../capture/capture_screen.dart';
import '../capture/source/capture_source.dart';
import '../color_science/color_science.dart';
import '../correction/correction_controller.dart';
import '../correction/correction_read_endpoint.dart';
import '../correction/correction_screen.dart';
import '../correction/engine/correction_engine.dart';
import '../correction/engine/correction_engine_impl.dart';
import '../display/display_controller.dart';
import '../display/display_read_endpoint.dart';
import '../display/display_scope.dart';
import '../display/grayscale_filter.dart';
import '../display/settings_screen.dart';
import '../display/spoken_output_panel.dart';
import '../compare/comparison_controller.dart';
import '../compare/comparison_read_endpoint.dart';
import '../compare/comparison_screen.dart';
import '../compare/sample_source.dart';
import '../domain/color_coordinates.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import '../palette/palette_controller.dart';
import '../palette/palette_read_endpoint.dart';
import '../palette/palette_screen.dart';
import '../projects/project_controller.dart';
import '../projects/project_read_endpoint.dart';
import '../projects/project_source.dart';
import '../readout/readout_screen.dart';
import '../recipes/engine/mixing_engine.dart';
import '../recipes/engine/subtractive_engine.dart';
import '../recipes/palette_source.dart';
import '../recipes/recipe_controller.dart';
import '../recipes/recipe_read_endpoint.dart';
import '../recipes/recipes_screen.dart';
import '../store/cvd_profile_store.dart';
import '../store/persistent_store.dart';
import '../store/source_photo_store.dart';
import 'router.dart';

/// The sample the shipped bs-01 app opens the Readout screen on.
///
/// bs-01 ships the reading surface before capture exists (capture is bs-02,
/// D-1), so there is no painter-supplied sample yet. This fixed sample gives the
/// Readout a subject to render until bs-02 wires capture into
/// [AppDependencies.initialSample]. It is a plain [Sample] (canonical CIELAB +
/// provenance) with no derived values pre-computed — every presentable form is
/// derived by the COLOR behaviour phases from these coordinates.
const Sample demoSample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

/// Opt-in that opens the app on the Comparison screen (bs-03 D-8), symmetric to
/// bs-02's capture entry.
///
/// When [AppDependencies.comparisonEntry] carries one, [buildApp] launches to
/// the [ComparisonHomeScreen] — a comparison over [AppDependencies.sampleSource]
/// for [AppDependencies.cvdProfile] via [AppDependencies.confusionCheck] — so
/// the acceptance harness and a later production shortcut both enter comparison
/// through the one assembly entry. null (the default) preserves bs-01's Readout
/// entry. A marker for now; bs-06 may extend it (e.g. a pre-selected pair).
class ComparisonEntry {
  /// Creates the comparison-entry marker.
  const ComparisonEntry();
}

/// Opt-in that opens the app on the Recipes screen for a given mixing [target]
/// (bs-04 D-6), symmetric to bs-02's capture entry and bs-03's comparison entry.
///
/// When [AppDependencies.recipesEntry] carries one, [buildApp] launches to the
/// [RecipesHomeScreen] — a `RecipeController` over
/// [AppDependencies.sampleSource] / [AppDependencies.paletteSource] /
/// [AppDependencies.mixingEngine] mixing toward [target] — so the acceptance
/// harness enters the Recipes feature through the one assembly entry. Unlike the
/// comparison entry this carries a [target], because a recipe is always toward a
/// specific colour. null (the default) preserves bs-01's Readout entry.
class RecipesEntry {
  /// Creates the recipes-entry marker for mixing toward [target].
  const RecipesEntry({required this.target});

  /// The colour the Recipes screen opens mixing toward.
  final Sample target;
}

/// Opt-in that opens the app on the Correction screen for a [currentMix] the
/// painter mixed toward [target] (bs-05 D-2), symmetric to bs-04's recipes
/// entry.
///
/// When [AppDependencies.correctionEntry] carries one, [buildApp] launches to
/// the [CorrectionHomeScreen] — a `CorrectionController` photographing the
/// swatch through [AppDependencies.captureSource] and reading it through
/// [AppDependencies.correctionEngine] — so the acceptance harness enters the
/// loop through the one assembly entry. It is checked **before**
/// [AppDependencies.captureSource] because the correction loop *reuses* the
/// injected capture source as its own camera (D-2); setting the capture source
/// alone still opens bs-02's Capture screen. Like the recipes entry it carries a
/// [currentMix], because a correction is always against a specific mix toward a
/// specific colour. null (the default) preserves bs-01's Readout entry.
class CorrectionEntry {
  /// Creates the correction-entry marker for [currentMix] toward [target].
  const CorrectionEntry({required this.target, required this.currentMix});

  /// The colour the mixed swatch is corrected toward.
  final Sample target;

  /// The recipe the painter mixed toward [target] — the correction adds to it.
  final Recipe currentMix;
}

/// Opt-in that opens the app on the Palette screen (bs-06 SCREEN-1), symmetric
/// to the capture / comparison / recipes entries.
///
/// When [AppDependencies.paletteEntry] carries one, [buildApp] launches to the
/// [PaletteHomeScreen] — a `PaletteController` over [AppDependencies.paletteSource]
/// and a `ProjectController` over [AppDependencies.projectSource], both wrapped
/// in the read endpoints the acceptance suite observes — so the bs-06 harness
/// enters the Palette feature through the one assembly entry. null (the default)
/// preserves the app's capture entry; the shipped app does not set it (the
/// Palette screen is reached by later navigation), but the persistent paint and
/// project sources are still wired in production so the screen reads real data
/// when it is shown.
class PaletteEntry {
  /// Creates the palette-entry marker.
  const PaletteEntry();
}

/// Loads the painter's saved colour-vision profile at app assembly, or the
/// const default when none is stored (bs-07 D-3, G-4).
///
/// Production assembly (`main.dart`'s `productionDependencies`) calls this with
/// a [CvdProfileStore] over the file-backed store and passes the result as
/// [AppDependencies.cvdProfile], so a measured profile configures bs-03's
/// `ConfusionCheck` and the shared `projectDichromat` seam bs-08/bs-10 reuse.
/// Absent (nothing saved yet) → the deutan default, so behaviour is unchanged
/// until the painter saves an assessment (PROFILE-2, AC-13).
Future<CvdProfile> loadCvdProfile(CvdProfileStore store) async =>
    await store.load() ?? const CvdProfile(type: CvdType.deutan);

/// The app-wide services assembled once at startup and injected down the tree.
///
/// A single immutable holder so production (`main.dart`) and the acceptance
/// harness (ITEST-1) construct the app the same way, differing only in which
/// implementations they pass — the harness swaps the faked platform sinks
/// ([Speech], [Haptics]) and a test [ColorScience] while reusing [buildApp].
class AppDependencies {
  const AppDependencies({
    required this.colorScience,
    required this.speech,
    required this.haptics,
    this.router = const AppRouter(),
    this.initialSample = demoSample,
    this.captureSource,
    this.cvdProfile = const CvdProfile(type: CvdType.deutan),
    this.confusionCheck = const DichromatConfusionCheck(),
    this.sampleSource = const InMemorySampleSource(),
    this.comparisonEntry,
    this.mixingEngine = const SubtractiveMixingEngine(),
    this.correctionEngine = const SubtractiveCorrectionEngine(),
    this.paletteSource = const InMemoryPaletteSource(),
    this.recipesEntry,
    this.correctionEntry,
    this.projectSource = const InMemoryProjectSource(),
    this.paletteEntry,
    this.store,
    this.sourcePhotoStore,
    this.pdfShareSink,
    this.displayController,
  });

  /// Derives every presentable form of a sample's colour (COLOR stub for now).
  final ColorScience colorScience;

  /// Spoken output sink (A11Y stub for now; faked in the acceptance suite).
  final Speech speech;

  /// Haptic feedback sink (A11Y stub for now; faked in the acceptance suite).
  final Haptics haptics;

  /// Typed navigation into the comparison / recipes destinations.
  final AppRouter router;

  /// The sample the app opens the Readout screen on.
  ///
  /// bs-01 has no capture yet (D-1), so production defaults to [demoSample]; the
  /// acceptance harness injects a fixture here to read each scenario's sample
  /// through this same [buildApp] entry (capture replaces it in bs-02).
  final Sample initialSample;

  /// The capture source the app opens the Capture screen on, or null to open on
  /// the Readout (bs-02 D-2).
  ///
  /// When present, [buildApp] launches to the Capture screen reading from this
  /// source and capture commits navigate to the Readout (D-5); when null the app
  /// opens on the Readout for [initialSample], preserving bs-01's entry. The
  /// shipped app injects a [CaptureSource]; the bs-02 acceptance harness injects
  /// a fake with a known ground-truth scene.
  final CaptureSource? captureSource;

  /// The painter's colour-vision profile, read by [confusionCheck] (bs-03 D-4).
  ///
  /// Defaults to a deutan profile for bs-03's comparison scenarios; **bs-07**
  /// (CVD self-assessment) later populates it from the painter. Injected here so
  /// the confusion detector and the later simulation/daltonization features
  /// (bs-08/bs-10) all read one profile.
  final CvdProfile cvdProfile;

  /// Decides whether a compared pair is confusable for [cvdProfile] (AC-7/AC-8).
  ///
  /// Defaults to the shipped [DichromatConfusionCheck] (CVD-2's Viénot 1999
  /// dichromat projection, D-4/D-5); inject [NoopConfusionCheck] to disable
  /// detection.
  final ConfusionCheck confusionCheck;

  /// The saved-sample catalogue the comparison picker lists (bs-03 D-7).
  ///
  /// Defaults to an empty [InMemorySampleSource]; **COMPARE-3** injects one
  /// seeded with the saved samples, and **bs-06** later supplies a persistent
  /// store behind the same [SampleSource] interface. Read both by the comparison
  /// entry and by the Readout → compare handoff so a carried sample lands in a
  /// comparison that can still offer the catalogue for the other slot.
  final SampleSource sampleSource;

  /// Opens the app on the Comparison screen when present (bs-03 D-8).
  ///
  /// null (the default) keeps bs-01's Readout entry; a [ComparisonEntry] makes
  /// [buildApp] launch to the [ComparisonHomeScreen] over [sampleSource] /
  /// [cvdProfile] / [confusionCheck]. The bs-03 acceptance harness injects one
  /// to drive each comparison scenario through this same assembly entry.
  final ComparisonEntry? comparisonEntry;

  /// The mixing engine the Recipes feature solves through (bs-04 D-2/D-6).
  ///
  /// Defaults to the shipped v1 [SubtractiveMixingEngine]; **RECIPE-2** passes it
  /// to the `RecipeController` so the controller never computes mixing math
  /// itself, and the measured-pigment engine
  /// (`docs/custom-mixing-engine-design.md`) is the deferred swap-in behind the
  /// same [MixingEngine] interface. A shell for now — no screen reads it yet.
  final MixingEngine mixingEngine;

  /// The correction engine the Mix-correction loop reads a checked mix through
  /// (bs-05 D-2/D-3).
  ///
  /// Defaults to the shipped stub [SubtractiveCorrectionEngine]; **LOOP-2**
  /// passes it to the `CorrectionController` so the controller never computes
  /// the difference or the correction itself, and the measured-pigment engine is
  /// the deferred swap-in behind the same [CorrectionEngine] interface. A shell
  /// for now — no screen reads it yet (LOOP-2 wires the controller).
  final CorrectionEngine correctionEngine;

  /// The owned palettes the Recipes solver is constrained to choose among
  /// (bs-04 D-5).
  ///
  /// Defaults to an empty [InMemoryPaletteSource]; the bs-04 acceptance harness
  /// injects one seeded with named palettes, and **bs-06** later supplies a
  /// persistent store behind the same [PaletteSource] interface. Read by the
  /// [RecipesHomeScreen]'s `RecipeController`.
  final PaletteSource paletteSource;

  /// Opens the app on the Recipes screen for a target when present (bs-04 D-6).
  ///
  /// null (the default) keeps bs-01's Readout entry; a [RecipesEntry] makes
  /// [buildApp] launch to the [RecipesHomeScreen] over [sampleSource] /
  /// [paletteSource] / [mixingEngine], mixing toward the entry's target. The
  /// bs-04 acceptance harness injects one to drive each recipes scenario through
  /// this same assembly entry.
  final RecipesEntry? recipesEntry;

  /// Opens the app on the Correction screen for a mix when present (bs-05 D-2).
  ///
  /// null (the default) keeps bs-01's Readout entry; a [CorrectionEntry] makes
  /// [buildApp] launch to the [CorrectionHomeScreen], correcting the entry's
  /// [CorrectionEntry.currentMix] toward its [CorrectionEntry.target]. It wins
  /// over [captureSource] (the loop reuses that source as its camera), so the
  /// bs-05 acceptance harness injects a correction entry **and** a fake capture
  /// source to drive each correction scenario through this one assembly entry.
  final CorrectionEntry? correctionEntry;

  /// The painter's projects the Palette screen's Projects view lists (bs-06
  /// PROJECT-1).
  ///
  /// Defaults to an empty [InMemoryProjectSource]; **PROJECT-1** builds the
  /// persistent `ProjectSource` over [store], the production wiring injects a
  /// store-backed one here (loaded before assembly), and the acceptance harness
  /// injects an in-memory-backed one. Read by the [PaletteHomeScreen]'s
  /// `ProjectController`.
  final ProjectSource projectSource;

  /// Opens the app on the Palette screen when present (bs-06 SCREEN-1).
  ///
  /// null (the default) keeps the app's capture entry; a [PaletteEntry] makes
  /// [buildApp] launch to the [PaletteHomeScreen] over [paletteSource] /
  /// [projectSource] / [cvdProfile]. The bs-06 acceptance harness injects one to
  /// drive each palette/project scenario through this same assembly entry; the
  /// shipped app leaves it null.
  final PaletteEntry? paletteEntry;

  /// The on-device persistent store the bs-06 palette/project sources write
  /// through (DATA-2, plan D-1), or null when no persistence is wired.
  ///
  /// null (the default) preserves today's in-memory-only assembly: no screen
  /// reads the store yet, so [buildApp] does not branch on it. **PALETTE-1** and
  /// **PROJECT-1** build the persistent `PaletteSource` / `ProjectSource` /
  /// write-side `SampleSource` over this seam, and the production wiring injects
  /// a file-backed [DriftPersistentStore] here (the platform-wiring step that
  /// also adds path_provider + the sqlite native libs, deferred like bs-02's
  /// native capture). The acceptance harness injects an
  /// [InMemoryPersistentStore] so the suite runs without a real database.
  final PersistentStore? store;

  /// The on-device source-photo sink a project's photo is stored through
  /// (DATA-2, plan D-10), or null when no persistence is wired.
  ///
  /// Paired with [store]: the project keeps only the reference this sink
  /// returns, never the pixels. null (the default) keeps today's assembly;
  /// PROJECT-1 consumes it, production injects a [FileSourcePhotoStore] over the
  /// application-documents directory, and the acceptance harness injects an
  /// [InMemorySourcePhotoStore].
  final SourcePhotoStore? sourcePhotoStore;

  /// The sink an exported project PDF is handed to for device delivery (bs-06
  /// AC-10, PROJECT-6), or null when none is wired.
  ///
  /// Threaded into the [ProjectController]: production injects the `printing`
  /// share sheet (`main.dart`), and the acceptance harness leaves it null so the
  /// export only produces `ProjectController.lastExport` bytes (plan D-6, no
  /// disk file, no device popup during a test).
  final PdfShareSink? pdfShareSink;

  /// The app-wide display-settings controller (bs-08 DISPLAY-2), or null to let
  /// [buildApp] create and own a default one.
  ///
  /// null (the default) keeps today's assembly: [buildApp] builds a fresh
  /// [DisplayController] whose [DisplayController.defaultSimulationType] is the
  /// painter's [cvdProfile] type (D-2), owns it, and disposes it with the tree.
  /// The bs-08 acceptance harness injects its own so it can both drive the
  /// setters and observe the resulting view; an injected controller is owned by
  /// its injector, not by [buildApp].
  final DisplayController? displayController;

  /// Returns a copy of these dependencies with only [cvdProfile] replaced
  /// (bs-07 AC-13, D-3).
  ///
  /// The one seam a saved self-assessment changes: [buildApp]'s root re-injects
  /// the measured profile here so bs-03's `ConfusionCheck` and the bs-08/bs-10
  /// projection — all reading `AppDependencies.cvdProfile` — reconfigure off the
  /// default immediately, leaving every other injected service untouched.
  AppDependencies withCvdProfile(CvdProfile cvdProfile) => AppDependencies(
        colorScience: colorScience,
        speech: speech,
        haptics: haptics,
        router: router,
        initialSample: initialSample,
        captureSource: captureSource,
        cvdProfile: cvdProfile,
        confusionCheck: confusionCheck,
        sampleSource: sampleSource,
        comparisonEntry: comparisonEntry,
        mixingEngine: mixingEngine,
        correctionEngine: correctionEngine,
        paletteSource: paletteSource,
        recipesEntry: recipesEntry,
        correctionEntry: correctionEntry,
        projectSource: projectSource,
        paletteEntry: paletteEntry,
        store: store,
        sourcePhotoStore: sourcePhotoStore,
        pdfShareSink: pdfShareSink,
        displayController: displayController,
      );
}

/// Exposes the app-wide [AppDependencies] to descendant widgets.
///
/// The Readout screen and its controller (READOUT-1) read the injected services
/// through [AppScope.of] rather than constructing them, so the same screen runs
/// unchanged against the production stubs and the acceptance suite's fakes.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  /// The services injected at the root by [buildApp].
  final AppDependencies dependencies;

  /// The [AppDependencies] injected by the nearest enclosing [AppScope].
  ///
  /// Throws if no [AppScope] is above [context]; every screen built by
  /// [buildApp] has one.
  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget.');
    return scope!.dependencies;
  }

  /// The [AppDependencies] from the nearest enclosing [AppScope], or null when
  /// there is none above [context] — for surfaces (such as `ColorChip`) that
  /// must also render standalone, outside the app assembly, where they fall
  /// back to a default (e.g. the stored CVD profile for daltonization, bs-10).
  static AppDependencies? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.dependencies;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

/// Builds the root widget of the Paint Color Assistant.
///
/// The single production assembly entry (D-7): it injects [deps] via [AppScope]
/// and wires the router into a [MaterialApp]. The app opens on the
/// [CorrectionHomeScreen] when a [AppDependencies.correctionEntry] is injected
/// (bs-05 D-2 — checked first, as the loop reuses the capture source as its
/// camera), on the Capture screen when a [AppDependencies.captureSource] is
/// injected (bs-02), on the [ComparisonHomeScreen] when a
/// [AppDependencies.comparisonEntry] is injected (bs-03 D-8), on the
/// [RecipesHomeScreen] when a [AppDependencies.recipesEntry] is injected (bs-04
/// D-6), on the [PaletteHomeScreen] when a [AppDependencies.paletteEntry] is
/// injected (bs-06 SCREEN-1), and otherwise on the [ReadoutScreen] for
/// [AppDependencies.initialSample] (bs-01's entry). `main.dart` and the
/// acceptance harnesses construct the app through this one entry, differing only
/// in the injected services, the initial sample, the capture source and the
/// comparison / recipes entries.
Widget buildApp(AppDependencies deps) {
  // Make the one app-wide [Speech] repeatable (bs-08 SPEECH-1): wrap the
  // injected sink in a [RepeatableSpeech] so every caller that speaks through
  // it (readout via [AppScope], comparison, recipes) can be replayed by the
  // spoken-output panel (E50), and the inner sink still records each utterance
  // for the acceptance suite. An already-repeatable injected speech is reused
  // as-is (its injector owns it); otherwise [buildApp] wraps and owns it, and
  // re-provides it through [AppScope] so the readout's controller picks it up.
  final injectedSpeech =
      deps.speech is RepeatableSpeech ? deps.speech as RepeatableSpeech : null;
  final speech = injectedSpeech ?? RepeatableSpeech(deps.speech);
  final scopedDeps =
      injectedSpeech == null ? _depsWithSpeech(deps, speech) : deps;
  return _App(
    deps: scopedDeps,
    speech: speech,
    ownsSpeech: injectedSpeech == null,
  );
}

/// The root widget, holding the live colour-vision profile the app's pipeline
/// reads so a saved self-assessment can reconfigure it (bs-07 AC-13, D-3).
///
/// Seeds the live profile from the injected [AppDependencies.cvdProfile] and
/// hands [_home] the dependencies unchanged until the painter saves an
/// assessment; the save calls back through the [LiveProfileScope] mounted above
/// the [MaterialApp], which re-injects the measured profile on the one seam all
/// CVD consumers read. Stateful because the live profile outlives any one route
/// (the onboarding is pushed on top of the running app and popped on save).
///
/// Beneath [LiveProfileScope] it mounts the bs-08 display and speech roots
/// (`_DisplayRoot` + `_SpeechRoot`) and the shared chrome, so simulation,
/// value-only grayscale and the spoken-output panel wrap every screen.
class _App extends StatefulWidget {
  const _App({
    required this.deps,
    required this.speech,
    required this.ownsSpeech,
  });

  /// The speech-scoped dependencies injected at assembly; its
  /// [AppDependencies.cvdProfile] seeds the mutable live profile.
  final AppDependencies deps;

  /// The app-wide repeatable speech (bs-08 SPEECH-1) provided to [_SpeechRoot].
  final RepeatableSpeech speech;

  /// Whether [buildApp] wrapped [speech] (and so [_SpeechRoot] must dispose it);
  /// an injected repeatable speech is owned by its injector.
  final bool ownsSpeech;

  @override
  State<_App> createState() => _AppState();
}

class _AppState extends State<_App> {
  /// The live colour-vision profile the pipeline reads (bs-07 AC-13). Seeded
  /// from the injected profile; a saved assessment replaces it so bs-03's
  /// confusion check and the bs-08/bs-10 projection reconfigure immediately.
  late CvdProfile _profile = widget.deps.cvdProfile;

  /// The profile store the live pipeline re-reads on a saved change (bs-10
  /// DALT-11, AC-6), or null when no persistence is wired (bare unit trees).
  CvdProfileStore? _profileStore;

  @override
  void initState() {
    super.initState();
    // Listen to the stored profile so a save recomputes the live pipeline even
    // when it is written straight to the store rather than through the
    // onboarding callback (AC-6) — the acceptance path that bypasses
    // [LiveProfileScope]. Production saves go through both paths; the re-read is
    // idempotent, so the extra signal never double-applies a change.
    final store = widget.deps.store;
    if (store != null) {
      _profileStore = CvdProfileStore(store);
      _profileStore!.changes.addListener(_handleStoreChanged);
    }
  }

  /// Replaces the live profile with the one a save just wrote (AC-13), rebuilding
  /// the tree so later-built CVD consumers read the measured profile.
  void _handleProfileSaved(CvdProfile profile) {
    setState(() => _profile = profile);
  }

  /// Re-reads the saved profile when the store changes, so a saved
  /// deutan→protan change recomputes the live daltonization remap (AC-6).
  void _handleStoreChanged() {
    unawaited(_reloadProfile());
  }

  /// Loads the current saved profile and adopts it when it differs from the live
  /// one; falls back to the injected default when the store was cleared.
  Future<void> _reloadProfile() async {
    final loaded = await _profileStore!.load();
    if (!mounted) return;
    final next = loaded ?? widget.deps.cvdProfile;
    if (next != _profile) setState(() => _profile = next);
  }

  @override
  void dispose() {
    _profileStore?.changes.removeListener(_handleStoreChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Inject the dependencies unchanged until a save replaces the profile, so the
    // startup tree still carries the exact injected deps object (bs-01..06
    // wiring); once the painter saves, re-inject with the measured profile on the
    // single seam every CVD consumer reads.
    final deps = _profile == widget.deps.cvdProfile
        ? widget.deps
        : widget.deps.withCvdProfile(_profile);
    return AppScope(
      dependencies: deps,
      child: LiveProfileScope(
        onProfileSaved: _handleProfileSaved,
        child: _DisplayRoot(
          injectedController: widget.deps.displayController,
          defaultSimulationType: widget.deps.cvdProfile.type,
          child: _SpeechRoot(
            speech: widget.speech,
            owns: widget.ownsSpeech,
            child: MaterialApp(
              title: 'Paint Color Assistant',
              theme: ThemeData(useMaterial3: true),
              // The shared app chrome: the open-display-settings entry (E2) on
              // every screen (SETTINGS-1) and, beneath it, the persistent
              // spoken-output panel (E50 — SPEECH-1) that replays the last
              // utterance.
              builder: (context, child) =>
                  DisplayChrome(child: _SpokenOutputChrome(child: child!)),
              home: _home(deps),
            ),
          ),
        ),
      ),
    );
  }
}

/// The screen [buildApp] opens on for [deps] (the entry precedence in the
/// [buildApp] doc): correction, then capture, comparison, recipes, palette, else
/// the Readout. [deps] carries the app-wide [RepeatableSpeech] as its `speech`,
/// so each screen speaks through the repeatable seam.
Widget _home(AppDependencies deps) {
  return deps.correctionEntry != null
      ? CorrectionHomeScreen(
          target: deps.correctionEntry!.target,
          currentMix: deps.correctionEntry!.currentMix,
          captureSource: deps.captureSource!,
          paletteSource: deps.paletteSource,
          correctionEngine: deps.correctionEngine,
          mixingEngine: deps.mixingEngine,
          sampleSource: deps.sampleSource,
          speech: deps.speech,
          router: deps.router,
        )
      : deps.captureSource != null
          ? const CaptureHomeScreen()
          : deps.comparisonEntry != null
              ? ComparisonHomeScreen(
                  sampleSource: deps.sampleSource,
                  cvdProfile: deps.cvdProfile,
                  confusionCheck: deps.confusionCheck,
                  speech: deps.speech,
                  router: deps.router,
                )
              : deps.recipesEntry != null
                  ? RecipesHomeScreen(
                      target: deps.recipesEntry!.target,
                      sampleSource: deps.sampleSource,
                      paletteSource: deps.paletteSource,
                      mixingEngine: deps.mixingEngine,
                      speech: deps.speech,
                      router: deps.router,
                    )
                  : deps.paletteEntry != null
                      ? const PaletteHomeScreen()
                      : ReadoutScreen(sample: deps.initialSample);
}

/// Exposes the callback the self-assessment calls after saving a profile, so the
/// app root can reconfigure the live `AppDependencies.cvdProfile` (bs-07 AC-13,
/// D-3).
///
/// Mounted by [buildApp] above the [MaterialApp]; the onboarding host reads it
/// ([of]) and hands it to its `OnboardingController`. Absent when the host is
/// pumped outside [buildApp] (bare unit tests) — [of] then returns null and the
/// save only writes the store.
class LiveProfileScope extends InheritedWidget {
  /// Creates the scope exposing [onProfileSaved] to the subtree.
  const LiveProfileScope({
    required this.onProfileSaved,
    required super.child,
    super.key,
  });

  /// Called with the saved profile to reconfigure the live pipeline (AC-13).
  final ValueChanged<CvdProfile> onProfileSaved;

  /// The nearest enclosing scope's callback, or null when none is mounted.
  static ValueChanged<CvdProfile>? of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LiveProfileScope>()
          ?.onProfileSaved;

  @override
  bool updateShouldNotify(LiveProfileScope oldWidget) =>
      onProfileSaved != oldWidget.onProfileSaved;
}

/// Returns a copy of [deps] with its [AppDependencies.speech] replaced by
/// [speech], preserving every other injected service (bs-08 SPEECH-1).
///
/// Used by [buildApp] to re-provide the app-wide [RepeatableSpeech] wrapper
/// through [AppScope] so the readout's controller — which reads
/// `AppScope.of(context).speech` — speaks through the repeatable seam.
AppDependencies _depsWithSpeech(AppDependencies deps, Speech speech) {
  return AppDependencies(
    colorScience: deps.colorScience,
    speech: speech,
    haptics: deps.haptics,
    router: deps.router,
    initialSample: deps.initialSample,
    captureSource: deps.captureSource,
    cvdProfile: deps.cvdProfile,
    confusionCheck: deps.confusionCheck,
    sampleSource: deps.sampleSource,
    comparisonEntry: deps.comparisonEntry,
    mixingEngine: deps.mixingEngine,
    correctionEngine: deps.correctionEngine,
    paletteSource: deps.paletteSource,
    recipesEntry: deps.recipesEntry,
    correctionEntry: deps.correctionEntry,
    projectSource: deps.projectSource,
    paletteEntry: deps.paletteEntry,
    store: deps.store,
    sourcePhotoStore: deps.sourcePhotoStore,
    pdfShareSink: deps.pdfShareSink,
    displayController: deps.displayController,
  );
}

/// Owns the app-wide [DisplayController] and exposes it to the whole tree
/// (bs-08 DISPLAY-2).
///
/// A small stateful root so the default controller [buildApp] creates has a
/// lifecycle to be disposed with the app, while an [injectedController] (the
/// acceptance harness's, or `main.dart`'s) is left for its injector to own. It
/// wraps [child] (the `MaterialApp`) in the [DisplayScope] every colour surface
/// reads and the [DisplayReadEndpoint] the acceptance suite observes, with the
/// inert root [GrayscaleFilter] directly around the app (DISPLAY-7 makes it
/// active). Placed above the `MaterialApp` so pushed routes read the scope too.
class _DisplayRoot extends StatefulWidget {
  const _DisplayRoot({
    required this.injectedController,
    required this.defaultSimulationType,
    required this.child,
  });

  /// The controller to use, or null to create and own a default one.
  final DisplayController? injectedController;

  /// The type a created default controller pre-selects for simulation (D-2).
  final CvdType defaultSimulationType;

  /// The app subtree (the `MaterialApp`) wrapped in the display layer.
  final Widget child;

  @override
  State<_DisplayRoot> createState() => _DisplayRootState();
}

class _DisplayRootState extends State<_DisplayRoot> {
  late final DisplayController _controller;

  /// Whether this state created [_controller] and must dispose it (an injected
  /// controller is owned by its injector).
  late final bool _owned;

  @override
  void initState() {
    super.initState();
    final injected = widget.injectedController;
    _owned = injected == null;
    _controller = injected ??
        DisplayController(defaultSimulationType: widget.defaultSimulationType);
  }

  @override
  void dispose() {
    if (_owned) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DisplayScope(
      controller: _controller,
      child: DisplayReadEndpoint(
        key: DisplayReadEndpoint.endpointKey,
        controller: _controller,
        child: GrayscaleFilter(child: widget.child),
      ),
    );
  }
}

/// Exposes the app-wide [RepeatableSpeech] to the whole tree and owns its
/// lifecycle when [buildApp] created it (bs-08 SPEECH-1).
///
/// A small stateful root, symmetric to [_DisplayRoot]: it wraps [child] (the
/// `MaterialApp`) in the [SpeechScope] the spoken-output panel (E50) reads, and
/// disposes the [RepeatableSpeech] with the tree when it [owns] it (a wrapper
/// [buildApp] built around the injected sink). An injected [RepeatableSpeech] is
/// left for its injector to dispose. Placed above the `MaterialApp` so the panel
/// in the chrome's `builder` reads the scope.
class _SpeechRoot extends StatefulWidget {
  const _SpeechRoot({
    required this.speech,
    required this.owns,
    required this.child,
  });

  /// The app-wide repeatable speech exposed to the subtree.
  final RepeatableSpeech speech;

  /// Whether this root created [speech] and must dispose it (an injected one is
  /// owned by its injector).
  final bool owns;

  /// The app subtree (the `MaterialApp`) wrapped in the speech scope.
  final Widget child;

  @override
  State<_SpeechRoot> createState() => _SpeechRootState();
}

class _SpeechRootState extends State<_SpeechRoot> {
  @override
  void dispose() {
    if (widget.owns) widget.speech.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpeechScope(speech: widget.speech, child: widget.child);
  }
}

/// Overlays the persistent spoken-output panel (E50) on every screen (bs-08
/// SPEECH-1).
///
/// Composed inside the shared [DisplayChrome] (as its child) so the settings
/// entry and any open settings panel sit above it. The panel itself collapses to
/// nothing until something has been spoken, so this adds no visible chrome to a
/// screen that has produced no spoken output yet.
class _SpokenOutputChrome extends StatelessWidget {
  const _SpokenOutputChrome({required this.child});

  /// The app content the spoken-output panel overlays.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        // Full-width at the bottom so the panel's last-spoken text has bounded
        // width to lay out in; it collapses to nothing until something is
        // spoken, so this occupies no height on a screen with no spoken output.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: const SafeArea(child: SpokenOutputPanel()),
        ),
      ],
    );
  }
}

/// The Capture screen the app opens on when a capture source is wired (bs-02).
///
/// It owns the [CaptureController] over the injected
/// [AppDependencies.captureSource] and wraps its subtree in a
/// [CaptureReadEndpoint] so the acceptance suite can observe the capture state.
/// The screen body is the SCREEN-1 [CaptureScreen] scaffold — the wireframe
/// regions E15–E21, the eyedropper and the stability indicator, bound to the
/// controller; the controller ownership and the endpoint wiring stay here.
class CaptureHomeScreen extends StatefulWidget {
  const CaptureHomeScreen({super.key});

  @override
  State<CaptureHomeScreen> createState() => _CaptureHomeScreenState();
}

class _CaptureHomeScreenState extends State<CaptureHomeScreen> {
  CaptureController? _controller;

  /// The committed sample the Readout has already been opened for, so the
  /// handoff fires once per capture rather than on every later state change.
  Sample? _openedReadoutFor;

  /// The pair the comparison has already been opened for, so the AC-5 pair
  /// handoff fires once per send rather than on every later state change.
  ComparisonPair? _openedComparisonFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once, over the capture source injected above.
    if (_controller == null) {
      final source = AppScope.of(context).captureSource!;
      _controller = CaptureController(source: source)
        ..addListener(_openReadoutOnCommit)
        ..addListener(_openComparisonOnPair);
    }
  }

  /// Opens the captured reading's Readout once a capture commits in adequate
  /// light (bs-02 D-5).
  ///
  /// A commit fills [CaptureController.state]'s `lastCommittedSample` with a
  /// just-captured sample; this pushes bs-01's Readout for it, where the
  /// just-captured marker fires the confirmation haptic as the reading lands
  /// (bs-01 AC-12). A low-light commit keeps the painter on the Capture screen
  /// to dismiss the warning and continue capturing at the lower accuracy
  /// (AC-6/AC-7), so the handoff waits for adequate light. The committed
  /// sample's identity gates the push to once per capture, not on every later
  /// state change (settling ticks, a warning dismiss).
  void _openReadoutOnCommit() {
    final committed = _controller!.state.lastCommittedSample;
    if (committed == null || identical(committed, _openedReadoutFor)) return;
    _openedReadoutFor = committed;
    if (_controller!.state.lowLightWarning) return;
    Navigator.of(context)
        .push(AppScope.of(context).router.toReadout(committed));
  }

  /// Opens the side-by-side comparison once the painter sends a pair of marked
  /// readings to it (bs-09 AC-5).
  ///
  /// A send fills [CaptureController.state]'s `pairToCompare`; this pushes the
  /// comparison with both slots filled from that pair, so the two readings
  /// arrive together. Gated on the pair's identity so the push fires once per
  /// send, not on every later state change (settling ticks, a warning dismiss)
  /// — the mirror of [_openReadoutOnCommit].
  void _openComparisonOnPair() {
    final pair = _controller!.state.pairToCompare;
    if (pair == null || identical(pair, _openedComparisonFor)) return;
    _openedComparisonFor = pair;
    Navigator.of(context)
        .push(AppScope.of(context).router.toComparisonPair(pair.a, pair.b));
  }

  @override
  void dispose() {
    _controller?.removeListener(_openReadoutOnCommit);
    _controller?.removeListener(_openComparisonOnPair);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CaptureReadEndpoint(
      key: CaptureReadEndpoint.endpointKey,
      controller: _controller!,
      child: CaptureScreen(controller: _controller!),
    );
  }
}

/// The Comparison screen the app opens on when a comparison entry is wired, and
/// the destination of the Readout → compare handoff (`AppRouter.toComparison`).
///
/// It owns the [ComparisonController] over the injected catalogue / profile /
/// detector and wraps its subtree in a [ComparisonReadEndpoint] so the
/// acceptance suite can observe the comparison state. The deps are passed in
/// (not read from [AppScope]) so the handoff route renders the carried sample
/// even when pushed outside an [AppScope] (bs-01's handoff tests); [initialA] /
/// [initialB] carry that sample into its slot.
///
/// It renders the real [ComparisonScreen] (SCREEN-1) — the wireframe regions
/// E3–E8 and the sample picker E49 — composed over the owned controller. Those
/// regions are shells (placeholders and disabled controls) until their behaviour
/// phases fill them; the controller ownership and the read endpoint stay here.
class ComparisonHomeScreen extends StatefulWidget {
  /// Creates the comparison home over the given catalogue / profile / detector,
  /// optionally pre-placing [initialA] / [initialB] into their slots.
  const ComparisonHomeScreen({
    this.sampleSource = const InMemorySampleSource(),
    this.cvdProfile = const CvdProfile(type: CvdType.deutan),
    this.confusionCheck = const DichromatConfusionCheck(),
    this.speech = const NoopSpeech(),
    this.router = const AppRouter(),
    this.initialA,
    this.initialB,
    super.key,
  });

  /// The saved-sample catalogue the comparison picker lists (D-7).
  final SampleSource sampleSource;

  /// Spoken-output sink the comparison's "Speak whole comparison" control drives
  /// (AC-9). Defaults to the inert [NoopSpeech] — the bs-01 shipped speech (D-1)
  /// and what the handoff route carries; the acceptance harness injects a
  /// recording fake through `AppDependencies.speech`.
  final Speech speech;

  /// Typed navigation the controller uses to open a slot's full Readout
  /// (AC-10, AC-11). Defaults to a plain [AppRouter]; the production assembly
  /// passes `AppDependencies.router`.
  final AppRouter router;

  /// The painter's colour-vision profile the confusion flag is judged against.
  final CvdProfile cvdProfile;

  /// The detector deciding whether the pair is confusable (AC-7/AC-8).
  final ConfusionCheck confusionCheck;

  /// A sample to pre-place into slot A (the Readout → compare-as-A handoff).
  final Sample? initialA;

  /// A sample to pre-place into slot B (the Readout → compare-as-B handoff).
  final Sample? initialB;

  @override
  State<ComparisonHomeScreen> createState() => _ComparisonHomeScreenState();
}

class _ComparisonHomeScreenState extends State<ComparisonHomeScreen> {
  late final ComparisonController _controller = ComparisonController(
    sampleSource: widget.sampleSource,
    confusionCheck: widget.confusionCheck,
    profile: widget.cvdProfile,
    speech: widget.speech,
    router: widget.router,
    initialA: widget.initialA,
    initialB: widget.initialB,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ComparisonReadEndpoint(
      key: ComparisonReadEndpoint.endpointKey,
      controller: _controller,
      child: ComparisonScreen(controller: _controller),
    );
  }
}

/// The Recipes screen the app opens on when a recipes entry is wired, and the
/// destination of the Readout → recipes handoff (`AppRouter.toRecipes`).
///
/// It owns the [RecipeController] over the injected catalogue / palettes /
/// engine mixing toward [target], and wraps its subtree in a
/// [RecipeReadEndpoint] so the acceptance suite can observe the recipe state.
/// The seams are passed in (not read from [AppScope]) so the handoff route
/// renders the carried target even when pushed outside an [AppScope] (bs-01's
/// AC-11 handoff test), symmetric to [ComparisonHomeScreen].
///
/// The body is the [RecipesScreen] — the recipes regions (E22–E25, the recipe
/// list, the gamut banner) composed over the owned controller (SCREEN-1); the
/// controller ownership and the read endpoint stay here. Its "Recipes" app bar
/// and target render keep bs-01's AC-11 handoff green.
class RecipesHomeScreen extends StatefulWidget {
  /// Creates the recipes home mixing toward [target], over the given seams.
  const RecipesHomeScreen({
    required this.target,
    this.sampleSource = const InMemorySampleSource(),
    this.paletteSource = const InMemoryPaletteSource(),
    this.mixingEngine = const SubtractiveMixingEngine(),
    this.speech = const NoopSpeech(),
    this.router = const AppRouter(),
    super.key,
  });

  /// The colour the painter wants to mix toward (AC-1/AC-2; AC-11 speaks it).
  final Sample target;

  /// The saved-sample catalogue the AC-1 target picker lists (reused from bs-03).
  final SampleSource sampleSource;

  /// The owned palettes the solver is constrained to choose among (AC-3).
  final PaletteSource paletteSource;

  /// The swappable mixing engine every solve is delegated to (D-6).
  final MixingEngine mixingEngine;

  /// Spoken-output sink the speak-target / speak-recipe controls drive (AC-11,
  /// AC-12). Defaults to the inert [NoopSpeech] — bs-01's shipped speech and what
  /// the handoff route carries; the acceptance harness injects a recording fake.
  final Speech speech;

  /// Typed navigation the controller uses. Defaults to a plain [AppRouter]; the
  /// production assembly passes `AppDependencies.router`.
  final AppRouter router;

  @override
  State<RecipesHomeScreen> createState() => _RecipesHomeScreenState();
}

class _RecipesHomeScreenState extends State<RecipesHomeScreen> {
  late final RecipeController _controller = RecipeController(
    sampleSource: widget.sampleSource,
    paletteSource: widget.paletteSource,
    mixingEngine: widget.mixingEngine,
    target: widget.target,
    speech: widget.speech,
    router: widget.router,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecipeReadEndpoint(
      key: RecipeReadEndpoint.endpointKey,
      controller: _controller,
      child: RecipesScreen(controller: _controller),
    );
  }
}

/// The Correction screen the app opens on when a correction entry is wired, and
/// the destination of the Recipes → correction handoff (`AppRouter.toCorrection`).
///
/// It owns the [CorrectionController] over the injected capture source / engine
/// / palettes correcting [currentMix] toward [target], and wraps its subtree in
/// a [CorrectionReadEndpoint] so the acceptance suite can observe the correction
/// state. The seams are passed in (not read from [AppScope]) so the handoff
/// route renders the carried mix even when pushed outside an [AppScope],
/// symmetric to [RecipesHomeScreen]; the one exception is [captureSource], which
/// has no const default (a camera is scene-specific) and so is required.
///
/// The body is the [CorrectionScreen] (SCREEN-1) composed over the owned
/// controller — the check, difference, correction, speak, re-photograph and save
/// regions (E26–E29); the controller ownership and the read endpoint stay here.
class CorrectionHomeScreen extends StatefulWidget {
  /// Creates the correction home correcting [currentMix] toward [target], over
  /// the given seams.
  const CorrectionHomeScreen({
    required this.target,
    required this.currentMix,
    required this.captureSource,
    this.paletteSource = const InMemoryPaletteSource(),
    this.correctionEngine = const SubtractiveCorrectionEngine(),
    this.mixingEngine = const SubtractiveMixingEngine(),
    this.sampleSource = const InMemorySampleSource(),
    this.speech = const NoopSpeech(),
    this.router = const AppRouter(),
    super.key,
  });

  /// The colour the mixed swatch is corrected toward (AC-1).
  final Sample target;

  /// The recipe the painter mixed toward [target] (AC-4/AC-5).
  final Recipe currentMix;

  /// The capture source the swatch is photographed through (bs-02 D-2).
  final CaptureSource captureSource;

  /// The owned palettes the correction's additions are drawn from (AC-4/AC-5).
  final PaletteSource paletteSource;

  /// The swappable engine the difference and correction are read through
  /// (D-2/D-3).
  final CorrectionEngine correctionEngine;

  /// The swappable mixing engine the correction scores candidates through.
  final MixingEngine mixingEngine;

  /// The saved-sample catalogue a confirmed mix is persisted to (D-8).
  final SampleSource sampleSource;

  /// Spoken-output sink the speak-correction control drives (AC-7). Defaults to
  /// the inert [NoopSpeech]; the acceptance harness injects a recording fake.
  final Speech speech;

  /// Typed navigation the controller uses. Defaults to a plain [AppRouter]; the
  /// production assembly passes `AppDependencies.router`.
  final AppRouter router;

  @override
  State<CorrectionHomeScreen> createState() => _CorrectionHomeScreenState();
}

class _CorrectionHomeScreenState extends State<CorrectionHomeScreen> {
  late final CorrectionController _controller = CorrectionController(
    captureSource: widget.captureSource,
    target: widget.target,
    currentMix: widget.currentMix,
    paletteSource: widget.paletteSource,
    correctionEngine: widget.correctionEngine,
    mixingEngine: widget.mixingEngine,
    sampleSource: widget.sampleSource,
    speech: widget.speech,
    router: widget.router,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CorrectionReadEndpoint(
      key: CorrectionReadEndpoint.endpointKey,
      controller: _controller,
      child: CorrectionScreen(controller: _controller),
    );
  }
}

/// The Palette screen the app opens on when a palette entry is wired (bs-06
/// SCREEN-1).
///
/// It owns a [PaletteController] over [AppDependencies.paletteSource], a
/// [ProjectController] over [AppDependencies.projectSource], and — since
/// PALETTE-4 — a shared [RecipeController] the palette selection re-points
/// (AC-5, D-5) — all read from the enclosing [AppScope] (the sources are loaded
/// before assembly, so the controllers read them synchronously). It wraps its
/// subtree in the [RecipeReadEndpoint], [PaletteReadEndpoint] and
/// [ProjectReadEndpoint] the acceptance suite observes, symmetric to the
/// capture / comparison / recipes homes. The body is the [PaletteScreen],
/// composed over the paint/project controllers (SCREEN-1); the view toggle, the
/// paint/legend rendering, the palette selection and the vision-profile estimate
/// land in their behaviour phases.
class PaletteHomeScreen extends StatefulWidget {
  const PaletteHomeScreen({super.key});

  @override
  State<PaletteHomeScreen> createState() => _PaletteHomeScreenState();
}

class _PaletteHomeScreenState extends State<PaletteHomeScreen> {
  PaletteController? _paletteController;
  ProjectController? _projectController;
  RecipeController? _recipeController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controllers once, over the sources injected above.
    if (_paletteController == null) {
      final deps = AppScope.of(context);
      // The shared recipe-solving state the Palette screen's palette selection
      // re-points (bs-06 AC-5, D-5). It reuses the frozen bs-04 [RecipeController]
      // over the same owned palettes / engine / catalogue the Recipes screen
      // solves through, mixing toward the current reading ([initialSample]) so
      // there is a solve to constrain; selecting a palette calls its frozen
      // [RecipeController.selectPalette], which re-solves against only that
      // palette. Observed by the acceptance suite through the [RecipeReadEndpoint].
      _recipeController = RecipeController(
        sampleSource: deps.sampleSource,
        paletteSource: deps.paletteSource,
        mixingEngine: deps.mixingEngine,
        target: deps.initialSample,
        speech: deps.speech,
        router: deps.router,
      );
      _paletteController = PaletteController(
        source: deps.paletteSource,
        onPaletteSelected: _recipeController!.selectPalette,
      );
      _projectController = ProjectController(
        source: deps.projectSource,
        confusionCheck: deps.confusionCheck,
        cvdProfile: deps.cvdProfile,
        shareSink: deps.pdfShareSink,
      );
    }
  }

  @override
  void dispose() {
    _paletteController?.dispose();
    _projectController?.dispose();
    _recipeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RecipeReadEndpoint(
      key: RecipeReadEndpoint.endpointKey,
      controller: _recipeController!,
      child: PaletteReadEndpoint(
        key: PaletteReadEndpoint.endpointKey,
        controller: _paletteController!,
        child: ProjectReadEndpoint(
          key: ProjectReadEndpoint.endpointKey,
          controller: _projectController!,
          child: PaletteScreen(
            paletteController: _paletteController!,
            projectController: _projectController!,
          ),
        ),
      ),
    );
  }
}
