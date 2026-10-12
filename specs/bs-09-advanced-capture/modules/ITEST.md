# Module ITEST — acceptance integration suite (bs-09)

**Status:** In progress — ITEST-1 done; next ITEST-2 → ITEST-3 (sequential: shared test file)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/advanced_capture_test.dart`,
`integration_test/advanced_capture_harness.dart`, `integration_test/bs09/pending.dart`,
torch/colour-space/RAW/platform/multi-point fixtures and the extended `FakeCaptureSource` test knobs
**Depends on:** all shell phases (SOURCE-1, CAPTURE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 8,883,964 | 54m 53s (57m 55s) |
| ITEST-2 | acceptance-tests | AC-1,2,3,4,5 (pending) | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-6,7,8,9,10 (pending) | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the whole app via `buildApp(AppDependencies(...))` on the Capture route, driven through the
  real UI with `WidgetTester` (reusing bs-02's `capture_harness.dart` — `CaptureHarness`, `givenCaptureOf`).
  Real: sampling, controller, Capture screen, routing, and bs-03's comparison. Faked (infrastructure only):
  the extended `FakeCaptureSource` and bs-01's `FakeHaptics`/`FakeSpeech`.
- **Observation points:**
  - AC-1 — the warning banner widget (colour-temperature text) + `controller.state.torchOn`.
  - AC-2 — `state.lastCommittedSample.litByTorch` via `CaptureReadEndpoint`.
  - AC-3 — `state.markedReadings.length` (== 3).
  - AC-4 — the rendered readings list (each reading's position + value) and `state.markedReadings`.
  - AC-5 — bs-03 `ComparisonReadEndpoint.slotA`/`slotB` after the pair handoff.
  - AC-6/7/8/9 — `state.lastCommittedSample.colorSpace` / `.captureMode` / coordinates; `supportsWideGamut` /
    `supportsRaw` for the Givens.
  - AC-10 — two committed samples (one per platform scene) compared for equal coordinates + equal tag.
- **Pending gate:** `integration_test/bs09/pending.dart` modelled on `bs02/pending.dart` —
  `const Map<String,String> pendingACs` (seeded with all 10), `acTestWidgets(acId, desc, body)` skipping
  while pending, `runPending` driven by `BS09_RUN_PENDING` (env `=1` on host or `--dart-define=…=true`
  on-device). Un-pend = delete the AC's row from `pendingACs`.

## Phase ITEST-1 — harness, fixtures, pending gate, smoke

- **Kind:** acceptance-tests
- **Depends on:** SOURCE-1, CAPTURE-2, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `advanced_capture_harness.dart`, `advanced_capture_test.dart`, `bs09/pending.dart`, fixtures +
  fake knobs
- **Tasks:**
  1. Build `advanced_capture_harness.dart` re-exporting bs-02's `capture_harness.dart` + `bs09/pending.dart`,
     adding `when`-actions for the new controls (torch, mark points, sample points, send pair) and the new
     fixtures (`SCENE_DIM_TORCH`, `SCENE_THREE_POINTS`, `SCENE_WIDE`, `SCENE_NARROW`, `SCENE_RAW`,
     `SCENE_ANDROID`, `SCENE_IOS`).
  2. Seed `pendingACs` with the 10 ACs; add a never-pending smoke test proving the shells wire end to end,
     plus guard tests over the pending gate and fixtures.
- **Exit criteria:** smoke + guard tests green; full regression green with all 10 pending; coverage gate
  passes; grade A.

### Result (ITEST-1)

- **Landed:** `advanced_capture_harness.dart` — re-exports bs-02's `capture_harness.dart`
  (`CaptureHarness` / `givenCaptureOf`, the bs-02 scenes, `Photo`, the fakes) **with bs-02's own pending gate
  hidden** so bs-09's `bs09/pending.dart` gate is the one in scope; also re-exports capture-state / source /
  sampling / frame / color-coordinates and bs-03's comparison endpoint+state. Adds the 7 fixtures
  (`SCENE_DIM_TORCH`, `SCENE_THREE_POINTS` as a `MultiPointScene` with its points + per-point colours,
  `SCENE_WIDE`, `SCENE_NARROW`, `SCENE_RAW`, `SCENE_ANDROID`, `SCENE_IOS`), the `AdvancedCaptureActions`
  extension (`whenTurnTorchOn/Off`, `whenAcknowledgeTorchWarning`, `whenMarkPoint(s)`, `whenSamplePoints`,
  `whenSendToComparison`, `whenSendPairToComparison`, `comparisonController`), and `sampleSceneAt` /
  `labDistance`. `advanced_capture_test.dart`: 3 pending-gate guards + 6 fixture guards + 1 never-pending smoke.
- **Gates:** `flutter analyze` clean; unit `flutter test --coverage` → **892 pass**; coverage gate
  `dart run tool/coverage_gate.dart main` → **100%** on the 10 touched lib files (ITEST-1 touched no `lib/`, so
  the cumulative set vs `main` is unchanged). Integration `flutter test integration_test/ -d <iPhone 17>` under
  the device lock → **142 pass**, exit 0 (the 10 bs-09 tests all green; **0 ACs un-pended** — no AC tests yet).
- **No red baseline / grade grid** this phase: no AC tests written (they land in ITEST-2/3). Scaffold-test
  discipline met — no vacuous passes (exact-set / `hasLength` assertions guard the loops; the fixtures are
  checked through the **real** `sampleAreaAverage` and the real `SoftwareCaptureSource` capability getters, not
  faked), honest comments, deterministic (no sleeps).
- **Fix passes:** 0/3. (Two `flutter analyze` fixes *before* the first gate run — an unused import and
  `SCENE_DIM_TORCH.scene` → the plain `CaptureScene` — so they don't count as fix passes.)
- **Tokens / time:** 8,883,964 · 54m 53s (57m 55s).

### Checkpoint / Handoff (ITEST-1 → ITEST-2, ITEST-3)

- **Frozen for the AC-test phases:** import `advanced_capture_harness.dart` only. Register each AC with
  `acTestWidgets('AC-n', '<slug>', (tester) async {…})`. Given via `givenCaptureOf(tester, <scene>)` (multi-point:
  `SCENE_THREE_POINTS.scene`, then `h.whenMarkPoints(SCENE_THREE_POINTS.points)`). Whens: `h.whenTurnTorchOn`,
  `h.whenAcknowledgeTorchWarning`, `h.whenSamplePoints`, `h.whenSendPairToComparison(i, j)`, bs-02's `h.whenCommit`.
  Thens: `h.state` (`torchOn` / `torchWarning` / `markedPoints` / `markedReadings` / `lastCommittedSample` →
  `litByTorch` / `colorSpace` / `captureMode`), the rendered readings list / torch-warning banner / marked-point
  markers, and `h.comparisonController.state` (`slotA` / `slotB`) after the AC-5 handoff. Grade each per-point
  value against `SCENE_THREE_POINTS.colorsAtPoints` / `sampleSceneAt` (the real sampling maths).
- **⚠ ITEST-2 and ITEST-3 share the one AC-test file `advanced_capture_test.dart`** (the module's sole AC-test
  file), so they **must run sequentially**, not in parallel (mirror bs-08's ITEST-2/3), unless a future re-plan
  splits them into two files. The master's `{ITEST-2, ITEST-3}` "concurrent" window does not hold with a shared
  file — flagged here as drift.
- **Known gaps:** every `when`-action over a deferred control (`turnTorchOn/Off`, `acknowledgeTorchWarning`,
  `markPoint`, `sampleMarkedPoints`, `sendPairToComparison`) throws `UnimplementedError` until its behaviour
  phase — which is exactly why each AC that uses one stays pending until then. SCREEN-1's send-to-comparison
  button carries a placeholder index pair (0, 1); a chosen pair goes through `whenSendPairToComparison` until
  CAPTURE-5 wires the selection.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host, no sim). Acceptance (needs a booted sim — always pass `-d <udid>`, no device ⇒ zero tests, false
  green): `flutter test integration_test/advanced_capture_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`;
  run-pending adds `--dart-define=BS09_RUN_PENDING=true`. Run sim commands under `coord.sh with-lock
  bs-09-advanced-capture <PHASE> --wait <n> -- …` (coord repo `/Users/matthew.quirk/Nuance`). No `timeout` on this
  macOS. Flutter SDK: `/Users/matthew.quirk/development/flutter/bin`.

## Phase ITEST-2 — AC tests: torch + multi-point (AC-1,2,3,4,5)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Tasks:** one *pending* `acTestWidgets` per AC (`TestAC01_…`..`TestAC05_…`) following the master
  catalogue rows; capture the run-pending red baseline below; grade each row (grade-A design).
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

## Phase ITEST-3 — AC tests: colour-space / RAW / normalization (AC-6,7,8,9,10)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Tasks:** one *pending* `acTestWidgets` per AC (`TestAC06_…`..`TestAC10_…`) per the catalogue; red
  baseline; grade.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (per-AC catalogue + red baseline + grade grid + fixtures); full
  regression green with the 10 pending; raise **G-2** for a human decision.
- **Exit criteria:** packet complete; G-2 recorded by a human (the agent never approves).

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_TorchWarnsColourTemp | — | — | SCREEN-2 | — |
| AC-2 | TestAC02_ReadingLabelledTorchLit | — | — | CAPTURE-3 | — |
| AC-3 | TestAC03_MultiPointSamplesAllAtOnce | — | — | CAPTURE-4 | — |
| AC-4 | TestAC04_EachPointKeepsPositionValue | — | — | SCREEN-3 | — |
| AC-5 | TestAC05_TwoPointsToComparison | — | — | CAPTURE-5 | — |
| AC-6 | TestAC06_TaggedWithColourSpace | — | — | SOURCE-2 | — |
| AC-7 | TestAC07_RawWhereSupported | — | — | SOURCE-3 | — |
| AC-8 | TestAC08_FallbackLabelsNarrower | — | — | SOURCE-2 | — |
| AC-9 | TestAC09_NormalizedTaggedSample | — | — | SOURCE-4 | — |
| AC-10 | TestAC10_PlatformAgnosticSample | — | — | SOURCE-4 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| — | none pre-seeded (each AC test carries its discriminating control in-fixture) | — | — | — |
