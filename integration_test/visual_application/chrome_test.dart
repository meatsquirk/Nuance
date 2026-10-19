// bs-18 acceptance suite — app chrome ACs (ITEST-2): AC-1 bottom navigation,
// AC-2 the shared top bar.
//
// Both drive the **real** assembled app through the single `buildApp` entry
// (the harness), reading the design-system chrome off the pumped widget tree:
// AC-1 over the CHROME-2 shell's bottom nav (present now — CHROME-3 keeps it),
// AC-2 over the shared `AppTopBar` each primary screen must mount (CHROME-4
// wires it; not yet present, so AC-2 is red at baseline). Each AC is one
// pending `acTestWidgets` test, skipped by default and run for the red baseline
// under `--dart-define=BS18_RUN_PENDING=true`.
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-1 — the design-system bottom navigation (owner CHROME-3; wireframe E44)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-1',
      'TestAC01_BottomNav: nav offers the 4 destinations with a non-colour '
      'active marker in the theme tokens', (tester) async {
    // GIVEN the app open on the default route — the nav shell renders.
    final h = await pumpShell(tester);
    expect(h.bottomNav, findsOneWidget, reason: 'Given: the bottom nav renders');

    // WHEN the chrome renders (the pump).

    // THEN the nav exposes exactly the four destinations, each by its stable
    // key (rejects a nav missing a destination).
    expect(AppDestination.values, hasLength(4));
    for (final destination in AppDestination.values) {
      expect(
        h.navItem(destination),
        findsOneWidget,
        reason: '${destination.label} destination present in the bar',
      );
    }

    // THEN the current destination carries the non-colour active marker, under
    // the opening Capture destination.
    expect(h.activeDestination, findsOneWidget);
    expect(
      find.descendant(
        of: h.navItem(AppDestination.capture),
        matching: find.byKey(AppShell.activeDestinationKey),
      ),
      findsOneWidget,
      reason: 'the shell opens on Capture, so its item is the active one',
    );

    // THEN the active state is readable without colour: the selected item shows
    // the FILLED glyph (and an unselected one shows its OUTLINE glyph), so the
    // indicator never rests on colour alone (rejects "active by colour only").
    expect(
      find.descendant(
        of: h.activeDestination,
        matching: find.byIcon(AppDestination.capture.selectedIcon),
      ),
      findsOneWidget,
      reason: 'the active destination shows its filled glyph',
    );
    expect(
      find.byIcon(AppDestination.compare.icon),
      findsOneWidget,
      reason: 'an unselected destination shows its outline glyph',
    );
    expect(
      find.byIcon(AppDestination.capture.icon),
      findsNothing,
      reason: 'the active destination does not also show the outline glyph',
    );

    // THEN the bar reads its surface + hairline colours from the installed
    // theme tokens, not a hardcoded palette (rejects a literal chrome colour).
    final bar = tester.widget<DecoratedBox>(h.bottomNav);
    final decoration = bar.decoration as BoxDecoration;
    expect(decoration.color, h.colorScheme.surfaceContainerLowest,
        reason: 'the nav fill is the theme surface token');
    expect(
      (decoration.border as Border).top.color,
      h.colorScheme.outline,
      reason: 'the nav hairline is the theme outline token',
    );
  });

  // ------------------------------------------------------------------------
  // AC-2 — the shared design-system top bar (owner CHROME-4; wireframe E1)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-2',
      'TestAC02_TopBar: every primary screen mounts the shared AppTopBar with '
      'an Atkinson title and the theme toggle', (tester) async {
    // Each primary surface the painter can be on. The shell's opening body is
    // the Readout (the Capture destination); the four deep-link screens are
    // pumped through their entry flag.
    final surfaces = <String, Future<VisualHarness> Function()>{
      'Readout (shell)': () => pumpShell(tester),
      'Capture': () => pumpScreen(tester, VisualScreen.capture),
      'Compare': () => pumpScreen(tester, VisualScreen.compare),
      'Recipes': () => pumpScreen(tester, VisualScreen.recipes),
      'Palette': () => pumpScreen(tester, VisualScreen.palette),
    };

    for (final entry in surfaces.entries) {
      final label = entry.key;
      final h = await entry.value();

      // GIVEN the app open on this destination — the screen renders (checked by
      // the presence of its single installed theme).
      expect(find.byType(MaterialApp), findsOneWidget, reason: '$label rendered');

      // WHEN the screen renders.

      // THEN it mounts exactly one shared top bar (rejects a screen left on its
      // ad-hoc header).
      expect(
        find.byType(AppTopBar),
        findsOneWidget,
        reason: '$label shows the one shared AppTopBar',
      );

      // THEN the title renders in the theme's Atkinson family, read from the
      // installed theme — not a hardcoded title style.
      final titleText = tester.widget<Text>(find.byKey(AppTopBar.titleKey));
      final titleFamily =
          titleText.style?.fontFamily ?? h.installedTheme.textTheme.titleLarge?.fontFamily;
      expect(
        titleFamily,
        contains('Atkinson'),
        reason: '$label top-bar title uses the Atkinson family',
      );
      expect(
        titleFamily,
        h.installedTheme.textTheme.titleLarge?.fontFamily,
        reason: '$label title family comes from the installed theme, not a '
            'hardcoded style',
      );

      // THEN it exposes the theme-toggle, rendered through the theme (rejects an
      // ad-hoc header without the toggle).
      expect(
        find.byKey(AppTopBar.themeToggleKey),
        findsOneWidget,
        reason: '$label top bar exposes the theme toggle',
      );
    }
  });
}
