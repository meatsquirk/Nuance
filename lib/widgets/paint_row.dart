import 'package:flutter/material.dart';

import '../domain/paint.dart';
import '../domain/provenance.dart';
import 'color_chip.dart';
import 'provenance_badge.dart';

/// A single paint's row in the My-paints list (wireframe S1.R1 — paint list).
///
/// Renders the paint's painter-facing identity — [Paint.name], [Paint.brand],
/// [Paint.line], its [Paint.medium] and [Paint.pigmentIndex] — alongside a
/// [ProvenanceBadge] stating the paint's [Paint.provenance] tier in words, so a
/// paint's trust is shown by the badge and **never by colour alone** (AC-2, SI
/// Accessibility).
///
/// The medium is rendered as its **own** labelled widget ([mediumKeyFor]),
/// distinct from the `line` identity text (which may itself contain the word
/// "Oil", as in "Artists' Oil"), so the medium can be read at its own grain.
///
/// When a [swatchColor] is given (the My-paints list supplies the paint's
/// masstone through the shared display chokepoint — bs-10 AC-9), the paint's
/// name is rendered through a [ColorChip] so a small decorative swatch of that
/// colour sits beside the name and daltonization reaches this screen through the
/// one chokepoint (D-1/D-6). The swatch is *never* shown alone — [ColorChip]
/// requires the name as its label (SI §5.1). With no [swatchColor] (a standalone
/// row, no display scope to remap through) the name renders as plain text,
/// unchanged.
class PaintRow extends StatelessWidget {
  const PaintRow({required this.paint, this.swatchColor, super.key});

  /// The paint this row renders.
  final Paint paint;

  /// The paint's masstone as the display sRGB colour, or null when no display
  /// scope is available to route the swatch through (bs-10 AC-9).
  ///
  /// Supplied by [PaintListRegion] from the enclosing `AppScope`'s colour
  /// science; passed through [ColorChip], it is remapped by daltonization (or a
  /// simulation) at the one display chokepoint, so the Palette screen's swatches
  /// are transformed on every screen exactly as the Readout's are. Null keeps a
  /// standalone row (unit contexts, no scope) rendering the name as plain text.
  final Color? swatchColor;

  /// Stable anchor for the whole row of the paint with [id].
  static Key rowKeyFor(String id) => ValueKey('paint-row-$id');

  /// Stable anchor for the masstone swatch chip of the paint with [id] (bs-10
  /// AC-9) — present only when a [swatchColor] is supplied.
  static Key swatchKeyFor(String id) => ValueKey('paint-row-swatch-$id');

  /// Stable anchor for the dedicated medium label of the paint with [id].
  ///
  /// A widget separate from the identity line, so the medium is observable at
  /// its own grain (not subsumed by a line such as "Artists' Oil").
  static Key mediumKeyFor(String id) => ValueKey('paint-row-medium-$id');

  /// Stable anchor for the provenance badge of the paint with [id].
  static Key badgeKeyFor(String id) => ValueKey('paint-row-badge-$id');

  /// The painter-facing label for [medium] (presentation only).
  static String mediumLabel(PaintMedium medium) {
    switch (medium) {
      case PaintMedium.oil:
        return 'Oil';
      case PaintMedium.acrylic:
        return 'Acrylic';
    }
  }

  @override
  Widget build(BuildContext context) {
    // The identity line: brand · line · pigment index, in that order, skipping
    // any the paint does not carry (bs-04 paints carry none).
    final identity = <String>[
      if (paint.brand != null) paint.brand!,
      if (paint.line != null) paint.line!,
      if (paint.pigmentIndex != null) paint.pigmentIndex!,
    ].join(' · ');

    return Padding(
      key: rowKeyFor(paint.id),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The name, with the masstone swatch beside it when a display
                // colour is available (bs-10 AC-9) — routed through the shared
                // [ColorChip] chokepoint so daltonization remaps the swatch on
                // this screen too; a bare name when there is no scope to remap
                // through. The swatch never stands alone (the name is its
                // label).
                if (swatchColor != null)
                  ColorChip(
                    key: swatchKeyFor(paint.id),
                    label: paint.name,
                    color: swatchColor,
                  )
                else
                  Text(
                    paint.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                if (identity.isNotEmpty) Text(identity),
                // The medium, as its own labelled widget (not the line text).
                Text(
                  mediumLabel(paint.medium),
                  key: mediumKeyFor(paint.id),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ProvenanceBadge(
            key: badgeKeyFor(paint.id),
            provenance: Provenance(paint.provenance),
          ),
        ],
      ),
    );
  }
}
