import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/widgets/mono_label.dart';
import 'package:paint_color_assistant/widgets/swatch_caption.dart';

Future<void> _pump(WidgetTester tester, {ThemeData? theme}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(body: SwatchCaption()),
    ),
  );
}

void main() {
  testWidgets('says the swatch is an approximation and the numbers authoritative',
      (tester) async {
    await _pump(tester, theme: AppTheme.light().themeData);
    // The explanatory line carries the approximation message verbatim.
    expect(find.text(SwatchCaption.message), findsOneWidget);
    expect(SwatchCaption.message.toLowerCase(), contains('approximation'));
    expect(SwatchCaption.message.toLowerCase(), contains('numbers'));
  });

  testWidgets('carries the APPROX. mono eyebrow through MonoLabel', (tester) async {
    await _pump(tester, theme: AppTheme.light().themeData);
    expect(find.byType(MonoLabel), findsOneWidget);
    // MonoLabel renders its text upper-cased.
    expect(find.text('APPROX.'), findsOneWidget);
    final mono = tester.widget<MonoLabel>(find.byType(MonoLabel));
    expect(mono.text, SwatchCaption.tag);
  });

  testWidgets('reads once: one semantics node labelled with the whole message',
      (tester) async {
    await _pump(tester, theme: AppTheme.light().themeData);
    final semantics = tester.widget<Semantics>(
      find.byKey(SwatchCaption.captionKey),
    );
    expect(semantics.properties.label, SwatchCaption.message);
    // The parts below are folded away — the screen reader announces the
    // caption a single time rather than the tag and the line separately.
    expect(semantics.excludeSemantics, isTrue);
  });

  testWidgets('draws the explanatory line in the muted secondary-text role',
      (tester) async {
    final theme = AppTheme.light().themeData;
    await _pump(tester, theme: theme);
    final line = tester.widget<Text>(find.text(SwatchCaption.message));
    // The explanatory line is the muted secondary-text role, derived from the
    // theme's small-body style (not a hardcoded colour — AC-14).
    expect(line.style?.color, theme.colorScheme.onSurfaceVariant);
    expect(line.style, isNotNull);
  });

  testWidgets('renders standalone under a bare theme (bodySmall may be sparse)',
      (tester) async {
    // No explicit theme: the stock default still has a bodySmall style, so the
    // caption renders its message and tag without an enclosing app theme.
    await _pump(tester);
    expect(find.text(SwatchCaption.message), findsOneWidget);
    expect(find.text('APPROX.'), findsOneWidget);
  });
}
