// bs-18 acceptance suite — cross-cutting guard ACs (ITEST-4): AC-11 the one
// installed theme, AC-12 the swatch approximation caption, AC-13 the preserved
// accessibility, AC-14 no new hardcoded palette colours.
//
// These four are *regression guards* over the design-system application: they
// extend bs-17's "one installed theme" / SwatchCaption / source-scan
// guarantees and bs-11's accessibility conformance across the screens bs-18
// swaps. Each drives the **real** assembled app through the single `buildApp`
// entry (the harness) and reuses the shipped bs-17 source-scan
// (`residualPaletteLiterals`) and bs-11 conformance check
// (`runConformanceCheck`) rather than re-deriving them.
//
// GROUND TRUTH (ITEST-4 probe over the live tree at the branch point): all four
// invariants already HOLD at baseline — every harness-reachable screen installs
// exactly one theme with no scheme override, every swatch-bearing screen already
// carries exactly one caption, every screen passes the 48dp + AA-contrast rules,
// and `lib/` has zero residual palette literals outside the bs-17 exclusions. So,
// like AC-1 (CHROME-2's nav was already conformant), each test is **green at
// baseline**. The scenario data alone therefore cannot separate a right from a
// wrong implementation (a guard that never fails is vacuous — G5), so each test
// carries a DISCRIMINATING CONTROL: a deliberately-non-conformant fixture the
// rule must flag (a nested-theme screen, an uncaptioned/duplicate-caption
// swatch, a 24dp target and low-contrast text, a planted colour literal). The
// test passes iff the rule holds on every real screen AND catches the control.
//
// Kept pending (owners GUARD-1/2/3 un-pend + keep green), consistent with this
// feature's all-14-pending model; the green-at-baseline status and the option to
// un-pend these guards now (for continuous regression cover during the behaviour
// phases) are surfaced for the ITEST-5 (G-2) review.
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';
import 'package:paint_color_assistant/app/theme.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';

import '../conformance/conformance_check.dart';
import '../design_system_source_scan.dart';
import 'harness.dart';

/// Every surface the guard sweeps — the full bs-18 roster, each opened through
/// its production pump. AC-11 and AC-13 sweep all of them; AC-12 sweeps the ones
/// that actually bear a swatch.
Map<String, Future<VisualHarness> Function()> _roster(WidgetTester tester) => {
      'Readout (shell)': () => pumpShell(tester),
      'Capture': () => pumpScreen(tester, VisualScreen.capture),
      'Compare': () => pumpScreen(tester, VisualScreen.compare),
      'Recipes': () => pumpScreen(tester, VisualScreen.recipes),
      'Palette': () => pumpScreen(tester, VisualScreen.palette),
      'Display settings': () => pumpDisplaySettings(tester),
      'Onboarding': () => pumpOnboarding(tester),
    };

/// The [Theme] widgets in the pumped tree whose colour scheme differs from the
/// one installed [scheme] — i.e. a surface wrapped in its own overriding theme.
/// Empty when every surface reads the single installed theme (AC-11).
List<Element> _schemeOverridingThemes(ColorScheme scheme) => find
    .byType(Theme)
    .evaluate()
    .where((e) => (e.widget as Theme).data.colorScheme != scheme)
    .toList();

/// Wraps [body] in a minimal app on the real [AppTheme] (the same theme
/// `buildApp` installs), keyed so a check targets exactly that subtree — the
/// control-fixture builder the AC-13 controls use.
Widget _fixtureApp(Key key, Widget body) => MaterialApp(
      theme: AppTheme.light().themeData,
      home: Scaffold(body: Center(child: KeyedSubtree(key: key, child: body))),
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-11 — every screen inherits the one installed theme (owner GUARD-2)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-11',
      'TestAC11_SingleTheme: every screen installs exactly one theme and wraps '
      'no child in its own Theme/MaterialApp', (tester) async {
    // GIVEN/WHEN each primary and configuration screen renders (the sweep).
    var screensChecked = 0;
    for (final entry in _roster(tester).entries) {
      final h = await entry.value();
      final scheme = h.installedTheme.colorScheme;

      // GIVEN the screen rendered — it has an installed theme to read from.
      expect(find.byType(MaterialApp), findsWidgets,
          reason: 'Given: ${entry.key} rendered on an installed theme');

      // THEN it installs exactly one MaterialApp — no child mounts its own app
      // (rejects a screen that nests a MaterialApp).
      expect(find.byType(MaterialApp), findsOneWidget,
          reason: '${entry.key} installs exactly one MaterialApp, not a nested '
              'one');

      // THEN no surface overrides the installed theme: every Theme in the tree
      // carries the one installed colour scheme (rejects a child wrapped in its
      // own Theme with a different scheme).
      final overriding = _schemeOverridingThemes(scheme);
      expect(overriding, isEmpty,
          reason: '${entry.key} wraps no child in its own overriding Theme, so '
              'every surface reads the one installed scheme; '
              '${overriding.length} differing Theme(s) found');
      screensChecked++;
    }
    expect(screensChecked, _roster(tester).length,
        reason: 'the sweep covered every roster screen (non-vacuous)');

    // CONTROL (G5 — the invariant holds on every real screen, so prove the rule
    // discriminates a screen that DID install its own theme): a surface wrapped
    // in a nested MaterialApp carrying a different scheme. The same two checks
    // must flag it — a second MaterialApp and a scheme-overriding Theme — so the
    // sweep above is not a vacuous pass.
    final base = AppTheme.light().themeData;
    final otherScheme =
        ColorScheme.fromSeed(seedColor: const Color(0xFF00FF00));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        theme: base,
        home: Scaffold(
          // A child that installs its OWN MaterialApp + theme — the violation.
          body: MaterialApp(
            theme: ThemeData.from(colorScheme: otherScheme),
            home: const Scaffold(body: Text('nested')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsNWidgets(2),
        reason: 'control: the nested MaterialApp is a second app the rule flags');
    expect(_schemeOverridingThemes(base.colorScheme), isNotEmpty,
        reason: 'control: the nested theme overrides the installed scheme — the '
            'rule catches it');
  });

  // ------------------------------------------------------------------------
  // AC-12 — every swatch-bearing screen carries its approximation caption
  // (owner GUARD-1; augmentation: enumerate ALL swatch-bearing screens)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-12',
      'TestAC12_SwatchCaption: every screen that shows a colour swatch shows '
      'exactly one approximation caption', (tester) async {
    // GIVEN/WHEN each screen renders; a screen "bears a swatch" iff it renders
    // at least one design-system ColorChip.
    final swept = <String>[];
    for (final entry in _roster(tester).entries) {
      final h = await entry.value();
      final bearsSwatch = find.byType(ColorChip).evaluate().isNotEmpty;
      if (!bearsSwatch) continue;
      swept.add(entry.key);

      // THEN it shows exactly one swatch approximation caption beside its
      // swatch group (rejects a swatch-bearing screen left uncaptioned, and a
      // screen that scatters more than one caption).
      expect(h.swatchCaptions, findsOneWidget,
          reason: '${entry.key} bears a swatch, so it carries exactly one '
              'SwatchCaption');
    }

    // GIVEN-coverage (G1): the sweep actually reached the known swatch-bearing
    // screens — it is not a vacuous empty loop.
    expect(swept, containsAll(<String>['Readout (shell)', 'Capture', 'Palette']),
        reason: 'the sweep covered the real swatch-bearing screens; swept: '
            '$swept');

    // CONTROL (G5 — every real swatch screen is already captioned, so prove the
    // "exactly one" rule discriminates both a MISSING and a DUPLICATE caption):
    // a ColorChip with no caption fails the rule (zero), and a screen with two
    // captions fails it (two) — only exactly-one passes.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      _fixtureApp(
        const ValueKey('ac12.noCaption'),
        const ColorChip(label: 'Terracotta', color: Color(0xFFB5651D)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ColorChip), findsOneWidget,
        reason: 'control bears a swatch');
    expect(find.byKey(SwatchCaption.captionKey), findsNothing,
        reason: 'control: an uncaptioned swatch screen has zero captions — the '
            'rule flags it (findsOneWidget would fail)');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      _fixtureApp(
        const ValueKey('ac12.twoCaptions'),
        // Two captions in distinct parents (never duplicate-key siblings).
        Row(
          children: const [
            Column(children: [SwatchCaption()]),
            Column(children: [SwatchCaption()]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SwatchCaption.captionKey), findsNWidgets(2),
        reason: 'control: two captions violate "exactly one" — the rule flags '
            'it (findsOneWidget would fail)');
  });

  // ------------------------------------------------------------------------
  // AC-13 — the restyle preserves accessibility (owner GUARD-3)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-13',
      'TestAC13_A11yPreserved: every screen still meets the 48dp tap-target and '
      'AA-contrast floors after the swap', (tester) async {
    // GIVEN/WHEN each screen renders and its controls + text are measured by the
    // reusable bs-11 conformance check.
    var screensChecked = 0;
    for (final entry in _roster(tester).entries) {
      await entry.value();
      final result = await runConformanceCheck(tester, find.byType(MaterialApp).first);
      final tap = result.outcomeFor(ConformanceRuleId.tapTarget48);
      final contrast = result.outcomeFor(ConformanceRuleId.contrastAA);

      // GIVEN the rules actually ran on this screen (not an absent outcome).
      expect(tap, isNotNull,
          reason: 'Given: the tap-target rule ran on ${entry.key}');
      expect(contrast, isNotNull,
          reason: 'Given: the contrast rule ran on ${entry.key}');

      // THEN every interactive control reserves at least a 48dp tap target
      // (rejects a swap that drops a control below the floor).
      expect(tap!.pass, isTrue,
          reason: '${entry.key} keeps the 48dp tap-target floor: ${tap.detail}');

      // THEN every text pairing still meets the WCAG 2.2 AA contrast floor
      // (rejects a swap that introduces a low-contrast pairing).
      expect(contrast!.pass, isTrue,
          reason: '${entry.key} keeps the AA contrast floor: ${contrast.detail}');
      screensChecked++;
    }
    expect(screensChecked, _roster(tester).length,
        reason: 'the sweep covered every roster screen (non-vacuous)');

    // CONTROL (G5 — every real screen passes, so prove each rule discriminates a
    // violation): a 24dp target fails the tap-target rule, and ~1.6:1 text fails
    // the contrast rule. Mirrors the bs-11 controls.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      _fixtureApp(
        const ValueKey('ac13.smallTarget'),
        SizedBox(
          width: 24,
          height: 24,
          child: GestureDetector(
            onTap: () {},
            child: Semantics(
              label: 'Tiny action',
              button: true,
              child: const ColoredBox(color: Color(0xFF1565C0)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final smallTargetResult =
        await runConformanceCheck(tester, find.byKey(const ValueKey('ac13.smallTarget')));
    expect(smallTargetResult.outcomeFor(ConformanceRuleId.tapTarget48)!.pass, isFalse,
        reason: 'control: a 24dp target fails the tap-target rule — it '
            'discriminates');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      _fixtureApp(
        const ValueKey('ac13.lowContrast'),
        const ColoredBox(
          color: Colors.white,
          child: Text(
            'Low-contrast label',
            style: TextStyle(color: Color(0xFFBDBDBD)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final lowContrastResult =
        await runConformanceCheck(tester, find.byKey(const ValueKey('ac13.lowContrast')));
    expect(lowContrastResult.outcomeFor(ConformanceRuleId.contrastAA)!.pass, isFalse,
        reason: 'control: ~1.6:1 text fails the AA-contrast rule — it '
            'discriminates');
  });

  // ------------------------------------------------------------------------
  // AC-14 — no new hardcoded palette colours (owner GUARD-2)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-14',
      'TestAC14_NoHardcodedPalette: the lib/ source-scan finds no palette '
      'Color(0x..) literal outside the bs-17 exclusion list', (tester) async {
    // WHEN the design-system source-scan runs over the swapped screen source
    // under lib/, with the bs-17 AC-14 exclusion list (the AppTheme authority +
    // the D-4 capture-device files).
    final residual = residualPaletteLiterals(
      roots: const ['lib'],
      exempt: {kThemeAuthorityFile, ...kCaptureDeviceLiteralFiles},
    );

    // THEN it finds no hardcoded palette literal (rejects a swapped screen that
    // introduced a Color(0x..) literal instead of a theme token).
    expect(residual, isEmpty,
        reason: 'no screen may hardcode a palette colour; residual literals '
            'outside the exclusions: '
            '${residual.map((o) => '${o.path}:${o.line}').join(', ')}');

    // CONTROL (G5 — lib/ is clean, so prove the scan discriminates a real
    // violation): a planted Color(0x..) literal is flagged, while the same
    // literal inside a comment or string is NOT (the scan masks those).
    final dir = Directory.systemTemp.createTempSync('bs18_ac14_scan');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/offender.dart').writeAsStringSync(
      '// Color(0xDEADBEEF) in a comment must be ignored\n'
      'const violation = Color(0xFF123456);\n'
      "const s = 'Color(0xFF000000) in a string must be ignored';\n",
    );
    final controlHits = residualPaletteLiterals(roots: [dir.path], exempt: const {});
    expect(controlHits, hasLength(1),
        reason: 'control: exactly the one real literal is flagged (the comment '
            'and string literals are masked) — the scan discriminates');
    expect(controlHits.single.rule, ruleHardcodedPalette,
        reason: 'control: the flagged literal is tagged the palette rule');
  });
}
