import 'package:flutter/material.dart';

import '../domain/provenance.dart';
import '../widgets/provenance_icon.dart';
import 'readout_controller.dart';

/// The provenance region: states where the reading came from and how far to
/// trust it (AC-6, AC-7).
///
/// Renders the sample's provenance tier as a plain-language badge — trust is
/// never conveyed by colour alone (SI Accessibility, SI D9):
///
/// * a measured reading reads "Measured" with no caveat (AC-6);
/// * an unverified, model-seeded reading reads "Estimated — not yet verified"
///   with the note "Seeded by a model. Treat as a starting point." beneath it
///   (AC-7).
///
/// The "— not yet verified" qualifier and the seeded-value note are presentation
/// concerns the region owns: the domain [Provenance.label] carries only the bare
/// tier word (shared by every surface), so the region maps the tier to its
/// displayed label and note here. The label and note are folded into a single
/// semantics announcement so a screen reader hears the caveat with the tier.
class ProvenanceRegion extends StatelessWidget {
  const ProvenanceRegion({required this.controller, super.key});

  /// Stable anchor for the provenance region.
  static const Key regionKey = ValueKey('readout-provenance-region');

  /// The seeded-value caveat shown beneath an estimated reading (AC-7).
  @visibleForTesting
  static const String estimatedNote =
      'Seeded by a model. Treat as a starting point.';

  /// The controller supplying the sample's provenance.
  final ReadoutController controller;

  /// The displayed badge label for [provenance].
  ///
  /// An estimated reading reads "Estimated — not yet verified" — the unverified
  /// qualifier is presentation, not part of the domain tier word (AC-7). Every
  /// other tier reads its bare [Provenance.label] (AC-6 and the other tiers).
  @visibleForTesting
  static String labelFor(Provenance provenance) =>
      provenance.tier == ProvenanceTier.estimated
          ? 'Estimated — not yet verified'
          : provenance.label;

  /// The caveat note shown beneath [provenance], or null when it needs none.
  ///
  /// An estimated reading carries the seeded-value caveat (AC-7); a confirmed
  /// reading carries its own [Provenance.note] — the "Confirmed — you measured
  /// this" phrasing the mix-correction loop promotes it with (bs-05 AC-10, G-4(d)
  /// / D-8), which rides the note so the shared tier label stays "Confirmed". A
  /// measured reading shows no note (AC-6, and the AC-7 control); a confirmed
  /// reading with no carried note shows none either.
  @visibleForTesting
  static String? noteFor(Provenance provenance) {
    switch (provenance.tier) {
      case ProvenanceTier.estimated:
        return estimatedNote;
      case ProvenanceTier.confirmed:
        return provenance.note;
      case ProvenanceTier.measured:
      case ProvenanceTier.calculated:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provenance = controller.sample.provenance;
    final label = labelFor(provenance);
    final note = noteFor(provenance);
    return Semantics(
      key: regionKey,
      label: note == null ? label : '$label. $note',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The tier's glyph (and its decorative, remappable tint) — the tier
          // reads from the icon + label, never from colour alone (AC-4).
          ProvenanceIcon(tier: provenance.tier),
          const SizedBox(width: 8),
          // Flexible so a long caveat note wraps within the available width
          // instead of overflowing the row (SI Accessibility: the caveat must
          // stay visible, never clipped).
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                if (note != null) Text(note),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
