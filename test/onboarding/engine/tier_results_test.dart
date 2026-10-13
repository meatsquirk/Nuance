import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';

void main() {
  group('ScreeningDirection', () {
    test('covers the red-green and blue-yellow axes', () {
      expect(
        ScreeningDirection.values,
        containsAll(<ScreeningDirection>[
          ScreeningDirection.redGreen,
          ScreeningDirection.blueYellow,
        ]),
      );
    });
  });

  group('IntakeAnswer', () {
    test('keeps its question id and value', () {
      const answer = IntakeAnswer(questionId: 'q1', value: 'Often');
      expect(answer.questionId, 'q1');
      expect(answer.value, 'Often');
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = IntakeAnswer(questionId: 'q1', value: 'Often');
      const b = IntakeAnswer(questionId: 'q1', value: 'Often');
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the question id differs', () {
      expect(
        const IntakeAnswer(questionId: 'q1', value: 'Often') ==
            const IntakeAnswer(questionId: 'q2', value: 'Often'),
        isFalse,
      );
    });

    test('differs when the value differs', () {
      expect(
        const IntakeAnswer(questionId: 'q1', value: 'Often') ==
            const IntakeAnswer(questionId: 'q1', value: 'Never'),
        isFalse,
      );
    });

    test('is not equal to a non-IntakeAnswer object', () {
      const answer = IntakeAnswer(questionId: 'q1', value: 'Often');
      // ignore: unrelated_type_equality_checks
      expect(answer == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const IntakeAnswer(questionId: 'q1', value: 'Often').toString(),
        'IntakeAnswer(q1: Often)',
      );
    });
  });

  group('StartingPrior', () {
    test('none is an empty prior', () {
      expect(StartingPrior.none.type, isNull);
      expect(StartingPrior.none.direction, isNull);
      expect(StartingPrior.none.weight, 0.0);
    });

    test('keeps an explicit type, direction and weight', () {
      const prior = StartingPrior(
        type: CvdType.deutan,
        direction: ScreeningDirection.redGreen,
        weight: 0.4,
      );
      expect(prior.type, CvdType.deutan);
      expect(prior.direction, ScreeningDirection.redGreen);
      expect(prior.weight, 0.4);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = StartingPrior(type: CvdType.deutan, weight: 0.4);
      const b = StartingPrior(type: CvdType.deutan, weight: 0.4);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the type differs', () {
      expect(
        const StartingPrior(type: CvdType.deutan) ==
            const StartingPrior(type: CvdType.protan),
        isFalse,
      );
    });

    test('differs when the direction differs', () {
      expect(
        const StartingPrior(direction: ScreeningDirection.redGreen) ==
            const StartingPrior(direction: ScreeningDirection.blueYellow),
        isFalse,
      );
    });

    test('differs when the weight differs', () {
      expect(
        const StartingPrior(weight: 0.4) == const StartingPrior(weight: 0.5),
        isFalse,
      );
    });

    test('is not equal to a non-StartingPrior object', () {
      // ignore: unrelated_type_equality_checks
      expect(StartingPrior.none == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const StartingPrior(type: CvdType.deutan, weight: 0.4).toString(),
        'StartingPrior(type: CvdType.deutan, direction: null, weight: 0.4)',
      );
    });
  });

  group('PlateResponse', () {
    test('keeps its axis and correctness', () {
      const response =
          PlateResponse(axis: ScreeningDirection.redGreen, correct: true);
      expect(response.axis, ScreeningDirection.redGreen);
      expect(response.correct, isTrue);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = PlateResponse(axis: ScreeningDirection.redGreen, correct: true);
      const b = PlateResponse(axis: ScreeningDirection.redGreen, correct: true);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the axis differs', () {
      expect(
        const PlateResponse(axis: ScreeningDirection.redGreen, correct: true) ==
            const PlateResponse(
                axis: ScreeningDirection.blueYellow, correct: true),
        isFalse,
      );
    });

    test('differs when correctness differs', () {
      expect(
        const PlateResponse(axis: ScreeningDirection.redGreen, correct: true) ==
            const PlateResponse(
                axis: ScreeningDirection.redGreen, correct: false),
        isFalse,
      );
    });

    test('is not equal to a non-PlateResponse object', () {
      const response =
          PlateResponse(axis: ScreeningDirection.redGreen, correct: true);
      // ignore: unrelated_type_equality_checks
      expect(response == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const PlateResponse(axis: ScreeningDirection.redGreen, correct: true)
            .toString(),
        'PlateResponse(redGreen, correct: true)',
      );
    });
  });

  group('ScreeningResult', () {
    test('keeps its presence and direction', () {
      const result = ScreeningResult(
          present: true, direction: ScreeningDirection.blueYellow);
      expect(result.present, isTrue);
      expect(result.direction, ScreeningDirection.blueYellow);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = ScreeningResult(
          present: true, direction: ScreeningDirection.redGreen);
      const b = ScreeningResult(
          present: true, direction: ScreeningDirection.redGreen);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when presence differs', () {
      expect(
        const ScreeningResult(
                present: true, direction: ScreeningDirection.redGreen) ==
            const ScreeningResult(
                present: false, direction: ScreeningDirection.redGreen),
        isFalse,
      );
    });

    test('differs when direction differs', () {
      expect(
        const ScreeningResult(
                present: true, direction: ScreeningDirection.redGreen) ==
            const ScreeningResult(
                present: true, direction: ScreeningDirection.blueYellow),
        isFalse,
      );
    });

    test('is not equal to a non-ScreeningResult object', () {
      const result = ScreeningResult(
          present: true, direction: ScreeningDirection.redGreen);
      // ignore: unrelated_type_equality_checks
      expect(result == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const ScreeningResult(
                present: true, direction: ScreeningDirection.redGreen)
            .toString(),
        'ScreeningResult(present: true, redGreen)',
      );
    });
  });

  group('ArrangementResult', () {
    test('keeps its presence', () {
      const result = ArrangementResult(present: true);
      expect(result.present, isTrue);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = ArrangementResult(present: true);
      const b = ArrangementResult(present: true);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when presence differs', () {
      expect(
        const ArrangementResult(present: true) ==
            const ArrangementResult(present: false),
        isFalse,
      );
    });

    test('is not equal to a non-ArrangementResult object', () {
      const result = ArrangementResult(present: true);
      // ignore: unrelated_type_equality_checks
      expect(result == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const ArrangementResult(present: false).toString(),
        'ArrangementResult(present: false)',
      );
    });
  });

  group('ThresholdProbe', () {
    test('keeps its contrast and detection', () {
      const probe = ThresholdProbe(contrast: 0.3, detected: true);
      expect(probe.contrast, 0.3);
      expect(probe.detected, isTrue);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = ThresholdProbe(contrast: 0.3, detected: true);
      const b = ThresholdProbe(contrast: 0.3, detected: true);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when contrast differs', () {
      expect(
        const ThresholdProbe(contrast: 0.3, detected: true) ==
            const ThresholdProbe(contrast: 0.5, detected: true),
        isFalse,
      );
    });

    test('differs when detection differs', () {
      expect(
        const ThresholdProbe(contrast: 0.3, detected: true) ==
            const ThresholdProbe(contrast: 0.3, detected: false),
        isFalse,
      );
    });

    test('is not equal to a non-ThresholdProbe object', () {
      const probe = ThresholdProbe(contrast: 0.3, detected: true);
      // ignore: unrelated_type_equality_checks
      expect(probe == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const ThresholdProbe(contrast: 0.3, detected: true).toString(),
        'ThresholdProbe(contrast: 0.3, detected: true)',
      );
    });
  });

  group('ThresholdResult', () {
    test('keeps its severity', () {
      const result = ThresholdResult(severity: 0.7);
      expect(result.severity, 0.7);
    });

    test('equal fields are == and share a hashCode', () {
      // ignore: prefer_const_constructors
      final a = ThresholdResult(severity: 0.7);
      const b = ThresholdResult(severity: 0.7);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when severity differs', () {
      expect(
        const ThresholdResult(severity: 0.7) ==
            const ThresholdResult(severity: 0.2),
        isFalse,
      );
    });

    test('is not equal to a non-ThresholdResult object', () {
      const result = ThresholdResult(severity: 0.7);
      // ignore: unrelated_type_equality_checks
      expect(result == 'x', isFalse);
    });

    test('has a readable toString', () {
      expect(
        const ThresholdResult(severity: 0.7).toString(),
        'ThresholdResult(severity: 0.7)',
      );
    });
  });
}
