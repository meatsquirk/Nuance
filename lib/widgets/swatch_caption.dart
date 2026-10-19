import 'package:flutter/material.dart';

import 'mono_label.dart';

/// The shared caption that accompanies a screen's colour swatches: the standing
/// reminder that an on-screen swatch is a *screen approximation* and the stated
/// numbers are authoritative (bs-17 AC-15).
///
/// The swatch is decorative — meaning never rides on colour alone (SI
/// Accessibility): every [ColorChip] already carries its own text label, and
/// this caption adds the one reminder that the swatch is a hint, not the
/// message — trust the numbers, not the pixels. A swatch-bearing screen renders
/// it **once** beside its swatch group (never once per swatch), reusing this
/// single widget rather than duplicating the copy. Its two parts — the `APPROX.`
/// mono eyebrow ([MonoLabel]) and the explanatory line — are folded into one
/// [Semantics] node, so a screen reader announces the caption a single time
/// ([message]) rather than reading the tag and the line separately.
class SwatchCaption extends StatelessWidget {
  const SwatchCaption({super.key});

  /// Stable anchor for the caption — one per swatch-bearing screen.
  static const Key captionKey = ValueKey('swatch-approximation-caption');

  /// The mono eyebrow tag (rendered uppercase by [MonoLabel] → `APPROX.`).
  static const String tag = 'Approx.';

  /// The authoritative caption copy (the wireframe's swatch caption): the
  /// swatch is an approximation and the numbers are authoritative.
  static const String message =
      'Swatches are screen approximations. Trust the numbers.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The muted secondary-text role, read from the one installed theme (AC-14 —
    // no hardcoded palette literal); its pairing over the surface is already
    // proven AA by the bs-11 contrast test.
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Semantics(
      key: captionKey,
      label: message,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const MonoLabel(tag),
            const SizedBox(width: 8),
            Flexible(child: Text(message, style: style)),
          ],
        ),
      ),
    );
  }
}
