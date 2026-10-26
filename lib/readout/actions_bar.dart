import 'package:flutter/material.dart';

import '../app/router.dart';
import '../display/display_scope.dart';
import 'readout_controller.dart';

/// The actions bar: speak the readout, carry it into a comparison, start a
/// recipe search, acknowledge a fresh capture (AC-8, AC-9, AC-10, AC-11, AC-12).
///
/// The navigation handoffs are wired here (READOUT-6): "compare as A"/"B" push
/// the comparison route with the reading in the chosen slot (AC-9, AC-10), and
/// "find mixing recipes" pushes the recipes route with the reading as the target
/// (AC-11). "Speak this readout" drives [ReadoutController.speak] (AC-8); when the
/// reading is just-captured a "Just captured" marker shows and "Acknowledge"
/// clears it via [ReadoutController.acknowledge] (AC-12) — otherwise acknowledge
/// is disabled (A11Y-2).
///
/// The Speak control is an accessibility affordance (bs-20 AC-7/AC-8): it is
/// shown only when the painter has turned on accessibility features, read live
/// through [DisplayScope] so toggling the setting reveals or hides it in place.
/// It is hidden by default — the shipped readout stays uncluttered until asked.
class ActionsBar extends StatelessWidget {
  const ActionsBar({required this.controller, super.key});

  /// Stable anchor for the actions bar.
  static const Key barKey = ValueKey('readout-actions-bar');

  /// Stable anchor for the "speak this readout" action (A11Y-2).
  static const Key speakKey = ValueKey('readout-action-speak');

  /// Stable anchor for the "compare as A" action (READOUT-6).
  static const Key compareAKey = ValueKey('readout-action-compare-a');

  /// Stable anchor for the "compare as B" action (READOUT-6).
  static const Key compareBKey = ValueKey('readout-action-compare-b');

  /// Stable anchor for the "find mixing recipes" action (READOUT-6).
  static const Key recipesKey = ValueKey('readout-action-recipes');

  /// Stable anchor for the "acknowledge captured reading" action (A11Y-2).
  static const Key acknowledgeKey = ValueKey('readout-action-acknowledge');

  /// Stable anchor for the "just captured" marker shown until acknowledged
  /// (A11Y-2, AC-12).
  static const Key justCapturedKey = ValueKey('readout-just-captured');

  /// The controller the actions drive through: its [ReadoutController.sample]
  /// is the reading carried into the comparison / recipes handoffs.
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    // Show Speak only while accessibility features are on (AC-7/AC-8). Read via
    // DisplayScope so flipping the setting rebuilds the bar in place; outside the
    // app assembly (no scope — standalone rendering) it defaults to hidden,
    // mirroring the shipped `DisplaySettings` default (accessibility off).
    final showSpeak =
        DisplayScope.maybeOf(context)?.settings.accessibilityFeatures ?? false;
    return Wrap(
      key: barKey,
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (showSpeak)
          OutlinedButton(
            key: speakKey,
            onPressed: () => controller.speak(),
            child: const Text('Speak this readout'),
          ),
        OutlinedButton(
          key: compareAKey,
          onPressed: () => Navigator.of(context)
              .push(controller.comparisonRoute(ComparisonSlot.a)),
          child: const Text('Compare as A'),
        ),
        OutlinedButton(
          key: compareBKey,
          onPressed: () => Navigator.of(context)
              .push(controller.comparisonRoute(ComparisonSlot.b)),
          child: const Text('Compare as B'),
        ),
        OutlinedButton(
          key: recipesKey,
          onPressed: () =>
              Navigator.of(context).push(controller.recipesRoute()),
          child: const Text('Find mixing recipes'),
        ),
        // A freshly captured reading shows the marker and enables Acknowledge;
        // otherwise the marker is absent and Acknowledge is disabled (AC-12).
        if (controller.justCaptured)
          const Text('Just captured', key: justCapturedKey),
        OutlinedButton(
          key: acknowledgeKey,
          onPressed: controller.justCaptured ? controller.acknowledge : null,
          child: const Text('Acknowledge'),
        ),
      ],
    );
  }
}
