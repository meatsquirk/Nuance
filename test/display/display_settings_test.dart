import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

void main() {
  group('DisplaySettings', () {
    test('defaults to the shipped view: no simulation, full severity, no '
        'grayscale', () {
      const settings = DisplaySettings();
      expect(settings.simulationType, isNull);
      expect(settings.simulationSeverity, 1.0);
      expect(settings.grayscale, isFalse);
    });

    test('keeps explicitly set fields', () {
      const settings = DisplaySettings(
        simulationType: CvdType.protan,
        simulationSeverity: 0.4,
        grayscale: true,
      );
      expect(settings.simulationType, CvdType.protan);
      expect(settings.simulationSeverity, 0.4);
      expect(settings.grayscale, isTrue);
    });

    test('simulationOn is false when no type is set', () {
      expect(const DisplaySettings().simulationOn, isFalse);
    });

    test('simulationOn is true when a type is set', () {
      expect(
        const DisplaySettings(simulationType: CvdType.deutan).simulationOn,
        isTrue,
      );
    });

    test('equal settings compare equal and share a hash code', () {
      const a = DisplaySettings(
        simulationType: CvdType.tritan,
        grayscale: true,
      );
      const b = DisplaySettings(
        simulationType: CvdType.tritan,
        grayscale: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('settings differing on any field are unequal', () {
      const base = DisplaySettings(simulationType: CvdType.deutan);
      expect(
        base,
        isNot(const DisplaySettings(simulationType: CvdType.protan)),
      );
      expect(
        base,
        isNot(
          const DisplaySettings(
            simulationType: CvdType.deutan,
            simulationSeverity: 0.5,
          ),
        ),
      );
      expect(
        base,
        isNot(
          const DisplaySettings(
            simulationType: CvdType.deutan,
            grayscale: true,
          ),
        ),
      );
      expect(base, isNot('not settings'));
    });

    test('toString names the three fields', () {
      final text = const DisplaySettings(
        simulationType: CvdType.protan,
        simulationSeverity: 0.25,
        grayscale: true,
      ).toString();
      expect(text, contains('protan'));
      expect(text, contains('0.25'));
      expect(text, contains('true'));
    });
  });
}
