import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A short, uppercase monospace micro-label — the wireframe's "mono-label"
/// treatment for provenance tags, swatch captions and field eyebrows.
///
/// The text is upper-cased in the widget (callers pass natural-case strings)
/// and drawn in [AppTheme.monoLabel], the single source for the mono
/// micro-label style (D-7). This is the **COMPONENTS-1 shell**: the style
/// currently resolves to the stock `labelSmall`, so the label looks ~stock
/// until THEME-4/5 fill the Mono family, weight and letter-spacing into that
/// token. Nothing renders a [MonoLabel] yet; APPLY routes labels through it.
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {super.key});

  /// The label text, in natural case; rendered upper-cased.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTheme.monoLabel);
  }
}
