import 'package:flutter/material.dart';

/// A status indicator that always states its status in words (and optionally an
/// icon) — never as a bare coloured dot.
///
/// Joins [ColorChip] under the app's "no meaning in colour alone" contract (SI
/// Accessibility): [label] is required and must be non-empty, [color] is
/// decorative only, and screen readers announce just [label] (the leading icon
/// or swatch carries no independent meaning). This is the **A11Y-1 shell** —
/// the primitive exists and is unit-covered but is rendered nowhere yet; A11Y-5
/// routes every screen's status through it (AC-1 / AC-2).
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.label, this.icon, this.color, super.key})
      : assert(
          label != '',
          'StatusBadge requires descriptive text; colour alone conveys no '
          'meaning (SI Accessibility).',
        );

  /// The text that always states the status.
  final String label;

  /// An optional leading icon reinforcing the status (a non-colour cue).
  final IconData? icon;

  /// An optional decorative colour tinting the icon, or drawn as a small swatch
  /// when there is no icon. Decorative only — [label] carries the meaning.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, color: color),
            )
          else if (color != null)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          // Flexible so a long status label wraps instead of overflowing the row.
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
