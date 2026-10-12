import 'package:flutter/widgets.dart';

import 'display_settings.dart';

/// Maps a swatch's true [original] colour to how it should be displayed under
/// [settings] — the per-swatch CVD simulation chokepoint (bs-08 D-4).
///
/// Inert in the shell (DISPLAY-2): it returns [original] unchanged, the explicit
/// "simulation off = trichromat" identity DISPLAY-3 formalises (AC-2). DISPLAY-4
/// extends it to project through the shipped `projectDichromat` — the one
/// dichromat projection, reused unmodified (D-1) — when
/// [DisplaySettings.simulationType] is set, scaled by
/// [DisplaySettings.simulationSeverity] (DISPLAY-5, AC-4). Kept as a free
/// function so the render path (`ColorChip`) has a single seam to call and the
/// behaviour phases change only this body, never its callers.
Color simulateColor(Color original, DisplaySettings settings) => original;
