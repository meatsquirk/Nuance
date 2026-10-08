import 'package:flutter/foundation.dart';

import '../domain/sample.dart';
import 'engine/mixing_engine.dart';
import 'palette.dart';

/// Whether recipes are shown for the paint **wet** or for its predicted **dry**
/// colour (bs-04 AC-10).
///
/// The solve and the predicted colours are computed against the selected mode;
/// the screen offers a toggle. Defaults to [wet] — the painter mixes wet paint.
/// ENGINE-6 fills the dry prediction behind this toggle.
enum MixMode {
  /// The colour of the mix while wet (the default).
  wet,

  /// The colour the mix is predicted to dry to (AC-10; per-medium transform).
  dry,
}

/// The observable state of the Recipes screen: the mixing [target], the
/// [selectedPalette] the solver is constrained to, the ordered [recipes] it
/// returned, the wet/dry [mode], and the manual-entry [manualError].
///
/// A plain immutable snapshot held by the `RecipeController` and surfaced to the
/// Recipes screen and the acceptance read endpoint, mirroring bs-03's
/// `ComparisonState`. [recipes] is empty until a solve runs (ENGINE-2);
/// [manualError] is null unless the last manual target entry was out of range
/// (AC-2). The shape is fixed here (RECIPE-2); the behaviour phases move the
/// target (RECIPE-3), fill [recipes] via the engine (ENGINE-2..6) and drive the
/// [mode] toggle (ENGINE-6).
class RecipeState {
  /// Creates a snapshot. [target] is required; the palette, recipes, mode and
  /// manual error default to an unsolved, wet, error-free start.
  const RecipeState({
    required this.target,
    this.selectedPalette,
    this.recipes = const [],
    this.mode = MixMode.wet,
    this.manualError,
  });

  /// The colour the painter wants to mix toward (AC-1/AC-2).
  final Sample target;

  /// The palette the solver is constrained to (AC-3), or null when none is
  /// available or chosen yet.
  final PaintPalette? selectedPalette;

  /// The recipes the engine returned, best-first (AC-4), empty until a solve.
  final List<Recipe> recipes;

  /// Whether the recipes are shown wet or dry (AC-10); defaults to [MixMode.wet].
  final MixMode mode;

  /// The validation message for the last rejected manual target (AC-2), or null
  /// when the last entry was accepted or none has been made.
  final String? manualError;

  /// True once the solver has returned at least one recipe (drives the
  /// screen's results vs. empty-state rendering).
  bool get hasRecipes => recipes.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is RecipeState &&
      other.target == target &&
      other.selectedPalette == selectedPalette &&
      listEquals(other.recipes, recipes) &&
      other.mode == mode &&
      other.manualError == manualError;

  @override
  int get hashCode => Object.hash(
        target,
        selectedPalette,
        Object.hashAll(recipes),
        mode,
        manualError,
      );

  @override
  String toString() => 'RecipeState(target: ${target.name ?? '(unnamed)'}, '
      'palette: ${selectedPalette?.name ?? '(none)'}, '
      '${recipes.length} recipes, ${mode.name}'
      '${manualError == null ? '' : ', error: $manualError'})';
}
