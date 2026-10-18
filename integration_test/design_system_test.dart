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
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';
import 'package:paint_color_assistant/widgets/provenance_icon.dart';

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

// ---------------------------------------------------------------------------
// ITEST-3 helpers (AC-7..AC-13): mount a styled component through the single
// production theme, and read what it renders.
//
// No screen mounts `PillButton`/`SpeakButton`/`SurfaceCard`/`MonoLabel`/the
// provenance badge until the APPLY phases, so each component AC mounts its
// widget here through the one `AppTheme.light()` chokepoint (the exact
// `ThemeData` `buildApp` installs; D-7) and reads the resolved geometry /
// decoration — exactly what production renders. THEME-3's warm-paper scheme and
// THEME-5's shape/border themes flow in through `AppTheme.light()`, so these
// tests go green only once both the theme and the component treatment land
// (which is why the component behaviour phases depend on THEME-3).
// ---------------------------------------------------------------------------

/// Wraps [child] in the production app theme (the single `AppTheme.light()`
/// chokepoint) on a Scaffold, for a component to render through.
Widget _themed(Widget child) => MaterialApp(
      theme: AppTheme.light().themeData,
      home: Scaffold(body: Center(child: child)),
    );

/// The [Material] a `ButtonStyleButton` ([FilledButton]/[OutlinedButton])
/// renders: its `color` is the resolved background and its `shape` the resolved
/// [OutlinedBorder] with the side folded in.
Material _buttonMaterial(WidgetTester tester, Finder button) =>
    tester.widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)),
    );

/// The [BoxDecoration] of the [Container] a [SurfaceCard] renders.
BoxDecoration _cardDecoration(WidgetTester tester, Finder card) =>
    tester
        .widget<Container>(
          find.descendant(of: card, matching: find.byType(Container)),
        )
        .decoration! as BoxDecoration;

/// A colour-independent descriptor of a provenance badge's visual signature:
/// whether, beyond the glyph and label, it draws a border, a fill, or a custom
/// (e.g. dashed) paint. The glyph+text badge carries none of these until
/// COMPONENTS-5 adds the border-style signature.
typedef _Signature = ({bool border, bool fill, bool custom});

/// Walks the [badge] subtree and reports its colour-independent [_Signature].
_Signature _badgeSignature(WidgetTester tester, Finder badge) {
  var border = false;
  var fill = false;
  var custom = false;
  void visit(Element e) {
    final w = e.widget;
    Decoration? dec;
    if (w is Container) {
      dec = w.decoration;
    } else if (w is DecoratedBox) {
      dec = w.decoration;
    }
    if (dec is BoxDecoration) {
      if (dec.border != null) border = true;
      if (dec.color != null) fill = true;
    } else if (dec is ShapeDecoration) {
      if (dec.color != null) fill = true;
      final shape = dec.shape;
      if (shape is OutlinedBorder &&
          shape.side.style != BorderStyle.none &&
          shape.side.width > 0) {
        border = true;
      }
    }
    if (w is CustomPaint && w.painter != null) custom = true;
    e.visitChildren(visit);
  }

  visit(tester.element(badge));
  return (border: border, fill: fill, custom: custom);
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
        'covers the 15 ACs — AC-1..AC-6 un-pended (THEME-3/4), the rest pending '
        'and owned by a real behaviour phase', () {
      // THEME-3 un-pended AC-1..AC-4 and THEME-4 AC-5..AC-6 by deleting their
      // rows. Each behaviour phase extends this set as it lands; when it reaches
      // all 15 the pending map is empty.
      const unpended = {'AC-1', 'AC-2', 'AC-3', 'AC-4', 'AC-5', 'AC-6'};
      for (final ac in unpended) {
        expect(pendingACs.containsKey(ac), isFalse,
            reason: '$ac is un-pended (THEME-3/4) and must run by default');
      }
      // The pending map is exactly AC-1..AC-15 minus the un-pended ACs — a
      // stray or re-pended key fails here.
      final allACs = {for (var n = 1; n <= 15; n++) 'AC-$n'};
      expect(pendingACs.keys.toSet(), allACs.difference(unpended));
      expect(pendingACs, hasLength(15 - unpended.length));
      // Every remaining key is a real AC-1..AC-15 owned by a real phase.
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
      for (final ac in const ['AC-7', 'AC-15']) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending and must be skipped in the default run');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac must execute under --dart-define=BS17_RUN_PENDING=true');
      }
      // An un-pended AC (AC-1 THEME-3, AC-5 THEME-4 deleted their rows) always
      // runs, in either mode — as does an AC that was never in the map.
      for (final ac in const ['AC-1', 'AC-5', 'AC-unmapped']) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNull,
            reason: '$ac is un-pended and runs by default');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull);
      }
      // The ambient path acTestWidgets uses agrees with the current mode.
      expect(
        pendingSkipReason('AC-7'),
        pendingSkipReason('AC-7', forceRunPending: runPending),
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

  // -------------------------------------------------------------------------
  // AC tests (ITEST-3: AC-7..AC-15) — one pending test per AC, appended to the
  // same file, registered through `acTestWidgets` (default run skips them;
  // `--dart-define=BS17_RUN_PENDING=true` runs them for the red baseline).
  //
  // AC-7..AC-9 read the one installed theme (shape/border/mono-label, made true
  // at the ThemeData level by THEME-5; D-7). AC-10..AC-13 mount the real styled
  // component through the production `AppTheme.light()` chokepoint and read what
  // it renders (the component behaviour phases finalise the treatment).
  // AC-14/AC-15 walk the real screens through `pumpApp`. Un-pend = delete the
  // AC's row in `bs17/pending.dart`.
  // -------------------------------------------------------------------------

  group('Rule: shape and weight follow the wireframe scale', () {
    // # UX: pills fully rounded at half-height; cards radius 16–22; frame 44
    acTestWidgets(
        'AC-7', 'Buttons render as fully-rounded pills and cards as rounded panels',
        (tester) async {
      // Given a screen shows buttons and cards → the one installed theme
      // resolves (the shape tokens the pill/card components inherit; D-7).
      final harness = await pumpApp(tester);
      final installed = harness.installedTheme;

      // When they are rendered → Then each button is a fully-rounded pill and
      // each card has the rounded-panel corner radius, from the theme's shape
      // tokens. The pill buttons (FilledButton/OutlinedButton) inherit a
      // StadiumBorder; the card radius comes from `cardTheme` (16–22).
      final filledShape = installed.filledButtonTheme.style?.shape
          ?.resolve(const <WidgetState>{});
      expect(filledShape, isA<StadiumBorder>(),
          reason: 'the primary pill must be fully rounded (StadiumBorder) from '
              'the theme — stock M3 is a RoundedRectangleBorder (~r20)');
      final outlinedShape = installed.outlinedButtonTheme.style?.shape
          ?.resolve(const <WidgetState>{});
      expect(outlinedShape, isA<StadiumBorder>(),
          reason: 'the secondary pill must be fully rounded (StadiumBorder)');

      final cardShape = installed.cardTheme.shape;
      expect(cardShape, isA<RoundedRectangleBorder>(),
          reason: 'cards must be rounded panels from the theme (stock card is '
              'unset → the default r12)');
      final radius = (cardShape! as RoundedRectangleBorder)
          .borderRadius
          .resolve(TextDirection.ltr)
          .topLeft
          .x;
      expect(radius, inInclusiveRange(16, 22),
          reason: 'the card corner radius must be in the wireframe 16–22 range, '
              'was $radius');
    });

    // # UX: border widths 1px hairline / 2px standard / 3px emphasis
    acTestWidgets('AC-8', 'Borders follow the weight scale', (tester) async {
      // Given a screen shows bordered elements → the one installed theme
      // resolves (THEME-5 wires the weight scale into the component themes).
      final harness = await pumpApp(tester);
      final installed = harness.installedTheme;

      // When their borders are rendered → Then hairline dividers are thin,
      // standard cards and buttons use the medium weight, and emphasis/warning
      // elements use the heavy weight — the theme wires 1/2/3 where each
      // applies.
      expect(installed.dividerTheme.thickness, AppTheme.hairlineBorderWidth,
          reason: 'hairline dividers must be the 1px weight from the theme '
              '(stock leaves it unset)');
      final side = installed.outlinedButtonTheme.style?.side
          ?.resolve(const <WidgetState>{});
      expect(side?.width, AppTheme.standardBorderWidth,
          reason: 'the standard (outlined pill) border must be the 2px medium '
              'weight from the theme');
      // The heavy emphasis weight is available as the design token (3px).
      expect(AppTheme.emphasisBorderWidth, 3.0,
          reason: 'the emphasis/warning weight must be the 3px heavy weight');
      // Control: the scale is strictly increasing and distinct (1 < 2 < 3), so
      // a flat / uniform-width impl is rejected.
      expect(
          AppTheme.hairlineBorderWidth < AppTheme.standardBorderWidth, isTrue);
      expect(
          AppTheme.standardBorderWidth < AppTheme.emphasisBorderWidth, isTrue);
    });

    // # UX: mono micro-label — 700, letter-spacing .06em, uppercase
    acTestWidgets(
        'AC-9', 'Monospace micro-labels render uppercase with wide letter-spacing',
        (tester) async {
      // Given a screen shows a monospace micro-label → mount a MonoLabel
      // through the production theme (natural-case input; the widget is the
      // single public surface for the mono micro-label treatment).
      await tester.pumpWidget(_themed(const MonoLabel('srgb')));
      await tester.pumpAndSettle();

      // When it is rendered → Then its text is uppercase, bold and widely
      // letter-spaced. Upper-casing is the widget's own contract (a control
      // that rejects a mixed-case label); the weight and tracking come from the
      // mono-label style THEME-5 fills.
      expect(find.text('SRGB'), findsOneWidget,
          reason: 'the micro-label must be upper-cased ("srgb" → "SRGB")');
      expect(find.text('srgb'), findsNothing,
          reason: 'the natural-case text must not render un-cased');
      final style = tester.widget<Text>(find.text('SRGB')).style!;
      expect(style.fontWeight, FontWeight.w700,
          reason: 'the mono micro-label must be bold (700) — stock labelSmall '
              'is not');
      final size = style.fontSize!;
      expect(style.letterSpacing! / size, closeTo(0.06, 0.012),
          reason: 'the mono micro-label must be tracked at ≈ .06em·fontSize');
    });
  });

  group('Rule: the core components carry the wireframe treatment', () {
    // # UX: primary = ink-fill pill (weight 800); secondary = outline pill (ink/line)
    acTestWidgets(
        'AC-10',
        'Primary actions render as ink-filled pills and secondary as outline pills',
        (tester) async {
      final cs = AppTheme.light().themeData.colorScheme;

      // Given a screen shows a primary action → mount the primary pill.
      await tester.pumpWidget(
        _themed(PillButton.primary(onPressed: () {}, child: const Text('Primary'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget);

      // When it is rendered → Then the primary action is an ink-filled pill:
      // an ink (onSurface) background with a paper (surface) label and no
      // border. (Stock FilledButton fills with the accent `primary`, so this
      // fails at baseline.)
      final primaryMat = _buttonMaterial(tester, find.byType(FilledButton));
      expect(primaryMat.color, cs.onSurface,
          reason: 'the primary pill must be ink-filled (onSurface), not the '
              'accent/primary fill');
      expect(effectiveTextStyleOf(tester, find.text('Primary')).color,
          cs.surface,
          reason: 'the primary pill label must be paper-coloured (surface)');
      final primaryShape = primaryMat.shape;
      if (primaryShape is OutlinedBorder) {
        expect(
            primaryShape.side.style == BorderStyle.none ||
                primaryShape.side.width == 0,
            isTrue,
            reason: 'the primary (filled) pill carries no border');
      }

      // Given a screen shows a secondary action → mount the secondary pill.
      await tester.pumpWidget(
        _themed(
            PillButton.secondary(onPressed: () {}, child: const Text('Secondary'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OutlinedButton), findsOneWidget);

      // Then the secondary action is a transparent pill with an ink border and
      // an ink label.
      final secondaryMat = _buttonMaterial(tester, find.byType(OutlinedButton));
      expect(secondaryMat.color == null || secondaryMat.color == Colors.transparent,
          isTrue,
          reason: 'the secondary pill must be transparent (no fill)');
      final secondaryShape = secondaryMat.shape;
      expect(secondaryShape, isA<OutlinedBorder>());
      expect((secondaryShape! as OutlinedBorder).side.width,
          AppTheme.standardBorderWidth,
          reason: 'the secondary pill carries the 2px standard border');
      expect((secondaryShape as OutlinedBorder).side.color, cs.onSurface,
          reason: 'the secondary pill border is ink (onSurface)');
      expect(effectiveTextStyleOf(tester, find.text('Secondary')).color,
          cs.onSurface,
          reason: 'the secondary pill label is ink (onSurface)');

      // Rejects a colour-swapped-only pair: the primary fill (ink) must differ
      // from the secondary's (transparent) treatment.
      expect(primaryMat.color, isNot(secondaryMat.color),
          reason: 'the two pill variants must not render identically');
    });

    // # UX: round accent FAB with speaker-wave glyph (sizes 64/52/44)
    acTestWidgets('AC-11', 'The speak action renders as a round accent floating button',
        (tester) async {
      final cs = AppTheme.light().themeData.colorScheme;

      // Given a screen offers spoken output → mount its speak control.
      await tester.pumpWidget(
        _themed(SpeakButton(onPressed: () {}, semanticLabel: 'Speak')),
      );
      await tester.pumpAndSettle();

      // When its speak control is rendered → Then it is a round button filled
      // with the accent colour, carrying a speaker icon.
      final button = tester.widget<RawMaterialButton>(
          find.byType(RawMaterialButton));
      expect(button.shape, isA<CircleBorder>(),
          reason: 'the speak control must be round (CircleBorder), not a text '
              'button');
      expect(button.fillColor, WarmPaper.accent,
          reason: 'the speak control must be filled with the cobalt accent '
              '(ColorScheme.primary), not a stock fill');
      expect(button.fillColor, cs.primary,
          reason: 'the accent fill is the theme primary, inherited not hardcoded');
      expect(find.byIcon(Icons.volume_up), findsOneWidget,
          reason: 'the speak control carries a speaker glyph');
      // Control: it is a single labelled button (rejects a bare glyph).
      expect(find.bySemanticsLabel('Speak'), findsOneWidget,
          reason: 'the speak control announces its action to screen readers');
    });

    // # UX: cards var(--sf)+2px var(--ln); emphasis 2px var(--ink); inverted var(--ink) bg
    acTestWidgets(
        'AC-12',
        'Panels render as bordered surface cards with emphasis and inverted variants',
        (tester) async {
      final cs = AppTheme.light().themeData.colorScheme;

      // Given a screen shows an ordinary panel → mount it.
      await tester.pumpWidget(_themed(const SurfaceCard(child: Text('ordinary'))));
      await tester.pumpAndSettle();
      final ordinary = _cardDecoration(tester, find.byType(SurfaceCard));

      // Then an ordinary panel is a surface card with a hairline-weight (line
      // colour) border at the standard 2px width.
      expect(ordinary.color, cs.surface,
          reason: 'an ordinary card has a surface fill');
      final ordinaryBorder = ordinary.border! as Border;
      expect(ordinaryBorder.top.color, cs.outlineVariant,
          reason: 'the ordinary card border is the paper hairline (line)');
      expect(ordinaryBorder.top.width, AppTheme.standardBorderWidth,
          reason: 'the ordinary card border is the 2px standard width (stock '
              'shell draws a 1px hairline)');

      // Given an emphasis panel → mount it.
      await tester
          .pumpWidget(_themed(const SurfaceCard.emphasis(child: Text('emphasis'))));
      await tester.pumpAndSettle();
      final emphasis = _cardDecoration(tester, find.byType(SurfaceCard));

      // Then an emphasis panel has an ink border.
      expect(emphasis.color, cs.surface);
      final emphasisBorder = emphasis.border! as Border;
      expect(emphasisBorder.top.color, cs.onSurface,
          reason: 'the emphasis card border is ink (onSurface)');
      expect(emphasisBorder.top.width, AppTheme.standardBorderWidth,
          reason: 'the emphasis card border is the 2px standard width');

      // Given an inverted panel → mount it.
      await tester
          .pumpWidget(_themed(const SurfaceCard.inverted(child: Text('inverted'))));
      await tester.pumpAndSettle();
      final inverted = _cardDecoration(tester, find.byType(SurfaceCard));

      // Then an inverted panel is ink-filled with paper-coloured text.
      expect(inverted.color, AppTheme.inverted.paper,
          reason: 'an inverted panel is ink-filled (the inverted paper tone)');
      expect(inverted.border, isNull,
          reason: 'an inverted panel carries no border (the fill is the cue)');
      expect(effectiveTextStyleOf(tester, find.text('inverted')).color,
          AppTheme.inverted.ink,
          reason: 'inverted-panel text is paper-coloured');

      // Rejects all three rendered the same: the ordinary (line) and emphasis
      // (ink) borders differ, and the inverted fill is neither surface.
      expect(ordinaryBorder.top.color, isNot(emphasisBorder.top.color),
          reason: 'the ordinary and emphasis borders must differ');
      expect(inverted.color, isNot(cs.surface),
          reason: 'the inverted fill must not be the surface fill');
    });

    // # UX: PROV badges — glyph ◉/∑/≈/✓ + solid/fill/dashed border, not hue alone
    acTestWidgets('AC-13', 'Provenance badges render with the glyph-and-border signature',
        (tester) async {
      // Given a provenance badge is shown, for each kind → mount it and read
      // its glyph and its colour-independent border signature.
      final glyphs = <IconData>{};
      final signatures = <_Signature>{};
      final perKind = <ProvenanceTier, _Signature>{};
      for (final tier in ProvenanceTier.values) {
        await tester
            .pumpWidget(_themed(ProvenanceBadge(provenance: Provenance(tier))));
        await tester.pumpAndSettle();
        glyphs.add(ProvenanceIcon.iconFor(tier));
        final signature = _badgeSignature(tester, find.byType(ProvenanceBadge));

        // When it is rendered → Then its kind is carried by a glyph AND a
        // border style (not by colour alone): each kind's badge draws a
        // non-colour signature (a border, a fill, or a dashed/custom paint),
        // which the glyph+text badge lacks until COMPONENTS-5 adds it.
        expect(signature.border || signature.fill || signature.custom, isTrue,
            reason: '${tier.name}: the badge must carry a border-style signature '
                '(solid/fill/dashed), not colour alone');
        signatures.add(signature);
        perKind[tier] = signature;
      }

      // The glyph channel distinguishes every kind (the colour-independent
      // carrier that is always present), and the border signature varies across
      // kinds — so a colour-only differentiation is rejected.
      expect(glyphs, hasLength(ProvenanceTier.values.length),
          reason: 'each provenance kind has a distinct glyph');
      expect(signatures.length, greaterThanOrEqualTo(2),
          reason: 'the border signature must vary across kinds (measured solid '
              'vs calculated/confirmed fill vs estimated dashed), not be uniform: '
              '$perKind');
    });
  });

  group('Rule: the design system is applied across every primary screen', () {
    // # UX: THEMES applied once on the device root; all screens inherit
    acTestWidgets('AC-14', 'Every screen inherits the one installed theme',
        (tester) async {
      // Given the app is assembled → walk every primary screen through the one
      // `buildApp` entry, recording the theme each resolves.
      final schemes = <ColorScheme>[];
      final texts = <TextTheme>[];
      for (final screen in screenRoster) {
        final harness = await pumpApp(tester, screen: screen);
        expect(find.byType(MaterialApp), findsOneWidget,
            reason: '${screen.label}: exactly one MaterialApp (no nested '
                'app/theme installed by the screen)');
        schemes.add(harness.colorScheme);
        texts.add(harness.textTheme);
      }

      // When any primary screen is shown → Then it reads its colours and type
      // from the single installed theme: every screen resolves the one
      // `AppTheme` chokepoint, none overriding the scheme or type.
      final chokepoint = AppTheme.light().themeData;
      for (var i = 0; i < screenRoster.length; i++) {
        expect(schemes[i], chokepoint.colorScheme,
            reason: '${screenRoster[i].label} must not override the colour scheme');
        expect(texts[i], chokepoint.textTheme,
            reason: '${screenRoster[i].label} must not override the text theme');
      }

      // … and no screen hardcodes a palette colour: zero residual palette
      // literals in `lib/` outside the theme authority and the D-4 capture
      // device files. PARTIAL at baseline — the one-theme part holds, but ~7
      // residual literals remain until APPLY-1 removes them (which then
      // augments this to pin the exclusion set).
      final residual = residualPaletteLiterals(
        roots: const ['lib'],
        exempt: {kThemeAuthorityFile, ...kCaptureDeviceLiteralFiles},
      );
      expect(residual, isEmpty,
          reason: 'no screen may hardcode a palette colour; residual literals '
              'outside the exclusions: '
              '${residual.map((o) => '${o.path}:${o.line}').join(', ')}');
    });

    // # UX: "Swatches are screen approximations. Trust the numbers." / "APPROX."
    acTestWidgets('AC-15', 'A displayed colour swatch carries its approximation caption',
        (tester) async {
      // Given a screen renders a colour swatch → walk every primary screen and
      // count the rendered swatches (a `ColorChip` carrying a colour).
      var totalSwatches = 0;
      for (final screen in screenRoster) {
        await pumpApp(tester, screen: screen);
        final swatches =
            find.byWidgetPredicate((w) => w is ColorChip && w.color != null);
        final count = swatches.evaluate().length;
        if (count == 0) continue;
        totalSwatches += count;

        // When the swatch is shown → Then it is accompanied by a caption that
        // the swatch is an approximation and the numbers are authoritative.
        final caption = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').toLowerCase().contains('approx'));
        expect(caption, findsWidgets,
            reason: '${screen.label}: a rendered colour swatch must be '
                'accompanied by an approximation caption');
      }
      // The rule is non-vacuous: at least one screen renders a swatch.
      expect(totalSwatches, greaterThan(0),
          reason: 'at least one primary screen must render a colour swatch');
    });
  });
}
