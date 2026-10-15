// BS13 Paint-dataset-integrity acceptance-suite pending gate (seeded in ITEST-1).
//
// This is the bs-13 mirror of bs-10's `integration_test/bs10/pending.dart`
// (itself a mirror of bs-09/bs-06/bs-04/bs-03/bs-02's pending files and bs-01's
// mechanism in `integration_test/harness.dart`): the plumbing that lets stage 3
// land one *pending* integration test per AC while the suite stays green, then
// un-pend each AC as its behaviour phase lands.
//
// The bs-13 plan seeds all 11 ACs here in ITEST-1 (this phase) — each mapped to
// the behaviour phase whose acceptance gate un-pends it (the master plan's
// AC-coverage table / ITEST red-baseline "Owning phase" column). ITEST-2/3
// register the per-AC tests via [acTestWidgets] (AC-1/2/4/5/6/11, observed
// through the widget `DatasetReadEndpoint`) and [acTest] (AC-3 guard scan, and
// AC-7/8/9/10 pure-domain provenance); the behaviour phases (SEED-3/4/5,
// PROV-2/3, GUARD-2) un-pend their AC by deleting its row here.
//
// Keyed to `BS13_RUN_PENDING` so a bs-13 run-pending pass is independent of the
// other features' `BS0n_RUN_PENDING` / `BS10_RUN_PENDING` flags.
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
/// `flutter test integration_test/bs13/dataset_test.dart -d flutter-tester`
/// skips pending ACs (their bodies, which assert un-built behaviour, never
/// run); set `--dart-define=BS13_RUN_PENDING=true` (or host env
/// `BS13_RUN_PENDING=1`) to execute them (the red-baseline / un-pend run).
///
/// Seeded with all 11 bs-13 ACs in ITEST-1; each behaviour phase then removes
/// the row it owns as it un-pends that AC. Every owner must be a member of
/// [behaviorPhases]. The owner is the phase whose acceptance gate un-pends the
/// AC, matching the master plan's AC-coverage table and ITEST's red baseline:
///   AC-1  → (un-pended at SEED-3 — shipped seed asset + loader; solver mixes
///            over its optical data)
///   AC-2  → SEED-4   (candidate-origin manifest)
///   AC-3  → GUARD-2  (ratios-from-solver guard)
///   AC-4  → SEED-4   (ingest accept metadata / reject claimed values)
///   AC-5  → SEED-5   (held-out validation manifest)
///   AC-6  → SEED-5   (ship decision: threshold ∧ beats-LLM)
///   AC-7  → PROV-2   (tier-by-origin derivation)
///   AC-8  → (un-pended at ITEST-3 — green at baseline; PROV-2 still owns it)
///   AC-9  → PROV-3   (Estimated→Confirmed on a measured swatch)
///   AC-10 → PROV-3   (opinions never promote)
///   AC-11 → (un-pended at SEED-3 — shipped seed stays narrow)
const Map<String, String> pendingACs = {
  // AC-1 (recipes solved from optical data) un-pended at SEED-3 — the shipped
  // seed asset + AssetSeedLoader make the solver mix over real optical data.
  'AC-2': 'SEED-4',
  'AC-3': 'GUARD-2',
  'AC-4': 'SEED-4',
  'AC-5': 'SEED-5',
  'AC-6': 'SEED-5',
  'AC-7': 'PROV-2',
  // AC-8 (evidence append-only) is NOT pending: the PROV-1 shell froze a working
  // append-only add (`ProvenanceDerivation.appendEvidence` returns
  // `[...old, new]`), so `TestAC08_EvidenceAppendOnly` is green at baseline
  // (ITEST-3, red-baseline rule). PROV-2 still owns AC-8 — it keeps the test
  // green and carries its unit coverage — but the acceptance test runs by
  // default from now on.
  'AC-9': 'PROV-3',
  'AC-10': 'PROV-3',
  // AC-11 (shipped seed stays narrow) un-pended at SEED-3 — the shipped asset
  // covers one brand, one medium, ~15 paints.
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own guard tests to reject a typo'd or stale owner in
/// [pendingACs]. These are the bs-13 behaviour phases from the master plan's
/// build order.
const Set<String> behaviorPhases = {
  'SEED-3',
  'SEED-4',
  'SEED-5',
  'PROV-2',
  'PROV-3',
  'GUARD-2',
};

/// The behaviour phases that have completed and un-pended every AC they own.
///
/// A completed phase legitimately owns no row in [pendingACs] any more, so the
/// harness's "no dead phase" guard treats a phase as valid when it is still a
/// pending owner **or** listed here. Each behaviour phase adds itself here as it
/// un-pends its last AC (SEED-3 un-pended AC-1 and AC-11, its only two).
const Set<String> completedBehaviorPhases = {
  'SEED-3',
};

/// Every AC id the bs-13 acceptance suite covers (the master plan's 11 ACs).
///
/// The scaffold's own guard test asserts the suite registers exactly these, so
/// a missing or stray AC test can't pass vacuously.
const List<String> allACs = <String>[
  'AC-1',
  'AC-2',
  'AC-3',
  'AC-4',
  'AC-5',
  'AC-6',
  'AC-7',
  'AC-8',
  'AC-9',
  'AC-10',
  'AC-11',
];

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/…` runs the tests in the app process on the
/// device (here `flutter-tester`), which does not inherit the host shell's
/// environment — so a `BS13_RUN_PENDING=1` env var set on the host never
/// reaches [runPending] there. A compile-time
/// `--dart-define=BS13_RUN_PENDING=true` does. (The [Platform.environment] path
/// below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS13_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device / `flutter-tester`: pass `--dart-define=BS13_RUN_PENDING=true`.
/// Host-process runs may also set the `BS13_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS13_RUN_PENDING'] == '1';

/// The reason to skip [acId] in this run, or null if it should execute.
///
/// An un-pended AC (absent from [pendingACs]) always runs; a pending AC runs
/// only in run-pending mode. Because the result drives the test runner's native
/// `skip`, a not-yet-built AC's body never executes in the default run — it is
/// *skipped*, never *failed*. [forceRunPending] overrides the ambient
/// [runPending] mode so the gate's own tests can assert both modes
/// deterministically without touching the environment.
String? pendingSkipReason(String acId, {bool? forceRunPending}) {
  final owner = pendingACs[acId];
  if (owner == null) return null;
  if (forceRunPending ?? runPending) return null;
  return 'pending $owner — --dart-define=BS13_RUN_PENDING=true to run';
}

/// Registers a **widget-driven** AC acceptance test wired to the pending gate.
///
/// Used by ITEST-2 for the ACs observed through the widget `DatasetReadEndpoint`
/// (AC-1/2/4/5/6/11); skipping follows [pendingSkipReason].
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

/// Registers a **pure-Dart** AC acceptance test wired to the pending gate.
///
/// Used by ITEST-2/3 for the ACs that need no widget tree — the AC-3 guard
/// source scan and the AC-7/8/9/10 provenance-model facts; skipping follows
/// [pendingSkipReason].
void acTest(
  String acId,
  String description,
  dynamic Function() body,
) {
  final reason = pendingSkipReason(acId);
  final name = reason == null
      ? '$acId: $description'
      : '$acId: $description ($reason)';
  test(name, body, skip: reason ?? false);
}
