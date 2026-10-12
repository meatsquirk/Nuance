import 'package:flutter/material.dart';

import '../a11y/cvd/cvd_profile.dart';
import '../app/router.dart';

/// The vision-profile card on the Palette screen (wireframe S1.R1, element E30).
///
/// Shows the painter's current colour-vision estimate from the injected
/// [profile] (AC-11) — the dichromacy class and a plain-word severity, e.g.
/// "deutan-type, moderate" — and offers to retake the CVD self-assessment:
/// choosing "retake the self-assessment" (E30) navigates via [router] to the
/// bs-07 self-assessment entry placeholder (`AppRouter.toSelfAssessment`, D-7).
/// bs-06 only *reads* the estimate and navigates; it never writes the profile
/// (bs-07 populates it). The card keeps its [regionKey] and the control its
/// [retakeKey] so the acceptance finder has stable anchors.
class VisionProfileCard extends StatelessWidget {
  const VisionProfileCard({
    required this.profile,
    required this.router,
    super.key,
  });

  /// Stable anchor for the vision-profile card (AC-11).
  static const Key regionKey = ValueKey('palette-vision-profile-card');

  /// Stable anchor for the E30 retake control (AC-11).
  static const Key retakeKey = ValueKey('palette-retake-assessment-button');

  /// The painter's current colour-vision estimate (D-7), read-only here.
  final CvdProfile profile;

  /// Typed navigation used to open the self-assessment entry (D-7).
  final AppRouter router;

  /// The estimate as shown on the card: the dichromacy class plus a plain-word
  /// severity, e.g. "deutan-type, moderate" (AC-11).
  String get _estimate =>
      '${profile.type.name}-type, ${_severityWord(profile.severity)}';

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
            Text('Your current estimate is $_estimate'),
            // E30 Retake the self-assessment — opens the bs-07 entry (D-7).
            TextButton(
              key: retakeKey,
              onPressed: () =>
                  Navigator.of(context).push(router.toSelfAssessment()),
              child: const Text('Retake the self-assessment'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Maps a [CvdProfile.severity] (0..1) to the plain word the card shows, so the
/// estimate reads naturally (e.g. "moderate" for a mid deuteranomaly).
String _severityWord(double severity) {
  if (severity < 1 / 3) return 'mild';
  if (severity < 2 / 3) return 'moderate';
  return 'strong';
}
