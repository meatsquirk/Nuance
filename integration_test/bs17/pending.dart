// BS17 Visual-design-system acceptance-suite pending gate (seeded in ITEST-1).
//
// This is the bs-17 mirror of the sibling per-feature gates (bs-06's
// `integration_test/bs06/pending.dart`, itself a mirror of bs-02..bs-05's and
// bs-01's mechanism in `integration_test/harness.dart`): the plumbing that lets
// stage 3 land one *pending* integration test per AC while the suite stays
// green, then un-pend each AC as its behaviour phase lands.
//
// ITEST-1 seeds all 15 ACs here — each mapped to the behaviour phase that
// un-pends it (the AC coverage table in the master plan). ITEST-1 builds the
// bs-17 harness (Given/When/Then vocabulary + fixtures) on top of this; ITEST-2
// registers AC-1..AC-6 and ITEST-3 AC-7..AC-15 via [acTestWidgets] in
// `integration_test/design_system_test.dart`; the behaviour phases (THEME-3/4/5,
// COMPONENTS-2/3/4/5, APPLY-1/2) un-pend their AC by deleting its row here.
//
// Keyed to `BS17_RUN_PENDING` so a bs-17 run-pending pass is independent of the
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
/// `flutter test -d flutter-tester integration_test/design_system_test.dart`
/// skips pending ACs (their bodies, which assert un-built behaviour, never
/// run); set `--dart-define=BS17_RUN_PENDING=true` (or the `BS17_RUN_PENDING=1`
/// environment variable on a host-process run) to execute them (the
/// red-baseline / un-pend run).
///
/// Seeded with all 15 bs-17 ACs in ITEST-1; each behaviour phase then removes
/// the row it owns as it un-pends that AC. Every owner must be a member of
/// [behaviorPhases]. The mapping is the master plan's AC coverage table:
/// AC-1..AC-4 → THEME-3, AC-5/AC-6 → THEME-4, AC-7/AC-8/AC-9 → THEME-5,
/// AC-10 → COMPONENTS-2, AC-11 → COMPONENTS-3, AC-12 → COMPONENTS-4,
/// AC-13 → COMPONENTS-5, AC-14 → APPLY-1, AC-15 → APPLY-2.
const Map<String, String> pendingACs = {
  // AC-1..AC-4 un-pended by THEME-3 (warm-paper ColorScheme + AA proof);
  // AC-5/AC-6 un-pended by THEME-4 (Atkinson Next/Mono typeface).
  'AC-7': 'THEME-5',
  'AC-8': 'THEME-5',
  'AC-9': 'THEME-5',
  'AC-10': 'COMPONENTS-2',
  'AC-11': 'COMPONENTS-3',
  'AC-12': 'COMPONENTS-4',
  'AC-13': 'COMPONENTS-5',
  'AC-14': 'APPLY-1',
  'AC-15': 'APPLY-2',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-17 behaviour phases from the master plan that
/// un-pend an AC (there is no enabler phase in this feature).
const Set<String> behaviorPhases = {
  'THEME-3',
  'THEME-4',
  'THEME-5',
  'COMPONENTS-2',
  'COMPONENTS-3',
  'COMPONENTS-4',
  'COMPONENTS-5',
  'APPLY-1',
  'APPLY-2',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/…` runs the tests in the app process *on the
/// device/simulator* (or `flutter-tester`), which does not inherit the host
/// shell's environment — so a `BS17_RUN_PENDING=1` env var set on the host
/// never reaches [runPending] there. A compile-time
/// `--dart-define=BS17_RUN_PENDING=true` does. (The [Platform.environment] path
/// below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS17_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device / flutter-tester: pass `--dart-define=BS17_RUN_PENDING=true`.
/// Host-process runs may also set the `BS17_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS17_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS17_RUN_PENDING=true to run';
}

/// Registers an AC acceptance test wired to the pending gate.
///
/// Used by ITEST-2/3 for every AC; skipping follows [pendingSkipReason].
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
