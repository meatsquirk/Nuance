// Acceptance suite for bs-17 Visual design system.
//
// ITEST-1 lays the scaffold here: a never-pending smoke test proving the real
// app assembles through the one `buildApp` entry onto every primary screen with
// the single theme installed, plus guard tests over the pending gate, the
// screen roster / token fixtures, and the AC-14 source-scan helper — so the
// scaffold cannot pass vacuously. ITEST-2 registers AC-1..AC-6 and ITEST-3
// AC-7..AC-15 via `acTestWidgets` (re-exported by the harness); the behaviour
// phases un-pend each by deleting its row in `bs17/pending.dart`.
//
// Default run (`flutter test -d flutter-tester integration_test/design_system_test.dart`)
// runs these scaffold tests; `--dart-define=BS17_RUN_PENDING=true` additionally
// executes the (future) pending AC tests for the red baseline.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'design_system_harness.dart';

// ---------------------------------------------------------------------------
// WCAG 2.2 contrast ratio math (AC-4) — a verbatim mirror of bs-11's ratio math
// in `test/app/theme_test.dart` (sRGB → linear → weighted luminance; the
// order-independent `(hi+0.05)/(lo+0.05)` ratio). The AA floor constants match
// Flutter's `MinimumTextContrastGuideline`.
// ---------------------------------------------------------------------------

/// The WCAG 2.2 AA floor for normal-weight text (bs-11's `_aaNormal`).
const double _aaNormal = 4.5;

/// The relative luminance of [color] per WCAG 2.x.
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// The WCAG contrast ratio between [a] and [b] (order-independent, 1..21).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('smoke: the one theme is installed on every primary screen', () {
    for (final screen in screenRoster) {
      testWidgets('${screen.label} boots through buildApp under one theme',
          (tester) async {
        final harness = await pumpApp(tester, screen: screen);

        // The real app assembled: exactly one MaterialApp, carrying a resolved
        // theme (the shells wire end to end through the one chokepoint).
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(harness.installedTheme, isNotNull);

        // The installed theme IS the app's single AppTheme chokepoint (AC-14's
        // "one installed theme"): identical colour scheme and text theme, not a
        // per-screen scheme. (Values are stock-derived until THEME-3/4 fill the
        // warm-paper tokens; this asserts the *source*, not the values.)
        final chokepoint = AppTheme.light().themeData;
        expect(harness.colorScheme, chokepoint.colorScheme);
        expect(harness.textTheme, chokepoint.textTheme);

        // Opening a screen renders quietly — nothing auto-speaks or buzzes.
        expect(harness.speech.utterances, isEmpty);
        expect(harness.haptics.confirmations, 0);
      });
    }
  });

  group('pending gate', () {
    test(
        'covers exactly AC-1..AC-15, each owned by a real behaviour phase, all '
        'pending at ITEST-1', () {
      expect(pendingACs, hasLength(15));
      for (var n = 1; n <= 15; n++) {
        expect(pendingACs.containsKey('AC-$n'), isTrue,
            reason: 'AC-$n must be pending at ITEST-1 (no behaviour built yet)');
      }
      // No stray keys outside AC-1..AC-15, and every owner is a real phase.
      for (final entry in pendingACs.entries) {
        final match = RegExp(r'^AC-(\d+)$').firstMatch(entry.key);
        expect(match, isNotNull, reason: 'unexpected pending key ${entry.key}');
        expect(int.parse(match!.group(1)!), inInclusiveRange(1, 15));
        expect(behaviorPhases, contains(entry.value),
            reason: '${entry.key} names unknown phase "${entry.value}"');
      }
    });

    test('hides a pending AC by default and admits it under the run-pending flag',
        () {
      for (final ac in const ['AC-1', 'AC-15']) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending and must be skipped in the default run');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac must execute under --dart-define=BS17_RUN_PENDING=true');
      }
      // An AC absent from the map always runs, in either mode (the un-pended
      // end state a behaviour phase reaches by deleting the row).
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
      // The ambient path acTestWidgets uses agrees with the current mode.
      expect(
        pendingSkipReason('AC-1'),
        pendingSkipReason('AC-1', forceRunPending: runPending),
      );
    });
  });

  group('fixtures', () {
    test('the screen roster is every primary screen, non-empty', () {
      expect(screenRoster, DesignScreen.values);
      expect(screenRoster, isNotEmpty);
    });

    test('the warm-paper surface / ink / accent roles are distinct colours', () {
      expect(WarmPaper.all, hasLength(8));
      // The seven semantic roles are distinct — the accent label colour
      // (accentInk) is deliberately white, the same as the raised surface, so
      // it is excluded from the distinctness claim.
      const roles = [
        WarmPaper.background,
        WarmPaper.surface,
        WarmPaper.sunken,
        WarmPaper.ink,
        WarmPaper.muted,
        WarmPaper.line,
        WarmPaper.accent,
      ];
      expect(roles.toSet(), hasLength(roles.length),
          reason: 'no palette role may share another role\'s value');
      // The accent label is white (reused surface white), by design.
      expect(WarmPaper.accentInk, WarmPaper.surface);
    });
  });

  group('AC-14 source-scan helper', () {
    test('flags a planted palette literal, honours exemptions and masking', () {
      final dir = Directory.systemTemp.createTempSync('bs17_scan');
      try {
        final planted = File('${dir.path}/planted.dart')
          ..writeAsStringSync(
            "import 'dart:ui';\n"
            '// Color(0xDEADBEEF) in a comment must be ignored\n'
            'const c = Color(0xFF123456);\n'
            "const s = 'Color(0xFF000000) in a string must be ignored';\n",
          );

        // The real code literal on line 3 is the only hit — comment and string
        // occurrences are masked out.
        final hits = residualPaletteLiterals(roots: [dir.path]);
        expect(hits, hasLength(1));
        expect(hits.single.line, 3);
        expect(hits.single.rule, ruleHardcodedPalette);

        // Exempting the file silences it (the theme authority / D-4 path).
        expect(
          residualPaletteLiterals(roots: [dir.path], exempt: {planted.path}),
          isEmpty,
        );

        // A missing root contributes nothing.
        expect(residualPaletteLiterals(roots: ['${dir.path}/nope']), isEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('detects fromARGB and fromRGBO constructors too', () {
      final dir = Directory.systemTemp.createTempSync('bs17_scan_ctors');
      try {
        File('${dir.path}/ctors.dart').writeAsStringSync(
          'final a = Color.fromARGB(255, 1, 2, 3);\n'
          'final b = Color.fromRGBO(1, 2, 3, 1.0);\n',
        );
        final hits = residualPaletteLiterals(roots: [dir.path]);
        expect(hits.map((h) => h.line), containsAll(const [1, 2]));
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });

  // -------------------------------------------------------------------------
  // AC tests (ITEST-2: AC-1..AC-6) — one pending test per AC, registered
  // through `acTestWidgets`, so the default run skips them and
  // `--dart-define=BS17_RUN_PENDING=true` executes them (the red baseline).
  //
  // Each reads what the real assembled app renders through `pumpApp` and the one
  // installed theme (`Theme.of` — the single chokepoint; D-7). The token/font
  // values are the wireframe `WarmPaper`/Atkinson targets the behaviour phases
  // (THEME-3/4) make true; at baseline the stock scheme/type do not match, so
  // each fails on its Then (or, for AC-4, on the Given precondition that names
  // its owning phase). Un-pend = delete the AC's row in `bs17/pending.dart`.
  // -------------------------------------------------------------------------

  group('Rule: the warm-paper palette is the single source of surface and ink',
      () {
    // # UX: THEME tokens --bg #F3F1EC, --sf #FFFFFF, --sf2 #E9E6DF
    acTestWidgets('AC-1', 'Surfaces use the warm-paper palette',
        (tester) async {
      // Given any screen is shown — pump the readout screen and confirm the one
      // theme resolves and the screen actually rendered content.
      final harness = await pumpApp(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(harness.installedTheme, isNotNull,
          reason: 'the screen must render with the installed theme resolved');
      expect(find.byType(Scaffold), findsWidgets,
          reason: 'the ${harness.screen.label} screen must render a surface');

      // When its surfaces are rendered — read the installed ColorScheme (the
      // single chokepoint every screen inherits).
      final cs = harness.colorScheme;

      // Then the background is the warm paper tone, raised surfaces are the
      // paper white and sunken surfaces are the muted paper tone, all from the
      // theme — the three surface roles equal the warm-paper tokens exactly.
      expect(cs.surface, WarmPaper.background,
          reason: 'scaffold surface must be the warm paper background --bg');
      expect(cs.surfaceContainerLowest, WarmPaper.surface,
          reason: 'raised surfaces must be the paper white --sf');
      expect(cs.surfaceContainer, WarmPaper.sunken,
          reason: 'sunken surfaces must be the muted paper tone --sf2');
      // Rejects a scheme that leaves the stock M3 surfaces in place.
      final stock = ThemeData(useMaterial3: true).colorScheme;
      expect(cs.surface, isNot(stock.surface),
          reason: 'must not keep the stock M3 surface');
    });

    // # UX: THEME tokens --ink #16150F, --mut #57544C, --ln #CFCAC0
    acTestWidgets(
        'AC-2', 'Ink, muted text and hairlines use the warm-paper neutrals',
        (tester) async {
      // Given a screen shows text and dividers — the readout screen renders
      // text; the installed theme resolves.
      final harness = await pumpApp(tester);
      expect(find.byType(Text), findsWidgets,
          reason: 'the screen must show text');
      final cs = harness.colorScheme;

      // When they are rendered → Then primary text uses the near-black ink,
      // secondary text the warm grey, and dividers the paper hairline, all from
      // the theme.
      expect(cs.onSurface, WarmPaper.ink,
          reason: 'primary text must be the near-black ink --ink');
      expect(cs.onSurfaceVariant, WarmPaper.muted,
          reason: 'secondary text must be the warm grey --mut');
      expect(cs.outline, WarmPaper.line,
          reason: 'dividers must be the paper hairline --ln');
      expect(cs.outlineVariant, WarmPaper.line,
          reason: 'hairline outlineVariant must be the paper hairline --ln');
      // Rejects stock onSurface/outline neutrals.
      final stock = ThemeData(useMaterial3: true).colorScheme;
      expect(cs.onSurface, isNot(stock.onSurface),
          reason: 'must not keep the stock M3 onSurface');
      expect(cs.outline, isNot(stock.outline),
          reason: 'must not keep the stock M3 outline');
    });

    // # UX: THEME token --acc (oklch 0.48 0.16 262 ≈ #2F55C8) / --accInk #FFFFFF
    acTestWidgets('AC-3', 'The primary action colour is the cobalt accent',
        (tester) async {
      // Given a screen shows its primary call-to-action surface → When rendered.
      final harness = await pumpApp(tester);
      final cs = harness.colorScheme;

      // Then it is filled with the cobalt accent and its label is white, from
      // the theme.
      expect(cs.primary, WarmPaper.accent,
          reason: 'the primary CTA colour must be the cobalt accent --acc');
      expect(cs.onPrimary, WarmPaper.accentInk,
          reason: 'the accent label must be white --accInk');
      // Rejects the stock M3 primary.
      final stock = ThemeData(useMaterial3: true).colorScheme;
      expect(cs.primary, isNot(stock.primary),
          reason: 'must not keep the stock M3 primary');
    });

    // # UX: the skin must stay within bs-11's floor — references, does not restate
    acTestWidgets('AC-4',
        'The warm-paper palette still meets the accessibility contrast floor',
        (tester) async {
      final harness = await pumpApp(tester);
      final cs = harness.colorScheme;

      // Given the warm-paper theme is installed — a precondition that THEME-3
      // owns: the installed scheme IS the warm-paper scheme. At baseline (stock
      // M3) this fails HERE, naming THEME-3, which is the expected red-baseline
      // failure for this pending test.
      expect(cs.surface, WarmPaper.background,
          reason: 'precondition (THEME-3): warm-paper surface installed');
      expect(cs.onSurface, WarmPaper.ink,
          reason: 'precondition (THEME-3): warm-paper ink installed');
      expect(cs.primary, WarmPaper.accent,
          reason: 'precondition (THEME-3): warm-paper accent installed');

      // When every meaningful text-on-surface pairing is measured (bs-11's
      // WCAG ratio math over the installed warm-paper tokens) → Then each still
      // clears the AA floor bs-11 requires (4.5:1 normal text).
      final pairings = <String, List<Color>>{
        'ink / background': [cs.onSurface, cs.surface],
        'ink / paper-white': [cs.onSurface, cs.surfaceContainerLowest],
        'ink / sunken': [cs.onSurface, cs.surfaceContainer],
        'muted / background': [cs.onSurfaceVariant, cs.surface],
        'muted / paper-white': [cs.onSurfaceVariant, cs.surfaceContainerLowest],
        'muted / sunken': [cs.onSurfaceVariant, cs.surfaceContainer],
        'accentInk / accent': [cs.onPrimary, cs.primary],
      };
      pairings.forEach((label, pair) {
        final ratio = _contrast(pair[0], pair[1]);
        expect(ratio, greaterThanOrEqualTo(_aaNormal),
            reason: '$label is ${ratio.toStringAsFixed(2)}:1 — below AA '
                '$_aaNormal:1 (a warm-paper edit dropped a pairing)');
      });
      // Sanity: the floor is the WCAG 2.2 AA normal-text value.
      expect(_aaNormal, 4.5);
    });
  });

  group('Rule: Atkinson Hyperlegible is the app\'s typeface', () {
    const nextFamily = 'Atkinson Hyperlegible Next';
    const monoFamily = 'Atkinson Hyperlegible Mono';

    // # UX: font-family 'Atkinson Hyperlegible Next' on prose, headings, labels
    acTestWidgets('AC-5', 'Prose and headings render in Atkinson Hyperlegible Next',
        (tester) async {
      // Given a screen shows headings and body text — the readout screen
      // renders prose Text through the one theme.
      final harness = await pumpApp(tester);
      expect(find.byType(Text), findsWidgets,
          reason: 'the screen must show headings and body text');
      final tt = harness.textTheme;

      // When they are rendered → Then they use the Atkinson Hyperlegible Next
      // family from the theme — every prose/heading role of the installed
      // TextTheme carries the Next family. (The mono label/readout roles are
      // AC-6's; they are not asserted here.)
      final proseStyles = <String, TextStyle?>{
        'displayLarge': tt.displayLarge,
        'headlineMedium': tt.headlineMedium,
        'headlineSmall': tt.headlineSmall,
        'titleLarge': tt.titleLarge,
        'titleMedium': tt.titleMedium,
        'bodyLarge': tt.bodyLarge,
        'bodyMedium': tt.bodyMedium,
        'bodySmall': tt.bodySmall,
      };
      proseStyles.forEach((role, style) {
        expect(style?.fontFamily, nextFamily,
            reason: 'TextTheme.$role must render in $nextFamily');
      });
      // Rejects the stock default (Roboto/SF — a null/non-Atkinson family).
      expect(tt.bodyLarge?.fontFamily, isNot(isNull),
          reason: 'must not leave the stock platform-default family');
    });

    // # UX: font-family 'Atkinson Hyperlegible Mono' on micro-labels and readouts
    acTestWidgets('AC-6',
        'Micro-labels and numeric readouts render in Atkinson Hyperlegible Mono',
        (tester) async {
      // Given a screen shows a micro-label or a numeric readout — the mono
      // micro-label style is the single source (AppTheme.monoLabel, D-7) that
      // MonoLabel and numeric readouts render from. (Nothing renders a MonoLabel
      // on a screen until the APPLY phases, so this reads that single theme
      // source rather than a not-yet-mounted instance.)
      final harness = await pumpApp(tester);
      expect(harness.installedTheme, isNotNull);

      // When it is rendered → Then it uses the Atkinson Hyperlegible Mono family
      // from the theme.
      expect(AppTheme.monoLabel.fontFamily, monoFamily,
          reason: 'the mono micro-label style must be in $monoFamily');
      // Rejects a label left in the sans family: the mono source must NOT be
      // the prose Next family, and must not be the stock (null) default.
      expect(AppTheme.monoLabel.fontFamily, isNot(nextFamily),
          reason: 'the mono style must not be the prose Next family');
      expect(AppTheme.monoLabel.fontFamily, isNot(isNull),
          reason: 'must not leave the stock platform-default family');
    });
  });
}
