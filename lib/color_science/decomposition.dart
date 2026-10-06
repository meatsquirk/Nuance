import 'dart:math' as math;

import '../domain/sample.dart';
import 'naming.dart';
import 'words.dart';

/// The spoken relational decomposition of a sample's readout — the COLOR-3
/// enabler behind [ColorScience.decompose] (consumed by AC-8 via A11Y-2).
///
/// Produces one plain-language statement naming every component AC-8 requires:
/// the name, the value (lightness), the temperature word, the hue in words, the
/// chroma and the hue angle. The chroma and hue angle are derived here straight
/// from canonical CIELAB (C\* = √(a\*²+b\*²), hue = atan2(b\*, a\*)), so the
/// decomposition does not depend on the separate conversions enabler (COLOR-2).
///
/// The statement is reused unchanged by bs-03's comparison decomposition later,
/// so it is kept a pure function of the sample.

/// A spoken statement decomposing [sample]'s readout into words.
///
/// The name is the sample's own name when it has one, else the nearest
/// catalogue name ([nearestColorName]) — so an unnamed reading still speaks a
/// name. A (near-)achromatic sample has no meaningful hue or temperature, so it
/// is spoken as a neutral grey; otherwise the statement gives the temperature
/// word, the hue family, the chroma and the hue angle.
String decompose(Sample sample) {
  final c = sample.coordinates;
  final name = sample.name ?? nearestColorName(c);
  final value = c.lightness.round();
  final chroma = _chroma(c.a, c.b).round();

  if (chroma == 0) {
    return '$name: a neutral grey. Value $value, chroma 0.';
  }

  final hue = _hueAngleDeg(c.a, c.b);
  final temperature = temperatureWord(hue);
  final family = hueFamilyWord(hue);
  final angle = hue.round();
  return '$name: a $temperature $family. '
      'Value $value, chroma $chroma, hue angle $angle degrees.';
}

/// CIELAB chroma C\* = √(a\*² + b\*²).
double _chroma(double a, double b) => math.sqrt(a * a + b * b);

/// The CIELAB hue angle (degrees, 0–360) = atan2(b\*, a\*).
double _hueAngleDeg(double a, double b) {
  final deg = math.atan2(b, a) * 180.0 / math.pi;
  return deg < 0 ? deg + 360.0 : deg;
}
