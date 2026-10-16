// BS14 Peer-to-peer-evidence-sharing acceptance-suite pending gate
// (scaffold skeleton, CORE-1).
//
// This is the bs-14 mirror of bs-13's `integration_test/bs13/pending.dart`
// (itself a mirror of bs-10/bs-09/bs-06/bs-04/bs-03/bs-02's pending files and
// bs-01's mechanism in `integration_test/harness.dart`): the plumbing that lets
// stage 3 land one *pending* integration test per AC while the suite stays
// green, then un-pend each AC as its behaviour phase lands.
//
// CORE-1 (this scaffold phase) seeds only the gate mechanism and the AC/phase
// bookkeeping — **no tests, harness or fixtures yet**. ITEST-1 adds the harness
// (the two-install fake `PeerTransport` loopback), the fixtures and the smoke
// test; ITEST-2/3/4 register the per-AC tests via [acTestWidgets] / [acTest];
// the behaviour phases (CORE-3/4, RECORD-2/3, MERGE-2/3/4/5, EXCHANGE-2/3)
// un-pend their AC by deleting its row from [pendingACs].
//
// Keyed to `BS14_RUN_PENDING` so a bs-14 run-pending pass is independent of the
// other features' `BS0n_RUN_PENDING` / `BS1n_RUN_PENDING` flags.
//
// AC ids mirror the plan's `AC-n` names verbatim, so this file opts out of
// lowerCamelCase for them.
// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pending gate
// ---------------------------------------------------------------------------

/// Maps each still-pending AC to the behaviour phase that un-pends it.
///
/// An AC is *pending* while its key is present; the named phase un-pends it by
/// deleting the row. The default
/// `flutter test integration_test/bs14/sharing_test.dart -d flutter-tester`
/// skips pending ACs (their bodies, which assert un-built behaviour, never
/// run); set `--dart-define=BS14_RUN_PENDING=true` (or host env
/// `BS14_RUN_PENDING=1`) to execute them (the red-baseline / un-pend run).
///
/// Seeded with all 12 bs-14 ACs here in CORE-1; each behaviour phase then
/// removes the row it owns as it un-pends that AC. Every owner must be a member
/// of [behaviorPhases]. The owner is the phase whose acceptance gate un-pends
/// the AC, matching the master plan's AC-coverage table:
///   AC-1  → CORE-3       (opt in once, never shown the mechanism)
///   AC-2  → CORE-4       (no per-exchange action)
///   AC-3  → RECORD-2     (record carries only the mapping evidence)
///   AC-4  → RECORD-2     (nothing personal leaves the device)
///   AC-5  → RECORD-3     (no declared palette ⇒ not shared)
///   AC-6  → EXCHANGE-2   (exchange only the records each is missing)
///   AC-7  → EXCHANGE-3   (no peer ⇒ no exchange, no wait)
///   AC-8  → MERGE-3      (clustered crowd records refine an Estimated value)
///   AC-9  → MERGE-4      (crowd evidence never promotes to Confirmed)
///   AC-10 → MERGE-2      (append-only, source-tagged merge)
///   AC-11 → MERGE-3      (statistical outliers discarded)
///   AC-12 → MERGE-5      (per-source rate limit)
const Map<String, String> pendingACs = {
  // AC-1 un-pended by CORE-3 (opt in once, never shown the mechanism).
  // AC-3, AC-4 un-pended by RECORD-2 (record carries only evidence, nothing
  // personal).
  // AC-5 un-pended by RECORD-3 (no declared palette ⇒ not shared).
  'AC-2': 'CORE-4',
  'AC-6': 'EXCHANGE-2',
  'AC-7': 'EXCHANGE-3',
  'AC-8': 'MERGE-3',
  'AC-9': 'MERGE-4',
  'AC-10': 'MERGE-2',
  'AC-11': 'MERGE-3',
  'AC-12': 'MERGE-5',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests (added in ITEST-1) to reject a typo'd
/// or stale owner in [pendingACs]. These are the bs-14 behaviour phases from the
/// master plan's build order.
const Set<String> behaviorPhases = {
  'CORE-3',
  'CORE-4',
  'RECORD-2',
  'RECORD-3',
  'MERGE-2',
  'MERGE-3',
  'MERGE-4',
  'MERGE-5',
  'EXCHANGE-2',
  'EXCHANGE-3',
};

/// The behaviour phases that have completed and un-pended every AC they own.
///
/// A completed phase legitimately owns no row in [pendingACs] any more, so the
/// harness's "no dead phase" guard treats a phase as valid when it is still a
/// pending owner **or** listed here. Each behaviour phase adds itself here as it
/// un-pends its last AC. CORE-3 (its only AC, AC-1) is the first; RECORD-2
/// (AC-3 + AC-4, both now un-pended) is the second.
const Set<String> completedBehaviorPhases = {'CORE-3', 'RECORD-2', 'RECORD-3'};

/// Every AC id the bs-14 acceptance suite covers (the master plan's 12 ACs).
///
/// The scaffold/harness guard test (ITEST-1) asserts the suite registers exactly
/// these, so a missing or stray AC test can't pass vacuously.
const List<String> allACs = <String>[
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
];

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/…` runs the tests in the app process on the
/// device (here `flutter-tester`), which does not inherit the host shell's
/// environment — so a `BS14_RUN_PENDING=1` env var set on the host never reaches
/// [runPending] there. A compile-time `--dart-define=BS14_RUN_PENDING=true`
/// does. (The [Platform.environment] path below still serves any host-process
/// run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS14_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device / `flutter-tester`: pass `--dart-define=BS14_RUN_PENDING=true`.
/// Host-process runs may also set the `BS14_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS14_RUN_PENDING'] == '1';

/// The reason to skip [acId] in this run, or null if it should execute.
///
/// An un-pended AC (absent from [pendingACs]) always runs; a pending AC runs
/// only in run-pending mode. Because the result drives the test runner's native
/// `skip`, a not-yet-built AC's body never executes in the default run — it is
/// *skipped*, never *failed*. [forceRunPending] overrides the ambient
/// [runPending] mode so the gate's own tests can assert both modes
/// deterministically without touching the environment.
String? pendingSkipReason(String acId, {bool? forceRunPending}) {
  final owner = pendingACs[acId];
  if (owner == null) return null;
  if (forceRunPending ?? runPending) return null;
  return 'pending $owner — --dart-define=BS14_RUN_PENDING=true to run';
}

/// Registers a **widget-driven** AC acceptance test wired to the pending gate.
///
/// Used by the ITEST phases for the ACs observed through a widget read endpoint
/// (e.g. AC-1/AC-2's opt-in surface and no-per-exchange signalling); skipping
/// follows [pendingSkipReason].
void acTestWidgets(
  String acId,
  String description,
  WidgetTesterCallback body,
) {
  final reason = pendingSkipReason(acId);
  final name = reason == null
      ? '$acId: $description'
      : '$acId: $description ($reason)';
  testWidgets(name, body, skip: reason != null);
}

/// Registers a **pure-Dart** AC acceptance test wired to the pending gate.
///
/// Used by the ITEST phases for the ACs that need no widget tree — the record,
/// exchange and merge logic observed through the sharing read endpoints;
/// skipping follows [pendingSkipReason].
void acTest(
  String acId,
  String description,
  dynamic Function() body,
) {
  final reason = pendingSkipReason(acId);
  final name = reason == null
      ? '$acId: $description'
      : '$acId: $description ($reason)';
  test(name, body, skip: reason ?? false);
}
