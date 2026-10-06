import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The colour-space selector: picks which space the readout shows (AC-5).
///
/// The four space options render as a button set; selecting one updates
/// [ReadoutController.selectedSpace] and the region below shows that space's
/// values ([ReadoutController.spaceReadout]) and only that space's — the
/// one-at-a-time rule: the other three are no longer shown.
class SpaceSelector extends StatelessWidget {
  const SpaceSelector({required this.controller, super.key});

  /// Stable anchor for the selector.
  static const Key selectorKey = ValueKey('readout-space-selector');

  /// Stable anchor for the selected space's rendered values.
  static const Key valuesKey = ValueKey('readout-space-values');

  /// The controller holding (and updating) the selected space.
  final ReadoutController controller;

  /// The user-facing label for [space].
  static String labelFor(ReadoutSpace space) {
    switch (space) {
      case ReadoutSpace.cielch:
        return 'CIELCh';
      case ReadoutSpace.munsell:
        return 'Munsell';
      case ReadoutSpace.srgb:
        return 'sRGB';
      case ReadoutSpace.cielab:
        return 'CIELAB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: selectorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final space in ReadoutSpace.values)
              ChoiceChip(
                label: Text(labelFor(space)),
                selected: controller.selectedSpace == space,
                onSelected: (_) => controller.selectSpace(space),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(controller.spaceReadout, key: valuesKey),
      ],
    );
  }
}
