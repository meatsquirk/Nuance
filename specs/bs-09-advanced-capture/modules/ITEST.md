# Module ITEST — acceptance integration suite (bs-09)

**Status:** In progress — ITEST-1/2/3/4 done-or-awaiting; ITEST-4 packet assembled, phase ⏸ Awaiting review, **G-2** awaiting a human decision (blocks every behavior phase)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/advanced_capture_test.dart`,
`integration_test/advanced_capture_harness.dart`, `integration_test/bs09/pending.dart`,
torch/colour-space/RAW/platform/multi-point fixtures and the extended `FakeCaptureSource` test knobs
**Depends on:** all shell phases (SOURCE-1, CAPTURE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 8,883,964 | 54m 53s (57m 55s) |
| ITEST-2 | acceptance-tests | AC-1,2,3,4,5 (pending) | ✅ Done | 8,028,691 | 18m 58s (21m 23s) |
| ITEST-3 | acceptance-tests | AC-6,7,8,9,10 (pending) | ✅ Done | 8,511,371 | 23m 24s |
| ITEST-4 | test-review | — (G-2) | ⏸ Awaiting review | 1,911,381 | 7m 15s |

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

### Result (ITEST-2)

- **Landed:** five *pending* `acTestWidgets` in `advanced_capture_test.dart` — `AC-1: TorchWarnsColourTemp`,
  `AC-2: ReadingLabelledTorchLit`, `AC-3: MultiPointSamplesAllAtOnce`, `AC-4: EachPointKeepsPositionValue`,
  `AC-5: TwoPointsToComparison` — all through the real assembled app via the harness: `givenCaptureOf` +
  `whenTurnTorchOn`/`whenAcknowledgeTorchWarning`/`whenMarkPoints`/`whenSamplePoints`/`whenCommit`/
  `whenSendPairToComparison`, observing `h.state` (torchOn/torchWarning/markedPoints/markedReadings/
  `lastCommittedSample.litByTorch`), the rendered `CaptureReadingsList`/`torchWarningKey`, and bs-03's live
  `comparisonController.state` (slotA/slotB) after the pair handoff. AC-2 carries an in-test **torch-off
  control** commit (G5); AC-4 checks each point's own value via `labDistance < 3` against
  `SCENE_THREE_POINTS.colorsAtPoints` and the shown position label; AC-5 asserts both slots filled, slotA=P1,
  slotB=P3, and the two slots > 3 apart.
- **Gates:** `flutter analyze` clean; unit `flutter test --coverage` → **892 pass** (unchanged — no `lib/`
  touched); coverage gate `dart run tool/coverage_gate.dart main` → **100%** on the 10 touched lib files
  (ITEST-2 touched no `lib/`; cumulative set vs `main` unchanged). Acceptance (device lock, iPhone 17 sim
  `5AB9D06D-…`): **default run green** — `+11 ~5`, all 11 ITEST-1 tests pass with AC-1..5 skipped, exit 0;
  **run-pending red baseline** — `+11 -5`, exactly AC-1..5 fail (see the Red baseline table), every one with
  `UnimplementedError` naming a real bs-09 behaviour phase, so none is green-at-baseline.
- **Grade gate:** independent adversarial grade in a fresh subagent against G1–G6 →
  `behavior-test-completeness-bs-09-advanced-capture.md` (in the feature dir). **ITEST-2: 5 A / 0 below A**;
  it also (re-)graded the ITEST-1 artifacts → **11 A** (whole suite so far **16 A, 0 below A**).
- **Test change (non-AC):** fixed the ITEST-1 scaffold guard
  `pendingSkipReason skips a pending AC by default, runs it when forced` to drive both modes through the
  explicit `forceRunPending` override instead of the ambient `runPending`. **Reason:** the run-pending
  baseline sets `BS09_RUN_PENDING=true`, under which the ambient-mode form's `expect(…, isNotNull)` flipped to
  null and failed — a mode-dependent (non-deterministic) guard. This is the same fix bs-08 ITEST-2 applied; it
  strengthens the guard (both modes now asserted) and does not touch any AC test.
- **Fix passes:** 1/3 — the first full run surfaced the mode-dependent ITEST-1 guard above under run-pending;
  fixed it and re-ran to a clean baseline (default green, only AC-1..5 red). The AC tests' red baseline is the
  designed outcome, not a fix.
- **Tokens / time:** 8,028,691 · 18m 58s (21m 23s).

### Checkpoint / Handoff (ITEST-2 → ITEST-3)

- **Shared file — ITEST-3 appends, does not rewrite.** The AC tests live in the single
  `advanced_capture_test.dart`; ITEST-3 adds a **second** `group` for AC-6..10 (`TestAC06_…`..`TestAC10_…`)
  after the ITEST-2 group — re-read the file first and append. ITEST-2 and ITEST-3 cannot run in parallel
  (one file); ITEST-3 depends on ITEST-2 being committed.
- **Imports/helpers available:** `advanced_capture_harness.dart` (sole harness import) plus `capture_screen.dart`
  (for `find.byType(CaptureScreen)`) and `package:flutter/widgets.dart` (for `tester.widget<Text>(…)`), already
  imported at the top of the file. AC-6..10 observe the committed sample's `colorSpace`/`captureMode` and the
  source capability getters (`supportsWideGamut`/`supportsRaw`) on the `SCENE_WIDE`/`SCENE_NARROW`/`SCENE_RAW`/
  `SCENE_ANDROID`/`SCENE_IOS` fixtures; use `h.source.<getter>` for the Given preconditions and `h.whenCommit`
  then `h.state.lastCommittedSample` for the Thens (commit needs only a non-null `currentSample`, set at boot —
  no lock required).
- **Red-baseline expectation for ITEST-3:** AC-6/7/8 commit on capability scenes; the shell's
  `SoftwareCaptureSource` returns `srgb`/`processed` defaults today (SOURCE-2/3), so AC-6/AC-7 fail on their
  `colorSpace == displayP3` / `captureMode == raw` Thens (not a throw), while AC-8 (`srgb` fallback) may be
  **green at baseline** — strengthen or add a control and, if still green, un-pend + record *green at baseline*.
  AC-9/AC-10 need SOURCE-4's normalization and are pending until then.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host); acceptance under the device lock — `flutter test integration_test/advanced_capture_test.dart
  -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default) and `--dart-define=BS09_RUN_PENDING=true` (red baseline),
  run through `coord.sh with-lock bs-09-advanced-capture ITEST-3 --wait <n> -- …` (coord repo
  `/Users/matthew.quirk/Nuance`). Always pass `-d <udid>` — no device ⇒ zero tests, false green.

## Phase ITEST-3 — AC tests: colour-space / RAW / normalization (AC-6,7,8,9,10)

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Tasks:** one *pending* `acTestWidgets` per AC (`TestAC06_…`..`TestAC10_…`) per the catalogue; red
  baseline; grade.
- **Exit criteria:** suite green with these pending; red baseline recorded; grade gate passed.

### Result (ITEST-3)

- **Landed:** five *pending* `acTestWidgets` appended as a **second** group
  (`bs-09 acceptance — colour-space / RAW / normalization (ITEST-3)`) after the ITEST-2 group in
  `advanced_capture_test.dart` (ITEST-2 group untouched) — `AC-6: TaggedWithColourSpace`,
  `AC-7: RawWhereSupported`, `AC-8: FallbackLabelsNarrower`, `AC-9: NormalizedTaggedSample`,
  `AC-10: PlatformAgnosticSample` — all through the real assembled app: `givenCaptureOf` on the
  capability/platform scenes, `h.source.supportsWideGamut`/`supportsRaw` for the Givens, `h.whenCommit`
  (real capture UI) for the When, and `h.state.lastCommittedSample.colorSpace`/`.captureMode`/`.coordinates`
  for the Thens. AC-6 carries a `SCENE_NARROW→srgb` in-test control; AC-7 a non-RAW→`processed` control;
  AC-8 a `SCENE_WIDE→displayP3` control (the control that makes AC-8 red at baseline, since its
  `SCENE_NARROW→srgb` primary passes against the hard-coded shell); AC-9/AC-10 assert canonical-CIELAB
  normalization against `h.source.groundTruth` / across the two platforms.
- **Test-infra changes (non-AC), recorded per the suite rule:**
  1. `fakes/fake_capture_source.dart` — the fake now applies the live scene's `SceneSpec.rawColorShift`
     to every generated frame (`_shiftRaw`). **Reason:** `SCENE_ANDROID`/`SCENE_IOS` carry a non-zero
     platform offset (10 / −8) that nothing consumed, so AC-9/AC-10 would have been **vacuously green** at
     baseline (both platforms read ground truth). Modelling the platform's *pre-normalization* raw is
     fixture infrastructure — it is **not** faking the behaviour under test (the normalization that cancels
     the offset, owned by SOURCE-4); the offset is a property of the modelled platform. Zero for every
     bs-02..bs-08 scene, so those suites are unaffected.
  2. `advanced_capture_test.dart` — a top-level `rebootCaptureOf(tester, scene)` helper used by the
     AC-6/7/8/10 controls. **Reason:** an adequate-light commit navigates to the Readout (D-5), so a plain
     second `pumpWidget(buildApp(…))` reuses the first app's `MaterialApp`/`Navigator` element in place with
     the Readout still pushed (no Capture controls on the second scene). The helper unmounts the first app
     (disposing its feed/timers) before re-opening Capture fresh, so each primary/control pair runs the real
     app end to end. No AC assertion changed.
- **Gates:** `flutter analyze` clean; unit `flutter test --coverage` → **892 pass** (unchanged — no `lib/`
  touched); coverage gate `dart run tool/coverage_gate.dart main` → **100%** on the 10 touched lib files
  (ITEST-3 touched no `lib/`; the cumulative set vs `main` is unchanged). Acceptance (device lock, iPhone 17
  sim `5AB9D06D-…`): **default run green** — `+11 ~10` (11 non-AC tests pass, all 10 ACs skipped), exit 0;
  **run-pending red baseline** — `+11 -10`, all 10 ACs fail. AC-1..5 unchanged (`UnimplementedError` naming
  their phase); AC-6..10 each fail on a **Then** (no throws, no compile errors): AC-6 `displayP3` vs `srgb`,
  AC-7 `raw` vs `processed`, AC-8 its `SCENE_WIDE` control `displayP3` vs `srgb`, AC-9 `labDistance 4.07 > 3.0`,
  AC-10 `labDistance 7.42 > 0.5`. See the Red baseline table.
- **Grade gate:** independent adversarial grade in a fresh subagent against G1–G6 →
  appended to `behavior-test-completeness-bs-09-advanced-capture.md`. **ITEST-3: 5 A / 0 below A**; whole
  suite now **24 A / 0 below A** (ITEST-1 14 + ITEST-2 5 + ITEST-3 5). No augmentation rows: AC-8 is sound
  now via its own-AC control (not *limited* — the control works as soon as AC-8's own owner SOURCE-2 lands);
  AC-9/AC-10 discriminate now via the fixture raw offset. No blocking findings for the test review.
- **Fix passes:** 1/3 — the first run-pending baseline surfaced AC-8/AC-10 failing on a `whenCommit` tap
  (button missing on the second boot, the Navigator-reuse issue above) instead of on their colour Then; added
  `rebootCaptureOf` and re-ran to the designed baseline (AC-8 fails on its wide control, AC-10 on the platform
  divergence). The AC tests' red baseline is the designed outcome, not a fix.
- **Tokens / time:** 8,511,371 · 23m 24s (23m 24s).

### Checkpoint / Handoff (ITEST-3 → ITEST-4)

- **Acceptance stage test-complete.** All 10 AC tests exist, pending, in the single
  `advanced_capture_test.dart` (ITEST-2 group AC-1..5, ITEST-3 group AC-6..10); default suite green with all
  10 skipped; run-pending red baseline is all 10 red, each on a Then or an `UnimplementedError` naming its
  owning phase; whole-suite grade **24 A / 0 below A**. **Next is ITEST-4 (test-review) — NO code**: assemble
  the review packet (per-AC catalogue + red baseline + grade grid + fixtures), confirm full regression green
  with the 10 pending, set **G-2** awaiting decision, and stop. A human approves G-2 before ANY behaviour
  phase (CAPTURE-3/4/5, SCREEN-2/3, SOURCE-2/3/4).
- **For the behaviour phases that un-pend AC-6..10:** SOURCE-2 (AC-6, AC-8) makes the source select the wide
  space / narrower fallback and thread it onto `Sample.colorSpace`; SOURCE-3 (AC-7) sets `captureMode == raw`
  and the widest space on RAW devices; SOURCE-4 (AC-9, AC-10) makes the capture contract return a **normalized**
  sample (canonical CIELAB regardless of the platform raw offset the fake now feeds) — note the AC-9/AC-10
  tests do **not** call `whenCalibrate`, so SOURCE-4 must normalize as part of the contract, not via an
  explicit calibrate step. The fake's `normaliseAgainstCard` already returns ground truth, so routing the
  platform capture through normalization lands both platforms on canonical.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host); acceptance under the device lock — `flutter test integration_test/advanced_capture_test.dart
  -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default) and `--dart-define=BS09_RUN_PENDING=true` (red baseline),
  run through `coord.sh with-lock bs-09-advanced-capture <PHASE> --wait <n> -- bash -c "cd
  /Users/matthew.quirk/Nuance-bs09; …"` (coord repo `/Users/matthew.quirk/Nuance`; the lock wrapper runs from
  the coord repo, so `cd` into the worktree inside the command). Always pass `-d <udid>` — no device ⇒ zero
  tests, false green.

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (per-AC catalogue + red baseline + grade grid + fixtures); full
  regression green with the 10 pending; raise **G-2** for a human decision.
- **Exit criteria:** packet complete; G-2 recorded by a human (the agent never approves).
- **Status:** ⏸ Awaiting review (packet below; **G-2** *awaiting decision*). No code ran in this phase.

### Review packet — ITEST-4 (2026-10-12)

**What this is.** Ten pending acceptance tests (one per AC) over the fully wired bs-09 shells — advanced
capture: torch, multi-point sampling, the two-reading comparison handoff, colour-space tagging, RAW capture,
and platform-agnostic normalization — to be approved before any behaviour is coded. The suite is
test-complete and grades **all A (24 A / 0 below A)** with **no augmentations**. **Approving G-2 opens all ten
behaviour phases** (CAPTURE-3/4/5, SCREEN-2/3, SOURCE-2/3/4).

**Read first (the three judgment calls a reviewer should confirm):**
1. **The platform raw offset is fixture infrastructure, not faked behaviour.** `FakeCaptureSource` now
   applies each scene's `SceneSpec.rawColorShift` to every generated frame (`_shiftRaw`). `SCENE_ANDROID`
   (+10) and `SCENE_IOS` (−8) carry *different* non-zero offsets; every bs-02..bs-08 scene is 0, so those
   suites are untouched. This models each platform's **pre-normalization raw** — a property of the modelled
   device — and is **not** faking the normalization under test (which SOURCE-4 owns). Without it, AC-9/AC-10
   would read ground truth on both platforms and be **vacuously green** at baseline. Confirm this models the
   platform, not the behaviour being graded.
2. **SOURCE-4 must normalize as part of the capture *contract*, not via a calibrate step.** The AC-9/AC-10
   tests deliberately **do not** call `whenCalibrate` — they commit through the real capture UI and expect
   the committed sample already normalized to canonical CIELAB. So routing the platform capture through
   normalization is the contract SOURCE-4 must satisfy (the fake's `normaliseAgainstCard` already returns
   ground truth, so wiring the commit path through it lands both platforms on canonical). Confirm this
   contract — not an explicit calibrate call — is the intended design before SOURCE-4 is coded.
3. **AC-8's in-test control is what makes it sound and red at baseline.** AC-8's `SCENE_NARROW→srgb` primary
   is **green against the hard-coded shell** (srgb is today's default), so on its own it would be *limited*.
   Its in-test **control** — a rebooted `SCENE_WIDE` device that must tag `displayP3` — is the discriminator
   that makes `srgb` a genuine *capability-conditional* fallback and drives AC-8 red at baseline. Confirm (a)
   the control legitimately belongs to AC-8 (it tests AC-8's own fallback claim, not AC-6's tagging leaking
   in — G6), and (b) it closes as soon as AC-8's own owner **SOURCE-2** lands (so AC-8 is **not** limited and
   needs no augmentation).

**Per-AC catalogue** (Given checked via the public surface → When through a real shipped control → Then +
what it Rejects; all through the one production `buildApp` via `advanced_capture_harness.dart`):

| AC | Test (`advanced_capture_test.dart`) | Given (checked) | When (real control) | Then + Rejects | Baseline | Grade |
|---|---|---|---|---|---|---|
| AC-1 | `AC-1: TorchWarnsColourTemp` | `CaptureScreen` shown, `lighting==low` (source), `torchOn==false`, `torchWarningKey` absent (rejects warning-before-torch) | `whenTurnTorchOn` (real `torchKey` tap) | `torchOn==true` **and** banner present **and** its text (off `torchWarningKey`) names `temperature` + bias/skew/shift. **Rejects** silent toggle (no banner), banner omitting the colour-temp bias | FAIL → `UnimplementedError('CAPTURE-3')` | A |
| AC-2 | `AC-2: ReadingLabelledTorchLit` | torch-off **control** commit first asserts `lastCommittedSample.litByTorch==false` | `whenTurnTorchOn` + `whenAcknowledgeTorchWarning` (torch stays lit, banner dismissed) + `whenCommit` | `litByTorch==true` at the exact bool grain. **Rejects** stamp-all-samples and never-stamp | FAIL → `UnimplementedError('CAPTURE-3')` | A |
| AC-3 | `AC-3: MultiPointSamplesAllAtOnce` | `whenMarkPoints` → `markedPoints` length 3 (state) | `whenSamplePoints` (real `samplePointsKey`) | `markedReadings` length **exactly 3** and the set of reading positions equals the three marked points. **Rejects** centre-only and one-averaged-reading (either collapses the count) | FAIL → `UnimplementedError('CAPTURE-4')` | A |
| AC-4 | `AC-4: EachPointKeepsPositionValue` | three readings exist | readings render | a `position→coordinates` map whose keys equal the three points, each value CIE76 `<3.0` of **that point's own** colour, each row labelled `Point (x, y)` under the real `CaptureReadingsList`. **Rejects** collapsed positions, "all one colour", "value is the frame centre" | FAIL → `UnimplementedError('CAPTURE-4')` | A |
| AC-5 | `AC-5: TwoPointsToComparison` | three readings; P1 and P3 resolved by position | `whenSendPairToComparison` (real `sendPairToComparison`) | via the live `ComparisonReadEndpoint`: **both** slots filled, `slotA`≈P1, `slotB`≈P3 (Δ<3), slots `>3` apart. **Rejects** one-slot-filled, a swap/duplicate, wrong two carried | FAIL → `UnimplementedError('CAPTURE-4')` | A |
| AC-6 | `AC-6: TaggedWithColourSpace` | `supportsWideGamut==true` (real getter) on `SCENE_WIDE` | `whenCommit` (real `captureKey`) | `colorSpace == displayP3` (exact enum). **Control (G5):** rebooted narrow device commits `srgb`. **Rejects** null/untagged and constant-`displayP3` | FAIL → `colorSpace==srgb`, expected `displayP3` | A |
| AC-7 | `AC-7: RawWhereSupported` | `supportsRaw==true` (real getter) on `SCENE_RAW` | `whenCommit` | `captureMode == raw` **and** `colorSpace == displayP3` (RAW uses the widest space). **Control (G5):** rebooted non-RAW device commits `processed`. **Rejects** "RAW set but space still narrow" | FAIL → `captureMode==processed`, expected `raw` | A |
| AC-8 | `AC-8: FallbackLabelsNarrower` | `supportsWideGamut==false` (real getter) on `SCENE_NARROW` | `whenCommit` | primary `colorSpace==srgb` (green-at-baseline alone) made sound by the **control (G5):** rebooted wide device **must** tag `displayP3`, proving `srgb` is a *capability-conditional* fallback. **Rejects** unlabelled-null fallback, constant-srgb | FAIL → control `SCENE_WIDE` `colorSpace==srgb`, expected `displayP3` | A |
| AC-9 | `AC-9: NormalizedTaggedSample` | `CaptureScreen` shown, `SCENE_ANDROID.rawColorShift != 0` (so "normalized" is a real check) | `whenCommit` | `colorSpace != null` **and** `labDistance(coordinates, groundTruth) < 3.0` on the raw committed coords. **Rejects** raw-passed-through (baseline 4.07), untagged | FAIL → `labDistance==4.07 > 3.0` | A |
| AC-10 | `AC-10: PlatformAgnosticSample` | `SCENE_ANDROID.rawColorShift != SCENE_IOS.rawColorShift` enforced in-test (agreement is a real result) | `whenCommit` on Android, then rebooted iOS | `labDistance(android, ios) < 0.5` (tight) **and** identical `colorSpace` tags. **Rejects** divergent platforms (baseline 7.42) | FAIL → `labDistance==7.42 > 0.5` | A |

**Red baseline summary** (run-pending `--dart-define=BS09_RUN_PENDING=true`, iPhone 17 sim `5AB9D06D…`,
recorded at ITEST-2/3, HEAD unchanged since): default run **11 pass / 10 skipped — all passed**; run-pending
**11 pass / 10 fail — every AC red**. AC-1..5 fail with an `UnimplementedError` naming their blocking
behaviour (CAPTURE-3 / CAPTURE-4); AC-6..10 each fail on their own **Then** (no throws, no compile errors) —
AC-6 `displayP3` vs `srgb`, AC-7 `raw` vs `processed`, AC-8 its `SCENE_WIDE` control, AC-9 `4.07>3.0`, AC-10
`7.42>0.5`. **None is green at baseline** — each one discriminates the wrong impl today. Full per-test rows in
the **Red baseline** table below.

**Augmentations scheduled:** **none.** Every AC test carries its discriminating control in-fixture or in-test
(AC-2 torch-off control, AC-6/7/8 rebooted-capability controls, AC-9/10 the enforced differing platform raw),
so no AC is *limited* by a missing precondition that a later phase must backfill. The *Test augmentations*
table below is empty by design.

One optional, **non-blocking** grader note (not a rule failure, stays A): AC-5 assumes `sendPairToComparison`
maps marked-reading indices 0 and 2 to the P1/P3 readings, while AC-3 pins only the *set* of positions, not
their order. The Then still rejects a swap (it matches `slotA` against the P1 reading looked up by position,
not by index), so it does not over-accept; the coupling is a reasonable ordering expectation of the
forthcoming CAPTURE-4/CAPTURE-5 contract. Not required for the grade.

**Fixtures & real-vs-faked.** The whole app is assembled through the one production `buildApp(deps)` on the
Capture route, driven through the real UI with `WidgetTester` (reusing bs-02's `CaptureHarness`/
`givenCaptureOf`). **Real:** sampling (`sampleAreaAverage`), the capture controller, the Capture screen,
routing, bs-03's comparison. **Faked infrastructure only:** the extended `FakeCaptureSource` (adds the
capability getters and the `_shiftRaw` platform offset) and bs-01's `FakeHaptics`/`FakeSpeech`. Fixtures:
`SCENE_DIM_TORCH` (low light + biasing torch, guard-proven `torchColorShift>0`), `SCENE_THREE_POINTS` (three
mutually-distinct, off-field points with per-point colours), `SCENE_WIDE`/`SCENE_NARROW` (wide-gamut
capability pair), `SCENE_RAW` (RAW capability), `SCENE_ANDROID`/`SCENE_IOS` (shared ground truth, differing
non-zero raw). Every bias/offset/capability an AC leans on is pinned by an ITEST-1 fixture guard.

**Regression confirmed (ITEST-4, 2026-10-12):** `flutter analyze` clean; unit `flutter test --coverage`
**892 pass**; coverage gate `dart run tool/coverage_gate.dart main` **100%** on the 10 touched lib files;
default acceptance run (device lock, sim `5AB9D06D…`) **+11 ~10 — all passed, exit 0** (11 non-AC tests green,
all 10 ACs skipped). No code changed this phase.

**Grade grid:** [`behavior-test-completeness-bs-09-advanced-capture.md`](../behavior-test-completeness-bs-09-advanced-capture.md)
— graded by a fresh adversarial subagent that did not write the tests. **Counts: 24 A / 0 below A** (14
ITEST-1 artifacts + 5 ITEST-2 (AC-1..5) + 5 ITEST-3 (AC-6..10)).

**Decision.** A human approves or requests changes:
`/feature-next-phase --gate bs-09-advanced-capture G-2 approved | "<changes>"`.
On **approved**, G-2 resolves, ITEST-4 is done, and the behaviour phases open — the CAPTURE/SCREEN track
(torch → multi-point → comparison handoff) and the SOURCE track (colour-space / RAW / normalization) run
concurrently (disjoint files). On **changes requested**, each item becomes an ITEST change phase before
behaviour, followed by a fresh review.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_TorchWarnsColourTemp | `UnimplementedError('CAPTURE-3')` | When — `whenTurnTorchOn` (torch tap); the banner/torchOn Then is unreachable until the torch mechanism (CAPTURE-3) then the banner (SCREEN-2) land | SCREEN-2 | A |
| AC-2 | TestAC02_ReadingLabelledTorchLit | `UnimplementedError('CAPTURE-3')` | When — `whenTurnTorchOn`, **after** the torch-off control commit asserted `litByTorch == false` | CAPTURE-3 | A |
| AC-3 | TestAC03_MultiPointSamplesAllAtOnce | `UnimplementedError('CAPTURE-4')` | Given — `whenMarkPoints` (`markPoint`) | CAPTURE-4 | A |
| AC-4 | TestAC04_EachPointKeepsPositionValue | `UnimplementedError('CAPTURE-4')` | Given — `whenMarkPoints` (`markPoint`); the show-each-reading Then is owned by SCREEN-3 (after CAPTURE-4) | SCREEN-3 | A |
| AC-5 | TestAC05_TwoPointsToComparison | `UnimplementedError('CAPTURE-4')` | Given — `whenMarkPoints` (`markPoint`); the pair handoff Then is owned by CAPTURE-5 (after CAPTURE-4) | CAPTURE-5 | A |
| AC-6 | TestAC06_TaggedWithColourSpace | Then fails: `colorSpace == srgb`, expected `displayP3` | Then — the committed sample's `colorSpace` on `SCENE_WIDE` (shell returns `srgb` until SOURCE-2) | SOURCE-2 | A |
| AC-7 | TestAC07_RawWhereSupported | Then fails: `captureMode == processed`, expected `raw` | Then — the committed `captureMode` on `SCENE_RAW` (shell returns `processed` until SOURCE-3) | SOURCE-3 | A |
| AC-8 | TestAC08_FallbackLabelsNarrower | Then fails on the `SCENE_WIDE` **control**: `colorSpace == srgb`, expected `displayP3` (the `SCENE_NARROW` primary already passes — srgb is hard-coded) | Then — control: `SCENE_WIDE` tagged `srgb` until SOURCE-2 labels the wide space, so `srgb` is not yet a capability-conditional fallback | SOURCE-2 | A |
| AC-9 | TestAC09_NormalizedTaggedSample | Then fails: `labDistance(coords, groundTruth) == 4.07 > 3.0` (coords are the raw platform-shifted value) | Then — committed `coordinates` on `SCENE_ANDROID` not normalized until SOURCE-4 (tag is already non-null) | SOURCE-4 | A |
| AC-10 | TestAC10_PlatformAgnosticSample | Then fails: `labDistance(android, ios) == 7.42 > 0.5` (platforms diverge) | Then — `SCENE_ANDROID` vs `SCENE_IOS` committed coords differ until SOURCE-4 normalizes both to canonical | SOURCE-4 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| — | none pre-seeded (each AC test carries its discriminating control in-fixture) | — | — | — |
