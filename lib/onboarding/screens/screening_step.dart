import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The Tier 2 pseudoisochromatic screening step (wireframe S1.R1 — screening
/// tier [body]; AC-5).
///
/// Presents the openly-licensed plate screening and scores presence plus the
/// red-green versus blue-yellow direction. The FLOW-1 shell renders the plate
/// control **inert** (`onPressed: null`): ENGINE-5 wires `scoreScreening` to
/// score the plate responses through the engine into a `ScreeningResult`.
class ScreeningStep extends StatelessWidget {
  /// Creates the screening step over [controller].
  const ScreeningStep({required this.controller, super.key});

  /// Stable anchor for the screening step.
  static const Key regionKey = ValueKey('onboarding-screening-step');

  /// The controller the screening responses are scored through (ENGINE-5).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Plate screening'),
        TextButton(onPressed: null, child: Text('Read the plate')),
      ],
    );
  }
}
