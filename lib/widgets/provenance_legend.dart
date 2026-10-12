import 'package:flutter/material.dart';

import '../domain/provenance.dart';

/// The provenance legend: the four confidence tiers a paint's provenance may
/// carry, each explained by its exact spec string (AC-3).
///
/// Renders one entry per [ProvenanceTier] so the painter can read what every
/// badge on the paint list means. The strings are the spec's exact legend
/// wording ([legendText]); the short [Provenance.label] is what the per-paint
/// badge shows.
class ProvenanceLegend extends StatelessWidget {
  const ProvenanceLegend({super.key});

  /// Stable anchor for the legend entry of [tier].
  static Key entryKeyFor(ProvenanceTier tier) =>
      ValueKey('provenance-legend-${tier.name}');

  /// The exact legend wording for [tier] (AC-3's four tier strings).
  static String legendText(ProvenanceTier tier) {
    switch (tier) {
      case ProvenanceTier.measured:
        return 'Measured';
      case ProvenanceTier.calculated:
        return 'Calculated';
      case ProvenanceTier.estimated:
        return 'Estimated — not yet verified';
      case ProvenanceTier.confirmed:
        return 'Confirmed — you measured this';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final tier in ProvenanceTier.values)
          Text(
            legendText(tier),
            key: entryKeyFor(tier),
          ),
      ],
    );
  }
}
