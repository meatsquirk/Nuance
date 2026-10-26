import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

void main() {
  group('DisplaySettings', () {
    test('defaults to the shipped view: no simulation, full severity, no '
        'grayscale, no daltonization, no accessibility features', () {
      const settings = DisplaySettings();
      expect(settings.simulationType, isNull);
      expect(settings.simulationSeverity, 1.0);
      expect(settings.grayscale, isFalse);
      expect(settings.daltonization, isFalse);
      expect(settings.accessibilityFeatures, isFalse);
    });

    test('keeps explicitly set fields', () {
      const settings = DisplaySettings(
        simulationType: CvdType.protan,
        simulationSeverity: 0.4,
        grayscale: true,
        daltonization: true,
        accessibilityFeatures: true,
      );
      expect(settings.simulationType, CvdType.protan);
      expect(settings.simulationSeverity, 0.4);
      expect(settings.grayscale, isTrue);
      expect(settings.daltonization, isTrue);
      expect(settings.accessibilityFeatures, isTrue);
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
      expect(
        base,
        isNot(
          const DisplaySettings(
            simulationType: CvdType.deutan,
            daltonization: true,
          ),
        ),
        reason: 'daltonization is part of settings identity',
      );
      expect(
        base,
        isNot(
          const DisplaySettings(
            simulationType: CvdType.deutan,
            accessibilityFeatures: true,
          ),
        ),
        reason: 'accessibilityFeatures is part of settings identity',
      );
      expect(base, isNot('not settings'));
    });

    test('daltonization is part of equality and hashing', () {
      const off = DisplaySettings(simulationType: CvdType.deutan);
      const on = DisplaySettings(
        simulationType: CvdType.deutan,
        daltonization: true,
      );
      // Differs from an otherwise-identical settings with daltonization off.
      expect(on, isNot(off));
      // Two equal daltonization-on settings share a hash (the field is hashed).
      const onAgain = DisplaySettings(
        simulationType: CvdType.deutan,
        daltonization: true,
      );
      expect(on, equals(onAgain));
      expect(on.hashCode, onAgain.hashCode);
    });

    test('accessibilityFeatures is part of equality and hashing', () {
      const off = DisplaySettings(simulationType: CvdType.deutan);
      const on = DisplaySettings(
        simulationType: CvdType.deutan,
        accessibilityFeatures: true,
      );
      // Differs from an otherwise-identical settings with the flag off.
      expect(on, isNot(off));
      // Two equal flag-on settings share a hash (the field is hashed).
      const onAgain = DisplaySettings(
        simulationType: CvdType.deutan,
        accessibilityFeatures: true,
      );
      expect(on, equals(onAgain));
      expect(on.hashCode, onAgain.hashCode);
    });

    test('toString names the five fields', () {
      final text = const DisplaySettings(
        simulationType: CvdType.protan,
        simulationSeverity: 0.25,
        grayscale: true,
        daltonization: true,
        accessibilityFeatures: true,
      ).toString();
      expect(text, contains('protan'));
      expect(text, contains('0.25'));
      expect(text, contains('grayscale: true'));
      expect(text, contains('daltonization: true'));
      expect(text, contains('accessibilityFeatures: true'));
    });
  });
}
