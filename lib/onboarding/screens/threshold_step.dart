import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The Tier 4 adaptive threshold-probing step (wireframe S1.R1 — threshold tier
/// [body]; AC-9).
///
/// Runs the adaptive probing along the painter's confusion line and scores a
/// severity. The FLOW-1 shell renders the probe control **inert**
/// (`onPressed: null`): ENGINE-6 wires `scoreThreshold` to score the probes
/// through the engine into a severity (0..1).
class ThresholdStep extends StatelessWidget {
  /// Creates the threshold step over [controller].
  const ThresholdStep({required this.controller, super.key});

  /// Stable anchor for the threshold step.
  static const Key regionKey = ValueKey('onboarding-threshold-step');

  /// The controller the threshold probes are scored through (ENGINE-6).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Threshold probing'),
        TextButton(onPressed: null, child: Text('I can see it')),
        TextButton(onPressed: null, child: Text("I can't see it")),
      ],
    );
  }
}
