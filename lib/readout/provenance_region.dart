import 'package:flutter/material.dart';

import '../domain/provenance.dart';
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
  /// Only an estimated reading carries the seeded-value caveat (AC-7); a
  /// measured reading shows no note (AC-6, and the AC-7 control).
  @visibleForTesting
  static String? noteFor(Provenance provenance) =>
      provenance.tier == ProvenanceTier.estimated ? estimatedNote : null;

  @override
  Widget build(BuildContext context) {
    final provenance = controller.sample.provenance;
    final label = labelFor(provenance);
    final note = noteFor(provenance);
    return Semantics(
      key: regionKey,
      label: note == null ? label : '$label. $note',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (note != null) Text(note),
        ],
      ),
    );
  }
}
