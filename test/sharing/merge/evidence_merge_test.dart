import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/sharing/merge/evidence_merge.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

MixAccuracyRecord _record(String id) => MixAccuracyRecord(
      paintCombination: PaintCombination.of([id]),
      declaredPalette:
          const DeclaredPalette(brand: 'WN', line: 'Pro', medium: 'oil'),
      measuredColour: const MeasuredColour(
        lab: ColorCoordinates(lightness: 50, a: 10, b: -5),
        lch: CielchCoordinates(lightness: 50, chroma: 11.18, hue: 333.4),
      ),
      tier: MeasurementTier.instrument,
    );

EvidencePoint _point(String source) => EvidencePoint(
      coordinates: const ColorCoordinates(lightness: 40, a: 1, b: 2),
      source: source,
      kind: EvidenceKind.llmSeed,
    );

void main() {
  group('SourcedRecord', () {
    test('carries its source and record', () {
      final record = _record('a');
      final sourced = SourcedRecord(source: 'peer-1', record: record);
      expect(sourced.source, 'peer-1');
      expect(sourced.record, record);
    });

    test('is value-equal and hashes by source and record', () {
      final a = SourcedRecord(source: 'peer-1', record: _record('a'));
      final sameAsA = SourcedRecord(source: 'peer-1', record: _record('a'));
      final sourceChanged =
          SourcedRecord(source: 'peer-2', record: _record('a'));
      final recordChanged =
          SourcedRecord(source: 'peer-1', record: _record('b'));
      expect(a, sameAsA);
      expect(a.hashCode, sameAsA.hashCode);
      expect(a, isNot(sourceChanged));
      expect(a, isNot(recordChanged));
      expect(a, isNot('not a SourcedRecord'));
    });

    test('toString names its source and record', () {
      final sourced = SourcedRecord(source: 'peer-1', record: _record('a'));
      expect(sourced.toString(), contains('peer-1'));
      expect(sourced.toString(), startsWith('SourcedRecord('));
    });
  });

  group('EvidenceMerge (shell)', () {
    test('ingest appends nothing — returns the existing evidence unchanged', () {
      final merge = EvidenceMerge();
      final existing = [_point('instrument'), _point('solver')];
      final incoming = [
        SourcedRecord(source: 'peer-1', record: _record('a')),
        SourcedRecord(source: 'peer-2', record: _record('b')),
      ];

      final merged = merge.ingest(existing, incoming);

      expect(merged, equals(existing));
      expect(merge.derivation, isNotNull);
    });

    test('ingest returns an unmodifiable view', () {
      final merge = EvidenceMerge();
      final merged = merge.ingest([_point('x')], const []);
      expect(() => merged.add(_point('y')), throwsUnsupportedError);
    });

    test('ingest of empty existing with no incoming is empty', () {
      final merge = EvidenceMerge();
      expect(merge.ingest(const [], const []), isEmpty);
    });
  });
}
