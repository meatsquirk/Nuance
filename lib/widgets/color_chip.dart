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
/// through [simulateColor] so a CVD simulation (DISPLAY-3/4) transforms every
/// swatch from this one chokepoint (D-4). In the shell that mapping is identity,
/// and with no scope above it (standalone use) the chip falls back to the
/// default view — either way the swatch renders exactly as its true [color].
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
    final swatch = color == null ? null : simulateColor(color!, settings);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (swatch != null)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
            ),
          Text(label),
        ],
      ),
    );
  }
}
