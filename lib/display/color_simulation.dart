import 'package:flutter/widgets.dart';

import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import '../a11y/cvd/daltonize.dart';
import '../color_science/color_science.dart';
import '../color_science/conversions.dart';
import 'display_settings.dart';

/// Maps a swatch's true [original] colour to how it should be displayed under
/// [settings] — the per-swatch CVD simulation chokepoint (bs-08 D-4).
///
/// DISPLAY-3 put this seam on the live render path (the Readout shows the
/// sample's true colour through `ColorChip`); with simulation off it maps the
/// colour unchanged — the "simulation off = trichromat" identity (AC-2).
///
/// DISPLAY-4 adds the projection branch (AC-3): when
/// [DisplaySettings.simulationType] is set, the colour is shown as a painter
/// with that dichromacy sees it, by projecting through the shipped
/// [projectDichromat] — the one dichromat projection, reused unmodified
/// (D-1) — at [DisplaySettings.simulationSeverity] (so DISPLAY-5/AC-4's slider
/// strength falls out of the same body; severity 0 collapses the projection
/// back to the original). The projection is defined in CIELAB, so the rendered
/// sRGB swatch is reversed with [srgbToLab] (the inverse of the readout's own
/// [labToSrgb]) and the projected CIELAB mapped back with [labToSrgb].
///
/// Kept as a free function so the render path (`ColorChip`) has a single seam to
/// call and the behaviour phases change only this body, never its callers. The
/// original swatch is rendered *alongside* this simulated one by `ColorChip`
/// itself (AC-3's "shown alongside"), not here.
Color simulateColor(Color original, DisplaySettings settings) {
  final type = settings.simulationType;
  if (type == null) return original;
  final lab = srgbToLab(SRGBColor(
    red: (original.r * 255).round(),
    green: (original.g * 255).round(),
    blue: (original.b * 255).round(),
  ));
  final projected = projectDichromat(
    lab,
    CvdProfile(type: type, severity: settings.simulationSeverity),
  );
  final srgb = labToSrgb(projected);
  return Color.fromARGB(255, srgb.red, srgb.green, srgb.blue);
}

/// The swatch colour the render chokepoint displays for a true [original] under
/// [settings], for a painter with [profile] — the **one** display-transform
/// decision every colour surface shares (bs-08 D-4 + bs-10 D-1).
///
/// The two CVD view modes are distinct (bs-10 AC-7) and resolved here, in one
/// place, so `ColorChip` and the read endpoint always agree on the displayed
/// colour:
///
/// * [DisplaySettings.daltonization] on → the bs-10 remap that pushes confusable
///   colours apart, [daltonizeColor] for the painter's stored [profile];
/// * otherwise → the bs-08 simulation, [simulateColor] (itself the identity when
///   no [DisplaySettings.simulationType] is set — the shipped trichromat view).
///
/// Both transforms are identity in the shells (DALT-2 / DISPLAY-2 off), so the
/// displayed colour equals [original] until the behaviour phases fill the
/// bodies; the callers never change.
Color displayedSwatchColor(
  Color original,
  DisplaySettings settings,
  CvdProfile profile,
) =>
    settings.daltonization
        ? daltonizeColor(original, profile)
        : simulateColor(original, settings);
