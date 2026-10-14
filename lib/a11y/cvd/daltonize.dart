import 'package:flutter/widgets.dart';

import '../../color_science/color_science.dart';
import '../../color_science/conversions.dart';
import '../../domain/color_coordinates.dart';
import 'confusion_check.dart' show projectDichromat;
import 'cvd_profile.dart';

/// Daltonizes a colour for a painter with [profile] — the display-only remap
/// that pushes confusable colours apart so the painter can tell them apart
/// (bs-10 D-1/D-2).
///
/// Pure and defined in CIELAB ([ColorCoordinates]), mirroring `projectDichromat`
/// (`confusion_check.dart`) so the two CVD transforms sit side by side behind
/// the same interface (SI D10: the CVD model stays behind an interface).
///
/// **Error-redistribution remap (DALT-3, D-2).** The painter's *full* dichromat
/// view ([projectDichromat] at severity 1) is the colour they cannot tell from
/// its confusers, so the chroma lost to that collapse — the a*/b* difference
/// between [c] and that view — is the confusion-axis error. The remap rotates
/// that lost chroma 90° in the a*/b* plane and adds it back, scaled by
/// [CvdProfile.severity], **preserving lightness**: it pushes confusable colours
/// apart (distinction) rather than collapsing them (perception), which is
/// precisely how daltonization differs from the simulation projection (AC-7).
///
/// The projection is taken at full strength (severity 1) so the *amount* of
/// collapse is the real confusion error for the painter's [CvdProfile.type]; the
/// painter's own severity then scales how much of it is redistributed, so a
/// milder deficiency remaps less (AC-5). The identity at severity 0 — an
/// unaffected painter needs no remap. Type-specific, because the lost chroma
/// depends on which cone [projectDichromat] drops (AC-1).
ColorCoordinates daltonize(ColorCoordinates c, CvdProfile profile) {
  final severity = profile.severity.clamp(0.0, 1.0);
  if (severity == 0) return c;
  // The painter's full dichromat view — the colour they cannot distinguish from
  // its confusers; the a*/b* chroma lost to that collapse is the error to
  // redistribute. Taken at full severity so the error is the true confusion,
  // not a pre-scaled one (the painter's severity scales the redistribution
  // below, not the projection — scaling both would double-count).
  final seen = projectDichromat(
    c,
    CvdProfile(type: profile.type, severity: 1.0),
  );
  final lostA = c.a - seen.a;
  final lostB = c.b - seen.b;
  // Rotate the lost chroma 90° in the a*/b* plane ((lostA, lostB) → (lostB,
  // −lostA)) and add it back, scaled by severity, lightness preserved.
  return ColorCoordinates(
    lightness: c.lightness,
    a: c.a + severity * lostB,
    b: c.b - severity * lostA,
  );
}

/// The displayed sRGB [Color] of [original] after [daltonize] for [profile] —
/// the Color-level bridge the render chokepoint calls, symmetric to
/// `simulateColor` (`color_simulation.dart`).
///
/// Reverses the sRGB swatch to CIELAB with [srgbToLab] (the inverse of the
/// readout's [labToSrgb]), remaps with [daltonize], and maps the result back
/// with [labToSrgb], so the remap is expressed in the canonical colour space
/// and shares simulation's single sRGB round-trip. With the real remap (DALT-3)
/// a chromatic swatch now displays shifted; a severity-0 profile (or a neutral
/// grey, which has no chroma to redistribute) still renders the original.
Color daltonizeColor(Color original, CvdProfile profile) {
  final lab = srgbToLab(SRGBColor(
    red: (original.r * 255).round(),
    green: (original.g * 255).round(),
    blue: (original.b * 255).round(),
  ));
  final remapped = daltonize(lab, profile);
  final srgb = labToSrgb(remapped);
  return Color.fromARGB(255, srgb.red, srgb.green, srgb.blue);
}
