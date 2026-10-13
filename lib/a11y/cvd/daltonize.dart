import 'package:flutter/widgets.dart';

import '../../color_science/color_science.dart';
import '../../color_science/conversions.dart';
import '../../domain/color_coordinates.dart';
import 'cvd_profile.dart';

/// Daltonizes a colour for a painter with [profile] — the display-only remap
/// that pushes confusable colours apart so the painter can tell them apart
/// (bs-10 D-1/D-2).
///
/// Pure and defined in CIELAB ([ColorCoordinates]), mirroring `projectDichromat`
/// (`confusion_check.dart`) so the two CVD transforms sit side by side behind
/// the same interface (SI D10: the CVD model stays behind an interface).
///
/// **Identity in this shell (DALT-2)** — it returns [c] unchanged. DALT-3
/// replaces the body with the real error-redistribution remap over
/// `projectDichromat`, scaled by [CvdProfile.severity]; everything downstream
/// (the [daltonizeColor] bridge, the `ColorChip` display chokepoint, the read
/// endpoint) is wired now so DALT-3 changes only this body, never its callers.
ColorCoordinates daltonize(ColorCoordinates c, CvdProfile profile) => c;

/// The displayed sRGB [Color] of [original] after [daltonize] for [profile] —
/// the Color-level bridge the render chokepoint calls, symmetric to
/// `simulateColor` (`color_simulation.dart`).
///
/// Reverses the sRGB swatch to CIELAB with [srgbToLab] (the inverse of the
/// readout's [labToSrgb]), remaps with [daltonize], and maps the result back
/// with [labToSrgb], so the remap is expressed in the canonical colour space
/// and shares simulation's single sRGB round-trip. Identity while [daltonize]
/// is (DALT-2), so the displayed swatch equals [original] for now.
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
