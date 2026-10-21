// BS19 Live-camera-capture acceptance-suite pending runner (scaffold: CAM-1).
//
// This is the bs-19 mirror of the sibling per-feature gates (bs-18's
// `integration_test/visual_application/pending.dart`, bs-17's
// `integration_test/bs17/pending.dart`, bs-13's
// `integration_test/bs13/pending.dart`, themselves mirrors of bs-02..bs-06's
// and bs-01's mechanism in `integration_test/harness.dart`): the plumbing that
// lets stage 3 land one *pending* integration test per AC while the suite stays
// green, then un-pend each AC as its behaviour phase lands.
//
// CAM-1 (scaffold) establishes this runner convention and seeds the AC→owner
// map from the master plan's AC coverage table. ITEST-1 builds the bs-19 harness
// (`ScriptedCameraSource` + fixtures + Given/When/Then vocabulary) on top of it;
// ITEST-2/3 register the 10 ACs via [acTestWidgets] in
// `integration_test/live_camera/*_test.dart`; ITEST-4 is the test review (G-2).
// The behaviour phases un-pend their AC by deleting its row in [pendingACs].
//
// Keyed to `BS19_RUN_PENDING` so a bs-19 run-pending pass is independent of the
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
/// `flutter test -d flutter-tester integration_test/live_camera/`
/// skips pending ACs (their bodies, which assert un-built behaviour, never
/// run); set `--dart-define=BS19_RUN_PENDING=true` (or the `BS19_RUN_PENDING=1`
/// environment variable on a host-process run) to execute them (the
/// red-baseline / un-pend run).
///
/// Seeded with all 10 bs-19 ACs in CAM-1 from the master plan's AC coverage
/// table; each behaviour phase then removes the row it owns as it un-pends that
/// AC. Every owner must be a member of [behaviorPhases].
const Map<String, String> pendingACs = {
  // AC-1 (The live view shows the camera feed) un-pended by VIEW-2.
  // AC-2 (Camera frames convert to the correct colour) un-pended by CAM-3.
  // AC-3 (The reading follows the live camera frame) un-pended by CAM-4.
  // AC-4 (Value-only mode shows the live feed in grayscale) un-pended by VIEW-3.
  // AC-5 (Locking AE·AWB·AF settles the live camera) un-pended by CAM-5.
  // AC-6 (The torch toggles the device light) un-pended by CAM-6.
  'AC-7': 'PERM-2', // Permission requested; denial falls back gracefully
  'AC-8': 'PERM-3', // A device with no camera falls back gracefully
  'AC-9': 'CAM-7', //  Camera released and re-acquired across lifecycle
  'AC-10': 'PERM-4', // The app declares camera use on both platforms
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests (seeded by ITEST-1) to reject a typo'd
/// or stale owner in [pendingACs]. These are the bs-19 behaviour phases from the
/// master plan that un-pend an AC (CAM-3 is enabler-ish but still un-pends
/// AC-2, so it belongs here).
const Set<String> behaviorPhases = {
  'CAM-3',
  'CAM-4',
  'CAM-5',
  'CAM-6',
  'CAM-7',
  'VIEW-2',
  'VIEW-3',
  'PERM-2',
  'PERM-3',
  'PERM-4',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/…` runs the tests in the app process *on the
/// device/simulator* (or `flutter-tester`), which does not inherit the host
/// shell's environment — so a `BS19_RUN_PENDING=1` env var set on the host
/// never reaches [runPending] there. A compile-time
/// `--dart-define=BS19_RUN_PENDING=true` does. (The [Platform.environment] path
/// below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS19_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device / flutter-tester: pass `--dart-define=BS19_RUN_PENDING=true`.
/// Host-process runs may also set the `BS19_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS19_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS19_RUN_PENDING=true to run';
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
