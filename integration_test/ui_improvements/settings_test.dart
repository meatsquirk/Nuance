// Acceptance tests for the bs-20 settings / Speak gating (ITEST-3).
//
// One *pending* integration test per settings/Speak AC — AC-6 (accessibility
// features off by default), AC-7 (Speak hidden while off) and AC-8 (Speak shown
// when on) — driving the *real* assembled app through the `harness.dart`
// vocabulary (ITEST-1). In the default run each body is skipped; under
// `--dart-define=BS20_RUN_PENDING=true` it executes and records the red
// baseline.
//
// AC-7 and AC-8 are a *pair*: each asserts its own direction as the primary Then
// (off→hidden for AC-7, on→shown for AC-8) and carries the opposite direction as
// an in-test control, so neither can be satisfied vacuously — an always-shown
// Speak fails AC-7 (and AC-8's control), a never-rendered Speak fails AC-8 (and
// AC-7's control). The pairing is complete in this phase, so the pre-seeded
// READOUT-7 augmentation is not needed (see ITEST.md Test augmentations).
//
// The readout AC tests (AC-1/2/3/4/5/9) live in the sibling `readout_test.dart`
// (ITEST-2), so the two AC-test phases stay parallel-friendly on disjoint files.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // ITEST-3 — settings / Speak gating (AC-6, AC-7, AC-8)
  // ===========================================================================

  // AC-6 (TestAC06_DefaultOff, owner A11Y-2) — with no settings changed, the
  // accessibility-features control reads off. Rejects a toggle defaulting on, or
  // one absent from the panel. A control drives the setting on to prove the
  // toggle reflects the live state (not a constant-off render), so "off by
  // default" is a real reading.
  //
  // NOTE (green at baseline): the A11Y-1 shell already ships
  // `DisplaySettings.accessibilityFeatures = false`, so this test passes at the
  // red baseline. It is left pending (owner A11Y-2) and flagged for the ITEST-4
  // test review (G-2): see ITEST.md Red baseline.
  acTestWidgets('AC-6', 'Accessibility features are off by default',
      (tester) async {
    // Given: the painter has not changed any settings (a fresh app on the
    // default `DisplaySettings`) — re-asserted before the When, so the
    // "unchanged" Given is checked, not assumed.
    final harness = await givenReadoutOf(tester, anySample);
    expect(harness.settings.accessibilityFeatures, isFalse,
        reason: 'AC-6 Given: a fresh app starts with accessibility features off');

    // When: the settings panel is shown.
    await harness.whenOpenSettings();

    // Then: the accessibility-features control is present (rejects absent) and
    // reads off (rejects defaulting on).
    expect(harness.accessibilityToggle, findsOneWidget,
        reason: 'AC-6: the accessibility-features toggle must be present');
    expect(tester.widget<SwitchListTile>(harness.accessibilityToggle).value,
        isFalse,
        reason: 'AC-6: the accessibility-features control must default off '
            '(A11Y-2)');

    // Control: the toggle reflects the live setting (rejects a constant-off
    // render) — driving the set on makes the control read on.
    await harness.whenSetAccessibilityFeatures(on: true);
    expect(tester.widget<SwitchListTile>(harness.accessibilityToggle).value,
        isTrue,
        reason: 'AC-6 control: the toggle must reflect the live accessibility '
            'setting, so "off by default" is a real reading, not a constant');
  });

  // AC-7 (TestAC07_SpeakHidden, owner READOUT-7) — while accessibility features
  // are off, no "Speak this readout" control is shown. Rejects Speak still shown
  // while off (the always-shown actions bar today). Control: turning
  // accessibility on reveals Speak, so "hidden while off" can't be satisfied by
  // never rendering Speak (pairs AC-8's direction).
  acTestWidgets('AC-7', 'With accessibility features off, Speak is hidden',
      (tester) async {
    // Given: accessibility features are off (the default) — re-asserted.
    final harness = await givenReadoutOf(tester, anySample);
    expect(harness.settings.accessibilityFeatures, isFalse,
        reason: 'AC-7 Given: accessibility features must be off');

    // When: the painter is reading a sample (the readout is shown).
    expect(find.text('Any Sample'), findsOneWidget,
        reason: 'AC-7: the readout must be showing the sample');

    // Then: no "Speak this readout" control is shown.
    expect(harness.speakControl, findsNothing,
        reason: 'AC-7: Speak must be hidden while accessibility features are off '
            '(READOUT-7)');

    // Control: Speak must be able to appear (when accessibility is on), so the
    // off→hidden reading above is not vacuous — a layout that simply never
    // renders Speak fails here.
    await harness.whenSetAccessibilityFeatures(on: true);
    expect(harness.speakControl, findsOneWidget,
        reason: 'AC-7 control: Speak must appear once accessibility is on, so the '
            'off→hidden reading is not vacuous (READOUT-7)');
  });

  // AC-8 (TestAC08_SpeakShown, owner READOUT-7) — turning accessibility features
  // on reveals the "Speak this readout" control. Rejects Speak absent after
  // turning on. Control: while off, Speak is hidden, so "shown when on" can't be
  // satisfied by an always-shown control (pairs AC-7's direction).
  acTestWidgets('AC-8', 'Turning accessibility features on reveals Speak',
      (tester) async {
    // Given: accessibility features are off — re-asserted.
    final harness = await givenReadoutOf(tester, anySample);
    expect(harness.settings.accessibilityFeatures, isFalse,
        reason: 'AC-8 Given: accessibility features must start off');

    // Control: while off, Speak is not shown — so the "shown when on" Then below
    // is not an always-shown control (an always-shown Speak fails here).
    expect(harness.speakControl, findsNothing,
        reason: 'AC-8 control: Speak must be hidden while accessibility is off, '
            'so "shown when on" is not vacuous (READOUT-7)');

    // When: the painter turns accessibility features on, and is reading a sample.
    await harness.whenSetAccessibilityFeatures(on: true);
    expect(harness.settings.accessibilityFeatures, isTrue,
        reason: 'AC-8 When: the configured flag must be on after turning it on');
    expect(find.text('Any Sample'), findsOneWidget,
        reason: 'AC-8: the readout must be showing the sample');

    // Then: a "Speak this readout" control is shown.
    expect(harness.speakControl, findsOneWidget,
        reason: 'AC-8: Speak must be revealed when accessibility features are on '
            '(READOUT-7)');
  });
}
