import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/conversions.dart';
import 'package:paint_color_assistant/display/color_simulation.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

/// The displayed sRGB [Color] of a projected CIELAB colour — the same back
/// conversion the readout uses, so the expectation composes the shipped pieces
/// (this is the chokepoint's own wiring; the acceptance test grades the result
/// against an independent projection, AC-3).
Color _project(Color original, CvdType type, {double severity = 1.0}) {
  final lab = srgbToLab(SRGBColor(
    red: (original.r * 255).round(),
    green: (original.g * 255).round(),
    blue: (original.b * 255).round(),
  ));
  final out =
      labToSrgb(projectDichromat(lab, CvdProfile(type: type, severity: severity)));
  return Color.fromARGB(255, out.red, out.green, out.blue);
}

void main() {
  // A saturated cyan-blue: shifted a clear distance by every one of the three
  // dichromacies (red-green for protan/deutan, blue-yellow for tritan), so the
  // "projection actually moves the colour" control below holds for each type.
  const original = Color(0xFF3AA0BF);

  group('simulateColor — identity (simulation off, AC-2)', () {
    test('returns the original colour when no simulation type is set', () {
      expect(simulateColor(original, const DisplaySettings()), original);
    });

    test('a severity set while the type is off still leaves the colour '
        'untouched (off is defined by the null type)', () {
      expect(
        simulateColor(original, const DisplaySettings(simulationSeverity: 0.5)),
        original,
      );
    });
  });

  group('simulateColor — projection (simulation on, AC-3)', () {
    for (final type in CvdType.values) {
      test('projects through the shipped projectDichromat for $type', () {
        final settings = DisplaySettings(simulationType: type);
        final simulated = simulateColor(original, settings);
        // Composes srgb→lab → projectDichromat → lab→srgb with the chosen type
        // at full severity (the CvdProfile default this DisplaySettings carries).
        expect(simulated, _project(original, type));
        // Control: the projection actually shifts this colour — a stubbed
        // identity (ignoring the type) would fail here.
        expect(simulated, isNot(original),
            reason: '$type projection shifts this saturated colour');
      });
    }

    test('uses the settings severity (severity 0 collapses to the original)',
        () {
      // Severity 0: projectDichromat blends 0 of the way to the dichromat
      // projection, so the displayed colour is the original (within the sRGB
      // round-trip). Proves the severity is read, not hard-coded to 1.
      final simulated = simulateColor(
        original,
        const DisplaySettings(
            simulationType: CvdType.deutan, simulationSeverity: 0),
      );
      expect(simulated, _project(original, CvdType.deutan, severity: 0));
      expect(_channelDistance(simulated, original), lessThanOrEqualTo(2),
          reason: 'severity 0 renders the unaffected original');
    });

    test('severity scales the shift (half is nearer the original than full)',
        () {
      final half = simulateColor(
        original,
        const DisplaySettings(
            simulationType: CvdType.deutan, simulationSeverity: 0.5),
      );
      final full = simulateColor(
        original,
        const DisplaySettings(simulationType: CvdType.deutan),
      );
      expect(_channelDistance(half, original),
          lessThan(_channelDistance(full, original)),
          reason: 'a weaker severity sits closer to the true colour');
    });
  });
}

/// Summed absolute 8-bit channel distance between two opaque colours.
int _channelDistance(Color a, Color b) =>
    ((a.r - b.r).abs() * 255 +
            (a.g - b.g).abs() * 255 +
            (a.b - b.b).abs() * 255)
        .round();
