import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/record/content_hash.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

void main() {
  group('PaintCombination', () {
    test('of() trims blanks, deduplicates and sorts into canonical order', () {
      final combo = PaintCombination.of(['b', 'a', '', '  ', 'a', ' c ']);
      expect(combo.paintIds, ['a', 'b', 'c']);
      expect(combo.canonical, 'a,b,c');
    });

    test('of() yields an empty combination from only-blank input', () {
      final combo = PaintCombination.of(['', '   ']);
      expect(combo.paintIds, isEmpty);
      expect(combo.canonical, '');
      expect(combo.toString(), contains('∅'));
    });

    test('value equality and hashCode compare the sorted ids', () {
      final a = PaintCombination.of(['x', 'y']);
      final b = PaintCombination.of(['y', 'x']);
      final c = PaintCombination.of(['x', 'z']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      final Object notACombo = 'x,y';
      expect(a == notACombo, isFalse);
    });

    test('toString lists the canonical ids', () {
      expect(PaintCombination.of(['a', 'b']).toString(), contains('a,b'));
    });
  });

  group('DeclaredPalette', () {
    const full = DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil');

    test('isPresent is true only when brand, line and medium are all set', () {
      expect(full.isPresent, isTrue);
      expect(const DeclaredPalette().isPresent, isFalse);
      expect(
        const DeclaredPalette(brand: '', line: 'Pro', medium: 'oil').isPresent,
        isFalse,
      );
      expect(
        const DeclaredPalette(brand: 'WN', line: ' ', medium: 'oil').isPresent,
        isFalse,
      );
      expect(
        const DeclaredPalette(brand: 'WN', line: 'Pro', medium: '').isPresent,
        isFalse,
      );
    });

    test('canonical joins the three parts', () {
      expect(full.canonical, 'WN|Pro|oil');
    });

    test('value equality, hashCode and toString', () {
      const same = DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil');
      const brandDiff = DeclaredPalette(brand: 'X', line: 'Pro', medium: 'oil');
      const lineDiff = DeclaredPalette(brand: 'WN', line: 'X', medium: 'oil');
      const mediumDiff = DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'x');
      expect(full, same);
      expect(full.hashCode, same.hashCode);
      expect(full, isNot(brandDiff));
      expect(full, isNot(lineDiff));
      expect(full, isNot(mediumDiff));
      final Object notAPalette = 'WN|Pro|oil';
      expect(full == notAPalette, isFalse);
      expect(full.toString(), contains('WN|Pro|oil'));
    });
  });

  group('CielchCoordinates', () {
    const base = CielchCoordinates(lightness: 50, chroma: 20, hue: 120);

    test('value equality, hashCode and toString', () {
      const same = CielchCoordinates(lightness: 50, chroma: 20, hue: 120);
      const lDiff = CielchCoordinates(lightness: 51, chroma: 20, hue: 120);
      const cDiff = CielchCoordinates(lightness: 50, chroma: 21, hue: 120);
      const hDiff = CielchCoordinates(lightness: 50, chroma: 20, hue: 121);
      expect(base, same);
      expect(base.hashCode, same.hashCode);
      expect(base, isNot(lDiff));
      expect(base, isNot(cDiff));
      expect(base, isNot(hDiff));
      final Object notLch = 'nope';
      expect(base == notLch, isFalse);
      expect(base.toString(), contains('C 20'));
    });
  });

  group('MeasuredColour', () {
    const lab = ColorCoordinates(lightness: 50, a: 10, b: -5);
    const lch = CielchCoordinates(lightness: 50, chroma: 11.18, hue: 333.43);
    const colour = MeasuredColour(lab: lab, lch: lch);

    test('value equality, hashCode and toString', () {
      const same = MeasuredColour(lab: lab, lch: lch);
      const labDiff = MeasuredColour(
        lab: ColorCoordinates(lightness: 51, a: 10, b: -5),
        lch: lch,
      );
      const lchDiff = MeasuredColour(
        lab: lab,
        lch: CielchCoordinates(lightness: 51, chroma: 11.18, hue: 333.43),
      );
      expect(colour, same);
      expect(colour.hashCode, same.hashCode);
      expect(colour, isNot(labDiff));
      expect(colour, isNot(lchDiff));
      final Object notColour = 'nope';
      expect(colour == notColour, isFalse);
      expect(colour.toString(), contains('ColorCoordinates'));
    });
  });

  group('MeasurementTier.fromEvidenceKind', () {
    test('instrument-measured maps to the instrument tier', () {
      expect(
        MeasurementTier.fromEvidenceKind(EvidenceKind.instrumentMeasured),
        MeasurementTier.instrument,
      );
    });

    test('a photographed swatch maps to the reference-card tier', () {
      expect(
        MeasurementTier.fromEvidenceKind(EvidenceKind.photographedSwatch),
        MeasurementTier.referenceCard,
      );
    });

    test('every lower-confidence origin maps to the card-less floor', () {
      for (final kind in const [
        EvidenceKind.solverCalculated,
        EvidenceKind.llmSeed,
        EvidenceKind.opinion,
      ]) {
        expect(
          MeasurementTier.fromEvidenceKind(kind),
          MeasurementTier.cardLess,
        );
      }
    });
  });

  group('MixAccuracyRecord', () {
    MixAccuracyRecord record({
      PaintCombination? combination,
      DeclaredPalette palette =
          const DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil'),
      MeasuredColour? colour,
      MeasurementTier tier = MeasurementTier.instrument,
    }) =>
        MixAccuracyRecord(
          paintCombination: combination ?? PaintCombination.of(['a', 'b']),
          declaredPalette: palette,
          measuredColour: colour ??
              const MeasuredColour(
                lab: ColorCoordinates(lightness: 50, a: 10, b: -5),
                lch: CielchCoordinates(lightness: 50, chroma: 11.18, hue: 333.4),
              ),
          tier: tier,
        );

    test('canonicalForm joins the fields with rounded coordinates', () {
      expect(
        record().canonicalForm,
        'a,b;WN|Pro|oil;lab:50.00,10.00,-5.00;lch:50.00,11.18,333.40;'
        'tier:instrument',
      );
    });

    test('canonicalForm folds negative-zero coordinates to 0.00', () {
      final r = record(
        colour: const MeasuredColour(
          lab: ColorCoordinates(lightness: 0, a: -0.004, b: 0),
          lch: CielchCoordinates(lightness: 0, chroma: 0, hue: 0),
        ),
      );
      expect(r.canonicalForm, contains('lab:0.00,0.00,0.00'));
      expect(r.canonicalForm, isNot(contains('-0.00')));
    });

    test('contentHash is the hash of the canonical form', () {
      final r = record();
      expect(r.contentHash, contentHashOf(r.canonicalForm));
    });

    test('byte-identical records collapse; distinct ones differ (D-7)', () {
      expect(record().contentHash, record().contentHash);
      expect(
        record().contentHash,
        isNot(record(tier: MeasurementTier.cardLess).contentHash),
      );
    });

    test('value equality across all four fields', () {
      final base = record();
      expect(base, record());
      expect(base.hashCode, record().hashCode);
      expect(
        base,
        isNot(record(combination: PaintCombination.of(['a', 'c']))),
      );
      expect(
        base,
        isNot(record(palette: const DeclaredPalette())),
      );
      expect(
        base,
        isNot(record(
          colour: const MeasuredColour(
            lab: ColorCoordinates(lightness: 99, a: 0, b: 0),
            lch: CielchCoordinates(lightness: 99, chroma: 0, hue: 0),
          ),
        )),
      );
      expect(base, isNot(record(tier: MeasurementTier.cardLess)));
      final Object notARecord = 'not a record';
      expect(base == notARecord, isFalse);
    });

    test('toString names the combination, palette and tier', () {
      final s = record().toString();
      expect(s, contains('a,b'));
      expect(s, contains('WN|Pro|oil'));
      expect(s, contains('instrument'));
    });
  });

  test('the value types are runtime-constructible from live measurements', () {
    // The record builder constructs these at runtime from a confirmed mix, not
    // as compile-time constants; build them from non-const locals so the
    // constructors actually execute.
    final brand = ['W', 'N'].join();
    final palette = DeclaredPalette(brand: brand, line: 'Pro', medium: 'oil');
    expect(palette.brand, 'WN');

    final hue = <double>[333.4].first;
    final lch = CielchCoordinates(lightness: 50, chroma: 11.18, hue: hue);
    expect(lch.hue, 333.4);

    final colour = MeasuredColour(
      lab: const ColorCoordinates(lightness: 50, a: 10, b: -5),
      lch: lch,
    );
    expect(colour.lab.a, 10);
  });
}
