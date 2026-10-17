import 'package:flutter/material.dart';

/// A fully-rounded "pill" action button in the wireframe's two weights.
///
/// [PillButton.primary] is the ink-filled call-to-action (wraps a
/// [FilledButton]); [PillButton.secondary] is the transparent, bordered
/// alternative (wraps an [OutlinedButton]). Both inherit their shape, colour
/// and type from the single installed theme, so the widgets carry no colour
/// arguments and the "one theme" guarantee (AC-14) holds.
///
/// This is the **COMPONENTS-1 shell**: the final public API over stock
/// Material buttons, so they look ~stock until THEME-5 wires the
/// fully-rounded [StadiumBorder] shape and COMPONENTS-2 finalises the
/// primary weight (AC-10). Nothing renders a [PillButton] yet; APPLY swaps
/// the ad-hoc buttons for it.
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

  @override
  Widget build(BuildContext context) {
    return _emphasised
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}
