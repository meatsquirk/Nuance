import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// A single colour space's name, openable to reveal a fuller plain-language
/// definition and an example (AC-5).
///
/// READOUT-2 shell — introduces the per-space [nameKey] / [definitionKey]
/// anchors so the AC-5 acceptance test can find a space's name and its (yet
/// unrevealed) definition. It renders an empty, findable placeholder for the
/// named [space]; the still-present [SpaceSelector] keeps rendering the visible
/// space labels until READOUT-3, so the shell adds no duplicate name text.
/// READOUT-6 renders the tappable name and reveals the real definition + example
/// under [definitionKey].
class SpaceDefinition extends StatelessWidget {
  const SpaceDefinition({required this.space, super.key});

  /// Stable anchor for [space]'s tappable name.
  static Key nameKey(ReadoutSpace space) =>
      ValueKey('readout-space-name-${space.name}');

  /// Stable anchor for [space]'s revealed definition (+ example), shown once the
  /// name is opened (READOUT-6).
  static Key definitionKey(ReadoutSpace space) =>
      ValueKey('readout-space-definition-${space.name}');

  /// The colour space this definition is for.
  final ReadoutSpace space;

  @override
  Widget build(BuildContext context) {
    // Shell placeholder: the name anchor is present and findable; the tappable
    // name and the revealed definition + example land in READOUT-6.
    return SizedBox.shrink(key: nameKey(space));
  }
}
