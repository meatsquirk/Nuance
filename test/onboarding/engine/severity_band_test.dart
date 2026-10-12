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
  });
}
