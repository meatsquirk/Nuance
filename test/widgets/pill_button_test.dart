import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/widgets/pill_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('primary renders a FilledButton carrying its child',
      (tester) async {
    await _pump(
      tester,
      PillButton.primary(onPressed: () {}, child: const Text('Save')),
    );
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('secondary renders an OutlinedButton carrying its child',
      (tester) async {
    await _pump(
      tester,
      PillButton.secondary(onPressed: () {}, child: const Text('Cancel')),
    );
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('a null handler disables the button', (tester) async {
    await _pump(
      tester,
      const PillButton.primary(onPressed: null, child: Text('Save')),
    );
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('invokes its handler on tap', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      PillButton.primary(onPressed: () => taps++, child: const Text('Save')),
    );
    await tester.tap(find.byType(FilledButton));
    expect(taps, 1);
  });
}
