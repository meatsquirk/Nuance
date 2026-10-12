import 'package:flutter/material.dart';

import '../widgets/provenance_legend.dart';

/// The provenance-legend region of the Palette screen's My-paints view
/// (wireframe S1.R1 — the provenance legend body).
///
/// Explains the four confidence tiers a paint's provenance may carry (AC-3):
/// "Measured", "Calculated", "Estimated — not yet verified" and "Confirmed —
/// you measured this", rendered by the [ProvenanceLegend] widget. The region
/// keeps its [regionKey] so the acceptance finder has a stable anchor.
class ProvenanceLegendRegion extends StatelessWidget {
  const ProvenanceLegendRegion({super.key});

  /// Stable anchor for the provenance-legend region (AC-3).
  static const Key regionKey = ValueKey('palette-provenance-legend-region');

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provenance legend',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        // The four confidence tiers, each by its exact spec string (AC-3).
        const ProvenanceLegend(),
      ],
    );
  }
}
