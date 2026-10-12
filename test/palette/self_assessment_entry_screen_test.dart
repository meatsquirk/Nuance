import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/palette/self_assessment_entry_screen.dart';

void main() {
  testWidgets('renders the bs-07 self-assessment entry placeholder',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SelfAssessmentEntryScreen()),
    );

    expect(find.byKey(SelfAssessmentEntryScreen.screenKey), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'CVD self-assessment'), findsOneWidget);
    expect(
      find.text('The CVD self-assessment is built in bs-07.'),
      findsOneWidget,
    );
  });
}
