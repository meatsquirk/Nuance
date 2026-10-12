import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The onboarding progress indicator: the current top-level step against the
/// total (wireframe S1.R1 — step progress [body]; AC-14).
///
/// Reads [OnboardingController.state]'s `stepIndex` and the controller's
/// [OnboardingController.stepTotal] and reads them back as text (never position
/// alone). The FLOW-1 shell renders the current count from the default state
/// (step 1); FLOW-2 implements the step advance and pins the concrete four steps
/// (G-5) so "the second of four steps" reads correctly.
class ProgressRegion extends StatelessWidget {
  /// Creates the progress region over [controller].
  const ProgressRegion({required this.controller, super.key});

  /// Stable anchor for the progress region.
  static const Key regionKey = ValueKey('onboarding-progress-region');

  /// The controller supplying the current step and the step total.
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final current = controller.state.stepIndex + 1;
    return Text(
      'Step $current of ${controller.stepTotal}',
      key: regionKey,
    );
  }
}
