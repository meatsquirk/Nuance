// BS04 Mixing-recipes acceptance-suite pending gate (scaffolded in RECIPE-1).
//
// This is the bs-04 mirror of bs-03's `integration_test/bs03/pending.dart`
// (itself a mirror of bs-02's `integration_test/bs02/pending.dart` and bs-01's
// BS01 pending mechanism in `integration_test/harness.dart`): the plumbing that
// lets stage 3 land one *pending* integration test per AC while the suite stays
// green, then un-pend each AC as its behaviour phase lands.
//
// RECIPE-1 (scaffold) provides the mechanism only — [pendingACs] is empty.
// ITEST-1 builds the bs-04 harness (Given/When/Then vocabulary + fixtures) on
// top of it and seeds [pendingACs] with the 12 ACs; ITEST-2/3 register the
// per-AC tests via [acTestWidgets] in `integration_test/recipes_test.dart`; the
// behaviour phases (RECIPE-3, RECIPE-4, ENGINE-2..6) un-pend their AC by
// deleting its row here.
//
// Keyed to `BS04_RUN_PENDING` so a bs-04 run-pending pass is independent of
// bs-01's `BS01_RUN_PENDING`, bs-02's `BS02_RUN_PENDING` and bs-03's
// `BS03_RUN_PENDING`.
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
/// deleting the row. The default `flutter test integration_test/` skips pending
/// ACs (their bodies, which assert un-built behaviour, never run); set
/// `BS04_RUN_PENDING=1` (or `--dart-define=BS04_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Empty at scaffold (RECIPE-1 provides the mechanism only). ITEST-1 seeds all
/// 12 bs-04 ACs; each behaviour phase then removes the row it owns as it
/// un-pends that AC. Every owner must be a member of [behaviorPhases].
const Map<String, String> pendingACs = {
  // AC-1, AC-2 un-pended by RECIPE-3 (target selection: saved sample + manual).
  'AC-1': 'RECIPE-3',
  'AC-2': 'RECIPE-3',
  // AC-3, AC-4 un-pended by ENGINE-2 (palette-constrained solver + top recipes).
  // AC-5, AC-6 un-pended by ENGINE-3 (per-recipe ΔE00 + verdict; prefer fewer).
  'AC-5': 'ENGINE-3',
  'AC-6': 'ENGINE-3',
  // AC-7, AC-8 un-pended by ENGINE-4 (trace "a touch of"; muddying flag).
  'AC-7': 'ENGINE-4',
  'AC-8': 'ENGINE-4',
  // AC-9 un-pended by ENGINE-5 (out-of-gamut + nearest-not-a-match).
  'AC-9': 'ENGINE-5',
  // AC-10 un-pended by ENGINE-6 (wet/dry toggle + dry prediction).
  'AC-10': 'ENGINE-6',
  // AC-11, AC-12 un-pended by RECIPE-4 (speak target; speak recipe).
  'AC-11': 'RECIPE-4',
  'AC-12': 'RECIPE-4',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own tests (ITEST-1) to reject a typo'd or stale owner
/// in [pendingACs]. These are the bs-04 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'RECIPE-3',
  'RECIPE-4',
  'ENGINE-2',
  'ENGINE-3',
  'ENGINE-4',
  'ENGINE-5',
  'ENGINE-6',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS04_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS04_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS04_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS04_RUN_PENDING=true`. Host-process runs may
/// also set the `BS04_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS04_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS04_RUN_PENDING=true to run';
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
