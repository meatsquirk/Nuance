import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/main.dart' as app;

void main() {
  testWidgets('app renders the placeholder home', (tester) async {
    await tester.pumpWidget(const app.PaintColorAssistantApp());
    expect(find.text('Paint Color Assistant'), findsOneWidget);
  });

  testWidgets('main() boots the app without error', (tester) async {
    // Exercises the main() entry point so the scaffold has full line coverage.
    app.main();
    await tester.pump();
    expect(find.byType(app.PaintColorAssistantApp), findsOneWidget);
  });
}
