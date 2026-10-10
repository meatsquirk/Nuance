import 'package:flutter/material.dart';

/// The provenance-legend region of the Palette screen's My-paints view
/// (wireframe S1.R1 — the provenance legend body).
///
/// Explains the four confidence tiers a paint's provenance may carry (AC-3).
/// This shell renders only a labelled placeholder; PALETTE-3 fills in the four
/// exact tier strings ("Measured", "Calculated", "Estimated — not yet
/// verified", "Confirmed — you measured this"). The region keeps its
/// [regionKey] so the acceptance finder and PALETTE-3 have a stable anchor.
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
        // PALETTE-3 renders the four confidence tiers here (AC-3).
        const Text('Confidence tiers shown here'),
      ],
    );
  }
}
