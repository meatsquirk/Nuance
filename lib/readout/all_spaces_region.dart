import 'package:flutter/material.dart';

import 'readout_controller.dart';
import 'space_definition.dart';
import 'space_selector.dart';

/// The all-colour-spaces region: every colour space shown together — CIELCh,
/// Munsell, sRGB and CIELAB — with no one-at-a-time selector (AC-4), each name
/// a host for a fuller definition (AC-5).
///
/// READOUT-3 renders every space's real values together (the selector is gone):
/// for each [ReadoutSpace] it shows the space's label and its
/// [ReadoutController.readoutForSpace] values, so the whole readout is visible
/// at once rather than one space at a time. Each space keeps a [SpaceDefinition]
/// host (the findable [SpaceDefinition.nameKey] / [SpaceDefinition.definitionKey]
/// anchors); READOUT-6 turns that host's name tappable and reveals a fuller
/// definition + example under [SpaceDefinition.definitionKey].
class AllSpacesRegion extends StatelessWidget {
  const AllSpacesRegion({required this.controller, super.key});

  /// Stable anchor for the all-spaces region (AC-4).
  static const Key regionKey = ValueKey('readout-all-spaces');

  /// The controller supplying each space's formatted values.
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final space in ReadoutSpace.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The per-space definition host: an (empty) findable anchor until
                // READOUT-6 makes the name tappable and reveals its definition.
                SpaceDefinition(space: space),
                // The space's label and its values, shown together with every
                // other space — the readout is no longer one space at a time.
                Text(SpaceSelector.labelFor(space), style: labelStyle),
                Text(controller.readoutForSpace(space)),
              ],
            ),
          ),
      ],
    );
  }
}
