import 'package:flutter/material.dart';

/// The bs-07 CVD self-assessment entry — a placeholder this feature owns until
/// bs-07 is built (bs-06 D-7).
///
/// AC-11's vision-profile card (E30) routes here when the painter chooses to
/// retake the self-assessment; bs-06 only reads the estimate and navigates, it
/// never writes the profile. bs-07 (CVD self-assessment) replaces this screen
/// behind the same `AppRouter.toSelfAssessment` route, so the card's navigation
/// and the acceptance test that observes it stay unchanged when bs-07 lands. The
/// screen carries [screenKey] so that test has a stable anchor for the
/// destination.
class SelfAssessmentEntryScreen extends StatelessWidget {
  const SelfAssessmentEntryScreen({super.key});

  /// Stable anchor for the self-assessment entry destination (AC-11).
  static const Key screenKey = ValueKey('self-assessment-entry-screen');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: screenKey,
      appBar: AppBar(title: const Text('CVD self-assessment')),
      body: const SafeArea(
        child: Center(
          child: Text('The CVD self-assessment is built in bs-07.'),
        ),
      ),
    );
  }
}
