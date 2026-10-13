import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/onboarding/engine/severity_band.dart';

void main() {
  group('SeverityBand', () {
    test('covers mild, moderate and strong in ascending order', () {
      expect(
        SeverityBand.values,
        <SeverityBand>[
          SeverityBand.mild,
          SeverityBand.moderate,
          SeverityBand.strong,
        ],
      );
    });

    test('label reads back the AC-11 vocabulary for each band', () {
      expect(SeverityBand.mild.label, 'mild');
      expect(SeverityBand.moderate.label, 'moderate');
      expect(SeverityBand.strong.label, 'strong');
    });

    group('forSeverity (G-4 cut-offs)', () {
      test('maps the three AC-11 anchors to the three bands', () {
        expect(SeverityBand.forSeverity(0.30), SeverityBand.mild);
        expect(SeverityBand.forSeverity(0.60), SeverityBand.moderate);
        expect(SeverityBand.forSeverity(0.90), SeverityBand.strong);
      });

      test('the cut-offs sit at the anchor midpoints, half-open going up', () {
        // mild [0, 0.45), moderate [0.45, 0.75), strong [0.75, 1.0].
        expect(SeverityBand.forSeverity(0.0), SeverityBand.mild);
        expect(SeverityBand.forSeverity(0.44), SeverityBand.mild);
        expect(SeverityBand.forSeverity(0.45), SeverityBand.moderate);
        expect(SeverityBand.forSeverity(0.74), SeverityBand.moderate);
        expect(SeverityBand.forSeverity(0.75), SeverityBand.strong);
        expect(SeverityBand.forSeverity(1.0), SeverityBand.strong);
      });

      test('is monotone and produces three distinct bands across the scale', () {
        final bands = [0.1, 0.5, 0.9].map(SeverityBand.forSeverity).toList();
        expect(bands, [
          SeverityBand.mild,
          SeverityBand.moderate,
          SeverityBand.strong,
        ]);
        expect(bands.toSet().length, 3);
      });

      test('stays total for out-of-range severities', () {
        expect(SeverityBand.forSeverity(-1), SeverityBand.mild);
        expect(SeverityBand.forSeverity(2), SeverityBand.strong);
      });
    });
  });
}
