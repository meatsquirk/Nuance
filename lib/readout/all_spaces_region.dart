import 'package:flutter/material.dart';

import 'readout_controller.dart';
import 'space_definition.dart';

/// The all-colour-spaces region: every colour space shown together — CIELCh,
/// Munsell, sRGB and CIELAB — with no one-at-a-time selector (AC-4), each name
/// openable for a fuller definition (AC-5).
///
/// READOUT-2 shell — introduces the findable [regionKey] anchor and hosts one
/// [SpaceDefinition] placeholder per [ReadoutSpace], so the harness and the
/// AC-4 / AC-5 acceptance tests can anchor on the region and each space. It
/// renders no space *values* yet and adds no duplicate name text, so the
/// still-present [SpaceSelector] keeps the one-at-a-time behaviour unchanged.
/// READOUT-3 renders every space's real values together and removes the
/// selector; READOUT-6 fills each [SpaceDefinition].
class AllSpacesRegion extends StatelessWidget {
  const AllSpacesRegion({super.key});

  /// Stable anchor for the all-spaces region (AC-4).
  static const Key regionKey = ValueKey('readout-all-spaces');

  @override
  Widget build(BuildContext context) {
    // Shell placeholder: the region anchor and one per-space definition host are
    // present and findable; every space's values land in READOUT-3.
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final space in ReadoutSpace.values) SpaceDefinition(space: space),
      ],
    );
  }
}
