// bs-12 accuracy harness (QUALITY-1 scaffold).
//
// test-support for the accuracy ACs (AC-10/11/12): grades a
// [SyntheticAccuracySample]'s produced colour against its known expected colour
// with the **independent** `referenceDeltaE00` (from `comparison_harness.dart`),
// so accuracy is never graded by the product's own ΔE metric against itself
// (plan bs-12 D-2).
//
// QUALITY-1 lays the grading signatures over the seed set: [grade] computes the
// reference ΔE00 between a sample's input and expected, and [gradeAll] returns
// one [AccuracyGrade] per sample — a populated result ITEST-1's smoke test can
// assert over. QUALITY-4 feeds the sample inputs through the *real* capture /
// engine pipeline (via `buildApp`) rather than reading them straight off the
// fixture, and asserts every grade is within bound plus the discriminating
// perturbation controls.
//
// This is test-support only — no `lib/` product code (plan bs-12 D-7).

import 'package:paint_color_assistant/domain/color_coordinates.dart';

import '../../comparison_harness.dart' show referenceDeltaE00;
import 'synthetic_accuracy_set.dart';

/// The ΔE00 outcome of grading one [SyntheticAccuracySample] (plan bs-12 D-2).
class AccuracyGrade {
  const AccuracyGrade({
    required this.sampleId,
    required this.condition,
    required this.deltaE,
    required this.maxDeltaE,
  });

  /// The graded sample's identifier.
  final String sampleId;

  /// Which accuracy claim it exercised.
  final AccuracyCondition condition;

  /// The ΔE00 between the produced and expected colour, by the independent
  /// reference metric.
  final double deltaE;

  /// The bound the sample's [condition] requires it stay within.
  final double maxDeltaE;

  /// Whether the produced colour landed within the condition's bound.
  bool get withinBound => deltaE <= maxDeltaE;

  @override
  String toString() =>
      'AccuracyGrade($sampleId: ΔE00 ${deltaE.toStringAsFixed(2)} '
      '${withinBound ? '≤' : '>'} $maxDeltaE)';
}

/// Grades synthetic accuracy samples with the independent `referenceDeltaE00`.
///
/// Stateless: [grade] scores one sample, [gradeAll] the whole set. QUALITY-1
/// scores the fixture's recorded [SyntheticAccuracySample.input] directly;
/// QUALITY-4 replaces the input with the colour the *real* pipeline produces for
/// that condition, keeping the independent reference grading.
class AccuracyHarness {
  const AccuracyHarness();

  /// The independent reference ΔE00 between a produced and an expected colour.
  double deltaE(ColorCoordinates produced, ColorCoordinates expected) =>
      referenceDeltaE00(produced, expected);

  /// Grades one [sample]: the reference ΔE00 of its input vs its expected
  /// colour, against the condition's bound.
  AccuracyGrade grade(SyntheticAccuracySample sample) => AccuracyGrade(
        sampleId: sample.id,
        condition: sample.condition,
        deltaE: deltaE(sample.input, sample.expected),
        maxDeltaE: sample.maxDeltaE,
      );

  /// Grades every sample in [samples] (defaults to the seed [syntheticAccuracySet]).
  List<AccuracyGrade> gradeAll([
    List<SyntheticAccuracySample> samples = syntheticAccuracySet,
  ]) =>
      [for (final sample in samples) grade(sample)];
}
