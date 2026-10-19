import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/widgets/speak_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('is round, accent-filled and carries a speaker glyph',
      (tester) async {
    await _pump(
      tester,
      SpeakButton(onPressed: () {}, semanticLabel: 'Speak reading'),
    );
    final button =
        tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
    expect(button.shape, const CircleBorder());

    final scheme = ThemeData(useMaterial3: true).colorScheme;
    expect(button.fillColor, scheme.primary);

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.volume_up);
    expect(icon.color, scheme.onPrimary);
  });

  testWidgets('announces one labelled, tappable button', (tester) async {
    await _pump(
      tester,
      SpeakButton(onPressed: () {}, semanticLabel: 'Speak reading'),
    );
    expect(
      tester.getSemantics(find.byType(SpeakButton)),
      isSemantics(label: 'Speak reading', isButton: true),
    );
  });

  testWidgets('invokes its handler on tap', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      SpeakButton(onPressed: () => taps++, semanticLabel: 'Speak'),
    );
    await tester.tap(find.byType(SpeakButton));
    expect(taps, 1);
  });

  testWidgets('defaults to the 64px standard diameter', (tester) async {
    await _pump(
      tester,
      SpeakButton(onPressed: () {}, semanticLabel: 'Speak'),
    );
    expect(tester.getSize(find.byType(RawMaterialButton)).width, 64);
  });

  testWidgets('renders each of the three wireframe diameters', (tester) async {
    for (final (size, diameter) in const [
      (SpeakButtonSize.standard, 64.0),
      (SpeakButtonSize.compact, 52.0),
      (SpeakButtonSize.mini, 44.0),
    ]) {
      expect(size.diameter, diameter);
      await _pump(
        tester,
        SpeakButton(onPressed: () {}, semanticLabel: 'Speak', size: size),
      );
      expect(tester.getSize(find.byType(RawMaterialButton)).width, diameter);
    }
  });

  testWidgets('a null handler disables the button', (tester) async {
    await _pump(
      tester,
      const SpeakButton(onPressed: null, semanticLabel: 'Speak'),
    );
    final button =
        tester.widget<RawMaterialButton>(find.byType(RawMaterialButton));
    expect(button.onPressed, isNull);
  });
}
