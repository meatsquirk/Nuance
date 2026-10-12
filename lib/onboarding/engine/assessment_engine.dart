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
