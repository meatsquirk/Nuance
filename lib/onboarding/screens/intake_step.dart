import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The Tier 1 intake step (wireframe S1.R1.E37 intake question answers
/// [button]/[body]; AC-3, AC-4).
///
/// Asks the intake questions that form the starting prior and offers the
/// prior-diagnosis entry. The FLOW-1 shell renders the answer controls **inert**
/// (`onPressed: null`): ENGINE-3 wires `answerIntake` so an answer moves the
/// prior, and ENGINE-4 wires `reportDiagnosis` so a reported diagnosis seeds it.
class IntakeStep extends StatelessWidget {
  /// Creates the intake step over [controller].
  const IntakeStep({required this.controller, super.key});

  /// Stable anchor for the intake step.
  static const Key regionKey = ValueKey('onboarding-intake-step');

  /// The controller the intake answers act on (ENGINE-3/ENGINE-4).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Do reds, browns and greens get mixed up?'),
        TextButton(onPressed: null, child: Text('Often')),
        TextButton(onPressed: null, child: Text('Sometimes')),
        TextButton(onPressed: null, child: Text('Never')),
        Text('Prior clinical diagnosis (optional)'),
        TextButton(onPressed: null, child: Text('I have a diagnosis')),
      ],
    );
  }
}
