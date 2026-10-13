import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/widgets/accessible_notice.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('renders its message', (tester) async {
    await _pump(tester, const AccessibleNotice(message: 'Saved to palette'));
    expect(find.text('Saved to palette'), findsOneWidget);
  });

  testWidgets('shows a dismiss control with the default label when onDismiss '
      'is given, and invokes it', (tester) async {
    var dismissed = false;
    await _pump(
      tester,
      AccessibleNotice(
        message: 'Saved to palette',
        onDismiss: () => dismissed = true,
      ),
    );
    expect(find.widgetWithText(TextButton, 'Dismiss'), findsOneWidget);
    await tester.tap(find.byType(TextButton));
    expect(dismissed, isTrue);
  });

  testWidgets('uses a custom dismiss label when provided', (tester) async {
    await _pump(
      tester,
      AccessibleNotice(
        message: 'Saved to palette',
        dismissLabel: 'Got it',
        onDismiss: () {},
      ),
    );
    expect(find.widgetWithText(TextButton, 'Got it'), findsOneWidget);
  });

  testWidgets('shows no control when onDismiss is null', (tester) async {
    await _pump(tester, const AccessibleNotice(message: 'Saved to palette'));
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('never auto-dismisses: the message persists as time advances',
      (tester) async {
    await _pump(
      tester,
      AccessibleNotice(message: 'Saved to palette', onDismiss: () {}),
    );
    // Advance well past any typical SnackBar auto-dismiss window.
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Saved to palette'), findsOneWidget);
  });

  testWidgets('announces itself as a live region', (tester) async {
    await _pump(tester, const AccessibleNotice(message: 'Saved to palette'));
    final liveRegions = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.liveRegion ?? false);
    expect(liveRegions, isNotEmpty,
        reason: 'the notice wraps its message in a live region so a screen '
            'reader announces it when it appears');
  });

  test('rejects an empty message', () {
    expect(() => AccessibleNotice(message: ''), throwsAssertionError);
  });
}
