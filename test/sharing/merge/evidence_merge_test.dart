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

  group('EvidenceMerge.ingest (append-only, source-tagged — AC-10)', () {
    test('appends one peer-contributed point per incoming record, tagged '
        'with its source and the record measured colour, in arrival order', () {
      const merge = EvidenceMerge();
      final existing = [_point('instrument'), _point('solver')];
      final incoming = [
        SourcedRecord(source: 'peer-1', record: _record('a')),
        SourcedRecord(source: 'peer-2', record: _record('b')),
      ];

      final merged = merge.ingest(existing, incoming);

      // The log grew by exactly the two incoming records.
      expect(merged, hasLength(existing.length + 2));
      // Prior points unchanged and still first, in order.
      expect(merged.sublist(0, existing.length), orderedEquals(existing));
      // Each appended point is peer-contributed, carries its source and the
      // record's measured colour, in arrival order.
      for (var i = 0; i < incoming.length; i++) {
        final appended = merged[existing.length + i];
        expect(appended.kind, EvidenceKind.peerContributed);
        expect(appended.source, incoming[i].source);
        expect(appended.coordinates, incoming[i].record.measuredColour.lab);
      }
    });

    test('does not dedup distinct records that share a source', () {
      const merge = EvidenceMerge();
      final incoming = [
        SourcedRecord(source: 'peer-1', record: _record('a')),
        SourcedRecord(source: 'peer-1', record: _record('b')),
      ];

      final merged = merge.ingest(const [], incoming);

      expect(merged, hasLength(2));
      expect(merged.map((p) => p.source), everyElement('peer-1'));
    });

    test('no incoming leaves the existing log unchanged', () {
      const merge = EvidenceMerge();
      final existing = [_point('instrument'), _point('solver')];
      expect(merge.ingest(existing, const []), orderedEquals(existing));
    });

    test('ingest returns an unmodifiable view', () {
      const merge = EvidenceMerge();
      final merged = merge.ingest([_point('x')], const []);
      expect(() => merged.add(_point('y')), throwsUnsupportedError);
    });

    test('ingest of empty existing with no incoming is empty', () {
      const merge = EvidenceMerge();
      expect(merge.ingest(const [], const []), isEmpty);
      expect(merge.derivation, isNotNull);
    });
  });
}
