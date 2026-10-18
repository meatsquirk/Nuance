import 'package:flutter/material.dart';

import '../app/theme.dart';

enum _SurfaceCardVariant { ordinary, emphasis, inverted }

/// A rounded "surface card" panel in the wireframe's three weights.
///
/// - default [SurfaceCard]: a surface fill with the `--ln` line-colour border
///   at the standard 2px weight;
/// - [SurfaceCard.emphasis]: the same fill with a standard-weight ink border;
/// - [SurfaceCard.inverted]: an ink fill with paper-coloured text (the
///   [AppTheme.inverted] pair), used for the one emphasised panel per screen.
///
/// Colours and border weights come from [AppTheme] / the installed
/// [ColorScheme] and the radius from the card theme, so the card carries no
/// colour arguments and the "one theme" guarantee holds.
///
/// COMPONENTS-4 finalised the exact borders (AC-12): the ordinary card draws
/// the line colour ([ColorScheme.outlineVariant]) at the standard 2px weight,
/// emphasis the ink colour at 2px, and inverted an ink fill with paper text and
/// no border; the radius is inherited from `cardTheme` (r18). Nothing renders a
/// [SurfaceCard] until the APPLY phases swap in the component.
class SurfaceCard extends StatelessWidget {
  /// An ordinary panel: surface fill, line-colour border at the standard weight.
  const SurfaceCard({required this.child, super.key})
      : _variant = _SurfaceCardVariant.ordinary;

  /// An emphasised panel: surface fill, standard-weight ink border.
  const SurfaceCard.emphasis({required this.child, super.key})
      : _variant = _SurfaceCardVariant.emphasis;

  /// An inverted panel: ink fill with paper-coloured text.
  const SurfaceCard.inverted({required this.child, super.key})
      : _variant = _SurfaceCardVariant.inverted;

  /// The panel's content.
  final Widget child;

  final _SurfaceCardVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Radius from the card theme when it supplies one, else a rounded default
    // in the wireframe's 16–22 range (THEME-5 sets the card theme's shape).
    final cardShape = theme.cardTheme.shape;
    final borderRadius = cardShape is RoundedRectangleBorder
        ? cardShape.borderRadius
        : BorderRadius.circular(16);

    final Color fill;
    final BoxBorder? border;
    final Color? textColor;
    switch (_variant) {
      case _SurfaceCardVariant.ordinary:
        fill = scheme.surface;
        border = Border.all(
          color: scheme.outlineVariant,
          width: AppTheme.standardBorderWidth,
        );
        textColor = null;
      case _SurfaceCardVariant.emphasis:
        fill = scheme.surface;
        border = Border.all(
          color: scheme.onSurface,
          width: AppTheme.standardBorderWidth,
        );
        textColor = null;
      case _SurfaceCardVariant.inverted:
        fill = AppTheme.inverted.paper;
        border = null;
        textColor = AppTheme.inverted.ink;
    }

    final content = textColor == null
        ? child
        : DefaultTextStyle.merge(style: TextStyle(color: textColor), child: child);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        border: border,
        borderRadius: borderRadius,
      ),
      child: content,
    );
  }
}
