import 'package:flutter/material.dart';

/// The speak region of the Correction screen (wireframe element **E27** — "Speak
/// correction").
///
/// Carries the control that speaks the difference and the paints to add as one
/// utterance (AC-7), through the controller's injected speech seam.
///
/// This is the SCREEN-1 **shell**: the control is disabled until LOOP-4 wires
/// [CorrectionController.speakCorrection] to it. The region keeps its [regionKey]
/// as a stable anchor for the acceptance smoke test and the behaviour phases.
class SpeakRegion extends StatelessWidget {
  const SpeakRegion({super.key});

  /// Stable anchor for the speak region.
  static const Key regionKey = ValueKey('correction-speak-region');

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E27 Speak correction — wired by LOOP-4 (AC-7). Disabled in this shell.
        TextButton(
          onPressed: null,
          child: Text('Speak correction'),
        ),
      ],
    );
  }
}
