import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/assessment_engine.dart';
import 'package:paint_color_assistant/onboarding/engine/cvd_estimate.dart';
import 'package:paint_color_assistant/onboarding/engine/severity_band.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';

void main() {
  group('ShellAssessmentEngine (trivial defaults — no scoring yet)', () {
    const engine = ShellAssessmentEngine();

    test('recordIntake returns the empty prior', () {
      expect(
        engine.recordIntake(const [IntakeAnswer(questionId: 'q1', value: 'Often')]),
        StartingPrior.none,
      );
    });

    test('seedFromDiagnosis returns the empty prior (no behaviour yet)', () {
      expect(engine.seedFromDiagnosis(CvdType.deutan), StartingPrior.none);
    });

    test('scoreScreening returns absent, red-green', () {
      expect(
        engine.scoreScreening(const [
          PlateResponse(axis: ScreeningDirection.redGreen, correct: true),
        ]),
        const ScreeningResult(
            present: false, direction: ScreeningDirection.redGreen),
      );
    });

    test('scoreThreshold returns zero severity', () {
      expect(
        engine.scoreThreshold(
            const [ThresholdProbe(contrast: 0.3, detected: true)]),
        const ThresholdResult(severity: 0),
      );
    });

    test('assemble carries the prior and tier results through, severity 0', () {
      final estimate = engine.assemble(
        prior: const StartingPrior(type: CvdType.protan),
        screening: const ScreeningResult(
            present: true, direction: ScreeningDirection.redGreen),
        arrangement: const ArrangementResult(present: true),
        threshold: const ThresholdResult(severity: 0.4),
      );
      expect(
        estimate,
        const CvdEstimate(
          type: CvdType.deutan,
          severity: 0,
          prior: StartingPrior(type: CvdType.protan),
          screening: ScreeningResult(
              present: true, direction: ScreeningDirection.redGreen),
          threshold: ThresholdResult(severity: 0.4),
          arrangementPresent: true,
        ),
      );
    });

    test('assemble defaults arrangementPresent to false when arrangement is null', () {
      final estimate = engine.assemble(prior: StartingPrior.none);
      expect(estimate.arrangementPresent, isFalse);
      expect(estimate.screening, isNull);
      expect(estimate.threshold, isNull);
    });

    test('band returns mild for any severity (behaviour pending G-4/ENGINE-7)', () {
      expect(engine.band(0.1), SeverityBand.mild);
      expect(engine.band(0.95), SeverityBand.mild);
    });
  });
}
