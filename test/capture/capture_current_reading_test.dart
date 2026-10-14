import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/capture_current_reading.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';

const Sample _sample = Sample(
  coordinates: ColorCoordinates(lightness: 55, a: -25, b: 30),
  provenance: Provenance(ProvenanceTier.measured),
);

Future<void> _pump(
  WidgetTester tester, {
  required Sample? sample,
  bool withScope = false,
}) {
  final widget = CaptureCurrentReading(sample: sample);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: withScope
            ? AppScope(
                dependencies: const AppDependencies(
                  colorScience: ColorScienceImpl(),
                  speech: NoopSpeech(),
                  haptics: NoopHaptics(),
                ),
                child: widget,
              )
            : widget,
      ),
    ),
  );
}

void main() {
  group('CaptureCurrentReading', () {
    testWidgets('renders nothing before a colour is sampled', (tester) async {
      await _pump(tester, sample: null, withScope: true);

      expect(find.byKey(CaptureCurrentReading.readingKey), findsNothing);
      expect(find.byType(ColorChip), findsNothing);
    });

    testWidgets('renders nothing with no enclosing AppScope to remap through',
        (tester) async {
      await _pump(tester, sample: _sample);

      expect(find.byKey(CaptureCurrentReading.readingKey), findsNothing);
      expect(find.byType(ColorChip), findsNothing);
    });

    testWidgets('renders the live reading as a labelled swatch under a scope',
        (tester) async {
      await _pump(tester, sample: _sample, withScope: true);

      final chip = tester.widget<ColorChip>(
          find.byKey(CaptureCurrentReading.readingKey));
      // The label carries the reading's CIELAB value, so the swatch never
      // stands alone (SI §5.1).
      expect(chip.label, 'Current reading: L 55.0 a -25.0 b 30.0');
      // The swatch is the reading's sRGB colour, which ColorChip then routes
      // through the display chokepoint for daltonization.
      final SRGBColor rgb =
          const ColorScienceImpl().toSRGB(_sample.coordinates);
      expect(
        chip.color,
        Color.fromARGB(255, rgb.red, rgb.green, rgb.blue),
      );
    });
  });
}
