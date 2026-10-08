// BS03 Relative-comparison acceptance-suite pending gate (scaffolded in COMPARE-1).
//
// This is the bs-03 mirror of bs-02's `integration_test/bs02/pending.dart`
// (itself a mirror of bs-01's BS01 pending mechanism in
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// COMPARE-1 (scaffold) provides the mechanism only — [pendingACs] is empty.
// ITEST-1 builds the bs-03 harness (Given/When/Then vocabulary + fixtures) on
// top of it and seeds [pendingACs] with the 12 ACs; ITEST-2/3 register the
// per-AC tests via [acTestWidgets] in `integration_test/comparison_test.dart`;
// the behaviour phases (COMPARE-3/5/6, DIFF-2/3, CVD-2/3) un-pend their AC by
// deleting its row here.
//
// Keyed to `BS03_RUN_PENDING` so a bs-03 run-pending pass is independent of
// bs-01's `BS01_RUN_PENDING` and bs-02's `BS02_RUN_PENDING`.
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
/// `BS03_RUN_PENDING=1` (or `--dart-define=BS03_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Empty at scaffold (COMPARE-1 provides the mechanism only). ITEST-1 seeds all
/// 12 bs-03 ACs; each behaviour phase then removes the row it owns as it
/// un-pends that AC. Every owner must be a member of [behaviorPhases].
const Map<String, String> pendingACs = {
  // AC-1, AC-2, AC-12 un-pended by COMPARE-3 (selection + slot render + invite).
  'AC-3': 'COMPARE-5', // swap A/B + re-express
  // AC-4 un-pended by DIFF-2 (overall ΔE00 + plain verdict).
  'AC-5': 'DIFF-3', // lightness/saturation/hue decomposition
  'AC-6': 'DIFF-3', // unchanged dimension → "Same hue"
  // AC-7, AC-8 un-pended by CVD-2 (confusion detector + warning region).
  'AC-9': 'CVD-3', // speak comparison incl. warning
  // AC-10, AC-11 un-pended by COMPARE-6 (open readout for A / B).
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own tests (ITEST-1) to reject a typo'd or stale owner
/// in [pendingACs]. These are the bs-03 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'COMPARE-3',
  'COMPARE-5',
  'COMPARE-6',
  'DIFF-2',
  'DIFF-3',
  'CVD-2',
  'CVD-3',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS03_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS03_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS03_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS03_RUN_PENDING=true`. Host-process runs may
/// also set the `BS03_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS03_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS03_RUN_PENDING=true to run';
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
