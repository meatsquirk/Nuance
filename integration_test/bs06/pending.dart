// BS06 Palette-and-projects acceptance-suite pending gate (scaffolded in DATA-1).
//
// This is the bs-06 mirror of bs-04's `integration_test/bs04/pending.dart`
// (itself a mirror of bs-03's `integration_test/bs03/pending.dart`, bs-02's
// `integration_test/bs02/pending.dart` and bs-01's pending mechanism in
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// Unlike bs-04 (whose scaffold left [pendingACs] empty for ITEST-1 to seed),
// the bs-06 plan seeds all 11 ACs here in DATA-1 (scaffold) — each mapped to
// the behaviour phase that un-pends it. ITEST-1 builds the bs-06 harness
// (Given/When/Then vocabulary + fixtures) on top of this; ITEST-2/3 register
// the per-AC tests via [acTestWidgets] in `integration_test/palette_test.dart`;
// the behaviour phases (PALETTE-2/3/4, PROJECT-3/4/5/6, SCREEN-2/3) un-pend
// their AC by deleting its row here.
//
// Keyed to `BS06_RUN_PENDING` so a bs-06 run-pending pass is independent of
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
/// deleting the row. The default `flutter test integration_test/palette_test.dart`
/// skips pending ACs (their bodies, which assert un-built behaviour, never run);
/// set `BS06_RUN_PENDING=1` (or `--dart-define=BS06_RUN_PENDING=true` on-device)
/// to execute them (the red-baseline / un-pend run).
///
/// Seeded with all 11 bs-06 ACs in DATA-1 (scaffold); each behaviour phase then
/// removes the row it owns as it un-pends that AC. Every owner must be a member
/// of [behaviorPhases]. (The enabler PROJECT-2 owns no AC and is intentionally
/// absent — it makes the Givens of the PROJECT ACs real, but un-pends nothing.)
const Map<String, String> pendingACs = {
  'AC-1': 'SCREEN-2', // switch My paints / Projects views
  'AC-2': 'PALETTE-3', // paint identity + provenance badge
  'AC-3': 'PALETTE-3', // provenance legend (four tiers)
  'AC-4': 'PALETTE-2', // add paint from the reviewed dataset
  'AC-5': 'PALETTE-4', // selected palette drives recipes
  'AC-6': 'PROJECT-3', // projects list size/counts/last-edit
  'AC-7': 'PROJECT-4', // open project note + photo
  'AC-8': 'PROJECT-4', // note retained on reopen
  'AC-9': 'PROJECT-5', // confusion pair flagged within a project
  'AC-10': 'PROJECT-6', // export PDF studio sheet
  'AC-11': 'SCREEN-3', // vision-profile card estimate + opens self-assessment
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-06 behaviour phases from the master plan that
/// un-pend an AC (the PROJECT-2 enabler is excluded — it owns no AC).
const Set<String> behaviorPhases = {
  'PALETTE-2',
  'PALETTE-3',
  'PALETTE-4',
  'PROJECT-3',
  'PROJECT-4',
  'PROJECT-5',
  'PROJECT-6',
  'SCREEN-2',
  'SCREEN-3',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS06_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS06_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS06_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS06_RUN_PENDING=true`. Host-process runs may
/// also set the `BS06_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS06_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS06_RUN_PENDING=true to run';
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
