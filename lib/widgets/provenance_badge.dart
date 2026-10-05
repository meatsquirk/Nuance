import 'package:flutter/material.dart';

import '../domain/provenance.dart';

/// A badge that states a reading's [Provenance] tier in words (+ optional note).
///
/// Renders the tier [Provenance.label] (e.g. "Measured", "Estimated") as text —
/// trust is never conveyed by colour alone (SI Accessibility, SI D9). When the
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(provenance.label),
          if (note != null) Text(note),
        ],
      ),
    );
  }
}
