import 'package:flutter/material.dart';

/// The vision-profile card on the Palette screen (wireframe S1.R1, element E30).
///
/// Shows the painter's current colour-vision estimate and offers to retake the
/// CVD self-assessment (AC-11). This shell renders a labelled placeholder and
/// an inert retake control; SCREEN-3 reads the injected `CvdProfile` to show the
/// real estimate (e.g. "deutan-type, moderate") and wires the retake control to
/// navigate to the bs-07 self-assessment entry (D-7, the placeholder route this
/// phase adds). The card keeps its [regionKey] and the control its [retakeKey]
/// so the acceptance finder and SCREEN-3 have stable anchors.
class VisionProfileCard extends StatelessWidget {
  const VisionProfileCard({super.key});

  /// Stable anchor for the vision-profile card (AC-11).
  static const Key regionKey = ValueKey('palette-vision-profile-card');

  /// Stable anchor for the E30 retake control (wired by SCREEN-3, AC-11).
  static const Key retakeKey = ValueKey('palette-retake-assessment-button');

  @override
  Widget build(BuildContext context) {
    return Card(
      key: regionKey,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vision profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // SCREEN-3 renders the current estimate here from the injected
            // CvdProfile (AC-11).
            const Text('Your current estimate is shown here'),
            // E30 Retake the self-assessment — wired by SCREEN-3 (AC-11) to the
            // bs-07 entry route. Inert in this shell.
            TextButton(
              key: retakeKey,
              onPressed: null,
              child: const Text('Retake the self-assessment'),
            ),
          ],
        ),
      ),
    );
  }
}
