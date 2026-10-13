import 'package:flutter/material.dart';

import '../onboarding/screens/onboarding_host.dart';

/// The CVD self-assessment entry (bs-06 D-7, built out in bs-07).
///
/// AC-11's vision-profile card (E30) routes here via `AppRouter.toSelfAssessment`
/// when the painter chooses to retake the self-assessment. bs-06 shipped a
/// placeholder behind this route; **bs-07 FLOW-1 replaces it** with the real
/// onboarding flow — an [OnboardingHost] that owns the assessment controller and
/// mounts the profile/onboarding read endpoints. The card's navigation and the
/// acceptance test that observes it are unchanged: this screen still carries the
/// stable [screenKey] anchor, now placed on the [OnboardingHost]'s scaffold.
class SelfAssessmentEntryScreen extends StatelessWidget {
  const SelfAssessmentEntryScreen({super.key});

  /// Stable anchor for the self-assessment entry destination (AC-11).
  static const Key screenKey = ValueKey('self-assessment-entry-screen');

  @override
  Widget build(BuildContext context) {
    return const OnboardingHost(scaffoldKey: screenKey);
  }
}
