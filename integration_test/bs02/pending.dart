// BS02 Sample-capture acceptance-suite pending gate (scaffolded in CAPTURE-1).
//
// This is the bs-02 mirror of bs-01's BS01 pending mechanism (see
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// CAPTURE-1 (scaffold) provides the mechanism only. ITEST-1 builds the bs-02
// harness (Given/When/Then vocabulary + fixtures) on top of it and seeds
// [pendingACs] with the 11 ACs; ITEST-2/3 register the per-AC tests via
// [acTestWidgets]; the behaviour phases (SOURCE-2/3, CAPTURE-3..6, SCREEN-2/3)
// un-pend their AC by deleting its row here.
//
// Keyed to `BS02_RUN_PENDING` so a bs-02 run-pending pass is independent of
// bs-01's `BS01_RUN_PENDING`.
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
/// `BS02_RUN_PENDING=1` (or `--dart-define=BS02_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Seeded with all 11 bs-02 ACs by ITEST-1; each behaviour phase removes the row
/// it owns as it un-pends that AC. The owner is the phase whose acceptance gate
/// un-pends the AC (AC-3 is un-pended by SCREEN-2 over SOURCE-2's radius
/// sampling), matching ITEST's red-baseline *Owning phase* column.
///
/// AC-1 (centre-point eyedropper) was un-pended at ITEST-2: its test is **green
/// at baseline** — the SCREEN-1 shell already renders a centre-point reticle
/// over the feed, so the AC holds before SCREEN-2's behaviour lands. SCREEN-2
/// still builds the real eyedropper/reticle and keeps the (always-running) test
/// green; see ITEST's red-baseline table.
const Map<String, String> pendingACs = {
  // AC-2 (5 px area-average sampling) un-pended by SOURCE-2 — now always runs.
  'AC-3': 'SCREEN-2', // radius selector + reticle (over SOURCE-2 sampling)
  // AC-4, AC-5 (lock lifecycle + stability settling) un-pended by CAPTURE-3 — now always run.
  'AC-6': 'CAPTURE-4', // low-light → approximate, not refused
  'AC-7': 'CAPTURE-4', // dismiss low-light warning
  'AC-8': 'CAPTURE-5', // reference-card calibration upgrades the tier
  // AC-9 (sample a point from a gallery photo) un-pended by SOURCE-3 — now always runs.
  'AC-10': 'SCREEN-3', // value-only grayscale preview
  'AC-11': 'CAPTURE-6', // multi-frame commit + haptic + open Readout
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-02 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'SOURCE-2',
  'SOURCE-3',
  'CAPTURE-3',
  'CAPTURE-4',
  'CAPTURE-5',
  'CAPTURE-6',
  'SCREEN-2',
  'SCREEN-3',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS02_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS02_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS02_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS02_RUN_PENDING=true`. Host-process runs may
/// also set the `BS02_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS02_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS02_RUN_PENDING=true to run';
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
