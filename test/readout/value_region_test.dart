import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/value_region.dart';

// Terracotta: CIELAB L58 → Munsell value 5.5, grayscale a neutral.
const _terracotta = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

ReadoutController _controllerFor(Sample sample) => ReadoutController(
      sample: sample,
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: const AppRouter(),
    );

Future<ReadoutController> _pumpRegion(
  WidgetTester tester, {
  Sample sample = _terracotta,
}) async {
  final controller = _controllerFor(sample);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ValueRegion(controller: controller)),
    ),
  );
  return controller;
}

/// The effective font size of the first `Text` whose data is [text].
double _fontSizeOf(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return paragraph.text.style?.fontSize ?? 14.0;
}

void main() {
  testWidgets('shows the lightness, its value word and the Munsell value',
      (tester) async {
    await _pumpRegion(tester);

    expect(find.text('58'), findsOneWidget);
    expect(find.text('middle value'), findsOneWidget);
    expect(find.text('Munsell value 5.5'), findsOneWidget);
  });

  testWidgets('the value word tracks the lightness', (tester) async {
    await _pumpRegion(
      tester,
      sample: _terracotta.copyWith(
        coordinates: const ColorCoordinates(lightness: 15, a: 25.27, b: 22.75),
      ),
    );
    expect(find.text('15'), findsOneWidget);
    expect(find.text('very low value'), findsOneWidget);
    expect(find.text('middle value'), findsNothing);
  });

  testWidgets('renders the lightness as the largest reading in the region',
      (tester) async {
    await _pumpRegion(tester);

    final lightnessSize = _fontSizeOf(tester, '58');
    expect(lightnessSize, ValueRegion.prominentFontSize);
    // Strictly larger than the other readings beside it.
    expect(lightnessSize, greaterThan(_fontSizeOf(tester, 'middle value')));
    expect(lightnessSize, greaterThan(_fontSizeOf(tester, 'Munsell value 5.5')));
  });

  testWidgets('the grayscale preview uses the sample neutral', (tester) async {
    final controller = await _pumpRegion(tester);

    final container =
        tester.widget<Container>(find.byKey(ValueRegion.grayscaleKey));
    final decoration = container.decoration! as BoxDecoration;
    final gray = controller.grayscale;
    expect(decoration.color, Color.fromARGB(255, gray.red, gray.green, gray.blue));
  });

  testWidgets('formats a whole Munsell value without a trailing .0',
      (tester) async {
    // A black sample has Munsell value 0 — a whole number, which must render as
    // "0", never "0.0" (the whole-number branch of the value formatter).
    await _pumpRegion(
      tester,
      sample: _terracotta.copyWith(
        coordinates: const ColorCoordinates(lightness: 0, a: 0, b: 0),
      ),
    );
    expect(find.text('Munsell value 0'), findsOneWidget);
    expect(find.textContaining('.0'), findsNothing);
  });
}
