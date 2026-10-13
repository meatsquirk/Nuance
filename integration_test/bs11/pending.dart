// BS11 Accessibility-conformance acceptance-suite pending gate (scaffolded in
// CONF-1).
//
// This is the bs-11 mirror of bs-09's `integration_test/bs09/pending.dart`
// (itself a mirror of bs-08's/bs-06's/bs-04's/bs-03's/bs-02's pending gates and
// bs-01's pending mechanism in `integration_test/harness.dart`): the plumbing
// that lets stage 3 land one *pending* integration test per AC while the suite
// stays green, then un-pend each AC as its behaviour phase lands.
//
// Like bs-06/bs-08/bs-09 (and unlike bs-02/bs-04, whose scaffolds left
// [pendingACs] empty for ITEST-1 to seed), the bs-11 plan seeds all 10
// *automated* ACs here in CONF-1 (scaffold) — each mapped to the behaviour
// phase that un-pends it. ITEST-1 builds the bs-11 accessibility harness
// (Given/When/Then vocabulary + the real-screen and non-compliant control
// fixtures, over the reusable conformance check) on top of this; ITEST-2/3
// register the per-AC tests via [acTestWidgets] in
// `integration_test/accessibility_test.dart`; the behaviour phases (A11Y-2..7,
// GATE-2/3/4) un-pend their AC by deleting its row here.
//
// AC-10 (manual eyes-free walkthrough) and AC-12 (on-device VoiceOver-vs-
// TalkBack parity) are **pure-manual gates** (plan D-2): they have no code, no
// automated test, and are therefore **absent** from this gate — they are
// performed and recorded by the reviewer at SIGNOFF-1 (gates G-3/G-4).
//
// Keyed to `BS11_RUN_PENDING` so a bs-11 run-pending pass is independent of the
// earlier features' `BS0n_RUN_PENDING` flags.
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
/// `flutter test integration_test/accessibility_test.dart` skips pending ACs
/// (their bodies, which assert un-built behaviour, never run); set
/// `BS11_RUN_PENDING=1` (or `--dart-define=BS11_RUN_PENDING=true` on-device) to
/// execute them (the red-baseline / un-pend run).
///
/// Seeded with all 10 automated bs-11 ACs in CONF-1 (scaffold); each behaviour
/// phase then removes the row it owns as it un-pends that AC. Every owner must
/// be a member of [behaviorPhases]. The owner is the phase whose acceptance
/// gate un-pends the AC, matching the master plan's AC-coverage table:
///   AC-1 colour cue              → A11Y-5 (colour-cue / no-bare-dot slice)
///   AC-2 no bare colour dot      → A11Y-5 (same slice)
///   AC-3 200% font scaling       → A11Y-4
///   AC-4 48dp tap targets        → A11Y-3
///   AC-5 AA contrast floor       → A11Y-2
///   AC-6 meaningful labels       → A11Y-6
///   AC-7 eyes-free walkthrough   → GATE-2 (semantics-only driver)
///   AC-8 nothing auto-dismisses  → A11Y-7
///   AC-9 failed check not accepted → GATE-3 (aggregate acceptanceDecision)
///   AC-11 WCAG 2.2 AA floor      → GATE-4 (recordedLevel)
///
/// AC-10 and AC-12 are **not** here — pure-manual gates (D-2), closed at
/// SIGNOFF-1 (G-3/G-4).
const Map<String, String> pendingACs = {
  'AC-1': 'A11Y-5',
  'AC-2': 'A11Y-5',
  'AC-3': 'A11Y-4',
  'AC-4': 'A11Y-3',
  // AC-5 (AA contrast floor) un-pended by A11Y-2.
  'AC-6': 'A11Y-6',
  'AC-7': 'GATE-2',
  'AC-8': 'A11Y-7',
  'AC-9': 'GATE-3',
  'AC-11': 'GATE-4',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-11 behaviour phases from the master plan
/// (A11Y-2..7 + GATE-2/3/4). AC-10/AC-12 are manual gates and own no row, so
/// SIGNOFF-1 is intentionally not listed here.
const Set<String> behaviorPhases = {
  'A11Y-2',
  'A11Y-3',
  'A11Y-4',
  'A11Y-5',
  'A11Y-6',
  'A11Y-7',
  'GATE-2',
  'GATE-3',
  'GATE-4',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS11_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS11_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS11_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS11_RUN_PENDING=true`. Host-process runs may
/// also set the `BS11_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS11_RUN_PENDING'] == '1';

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
  return 'pending $owner — --dart-define=BS11_RUN_PENDING=true to run';
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
