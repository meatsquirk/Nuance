import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/app_destinations.dart';
import 'package:paint_color_assistant/app/app_shell.dart';
import 'package:paint_color_assistant/app/theme.dart';

/// A fake destination body that records how many times it was built, so the
/// lazy-mount and keep-alive behaviour can be observed.
class _Body extends StatefulWidget {
  const _Body(this.name) : super(key: null);
  final String name;
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(widget.name, key: Key('body-${widget.name}')));
}

/// Builds the shell under the real app theme so `Theme.of` resolves.
Widget _host(Widget shell) =>
    MaterialApp(theme: AppTheme.light().themeData, home: shell);

Finder _navItem(AppDestination d) => find.byKey(d.navItemKey);

void main() {
  final bodies = <WidgetBuilder>[
    (_) => const _Body('capture'),
    (_) => const _Body('compare'),
    (_) => const _Body('recipes'),
    (_) => const _Body('palette'),
  ];

  AppShell shell({int initialIndex = 0}) => AppShell(
        destinations: AppDestination.values,
        bodies: bodies,
        initialIndex: initialIndex,
      );

  group('AppShell structure', () {
    testWidgets('renders the bottom nav with one keyed item per destination',
        (tester) async {
      await tester.pumpWidget(_host(shell()));
      expect(find.byKey(AppShell.bottomNavKey), findsOneWidget);
      for (final d in AppDestination.values) {
        expect(_navItem(d), findsOneWidget, reason: '${d.name} item present');
        expect(find.text(d.label), findsOneWidget);
      }
    });

    testWidgets('the nav fill and hairline read the theme tokens, not literals',
        (tester) async {
      await tester.pumpWidget(_host(shell()));
      final colors = AppTheme.light().colorScheme;
      final box =
          tester.widget<DecoratedBox>(find.byKey(AppShell.bottomNavKey));
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.color, colors.surfaceContainerLowest);
      expect((decoration.border! as Border).top.color, colors.outline);
    });
  });

  group('AppShell active marker (non-colour)', () {
    testWidgets('marks exactly the opening destination as active', (tester) async {
      await tester.pumpWidget(_host(shell()));
      expect(find.byKey(AppShell.activeDestinationKey), findsOneWidget);
      // The active marker is inside the Capture item and shows the FILLED glyph
      // + bold label — the non-colour indicator.
      final marker = find.byKey(AppShell.activeDestinationKey);
      expect(
        find.descendant(
            of: marker, matching: find.byIcon(AppDestination.capture.selectedIcon)),
        findsOneWidget,
      );
      final label = tester.widget<Text>(
          find.descendant(of: marker, matching: find.text('Capture')));
      expect(label.style!.fontWeight, FontWeight.w700);
      // A non-selected item shows the OUTLINE glyph.
      expect(find.byIcon(AppDestination.compare.icon), findsOneWidget);
      expect(find.byIcon(AppDestination.compare.selectedIcon), findsNothing);
    });

    testWidgets('respects a non-zero initialIndex', (tester) async {
      await tester.pumpWidget(_host(shell(initialIndex: 2)));
      final marker = find.byKey(AppShell.activeDestinationKey);
      expect(
        find.descendant(
            of: marker,
            matching: find.byIcon(AppDestination.recipes.selectedIcon)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('body-recipes')), findsOneWidget);
    });
  });

  group('AppShell lazy mount + switching', () {
    testWidgets('opens on initialIndex only; other bodies are not built',
        (tester) async {
      await tester.pumpWidget(_host(shell()));
      expect(find.byKey(const Key('body-capture')), findsOneWidget);
      // Unvisited destinations are placeholders — their bodies are not in the
      // tree at all (not merely offstage).
      expect(find.byKey(const Key('body-compare'), skipOffstage: false),
          findsNothing);
      expect(find.byKey(const Key('body-palette'), skipOffstage: false),
          findsNothing);
    });

    testWidgets('tapping a destination builds it, shows it and moves the marker',
        (tester) async {
      await tester.pumpWidget(_host(shell()));
      await tester.tap(_navItem(AppDestination.compare));
      await tester.pumpAndSettle();
      // The compare body is now built and shown; capture is kept alive offstage.
      expect(find.byKey(const Key('body-compare')), findsOneWidget);
      expect(find.byKey(const Key('body-capture'), skipOffstage: false),
          findsOneWidget);
      expect(find.byKey(const Key('body-capture')), findsNothing);
      // The active marker moved to Compare.
      final marker = find.byKey(AppShell.activeDestinationKey);
      expect(
        find.descendant(
            of: marker,
            matching: find.byIcon(AppDestination.compare.selectedIcon)),
        findsOneWidget,
      );
    });

    testWidgets('keeps a visited destination alive when switching back',
        (tester) async {
      await tester.pumpWidget(_host(shell()));
      await tester.tap(_navItem(AppDestination.compare));
      await tester.pumpAndSettle();
      await tester.tap(_navItem(AppDestination.capture));
      await tester.pumpAndSettle();
      // Both visited bodies remain in the tree; capture is shown again.
      expect(find.byKey(const Key('body-capture')), findsOneWidget);
      expect(find.byKey(const Key('body-compare'), skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('re-tapping the active destination is a no-op', (tester) async {
      await tester.pumpWidget(_host(shell()));
      await tester.tap(_navItem(AppDestination.capture));
      await tester.pumpAndSettle();
      expect(find.byKey(AppShell.activeDestinationKey), findsOneWidget);
      expect(find.byKey(const Key('body-capture')), findsOneWidget);
    });
  });

  group('AppShell invariants', () {
    test('rejects mismatched destinations/bodies lengths', () {
      expect(
        () => AppShell(
          destinations: AppDestination.values,
          bodies: [(_) => const SizedBox()],
        ),
        throwsAssertionError,
      );
    });

    test('rejects an empty destination list', () {
      expect(
        () => AppShell(destinations: const [], bodies: const []),
        throwsAssertionError,
      );
    });

    test('rejects an out-of-range initialIndex', () {
      expect(
        () => AppShell(
          destinations: AppDestination.values,
          bodies: bodies,
          initialIndex: 9,
        ),
        throwsAssertionError,
      );
    });
  });
}
