import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The provenance region: states where the reading came from and how far to
/// trust it (AC-6, AC-7).
///
/// Shell placeholder: the region is laid out with a stable anchor, but the real
/// badge — the tier label ("Measured" / "Estimated — not yet verified") and the
/// seeded-value note, rendered through the `ProvenanceBadge` widget — lands in
/// READOUT-5.
class ProvenanceRegion extends StatelessWidget {
  const ProvenanceRegion({required this.controller, super.key});

  /// Stable anchor for the provenance region.
  static const Key regionKey = ValueKey('readout-provenance-region');

  /// The controller supplying the sample's provenance (unused in the shell).
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return const Text('Provenance —', key: regionKey);
  }
}
