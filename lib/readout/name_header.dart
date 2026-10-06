import 'package:flutter/material.dart';

import 'readout_controller.dart';
import 'value_region.dart';

/// The sample's plain-language colour name, shown large at the top of the
/// readout (AC-3).
///
/// The name is [ReadoutController.nameText] — the sample's own name when it has
/// one, otherwise the nearest ISCC-NBS colour name derived from its
/// coordinates. It is rendered at [ValueRegion.prominentFontSize] so the name is
/// at least as large as the prominent value reading, keeping it the most
/// prominent text at the top of the screen (AC-3). The name text sits inside the
/// keyed [Semantics] header, marking it the readout's heading for assistive
/// technology (SI Accessibility).
class NameHeader extends StatelessWidget {
  const NameHeader({required this.controller, super.key});

  /// Stable anchor for the name header. Keyed on the wrapping header so the name
  /// text is a descendant finders can match within it.
  static const Key headerKey = ValueKey('readout-name-header');

  /// Style for the name: bold and as large as the prominent value reading, so
  /// it is the largest text in the readout body (AC-3).
  static const TextStyle nameStyle = TextStyle(
    fontSize: ValueRegion.prominentFontSize,
    fontWeight: FontWeight.bold,
  );

  /// The controller supplying the name.
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: headerKey,
      header: true,
      child: Text(controller.nameText, style: nameStyle),
    );
  }
}
