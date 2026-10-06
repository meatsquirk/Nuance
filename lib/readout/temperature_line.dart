import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The temperature line: the sample's warmth stated in words (AC-4).
///
/// Renders [ReadoutController.temperatureWord] — "warm", "cool" or "neutral",
/// derived from the sample's hue relative to the neutral axis — so the painter
/// reads the temperature as a word, never as a raw hue angle (AC-4).
class TemperatureLine extends StatelessWidget {
  const TemperatureLine({required this.controller, super.key});

  /// Stable anchor for the temperature line.
  static const Key lineKey = ValueKey('readout-temperature-line');

  /// The controller supplying the temperature word.
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return Text('Temperature: ${controller.temperatureWord}', key: lineKey);
  }
}
