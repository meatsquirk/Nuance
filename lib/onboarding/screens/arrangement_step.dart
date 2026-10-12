import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The Tier 3 arrangement step (wireframe S1.R1.E38 arrange colour caps
/// [button], E39 start the arrangement over [button], E43 skip [button]; AC-6,
/// AC-7, AC-8).
///
/// Shows the pool of unplaced caps, the arranged order, and the start-over /
/// skip controls, reading the counts back from [OnboardingController.state]. The
/// FLOW-1 shell renders the controls **inert** (`onPressed: null`): FLOW-4 wires
/// `placeCap` (pool → next position), `startOver` (all caps back to the pool)
/// and `skipArrangement` (continue with no arrangement result).
class ArrangementStep extends StatelessWidget {
  /// Creates the arrangement step over [controller].
  const ArrangementStep({required this.controller, super.key});

  /// Stable anchor for the arrangement step.
  static const Key regionKey = ValueKey('onboarding-arrangement-step');

  /// Stable anchor for the pool of unplaced caps (E38).
  static const Key poolKey = ValueKey('onboarding-arrangement-pool');

  /// Stable anchor for the arranged order (E38).
  static const Key arrangedKey = ValueKey('onboarding-arrangement-arranged');

  /// Stable anchor for the start-over control (E39).
  static const Key startOverKey = ValueKey('onboarding-arrangement-start-over');

  /// Stable anchor for the skip control (E43).
  static const Key skipKey = ValueKey('onboarding-arrangement-skip');

  /// The controller the place / start-over / skip actions act on (FLOW-4).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Arrange the colour caps in hue order'),
        Text('Pool: ${state.arrangementPool.length} caps', key: poolKey),
        Text('Arranged: ${state.arrangedCaps.length}', key: arrangedKey),
        const TextButton(
          key: startOverKey,
          onPressed: null,
          child: Text('Start over'),
        ),
        const TextButton(
          key: skipKey,
          onPressed: null,
          child: Text('Skip for now'),
        ),
      ],
    );
  }
}
