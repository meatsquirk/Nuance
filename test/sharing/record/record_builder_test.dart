import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';
import 'package:paint_color_assistant/sharing/record/record_builder.dart';

void main() {
  const builder = EvidenceRecordBuilder();
  const colorScience = ColorScienceImpl();
  const palette = DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil');
  const lab = ColorCoordinates(lightness: 42, a: 3, b: -7);

  Sample mix({
    List<String> paintIds = const ['b-paint', 'a-paint'],
    List<EvidencePoint> evidence = const <EvidencePoint>[
      EvidencePoint(
        coordinates: lab,
        source: 'own-swatch',
        kind: EvidenceKind.photographedSwatch,
      ),
    ],
  }) =>
      Sample(
        coordinates: lab,
        provenance: const Provenance(ProvenanceTier.confirmed),
        name: 'my private mix',
        paintIds: paintIds,
        evidence: evidence,
      );

  group('prepare (RECORD-2)', () {
    test('builds a record carrying exactly the four fields (AC-3)', () {
      final record = builder.prepare(mix(), palette: palette)!;

      // Paint combination: the sample's recipe, canonicalised (sorted, deduped).
      expect(record.paintCombination, PaintCombination.of(['b-paint', 'a-paint']));
      expect(record.paintCombination.paintIds, orderedEquals(['a-paint', 'b-paint']));
      // Declared palette: carried verbatim.
      expect(record.declaredPalette, palette);
      // Measured colour: the sample's CIELAB verbatim, CIELCh from the real engine.
      expect(record.measuredColour.lab, lab);
      final CIELCh expected = colorScience.toCIELCh(lab);
      expect(record.measuredColour.lch.lightness, closeTo(expected.lightness, 1e-9));
      expect(record.measuredColour.lch.chroma, closeTo(expected.chroma, 1e-9));
      expect(record.measuredColour.lch.hue, closeTo(expected.hue, 1e-9));
      // Tier: from the own-swatch photograph (card-calibrated ⇒ referenceCard).
      expect(record.tier, MeasurementTier.referenceCard);
    });

    test('carries nothing personal from the source mix (AC-4)', () {
      final crossing = builder.prepare(mix(), palette: palette)!.canonicalForm;
      expect(crossing, isNot(contains('my private mix')));
      expect(crossing, isNot(contains('own-swatch')));
      expect(crossing, contains('WN'));
    });

    test('returns null when the sample declares no paints (no mix to share)', () {
      expect(builder.prepare(mix(paintIds: const <String>[]), palette: palette),
          isNull);
      // Blank ids normalise away, so they are no mix either.
      expect(builder.prepare(mix(paintIds: const <String>['', '  ']),
          palette: palette),
          isNull);
    });

    test('carries an absent declared palette when none is given', () {
      final record = builder.prepare(mix())!;
      expect(record.declaredPalette, const DeclaredPalette());
      expect(record.declaredPalette.isPresent, isFalse);
    });

    group('measurement tier is the strongest evidence tier', () {
      test('instrument reading outranks a weaker point in the same sample', () {
        final record = builder.prepare(
          mix(evidence: const <EvidencePoint>[
            EvidencePoint(
                coordinates: lab, source: 's', kind: EvidenceKind.opinion),
            EvidencePoint(
                coordinates: lab,
                source: 'spectro',
                kind: EvidenceKind.instrumentMeasured),
          ]),
          palette: palette,
        )!;
        expect(record.tier, MeasurementTier.instrument);
      });

      test('a weaker point after a stronger one does not demote the tier', () {
        final record = builder.prepare(
          mix(evidence: const <EvidencePoint>[
            EvidencePoint(
                coordinates: lab,
                source: 'spectro',
                kind: EvidenceKind.instrumentMeasured),
            EvidencePoint(
                coordinates: lab, source: 's', kind: EvidenceKind.opinion),
          ]),
          palette: palette,
        )!;
        expect(record.tier, MeasurementTier.instrument);
      });

      test('no evidence falls to the conservative card-less floor', () {
        final record =
            builder.prepare(mix(evidence: const <EvidencePoint>[]), palette: palette)!;
        expect(record.tier, MeasurementTier.cardLess);
      });
    });
  });

  group('selectShareSet (RECORD-3, AC-5)', () {
    MixAccuracyRecord recordWith(DeclaredPalette declaredPalette) =>
        MixAccuracyRecord(
          paintCombination: PaintCombination.of(['a']),
          declaredPalette: declaredPalette,
          measuredColour: const MeasuredColour(
            lab: ColorCoordinates(lightness: 1, a: 2, b: 3),
            lch: CielchCoordinates(lightness: 1, chroma: 2, hue: 3),
          ),
          tier: MeasurementTier.cardLess,
        );

    test('excludes a candidate whose declared palette is absent', () {
      final interpretable = recordWith(palette);
      final noPalette = recordWith(const DeclaredPalette());
      expect(noPalette.declaredPalette.isPresent, isFalse);

      final shared = builder.selectShareSet([interpretable, noPalette]);

      expect(shared, contains(interpretable));
      expect(shared, isNot(contains(noPalette)));
    });

    test('keeps every interpretable candidate, in order', () {
      final first = recordWith(palette);
      final second = recordWith(
          const DeclaredPalette(brand: 'DS', line: 'Artist', medium: 'water'));
      expect(builder.selectShareSet([first, second]),
          orderedEquals(<MixAccuracyRecord>[first, second]));
    });

    test('an empty candidate set shares nothing', () {
      expect(builder.selectShareSet(const <MixAccuracyRecord>[]), isEmpty);
    });

    test('names why a no-palette record is dropped', () {
      expect(EvidenceRecordBuilder.noPaletteExclusionReason,
          'not interpretable — no declared palette');
    });
  });

  test('is a RecordBuilder (the DI seam the CORE scope wires)', () {
    expect(builder, isA<RecordBuilder>());
  });

  test('defaults to the real colour engine when none is injected', () {
    // Built at runtime (non-const) so the default `const ColorScienceImpl()`
    // expression actually executes — and the record it prepares carries a CIELCh
    // matching that real engine, proving the default is wired, not a stub.
    // ignore: prefer_const_constructors
    final defaulted = EvidenceRecordBuilder();
    final record = defaulted.prepare(mix(), palette: palette)!;
    final CIELCh expected = colorScience.toCIELCh(lab);
    expect(record.measuredColour.lch.lightness, closeTo(expected.lightness, 1e-9));
    expect(record.measuredColour.lch.chroma, closeTo(expected.chroma, 1e-9));
    expect(record.measuredColour.lch.hue, closeTo(expected.hue, 1e-9));
  });
}
