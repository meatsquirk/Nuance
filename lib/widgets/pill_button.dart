import 'package:flutter/material.dart';

/// A fully-rounded "pill" action button in the wireframe's two weights.
///
/// [PillButton.primary] is the ink-filled call-to-action (wraps a
/// [FilledButton]); [PillButton.secondary] is the transparent, bordered
/// alternative (wraps an [OutlinedButton]). Both inherit their fully-rounded
/// [StadiumBorder] shape and the 2px ink outline weight from the single
/// installed theme (THEME-5); COMPONENTS-2 finalises the per-variant colour
/// treatment here, so the widgets still carry no colour arguments and the
/// "one theme" guarantee (AC-14) holds.
///
/// The treatment (AC-10): the **primary** pill is ink-filled — an `onSurface`
/// background with a paper (`surface`) label at the heavy weight 800 and no
/// border; the **secondary** pill is transparent with an ink (`onSurface`)
/// label behind the theme's 2px ink outline. Stock M3 fills the primary with
/// the accent `primary` and labels both with `primary`, so the colours are
/// overridden per variant (the theme is frozen and cannot encode them).
/// Nothing renders a [PillButton] yet; APPLY swaps the ad-hoc buttons for it.
class PillButton extends StatelessWidget {
  /// The ink-filled primary action (a [FilledButton]).
  const PillButton.primary({
    required this.onPressed,
    required this.child,
    super.key,
  }) : _emphasised = true;

  /// The transparent, bordered secondary action (an [OutlinedButton]).
  const PillButton.secondary({
    required this.onPressed,
    required this.child,
    super.key,
  }) : _emphasised = false;

  /// The tap handler; `null` disables the button.
  final VoidCallback? onPressed;

  /// The button's label (or icon+label row).
  final Widget child;

  /// Whether this is the primary (filled) weight; otherwise the outlined one.
  final bool _emphasised;

  /// The heavy label weight the primary pill carries (wireframe weight 800).
  static const FontWeight _primaryLabelWeight = FontWeight.w800;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_emphasised) {
      // Ink fill + paper label + heavy weight, no border; the fully-rounded
      // StadiumBorder shape is inherited from the theme's filledButtonTheme.
      final labelStyle = theme.textTheme.labelLarge;
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: cs.onSurface,
          foregroundColor: cs.surface,
          textStyle: (labelStyle ?? const TextStyle())
              .copyWith(fontWeight: _primaryLabelWeight),
        ),
        child: child,
      );
    }

    // Transparent fill + ink label; the 2px ink outline is inherited from the
    // theme's outlinedButtonTheme side, so no side is set here.
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
      ),
      child: child,
    );
  }
}
