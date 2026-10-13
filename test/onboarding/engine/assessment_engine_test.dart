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

    test('no longer inherits the always-mild band stub (ENGINE-7 overrides it)',
        () {
      // ENGINE-7 is the last tier: the Tiered engine now overrides every method,
      // so a strong severity no longer falls through to ShellAssessmentEngine's
      // always-mild default.
      expect(engine.band(0.95), SeverityBand.strong);
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

  group('TieredAssessmentEngine.scoreThreshold (Tier 4, AC-9)', () {
    const engine = TieredAssessmentEngine();

    ThresholdProbe probe(double contrast, {required bool detected}) =>
        ThresholdProbe(contrast: contrast, detected: detected);

    test('detecting every probe scores zero severity', () {
      // The painter sees even the lowest contrast — no threshold deficit.
      expect(
        engine.scoreThreshold([
          probe(0.2, detected: true),
          probe(0.4, detected: true),
          probe(0.8, detected: true),
        ]),
        const ThresholdResult(severity: 0),
      );
    });

    test('no probes score zero severity', () {
      expect(engine.scoreThreshold(const []), const ThresholdResult(severity: 0));
    });

    test('the highest contrast the painter cannot see is the severity', () {
      // Misses low contrast, only sees high contrast → the threshold is the
      // highest failed contrast (0.6), a severity on the confusion line.
      expect(
        engine.scoreThreshold([
          probe(0.2, detected: false),
          probe(0.4, detected: false),
          probe(0.6, detected: false),
          probe(0.8, detected: true),
        ]),
        const ThresholdResult(severity: 0.6),
      );
    });

    test('a later easier miss does not lower the threshold', () {
      // A miss at a lower contrast than one already failed must not reduce the
      // severity — the threshold is the *highest* failed contrast, 0.8.
      expect(
        engine.scoreThreshold([
          probe(0.8, detected: false),
          probe(0.4, detected: false),
        ]),
        const ThresholdResult(severity: 0.8),
      );
    });

    test('harder thresholds score higher than easier ones (monotonic)', () {
      final easy = engine
          .scoreThreshold([probe(0.2, detected: true), probe(0.4, detected: true)]);
      final hard = engine.scoreThreshold(
          [probe(0.2, detected: false), probe(0.4, detected: true)]);
      expect(hard.severity, greaterThan(easy.severity));
    });

    test('a severity is clamped to the 0..1 scale', () {
      // A defensively out-of-range contrast cannot push severity above 1.
      expect(
        engine.scoreThreshold([probe(1.5, detected: false)]),
        const ThresholdResult(severity: 1),
      );
    });
  });

  group('TieredAssessmentEngine.assemble (FLOW-5, D-7)', () {
    const engine = TieredAssessmentEngine();

    test('a measured present screening sets the direction over the prior', () {
      // The prior leans red-green, but a present blue-yellow screening is the
      // measured evidence and wins — narrowing the type to tritan.
      final estimate = engine.assemble(
        prior: const StartingPrior(direction: ScreeningDirection.redGreen),
        screening: const ScreeningResult(
            present: true, direction: ScreeningDirection.blueYellow),
      );
      expect(estimate.type, CvdType.tritan);
    });

    test('an absent screening falls back to the prior lean for the direction',
        () {
      // present == false: the screening carries no direction evidence, so the
      // prior's blue-yellow lean stands and the type narrows to tritan.
      final estimate = engine.assemble(
        prior: const StartingPrior(direction: ScreeningDirection.blueYellow),
        screening: const ScreeningResult(
            present: false, direction: ScreeningDirection.redGreen),
      );
      expect(estimate.type, CvdType.tritan);
    });

    test('with no screening the prior direction narrows the type', () {
      final estimate = engine.assemble(
        prior: const StartingPrior(direction: ScreeningDirection.redGreen),
      );
      expect(estimate.type, CvdType.deutan);
    });

    test('a directionless prior defaults to a red-green (deutan) estimate', () {
      // The empty prior leans nowhere and no tier ran: the estimate falls to the
      // more common red-green deutan default, and severity is 0.
      final estimate = engine.assemble(prior: StartingPrior.none);
      expect(estimate.type, CvdType.deutan);
      expect(estimate.severity, 0);
      expect(estimate.arrangementPresent, isFalse);
      expect(estimate.screening, isNull);
      expect(estimate.threshold, isNull);
    });

    test('a reported diagnosis type is kept over the narrowed direction', () {
      // A present red-green screening would narrow to deutan, but the authoritative
      // protan diagnosis on the prior is kept.
      final estimate = engine.assemble(
        prior: const StartingPrior(
            type: CvdType.protan,
            direction: ScreeningDirection.redGreen,
            weight: 1),
        screening: const ScreeningResult(
            present: true, direction: ScreeningDirection.redGreen),
      );
      expect(estimate.type, CvdType.protan);
    });

    test('the measured threshold severity is used when probing ran', () {
      final estimate = engine.assemble(
        prior: const StartingPrior(
            direction: ScreeningDirection.redGreen, weight: 1),
        threshold: const ThresholdResult(severity: 0.6),
      );
      // The Tier 4 measurement (0.6) wins over the prior's self-report weight.
      expect(estimate.severity, 0.6);
    });

    test('with no threshold the prior weight stands in for the severity', () {
      final estimate = engine.assemble(
        prior: const StartingPrior(
            direction: ScreeningDirection.redGreen, weight: 0.5),
      );
      expect(estimate.severity, 0.5);
    });

    test('a completed arrangement is recorded as present', () {
      final estimate = engine.assemble(
        prior: StartingPrior.none,
        arrangement: const ArrangementResult(present: true),
      );
      expect(estimate.arrangementPresent, isTrue);
    });

    test('carries the prior and tier results through onto the estimate', () {
      const prior = StartingPrior(
          type: CvdType.deutan, direction: ScreeningDirection.redGreen, weight: 1);
      const screening =
          ScreeningResult(present: true, direction: ScreeningDirection.redGreen);
      const threshold = ThresholdResult(severity: 0.6);
      final estimate = engine.assemble(
        prior: prior,
        screening: screening,
        arrangement: const ArrangementResult(present: true),
        threshold: threshold,
      );
      expect(
        estimate,
        const CvdEstimate(
          type: CvdType.deutan,
          severity: 0.6,
          prior: prior,
          screening: screening,
          threshold: threshold,
          arrangementPresent: true,
        ),
      );
    });
  });

  group('TieredAssessmentEngine.band (AC-11, G-4 cut-offs)', () {
    const engine = TieredAssessmentEngine();

    test('the three AC-11 slider anchors map to the three bands', () {
      // 30 / 60 / 90 on the 0..100 slider → severity 0.30 / 0.60 / 0.90 (D-5).
      expect(engine.band(0.30), SeverityBand.mild);
      expect(engine.band(0.60), SeverityBand.moderate);
      expect(engine.band(0.90), SeverityBand.strong);
    });

    test('each band region reads its band', () {
      expect(engine.band(0.0), SeverityBand.mild); // low end of mild
      expect(engine.band(0.44), SeverityBand.mild); // just below the cut-off
      expect(engine.band(0.5), SeverityBand.moderate); // inside moderate
      expect(engine.band(0.74), SeverityBand.moderate); // just below the cut-off
      expect(engine.band(0.8), SeverityBand.strong); // inside strong
      expect(engine.band(1.0), SeverityBand.strong); // top of the scale
    });

    test('the cut-offs are half-open going up — the midpoint reads the higher '
        'band', () {
      // 0.45 is moderate (not mild); 0.75 is strong (not moderate): the band
      // steps up exactly at the anchor midpoint, so the mapping is monotone.
      expect(engine.band(0.45), SeverityBand.moderate);
      expect(engine.band(0.75), SeverityBand.strong);
    });

    test('out-of-range severities extend the end bands (total-safe)', () {
      // The pipeline clamps severity to 0..1 upstream; the function still stays
      // total for a defensively out-of-range value.
      expect(engine.band(-0.1), SeverityBand.mild);
      expect(engine.band(1.5), SeverityBand.strong);
    });
  });
}
