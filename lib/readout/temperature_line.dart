import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The temperature line: the sample's warmth stated in words (AC-4).
///
/// Shell placeholder: the line is laid out with a stable anchor, but the
/// hue → temperature-word derivation ("warm" / "cool", relative to a neutral)
/// lands in COLOR-3 / READOUT-3.
class TemperatureLine extends StatelessWidget {
  const TemperatureLine({required this.controller, super.key});

  /// Stable anchor for the temperature line.
  static const Key lineKey = ValueKey('readout-temperature-line');

  /// The controller supplying the temperature (unused in the shell).
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return const Text('Temperature —', key: lineKey);
  }
}
