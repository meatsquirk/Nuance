import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The onboarding progress indicator: the current top-level step against the
/// total (wireframe S1.R1 — step progress [body]; AC-14).
///
/// Reads [OnboardingController.state]'s `stepIndex` and the controller's
/// [OnboardingController.stepTotal] and reads them back as text (never position
/// alone). FLOW-2 implemented the step advance and pinned the concrete four
/// steps (G-5 ✅) so "the second of four steps" reads correctly as the painter
/// moves through the flow.
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
