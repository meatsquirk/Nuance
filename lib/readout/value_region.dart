import 'package:flutter/material.dart';

import '../widgets/value_reading.dart';
import 'readout_controller.dart';

/// The value region: the prominent lightness reading, its grayscale preview and
/// the Munsell value beside it (AC-1, AC-2).
///
/// Lightness is rendered as the largest reading on the screen through
/// [prominentFontSize] (AC-1); the grayscale preview is the sample's own
/// lightness shown as a neutral; the Munsell value sits beside the number; and
/// the plain-language value word is paired with the figure by [ValueReading]
/// so the number never stands alone (AC-2).
class ValueRegion extends StatelessWidget {
  const ValueRegion({required this.controller, super.key});

  /// Stable anchor for the region.
  static const Key regionKey = ValueKey('readout-value-region');

  /// Stable anchor for the grayscale preview slot.
  static const Key grayscaleKey = ValueKey('readout-grayscale-preview');

  /// Font size of the prominent lightness figure.
  ///
  /// Large enough to out-size every other reading rendered in the readout body
  /// (the name header's prominence is AC-3's concern, not a reading), making the
  /// lightness the largest reading on the screen (AC-1).
  static const double prominentFontSize = 48;

  /// The controller supplying the derived value readings.
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    final grayscale = controller.grayscale;
    return Padding(
      key: regionKey,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // The grayscale preview: the sample's lightness as a neutral swatch,
          // so the value reads without colour (SI Accessibility, AC-1).
          Container(
            key: grayscaleKey,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color.fromARGB(
                255,
                grayscale.red,
                grayscale.green,
                grayscale.blue,
              ),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lightness as the prominent reading, paired with its value word.
                ValueReading(
                  number: _formatLightness(controller.lightness),
                  word: controller.valueWord,
                  numberStyle: const TextStyle(
                    fontSize: prominentFontSize,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                // The Munsell value beside the lightness (AC-1).
                Text('Munsell value ${_formatMunsellValue(controller.munsell.value)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats a CIELAB L\* [lightness] for the prominent reading — a whole number
/// (readout precision for a painter; the spec states "Lightness 58").
String _formatLightness(double lightness) => lightness.round().toString();

/// Formats a Munsell [value] for display, dropping a redundant ".0" (so a value
/// of 5.5 reads "5.5" and 6.0 reads "6").
String _formatMunsellValue(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toString();
