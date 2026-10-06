import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The sample's plain-language name, shown at the top of the readout (AC-3).
///
/// Shell placeholder: the header renders [ReadoutController.nameText] (the
/// sample's own name, or an "Unnamed sample" fallback). The nearest-name
/// derivation and the large top-of-screen prominence (AC-3) land in
/// COLOR-3 / READOUT-3.
class NameHeader extends StatelessWidget {
  const NameHeader({required this.controller, super.key});

  /// Stable anchor for the name header.
  static const Key headerKey = ValueKey('readout-name-header');

  /// The controller supplying the name.
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return Text(
      controller.nameText,
      key: headerKey,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}
