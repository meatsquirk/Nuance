import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/widgets/mono_label.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('upper-cases its text', (tester) async {
    await _pump(tester, const MonoLabel('Measured'));
    expect(find.text('MEASURED'), findsOneWidget);
    expect(find.text('Measured'), findsNothing);
  });

  testWidgets('renders in the AppTheme mono-label style', (tester) async {
    await _pump(tester, const MonoLabel('approx'));
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style, AppTheme.monoLabel);
  });
}
