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

// ---------------------------------------------------------------------------
// The full held-out accuracy set (QUALITY-4 — fed through the REAL pipeline)
// ---------------------------------------------------------------------------

/// One held-out accuracy fixture graded through the **real** capture / engine
/// pipeline (QUALITY-4), not off the recorded fixture colour.
///
/// [truth] is the scene's (or target's) canonical ground-truth colour. For the
/// capture conditions the AC test builds a [SoftwareCaptureSource] scene from
/// [truth], drives a committed reading through the real `CaptureController`, and
/// grades the produced reading against [truth] with the independent
/// `referenceDeltaE00`. For the recipe condition it solves the real engine
/// toward [truth] and grades the best recipe's `predictedColor` against it.
///
/// This is still a *synthetic* ground truth — a deterministic stand-in for a
/// spectrophotometer measurement (plan bs-12 D-2). That "synthetic ≠ physical
/// ground truth" gap is carried to sign-off; what QUALITY-4 proves is that the
/// real pipeline meets each bound against a known truth, graded independently.
class HeldOutAccuracySample {
  const HeldOutAccuracySample({
    required this.id,
    required this.condition,
    required this.truth,
  });

  /// A stable identifier naming the sample (used in grade reporting).
  final String id;

  /// The accuracy claim this sample exercises.
  final AccuracyCondition condition;

  /// The known ground-truth colour the produced reading / prediction is graded
  /// against: the scene colour (capture) or the mixing target (recipe).
  final ColorCoordinates truth;

  /// The ΔE00 bound this sample must stay within (from its [condition]).
  double get maxDeltaE => condition.maxDeltaE;

  /// Whether the real pipeline must additionally *label* the reading approximate
  /// — true for the card-less daylight condition (AC-11), never for the others.
  bool get expectApproximate =>
      condition == AccuracyCondition.cardlessDaylight;
}

/// The held-out **card + controlled lighting** set (AC-10): each truth is read
/// back through the real capture pipeline with a reference card in view and the
/// card calibration applied, which must land within ΔE00 3. Distinct mid colours
/// so the set is not a single-point accident (≥3, plan test augmentation).
const List<HeldOutAccuracySample> heldOutCardControlled = [
  HeldOutAccuracySample(
    id: 'card-controlled/warm-earth',
    condition: AccuracyCondition.cardControlled,
    truth: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  ),
  HeldOutAccuracySample(
    id: 'card-controlled/slate',
    condition: AccuracyCondition.cardControlled,
    truth: ColorCoordinates(lightness: 45, a: -2, b: -8),
  ),
  HeldOutAccuracySample(
    id: 'card-controlled/ochre',
    condition: AccuracyCondition.cardControlled,
    truth: ColorCoordinates(lightness: 63, a: 14, b: 40),
  ),
];

/// The held-out **card-less daylight** set (AC-11): each truth is read back
/// through the real capture pipeline with **no** card, so the reading is both
/// within ΔE00 8 of truth and *labelled approximate* (never calibrated). In-sRGB
/// moderate-chroma colours so the capture-space round trip stays well inside 8.
const List<HeldOutAccuracySample> heldOutCardlessDaylight = [
  HeldOutAccuracySample(
    id: 'cardless-daylight/raw-sienna',
    condition: AccuracyCondition.cardlessDaylight,
    truth: ColorCoordinates(lightness: 52, a: 18, b: 34),
  ),
  HeldOutAccuracySample(
    id: 'cardless-daylight/sage',
    condition: AccuracyCondition.cardlessDaylight,
    truth: ColorCoordinates(lightness: 62, a: -12, b: 20),
  ),
  HeldOutAccuracySample(
    id: 'cardless-daylight/putty',
    condition: AccuracyCondition.cardlessDaylight,
    truth: ColorCoordinates(lightness: 70, a: 3, b: 12),
  ),
];

/// The held-out **recipe-vs-swatch** set (AC-12): each truth is a reachable
/// in-gamut target the real engine solves over the owned palette; the best
/// recipe's predicted (forward-mixed) colour must land within ΔE00 5 of truth.
/// Two palette masstones (reachable near-exactly) plus the shared warm-earth
/// target, so a reachable prediction is genuinely demonstrated.
const List<HeldOutAccuracySample> heldOutRecipeVsSwatch = [
  HeldOutAccuracySample(
    id: 'recipe-vs-swatch/warm-earth',
    condition: AccuracyCondition.recipeVsSwatch,
    truth: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  ),
  HeldOutAccuracySample(
    id: 'recipe-vs-swatch/yellow-ochre',
    condition: AccuracyCondition.recipeVsSwatch,
    truth: ColorCoordinates(lightness: 60, a: 12, b: 46),
  ),
  HeldOutAccuracySample(
    id: 'recipe-vs-swatch/venetian-red',
    condition: AccuracyCondition.recipeVsSwatch,
    truth: ColorCoordinates(lightness: 40, a: 32, b: 26),
  ),
];

/// The whole held-out accuracy set across the three conditions (QUALITY-4).
const List<HeldOutAccuracySample> syntheticHeldOutSet = [
  ...heldOutCardControlled,
  ...heldOutCardlessDaylight,
  ...heldOutRecipeVsSwatch,
];

/// One discriminating **perturbation control** per condition (QUALITY-4): a
/// synthetic (input, expected) pair whose independent `referenceDeltaE00`
/// *exceeds* the condition's bound. Graded directly by [AccuracyHarness.grade],
/// each must report `withinBound == false` — proving the bound + metric reject an
/// off reading, so the within-bound assertions are not vacuously satisfiable.
const List<SyntheticAccuracySample> accuracyPerturbationControls = [
  // Card+controlled control: a reading pulled far off truth — ΔE00 ≫ 3.
  SyntheticAccuracySample(
    id: 'perturbation/card-controlled',
    condition: AccuracyCondition.cardControlled,
    input: ColorCoordinates(lightness: 58, a: 25, b: 22),
    expected: ColorCoordinates(lightness: 76, a: -12, b: 52),
  ),
  // Card-less daylight control: a reading far off truth — ΔE00 ≫ 8.
  SyntheticAccuracySample(
    id: 'perturbation/cardless-daylight',
    condition: AccuracyCondition.cardlessDaylight,
    input: ColorCoordinates(lightness: 52, a: 18, b: 34),
    expected: ColorCoordinates(lightness: 52, a: -42, b: -30),
    expectApproximate: true,
  ),
  // Recipe-vs-swatch control: a prediction far off target — ΔE00 ≫ 5.
  SyntheticAccuracySample(
    id: 'perturbation/recipe-vs-swatch',
    condition: AccuracyCondition.recipeVsSwatch,
    input: ColorCoordinates(lightness: 40, a: 32, b: 26),
    expected: ColorCoordinates(lightness: 82, a: -48, b: 58),
  ),
];
