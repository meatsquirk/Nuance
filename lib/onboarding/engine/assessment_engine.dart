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

  /// Scores the Tier 4 adaptive threshold probes into a severity on the
  /// painter's confusion line (AC-9).
  ///
  /// Each [ThresholdProbe] presents a stimulus at a contrast *along the
  /// confusion line* (the direction already fixed by the earlier tiers) and
  /// records whether the painter detected it. The severity is the painter's
  /// detection threshold on that line: the **highest contrast they failed to
  /// detect**, since they need more contrast than that to perceive the
  /// difference — a fuller deficiency fails higher-contrast probes and so scores
  /// a higher severity (monotone). A painter who detects every probe (including
  /// the lowest contrast) has no measurable threshold deficit and scores 0; an
  /// empty probe set likewise scores 0 (the pipeline stays total-safe). The
  /// result is clamped to the 0..1 severity scale (`CvdProfile.severity`).
  @override
  ThresholdResult scoreThreshold(List<ThresholdProbe> probes) {
    var threshold = 0.0;
    for (final probe in probes) {
      if (!probe.detected && probe.contrast > threshold) {
        threshold = probe.contrast;
      }
    }
    return ThresholdResult(severity: threshold.clamp(0.0, 1.0).toDouble());
  }

  /// Folds the [prior] and the available tier results into a single estimate
  /// (D-7, AC-1/10/11/13).
  ///
  /// The tiers are optional and run fastest-first, so the estimate is assembled
  /// from whatever is present — a skipped tier simply does not contribute, and a
  /// result is always reachable (the shell default would stand in for a tier
  /// never run):
  ///
  /// - **Direction** (the confusion axis): a *present* Tier 2 [screening] is the
  ///   measured evidence and wins; failing that the Tier 1 [prior]'s lean is
  ///   used; failing that the red-green axis (the more common, matching the
  ///   shell default).
  /// - **Type**: an authoritative reported diagnosis (the [prior] carries a
  ///   concrete [CvdType]) is kept as-is; otherwise the direction is narrowed to
  ///   the representative type on that axis — red-green to deutan (the more
  ///   common dichromacy), blue-yellow to tritan. The painter refines it by hand
  ///   on the result step (AC-10, FLOW-6).
  /// - **Severity** (0..1): the measured Tier 4 [threshold] severity when the
  ///   probing ran; otherwise the [prior]'s graded self-report weight stands in,
  ///   clamped to the 0..1 `CvdProfile.severity` scale. The painter can override
  ///   it with the self-calibration slider (AC-12, FLOW-7).
  ///
  /// [arrangement] contributes only its presence (a skip leaves it absent, AC-8);
  /// the ordering detail is carried but not yet folded into the type/severity.
  @override
  CvdEstimate assemble({
    required StartingPrior prior,
    ScreeningResult? screening,
    ArrangementResult? arrangement,
    ThresholdResult? threshold,
  }) {
    final direction = _estimatedDirection(prior, screening);
    return CvdEstimate(
      type: _estimatedType(prior, direction),
      severity: _estimatedSeverity(prior, threshold),
      prior: prior,
      screening: screening,
      threshold: threshold,
      arrangementPresent: arrangement?.present ?? false,
    );
  }

  /// The confusion axis the estimate sits on: a measured, *present* [screening]
  /// is stronger evidence than the self-reported [prior] and wins; otherwise the
  /// prior's lean is used, falling back to red-green (the more common axis, the
  /// shell default).
  static ScreeningDirection _estimatedDirection(
    StartingPrior prior,
    ScreeningResult? screening,
  ) {
    if (screening != null && screening.present) return screening.direction;
    return prior.direction ?? ScreeningDirection.redGreen;
  }

  /// The estimated dichromacy class: a reported diagnosis ([prior.type]) is
  /// authoritative and kept; otherwise [direction] is narrowed to the
  /// representative type on its axis (red-green to deutan, blue-yellow to
  /// tritan).
  static CvdType _estimatedType(
    StartingPrior prior,
    ScreeningDirection direction,
  ) {
    final reported = prior.type;
    if (reported != null) return reported;
    return direction == ScreeningDirection.blueYellow
        ? CvdType.tritan
        : CvdType.deutan;
  }

  /// The estimated severity (0..1): the measured [threshold] severity when the
  /// Tier 4 probing ran, otherwise the [prior]'s graded self-report weight,
  /// clamped to the `CvdProfile.severity` scale.
  static double _estimatedSeverity(
    StartingPrior prior,
    ThresholdResult? threshold,
  ) {
    final severity = threshold?.severity ?? prior.weight;
    return severity.clamp(0.0, 1.0).toDouble();
  }
}
