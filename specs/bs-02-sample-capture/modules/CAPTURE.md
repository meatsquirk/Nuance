# Module CAPTURE — scaffold, capture controller, accuracy, commit

**Status:** In progress — CAPTURE-1 (scaffold) done; branch `feat/bs-02-sample-capture`, baseline green, BS02 pending runner wired
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_controller.dart`, `lib/capture/capture_state.dart`, `lib/capture/capture_accuracy.dart`, `lib/capture/capture_read_endpoint.dart`; edits to bs-01's `lib/app/build_app.dart` and `lib/app/router.dart` (add the Capture route); the BS02 pending-runner wiring the scaffold adds.
**Depends on:** SOURCE (consumes `CaptureSource` + sampling), bs-01 `Haptics` + Readout route · **Blocks:** SCREEN, ITEST, every capture behavior

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 2,239,601 | 8m 15s (8m 15s) |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-4, AC-5 | ⬜ Todo | | |
| 4 | behavior | AC-6, AC-7 | ⬜ Todo | | |
| 5 | behavior | AC-8 | ⬜ Todo | | |
| 6 | behavior | AC-11 | ⬜ Todo | | |

## Interface reconciliation

- **`CaptureController`** holds `CaptureState` { `lockState` (auto / locked), `stabilityCount` (n/12) +
  `stabilityText` ("SETTLING 6/12" / "STABLE 12/12"), `radiusPx` (default 5), `accuracy` (`CaptureAccuracy`),
  `valueOnly` (bool), `lowLightWarning` (bool), `currentSample`, `lastCommittedSample`, `framesAveraged` }.
- **`CaptureAccuracy`** (D-3): `{ approximate (ΔE00 ≤ 8, card-less), calibrated (ΔE00 ≤ 3, reference card) }`
  with its user-facing label. Attached to the committed `Sample`; distinct from bs-01 `Provenance`. The
  committed `Sample` gains an `accuracy` field — coordinated with bs-01's shared `Sample` (added here; bs-01
  is not frozen). Record the exact field shape in this section when CAPTURE-2 lands.
- **Read endpoint** (`capture_read_endpoint.dart`): exposes the observable `CaptureState` (and the fake's
  ground-truth hook) to the acceptance tests for the Thens the rendered UI doesn't surface (sampled/committed
  colour value, `framesAveraged`, accuracy value).
- **Routing:** CAPTURE-2 adds a Capture route to bs-01's `router.dart` and wires the controller + a
  `CaptureSource` into `buildApp(deps)`. Commit navigates to bs-01's Readout route (`toReadout(sample)` or the
  existing Readout entry) carrying the committed sample (D-5).

## Open gates

- **G-1 (approve spec)** ✅ Resolved 2026-10-06 (owner Matt Quirk) and **G-2 (bs-01 foundation)** ✅ Resolved
  2026-10-06 (bs-01 merged to `main` at c793839) — CAPTURE-1 is now unblocked.
- **G-3 (approve tests)** blocks CAPTURE-3/4/5/6 (behavior) — still open, decided at the ITEST test review.

## Phase 1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1 and G-2 must be resolved first) · **Blocks:** SOURCE-1, CAPTURE-2, SCREEN-1, ITEST-1
- **Files:** branch only + `integration_test/` pending-runner wiring; no product code beyond the test flag.
- **Tasks:**
  1. Confirm bs-01's foundation is merged to `main` (G-2) and the Flutter SDK is present (bs-01 CORE-1
     installed it; installing it here would be a machine change needing the user's yes). Create the feature
     branch `feat/bs-02-sample-capture` from `main`.
  2. Record the baseline: `flutter analyze`, `flutter test` (bs-01 suites green), and the existing
     coverage-gate tool passing on the clean tree and failing on a planted uncovered line (reuse bs-01's
     `tool/coverage_gate.dart`; do not re-create it).
  3. Add the BS02 pending-runner convention: a `pendingACs` map + `ac('AC-n')` helper keyed to
     `BS02_RUN_PENDING` (mirror bs-01's BS01 mechanism), ready for ITEST-1.
- **Exit criteria:** branch pushed; `flutter analyze` clean; `flutter test` green; coverage gate passes clean
  and fails on a planted gap; baseline recorded.
- **Acceptance gate:** *(n/a — scaffold)*

### Result

Landed: feature branch `feat/bs-02-sample-capture` cut from `main` (b3bcc38). No
product code — bs-01's Flutter project, `tool/coverage_gate.dart` and
`integration_test/` runner are all reused as-is. One new file,
`integration_test/bs02/pending.dart`: the bs-02 mirror of bs-01's BS01 pending
mechanism, keyed to `BS02_RUN_PENDING` (`pendingACs` seeded empty for ITEST-1 to
fill with the 11 ACs, `behaviorPhases` = the 8 bs-02 behaviour phases,
`runPending` / `pendingSkipReason` / `acTestWidgets`). Namespaced under
`integration_test/bs02/` so it never collides with bs-01's flat
`harness.dart` / `readout_test.dart`.

Naming note: the plan sketched the per-AC registrar as `ac('AC-n')`; kept bs-01's
exact name `acTestWidgets(acId, description, body)` instead, so the repo has one
pending-gate convention and ITEST-1/2/3 inherit the known bs-01 shape verbatim.

Verification (Flutter 3.47.6 / Dart 3.13.5, `~/development/flutter/bin` on PATH):
`flutter analyze` clean (no issues). Baseline `flutter test` green — 196 unit
tests. Baseline `flutter test integration_test/` green — 17 tests across bs-01's
`harness_test.dart` + `readout_test.dart`. Coverage gate proven both ways:
PASS on the clean tree (no touched `lib/**.dart` → "nothing to gate", exit 0);
FAIL (exit 1) on a planted uncovered line in `lib/main.dart` ("3/4 lines
covered — uncovered lines: 32"), then reverted clean.

No lib code touched → coverage gate not applicable to this phase's own output
(integration_test files are outside the gate's `lib/**` scope). Fix passes: 0/3
(first full run clean). No augmentations, no exclusions. No gates resolved this
session (G-1/G-2 already resolved; G-3 remains open for the ITEST test review).
Tokens 2,239,601 · time 8m 15s (8m 15s).

### Checkpoint / Handoff

- **Flutter SDK:** at `~/development/flutter` (stable, 3.47.6). Not on the
  default PATH — prepend `export PATH="$HOME/development/flutter/bin:$PATH"`
  before any `flutter`/`dart` command.
- **Verification commands** (repo root, with the PATH export):
  - `flutter analyze`
  - `flutter test --coverage`  → writes `coverage/lcov.info` (gitignored)
  - `flutter test integration_test/`  → bs-01 + (later) bs-02 acceptance suites
  - `dart run tool/coverage_gate.dart main`  (base ref = arg, else
    `$COVERAGE_GATE_BASE`, else `main`)
- **BS02 pending gate:** `integration_test/bs02/pending.dart`. ITEST-1 builds the
  bs-02 harness (Given/When/Then + fixtures) importing it, and seeds `pendingACs`
  with the 11 ACs (AC-1..AC-11); ITEST-2/3 register the per-AC tests via
  `acTestWidgets`; each behaviour phase un-pends its AC by deleting the row.
  Run-pending (red baseline / un-pend): `--dart-define=BS02_RUN_PENDING=true`
  on-device, or `BS02_RUN_PENDING=1` for a host-process run.
- **Frozen interfaces:** none added (no product code). bs-01's `buildApp`,
  router and `Sample` are unchanged; SOURCE-1 / CAPTURE-2 extend them.
- **Known gaps:** none. `pendingACs` is intentionally empty until ITEST-1.
- **Next phase (SOURCE-1):** shell — `CaptureSource` interface + software source
  + sampling signatures. Keep every new `lib` file at 100% line coverage.

## Phase 2 — Shell: controller, state, accuracy, read endpoint, route

- **Kind:** shell
- **Target AC:** —
- **Depends on:** SOURCE-1 · **Blocks:** SCREEN-1, ITEST-1, CAPTURE-3/4/5/6
- **Files:** `lib/capture/capture_controller.dart`, `capture_state.dart`, `capture_accuracy.dart`, `capture_read_endpoint.dart`; edits to `lib/app/build_app.dart`, `lib/app/router.dart`.
- **Tasks:**
  1. Define `CaptureState`, `CaptureAccuracy`, and the `CaptureController` skeleton (fields present, behaviour
     deferred): holds a `CaptureSource`, exposes state, placeholder `lock()`, `setRadius()`, `calibrate()`,
     `dismissWarning()`, `toggleValueOnly()`, `commit()`.
  2. Add the committed-sample `accuracy` field to the shared `Sample` (coordinate with bs-01); default/nullable
     so bs-01 readout is unaffected.
  3. The read endpoint exposing `CaptureState` for tests.
  4. Wire a Capture route into bs-01's router and `buildApp(deps)` (inject controller + a `CaptureSource`);
     app launches to a placeholder Capture screen. Behaviour unchanged elsewhere.
- **Exit criteria:** unit gate passes on new types; `flutter test` green; app builds and launches to the
  Capture route.
- **Acceptance gate:** *(n/a — shell)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Behavior: lock lifecycle + stability settling (AC-4, AC-5)

- **Kind:** behavior
- **Target AC:** AC-4 (full), AC-5 (full). **Enabler** for AC-11 Given ("STABLE 12/12").
- **Depends on:** CAPTURE-2, G-3 · **Blocks:** CAPTURE-6 · ∥ SOURCE-2
- **Files:** `lib/capture/capture_controller.dart` (lock + settling).
- **Tasks:**
  1. Stability settling counter driven by frames: advances n/12 under auto exposure; `stabilityText` =
     "SETTLING n/12" while unlocked, reaching "STABLE 12/12" when settled/locked.
  2. Lock lifecycle: `lock()` locks AE + AWB + AF together; indicator becomes "AE · AWB · AF LOCKED";
     settling completes to "STABLE 12/12". The lock affordance invites locking while unlocked (AC-5).
- **Exit criteria:** un-pend AC-4, AC-5; run-pending green for both; coverage 100% touched; grade A (re-grade
  every un-pended AC test).
- **Acceptance gate:** un-pend AC-4, AC-5; `TestAC04_LockSettles` + `TestAC05_SettlingWarns` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Behavior: low-light detection + accuracy tier + warning (AC-6, AC-7)

- **Kind:** behavior
- **Target AC:** AC-6 (full), AC-7 (full)
- **Depends on:** CAPTURE-2, SOURCE-2, G-3 · **Blocks:** CAPTURE-5 · ∥ SOURCE-3, SCREEN-2
- **Files:** `lib/capture/capture_controller.dart` (low-light + accuracy + warning), `capture_accuracy.dart`.
- **Tasks:**
  1. Assess lighting from the source; in dim light set `lowLightWarning` and commit with
     `CaptureAccuracy.approximate` (ΔE00 ≤ 8) — **never refuse** the capture.
  2. `dismissWarning()` clears the warning without changing the accuracy label (AC-7).
- **Exit criteria:** un-pend AC-6, AC-7; run-pending green; coverage 100% touched; grade A. AC-6 recorded as
  *B pending CAPTURE-5* until its control lands (see augmentation).
- **Acceptance gate:** un-pend AC-6, AC-7; `TestAC06_LowLightApproximate` + `TestAC07_DismissWarning` green
  (committed colour within ΔE00 8 of ground truth; a sample is committed, not refused).
- **Augments:** none here; AC-6's control is added by CAPTURE-5.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 5 — Behavior: reference-card calibration + accuracy upgrade (AC-8)

- **Kind:** behavior
- **Target AC:** AC-8 (full)
- **Depends on:** CAPTURE-4 · **Blocks:** SIGNOFF-1
- **Files:** `lib/capture/capture_controller.dart` (calibration path), `capture_accuracy.dart`.
- **Tasks:**
  1. `calibrate()` when a reference card is present under controlled lighting: normalise captures against the
     card (correct toward ground truth) and upgrade the committed sample to `CaptureAccuracy.calibrated`
     (ΔE00 ≤ 3).
- **Exit criteria:** un-pend AC-8; run-pending green; coverage 100% touched; grade A.
- **Acceptance gate:** un-pend AC-8; `TestAC08_CardCalibrates` green (normalised within ΔE00 3; label upgraded).
- **Augments:** `TestAC06_LowLightApproximate`: add the control — a `SCENE_CARD` calibrated capture reads
  **calibrated** ΔE3 while the card-less dim capture reads **approximate** ΔE8 — proving low light
  specifically downgrades. Clears AC-6's *B pending CAPTURE-5* to A.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 6 — Behavior: multi-frame commit + haptic + open readout (AC-11)

- **Kind:** behavior
- **Target AC:** AC-11 (full)
- **Depends on:** CAPTURE-3 (STABLE), SOURCE-2 (sampling + `averageFrames`), bs-01 `Haptics` + Readout route · **Blocks:** SIGNOFF-1
- **Files:** `lib/capture/capture_controller.dart` (commit), route call into Readout.
- **Tasks:**
  1. `commit()`: average several source frames (`averageFrames`), build a `Sample` (ColorCoordinates +
     provenance + `CaptureAccuracy`), set `justCaptured`, record `framesAveraged`.
  2. Fire exactly one `Haptics` confirm pulse; navigate to bs-01's Readout carrying the sample (D-5).
- **Exit criteria:** un-pend AC-11; run-pending green; coverage 100% touched; grade A.
- **Acceptance gate:** un-pend AC-11; `TestAC11_CommitOpensReadout` green (committed colour == multi-frame
  mean, not a single frame; one haptic; Readout shows "Deep Olive Green").
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
