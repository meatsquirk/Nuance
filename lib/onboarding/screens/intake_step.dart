import 'package:flutter/material.dart';

import '../../a11y/cvd/cvd_profile.dart';
import '../engine/assessment_engine.dart';
import '../engine/tier_results.dart';
import '../onboarding_controller.dart';

/// The Tier 1 intake step (wireframe S1.R1.E37 intake question answers
/// [button]/[body]; AC-3, AC-4).
///
/// Asks the intake questions that form the starting prior and offers the
/// prior-diagnosis entry. ENGINE-3 wires the red-green confusion answers so each
/// moves the prior through `answerIntake`; ENGINE-4 wires the prior-diagnosis
/// entry: tapping "I have a diagnosis" reveals a type picker whose choices seed
/// the prior through `reportDiagnosis`.
class IntakeStep extends StatefulWidget {
  /// Creates the intake step over [controller].
  const IntakeStep({required this.controller, super.key});

  /// Stable anchor for the intake step.
  static const Key regionKey = ValueKey('onboarding-intake-step');

  /// The confusion-frequency answers offered for the red-green intake question
  /// (AC-3), from strongest lean to none.
  static const List<String> confusionAnswers = ['Often', 'Sometimes', 'Never'];

  /// The label the type picker offers for each diagnosable [CvdType] (AC-4).
  ///
  /// Both the picker buttons and the acceptance driver (`whenReportDiagnosis`)
  /// key off this map, so a reported type always finds its button.
  static const Map<CvdType, String> diagnosisTypeLabels = {
    CvdType.protan: 'Protan (red-weak)',
    CvdType.deutan: 'Deutan (green-weak)',
    CvdType.tritan: 'Tritan (blue-weak)',
  };

  /// The controller the intake answers act on (ENGINE-3/ENGINE-4).
  final OnboardingController controller;

  @override
  State<IntakeStep> createState() => _IntakeStepState();
}

class _IntakeStepState extends State<IntakeStep> {
  /// Whether the prior-diagnosis type picker is revealed (AC-4). Starts closed;
  /// "I have a diagnosis" opens it.
  bool _diagnosisOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: IntakeStep.regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Do reds, browns and greens get mixed up?'),
        for (final answer in IntakeStep.confusionAnswers) _answerButton(answer),
        const Text('Prior clinical diagnosis (optional)'),
        TextButton(
          onPressed: () => setState(() => _diagnosisOpen = true),
          child: const Text('I have a diagnosis'),
        ),
        if (_diagnosisOpen)
          for (final entry in IntakeStep.diagnosisTypeLabels.entries)
            _diagnosisButton(entry.key, entry.value),
      ],
    );
  }

  /// A red-green confusion-frequency answer button wired to record [label]
  /// toward the starting prior (AC-3).
  Widget _answerButton(String label) => TextButton(
        onPressed: () => widget.controller.answerIntake(
          IntakeAnswer(questionId: rgConfusionQuestionId, value: label),
        ),
        child: Text(label),
      );

  /// A diagnosis type-picker button that seeds the prior as [type] (AC-4).
  Widget _diagnosisButton(CvdType type, String label) => TextButton(
        onPressed: () => widget.controller.reportDiagnosis(type),
        child: Text(label),
      );
}
