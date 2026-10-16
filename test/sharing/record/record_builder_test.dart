import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';
import 'package:paint_color_assistant/sharing/record/record_builder.dart';

void main() {
  const builder = EvidenceRecordBuilder();

  const sample = Sample(
    coordinates: ColorCoordinates(lightness: 42, a: 3, b: -7),
    provenance: Provenance(ProvenanceTier.measured),
  );

  test('the skeleton prepares nothing (no behaviour until RECORD-2)', () {
    expect(builder.prepare(sample), isNull);
    expect(
      builder.prepare(
        sample,
        palette: const DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil'),
      ),
      isNull,
    );
  });

  test('the skeleton shares nothing (no selection until RECORD-3)', () {
    final candidate = MixAccuracyRecord(
      paintCombination: PaintCombination.of(['a']),
      declaredPalette: const DeclaredPalette(),
      measuredColour: const MeasuredColour(
        lab: ColorCoordinates(lightness: 1, a: 2, b: 3),
        lch: CielchCoordinates(lightness: 1, chroma: 2, hue: 3),
      ),
      tier: MeasurementTier.cardLess,
    );
    expect(builder.selectShareSet([candidate]), isEmpty);
    expect(builder.selectShareSet(const []), isEmpty);
  });

  test('is a RecordBuilder (the DI seam RECORD-2/3 fill in)', () {
    expect(builder, isA<RecordBuilder>());
  });
}
