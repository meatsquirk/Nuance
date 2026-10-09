import 'package:flutter/foundation.dart';

import '../a11y/speech.dart';
import '../app/router.dart';
import '../compare/sample_source.dart';
import '../domain/color_coordinates.dart';
import '../domain/paint.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import 'engine/mixing_engine.dart';
import 'palette.dart';
import 'palette_source.dart';
import 'recipe_state.dart';

/// Drives the Recipes screen: holds the mixing [state] and offers the actions
/// the screen takes on it.
///
/// A [ChangeNotifier] so the screen and the acceptance read endpoint rebuild as
/// the state moves, mirroring bs-03's `ComparisonController`. It is given the
/// four seams the feature wires — the saved-sample catalogue ([sampleSource],
/// reused from bs-03 for the AC-1 target picker), the owned palettes
/// ([paletteSource]), the swappable [mixingEngine] (the controller never
/// computes mixing math itself — D-6), and the [speech] sink — plus the typed
/// [router].
///
/// This is the RECIPE-2 **shell**: it establishes the state shape, the seams and
/// the read getters, but every painter *action* ([selectTarget] /
/// [enterManualTarget] / [selectPalette] / [setMode] / [speakTarget] /
/// [speakRecipe]) is declared here and throws until its behaviour phase fills it
/// — exactly as bs-02's capture controller deferred its actions. No selection,
/// no solve and no spoken output happen yet.
class RecipeController extends ChangeNotifier {
  /// Creates a controller for mixing toward [target], over the given seams.
  ///
  /// The initial [RecipeState] carries [target], no recipes, wet mode and no
  /// manual error, with [RecipeState.selectedPalette] defaulted to the first
  /// palette the [paletteSource] offers (null when it offers none) so the screen
  /// has a palette to name before the painter chooses another.
  RecipeController({
    required this.sampleSource,
    required this.paletteSource,
    required this.mixingEngine,
    required Sample target,
    this.speech = const NoopSpeech(),
    this.router = const AppRouter(),
  }) : _state = _initial(target, paletteSource, mixingEngine);

  /// The saved-sample catalogue the AC-1 target picker lists (reused from bs-03).
  final SampleSource sampleSource;

  /// The owned palettes the solver is constrained to choose among (AC-3).
  final PaletteSource paletteSource;

  /// The swappable engine every solve and prediction is delegated to (D-6); the
  /// controller never computes mixing math itself.
  final MixingEngine mixingEngine;

  /// Spoken-output sink the [speakTarget] / [speakRecipe] actions drive (AC-11,
  /// AC-12) — the same injected [Speech] seam bs-01's readout speaks through.
  final Speech speech;

  /// Typed navigation (e.g. back to a sample's Readout), injected by the app.
  final AppRouter router;

  /// The solver options every solve runs under (the D-8/D-10/D-12 defaults).
  static const MixOptions _options = MixOptions();

  // Reassigned through [_emit] as the painter acts: selection re-derives the
  // target (RECIPE-3), the solve fills the recipes (ENGINE-2), the toggle moves
  // the mode (ENGINE-6). Not final by design.
  RecipeState _state;

  /// The current observable recipe state.
  RecipeState get state => _state;

  /// The saved samples the AC-1 target picker offers (empty until seeded).
  List<Sample> get savedSamples => sampleSource.savedSamples();

  /// The palettes the painter may constrain the solve to (empty until seeded).
  List<PaintPalette> get palettes => paletteSource.palettes();

  /// Builds the initial state for [target], defaulting the selected palette to
  /// the first the [source] offers and solving the recipes over it on open
  /// (ENGINE-2) so the screen shows mixes without the painter acting first.
  static RecipeState _initial(
    Sample target,
    PaletteSource source,
    MixingEngine engine,
  ) {
    final available = source.palettes();
    final selected = available.isEmpty ? null : available.first;
    return RecipeState(
      target: target,
      selectedPalette: selected,
      recipes: _solve(engine, target, selected),
    );
  }

  /// The recipes the [engine] finds for [target] over [palette], or none when no
  /// palette is selected (nothing to constrain the solve to).
  static List<Recipe> _solve(
    MixingEngine engine,
    Sample target,
    PaintPalette? palette,
  ) =>
      palette == null ? const [] : engine.inverse(target, palette, _options);

  // --- Target selection (RECIPE-3) ---

  /// Chooses a saved [sample] as the mixing target (AC-1).
  ///
  /// Moves the target to [sample] and clears any outstanding manual-entry error;
  /// the palette, recipes and mode are carried unchanged (the re-solve on a new
  /// target lands in ENGINE-2).
  void selectTarget(Sample sample) => _emit(RecipeState(
        target: sample,
        selectedPalette: _state.selectedPalette,
        recipes: _state.recipes,
        mode: _state.mode,
      ));

  /// Sets a manually entered CIELAB [coordinates] target, validating its range
  /// and leaving the previous target unchanged on an impossible value (AC-2).
  ///
  /// A value outside CIELAB's range (L\* 0–100, a\*/b\* within ±128, all finite)
  /// is refused: [RecipeState.manualError] is raised and [RecipeState.target] is
  /// kept exactly as it was. An in-range entry becomes the new target (a
  /// painter-confirmed sample) and clears the error.
  void enterManualTarget(ColorCoordinates coordinates) {
    if (!_inLabRange(coordinates)) {
      _emit(RecipeState(
        target: _state.target,
        selectedPalette: _state.selectedPalette,
        recipes: _state.recipes,
        mode: _state.mode,
        manualError: _manualRangeError,
      ));
      return;
    }
    _emit(RecipeState(
      target: Sample(
        name: 'Manual target',
        coordinates: coordinates,
        provenance:
            const Provenance(ProvenanceTier.confirmed, note: 'Entered by hand'),
      ),
      selectedPalette: _state.selectedPalette,
      recipes: _state.recipes,
      mode: _state.mode,
    ));
  }

  /// The message shown when a manual target is out of CIELAB's range (AC-2).
  static const String _manualRangeError =
      'Enter L* 0–100 and a*/b* within ±128.';

  /// Whether [c] is a representable CIELAB colour: finite, L\* in 0–100 and
  /// a\*/b\* within ±128.
  static bool _inLabRange(ColorCoordinates c) =>
      _within(c.lightness, 0, 100) &&
      _within(c.a, -128, 127) &&
      _within(c.b, -128, 127);

  static bool _within(double v, double lo, double hi) =>
      v.isFinite && v >= lo && v <= hi;

  /// Assigns [next] as the current state and notifies listeners — the single
  /// mutation path every action routes through (mirrors bs-03).
  void _emit(RecipeState next) {
    _state = next;
    notifyListeners();
  }

  /// Constrains the solve to [palette] and re-solves over it (AC-3) — ENGINE-2.
  void selectPalette(PaintPalette palette) {
    _emit(RecipeState(
      target: _state.target,
      selectedPalette: palette,
      recipes: _solve(mixingEngine, _state.target, palette),
      mode: _state.mode,
      manualError: _state.manualError,
    ));
  }

  /// Switches between wet and dry predictions (AC-10) — ENGINE-6.
  ///
  /// Re-renders every current recipe for [mode] by asking the [mixingEngine] to
  /// predict each recipe's own parts wet or dry (the controller never computes
  /// the shift itself — D-6), then emits the new mode. The solve is unchanged:
  /// only each recipe's predicted colour moves, so toggling back to wet restores
  /// the wet prediction exactly.
  void setMode(MixMode mode) => _emit(RecipeState(
        target: _state.target,
        selectedPalette: _state.selectedPalette,
        recipes: _repredict(_state.recipes, mode),
        mode: mode,
        manualError: _state.manualError,
      ));

  /// Each recipe in [recipes] re-rendered for [mode]: the engine predicts the
  /// recipe's own parts wet or dry (AC-10), leaving the parts and distance as
  /// they were.
  List<Recipe> _repredict(List<Recipe> recipes, MixMode mode) {
    final dry = mode == MixMode.dry;
    return [
      for (final recipe in recipes)
        recipe.withPredictedColor(
          mixingEngine.forward(_partsByVolume(recipe), dry: dry),
        ),
    ];
  }

  /// The paint → volume-share map for [recipe], the input the engine's forward
  /// model takes (only the ratios matter, so the parts fractions suffice).
  static Map<Paint, double> _partsByVolume(Recipe recipe) => {
        for (final component in recipe.components)
          component.paint: component.partsFraction,
      };

  /// Speaks the target as one utterance — name + L, C, h (AC-11) — RECIPE-4.
  Future<void> speakTarget() => throw UnimplementedError(_deferred('RECIPE-4'));

  /// Speaks [recipe] as one utterance — each paint and its parts (AC-12) —
  /// RECIPE-4.
  Future<void> speakRecipe(Recipe recipe) =>
      throw UnimplementedError(_deferred('RECIPE-4'));

  static String _deferred(String phase) =>
      'RecipeController is a shell (RECIPE-2); this action lands in $phase.';
}
