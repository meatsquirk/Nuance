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

  group('TieredAssessmentEngine.recordIntake (Tier 1, AC-3)', () {
    const engine = TieredAssessmentEngine();

    IntakeAnswer confusion(String value) =>
        IntakeAnswer(questionId: rgConfusionQuestionId, value: value);

    test('"Often" leans the prior red-green with full weight', () {
      final prior = engine.recordIntake([confusion('Often')]);
      expect(prior.direction, ScreeningDirection.redGreen);
      expect(prior.weight, 1.0);
      expect(prior.type, isNull);
    });

    test('"Sometimes" leans red-green with partial weight', () {
      final prior = engine.recordIntake([confusion('Sometimes')]);
      expect(prior.direction, ScreeningDirection.redGreen);
      expect(prior.weight, 0.5);
    });

    test('"Never" contributes nothing — the empty prior', () {
      expect(engine.recordIntake([confusion('Never')]), StartingPrior.none);
    });

    test('an unrecognised answer contributes nothing', () {
      expect(engine.recordIntake([confusion('Dunno')]), StartingPrior.none);
    });

    test('no intake answers leaves the empty prior', () {
      expect(engine.recordIntake(const []), StartingPrior.none);
    });

    test('an answer to another question is ignored', () {
      expect(
        engine.recordIntake(
            const [IntakeAnswer(questionId: 'other', value: 'Often')]),
        StartingPrior.none,
      );
    });

    test('repeated confusion answers accumulate and clamp to 1', () {
      // Two "Often" answers would sum to 2.0; the weight clamps to 1.0 (the
      // controller keeps only one per question, but the engine is total-safe).
      final prior = engine.recordIntake([confusion('Often'), confusion('Often')]);
      expect(prior.direction, ScreeningDirection.redGreen);
      expect(prior.weight, 1.0);
    });

    test('inherits the trivial defaults for the tiers not yet built', () {
      expect(engine.band(0.95), SeverityBand.mild);
    });
  });

  group('TieredAssessmentEngine.seedFromDiagnosis (Tier 1, AC-4)', () {
    const engine = TieredAssessmentEngine();

    test('a deutan diagnosis seeds the prior as deutan, red-green, full weight',
        () {
      final prior = engine.seedFromDiagnosis(CvdType.deutan);
      expect(prior.type, CvdType.deutan);
      expect(prior.direction, ScreeningDirection.redGreen);
      expect(prior.weight, 1.0);
    });

    test('a protan diagnosis seeds protan on the red-green axis', () {
      final prior = engine.seedFromDiagnosis(CvdType.protan);
      expect(prior.type, CvdType.protan);
      expect(prior.direction, ScreeningDirection.redGreen);
      expect(prior.weight, 1.0);
    });

    test('a tritan diagnosis seeds tritan on the blue-yellow axis', () {
      final prior = engine.seedFromDiagnosis(CvdType.tritan);
      expect(prior.type, CvdType.tritan);
      expect(prior.direction, ScreeningDirection.blueYellow);
      expect(prior.weight, 1.0);
    });
  });

  group('TieredAssessmentEngine.scoreScreening (Tier 2, AC-5)', () {
    const engine = TieredAssessmentEngine();

    PlateResponse plate(ScreeningDirection axis, {required bool correct}) =>
        PlateResponse(axis: axis, correct: correct);

    test('misreading the red-green plates reports present along red-green', () {
      final result = engine.scoreScreening([
        plate(ScreeningDirection.redGreen, correct: false),
        plate(ScreeningDirection.redGreen, correct: false),
        plate(ScreeningDirection.blueYellow, correct: true),
      ]);
      expect(result.present, isTrue);
      expect(result.direction, ScreeningDirection.redGreen);
    });

    test('misreading the blue-yellow plates reports present along blue-yellow',
        () {
      final result = engine.scoreScreening([
        plate(ScreeningDirection.redGreen, correct: true),
        plate(ScreeningDirection.blueYellow, correct: false),
        plate(ScreeningDirection.blueYellow, correct: false),
      ]);
      expect(result.present, isTrue);
      expect(result.direction, ScreeningDirection.blueYellow);
    });

    test('reading every plate correctly reports no deficiency', () {
      final result = engine.scoreScreening([
        plate(ScreeningDirection.redGreen, correct: true),
        plate(ScreeningDirection.blueYellow, correct: true),
      ]);
      expect(
        result,
        const ScreeningResult(
            present: false, direction: ScreeningDirection.redGreen),
      );
    });

    test('no responses report no deficiency', () {
      expect(
        engine.scoreScreening(const []),
        const ScreeningResult(
            present: false, direction: ScreeningDirection.redGreen),
      );
    });

    test('an equal miss on both axes points at red-green (the tie default)', () {
      // One miss on each axis: present, and the direction falls to red-green
      // (blue-yellow only wins when it has strictly more misses).
      final result = engine.scoreScreening([
        plate(ScreeningDirection.redGreen, correct: false),
        plate(ScreeningDirection.blueYellow, correct: false),
      ]);
      expect(result.present, isTrue);
      expect(result.direction, ScreeningDirection.redGreen);
    });
  });
}
