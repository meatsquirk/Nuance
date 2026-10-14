// BS10 Daltonization acceptance-suite pending gate (scaffolded in DALT-1).
//
// This is the bs-10 mirror of bs-09's `integration_test/bs09/pending.dart`
// (itself a mirror of bs-06's `integration_test/bs06/pending.dart`, bs-04's
// `integration_test/bs04/pending.dart`, bs-03's `integration_test/bs03/pending.dart`,
// bs-02's `integration_test/bs02/pending.dart` and bs-01's pending mechanism in
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// Like bs-06/bs-09 (and unlike bs-02/bs-04, whose scaffolds left [pendingACs]
// empty for ITEST-1 to seed), the bs-10 plan seeds all 10 ACs here in DALT-1
// (scaffold) — each mapped to the behaviour phase that un-pends it. ITEST-1
// builds the bs-10 harness (Given/When/Then vocabulary + fixtures, re-exporting
// bs-08's `display_harness.dart` / bs-02's `capture_harness.dart`) on top of
// this; ITEST-2/3 register the per-AC tests via [acTestWidgets] in
// `integration_test/daltonization_test.dart`; the behaviour phases (DALT-3..11,
// CONTROL-2) un-pend their AC by deleting its row here.
//
// Keyed to `BS10_RUN_PENDING` so a bs-10 run-pending pass is independent of
// bs-01's `BS01_RUN_PENDING`, bs-02's `BS02_RUN_PENDING`, bs-03's
// `BS03_RUN_PENDING`, bs-04's `BS04_RUN_PENDING`, bs-05's `BS05_RUN_PENDING`,
// bs-06's `BS06_RUN_PENDING`, bs-07's `BS07_RUN_PENDING`, bs-08's
// `BS08_RUN_PENDING` and bs-09's `BS09_RUN_PENDING`.
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
/// `flutter test integration_test/daltonization_test.dart` skips pending ACs
/// (their bodies, which assert un-built behaviour, never run); set
/// `BS10_RUN_PENDING=1` (or `--dart-define=BS10_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Seeded with all 10 bs-10 ACs in DALT-1 (scaffold); each behaviour phase then
/// removes the row it owns as it un-pends that AC. Every owner must be a member
/// of [behaviorPhases]. The owner is the phase whose acceptance gate un-pends
/// the AC, matching the master plan's AC-coverage table:
///   AC-1 → DALT-3 (keystone: real remap + chokepoint applies it per type)
///   AC-5 → DALT-4 (remap uses the stored type + severity)
///   AC-7 → DALT-5 (distinct from simulation)
///   AC-2 → DALT-6 (off = original)
///   AC-8 → DALT-7 (stored values unchanged)
///   AC-9 → DALT-8 (every screen)
///   AC-3 → DALT-9 (label + value kept)
///   AC-4 → DALT-10 (provenance badge readable)
///   AC-6 → DALT-11 (profile change recomputes)
///   AC-10 → CONTROL-2 (no saved profile → self-assessment needed)
const Map<String, String> pendingACs = {
  // AC-1 un-pended by DALT-3 — the real error-redistribution remap over
  // projectDichromat (scaled by severity; the chokepoint renders a type-specific
  // remap when daltonization is on) now ships, so AC-1's row is removed here.
  // AC-2 un-pended by DALT-6 — the chokepoint's off path is explicit (no remap
  // when daltonization is false → `simulateColor`, which is the stored original
  // when no simulation is set), so colours off are shown with their original
  // values; AC-2's row is removed here.
  // AC-3 un-pended by DALT-9 (a remapped colour-coded element still renders its
  // label text + numeric value; only the swatch colour changes).
  'AC-3': 'DALT-9',
  // AC-4 un-pended by DALT-10 (a provenance badge stays readable from its label
  // + icon, not colour, under the remap).
  'AC-4': 'DALT-10',
  // AC-5 un-pended by DALT-4 — the one chokepoint (`displayedSwatchColor`, fed
  // `AppScope.cvdProfile`) already drives the remap from the stored profile's
  // type AND severity, not a default (verified at the unit level and by
  // `TestAC05_UsesStoredProfile` with its stronger-severity control), so AC-5's
  // row is removed here.
  // AC-6 un-pended by DALT-11 (the render listens to CvdProfileStore so a saved
  // profile change re-renders with the recomputed remap).
  'AC-6': 'DALT-11',
  // AC-7 un-pended by DALT-5 — the error-redistribution remap (DALT-3 keystone)
  // is distinct from the simulation projection by construction: it rotates the
  // lost a*/b* chroma 90° and adds it back (aiding distinction) rather than
  // collapsing it (perception). DALT-5 verifies this at the chokepoint grain and
  // removes AC-7's row here.
  // AC-8 un-pended by DALT-7 (the remap is applied only at render, never
  // written back; the stored Sample/ColorCoordinates are unchanged).
  'AC-8': 'DALT-7',
  // AC-9 un-pended by DALT-8 (the remap is injected at the one shared
  // ColorChip/DisplayScope chokepoint so capture, readout and palette all get
  // it).
  'AC-9': 'DALT-8',
  // AC-10 un-pended by CONTROL-2 (with no saved profile the control reports a
  // self-assessment is needed before colours can be remapped; no remap applied).
  'AC-10': 'CONTROL-2',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-10 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'DALT-3',
  'DALT-4',
  'DALT-5',
  'DALT-6',
  'DALT-7',
  'DALT-8',
  'DALT-9',
  'DALT-10',
  'DALT-11',
  'CONTROL-2',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS10_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS10_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS10_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS10_RUN_PENDING=true`. Host-process runs may
/// also set the `BS10_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS10_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS10_RUN_PENDING=true to run';
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
