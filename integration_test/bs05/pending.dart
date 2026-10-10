// BS05 Mix-correction-loop acceptance-suite pending gate (scaffolded in LOOP-1).
//
// This is the bs-05 mirror of bs-04's `integration_test/bs04/pending.dart`
// (itself a mirror of bs-03's `integration_test/bs03/pending.dart`, bs-02's
// `integration_test/bs02/pending.dart` and bs-01's BS01 pending mechanism in
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// LOOP-1 (scaffold) provides the mechanism AND seeds [pendingACs] with all 10
// bs-05 ACs mapped to the behaviour phase that un-pends each (per the LOOP-1
// plan — unlike bs-04, where the scaffold left the map empty and ITEST-1
// seeded it). ITEST-1 builds the bs-05 harness (Given/When/Then vocabulary +
// fixtures) on top of this; ITEST-2/3 register the per-AC tests via
// [acTestWidgets] in `integration_test/correction_test.dart`; the behaviour
// phases un-pend their AC by deleting its row here.
//
// Keyed to `BS05_RUN_PENDING` so a bs-05 run-pending pass is independent of
// bs-01's `BS01_RUN_PENDING`, bs-02's `BS02_RUN_PENDING`, bs-03's
// `BS03_RUN_PENDING` and bs-04's `BS04_RUN_PENDING`.
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
/// `BS05_RUN_PENDING=1` (or `--dart-define=BS05_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Seeded with all 10 bs-05 ACs at scaffold (LOOP-1). Each behaviour phase then
/// removes the row it owns as it un-pends that AC. Every owner must be a member
/// of [behaviorPhases].
const Map<String, String> pendingACs = {
  'AC-1': 'LOOP-3', // check photographs the swatch + compares to the target
  'AC-2': 'CORRECT-2', // ΔE00 + plain verdict
  'AC-3': 'CORRECT-2', // value-leading decomposition
  'AC-4': 'CORRECT-3', // concrete correction: paint + amount
  'AC-5': 'CORRECT-3', // small correction → "a touch of"
  'AC-6': 'CORRECT-4', // within tolerance → "very close", no correction
  'AC-7': 'LOOP-4', // speak the correction (E27)
  'AC-8': 'LOOP-5', // re-photograph re-checks (E28)
  'AC-9': 'LOOP-6', // save confirmed → promote provenance (E29)
  'AC-10': 'LOOP-6', // a confirmed value shows its provenance in later readouts
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own tests (ITEST-1) to reject a typo'd or stale owner
/// in [pendingACs]. These are the bs-05 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'LOOP-3',
  'LOOP-4',
  'LOOP-5',
  'LOOP-6',
  'CORRECT-2',
  'CORRECT-3',
  'CORRECT-4',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS05_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS05_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS05_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS05_RUN_PENDING=true`. Host-process runs may
/// also set the `BS05_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS05_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS05_RUN_PENDING=true to run';
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
