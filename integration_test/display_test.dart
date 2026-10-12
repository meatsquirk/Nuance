// Acceptance suite for bs-08 Display, simulation and spoken output.
//
// DISPLAY-1 (scaffold) lands this runner target with the pending-gate skeleton
// (`bs08/pending.dart`, all 10 ACs pending) and a single integrity guard so the
// scaffold cannot pass vacuously: the pending map must cover exactly AC-1..AC-10
// and every owner must be a real bs-08 behaviour phase.
//
// ITEST-1 builds the bs-08 harness (Given/When/Then vocabulary + fixtures + the
// independent reference projection) in `display_harness.dart` and adds a
// never-pending smoke test proving the shells wire end to end; ITEST-2/3
// register one *pending* `acTestWidgets` per AC; the behaviour phases un-pend
// each by deleting its row in `bs08/pending.dart`.
//
// Default `flutter test integration_test/display_test.dart -d <udid>` skips
// pending ACs; `--dart-define=BS08_RUN_PENDING=true` runs them (red baseline /
// un-pend run). A booted device udid is mandatory — without `-d` the run
// executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'bs08/pending.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-08 pending gate (scaffold guard)', () {
    test('pending map covers exactly AC-1..AC-10', () {
      final expected = {for (var i = 1; i <= 10; i++) 'AC-$i'};
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-08 '
              'behaviour phase',
        );
      }
    });

    test('pendingSkipReason skips a pending AC by default, runs it when forced',
        () {
      expect(pendingSkipReason('AC-1'), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An AC absent from the map (un-pended) always runs.
      expect(pendingSkipReason('AC-999'), isNull);
    });
  });
}
