/// The per-tier inputs and results of the CVD self-assessment battery (bs-07).
///
/// These are the small value types the tiered estimate is built from: intake
/// answers (Tier 1), screening responses and their scored result (Tier 2), the
/// arrangement result (Tier 3), the threshold probes and their scored result
/// (Tier 4), and the [StartingPrior] the intake forms before the measurement
/// tiers run.
///
/// Introduced as *shells* at ENGINE-2: every type carries its final shape and
/// value equality, but no scoring lives here — the behaviour phases
/// (ENGINE-3..6) compute the results, and [assemble] on `AssessmentEngine`
/// (`assessment_engine.dart`) folds them into a `CvdEstimate`. The scale is
/// 0..1 throughout to match `CvdProfile.severity` (bs-03, D-5).
library;

import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';

/// The confusion axis a screening (Tier 2) distinguishes.
///
/// The estimate narrows a *direction* to a `CvdType` later using the prior and
/// arrangement (D — "Direction vs type"): red-green covers protan/deutan,
/// blue-yellow covers tritan.
enum ScreeningDirection {
  /// The red-green axis (protan or deutan).
  redGreen,

  /// The blue-yellow axis (tritan).
  blueYellow,
}

/// One answer the painter gives to an intake question (Tier 1, AC-3).
///
/// [questionId] identifies the question and [value] is the chosen answer (e.g.
/// `"Often"`). ENGINE-3 maps a set of these onto a [StartingPrior].
class IntakeAnswer {
  const IntakeAnswer({required this.questionId, required this.value});

  /// Stable identifier of the intake question.
  final String questionId;

  /// The answer the painter chose, verbatim.
  final String value;

  @override
  bool operator ==(Object other) =>
      other is IntakeAnswer &&
      other.questionId == questionId &&
      other.value == value;

  @override
  int get hashCode => Object.hash(questionId, value);

  @override
  String toString() => 'IntakeAnswer($questionId: $value)';
}

/// A bias toward a CVD [type] or [direction], accumulated before the
/// measurement tiers (the output of Tier 1).
///
/// [weight] is 0 (no bias) to 1 (strong bias). [none] is the empty prior the
/// shell returns and the starting point ENGINE-3/4 build on. Either or both of
/// [type] and [direction] may be null when nothing yet points at one.
class StartingPrior {
  const StartingPrior({this.type, this.direction, this.weight = 0.0});

  /// An empty prior: no bias in any direction.
  static const StartingPrior none = StartingPrior();

  /// The CVD type the intake leans toward, if any.
  final CvdType? type;

  /// The confusion axis the intake leans toward, if any.
  final ScreeningDirection? direction;

  /// Strength of the bias, 0 (none) to 1 (strong).
  final double weight;

  @override
  bool operator ==(Object other) =>
      other is StartingPrior &&
      other.type == type &&
      other.direction == direction &&
      other.weight == weight;

  @override
  int get hashCode => Object.hash(type, direction, weight);

  @override
  String toString() => 'StartingPrior(type: $type, direction: $direction, '
      'weight: $weight)';
}

/// One plate response in the pseudoisochromatic screening (Tier 2 input).
///
/// [axis] is the confusion axis the plate probes and [correct] is whether the
/// painter read it correctly. ENGINE-5 scores a list of these into a
/// [ScreeningResult].
class PlateResponse {
  const PlateResponse({required this.axis, required this.correct});

  /// The confusion axis this plate probes.
  final ScreeningDirection axis;

  /// Whether the painter read the plate correctly.
  final bool correct;

  @override
  bool operator ==(Object other) =>
      other is PlateResponse && other.axis == axis && other.correct == correct;

  @override
  int get hashCode => Object.hash(axis, correct);

  @override
  String toString() => 'PlateResponse(${axis.name}, correct: $correct)';
}

/// The scored outcome of the screening (Tier 2, AC-5): whether a deficiency is
/// [present] and, if so, along which [direction].
class ScreeningResult {
  const ScreeningResult({required this.present, required this.direction});

  /// Whether the screening detected a deficiency.
  final bool present;

  /// The confusion axis the screening points at.
  final ScreeningDirection direction;

  @override
  bool operator ==(Object other) =>
      other is ScreeningResult &&
      other.present == present &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(present, direction);

  @override
  String toString() =>
      'ScreeningResult(present: $present, ${direction.name})';
}

/// The outcome of the arrangement test (Tier 3, AC-6/7/8).
///
/// [present] is whether an arrangement was completed (false when the painter
/// skipped it, AC-8). Later phases carry the ordering detail; the shell records
/// only presence.
class ArrangementResult {
  const ArrangementResult({required this.present});

  /// Whether an arrangement result is available (false when skipped).
  final bool present;

  @override
  bool operator ==(Object other) =>
      other is ArrangementResult && other.present == present;

  @override
  int get hashCode => present.hashCode;

  @override
  String toString() => 'ArrangementResult(present: $present)';
}

/// One step of the adaptive threshold probing (Tier 4 input).
///
/// [contrast] is the contrast presented along the confusion line (0..1) and
/// [detected] is whether the painter saw it. ENGINE-6 scores a list of these
/// into a [ThresholdResult].
class ThresholdProbe {
  const ThresholdProbe({required this.contrast, required this.detected});

  /// The contrast presented along the confusion line, 0..1.
  final double contrast;

  /// Whether the painter detected the stimulus at this contrast.
  final bool detected;

  @override
  bool operator ==(Object other) =>
      other is ThresholdProbe &&
      other.contrast == contrast &&
      other.detected == detected;

  @override
  int get hashCode => Object.hash(contrast, detected);

  @override
  String toString() => 'ThresholdProbe(contrast: $contrast, detected: $detected)';
}

/// The scored outcome of the threshold probing (Tier 4, AC-9): a [severity]
/// along the painter's confusion line, 0 (none) to 1 (full dichromat).
class ThresholdResult {
  const ThresholdResult({required this.severity});

  /// Estimated severity, 0..1 (matches `CvdProfile.severity`).
  final double severity;

  @override
  bool operator ==(Object other) =>
      other is ThresholdResult && other.severity == severity;

  @override
  int get hashCode => severity.hashCode;

  @override
  String toString() => 'ThresholdResult(severity: $severity)';
}
