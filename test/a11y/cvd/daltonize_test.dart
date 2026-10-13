import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/cvd/daltonize.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/conversions.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

/// The sRGB round-trip the Color bridge performs (srgb→lab→srgb) with no remap
/// in between, composed from the shipped conversions — what [daltonizeColor]
/// returns when [daltonize] is the identity (a severity-0 profile).
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

/// The squared a*/b* chroma distance between two CIELAB colours (the plane the
/// remap acts in; lightness is preserved so it is excluded).
double _chromaDistance(ColorCoordinates a, ColorCoordinates b) {
  final da = a.a - b.a, db = a.b - b.b;
  return da * da + db * db;
}

void main() {
  // A muted yellow-green that stays inside the sRGB gamut under every dichromat
  // projection yet shifts clearly under each — chroma for the remap to move.
  // (The same olive bs-08/bs-10 use as the observable display sample.)
  const lab = ColorCoordinates(lightness: 55, a: -25, b: 30);

  group('daltonize — error-redistribution remap (DALT-3)', () {
    test('is the identity at severity 0 for every type (no remap)', () {
      for (final type in CvdType.values) {
        expect(daltonize(lab, CvdProfile(type: type, severity: 0)), lab,
            reason: 'severity 0 is an unaffected painter — nothing to remap');
      }
    });

    test('preserves lightness for every type (a chroma-redistribution aid)', () {
      for (final type in CvdType.values) {
        final remapped = daltonize(lab, CvdProfile(type: type, severity: 0.6));
        expect(remapped.lightness, closeTo(lab.lightness, 1e-9),
            reason: '$type: daltonization redistributes chroma, not luminance');
      }
    });

    test('visibly shifts the sample for every type (the aid is observable)', () {
      for (final type in CvdType.values) {
        final remapped = daltonize(lab, CvdProfile(type: type, severity: 0.6));
        expect(_chromaDistance(lab, remapped), greaterThan(1.0),
            reason: '$type: the sample must move so the aid is observable');
      }
    });

    test('is type-specific (the three types do not all remap alike)', () {
      final byType = {
        for (final type in CvdType.values)
          type: daltonize(lab, CvdProfile(type: type, severity: 0.6)),
      };
      // At least two of the three land in different places — the remap depends
      // on which cone the projection drops (AC-1 grades per type).
      final distinct = <String>{
        for (final r in byType.values)
          '${r.a.toStringAsFixed(3)},${r.b.toStringAsFixed(3)}',
      };
      expect(distinct.length, greaterThanOrEqualTo(2),
          reason: 'protan/deutan/tritan must not all remap identically');
    });

    test('a stronger severity remaps further for every type (AC-5 control)', () {
      for (final type in CvdType.values) {
        final mild = daltonize(lab, CvdProfile(type: type, severity: 0.3));
        final strong = daltonize(lab, CvdProfile(type: type, severity: 0.9));
        expect(_chromaDistance(lab, strong),
            greaterThan(_chromaDistance(lab, mild)),
            reason: '$type: a stronger stored severity pushes it further');
      }
    });

    test('is distinct from the dichromat projection for every type (AC-7)', () {
      // Daltonization aids distinction; it must not land on the simulation
      // projection (how the painter perceives the colour).
      for (final type in CvdType.values) {
        final profile = CvdProfile(type: type, severity: 0.6);
        final remapped = daltonize(lab, profile);
        final projected = projectDichromat(lab, profile);
        expect(_chromaDistance(remapped, projected), greaterThan(1.0),
            reason: '$type: the remap differs from the perceived colour');
      }
    });

    test('leaves a neutral grey near-neutral (no chroma to redistribute)', () {
      const grey = ColorCoordinates(lightness: 50, a: 0, b: 0);
      for (final type in CvdType.values) {
        final remapped = daltonize(grey, CvdProfile(type: type, severity: 0.6));
        expect(remapped.a.abs(), lessThan(1.5), reason: '$type: grey stays grey');
        expect(remapped.b.abs(), lessThan(1.5), reason: '$type: grey stays grey');
      }
    });

    test('clamps severity above 1 to full strength', () {
      const type = CvdType.deutan;
      final atOne = daltonize(lab, const CvdProfile(type: type, severity: 1.0));
      final above = daltonize(lab, const CvdProfile(type: type, severity: 2.0));
      expect(above.a, closeTo(atOne.a, 1e-9));
      expect(above.b, closeTo(atOne.b, 1e-9));
      expect(above.lightness, closeTo(atOne.lightness, 1e-9));
    });

    test('clamps a negative severity to the identity (severity 0)', () {
      // clamp(0,1) floors a negative severity at 0 → the early-return identity.
      expect(
          daltonize(lab, const CvdProfile(type: CvdType.protan, severity: -0.5)),
          lab);
    });

    test('handles a near-black colour (sub-knee CIELAB branch)', () {
      const nearBlack = ColorCoordinates(lightness: 2, a: 1, b: 1);
      for (final type in CvdType.values) {
        final remapped =
            daltonize(nearBlack, CvdProfile(type: type, severity: 0.6));
        expect(remapped.lightness.isFinite, isTrue);
        expect(remapped.a.isFinite, isTrue);
        expect(remapped.b.isFinite, isTrue);
      }
    });
  });

  group('daltonizeColor — Color bridge', () {
    const original = Color(0xFF3AA0BF);

    test('renders a chromatic swatch shifted under the real remap', () {
      const profile = CvdProfile(type: CvdType.deutan, severity: 0.6);
      // A real remap moves the swatch beyond the sRGB round-trip rounding.
      expect(_channelDistance(daltonizeColor(original, profile), original),
          greaterThan(2),
          reason: 'the displayed swatch is remapped, not the original');
    });

    test('is the sRGB round-trip of the original at severity 0 (no remap)', () {
      const profile = CvdProfile(type: CvdType.deutan, severity: 0);
      expect(daltonizeColor(original, profile), _roundTrip(original));
    });

    test('is fully opaque', () {
      const profile = CvdProfile(type: CvdType.protan, severity: 0.6);
      expect(daltonizeColor(original, profile).a, 1.0);
    });
  });
}
