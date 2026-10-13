// bs-12 synthetic accuracy set (QUALITY-1 scaffold).
//
// test-support for the accuracy ACs (AC-10 card+controlled ≤ ΔE00 3, AC-11
// card-less daylight ≤ 8 + labelled approximate, AC-12 recipe-vs-swatch ≤ 5)
// and the out-of-gamut AC (AC-13). A **deterministic** held-out fixture — no
// device, no spectrophotometer (plan bs-12 D-2): each sample pairs an input
// colour with its *known expected* colour, and the harness grades the distance
// between them with the independent `referenceDeltaE00` (never the product
// metric against itself).
//
// QUALITY-1 fixes the fixture *shape* and a small deterministic seed set so
// ITEST-1's smoke test has something populated to grade; QUALITY-4 expands this
// into the full held-out set (with perturbed inputs and the discriminating
// controls). The "synthetic ≠ physical ground truth" gap is carried to sign-off.
//
// This is test-support only — no `lib/` product code (plan bs-12 D-7).

import 'package:paint_color_assistant/domain/color_coordinates.dart';

/// Which accuracy claim a [SyntheticAccuracySample] exercises (plan bs-12 D-2).
enum AccuracyCondition {
  /// A reference-card reading under controlled lighting — AC-10, ΔE00 ≤ 3.
  cardControlled,

  /// A card-less reading in daylight — AC-11, ΔE00 ≤ 8 **and** labelled
  /// approximate.
  cardlessDaylight,

  /// A recipe's predicted colour vs the mixed swatch — AC-12, ΔE00 ≤ 5 for an
  /// in-gamut target.
  recipeVsSwatch;

  /// The ΔE00 bound this condition's reading must stay within of ground truth.
  double get maxDeltaE {
    switch (this) {
      case AccuracyCondition.cardControlled:
        return 3;
      case AccuracyCondition.cardlessDaylight:
        return 8;
      case AccuracyCondition.recipeVsSwatch:
        return 5;
    }
  }
}

/// One deterministic accuracy fixture: an [input] colour and the known
/// [expected] ground-truth colour it should land within [AccuracyCondition]'s
/// bound of (plan bs-12 D-2).
///
/// [expectApproximate] is true for the card-less condition (AC-11), which must
/// additionally be *labelled* approximate, never returned as calibrated.
class SyntheticAccuracySample {
  const SyntheticAccuracySample({
    required this.id,
    required this.condition,
    required this.input,
    required this.expected,
    this.expectApproximate = false,
  });

  /// A stable identifier naming the sample (used in grade reporting).
  final String id;

  /// The accuracy claim this sample exercises.
  final AccuracyCondition condition;

  /// The colour produced by the pipeline under test (the reading / prediction).
  final ColorCoordinates input;

  /// The known ground-truth colour the input is graded against.
  final ColorCoordinates expected;

  /// Whether the reading must also be labelled approximate (AC-11).
  final bool expectApproximate;

  /// The ΔE00 bound this sample must stay within (from its [condition]).
  double get maxDeltaE => condition.maxDeltaE;
}

/// A target colour tagged with whether it is reachable by the paint gamut
/// (AC-13): an out-of-gamut target must be *identified* and offered **no**
/// recipe, while an in-gamut control is not flagged and does return recipes.
class SyntheticGamutTarget {
  const SyntheticGamutTarget({
    required this.id,
    required this.target,
    required this.inGamut,
  });

  /// A stable identifier naming the target.
  final String id;

  /// The target colour put to the engine.
  final ColorCoordinates target;

  /// Whether the target is expected to be reachable (in gamut).
  final bool inGamut;
}

/// The deterministic seed accuracy set (QUALITY-1) — one sample per condition.
///
/// The inputs here sit comfortably inside each condition's bound so the shape is
/// exercised end-to-end; QUALITY-4 replaces this with the full held-out set,
/// including perturbed inputs and the controls that must exceed the bound.
const List<SyntheticAccuracySample> syntheticAccuracySet = [
  // AC-10: a calibrated reading of a mid warm earth under controlled light.
  SyntheticAccuracySample(
    id: 'card-controlled/warm-earth',
    condition: AccuracyCondition.cardControlled,
    input: ColorCoordinates(lightness: 58.8, a: 25.5, b: 22.4),
    expected: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  ),
  // AC-11: a card-less daylight reading, approximate, further off but ≤ 8.
  SyntheticAccuracySample(
    id: 'cardless-daylight/raw-sienna',
    condition: AccuracyCondition.cardlessDaylight,
    input: ColorCoordinates(lightness: 72.5, a: 14.0, b: 24.0),
    expected: ColorCoordinates(lightness: 70, a: 12.5, b: 21.65),
    expectApproximate: true,
  ),
  // AC-12: a recipe prediction vs its mixed swatch, in gamut, ≤ 5.
  SyntheticAccuracySample(
    id: 'recipe-vs-swatch/terre-verte',
    condition: AccuracyCondition.recipeVsSwatch,
    input: ColorCoordinates(lightness: 41.5, a: -9.0, b: 19.5),
    expected: ColorCoordinates(lightness: 40, a: -10, b: 18),
  ),
];

/// The deterministic seed gamut targets (QUALITY-1) — one in, one out.
///
/// QUALITY-3 grades AC-13 against these: the out-of-gamut target must be
/// identified with no false recipe; the in-gamut control must not be flagged.
const List<SyntheticGamutTarget> syntheticGamutTargets = [
  // A reachable mid earth — the AC-13 positive control (`control_inGamut`).
  SyntheticGamutTarget(
    id: 'in-gamut/warm-earth',
    target: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
    inGamut: true,
  ),
  // A hyper-saturated primary beyond any mixable paint — out of gamut.
  SyntheticGamutTarget(
    id: 'out-of-gamut/neon-cyan',
    target: ColorCoordinates(lightness: 90, a: -90, b: -40),
    inGamut: false,
  ),
];
