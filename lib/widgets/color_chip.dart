import 'package:flutter/material.dart';

/// A colour swatch that is *never* shown without accompanying text.
///
/// Enforces the app's "no meaning in colour alone" rule (SI Accessibility)
/// structurally: [label] is required and must be non-empty, so a colour can
/// never be presented as a bare swatch. The optional [color] renders a small
/// decorative swatch beside the text; screen readers announce only [label]
/// (the swatch carries no independent meaning).
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
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          Text(label),
        ],
      ),
    );
  }
}
