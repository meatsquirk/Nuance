import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  testWidgets('main() boots the app to the Readout route', (tester) async {
    // Exercises the main() entry point so the scaffold has full line coverage.
    app.main();
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Readout'), findsOneWidget);
  });
}
