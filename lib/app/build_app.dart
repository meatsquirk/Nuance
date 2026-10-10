import 'package:flutter/material.dart';

import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import '../a11y/haptics.dart';
import '../a11y/speech.dart';
import '../capture/capture_controller.dart';
import '../capture/capture_read_endpoint.dart';
import '../capture/capture_screen.dart';
import '../capture/source/capture_source.dart';
import '../color_science/color_science.dart';
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
    this.paletteSource = const InMemoryPaletteSource(),
    this.recipesEntry,
    this.projectSource = const InMemoryProjectSource(),
    this.paletteEntry,
    this.store,
    this.sourcePhotoStore,
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

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

/// Builds the root widget of the Paint Color Assistant.
///
/// The single production assembly entry (D-7): it injects [deps] via [AppScope]
/// and wires the router into a [MaterialApp]. The app opens on the Capture
/// screen when a [AppDependencies.captureSource] is injected (bs-02), on the
/// [ComparisonHomeScreen] when a [AppDependencies.comparisonEntry] is injected
/// (bs-03 D-8), on the [RecipesHomeScreen] when a [AppDependencies.recipesEntry]
/// is injected (bs-04 D-6), on the [PaletteHomeScreen] when a
/// [AppDependencies.paletteEntry] is injected (bs-06 SCREEN-1), and otherwise on
/// the [ReadoutScreen] for [AppDependencies.initialSample] (bs-01's entry).
/// `main.dart` and the
/// acceptance harnesses construct the app through this one entry, differing only
/// in the injected services, the initial sample, the capture source and the
/// comparison / recipes entries.
Widget buildApp(AppDependencies deps) {
  return AppScope(
    dependencies: deps,
    child: MaterialApp(
      title: 'Paint Color Assistant',
      theme: ThemeData(useMaterial3: true),
      home: deps.captureSource != null
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
                      : ReadoutScreen(sample: deps.initialSample),
    ),
  );
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once, over the capture source injected above.
    if (_controller == null) {
      final source = AppScope.of(context).captureSource!;
      _controller = CaptureController(source: source)
        ..addListener(_openReadoutOnCommit);
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

  @override
  void dispose() {
    _controller?.removeListener(_openReadoutOnCommit);
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

/// The Palette screen the app opens on when a palette entry is wired (bs-06
/// SCREEN-1).
///
/// It owns a [PaletteController] over [AppDependencies.paletteSource] and a
/// [ProjectController] over [AppDependencies.projectSource] — both read from the
/// enclosing [AppScope] (the sources are loaded before assembly, so the
/// controllers read them synchronously) — and wraps its subtree in the
/// [PaletteReadEndpoint] and [ProjectReadEndpoint] the acceptance suite observes,
/// symmetric to the capture / comparison / recipes homes. The body is the
/// [PaletteScreen], composed over the two owned controllers (SCREEN-1); the view
/// toggle, the paint/legend rendering, the palette selection and the
/// vision-profile estimate land in their behaviour phases.
class PaletteHomeScreen extends StatefulWidget {
  const PaletteHomeScreen({super.key});

  @override
  State<PaletteHomeScreen> createState() => _PaletteHomeScreenState();
}

class _PaletteHomeScreenState extends State<PaletteHomeScreen> {
  PaletteController? _paletteController;
  ProjectController? _projectController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controllers once, over the sources injected above.
    if (_paletteController == null) {
      final deps = AppScope.of(context);
      _paletteController = PaletteController(source: deps.paletteSource);
      _projectController = ProjectController(source: deps.projectSource);
    }
  }

  @override
  void dispose() {
    _paletteController?.dispose();
    _projectController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PaletteReadEndpoint(
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
    );
  }
}
