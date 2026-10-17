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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'design_system_harness.dart';

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
}
