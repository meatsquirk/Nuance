import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/cvd_estimate.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';

void main() {
  group('CvdEstimate', () {
    const base = CvdEstimate(
      type: CvdType.deutan,
      severity: 0.5,
      prior: StartingPrior.none,
    );

    test('keeps its type, severity and prior; tiers default to null/false', () {
      expect(base.type, CvdType.deutan);
      expect(base.severity, 0.5);
      expect(base.prior, StartingPrior.none);
      expect(base.screening, isNull);
      expect(base.threshold, isNull);
      expect(base.arrangementPresent, isFalse);
    });

    test('carries the optional tier results when given', () {
      const estimate = CvdEstimate(
        type: CvdType.protan,
        severity: 0.8,
        prior: StartingPrior(type: CvdType.protan),
        screening: ScreeningResult(
            present: true, direction: ScreeningDirection.redGreen),
        threshold: ThresholdResult(severity: 0.8),
        arrangementPresent: true,
      );
      expect(estimate.screening,
          const ScreeningResult(present: true, direction: ScreeningDirection.redGreen));
      expect(estimate.threshold, const ThresholdResult(severity: 0.8));
      expect(estimate.arrangementPresent, isTrue);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = CvdEstimate(
          type: CvdType.deutan, severity: 0.5, prior: StartingPrior.none);
      expect(a == base, isTrue);
      expect(a.hashCode, base.hashCode);
    });

    test('differs when the type differs', () {
      expect(
        base ==
            const CvdEstimate(
                type: CvdType.protan,
                severity: 0.5,
                prior: StartingPrior.none),
        isFalse,
      );
    });

    test('differs when the severity differs', () {
      expect(
        base ==
            const CvdEstimate(
                type: CvdType.deutan,
                severity: 0.9,
                prior: StartingPrior.none),
        isFalse,
      );
    });

    test('differs when the prior differs', () {
      expect(
        base ==
            const CvdEstimate(
                type: CvdType.deutan,
                severity: 0.5,
                prior: StartingPrior(type: CvdType.deutan)),
        isFalse,
      );
    });

    test('differs when the screening differs', () {
      expect(
        base ==
            const CvdEstimate(
                type: CvdType.deutan,
                severity: 0.5,
                prior: StartingPrior.none,
                screening: ScreeningResult(
                    present: true, direction: ScreeningDirection.redGreen)),
        isFalse,
      );
    });

    test('differs when the threshold differs', () {
      expect(
        base ==
            const CvdEstimate(
                type: CvdType.deutan,
                severity: 0.5,
                prior: StartingPrior.none,
                threshold: ThresholdResult(severity: 0.5)),
        isFalse,
      );
    });

    test('differs when arrangementPresent differs', () {
      expect(
        base ==
            const CvdEstimate(
                type: CvdType.deutan,
                severity: 0.5,
                prior: StartingPrior.none,
                arrangementPresent: true),
        isFalse,
      );
    });

    test('is not equal to a non-CvdEstimate object', () {
      // ignore: unrelated_type_equality_checks
      expect(base == 'x', isFalse);
    });

    test('has a readable toString naming the type and tiers', () {
      expect(
        base.toString(),
        'CvdEstimate(deutan, severity: 0.5, '
        'prior: StartingPrior(type: null, direction: null, weight: 0.0), '
        'screening: null, threshold: null, arrangementPresent: false)',
      );
    });
  });
}
