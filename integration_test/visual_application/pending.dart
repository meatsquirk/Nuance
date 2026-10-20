// BS18 Apply-visual-components acceptance-suite pending runner (scaffold: CHROME-1).
//
// This is the bs-18 mirror of the sibling per-feature gates (bs-17's
// `integration_test/bs17/pending.dart`, bs-13's `integration_test/bs13/pending.dart`,
// themselves mirrors of bs-02..bs-06's and bs-01's mechanism in
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// CHROME-1 (scaffold) establishes this runner convention and seeds the AC→owner
// map from the master plan's AC coverage table. ITEST-1 builds the bs-18 harness
// (Given/When/Then vocabulary + fixtures) on top of it; ITEST-2/3/4 register the
// 14 ACs via [acTestWidgets] in `integration_test/visual_application/*_test.dart`;
// the behaviour phases un-pend their AC by deleting its row in [pendingACs].
//
// Keyed to `BS18_RUN_PENDING` so a bs-18 run-pending pass is independent of the
// sibling features' `BSnn_RUN_PENDING` gates.
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
/// `flutter test -d flutter-tester integration_test/visual_application/`
/// skips pending ACs (their bodies, which assert un-built behaviour, never
/// run); set `--dart-define=BS18_RUN_PENDING=true` (or the `BS18_RUN_PENDING=1`
/// environment variable on a host-process run) to execute them (the
/// red-baseline / un-pend run).
///
/// Seeded with all 14 bs-18 ACs in CHROME-1 from the master plan's AC coverage
/// table; each behaviour phase then removes the row it owns as it un-pends that
/// AC. Every owner must be a member of [behaviorPhases].
///   AC-1 → CHROME-3, AC-2 → CHROME-4, AC-3 → READ-1, AC-4 → READ-2,
///   AC-5 → READ-3, AC-6 → FLOW-1, AC-7 → FLOW-2, AC-8 → ORG-1, AC-9 → ORG-2,
///   AC-10 → CFG-1, AC-11 → GUARD-2, AC-12 → GUARD-1, AC-13 → GUARD-3,
///   AC-14 → GUARD-2.
const Map<String, String> pendingACs = {
  // All 14 bs-18 ACs are now delivered — the map is intentionally empty.
  // AC-13 (the restyle preserves accessibility) was un-pended by GUARD-3, the
  // last behaviour phase, so the gate is fully open and every AC runs by
  // default. The scaffold guard in `smoke_test.dart` asserts it is exactly {}.
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests (seeded by ITEST-1) to reject a typo'd
/// or stale owner in [pendingACs]. These are the bs-18 behaviour phases from the
/// master plan that un-pend an AC (there is no enabler phase in this feature).
const Set<String> behaviorPhases = {
  'CHROME-3',
  'CHROME-4',
  'READ-1',
  'READ-2',
  'READ-3',
  'FLOW-1',
  'FLOW-2',
  'ORG-1',
  'ORG-2',
  'CFG-1',
  'GUARD-1',
  'GUARD-2',
  'GUARD-3',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/…` runs the tests in the app process *on the
/// device/simulator* (or `flutter-tester`), which does not inherit the host
/// shell's environment — so a `BS18_RUN_PENDING=1` env var set on the host
/// never reaches [runPending] there. A compile-time
/// `--dart-define=BS18_RUN_PENDING=true` does. (The [Platform.environment] path
/// below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS18_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device / flutter-tester: pass `--dart-define=BS18_RUN_PENDING=true`.
/// Host-process runs may also set the `BS18_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS18_RUN_PENDING'] == '1';

/// The reason to skip [acId] in this run, or null if it should execute.
///
/// An un-pended AC (absent from [pendingACs]) always runs; a pending AC runs
/// only in run-pending mode. Because the result drives `testWidgets`' native
/// `skip`, a not-yet-built AC's body never executes in the default run — it is
/// *skipped*, never *failed*. [forceRunPending] overrides the ambient
/// [runPending] mode so the gate's own tests can assert both modes
/// deterministically without touching the environment.
String? pendingSkipReason(String acId, {bool? forceRunPending}) {
  final owner = pendingACs[acId];
  if (owner == null) return null;
  if (forceRunPending ?? runPending) return null;
  return 'pending $owner — --dart-define=BS18_RUN_PENDING=true to run';
}

/// Registers an AC acceptance test wired to the pending gate.
///
/// Used by ITEST-2/3/4 for every AC; skipping follows [pendingSkipReason].
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
