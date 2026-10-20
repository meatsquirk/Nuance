import 'package:flutter/material.dart';

import '../../widgets/surface_card.dart';
import '../onboarding_controller.dart';

/// The Tier 3 arrangement step (wireframe S1.R1.E38 arrange colour caps
/// [button], E39 start the arrangement over [button], E43 skip [button]; AC-6,
/// AC-7, AC-8).
///
/// Shows the pool of unplaced caps as a control per cap, the arranged order, and
/// the start-over / skip controls, reading them back from
/// [OnboardingController.state]. FLOW-4 wires `placeCap` (tap a pooled cap to
/// take the next arranged position), `startOver` (all caps back to the pool) and
/// `skipArrangement` (continue with no arrangement result).
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

  /// The key the place-cap control for [capId] is found by (FLOW-4).
  static Key capKey(int capId) => ValueKey('onboarding-arrangement-cap-$capId');

  /// The controller the place / start-over / skip actions act on (FLOW-4).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          key: regionKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Arrange the colour caps in hue order'),
            // The unplaced caps: tapping one places it in the next arranged
            // position (AC-6). A Wrap keeps the pool compact as it grows/shrinks.
            Wrap(
              key: poolKey,
              spacing: 8,
              children: [
                for (final capId in state.arrangementPool)
                  TextButton(
                    key: capKey(capId),
                    onPressed: () => controller.placeCap(capId),
                    child: Text('Cap $capId'),
                  ),
              ],
            ),
            Text('Arranged: ${state.arrangedCaps.length}', key: arrangedKey),
            TextButton(
              key: startOverKey,
              onPressed: controller.startOver,
              child: const Text('Start over'),
            ),
            TextButton(
              key: skipKey,
              onPressed: controller.skipArrangement,
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
