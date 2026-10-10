// Acceptance suite for bs-06 Palette and projects.
//
// DATA-1 (scaffold) lands this runner target with the pending-gate skeleton
// (`bs06/pending.dart`, all 11 ACs pending) and a single integrity guard so the
// scaffold cannot pass vacuously: the pending map must cover exactly AC-1..AC-11
// and every owner must be a real bs-06 behaviour phase.
//
// ITEST-1 builds the bs-06 harness (Given/When/Then vocabulary + fixtures) here
// and adds a never-pending smoke test proving the shells wire end to end;
// ITEST-2/3 register one *pending* `acTestWidgets` per AC; the behaviour phases
// un-pend each by deleting its row in `bs06/pending.dart`.
//
// Default `flutter test integration_test/palette_test.dart -d <udid>` skips
// pending ACs; `--dart-define=BS06_RUN_PENDING=true` runs them (red baseline /
// un-pend run). A booted device udid is mandatory — without `-d` the run
// executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'bs06/pending.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-06 pending gate (scaffold guard)', () {
    test('pending map covers exactly AC-1..AC-11', () {
      final expected = {for (var i = 1; i <= 11; i++) 'AC-$i'};
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-06 '
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
