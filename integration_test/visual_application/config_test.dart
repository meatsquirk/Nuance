// bs-18 acceptance suite — Config-screens AC (ITEST-3): AC-10 the Display and
// Onboarding screens through the design system (owner CFG-1).
//
// The two configuration surfaces have no `AppDependencies` home entry, so the
// harness pumps them through the real app chrome / route (ITEST-1 handoff):
// `pumpDisplaySettings` opens the Display settings panel through its E2 entry
// (seeded from the CFG fixture's deutan-simulation snapshot), and
// `pumpOnboarding` pushes the onboarding host onto the running app. Both read
// the design-system treatment off the real pumped tree under the one installed
// theme. Pending; red at baseline (simulation options + onboarding controls are
// ad-hoc `TextButton`s; onboarding steps are bare `Column`s).
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/onboarding/screens/lighting_step.dart';
import 'package:paint_color_assistant/onboarding/screens/onboarding_screen.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-10 — Display + Onboarding through the design system (owner CFG-1)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-10',
      'TestAC10_DisplayOnboarding: the Display settings view controls render as '
      'pills and each onboarding step sits in a surface card with pill actions',
      (tester) async {
    // --- Display settings panel (E45) ---

    // GIVEN the Display settings panel is open with its simulation view controls.
    await pumpDisplaySettings(tester);
    expect(find.byKey(DisplaySettingsScreen.panelKey), findsOneWidget,
        reason: 'Given: the Display settings panel is open');
    final simOff = DisplaySettingsScreen.simulationOptionKey(null);
    final simDeutan = DisplaySettingsScreen.simulationOptionKey(CvdType.deutan);
    expect(find.byKey(simOff), findsOneWidget,
        reason: 'Given: the simulation "off" option renders');
    expect(find.byKey(simDeutan), findsOneWidget,
        reason: 'Given: the simulation deutan option renders');

    // WHEN the panel renders.

    // THEN the simulation view-switch options render as design-system pills, not
    // the ad-hoc TextButtons they are today (rejects an option left ad-hoc).
    expectPill(tester, simOff,
        reason: 'the simulation "off" option renders as a PillButton');
    expectPill(tester, simDeutan,
        reason: 'the simulation deutan option renders as a PillButton');

    // --- Onboarding step (E42) ---

    // GIVEN the onboarding host is pushed onto the running app — a step and its
    // continue (next) action render.
    await pumpOnboarding(tester);
    expect(find.byKey(LightingStep.regionKey), findsOneWidget,
        reason: 'Given: an onboarding step renders');
    expect(find.byKey(LightingStep.continueKey), findsOneWidget,
        reason: 'Given: the step continue action renders');

    // WHEN the step renders.

    // THEN the step's content sits in a surface card (rejects a step left as a
    // bare Column).
    expect(
      find.ancestor(
        of: find.byKey(LightingStep.regionKey),
        matching: find.byType(SurfaceCard),
      ),
      findsOneWidget,
      reason: 'the onboarding step content sits inside a SurfaceCard',
    );

    // THEN the step's continue (next) action and the flow's "see my result"
    // action render as design-system pills, not the ad-hoc TextButtons they are
    // today (rejects a next/back control left ad-hoc).
    expectPill(tester, LightingStep.continueKey,
        reason: 'the step continue action renders as a PillButton');
    expectPill(tester, OnboardingScreen.seeResultKey,
        reason: 'the onboarding "see my result" action renders as a PillButton');
  });
}
