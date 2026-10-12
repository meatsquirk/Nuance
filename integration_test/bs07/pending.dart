// BS07 CVD-self-assessment acceptance-suite pending gate (scaffolded in ENGINE-1).
//
// This is the bs-07 mirror of bs-06's `integration_test/bs06/pending.dart`
// (itself a lineage from bs-01..bs-05): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// Like bs-06, the bs-07 plan seeds all 14 ACs here in the scaffold (ENGINE-1) —
// each mapped to the behaviour phase that un-pends it. ITEST-1 builds the bs-07
// harness (Given/When/Then vocabulary + fixtures + smoke test) on top of this;
// ITEST-2/3 register the per-AC tests via [acTestWidgets] in
// `integration_test/self_assessment_test.dart`; the behaviour phases (FLOW-2/3/
// 4/6/7/8, ENGINE-3/4/5/6/7, PROFILE-2) un-pend their AC by deleting its row
// here. The enabler FLOW-5 owns no AC and is intentionally absent.
//
// Keyed to `BS07_RUN_PENDING` so a bs-07 run-pending pass is independent of the
// earlier features' `BS0{1..6}_RUN_PENDING` defines.
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
/// `flutter test integration_test/self_assessment_test.dart` skips pending ACs
/// (their bodies, which assert un-built behaviour, never run); set
/// `--dart-define=BS07_RUN_PENDING=true` (on-device) or `BS07_RUN_PENDING=1`
/// (host process) to execute them (the red-baseline / un-pend run).
///
/// Seeded with all 14 bs-07 ACs in ENGINE-1 (scaffold); each behaviour phase
/// then removes the row it owns as it un-pends that AC. Every owner must be a
/// member of [behaviorPhases]. Mapping is taken verbatim from the master plan's
/// AC-coverage table.
const Map<String, String> pendingACs = {
  'AC-1': 'FLOW-8', // result caveat: approximate estimate + clinical test
  // AC-2 (Tier 0 lighting gate) un-pended by FLOW-3.
  'AC-3': 'ENGINE-3', // Tier 1 intake answer → starting prior
  'AC-4': 'ENGINE-4', // intake prior-diagnosis seeds the prior
  'AC-5': 'ENGINE-5', // Tier 2 screening presence + R-G/B-Y direction
  'AC-6': 'FLOW-4', // arrangement: place a cap in the next position
  'AC-7': 'FLOW-4', // arrangement: start over clears the arrangement
  'AC-8': 'FLOW-4', // arrangement: skip continues without a result
  'AC-9': 'ENGINE-6', // Tier 4 threshold severity on the confusion line
  'AC-10': 'FLOW-6', // result: adjust estimated type by hand
  'AC-11': 'ENGINE-7', // severity value → plain-language band
  'AC-12': 'FLOW-7', // severity slider doubles as self-calibration
  'AC-13': 'PROFILE-2', // save profile configures the pipeline
  'AC-14': 'FLOW-2', // progress: current step of the total
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-07 behaviour phases from the master plan that
/// un-pend an AC (the FLOW-5 enabler is excluded — it owns no AC).
const Set<String> behaviorPhases = {
  'FLOW-2',
  'FLOW-3',
  'FLOW-4',
  'FLOW-6',
  'FLOW-7',
  'FLOW-8',
  'ENGINE-3',
  'ENGINE-4',
  'ENGINE-5',
  'ENGINE-6',
  'ENGINE-7',
  'PROFILE-2',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS07_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS07_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS07_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS07_RUN_PENDING=true`. Host-process runs may
/// also set the `BS07_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS07_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS07_RUN_PENDING=true to run';
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
