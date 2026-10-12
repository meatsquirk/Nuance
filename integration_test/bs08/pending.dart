// BS08 Display-simulation-and-spoken-output acceptance-suite pending gate
// (scaffolded in DISPLAY-1).
//
// This is the bs-08 mirror of bs-06's `integration_test/bs06/pending.dart`
// (itself a mirror of bs-04's/bs-03's/bs-02's pending gates and bs-01's pending
// mechanism in `integration_test/harness.dart`): the plumbing that lets stage 3
// land one *pending* integration test per AC while the suite stays green, then
// un-pend each AC as its behaviour phase lands.
//
// Like bs-06 (and unlike bs-04, whose scaffold left [pendingACs] empty for
// ITEST-1 to seed), the bs-08 plan seeds all 10 ACs here in DISPLAY-1
// (scaffold) — each mapped to the behaviour phase that un-pends it. ITEST-1
// builds the bs-08 harness (Given/When/Then vocabulary + fixtures + the
// independent reference projection) on top of this; ITEST-2/3 register the
// per-AC tests via [acTestWidgets] in `integration_test/display_test.dart`; the
// behaviour phases (DISPLAY-3..8, SETTINGS-2, SPEECH-2/3/4) un-pend their AC by
// deleting its row here.
//
// Keyed to `BS08_RUN_PENDING` so a bs-08 run-pending pass is independent of the
// earlier features' `BS0n_RUN_PENDING` flags.
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
/// deleting the row. The default `flutter test integration_test/display_test.dart`
/// skips pending ACs (their bodies, which assert un-built behaviour, never run);
/// set `BS08_RUN_PENDING=1` (or `--dart-define=BS08_RUN_PENDING=true` on-device)
/// to execute them (the red-baseline / un-pend run).
///
/// Seeded with all 10 bs-08 ACs in DISPLAY-1 (scaffold); each behaviour phase
/// then removes the row it owns as it un-pends that AC. Every owner must be a
/// member of [behaviorPhases]. (bs-08 has no enabler phase — every behaviour
/// phase owns exactly one AC.)
const Map<String, String> pendingACs = {
  'AC-1': 'SETTINGS-2', // open display & simulation settings from any screen
  // AC-2 un-pended by DISPLAY-3 (simulation off = trichromat, identity path).
  // AC-3 un-pended by DISPLAY-4 (simulate chosen type alongside the original).
  // AC-4 un-pended by DISPLAY-5 (severity slider sets simulation strength).
  // AC-5 un-pended by DISPLAY-6 (grayscale clears an active simulation, D-3).
  // AC-6 un-pended by DISPLAY-7 (value-only grayscale greys the whole app).
  'AC-7': 'DISPLAY-8', // reading keeps numeric value + label under simulation
  'AC-8': 'SPEECH-2', // repeat the last spoken output
  'AC-9': 'SPEECH-3', // reading + comparison one consistent phrasing
  'AC-10': 'SPEECH-4', // spoken-output panel never auto-dismisses
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-08 behaviour phases from the master plan that
/// un-pend an AC (bs-08 has no enabler phase to exclude).
const Set<String> behaviorPhases = {
  'DISPLAY-3',
  'DISPLAY-4',
  'DISPLAY-5',
  'DISPLAY-6',
  'DISPLAY-7',
  'DISPLAY-8',
  'SETTINGS-2',
  'SPEECH-2',
  'SPEECH-3',
  'SPEECH-4',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS08_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS08_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS08_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS08_RUN_PENDING=true`. Host-process runs may
/// also set the `BS08_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS08_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS08_RUN_PENDING=true to run';
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
