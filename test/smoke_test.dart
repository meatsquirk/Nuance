import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/main.dart' as app;

void main() {
  test('productionDependencies wires the shipped stub implementations', () {
    final deps = app.productionDependencies();
    expect(deps.colorScience, isA<ColorScienceImpl>());
    expect(deps.speech, isA<NoopSpeech>());
    expect(deps.haptics, isA<NoopHaptics>());
    // bs-02: the shipped app wires a software capture source, so it opens on
    // the Capture screen (D-2).
    expect(deps.captureSource, isA<SoftwareCaptureSource>());
  });

  testWidgets('main() boots the app to the Capture route', (tester) async {
    // Exercises the main() entry point so the scaffold has full line coverage.
    // bs-02 changed the entry point: with a capture source wired, the app opens
    // on the Capture screen rather than bs-01's Readout (build_app D-2).
    app.main();
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget);
  });
}
