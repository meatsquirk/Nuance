import 'package:flutter/material.dart';

/// The three wireframe diameters for a [SpeakButton], in logical pixels.
enum SpeakButtonSize {
  /// The 64px primary floating speak control.
  standard(64),

  /// The 52px inline speak control.
  compact(52),

  /// The 44px minimum-tap-target speak control.
  mini(44);

  const SpeakButtonSize(this.diameter);

  /// The button's width and height in logical pixels.
  final double diameter;
}

/// A round, accent-filled "speak" floating button carrying a speaker glyph —
/// the wireframe's spoken-output affordance.
///
/// The fill is the theme accent ([ColorScheme.primary], the cobalt `--acc`)
/// with a paper-coloured glyph ([ColorScheme.onPrimary]), so it carries no
/// colour arguments and inherits the one installed theme. [semanticLabel]
/// names the action for screen readers (bs-11's spoken-output label
/// contract); the glyph itself is excluded from semantics.
///
/// Finalised in **COMPONENTS-3** (AC-11): the wireframe speak affordance is a
/// round, accent-filled FAB, and that look is exactly the theme accent fill —
/// so, unlike the [PillButton] (which overrides the stock accent fill with an
/// ink fill), this widget needs no widget-level colour override; the shell's
/// `fillColor: scheme.primary` already carries the final treatment, now that
/// the warm-paper `ColorScheme` (THEME-3) makes `primary` the cobalt `--acc`.
/// The three [SpeakButtonSize] diameters (64/52/44), the speaker glyph and the
/// semantic label are the frozen public API. APPLY wires it into screens;
/// nothing renders a [SpeakButton] yet.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    required this.onPressed,
    required this.semanticLabel,
    this.size = SpeakButtonSize.standard,
    super.key,
  });

  /// The tap handler; `null` disables the button.
  final VoidCallback? onPressed;

  /// The action name announced to screen readers.
  final String semanticLabel;

  /// Which of the three wireframe diameters to render.
  final SpeakButtonSize size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // MergeSemantics folds the label into the button's own tap semantics so a
    // screen reader announces one labelled button, not a label beside a button.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: RawMaterialButton(
          onPressed: onPressed,
          shape: const CircleBorder(),
          fillColor: scheme.primary,
          elevation: 0,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          constraints: BoxConstraints.tightFor(
            width: size.diameter,
            height: size.diameter,
          ),
          child: Icon(
            Icons.volume_up,
            color: scheme.onPrimary,
            size: size.diameter / 2,
          ),
        ),
      ),
    );
  }
}
