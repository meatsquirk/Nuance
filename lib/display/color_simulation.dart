import 'package:flutter/widgets.dart';

import 'display_settings.dart';

/// Maps a swatch's true [original] colour to how it should be displayed under
/// [settings] — the per-swatch CVD simulation chokepoint (bs-08 D-4).
///
/// DISPLAY-3 puts this seam on the live render path: the Readout now shows the
/// sample's true colour through `ColorChip`, and with simulation off this maps
/// it unchanged — the "simulation off = trichromat" identity (AC-2). The body
/// stays the identity until DISPLAY-4 adds the `simulationType != null`
/// projection branch, so there is no yet-uncovered branch here. DISPLAY-4
/// extends it to project through the shipped `projectDichromat` — the one
/// dichromat projection, reused unmodified (D-1) — when
/// [DisplaySettings.simulationType] is set, scaled by
/// [DisplaySettings.simulationSeverity] (DISPLAY-5, AC-4). Kept as a free
/// function so the render path (`ColorChip`) has a single seam to call and the
/// behaviour phases change only this body, never its callers.
Color simulateColor(Color original, DisplaySettings settings) => original;
