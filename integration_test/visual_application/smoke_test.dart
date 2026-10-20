// Acceptance-suite scaffold for bs-18 Apply the visual design system (ITEST-1).
//
// The never-pending harness smoke + guard tests the acceptance suite stands on,
// proving the scaffold cannot pass vacuously (acceptance-suite grade rules):
//
//   * a shell smoke that boots the real app through the one `buildApp` entry
//     onto the CHROME-2 nav shell — all four destinations present, exactly one
//     non-colour active marker (under the opening Capture destination), the one
//     theme installed — and that the shell switches between destinations;
//   * the `BS18_RUN_PENDING` pending gate proven **both directions** (a pending
//     AC is skipped by default and runs under the flag; an un-pended AC always
//     runs), plus the integrity invariants (every owner is a known behaviour
//     phase; the seed matches the master plan AC coverage table) and a planted
//     `acTestWidgets` wiring smoke;
//   * fixture guards asserting each of the six fixtures is well-formed, so a
//     later AC test built on an empty/degenerate fixture fails here first.
//
// This supersedes CHROME-1's `pending_runner_test.dart` (which it folds in).
// Default run (`flutter test -d flutter-tester integration_test/visual_application/`)
// runs these scaffold tests with the (future) AC tests pending;
// `--dart-define=BS18_RUN_PENDING=true` additionally executes the pending AC
// tests for the red baseline.
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/onboarding/onboarding_steps.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ITEST-1 shell smoke — the real app assembles onto the nav shell', () {
    testWidgets('pumpShell boots the 4-destination shell on one theme', (
      tester,
    ) async {
      final h = await pumpShell(tester);

      // Exactly one theme is installed (the one chokepoint every screen reads).
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(h.installedTheme, isNotNull);

      // The bottom nav and every destination item are present.
      expect(h.bottomNav, findsOneWidget);
      for (final destination in AppDestination.values) {
        expect(
          h.navItem(destination),
          findsOneWidget,
          reason: '${destination.label} nav item present',
        );
      }

      // Exactly one non-colour active marker, under the opening Capture
      // destination (the shell opens on index 0).
      expect(h.activeDestination, findsOneWidget);
      expect(
        find.descendant(
          of: h.navItem(AppDestination.capture),
          matching: find.byKey(AppShell.activeDestinationKey),
        ),
        findsOneWidget,
        reason: 'the shell opens on the Capture destination',
      );
    });

    testWidgets('the shell switches to each destination', (tester) async {
      final h = await pumpShell(tester);
      for (final destination in AppDestination.values) {
        await tester.tap(h.navItem(destination));
        await tester.pumpAndSettle();
        // After selecting, the single active marker sits under this item.
        expect(h.activeDestination, findsOneWidget);
        expect(
          find.descendant(
            of: h.navItem(destination),
            matching: find.byKey(AppShell.activeDestinationKey),
          ),
          findsOneWidget,
          reason: 'selecting ${destination.label} marks it active',
        );
      }
    });
  });

  group('ITEST-1 pending gate — proven both directions', () {
    test('a pending AC is skipped by default and runs under the flag', () {
      // AC-3 is still seeded pending (owner READ-1) — AC-1 (CHROME-3) and AC-2
      // (CHROME-4) were un-pended, so this proof moved to the next pending AC.
      expect(
        pendingACs.containsKey('AC-3'),
        isTrue,
        reason: 'AC-3 must be seeded pending for this proof',
      );

      // Default run: the AC is skipped with an owner-naming reason.
      final defaultReason = pendingSkipReason('AC-3', forceRunPending: false);
      expect(defaultReason, isNotNull);
      expect(defaultReason, contains('READ-1'));
      expect(defaultReason, contains('--dart-define=BS18_RUN_PENDING=true'));

      // Run-pending: the same AC executes (no skip reason).
      expect(pendingSkipReason('AC-3', forceRunPending: true), isNull);

      // The un-pended ACs (AC-1 CHROME-3, AC-2 CHROME-4) never skip, either mode.
      for (final unpended in const ['AC-1', 'AC-2']) {
        expect(pendingSkipReason(unpended, forceRunPending: false), isNull);
        expect(pendingSkipReason(unpended, forceRunPending: true), isNull);
      }
    });

    test('an un-pended AC always runs, in either mode', () {
      const unpended = 'AC-NOT-SEEDED';
      expect(pendingACs.containsKey(unpended), isFalse);
      expect(pendingSkipReason(unpended, forceRunPending: false), isNull);
      expect(pendingSkipReason(unpended, forceRunPending: true), isNull);
    });

    test('every pending AC names a known behaviour phase as its owner', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases.contains(entry.value),
          isTrue,
          reason: '${entry.key} owner "${entry.value}" is not a behaviour phase',
        );
      }
    });

    test('the still-pending ACs match the full seed minus the un-pended ones',
        () {
      // The full 14-AC seed CHROME-1 planted from the master plan AC coverage
      // table. Behaviour phases un-pend their AC by deleting its row; the ACs
      // whose behaviour phase has landed are listed in [unpended], so this test
      // tracks the seed exactly as it drains (each phase adds its AC here).
      const fullSeed = <String, String>{
        'AC-1': 'CHROME-3',
        'AC-2': 'CHROME-4',
        'AC-3': 'READ-1',
        'AC-4': 'READ-2',
        'AC-5': 'READ-3',
        'AC-6': 'FLOW-1',
        'AC-7': 'FLOW-2',
        'AC-8': 'ORG-1',
        'AC-9': 'ORG-2',
        'AC-10': 'CFG-1',
        'AC-11': 'GUARD-2',
        'AC-12': 'GUARD-1',
        'AC-13': 'GUARD-3',
        'AC-14': 'GUARD-2',
      };
      // ACs un-pended by a completed behaviour phase (removed from pendingACs).
      const unpended = <String>{
        'AC-1', // CHROME-3 (bottom nav)
        'AC-2', // CHROME-4 (top bar)
      };
      final expectedPending = Map.of(fullSeed)
        ..removeWhere((ac, _) => unpended.contains(ac));
      expect(pendingACs, equals(expectedPending));
      expect(fullSeed, hasLength(14), reason: 'the seed covers all 14 ACs');
    });
  });

  group('ITEST-1 acTestWidgets wiring smoke', () {
    // Registering through the gate must not throw for a pending or an un-pended
    // AC; the skip-by-default vs run-under-flag logic itself is proven
    // deterministically by the forceRunPending tests above, so these bodies are
    // benign and never pollute the red-baseline run. The ITEST AC tests supply
    // the real assertions.
    acTestWidgets('AC-3', 'planted pending-AC wiring smoke', (tester) async {
      // AC-3 is still pending (AC-1/AC-2 were un-pended by CHROME-3/CHROME-4),
      // so this body is skipped by default and proves the gate wiring under the
      // run flag.
      expect(pendingACs.containsKey('AC-3'), isTrue);
    });
    acTestWidgets('AC-NOT-SEEDED', 'planted unpended-AC wiring smoke', (
      tester,
    ) async {
      expect(pendingACs.containsKey('AC-NOT-SEEDED'), isFalse);
    });
  });

  group('ITEST-1 fixtures — well-formed (no vacuous AC can build on them)', () {
    test('aReading is a measured, named sample', () {
      expect(aReading.name, isNotEmpty);
      expect(aReading.provenance.tier, ProvenanceTier.measured);
    });

    test('aComparison carries two distinct named samples + a 2-entry picker', () {
      expect(aComparison.a.name, isNot(aComparison.b.name));
      expect(aComparison.catalogue, hasLength(2));
      expect(aComparison.sampleSource, isNotNull);
    });

    test('recipesForTarget: a reachable + an out-of-gamut target over a palette',
        () {
      expect(recipesForTarget.palette.paints.length, greaterThanOrEqualTo(2));
      expect(
        recipesForTarget.target.name,
        isNot(recipesForTarget.outOfGamutTarget.name),
      );
      expect(recipesForTarget.paletteSource.palettes(), hasLength(1));
    });

    test('aPalette has >=3 paints spanning >=2 provenance tiers', () {
      expect(aPalette.paints.length, greaterThanOrEqualTo(3));
      final tiers = aPalette.paints.map((p) => p.provenance).toSet();
      expect(
        tiers.length,
        greaterThanOrEqualTo(2),
        reason: 'mixed provenance so every row needs a distinguishing badge',
      );
      expect(aPalette.paletteSource.palettes(), hasLength(1));
    });

    test('aProject is a named project with a note, over a 1-entry source', () {
      expect(aProject.project.name, isNotEmpty);
      expect(aProject.project.note, isNotNull);
      expect(aProject.projectSource.projects(), hasLength(1));
    });

    test('anOnboardingStep is a mid-flow step with an active-sim snapshot', () {
      expect(anOnboardingStep.stepIndex, greaterThan(0));
      expect(
        anOnboardingStep.stepIndex,
        lessThan(defaultOnboardingSteps.length - 1),
        reason: 'interior step so both next and back controls exist',
      );
      expect(
        defaultOnboardingSteps[anOnboardingStep.stepIndex],
        anOnboardingStep.step,
      );
      expect(anOnboardingStep.displaySettings.simulationOn, isTrue);
    });
  });
}
