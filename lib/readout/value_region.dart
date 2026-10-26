import 'package:flutter/material.dart';

import '../widgets/color_chip.dart';
import '../widgets/surface_card.dart';
import '../widgets/swatch_caption.dart';
import '../widgets/value_reading.dart';
import 'readout_controller.dart';

/// The value region: the prominent lightness reading, its grayscale preview and
/// the Munsell value beside it (AC-1, AC-2), plus the sample's displayed colour.
///
/// Lightness is rendered as the largest reading on the screen through
/// [prominentFontSize] (AC-1); the grayscale preview is the sample's own
/// lightness shown as a neutral; the Munsell value sits beside the number; and
/// the plain-language value word is paired with the figure by [ValueReading]
/// so the number never stands alone (AC-2).
///
/// The sample's true colour is shown as a chromatic swatch through the shared
/// [ColorChip] — the one display-simulation chokepoint (bs-08 D-4). With
/// simulation off it is the colour "as a trichromat sees it", unchanged (bs-08
/// AC-2, the identity path DISPLAY-4 extends to the simulated-alongside pair).
/// The swatch never stands alone: [ColorChip] requires a text label.
class ValueRegion extends StatelessWidget {
  const ValueRegion({required this.controller, super.key});

  /// Stable anchor for the region.
  static const Key regionKey = ValueKey('readout-value-region');

  /// Stable anchor for the value-hero card (AC-1).
  ///
  /// The value content sits inside a bordered [SurfaceCard] (READOUT-4) so the
  /// lightness is presented as a prominent hero card — the largest reading on
  /// the screen through [prominentFontSize].
  static const Key heroCardKey = ValueKey('readout-value-hero-card');

  /// Stable anchor for the grayscale preview slot.
  static const Key grayscaleKey = ValueKey('readout-grayscale-preview');

  /// Side length of the two value swatches — the grayscale preview and the
  /// displayed-colour swatch — kept equal so the displayed colour reads as
  /// large as the grayscale value swatch (AC-3).
  static const double swatchSize = 48;

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
    final color = controller.displayColor;
    // The value content sits inside a bordered hero card (READOUT-4, AC-1): a
    // SurfaceCard draws the one-theme line border, so the lightness reads as a
    // prominent card rather than a plain row.
    return SurfaceCard(
      key: heroCardKey,
      child: Padding(
        key: regionKey,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The grayscale preview: the sample's lightness as a neutral swatch,
            // so the value reads without colour (SI Accessibility, AC-1).
            Container(
              key: grayscaleKey,
              width: swatchSize,
              height: swatchSize,
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
                  Text(
                    'Munsell value ${_formatMunsellValue(controller.munsell.value)}',
                  ),
                  const SizedBox(height: 4),
                  // The sample's true displayed colour, routed through the shared
                  // ColorChip (the bs-08 simulation chokepoint). Simulation off =
                  // the colour a trichromat sees, unchanged (AC-2). The label is
                  // generic so it never repeats the colour name shown in the
                  // header — the swatch is decorative; its meaning is in the text.
                  // Its swatch is sized equal to the grayscale swatch (AC-3).
                  ColorChip(
                    label: 'Displayed color',
                    color: Color.fromARGB(
                      255,
                      color.red,
                      color.green,
                      color.blue,
                    ),
                    swatchSize: swatchSize,
                  ),
                  // The one standing reminder that the swatch is a screen
                  // approximation and the numbers are authoritative (bs-17 AC-15);
                  // rendered once beside the region's single swatch.
                  const SwatchCaption(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats a CIELAB L\* [lightness] for the prominent reading — a whole number
/// (readout precision for a painter; the spec states "Lightness 58").
String _formatLightness(double lightness) => lightness.round().toString();

/// Formats a Munsell [value] for display, dropping a redundant ".0" (so a value
/// of 5.5 reads "5.5" and 6.0 reads "6").
String _formatMunsellValue(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
