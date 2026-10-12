/// The scoring interface for the CVD self-assessment battery (bs-07, D-9).
///
/// All scoring lives behind [AssessmentEngine]: no widget or controller
/// computes a score — the onboarding controller (FLOW) calls these methods and
/// holds the returned value types. The behaviour phases (ENGINE-3..7) implement
/// the real scoring; [ShellAssessmentEngine] here returns trivial defaults so
/// the shells wire together with the existing suite unchanged.
library;

import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/cvd_estimate.dart';
import 'package:paint_color_assistant/onboarding/engine/severity_band.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';

/// Scores the tiered battery into a [CvdEstimate].
///
/// The tiers run fastest-first: intake forms a [StartingPrior] ([recordIntake],
/// [seedFromDiagnosis]); screening and threshold probing score into their
/// results ([scoreScreening], [scoreThreshold]); [assemble] folds the prior and
/// the available tier results into a single estimate; [band] maps a severity to
/// a plain-language [SeverityBand].
abstract interface class AssessmentEngine {
  /// Folds the Tier 1 intake answers into a [StartingPrior] (AC-3).
  StartingPrior recordIntake(List<IntakeAnswer> answers);

  /// Seeds a [StartingPrior] from a prior clinical diagnosis (AC-4).
  StartingPrior seedFromDiagnosis(CvdType type);

  /// Scores the Tier 2 screening responses into presence + direction (AC-5).
  ScreeningResult scoreScreening(List<PlateResponse> responses);

  /// Scores the Tier 4 threshold probes into a severity (AC-9).
  ThresholdResult scoreThreshold(List<ThresholdProbe> probes);

  /// Assembles the prior and the available tier results into an estimate.
  CvdEstimate assemble({
    required StartingPrior prior,
    ScreeningResult? screening,
    ArrangementResult? arrangement,
    ThresholdResult? threshold,
  });

  /// Maps a 0..1 [severity] to a plain-language band (AC-11).
  SeverityBand band(double severity);
}

/// The stable id of the Tier 1 red-green confusion question (AC-3): "do reds,
/// browns and greens get mixed up?".
///
/// The intake step tags its answer with this id so
/// [TieredAssessmentEngine.recordIntake] can tell the red-green confusion item
/// apart from any later Tier 1 question and fold it into the prior.
const String rgConfusionQuestionId = 'rg-confusion';

/// A trivial [AssessmentEngine] for the shell stage: no real scoring.
///
/// Every method returns a default so the pipeline compiles and the existing
/// suite stays green. The behaviour phases replace this with real scoring; it
/// exists so FLOW-1/PROFILE-1 have something to wire against.
class ShellAssessmentEngine implements AssessmentEngine {
  const ShellAssessmentEngine();

  @override
  StartingPrior recordIntake(List<IntakeAnswer> answers) => StartingPrior.none;

  @override
  StartingPrior seedFromDiagnosis(CvdType type) => StartingPrior.none;

  @override
  ScreeningResult scoreScreening(List<PlateResponse> responses) =>
      const ScreeningResult(
        present: false,
        direction: ScreeningDirection.redGreen,
      );

  @override
  ThresholdResult scoreThreshold(List<ThresholdProbe> probes) =>
      const ThresholdResult(severity: 0);

  @override
  CvdEstimate assemble({
    required StartingPrior prior,
    ScreeningResult? screening,
    ArrangementResult? arrangement,
    ThresholdResult? threshold,
  }) =>
      CvdEstimate(
        type: CvdType.deutan,
        severity: 0,
        prior: prior,
        screening: screening,
        threshold: threshold,
        arrangementPresent: arrangement?.present ?? false,
      );

  @override
  SeverityBand band(double severity) => SeverityBand.mild;
}

/// The real [AssessmentEngine] the production self-assessment scores through.
///
/// Introduced at ENGINE-3 with real Tier 1 intake scoring ([recordIntake]); the
/// later tier phases replace one more inherited method each (ENGINE-4
/// `seedFromDiagnosis`, ENGINE-5 `scoreScreening`, ENGINE-6 `scoreThreshold`,
/// FLOW-5 `assemble`, ENGINE-7 `band`). Until a tier is built it inherits
/// [ShellAssessmentEngine]'s trivial default, so the pipeline stays whole and
/// the un-pended ACs are the only ones asserted.
class TieredAssessmentEngine extends ShellAssessmentEngine {
  /// Creates the production engine (const: it holds no state).
  const TieredAssessmentEngine();

  /// Folds the Tier 1 intake answers into a [StartingPrior] (AC-3).
  ///
  /// The red-green confusion question ([rgConfusionQuestionId]) is the only Tier
  /// 1 item that leans the prior today: the more often the painter reports
  /// mixing up reds, browns and greens, the stronger the evidence of a red-green
  /// deficiency. Each such answer contributes a frequency weight; a non-zero
  /// total leans the prior toward [ScreeningDirection.redGreen] (its weight
  /// clamped to 1). "Never", an unrecognised answer and an empty intake
  /// contribute nothing, leaving [StartingPrior.none]. Answers to other
  /// questions are ignored (none is wired yet). The controller keeps at most one
  /// answer per question, so re-answering replaces rather than accumulates.
  @override
  StartingPrior recordIntake(List<IntakeAnswer> answers) {
    var weight = 0.0;
    for (final answer in answers) {
      if (answer.questionId == rgConfusionQuestionId) {
        weight += _confusionFrequencyWeight(answer.value);
      }
    }
    if (weight <= 0) return StartingPrior.none;
    return StartingPrior(
      direction: ScreeningDirection.redGreen,
      weight: weight.clamp(0.0, 1.0),
    );
  }

  /// The prior-weight contribution of a red-green confusion [frequency] answer:
  /// a stronger lean the more often colours are confused. Unrecognised answers
  /// (and "Never") contribute nothing.
  static double _confusionFrequencyWeight(String frequency) {
    switch (frequency) {
      case 'Often':
        return 1.0;
      case 'Sometimes':
        return 0.5;
      default:
        return 0.0;
    }
  }

  /// Seeds a [StartingPrior] from a prior clinical diagnosis (AC-4).
  ///
  /// A reported diagnosis is authoritative evidence, so the prior leans fully
  /// (weight 1) toward the diagnosed [type], along the confusion axis that type
  /// sits on ([_directionForType]: protan/deutan are red-green, tritan is
  /// blue-yellow). This is the strongest Tier 1 signal — unlike [recordIntake]'s
  /// graded self-report, the type itself is known, so the prior carries it.
  @override
  StartingPrior seedFromDiagnosis(CvdType type) => StartingPrior(
        type: type,
        direction: _directionForType(type),
        weight: 1.0,
      );

  /// The confusion axis a dichromacy [type] sits on: tritan is the blue-yellow
  /// (S-cone) line; protan and deutan are the red-green (L/M-cone) line.
  static ScreeningDirection _directionForType(CvdType type) =>
      type == CvdType.tritan
          ? ScreeningDirection.blueYellow
          : ScreeningDirection.redGreen;

  /// Scores the Tier 2 pseudoisochromatic screening into presence + direction
  /// (AC-5).
  ///
  /// A deficiency is [ScreeningResult.present] when the painter misreads any
  /// plate; its [ScreeningResult.direction] is the confusion axis the misread
  /// plates fall on — red-green or blue-yellow — taken from the axis with the
  /// more misses (a screening points at whichever axis the painter failed more
  /// of). Reading every plate correctly reports no deficiency. The direction of
  /// an absent result is immaterial and defaults to red-green (the more common
  /// axis), matching the shell default.
  @override
  ScreeningResult scoreScreening(List<PlateResponse> responses) {
    var redGreenMissed = 0;
    var blueYellowMissed = 0;
    for (final response in responses) {
      if (response.correct) continue;
      if (response.axis == ScreeningDirection.redGreen) {
        redGreenMissed++;
      } else {
        blueYellowMissed++;
      }
    }
    if (redGreenMissed == 0 && blueYellowMissed == 0) {
      return const ScreeningResult(
        present: false,
        direction: ScreeningDirection.redGreen,
      );
    }
    return ScreeningResult(
      present: true,
      direction: blueYellowMissed > redGreenMissed
          ? ScreeningDirection.blueYellow
          : ScreeningDirection.redGreen,
    );
  }
}
