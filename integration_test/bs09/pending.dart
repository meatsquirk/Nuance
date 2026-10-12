// BS09 Advanced-capture acceptance-suite pending gate (scaffolded in CAPTURE-1).
//
// This is the bs-09 mirror of bs-06's `integration_test/bs06/pending.dart`
// (itself a mirror of bs-04's `integration_test/bs04/pending.dart`, bs-03's
// `integration_test/bs03/pending.dart`, bs-02's `integration_test/bs02/pending.dart`
// and bs-01's pending mechanism in `integration_test/harness.dart`): the
// plumbing that lets stage 3 land one *pending* integration test per AC while
// the suite stays green, then un-pend each AC as its behaviour phase lands.
//
// Like bs-06 (and unlike bs-02/bs-04, whose scaffolds left [pendingACs] empty
// for ITEST-1 to seed), the bs-09 plan seeds all 10 ACs here in CAPTURE-1
// (scaffold) — each mapped to the behaviour phase that un-pends it. ITEST-1
// builds the bs-09 harness (Given/When/Then vocabulary + fixtures, re-exporting
// bs-02's `capture_harness.dart`) on top of this; ITEST-2/3 register the per-AC
// tests via [acTestWidgets] in `integration_test/advanced_capture_test.dart`;
// the behaviour phases (CAPTURE-3/4/5, SCREEN-2/3, SOURCE-2/3/4) un-pend their
// AC by deleting its row here.
//
// Keyed to `BS09_RUN_PENDING` so a bs-09 run-pending pass is independent of
// bs-01's `BS01_RUN_PENDING`, bs-02's `BS02_RUN_PENDING`, bs-03's
// `BS03_RUN_PENDING`, bs-04's `BS04_RUN_PENDING`, bs-05's `BS05_RUN_PENDING`
// and bs-06's `BS06_RUN_PENDING`.
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
/// `flutter test integration_test/advanced_capture_test.dart` skips pending ACs
/// (their bodies, which assert un-built behaviour, never run); set
/// `BS09_RUN_PENDING=1` (or `--dart-define=BS09_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Seeded with all 10 bs-09 ACs in CAPTURE-1 (scaffold); each behaviour phase
/// then removes the row it owns as it un-pends that AC. Every owner must be a
/// member of [behaviorPhases]. The owner is the phase whose acceptance gate
/// un-pends the AC, matching the master plan's AC-coverage table:
///   AC-1 → SCREEN-2 (torch control + colour-temperature warning banner)
///   AC-6/AC-8 → SOURCE-2 (colour-space selection + narrower fallback + tag)
///   AC-9/AC-10 → SOURCE-4 (normalized+tagged contract + platform-agnostic)
const Map<String, String> pendingACs = {
  'AC-1': 'SCREEN-2',
  'AC-2': 'CAPTURE-3',
  'AC-3': 'CAPTURE-4',
  'AC-4': 'SCREEN-3',
  'AC-5': 'CAPTURE-5',
  'AC-6': 'SOURCE-2',
  'AC-7': 'SOURCE-3',
  'AC-8': 'SOURCE-2',
  'AC-9': 'SOURCE-4',
  'AC-10': 'SOURCE-4',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-09 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'CAPTURE-3',
  'CAPTURE-4',
  'CAPTURE-5',
  'SCREEN-2',
  'SCREEN-3',
  'SOURCE-2',
  'SOURCE-3',
  'SOURCE-4',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS09_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS09_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS09_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS09_RUN_PENDING=true`. Host-process runs may
/// also set the `BS09_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS09_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS09_RUN_PENDING=true to run';
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
