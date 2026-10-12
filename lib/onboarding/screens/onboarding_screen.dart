import 'package:flutter/material.dart';

import '../onboarding_controller.dart';
import 'arrangement_step.dart';
import 'intake_step.dart';
import 'lighting_step.dart';
import 'progress_region.dart';
import 'result_step.dart';
import 'screening_step.dart';
import 'threshold_step.dart';

/// The self-assessment onboarding surface: the progress indicator and the keyed
/// step widgets the tiered battery runs through (wireframe S1.R1, elements
/// E36–E41, E43).
///
/// A pure view over the [OnboardingController] it is given (owned by
/// [OnboardingHost], which also wraps this subtree in the `CvdProfileReadEndpoint`
/// and `OnboardingReadEndpoint` the acceptance suite observes). It lays out every
/// region — the progress indicator and the lighting, intake, screening,
/// arrangement, threshold and result steps — so the acceptance finders and the
/// behaviour phases have stable anchors. This shell renders placeholders and
/// inert controls; each step's real readout and each action land in their
/// behaviour phase, and the step-by-step presentation is pinned at FLOW-2 once
/// G-5 resolves (the shell lays out all steps as anchors).
///
/// Carries [scaffoldKey] on its [Scaffold] so bs-06's vision-profile card
/// navigation and its acceptance test keep their stable anchor
/// (`ValueKey('self-assessment-entry-screen')`) when bs-07 replaces the
/// placeholder entry screen.
class OnboardingScreen extends StatelessWidget {
  /// Creates the onboarding surface over [controller], keyed by [scaffoldKey].
  const OnboardingScreen({required this.controller, this.scaffoldKey, super.key});

  /// Stable anchor for the "See my result" control that assembles the estimate
  /// and advances to the result step (FLOW-5; `advanceToResult`).
  static const Key seeResultKey = ValueKey('onboarding-see-result');

  /// The key placed on the [Scaffold] — the stable entry anchor (bs-06 D-7).
  final Key? scaffoldKey;

  /// The controller every region reads and (later) acts on.
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: const Text('CVD self-assessment')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            // A SingleChildScrollView + Column (not a lazy ListView) so every
            // keyed step region is built as a stable anchor regardless of the
            // viewport — the shell lays them all out for the acceptance finders
            // and the behaviour phases.
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressRegion(controller: controller),
                  const SizedBox(height: 12),
                  LightingStep(controller: controller),
                  const SizedBox(height: 12),
                  IntakeStep(controller: controller),
                  const SizedBox(height: 12),
                  ScreeningStep(controller: controller),
                  const SizedBox(height: 12),
                  ArrangementStep(controller: controller),
                  const SizedBox(height: 12),
                  ThresholdStep(controller: controller),
                  const SizedBox(height: 12),
                  // Concludes the battery: assembles the estimate from whatever
                  // tiers ran and advances to the result step (FLOW-5). Always
                  // present — the shell lays every step out at once.
                  TextButton(
                    key: seeResultKey,
                    onPressed: controller.advanceToResult,
                    child: const Text('See my result'),
                  ),
                  const SizedBox(height: 12),
                  ResultStep(controller: controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
