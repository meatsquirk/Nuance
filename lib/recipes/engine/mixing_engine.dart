import 'package:flutter/foundation.dart';

import '../../domain/color_coordinates.dart';
import '../../domain/paint.dart';
import '../../domain/sample.dart';
import '../palette.dart';

/// The knobs the inverse solver runs under (bs-04 D-8/D-10/D-12).
///
/// Carried as a value so a scenario or the controller can tune the search
/// without a new engine. The threshold defaults encode the design decisions; the
/// authoritative gamut and trace values are confirmed by **G-4** — until then the
/// behaviour phases assert properties, not these literals (D-13).
///
/// Value-equal and `const`-constructible.
class MixOptions {
  /// Creates the solver options. All fields default to the D-decisions.
  const MixOptions({
    this.maxPaints = 4,
    this.topK = 5,
    this.gamutThreshold = 5.0,
    this.traceThreshold = 0.02,
  });

  /// The largest number of paints a recipe may combine (subset-size bound, D-8).
  final int maxPaints;

  /// The most recipes the solver returns (the top-K; AC-4 wants three to five).
  final int topK;

  /// ΔE00 above which the best achievable recipe is out of gamut (D-10; G-4).
  final double gamutThreshold;

  /// Volume fraction below which a component is a trace — "a touch of" (D-12;
  /// ~2%; G-4).
  final double traceThreshold;

  @override
  bool operator ==(Object other) =>
      other is MixOptions &&
      other.maxPaints == maxPaints &&
      other.topK == topK &&
      other.gamutThreshold == gamutThreshold &&
      other.traceThreshold == traceThreshold;

  @override
  int get hashCode => Object.hash(maxPaints, topK, gamutThreshold, traceThreshold);

  @override
  String toString() => 'MixOptions(maxPaints $maxPaints, topK $topK, '
      'gamut $gamutThreshold, trace $traceThreshold)';
}

/// One paint's share of a [Recipe] (bs-04 AC-4/AC-7).
///
/// [partsFraction] is the paint's fraction of the mix by volume (the shares of a
/// recipe sum to 1). A component under the trace threshold (D-12) is flagged
/// [isTrace] and renders as "a touch of" + a [techniqueNote] rather than a
/// measured part (AC-7); ENGINE-4 fills the flag and the note.
///
/// Value-equal and `const`-constructible.
class RecipeComponent {
  /// Creates a component: [paint] at [partsFraction] of the mix by volume.
  const RecipeComponent({
    required this.paint,
    required this.partsFraction,
    this.isTrace = false,
    this.techniqueNote,
  });

  /// The paint this share is of.
  final Paint paint;

  /// The paint's fraction of the mix by volume (0 … 1).
  final double partsFraction;

  /// True when the share is below [MixOptions.traceThreshold] — rendered as
  /// "a touch of" (AC-7). Defaults to false; ENGINE-4 sets it.
  final bool isTrace;

  /// A static technique note shown with a trace component (D-12), or null.
  final String? techniqueNote;

  @override
  bool operator ==(Object other) =>
      other is RecipeComponent &&
      other.paint == paint &&
      other.partsFraction == partsFraction &&
      other.isTrace == isTrace &&
      other.techniqueNote == techniqueNote;

  @override
  int get hashCode =>
      Object.hash(paint, partsFraction, isTrace, techniqueNote);

  @override
  String toString() =>
      'RecipeComponent(${paint.name} ${(partsFraction * 100).toStringAsFixed(1)}%'
      '${isTrace ? ', trace' : ''})';
}

/// A candidate mix the engine returns: the [components] and parts, the
/// [predictedColor] the forward model expects, its distance [deltaE00] from the
/// target, and the flags the screen renders (bs-04 AC-4..AC-10).
///
/// [verdict] is the plain-language band for [deltaE00] (D-7), null until ENGINE-3
/// fills it. [outOfGamut] (ENGINE-5) marks a result that cannot match the target
/// — the nearest mix, never a claimed match (AC-9). [muddying] (ENGINE-4) flags a
/// complementary-crossing mix (AC-8). A recipe never spans media, so it carries a
/// single [medium].
///
/// Value-equal and `const`-constructible.
class Recipe {
  /// Creates a recipe. [medium], [components], [predictedColor] and [deltaE00]
  /// are required; the verdict and the flags default to unset.
  const Recipe({
    required this.medium,
    required this.components,
    required this.predictedColor,
    required this.deltaE00,
    this.verdict,
    this.outOfGamut = false,
    this.muddying = false,
  });

  /// The medium of every paint in the mix (recipes never span media).
  final PaintMedium medium;

  /// The paints and their parts-by-volume (AC-4).
  final List<RecipeComponent> components;

  /// The colour the forward model predicts this mix produces (AC-4; AC-10 for
  /// the dry prediction).
  final ColorCoordinates predictedColor;

  /// ΔE00 between [predictedColor] and the target (D-2; AC-5).
  final double deltaE00;

  /// The plain-language verdict band for [deltaE00] (D-7; AC-5), or null until
  /// ENGINE-3 fills it.
  final String? verdict;

  /// True when the target is unreachable and this is the nearest mix, not a
  /// match (D-10; AC-9). Defaults to false; ENGINE-5 sets it.
  final bool outOfGamut;

  /// True when the mix crosses a complementary hue pair and is liable to muddy
  /// (D-9; AC-8). Defaults to false; ENGINE-4 sets it.
  final bool muddying;

  /// This recipe with its [predictedColor] replaced, every other field kept.
  ///
  /// Used to re-render the mix wet or dry (AC-10 / ENGINE-6) without re-solving:
  /// the parts, distance, verdict and flags are unchanged — only the colour the
  /// forward model predicts moves with the wet/dry mode.
  Recipe withPredictedColor(ColorCoordinates predictedColor) => Recipe(
        medium: medium,
        components: components,
        predictedColor: predictedColor,
        deltaE00: deltaE00,
        verdict: verdict,
        outOfGamut: outOfGamut,
        muddying: muddying,
      );

  /// This recipe re-flagged [outOfGamut], every other field kept.
  ///
  /// Used by the engine when the target is unreachable (D-10; AC-9): the best
  /// achievable mix cannot reach the target within the in-gamut ceiling, so
  /// every offered recipe is the nearest possible and is marked so the screen
  /// presents it as the nearest, never as a claimed match. The parts, distance
  /// and verdict are unchanged — the verdict band at this distance is already a
  /// worse-than-"very close" phrase, so the flag is the honest signal, not a
  /// rewritten verdict.
  Recipe asOutOfGamut() => Recipe(
        medium: medium,
        components: components,
        predictedColor: predictedColor,
        deltaE00: deltaE00,
        verdict: verdict,
        outOfGamut: true,
        muddying: muddying,
      );

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.medium == medium &&
      listEquals(other.components, components) &&
      other.predictedColor == predictedColor &&
      other.deltaE00 == deltaE00 &&
      other.verdict == verdict &&
      other.outOfGamut == outOfGamut &&
      other.muddying == muddying;

  @override
  int get hashCode => Object.hash(
        medium,
        Object.hashAll(components),
        predictedColor,
        deltaE00,
        verdict,
        outOfGamut,
        muddying,
      );

  @override
  String toString() => 'Recipe(${medium.name}, ${components.length} paints, '
      'ΔE00 $deltaE00${verdict == null ? '' : ' $verdict'}'
      '${outOfGamut ? ', out-of-gamut' : ''}${muddying ? ', muddying' : ''})';
}

/// The mixing engine the Recipes feature solves through (SI D3, swappable).
///
/// [forward] predicts the colour of a mix given its paints and parts by volume
/// (optionally the dry colour); [inverse] searches a [PaintPalette] for the top
/// recipes that reproduce a target [Sample]. The v1 [SubtractiveMixingEngine]
/// implements it; the measured-pigment engine
/// (`docs/custom-mixing-engine-design.md`) is the deferred upgrade behind this
/// same interface, so swapping the engine never touches the controller or the
/// screen. ΔE00 is the shipped `deltaE00` (`lib/compare/difference.dart`), not a
/// second copy.
abstract interface class MixingEngine {
  /// Predicts the CIELAB colour of [partsByVolume] (paint → its volume share).
  ///
  /// With `dry: true` returns the predicted **dry** colour (the per-medium
  /// drying transform, AC-10); the default `dry: false` is the wet prediction.
  ColorCoordinates forward(Map<Paint, double> partsByVolume, {bool dry});

  /// The top recipes from [palette] that reproduce [target], under [opts].
  ///
  /// Returns up to [MixOptions.topK] recipes, ordered best-first, each using only
  /// paints in [palette] (AC-3). When the target is unreachable the result is the
  /// nearest mix flagged [Recipe.outOfGamut] (AC-9) — never a false match.
  List<Recipe> inverse(Sample target, PaintPalette palette, MixOptions opts);
}
