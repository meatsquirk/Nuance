import 'package:flutter/material.dart';

import '../domain/provenance.dart';
import 'provenance_icon.dart';

/// A badge that states a reading's [Provenance] tier in words (+ optional note).
///
/// Renders the tier [Provenance.label] (e.g. "Measured", "Estimated") as text
/// beside a tier [ProvenanceIcon] (glyph) — trust is conveyed by the words and
/// the shape, never by colour alone (SI Accessibility, SI D9, bs-10 AC-4). The
/// icon's tint is decorative and routed through the display chokepoint, so
/// daltonization may remap it without the tier losing its readability. When the
/// provenance carries a [Provenance.note] it is shown beneath the tier label and
/// folded into a single semantics announcement.
class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge({required this.provenance, super.key});

  /// The provenance whose tier (and optional note) this badge states.
  final Provenance provenance;

  @override
  Widget build(BuildContext context) {
    final note = provenance.note;
    return Semantics(
      label: note == null ? provenance.label : '${provenance.label}. $note',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProvenanceIcon(tier: provenance.tier),
          const SizedBox(width: 8),
          // Flexible so a long caveat note wraps within the available width
          // instead of overflowing the row.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provenance.label),
                if (note != null) Text(note),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
