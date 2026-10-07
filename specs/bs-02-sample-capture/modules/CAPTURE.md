# Module CAPTURE — scaffold, capture controller, accuracy, commit

**Status:** In progress — CAPTURE-3 (behavior) done; lock lifecycle + stability settling landed, AC-4/AC-5 un-pended green. Next CAPTURE-4 (AC-6, AC-7; depends on SOURCE-2 — merged)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_controller.dart`, `lib/capture/capture_state.dart`, `lib/capture/capture_accuracy.dart`, `lib/capture/capture_read_endpoint.dart`; edits to bs-01's `lib/app/build_app.dart` and `lib/app/router.dart` (add the Capture route); the BS02 pending-runner wiring the scaffold adds.
**Depends on:** SOURCE (consumes `CaptureSource` + sampling), bs-01 `Haptics` + Readout route · **Blocks:** SCREEN, ITEST, every capture behavior

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 2,239,601 | 8m 15s (8m 15s) |
| 2 | shell | — | ✅ Done | 9,221,563 | 16m 54s (16m 54s) |
| 3 | behavior | AC-4, AC-5 | ✅ Done | 51,577,446 | 1h 28m (3h 35m) |
| 4 | behavior | AC-6, AC-7 | ⬜ Todo | | |
| 5 | behavior | AC-8 | ⬜ Todo | | |
| 6 | behavior | AC-11 | ⬜ Todo | | |

## Interface reconciliation

- **`CaptureController`** (CAPTURE-2, frozen) `extends ChangeNotifier`, `CaptureController({required CaptureSource source})`.
  Exposes `CaptureState get state`; placeholder actions `lock()`, `setRadius(int px)`, `calibrate()`,
  `dismissWarning()`, `toggleValueOnly()`, `commit()` each `throw UnimplementedError('<name>: behaviour lands
  in <phase>')` (lock→CAPTURE-3, setRadius→SCREEN-2, calibrate→CAPTURE-5, dismissWarning→CAPTURE-4,
  toggleValueOnly→SCREEN-3, commit→CAPTURE-6). A single `@protected void emit(CaptureState next)` mutation
  seam (no-op + notify) is the path the behaviour phases move state through.
- **`CaptureState`** (CAPTURE-2, frozen) — immutable + `copyWith` + `==`/`hashCode` + `toString`. Fields:
  `LockState lockState` (enum `auto`/`locked`, default `auto`), `int stabilityCount` (0, the n in n/12),
  `int radiusPx` (default `kDefaultSamplingRadiusPx` = 5), `CaptureAccuracy accuracy` (default `approximate`),
  `bool valueOnly` (false), `bool lowLightWarning` (false), `Sample? currentSample`, `Sample? lastCommittedSample`,
  `int framesAveraged` (0). Derived: `bool get isStable` (count ≥ 12), `String get stabilityText`
  ("STABLE 12/12" when stable **or** locked, else "SETTLING n/12"). `copyWith` is set-forward on the nullable
  sample fields (`x ?? this.x`).
- **`CaptureAccuracy`** (D-3, CAPTURE-2, frozen): plain `enum { approximate, calibrated }` with
  `String get label` ('Approximate' / 'Calibrated') and `double get maxDeltaE` (8 / 3) — the numeric ΔE00
  bound the accuracy tests assert (D-4). CAPTURE-4/5 set it; tests compare the **enum value** (label is UI text).
- **`Sample.accuracy`** (added to bs-01's shared `lib/domain/sample.dart`): `final CaptureAccuracy? accuracy`,
  **nullable, default null** — a non-capture (bs-01) sample leaves it null, so bs-01 readout is unaffected.
  In `copyWith` (set-forward) and appended to `toString` only when non-null. `sample.dart` now imports
  `../capture/capture_accuracy.dart` (domain → capture, accepted per D-3 so accuracy rides on the shared Sample).
- **Read endpoint** `CaptureReadEndpoint` (`capture_read_endpoint.dart`): an `InheritedWidget` carrying the
  `CaptureController` (→ `.state` and `.source`, incl. the fake's ground truth). Find it with
  `find.byKey(CaptureReadEndpoint.endpointKey)` (`Key('capture-read-endpoint')`) or `CaptureReadEndpoint.of(context)`.
  Observation seam only; production screens read their own controller.
- **Routing:** `AppRouter.toReadout(Sample)` added to `router.dart` (pushes `ReadoutScreen(sample:)` — CAPTURE-6's
  commit uses it, D-5). `AppDependencies.captureSource` (`CaptureSource?`, default null) added to `build_app.dart`;
  `buildApp` opens on `CaptureHomeScreen` when a source is wired, else bs-01's Readout. `CaptureHomeScreen`
  (in `build_app.dart`) owns the controller (built from the injected source via `AppScope`, disposed on teardown)
  and wraps its subtree in the read endpoint; its body is a placeholder (AppBar "Capture") **SCREEN-1 replaces**.
  Production `main.dart` injects a `SoftwareCaptureSource` (demo scene) → the shipped app opens on Capture.

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

### Result

Landed four new `lib/capture` files — `capture_accuracy.dart` (enum, D-3), `capture_state.dart`
(`CaptureState` + `LockState`), `capture_controller.dart` (`CaptureController extends ChangeNotifier`,
deferred actions throw with their owning phase, `@protected emit` seam), `capture_read_endpoint.dart`
(`CaptureReadEndpoint` InheritedWidget) — and wired capture into the app: `Sample` gains a nullable
`accuracy` field (bs-01 shared file, default null → bs-01 unaffected), `AppRouter.toReadout(Sample)` for
CAPTURE-6's commit→Readout (D-5), `AppDependencies.captureSource` (`CaptureSource?`) + `CaptureHomeScreen`
in `build_app.dart` (owns the controller, wraps the subtree in the read endpoint, placeholder body SCREEN-1
replaces), and `main.dart` injects a `SoftwareCaptureSource` so the shipped app opens on Capture. Exact
shapes recorded in **Interface reconciliation**.

Verification (Flutter 3.47.6, `~/development/flutter/bin` on PATH): `flutter analyze` clean. Unit: 264 tests
green (was 229 — +35 across capture_accuracy/state/controller/read_endpoint, build_app, router, sample
tests). Coverage gate `dart run tool/coverage_gate.dart main`: **100% on all 12 touched `lib` files, PASS**.
Integration `flutter test integration_test/`: bs-01's 17 tests green (bs-01 `givenReadoutOf` passes no
capture source → still opens on Readout, unchanged). App-launches-to-Capture proven at unit level via
`build_app_test` (buildApp+source → `CaptureHomeScreen`, AppBar "Capture", endpoint over the injected
source, controller disposed on teardown) and `smoke_test` (`main()` boots to the Capture AppBar).

**bs-01 test change (recorded):** `test/smoke_test.dart` `main()`-boots assertion changed from Readout to
the Capture AppBar, because bs-02 D-2 moved the production entry point to Capture; not an AC test, no AC
weakened. No `pendingACs` touched (shell un-pends nothing). Fix passes: 2/3 (1 — smoke-test matched a
duplicate "Capture" text, retargeted to the AppBar; 2 — the accuracy enum had no executable lines so was
absent from lcov, rewrote its `label`/`maxDeltaE` as `switch` getters like bs-01 `Provenance.label`). No
exclusions, no augmentations. Tokens 9,221,563 · time 16m 54s (16m 54s).

### Checkpoint / Handoff

- **Verification commands:** unchanged from SOURCE-1 (PATH export + `flutter analyze` / `flutter test
  --coverage` / `flutter test integration_test/` / `dart run tool/coverage_gate.dart main`).
- **Frozen interfaces (CAPTURE-2):** `CaptureController`, `CaptureState`/`LockState`, `CaptureAccuracy`,
  `Sample.accuracy`, `CaptureReadEndpoint`, `AppRouter.toReadout`, `AppDependencies.captureSource`,
  `CaptureHomeScreen` — all detailed in **Interface reconciliation**. Behaviour phases move state **only**
  through `CaptureController.emit` and un-defer the action methods (replace each `throw` with real behaviour).
- **For SCREEN-1 (next shell):** replace `CaptureHomeScreen`'s placeholder body (in `lib/app/build_app.dart`)
  with the real `lib/capture/capture_screen.dart` scaffold — keep the controller ownership + `CaptureReadEndpoint`
  wiring (read the source from `AppScope.of(context).captureSource!`, dispose the controller). Render the
  E15–E21 regions, eyedropper and stability indicator as findable placeholders bound to `controller.state`.
- **For ITEST-1:** the harness builds `buildApp(AppDependencies(..., captureSource: FakeCaptureSource(...)))`
  → app opens on Capture; observe state via `find.byKey(CaptureReadEndpoint.endpointKey)` →
  `.controller.state` (and `.controller.source` for the fake's ground truth).
- **Known gaps:** controller actions intentionally throw `UnimplementedError` until their behaviour phase;
  `CaptureHomeScreen` body is a placeholder until SCREEN-1. G-3 still gates every behaviour phase.
- **Next phase (SCREEN-1):** shell — Capture screen scaffold (E15–E21 placeholders) bound to the controller.

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

### Result

Landed lock lifecycle + stability settling on `capture_controller.dart`, with the lock indicator on
`capture_state.dart` + `capture_live_view.dart`. **Settling** advances one step per *rendered frame* while
unlocked and not yet stable (a `SchedulerBinding.addPostFrameCallback` loop in the controller, guarded
`auto && !isStable`, re-arming each frame and stopping at the target or on lock) — a render-frame proxy for
the camera settling, which climbs to STABLE 12/12 in ~12 frames in production. **`lock()`** locks the
source AE/AWB/AF and settles at once to `LockState.locked` + `stabilityCount = 12`. New derived reading
`CaptureState.lockIndicatorText` ("AE · AWB · AF LOCKED" / "… AUTO") rendered at `lockIndicatorKey`.

**Harness change (necessary, flag for review — G-3 territory):** `givenCaptureOf` now mounts with a single
`pumpWidget` instead of `pumpAndSettle`. Reason: the settling tick advances per rendered frame, so
`pumpAndSettle` would drive it straight to STABLE 12/12 and the screen could never be observed at
"SETTLING 0/12". With a single mount the screen opens at "SETTLING 0/12" (the first build renders before the
first tick draws) with `currentSample` already sampled from the drained feed; `_pumpUntilText` then watches
it climb one step per `tester.pump()`. `when…` actions still `pumpAndSettle` locally. No AC assertion was
weakened (see the regrade); AC-tests AC-1/2/9 stay green. This conflates "pump a frame" with "a camera frame
arriving" — the real reason the AC-4/AC-5 settling contract and SOURCE-2's drained feed could not otherwise
co-exist; recommend a test-review confirm.

Un-pended **AC-4, AC-5** (deleted their `pendingACs` rows; updated the pending-gate guard: expectedOwners
now 6 entries). Acceptance gate green: `TestAC04_LockSettles` + `TestAC05_SettlingWarns` pass run-pending;
default integration suite **13 pass + 6 pending-skipped**. Unit **302 pass**; `flutter analyze` clean;
coverage gate **100% on all 3 touched lib files, PASS**.

**Other test changes (recorded, not AC-weakening):** `build_app_test` now asserts the opened screen shows
"SETTLING 0/12" on the live view (was `state.stabilityText`, which now reads 1/12 after the first frame);
`capture_screen_test` "binds…" locks first so the live ticker stops before the identity check;
`capture_controls_test` moved E16 out of the still-deferred group into a live-lock assertion;
`capture_controller_test` added a settling/lock group (and `TestWidgetsFlutterBinding.ensureInitialized()`,
since the constructor now touches `SchedulerBinding`). Grade gate: 5×A on the un-pended set (AC-1/2/4/5/9), fresh independent regrade; whole-suite grid 10×A + AC-6 B-pending-CAPTURE-5 unchanged; the `givenCaptureOf` change weakened no AC (AC-9 strengthened — its photo-import feed-switch guard is now exercised by the AC test) (fresh independent regrade of
every un-pended AC test). Fix passes: 1/3 (unit-test breakages from the new behaviour — lock no longer
throws, the shared `givenCaptureOf` change, `LockState` import clash with Flutter's `LockState`). No
exclusions, no augmentations. Tokens 51,577,446 · time 1h 28m (3h 35m).

### Checkpoint / Handoff

- **Verification commands:** unchanged (PATH export + `flutter analyze` / `flutter test --coverage` /
  `flutter test integration_test/capture_test.dart` [+ `--dart-define=BS02_RUN_PENDING=true` to run pending] /
  `dart run tool/coverage_gate.dart <base>`).
- **Frozen interfaces (CAPTURE-3):** `CaptureController.lock()` is live (locks source AE/AWB/AF + emits
  `LockState.locked`, `stabilityCount = 12`); the controller runs a per-rendered-frame settling tick while
  `auto && !isStable`; `CaptureState.lockIndicatorText`; `CaptureLiveView.lockIndicatorKey`.
- **Harness contract for later phases:** `givenCaptureOf` mounts with one `pumpWidget` (no `pumpAndSettle`),
  so the reading opens at "SETTLING 0/12" and climbs one step per `tester.pump()`. CAPTURE-6's AC-11 reaches
  "STABLE 12/12" via `whenLock()` (its Given), exactly as its test already does.
- **Known gaps:** the `givenCaptureOf` harness change and the render-frame settling model should be confirmed
  at a test-review (approved tests touched). `calibrate` / `dismissWarning` / `toggleValueOnly` / `commit`
  still throw until their phases.
- **Integration note:** built on SOURCE-3 tip (269bfd5 — includes SOURCE-2). This phase branch is **not yet
  merged** into `feat/bs-02-sample-capture`; merge order SOURCE-2 → SOURCE-3 → CAPTURE-3 (all touch the
  controller / harness). Master-plan rollup deferred to reconcile.
- **Next phase (CAPTURE-4, AC-6/AC-7):** low-light detection + accuracy tier + dismiss, over SOURCE-2's feed.

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
