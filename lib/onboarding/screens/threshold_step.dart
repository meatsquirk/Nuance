import 'package:flutter/material.dart';

import '../../widgets/surface_card.dart';
import '../engine/tier_results.dart';
import '../onboarding_controller.dart';

/// The Tier 4 adaptive threshold-probing step (wireframe S1.R1 — threshold tier
/// [body]; AC-9).
///
/// Runs the adaptive probing along the painter's confusion line one probe at a
/// time: each probe presents a stimulus at a fixed contrast from [contrastDeck]
/// and the painter reports whether they can see it ("I can see it" /
/// "I can't see it"). ENGINE-6 wires the responses through `scoreThreshold`:
/// once every probe in the deck is answered the whole set is scored through the
/// engine into a severity (0..1) on the confusion line. The [contrastDeck] fixes
/// the contrast each probe presents; the painter's per-probe see/can't-see
/// choice is the input the engine scores.
class ThresholdStep extends StatefulWidget {
  /// Creates the threshold step over [controller].
  const ThresholdStep({required this.controller, super.key});

  /// Stable anchor for the threshold step.
  static const Key regionKey = ValueKey('onboarding-threshold-step');

  /// The fixed adaptive probe deck: increasing contrasts (0..1) presented along
  /// the painter's confusion line, one probe at a time. The painter reports
  /// whether they detect each; the engine scores the responses into a severity
  /// (the highest contrast they could not see). A short, monotone sequence so
  /// the probe is quick and a higher detection threshold scores a higher
  /// severity.
  static const List<double> contrastDeck = [0.2, 0.4, 0.6, 0.8];

  /// The controller the threshold probes are scored through (ENGINE-6).
  final OnboardingController controller;

  @override
  State<ThresholdStep> createState() => _ThresholdStepState();
}

class _ThresholdStepState extends State<ThresholdStep> {
  /// The painter's detection response per answered probe, in deck order (true
  /// when they saw the stimulus). Scoring runs once every probe in
  /// [ThresholdStep.contrastDeck] is answered.
  final List<bool> _responses = [];

  /// Records the painter's [detected] response for the current probe. Once every
  /// probe in the deck is answered, folds the ordered probes through the
  /// controller so the engine scores them into a `ThresholdResult`.
  void _answer({required bool detected}) {
    setState(() => _responses.add(detected));
    if (_responses.length == ThresholdStep.contrastDeck.length) {
      widget.controller.scoreThreshold([
        for (var i = 0; i < ThresholdStep.contrastDeck.length; i++)
          ThresholdProbe(
            contrast: ThresholdStep.contrastDeck[i],
            detected: _responses[i],
          ),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _responses.length == ThresholdStep.contrastDeck.length;
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: ThresholdStep.regionKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Threshold probing'),
            if (done)
              const Text('Threshold probing complete')
            else ...[
              Text(
                'Probe ${_responses.length + 1} of '
                '${ThresholdStep.contrastDeck.length}',
              ),
              TextButton(
                onPressed: () => _answer(detected: true),
                child: const Text('I can see it'),
              ),
              TextButton(
                onPressed: () => _answer(detected: false),
                child: const Text("I can't see it"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
