import 'package:flutter/material.dart';

import '../display/color_simulation.dart';
import '../display/display_scope.dart';
import '../display/display_settings.dart';

/// A colour swatch that is *never* shown without accompanying text.
///
/// Enforces the app's "no meaning in colour alone" rule (SI Accessibility)
/// structurally: [label] is required and must be non-empty, so a colour can
/// never be presented as a bare swatch. The optional [color] renders a small
/// decorative swatch beside the text; screen readers announce only [label]
/// (the swatch carries no independent meaning).
///
/// The displayed swatch colour is routed through the app's display settings
/// (bs-08): [ColorChip] reads the nearest `DisplayScope` and maps [color]
/// through [simulateColor] so a CVD simulation transforms every swatch from this
/// one chokepoint (D-4). With simulation off (or no scope above it, standalone
/// use) that mapping is the identity, so a single swatch renders exactly as its
/// true [color] — "the colour a trichromat sees" (AC-2).
///
/// With a simulation **on**, the chip shows the simulated swatch *alongside* the
/// untouched original (two swatches), so the painter sees both how the colour
/// appears to them and its true colour side by side (AC-3). The label still
/// carries all the meaning; the swatches stay decorative.
class ColorChip extends StatelessWidget {
  const ColorChip({required this.label, this.color, super.key})
      : assert(
          label != '',
          'ColorChip requires descriptive text; colour alone conveys no '
          'meaning (SI Accessibility).',
        );

  /// The text that always accompanies the swatch.
  final String label;

  /// The swatch colour, if any. Decorative only — [label] carries the meaning.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final settings =
        DisplayScope.maybeOf(context)?.settings ?? const DisplaySettings();
    // The swatch(es) to draw: the displayed colour (the simulation of [color],
    // which is [color] itself when simulation is off — AC-2), and, when a
    // simulation is on, the untouched original shown alongside it (AC-3).
    final swatches = <Color>[
      if (color != null) simulateColor(color!, settings),
      if (color != null && settings.simulationOn) color!,
    ];
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final swatch in swatches)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
            ),
          // Flexible so a long label wraps within the available width instead of
          // overflowing the row — a multi-point reading's label carries its
          // position and full colour value and can be wider than the region.
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
