// BS12 Core non-functional-requirements acceptance-suite pending gate
// (scaffolded in GUARD-1).
//
// This is the bs-12 mirror of bs-09's `integration_test/bs09/pending.dart`
// (itself a mirror of bs-06/bs-04/bs-03/bs-02 and bs-01's pending mechanism in
// `integration_test/harness.dart`): the plumbing that lets stage 3 land one
// *pending* integration test per AC while the suite stays green, then un-pend
// each AC as its behaviour phase lands.
//
// Like bs-09 (and unlike bs-02/bs-04, whose scaffolds left [pendingACs] empty
// for ITEST-1 to seed), the bs-12 plan seeds all 16 *automatable* ACs here in
// GUARD-1 (scaffold) — each mapped to the behaviour phase that un-pends it.
// ITEST-1 builds the bs-12 harness (Given/When/Then vocabulary + real-flow /
// control / swap fixtures) on top of this; ITEST-2/3 register the per-AC tests
// via [acTestWidgets] in `integration_test/bs12/nfr_test.dart`; the behaviour
// phases (GUARD-3..GUARD-6, QUALITY-2..QUALITY-5) un-pend their AC by deleting
// its row here.
//
// **AC-5 (the live-preview frame rate) never enters this gate**: it is
// pure-manual (D-3), verified on device at SIGNOFF-1 under G-3, so it has no
// automatable acceptance test. The 16 rows below are exactly the automatable
// ACs (AC-1..AC-4, AC-6..AC-17).
//
// Keyed to `BS12_RUN_PENDING` so a bs-12 run-pending pass is independent of the
// per-feature run-pending flags bs-01..bs-09 use (`BS0n_RUN_PENDING`).
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
/// `flutter test integration_test/bs12/nfr_test.dart` skips pending ACs (their
/// bodies, which assert un-built behaviour, never run); set `BS12_RUN_PENDING=1`
/// (or `--dart-define=BS12_RUN_PENDING=true` on-device) to execute them (the
/// red-baseline / un-pend run).
///
/// Seeded with all 16 automatable bs-12 ACs in GUARD-1 (scaffold); each
/// behaviour phase then removes the row it owns as it un-pends that AC. Every
/// owner must be a member of [behaviorPhases]. The owner is the phase whose
/// acceptance gate un-pends the AC, matching the master plan's AC-coverage
/// table. AC-5 (live-preview frame rate) is absent — pure-manual (D-3).
const Map<String, String> pendingACs = {
  // Offline (Rule: every core function works offline)
  // AC-1, AC-2 un-pended by GUARD-3: the network-block sink now records every
  // attempt, so each core flow sweeps offline (zero attempts) and the counter
  // control discriminates (a deliberate touch is recorded + refused).
  // Performance (AC-5 live-preview frame rate is manual — not here)
  'AC-3': 'QUALITY-5', // reading settles within budget + visible indicator
  'AC-4': 'QUALITY-5', // recipe search returns top 3–5 within budget
  // Privacy & security
  'AC-6': 'GUARD-4', // photos and samples never leave the device
  'AC-7': 'GUARD-4', // no account, no telemetry in v1
  'AC-8': 'GUARD-4', // any future sync is opt-in and explicit
  // Reliability
  'AC-9': 'QUALITY-2', // poor conditions downgrade stated accuracy, not silent
  // Accuracy (ΔE00 targets)
  'AC-10': 'QUALITY-4', // card + controlled lighting: ΔE00 ≤ 3
  'AC-11': 'QUALITY-4', // cardless daylight: ΔE00 ≤ 8, labelled approximate
  'AC-12': 'QUALITY-4', // recipe prediction vs swatch: ΔE00 ≤ 5 in-gamut
  'AC-13': 'QUALITY-3', // out-of-gamut target identified, no false recipe
  // Maintainability (swappable behind interfaces)
  'AC-14': 'GUARD-5', // mixing engine swappable without touching callers
  'AC-15': 'GUARD-5', // CVD model swappable without touching callers
  'AC-16': 'GUARD-6', // colour-science from one tested library
  // Portability
  'AC-17': 'GUARD-6', // only native capture differs per platform
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-12 behaviour phases from the master plan.
const Set<String> behaviorPhases = {
  'GUARD-3',
  'GUARD-4',
  'GUARD-5',
  'GUARD-6',
  'QUALITY-2',
  'QUALITY-3',
  'QUALITY-4',
  'QUALITY-5',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS12_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS12_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS12_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS12_RUN_PENDING=true`. Host-process runs may
/// also set the `BS12_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS12_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS12_RUN_PENDING=true to run';
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
