import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The Tier 0 display-and-lighting setup step (wireframe S1.R1.E36 display and
/// lighting checks [button], E43 continue [button]; AC-2).
///
/// Shows the three checks — screen brightness, night-light off and daylight —
/// and a continue control. FLOW-3 wires each checkbox to
/// `confirmLightingCheck` and the continue control to the gated `tryContinue`,
/// so testing begins only once all three are confirmed (AC-2). Continue is
/// always tappable; the gate lives in `tryContinue` (an unconfirmed tap is a
/// no-op), which is the negative-Then settle point AC-2's test relies on.
class LightingStep extends StatelessWidget {
  /// Creates the lighting step over [controller].
  const LightingStep({required this.controller, super.key});

  /// Stable anchor for the lighting step.
  static const Key regionKey = ValueKey('onboarding-lighting-step');

  /// Stable anchor for the continue control (E43).
  static const Key continueKey = ValueKey('onboarding-lighting-continue');

  /// The controller the lighting checks and continue act on (FLOW-3).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Display and lighting setup'),
        CheckboxListTile(
          value: state.brightnessConfirmed,
          onChanged: (value) => controller.confirmLightingCheck(
              LightingCheck.brightness,
              confirmed: value ?? false),
          title: const Text('Screen brightness turned up'),
        ),
        CheckboxListTile(
          value: state.nightLightConfirmed,
          onChanged: (value) => controller.confirmLightingCheck(
              LightingCheck.nightLight,
              confirmed: value ?? false),
          title: const Text('Night-light turned off'),
        ),
        CheckboxListTile(
          value: state.daylightConfirmed,
          onChanged: (value) => controller.confirmLightingCheck(
              LightingCheck.daylight,
              confirmed: value ?? false),
          title: const Text('In daylight'),
        ),
        TextButton(
          key: continueKey,
          onPressed: controller.tryContinue,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
