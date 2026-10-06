import 'package:flutter/material.dart';

import 'readout_controller.dart';

/// The actions bar: speak the readout, carry it into a comparison, start a
/// recipe search, acknowledge a fresh capture (AC-8, AC-9, AC-10, AC-11, AC-12).
///
/// Shell placeholder: every action renders as a labelled, findable control with
/// a stable anchor, but none is wired yet — each stays disabled until its
/// behaviour phase connects it (speak + acknowledge → A11Y-2; compare-as-A/B and
/// find-recipes → READOUT-6). The shell implements no handoff.
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

  /// The controller the behaviour phases drive the actions through (unused in
  /// the shell — the controls are disabled placeholders here).
  final ReadoutController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: barKey,
      spacing: 8,
      children: const [
        // Wired by the behaviour phases; disabled placeholders in the shell.
        OutlinedButton(
          key: speakKey,
          onPressed: null,
          child: Text('Speak this readout'),
        ),
        OutlinedButton(
          key: compareAKey,
          onPressed: null,
          child: Text('Compare as A'),
        ),
        OutlinedButton(
          key: compareBKey,
          onPressed: null,
          child: Text('Compare as B'),
        ),
        OutlinedButton(
          key: recipesKey,
          onPressed: null,
          child: Text('Find mixing recipes'),
        ),
        OutlinedButton(
          key: acknowledgeKey,
          onPressed: null,
          child: Text('Acknowledge'),
        ),
      ],
    );
  }
}
