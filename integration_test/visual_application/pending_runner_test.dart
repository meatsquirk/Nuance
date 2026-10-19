// CHROME-1 (scaffold) self-test for the bs-18 `BS18_RUN_PENDING` pending runner.
//
// Proves the runner tooling works *both directions* — the scaffold-stage
// equivalent of the coverage gate's "passes clean / fails on a planted gap":
//   * a pending AC is SKIPPED in the default run and RUNS under the flag, and
//   * an un-pended AC always runs;
// plus the integrity invariants ITEST-1's harness guard will later rely on
// (every pending owner is a known behaviour phase; the seed matches the master
// plan's AC coverage table).
//
// Runs on the flutter-tester lane like the rest of the acceptance suite; it has
// no widgets to pump, so it is a plain unit-style group over the runner's pure
// functions. ITEST-1 replaces/extends these with the full harness guard tests.
//
// ignore_for_file: constant_identifier_names

import 'package:flutter_test/flutter_test.dart';

import 'pending.dart';

void main() {
  group('BS18_RUN_PENDING runner — both directions', () {
    test('a pending AC is skipped by default and runs under the flag', () {
      // AC-1 is seeded pending (owner CHROME-3).
      expect(pendingACs.containsKey('AC-1'), isTrue,
          reason: 'AC-1 must be seeded pending for this proof');

      // Default run: the AC is skipped with an owner-naming reason.
      final defaultReason = pendingSkipReason('AC-1', forceRunPending: false);
      expect(defaultReason, isNotNull);
      expect(defaultReason, contains('CHROME-3'));
      expect(defaultReason, contains('--dart-define=BS18_RUN_PENDING=true'));

      // Run-pending: the same AC executes (no skip reason).
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
    });

    test('an un-pended AC always runs, in either mode', () {
      const unpended = 'AC-NOT-SEEDED';
      expect(pendingACs.containsKey(unpended), isFalse);
      expect(pendingSkipReason(unpended, forceRunPending: false), isNull);
      expect(pendingSkipReason(unpended, forceRunPending: true), isNull);
    });

    test('un-pending an AC = removing it makes it run by default', () {
      // Simulate the behaviour-phase edit (deleting the row) by checking a key
      // that is absent: it must then run with no skip reason by default.
      const alreadyUnpended = 'AC-99';
      expect(pendingACs.containsKey(alreadyUnpended), isFalse);
      expect(pendingSkipReason(alreadyUnpended, forceRunPending: false), isNull);
    });
  });

  group('runner integrity invariants', () {
    test('every pending AC names a known behaviour phase as its owner', () {
      for (final entry in pendingACs.entries) {
        expect(behaviorPhases.contains(entry.value), isTrue,
            reason: '${entry.key} owner "${entry.value}" is not a '
                'behaviour phase');
      }
    });

    test('the seed matches the master plan AC coverage table (all 14 ACs)', () {
      const expected = <String, String>{
        'AC-1': 'CHROME-3',
        'AC-2': 'CHROME-4',
        'AC-3': 'READ-1',
        'AC-4': 'READ-2',
        'AC-5': 'READ-3',
        'AC-6': 'FLOW-1',
        'AC-7': 'FLOW-2',
        'AC-8': 'ORG-1',
        'AC-9': 'ORG-2',
        'AC-10': 'CFG-1',
        'AC-11': 'GUARD-2',
        'AC-12': 'GUARD-1',
        'AC-13': 'GUARD-3',
        'AC-14': 'GUARD-2',
      };
      expect(pendingACs, equals(expected));
    });

    // Wiring smoke: acTestWidgets must register without throwing for both a
    // pending and an un-pended AC. The gating logic itself (skip-by-default vs
    // run-under-flag) is proven deterministically by the forceRunPending tests
    // above; the body here is benign so this self-test never pollutes the
    // red-baseline run. ITEST AC tests supply the real assertions.
    acTestWidgets('AC-1', 'pending-AC wiring smoke', (tester) async {
      expect(pendingACs.containsKey('AC-1'), isTrue);
    });
    acTestWidgets('AC-NOT-SEEDED', 'unpended-AC wiring smoke', (tester) async {
      expect(pendingACs.containsKey('AC-NOT-SEEDED'), isFalse);
    });
  });
}
