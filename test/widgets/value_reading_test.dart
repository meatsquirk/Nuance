import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/widgets/value_reading.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('renders both the number and its word', (tester) async {
    await _pump(tester, const ValueReading(number: '58', word: 'middle value'));
    expect(find.text('58'), findsOneWidget);
    expect(find.text('middle value'), findsOneWidget);
  });

  testWidgets('applies the given number style', (tester) async {
    await _pump(
      tester,
      const ValueReading(
        number: '58',
        word: 'middle value',
        numberStyle: TextStyle(fontSize: 48),
      ),
    );
    final numberText = tester.widget<Text>(find.text('58'));
    expect(numberText.style?.fontSize, 48);
  });

  testWidgets('leaves the number unstyled when no style is given',
      (tester) async {
    await _pump(tester, const ValueReading(number: '58', word: 'middle value'));
    final numberText = tester.widget<Text>(find.text('58'));
    expect(numberText.style, isNull);
  });

  testWidgets('announces the number and word as one phrase', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const ValueReading(number: '58', word: 'middle value'));
    expect(
      tester.getSemantics(find.byType(ValueReading)).label,
      '58, middle value',
    );
    handle.dispose();
  });

  test('rejects a number-only construction (empty word)', () {
    expect(() => ValueReading(number: '58', word: ''), throwsAssertionError);
  });
}
