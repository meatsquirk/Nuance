import 'package:flutter/material.dart';

import '../domain/paint.dart';
import '../domain/provenance.dart';
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
class PaintRow extends StatelessWidget {
  const PaintRow({required this.paint, super.key});

  /// The paint this row renders.
  final Paint paint;

  /// Stable anchor for the whole row of the paint with [id].
  static Key rowKeyFor(String id) => ValueKey('paint-row-$id');

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
