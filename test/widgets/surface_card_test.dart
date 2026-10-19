import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/widgets/surface_card.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeData? theme}) {
  return tester.pumpWidget(
    MaterialApp(theme: theme, home: Scaffold(body: child)),
  );
}

BoxDecoration _decoration(WidgetTester tester) {
  final container = tester.widget<Container>(find.byType(Container));
  return container.decoration! as BoxDecoration;
}

void main() {
  final scheme = ThemeData(useMaterial3: true).colorScheme;

  testWidgets('ordinary: surface fill with a line-colour border at the standard weight',
      (tester) async {
    await _pump(tester, const SurfaceCard(child: Text('panel')));
    final d = _decoration(tester);
    expect(d.color, scheme.surface);
    final border = d.border! as Border;
    expect(border.top.color, scheme.outlineVariant);
    expect(border.top.width, AppTheme.standardBorderWidth);
    expect(find.text('panel'), findsOneWidget);
  });

  testWidgets('emphasis: surface fill with a standard-weight ink border',
      (tester) async {
    await _pump(tester, const SurfaceCard.emphasis(child: Text('warn')));
    final d = _decoration(tester);
    expect(d.color, scheme.surface);
    final border = d.border! as Border;
    expect(border.top.color, scheme.onSurface);
    expect(border.top.width, AppTheme.standardBorderWidth);
  });

  testWidgets('inverted: ink fill, no border, paper-coloured text',
      (tester) async {
    await _pump(tester, const SurfaceCard.inverted(child: Text('hero')));
    final d = _decoration(tester);
    expect(d.color, AppTheme.inverted.paper);
    expect(d.border, isNull);
    final text = tester.widget<Text>(find.text('hero'));
    // The inverted variant injects the paper ink as the default text colour.
    final style = DefaultTextStyle.of(
      tester.element(find.text('hero')),
    ).style;
    expect(style.color, AppTheme.inverted.ink);
    expect(text.style, isNull);
  });

  testWidgets('defaults to a 16px radius when the card theme sets no shape',
      (tester) async {
    await _pump(tester, const SurfaceCard(child: Text('panel')));
    expect(_decoration(tester).borderRadius, BorderRadius.circular(16));
  });

  testWidgets('adopts the card theme radius when one is set', (tester) async {
    final theme = ThemeData(
      useMaterial3: true,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
    await _pump(tester, const SurfaceCard(child: Text('panel')), theme: theme);
    expect(
      _decoration(tester).borderRadius,
      const BorderRadius.all(Radius.circular(20)),
    );
  });
}
