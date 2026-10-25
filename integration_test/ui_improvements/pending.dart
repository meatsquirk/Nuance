// bs-20 UI-improvements acceptance-suite pending gate (ITEST-1).
//
// The bs-20 mirror of the sibling per-feature gates
// (`integration_test/bs14/pending.dart`, `integration_test/bs08/pending.dart`,
// …, and bs-01's mechanism in `integration_test/harness.dart`): the plumbing
// that lets stage 3 land one *pending* integration test per AC while the suite
// stays green, then un-pend each AC as its behaviour phase lands.
//
// ITEST-1 (this phase) seeds the gate mechanism and the AC/phase bookkeeping,
// and the harness (`harness.dart`) and smoke test (`smoke_test.dart`) around it.
// ITEST-2 registers the readout AC tests (AC-1/2/3/4/5/9) and ITEST-3 the
// settings/Speak AC tests (AC-6/7/8) via [acTestWidgets]; the behaviour phases
// (A11Y-2, READOUT-3..READOUT-8) un-pend their AC by deleting its row from
// [pendingACs] and recording the un-pend in [completedBehaviorPhases].
//
// Keyed to `BS20_RUN_PENDING` so a bs-20 run-pending pass is independent of the
// other features' `BS0n_RUN_PENDING` / `BS1n_RUN_PENDING` flags.
//
// AC ids mirror the master plan's `AC-n` names verbatim, so this file opts out
// of lowerCamelCase for them.
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
/// `flutter test integration_test/ui_improvements/<file>_test.dart -d flutter-tester`
/// skips pending ACs (their bodies, which assert un-built behaviour, never
/// run); set `--dart-define=BS20_RUN_PENDING=true` (or host env
/// `BS20_RUN_PENDING=1`) to execute them (the red-baseline / un-pend run).
///
/// Seeded with all 9 bs-20 ACs here in ITEST-1; each behaviour phase then
/// removes the row it owns as it un-pends that AC. Every owner must be a member
/// of [behaviorPhases]. The owner is the phase whose acceptance gate un-pends
/// the AC, matching the master plan's AC-coverage table:
///   AC-1 → READOUT-4   (value-hero card)
///   AC-2 → READOUT-5   (0–10 value scale)
///   AC-3 → READOUT-4   (equal-size swatches)
///   AC-4 → READOUT-3   (all spaces at once; selector removed)
///   AC-5 → READOUT-6   (per-space definitions)
///   AC-6 → A11Y-2      (accessibility features off by default)
///   AC-7 → READOUT-7   (Speak hidden while accessibility off)
///   AC-8 → READOUT-7   (Speak shown when accessibility on)
///   AC-9 → READOUT-8   ("Color" rather than "Colour")
const Map<String, String> pendingACs = {
  // AC-1 un-pended by READOUT-4 (2026-10-25): the lightness reads in a bordered
  // hero card as the largest reading — proven green by `TestAC01_HeroCard`.
  // AC-2 un-pended by READOUT-5 (2026-10-25): the Munsell value reads on a
  // labelled 0–10 scale with the sample's step marked — proven green by
  // `TestAC02_ValueScale`.
  // AC-3 un-pended by READOUT-4 (2026-10-25): the displayed-colour swatch is
  // sized equal to the grayscale value swatch — proven green by
  // `TestAC03_EqualSwatches`.
  // AC-4 un-pended by READOUT-3 (2026-10-25): every colour space shown together
  // in the all-spaces region, the one-at-a-time selector removed — proven green
  // by `TestAC04_AllSpaces`.
  // AC-5 un-pended by READOUT-6 (2026-10-25): each colour space's name is
  // tappable and opening it reveals a fuller plain-language definition with an
  // example — proven green by `TestAC05_Definitions`.
  // AC-6 un-pended by A11Y-2 (2026-10-25): accessibility features off by
  // default — satisfied by the A11Y-1 shell's `DisplaySettings` default and
  // proven green by `TestAC06_DefaultOff`.
  // AC-9 un-pended by READOUT-8 (2026-10-25): the readout copy uses the
  // American "Color" and no "Colour"/"colour" appears — proven green by
  // `TestAC09_ColorSpelling`.
  'AC-7': 'READOUT-7',
  'AC-8': 'READOUT-7',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the smoke test's "real owner" guard to reject a typo'd or stale owner
/// in [pendingACs]. These are the bs-20 behaviour phases from the master plan's
/// build order.
const Set<String> behaviorPhases = {
  'A11Y-2',
  'READOUT-3',
  'READOUT-4',
  'READOUT-5',
  'READOUT-6',
  'READOUT-7',
  'READOUT-8',
};

/// The behaviour phases that have completed and un-pended every AC they own.
///
/// A completed phase legitimately owns no row in [pendingACs] any more, so the
/// smoke test's "no dead phase" guard treats a phase as valid when it is still a
/// pending owner **or** listed here. Each behaviour phase adds itself here as it
/// un-pends its last AC.
const Set<String> completedBehaviorPhases = {
  'A11Y-2', // un-pended AC-6 (accessibility features off by default)
  'READOUT-3', // un-pended AC-4 (every colour space shown together, no selector)
  'READOUT-4', // un-pended AC-1 (bordered hero card) + AC-3 (equal-size swatches)
  'READOUT-5', // un-pended AC-2 (0–10 Munsell value scale with the value marked)
  'READOUT-6', // un-pended AC-5 (per-space openable definitions with examples)
  'READOUT-8', // un-pended AC-9 ("Color" rather than "Colour" in readout copy)
};

/// Every AC id the bs-20 acceptance suite covers (the master plan's 9 ACs).
///
/// The smoke test asserts this universe is exactly these nine, so a missing or
/// stray AC can't pass vacuously as the gate empties.
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
];

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/…` runs the tests in the app process on the
/// device (here `flutter-tester`), which does not inherit the host shell's
/// environment — so a `BS20_RUN_PENDING=1` env var set on the host never reaches
/// [runPending] there. A compile-time `--dart-define=BS20_RUN_PENDING=true`
/// does. (The [Platform.environment] path below still serves any host-process
/// run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS20_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device / `flutter-tester`: pass `--dart-define=BS20_RUN_PENDING=true`.
/// Host-process runs may also set the `BS20_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS20_RUN_PENDING'] == '1';

/// The reason to skip [acId] in this run, or null if it should execute.
///
/// An un-pended AC (absent from [pendingACs]) always runs; a pending AC runs
/// only in run-pending mode. Because the result drives the test runner's native
/// `skip`, a not-yet-built AC's body never executes in the default run — it is
/// *skipped*, never *failed*. [forceRunPending] overrides the ambient
/// [runPending] mode so the smoke test can assert both modes deterministically
/// without touching the environment.
String? pendingSkipReason(String acId, {bool? forceRunPending}) {
  final owner = pendingACs[acId];
  if (owner == null) return null;
  if (forceRunPending ?? runPending) return null;
  return 'pending $owner — --dart-define=BS20_RUN_PENDING=true to run';
}

/// Registers a **widget-driven** AC acceptance test wired to the pending gate.
///
/// Used by ITEST-2 / ITEST-3 for every AC (the bs-20 ACs are all observed
/// through the rendered widget tree); skipping follows [pendingSkipReason], so
/// in the default run a not-yet-built AC's body is skipped, and under
/// `BS20_RUN_PENDING=true` it executes (the red-baseline / un-pend run).
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
