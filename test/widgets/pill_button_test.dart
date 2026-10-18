import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/widgets/pill_button.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

/// Pumps [child] through the production warm-paper theme, so the pill resolves
/// the real colour scheme (as the app installs it).
Future<void> _pumpThemed(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(theme: AppTheme.light().themeData, home: Scaffold(body: child)),
  );
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

  testWidgets('primary is ink-filled with a paper label at the heavy weight',
      (tester) async {
    final cs = AppTheme.light().themeData.colorScheme;
    await _pumpThemed(
      tester,
      PillButton.primary(onPressed: () {}, child: const Text('Save')),
    );
    final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
    const states = <WidgetState>{};
    expect(style.backgroundColor?.resolve(states), cs.onSurface,
        reason: 'primary fills with ink (onSurface), not the accent');
    expect(style.foregroundColor?.resolve(states), cs.surface,
        reason: 'primary label is paper-coloured (surface)');
    expect(style.textStyle?.resolve(states)?.fontWeight, FontWeight.w800,
        reason: 'primary label carries the heavy weight 800');
  });

  testWidgets('secondary is transparent with an ink label', (tester) async {
    final cs = AppTheme.light().themeData.colorScheme;
    await _pumpThemed(
      tester,
      PillButton.secondary(onPressed: () {}, child: const Text('Cancel')),
    );
    final style =
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;
    const states = <WidgetState>{};
    expect(style.backgroundColor?.resolve(states), Colors.transparent,
        reason: 'secondary carries no fill');
    expect(style.foregroundColor?.resolve(states), cs.onSurface,
        reason: 'secondary label is ink (onSurface)');
  });
}
