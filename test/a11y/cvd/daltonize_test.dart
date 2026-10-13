import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/cvd/daltonize.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/conversions.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

/// The sRGB round-trip the Color bridge performs (srgb→lab→srgb) with no remap
/// in between — what [daltonizeColor] must return while [daltonize] is the
/// identity (DALT-2), composed here from the shipped conversions.
Color _roundTrip(Color original) {
  final lab = srgbToLab(SRGBColor(
    red: (original.r * 255).round(),
    green: (original.g * 255).round(),
    blue: (original.b * 255).round(),
  ));
  final out = labToSrgb(lab);
  return Color.fromARGB(255, out.red, out.green, out.blue);
}

/// Summed absolute 8-bit channel distance between two opaque colours.
int _channelDistance(Color a, Color b) =>
    ((a.r - b.r).abs() * 255 +
            (a.g - b.g).abs() * 255 +
            (a.b - b.b).abs() * 255)
        .round();

void main() {
  group('daltonize — identity remap (DALT-2 shell)', () {
    // A saturated cyan-blue, well inside the sRGB gamut, so the round-trip is
    // stable; the three dichromacies give three profiles to prove the stub
    // ignores the profile (identity) for now.
    const lab = ColorCoordinates(lightness: 60, a: -20, b: -30);

    for (final type in CvdType.values) {
      test('returns the coordinates unchanged for $type', () {
        final profile = CvdProfile(type: type, severity: 0.7);
        expect(daltonize(lab, profile), lab,
            reason: 'the shell remap is the identity until DALT-3');
      });
    }

    test('ignores severity (identity at any strength)', () {
      const profile = CvdProfile(type: CvdType.protan, severity: 0.25);
      expect(daltonize(lab, profile), lab);
    });
  });

  group('daltonizeColor — Color bridge', () {
    const original = Color(0xFF3AA0BF);
    const profile = CvdProfile(type: CvdType.deutan);

    test('returns the sRGB round-trip of the original (identity remap)', () {
      expect(daltonizeColor(original, profile), _roundTrip(original));
    });

    test('leaves the colour effectively unchanged (within the round-trip)', () {
      expect(_channelDistance(daltonizeColor(original, profile), original),
          lessThanOrEqualTo(2),
          reason: 'an identity remap renders the true colour (the 8-bit '
              'round-trip may drift by at most a step)');
    });
  });
}
