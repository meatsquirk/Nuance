import 'package:flutter/material.dart';

import '../correction_controller.dart';
import '../correction_speech.dart';

/// The speak region of the Correction screen (wireframe element **E27** — "Speak
/// correction").
///
/// Carries the control that speaks the difference and the paints to add as one
/// utterance (AC-7), through the controller's injected speech seam.
///
/// The "Speak correction" control is wired to
/// [CorrectionController.speakCorrection] (LOOP-4, AC-7) and is enabled only once
/// the mix has been checked — there is nothing to speak before then, so
/// [correctionSpeech] is null and the control stays disabled (mirroring the
/// comparison screen's E6). The region keeps its [regionKey] as a stable anchor
/// for the acceptance smoke test and the behaviour phases.
class SpeakRegion extends StatelessWidget {
  const SpeakRegion({required this.controller, super.key});

  /// Stable anchor for the speak region.
  static const Key regionKey = ValueKey('correction-speak-region');

  /// The controller supplying the checked mix's state and the speak action.
  final CorrectionController controller;

  @override
  Widget build(BuildContext context) {
    // Nothing to speak until the mix is checked ([correctionSpeech] null).
    final canSpeak = correctionSpeech(controller.state) != null;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E27 Speak correction (AC-7): speaks the difference and the paints to
        // add as one utterance through the controller.
        TextButton(
          onPressed: canSpeak ? () => controller.speakCorrection() : null,
          child: const Text('Speak correction'),
        ),
      ],
    );
  }
}
