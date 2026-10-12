import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/color_simulation.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

void main() {
  group('simulateColor (shell: inert identity)', () {
    const original = Color(0xFFBF5B3A);

    test('returns the original colour when simulation is off', () {
      expect(simulateColor(original, const DisplaySettings()), original);
    });

    test('returns the original colour even when a type is set (DISPLAY-4 '
        'formalises the projection)', () {
      expect(
        simulateColor(
          original,
          const DisplaySettings(
            simulationType: CvdType.deutan,
            simulationSeverity: 0.5,
          ),
        ),
        original,
      );
    });
  });
}
