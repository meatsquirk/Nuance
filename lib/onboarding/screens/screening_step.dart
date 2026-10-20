import 'package:flutter/material.dart';

import '../../widgets/surface_card.dart';
import '../engine/tier_results.dart';
import '../onboarding_controller.dart';

/// The Tier 2 pseudoisochromatic screening step (wireframe S1.R1 — screening
/// tier [body]; AC-5).
///
/// Presents the openly-licensed plate deck and lets the painter report, per
/// plate, whether they can read the hidden figure. ENGINE-5 wires the responses
/// through `scoreScreening`: once every plate has a response the whole set is
/// scored into a `ScreeningResult` (presence + the red-green versus blue-yellow
/// direction). The [plateDeck] fixes which confusion axis each plate probes;
/// the painter's per-plate read/can't-read choice is the input the engine
/// scores (the axis the painter fails the more of points the direction).
class ScreeningStep extends StatefulWidget {
  /// Creates the screening step over [controller].
  const ScreeningStep({required this.controller, super.key});

  /// Stable anchor for the screening step.
  static const Key regionKey = ValueKey('onboarding-screening-step');

  /// The fixed deck of plates the painter reads, by the confusion axis each one
  /// probes. Three red-green plates then two blue-yellow plates, so misreading
  /// one axis' plates isolates that direction. The acceptance fixtures are
  /// per-plate response sets over this deck (see the harness).
  static const List<ScreeningDirection> plateDeck = [
    ScreeningDirection.redGreen,
    ScreeningDirection.redGreen,
    ScreeningDirection.redGreen,
    ScreeningDirection.blueYellow,
    ScreeningDirection.blueYellow,
  ];

  /// The key of the "I can read it" control for the plate at [index].
  static Key readKey(int index) => ValueKey('onboarding-screening-read-$index');

  /// The key of the "I can't read it" control for the plate at [index].
  static Key cantReadKey(int index) =>
      ValueKey('onboarding-screening-cant-read-$index');

  /// The controller the screening responses are scored through (ENGINE-5).
  final OnboardingController controller;

  @override
  State<ScreeningStep> createState() => _ScreeningStepState();
}

class _ScreeningStepState extends State<ScreeningStep> {
  /// The painter's response per plate index: true when they read it correctly.
  /// Scoring runs once every plate in [ScreeningStep.plateDeck] is answered.
  final Map<int, bool> _responses = {};

  /// Records the painter's [correct] response for the plate at [index]. Once all
  /// plates are answered, folds the ordered responses through the controller so
  /// the engine scores them into a `ScreeningResult`.
  void _answer(int index, {required bool correct}) {
    setState(() => _responses[index] = correct);
    if (_responses.length == ScreeningStep.plateDeck.length) {
      widget.controller.scoreScreening([
        for (var i = 0; i < ScreeningStep.plateDeck.length; i++)
          PlateResponse(
            axis: ScreeningStep.plateDeck[i],
            correct: _responses[i]!,
          ),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: ScreeningStep.regionKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Plate screening'),
            for (var i = 0; i < ScreeningStep.plateDeck.length; i++) _plate(i),
          ],
        ),
      ),
    );
  }

  /// One plate row: its number and the read / can't-read responses. The controls
  /// go inert once the plate is answered, so each plate is read exactly once.
  Widget _plate(int index) {
    final answered = _responses.containsKey(index);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Plate ${index + 1}'),
        TextButton(
          key: ScreeningStep.readKey(index),
          onPressed: answered ? null : () => _answer(index, correct: true),
          child: const Text('I can read it'),
        ),
        TextButton(
          key: ScreeningStep.cantReadKey(index),
          onPressed: answered ? null : () => _answer(index, correct: false),
          child: const Text("I can't read it"),
        ),
      ],
    );
  }
}
