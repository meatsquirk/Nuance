import 'package:flutter/material.dart';

import '../engine/assessment_engine.dart';
import '../engine/tier_results.dart';
import '../onboarding_controller.dart';

/// The Tier 1 intake step (wireframe S1.R1.E37 intake question answers
/// [button]/[body]; AC-3, AC-4).
///
/// Asks the intake questions that form the starting prior and offers the
/// prior-diagnosis entry. ENGINE-3 wires the red-green confusion answers so each
/// moves the prior through `answerIntake`; the prior-diagnosis entry stays inert
/// (`onPressed: null`) until ENGINE-4 wires `reportDiagnosis`.
class IntakeStep extends StatelessWidget {
  /// Creates the intake step over [controller].
  const IntakeStep({required this.controller, super.key});

  /// Stable anchor for the intake step.
  static const Key regionKey = ValueKey('onboarding-intake-step');

  /// The confusion-frequency answers offered for the red-green intake question
  /// (AC-3), from strongest lean to none.
  static const List<String> confusionAnswers = ['Often', 'Sometimes', 'Never'];

  /// The controller the intake answers act on (ENGINE-3/ENGINE-4).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Do reds, browns and greens get mixed up?'),
        for (final answer in confusionAnswers) _answerButton(answer),
        const Text('Prior clinical diagnosis (optional)'),
        const TextButton(onPressed: null, child: Text('I have a diagnosis')),
      ],
    );
  }

  /// A red-green confusion-frequency answer button wired to record [label]
  /// toward the starting prior (AC-3).
  Widget _answerButton(String label) => TextButton(
        onPressed: () => controller.answerIntake(
          IntakeAnswer(questionId: rgConfusionQuestionId, value: label),
        ),
        child: Text(label),
      );
}
