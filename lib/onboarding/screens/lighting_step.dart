import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The Tier 0 display-and-lighting setup step (wireframe S1.R1.E36 display and
/// lighting checks [button], E43 continue [button]; AC-2).
///
/// Shows the three checks — screen brightness, night-light off and daylight —
/// and a continue control. The FLOW-1 shell renders them **inert**
/// (`onPressed: null`): FLOW-3 wires `confirmLightingCheck` to the three checks
/// and gates `tryContinue` so testing begins only once all three are confirmed.
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
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Display and lighting setup'),
        CheckboxListTile(
          value: false,
          onChanged: null,
          title: Text('Screen brightness turned up'),
        ),
        CheckboxListTile(
          value: false,
          onChanged: null,
          title: Text('Night-light turned off'),
        ),
        CheckboxListTile(
          value: false,
          onChanged: null,
          title: Text('In daylight'),
        ),
        TextButton(
          key: continueKey,
          onPressed: null,
          child: Text('Continue'),
        ),
      ],
    );
  }
}
