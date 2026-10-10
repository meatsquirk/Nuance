import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';

const _white = Paint(
  id: 'tw',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
);
const _ochre = Paint(
  id: 'yo',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 48),
);

void main() {
  group('Difference', () {
    const base = Difference(
      deltaE00: 6,
      verdict: 'noticeably off',
      valueReading: 'too dark by 6',
      hueReading: 'shifted toward green',
      withinTolerance: false,
    );

    test('carries its readings', () {
      expect(base.deltaE00, 6);
      expect(base.verdict, 'noticeably off');
      expect(base.valueReading, 'too dark by 6');
      expect(base.hueReading, 'shifted toward green');
      expect(base.withinTolerance, isFalse);
    });

    test('equal when every field matches; unequal per field', () {
      expect(
        base,
        equals(const Difference(
          deltaE00: 6,
          verdict: 'noticeably off',
          valueReading: 'too dark by 6',
          hueReading: 'shifted toward green',
          withinTolerance: false,
        )),
      );
      expect(base.hashCode,
          equals(const Difference(
            deltaE00: 6,
            verdict: 'noticeably off',
            valueReading: 'too dark by 6',
            hueReading: 'shifted toward green',
            withinTolerance: false,
          ).hashCode));
      expect(
          base,
          isNot(equals(const Difference(
            deltaE00: 7,
            verdict: 'noticeably off',
            valueReading: 'too dark by 6',
            hueReading: 'shifted toward green',
            withinTolerance: false,
          ))));
      expect(
          base,
          isNot(equals(const Difference(
            deltaE00: 6,
            verdict: 'very close',
            valueReading: 'too dark by 6',
            hueReading: 'shifted toward green',
            withinTolerance: false,
          ))));
      expect(
          base,
          isNot(equals(const Difference(
            deltaE00: 6,
            verdict: 'noticeably off',
            valueReading: 'too light by 2',
            hueReading: 'shifted toward green',
            withinTolerance: false,
          ))));
      expect(
          base,
          isNot(equals(const Difference(
            deltaE00: 6,
            verdict: 'noticeably off',
            valueReading: 'too dark by 6',
            hueReading: 'shifted toward red',
            withinTolerance: false,
          ))));
      expect(
          base,
          isNot(equals(const Difference(
            deltaE00: 6,
            verdict: 'noticeably off',
            valueReading: 'too dark by 6',
            hueReading: 'shifted toward green',
            withinTolerance: true,
          ))));
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });

    test('toString reports the readings, flagging within tolerance', () {
      expect(
        base.toString(),
        'Difference(ΔE00 6.0, noticeably off, '
        'too dark by 6 / shifted toward green)',
      );
      expect(
        const Difference(
          deltaE00: 1,
          verdict: 'very close',
          valueReading: 'spot on for value',
          hueReading: 'no hue shift',
          withinTolerance: true,
        ).toString(),
        'Difference(ΔE00 1.0, very close, '
        'spot on for value / no hue shift, within tolerance)',
      );
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(
        Difference(
          deltaE00: 0,
          verdict: '',
          valueReading: '',
          hueReading: '',
          withinTolerance: false,
        ),
        isA<Difference>(),
      );
    });
  });

  group('CorrectionAddition', () {
    const base = CorrectionAddition(paint: _white, parts: 0.5);

    test('defaults isTrace false and no note', () {
      expect(base.paint, _white);
      expect(base.parts, 0.5);
      expect(base.isTrace, isFalse);
      expect(base.techniqueNote, isNull);
    });

    test('equal when every field matches; unequal per field', () {
      expect(base, equals(const CorrectionAddition(paint: _white, parts: 0.5)));
      expect(base.hashCode,
          equals(const CorrectionAddition(paint: _white, parts: 0.5).hashCode));
      expect(base,
          isNot(equals(const CorrectionAddition(paint: _ochre, parts: 0.5))));
      expect(base,
          isNot(equals(const CorrectionAddition(paint: _white, parts: 0.25))));
      expect(
          base,
          isNot(equals(const CorrectionAddition(
              paint: _white, parts: 0.5, isTrace: true))));
      expect(
          base,
          isNot(equals(const CorrectionAddition(
              paint: _white, parts: 0.5, techniqueNote: 'add slowly'))));
      // ignore: unrelated_type_equality_checks
      expect(base == 'nope', isFalse);
    });

    test('toString names the paint and flags a trace', () {
      expect(base.toString(), 'CorrectionAddition(Titanium White 0.5)');
      expect(
        const CorrectionAddition(paint: _ochre, parts: 0.01, isTrace: true)
            .toString(),
        'CorrectionAddition(Yellow Ochre 0.01, trace)',
      );
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(CorrectionAddition(paint: _white, parts: 0.5),
          isA<CorrectionAddition>());
    });
  });

  group('Correction', () {
    const addition = CorrectionAddition(paint: _white, parts: 0.5);

    test('empty by default', () {
      expect(const Correction().isEmpty, isTrue);
      expect(const Correction().additions, isEmpty);
    });

    test('not empty when it carries additions', () {
      const correction = Correction(additions: [addition]);
      expect(correction.isEmpty, isFalse);
      expect(correction.additions, [addition]);
    });

    test('equal when the additions match; unequal otherwise', () {
      expect(const Correction(additions: [addition]),
          equals(const Correction(additions: [addition])));
      expect(const Correction(additions: [addition]).hashCode,
          equals(const Correction(additions: [addition]).hashCode));
      expect(const Correction(additions: [addition]),
          isNot(equals(const Correction())));
      expect(
        const Correction(additions: [addition]),
        isNot(equals(const Correction(
            additions: [CorrectionAddition(paint: _ochre, parts: 0.5)]))),
      );
      // ignore: unrelated_type_equality_checks
      expect(const Correction() == 'nope', isFalse);
    });

    test('toString reports the addition count', () {
      expect(const Correction().toString(), 'Correction(0 additions)');
      expect(const Correction(additions: [addition]).toString(),
          'Correction(1 additions)');
    });

    test('constructs at runtime (covers the const constructor line)', () {
      // ignore: prefer_const_constructors
      expect(Correction(), isA<Correction>());
    });
  });
}
