import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/app_top_bar.dart';
import 'package:paint_color_assistant/app/theme.dart';

Widget _host(AppTopBar bar) => MaterialApp(
      theme: AppTheme.light().themeData,
      home: Scaffold(appBar: bar, body: const SizedBox()),
    );

void main() {
  group('AppTopBar', () {
    testWidgets('renders the title in the theme title style (Atkinson)',
        (tester) async {
      await tester.pumpWidget(_host(const AppTopBar(title: 'Readout')));
      final title = tester.widget<Text>(find.byKey(AppTopBar.titleKey));
      // The ambient, fully-resolved titleLarge (MaterialApp fills in the
      // geometry the raw AppTheme textTheme leaves null).
      final ambientTitleLarge = Theme.of(
        tester.element(find.byKey(AppTopBar.titleKey)),
      ).textTheme.titleLarge;
      expect(title.data, 'Readout');
      // The title uses the theme's titleLarge rendered in the Atkinson family
      // (AC-2), not a hardcoded style.
      expect(title.style, ambientTitleLarge);
      expect(title.style!.fontFamily, AppTheme.nextFamily);
    });

    testWidgets('shows no leading affordance and no toggle by default',
        (tester) async {
      await tester.pumpWidget(_host(const AppTopBar(title: 'Palette')));
      expect(find.byKey(AppTopBar.leadingKey), findsNothing);
      expect(find.byKey(AppTopBar.themeToggleKey), findsNothing);
    });

    testWidgets('shows a back affordance that calls onBack', (tester) async {
      var backs = 0;
      await tester.pumpWidget(
          _host(AppTopBar(title: 'Compare', onBack: () => backs++)));
      expect(
        find.descendant(
            of: find.byKey(AppTopBar.leadingKey),
            matching: find.byIcon(Icons.arrow_back)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(AppTopBar.leadingKey));
      expect(backs, 1);
    });

    testWidgets('shows a close affordance that calls onClose', (tester) async {
      var closes = 0;
      await tester.pumpWidget(
          _host(AppTopBar(title: 'Settings', onClose: () => closes++)));
      expect(
        find.descendant(
            of: find.byKey(AppTopBar.leadingKey),
            matching: find.byIcon(Icons.close)),
        findsOneWidget,
      );
      await tester.tap(find.byKey(AppTopBar.leadingKey));
      expect(closes, 1);
    });

    testWidgets('mounts the supplied theme-toggle control', (tester) async {
      await tester.pumpWidget(_host(
        AppTopBar(
          title: 'Recipes',
          themeToggle: IconButton(
            key: const Key('toggle-control'),
            icon: const Icon(Icons.brightness_6),
            onPressed: () {},
          ),
        ),
      ));
      expect(find.byKey(AppTopBar.themeToggleKey), findsOneWidget);
      expect(
        find.descendant(
            of: find.byKey(AppTopBar.themeToggleKey),
            matching: find.byKey(const Key('toggle-control'))),
        findsOneWidget,
      );
    });

    test('rejects showing both a back and a close affordance', () {
      expect(
        () => AppTopBar(title: 'x', onBack: () {}, onClose: () {}),
        throwsAssertionError,
      );
    });
  });
}
