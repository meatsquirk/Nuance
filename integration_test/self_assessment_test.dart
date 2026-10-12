// Acceptance suite for bs-07 CVD self-assessment (onboarding).
//
// ENGINE-1 (scaffold) lands the runner target with the pending-gate skeleton
// (`bs07/pending.dart`, all 14 ACs pending) and the integrity guards so the
// scaffold cannot pass vacuously. No AC tests and no app-boot smoke test exist
// yet — those arrive in stage 3:
//   * ITEST-1 adds the bs-07 harness (`self_assessment_harness.dart` —
//     Given/When/Then vocabulary + fixtures + the independent references) and a
//     never-pending smoke test proving the shells boot to the onboarding host.
//   * ITEST-2/3 register one *pending* `acTestWidgets` per AC here; the
//     behaviour phases un-pend each by deleting its row in `bs07/pending.dart`.
//
// Default `flutter test integration_test/self_assessment_test.dart -d <udid>`
// skips pending ACs; `--dart-define=BS07_RUN_PENDING=true` runs them (red
// baseline / un-pend run). A booted device udid is mandatory once AC tests land
// — without `-d` the app-boot tests execute zero tests and still exit 0 (false
// green; carried flake from bs-04/bs-06). The scaffold-guard group below is
// plain `test()`, so it runs on the host and keeps the gate honest even now.

import 'package:flutter_test/flutter_test.dart';

import 'bs07/pending.dart';

void main() {
  // -------------------------------------------------------------------------
  // Pending-gate scaffold guards (ENGINE-1) — kept so the gate stays honest as
  // ACs land. While an AC is pending, guard 3 asserts it is skipped by default
  // and runs only when forced; as each behaviour phase deletes its row the
  // expected set below must shrink to match (non-vacuous).
  // -------------------------------------------------------------------------

  group('bs-07 pending gate (scaffold guard)', () {
    test('pending map is exactly the still-pending ACs (shrinks as they land)',
        () {
      // Seeded with AC-1..AC-14 (ENGINE-1); each behaviour phase deletes its
      // AC's row here as it un-pends it, so this set shrinks by one per
      // delivered AC. None delivered yet — all 14 are pending.
      const expected = <String>{
        'AC-1',
        'AC-2',
        'AC-3',
        'AC-4',
        'AC-5',
        'AC-6',
        'AC-7',
        'AC-8',
        'AC-9',
        'AC-10',
        'AC-11',
        'AC-12',
        'AC-13',
        'AC-14',
      };
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-07 '
              'behaviour phase',
        );
      }
    });

    test('pendingSkipReason skips pending ACs by default and runs them forced',
        () {
      for (var i = 1; i <= 14; i++) {
        final ac = 'AC-$i';
        // Pending ⇒ skipped in the default pass…
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending — it must be skipped in the default pass');
        // …but executes in the run-pending pass.
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac is pending — it must run in the run-pending pass');
      }
      // An id absent from the map always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
    });
  });
}
