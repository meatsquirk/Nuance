# Module CAPTURE — controller: torch, multi-point, send-to-comparison, colour-space stamp

**Status:** In progress — CAPTURE-1/2/3/4 done (AC-2, AC-3 un-pended); next CAPTURE-5 (AC-5), unblocked by CAPTURE-4 (same controller file — serial)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_controller.dart`, `lib/capture/capture_state.dart`,
`lib/capture/capture_read_endpoint.dart`, `lib/domain/sample.dart` (new fields),
`lib/app/router.dart` (pair handoff); the scaffold (CAPTURE-1) owns no product code
**Depends on:** SOURCE-1 (new source getters), bs-02 controller, bs-03 comparison (both on `main`) ·
**Blocks:** SCREEN-1/2/3, ITEST-*, SOURCE-2/4 (threading)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CAPTURE-1 | scaffold | — | ✅ Done | 7,102,221 | 15m 16s (6h 58m) |
| CAPTURE-2 | shell | — | ✅ Done | 8,882,434 | 17m 46s |
| CAPTURE-3 | behavior | AC-2 | ✅ Done | 10,436,918 | 15m 55s |
| CAPTURE-4 | behavior | AC-3 | ✅ Done | 9,233,826 | 23m 46s |
| CAPTURE-5 | behavior | AC-5 | ⬜ Todo | | |

## Interface reconciliation

- **`Sample` (new, nullable, default off — no break to bs-01..bs-06 callers):** `CaptureColorSpace?
  colorSpace`, `bool litByTorch` (default false), `CaptureMode? captureMode`. Added to `copyWith`/`==`.
- **`CaptureState` (new fields):** `bool torchOn`, `String? torchWarning`, `List<MarkedPoint> markedPoints`,
  `List<MultiPointReading> markedReadings` (each keeps its frame position + `ColorCoordinates`). Derived text
  as needed for the screen.
- **Controller commands (stubs in CAPTURE-2, behaviour later):** `turnTorchOn()`/`turnTorchOff()`,
  `acknowledgeTorchWarning()`, `markPoint(x,y)`, `clearMarkedPoints()`, `sampleMarkedPoints()`,
  `sendPairToComparison(i, j)`.
- **Commit threading (CAPTURE-2):** `commit()` copies `source.colorSpace` → `Sample.colorSpace`,
  `source.captureMode` → `Sample.captureMode`, and `state.torchOn` → `Sample.litByTorch`. Until SOURCE-2/3
  give the source meaningful values these default to `srgb`/`processed`, so the plumbing lands first and the
  SOURCE behavior phases make the tags meaningful.
- **Router pair handoff (D-5):** add `toComparisonPair(Sample a, Sample b)` opening `ComparisonHomeScreen`
  with `initialA: a, initialB: b` (bs-03's `ComparisonController` already takes both). `toComparison(sample,
  slot)` is unchanged.
- **Read endpoint:** `CaptureReadEndpoint` already exposes the controller; the new state getters ride on it.

## Open gates

G-2 (test review) blocks CAPTURE-3/4/5 as behavior phases. CAPTURE-1/CAPTURE-2 are scaffold/shell (not gated
by G-2). **G-1 (spec approval) ✅ Resolved 2026-10-12: approved — Matt Quirk**, so CAPTURE-1 is unblocked.

## Phase CAPTURE-1 — scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** SOURCE-1
- **Files:** branch only; `integration_test/bs09/pending.dart`
- **Tasks:**
  1. Branch `feat/bs-09-advanced-capture` from `main` (@ 4d4aedd).
  2. Baseline run: full unit suite + existing integration suites; record counts.
  3. Prove `tool/coverage_gate.dart` passes on a clean tree and fails on a planted uncovered line.
  4. Add `integration_test/bs09/pending.dart` modelled on `bs02/pending.dart`: `pendingACs` seeded with the
     10 ACs, `acTestWidgets`, `runPending` via `BS09_RUN_PENDING`, `behaviorPhases` set.
- **Exit criteria:** gate proven both ways; baseline recorded; no product code.

### Result — CAPTURE-1  <!-- 2026-10-12 -->

- Branched `feat/bs-09-advanced-capture` from `main` @ `a695e4c` in worktree `/Users/matthew.quirk/Nuance-bs09`.
  (Plan said "@ 4d4aedd"; main has since advanced only with planning-only commits `c0486f0` (bs-09 PLAN) and
  `a695e4c` (bs-08 PLAN) — no code change; branching from current main is required so the bs-09 plan/spec,
  absent at 4d4aedd, are present.)
- **G-1 approved** 2026-10-12 by Matt Quirk — spec first line stamped; master + this module's Open gates
  resolved.
- **Baseline (green):** unit + coverage `flutter test --coverage` → **849 passed**, `coverage/lcov.info`
  produced. Existing integration suites `flutter test integration_test/ -d <iPhone 17 udid>` (default mode,
  pending skipped) → **131 passed** (bs-02..bs-06 + harness), exit 0, under the verify lock. `flutter analyze`
  → no issues.
- **Coverage gate proven both ways:** clean tree (no touched `lib/`) → PASS (exit 0); planted
  `lib/_gate_probe.dart` + under-covering test → FAIL (`lib/_gate_probe.dart: 2/3 lines covered — uncovered
  lines: 7`, exit 1); probe removed → PASS. Probe files deleted; no product code remains.
- **Pending gate added:** `integration_test/bs09/pending.dart` (modelled on `bs06/pending.dart`) — all 10 ACs
  seeded pending → owning behaviour phases (AC-1→SCREEN-2, AC-2→CAPTURE-3, AC-3→CAPTURE-4, AC-4→SCREEN-3,
  AC-5→CAPTURE-5, AC-6/AC-8→SOURCE-2, AC-7→SOURCE-3, AC-9/AC-10→SOURCE-4); `behaviorPhases`, `acTestWidgets`,
  `runPending` via `BS09_RUN_PENDING`. Compiles clean (analyze).
- Coverage (touched `lib/`): none — scaffold owns no product code → gate PASS. Acceptance: n/a (no AC tests
  yet; ITEST-1 builds the harness, ITEST-2/3 register the per-AC tests).
- Fix passes: 0/3 (all gates green on first run).
- Closed by: gate proven both ways; baseline recorded green; no product code.

### Checkpoint / Handoff — CAPTURE-1

- **Frozen for SOURCE-1:** `integration_test/bs09/pending.dart` is the un-pend registry — a behaviour phase
  un-pends its AC by deleting that AC's row here. Don't add product code in the scaffold's wake; SOURCE-1 is
  the first shell (signatures only).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run
  tool/coverage_gate.dart main` (host, no sim). Acceptance (needs a booted sim, always pass `-d <udid>` —
  no device ⇒ zero tests, false green): `flutter test integration_test/advanced_capture_test.dart -d <udid>`
  once ITEST-1 creates it; run-pending adds `--dart-define=BS09_RUN_PENDING=true`. Flutter SDK:
  `/Users/matthew.quirk/development/flutter/bin`. Run sim commands under `coord.sh with-lock
  bs-09-advanced-capture <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs09 && …'`
  (`with-lock` runs from the coord repo `/Users/matthew.quirk/Nuance`). `timeout` is absent on this macOS —
  for the push step use a plain `git push` (no `timeout` wrapper) or `gtimeout` if present.
- **Known gaps:** no product code, no bs-09 harness yet (ITEST-1), no `CaptureSource` extensions yet
  (SOURCE-1), no `Sample` fields yet (CAPTURE-2).

## Phase CAPTURE-2 — shell: Sample fields, command stubs, read-endpoint + router signatures

- **Kind:** shell
- **Target AC:** —
- **Depends on:** SOURCE-1 · **Blocks:** SCREEN-1, ITEST-1
- **Files:** `sample.dart`, `capture_state.dart`, `capture_controller.dart`, `capture_read_endpoint.dart`,
  `router.dart`
- **Tasks:**
  1. Add the `Sample` fields and the `CaptureState` fields + supporting types (`MarkedPoint`,
     `MultiPointReading`).
  2. Add the controller command stubs (no behaviour) and thread commit→Sample tagging (D-2/D-3 plumbing,
     default values until SOURCE/CAPTURE behavior phases).
  3. Add `AppRouter.toComparisonPair(a, b)`.
- **Exit criteria:** 100% coverage on touched files; `flutter analyze` clean; existing suites green
  (behaviour unchanged — torch off, no marked points, `srgb`/`processed`, `litByTorch` false).

## Phase CAPTURE-3 — behavior: torch mechanism + litByTorch stamp (AC-2)

- **Kind:** behavior
- **Target AC:** AC-2 (full). Also delivers the torch mechanism (turn on/off, colour-temperature warning
  string, acknowledge) that makes AC-1's Given real (consumed by SCREEN-2).
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SCREEN-2, CAPTURE-4
- **Files:** `capture_controller.dart`, `capture_state.dart`
- **Tasks:**
  1. `turnTorchOn()` calls `source.turnTorchOn()`, sets `torchOn`, and sets `torchWarning` (text naming the
     torch **colour temperature** biasing the reading). `turnTorchOff()` clears both.
  2. `acknowledgeTorchWarning()` clears `torchWarning` but leaves `torchOn` true.
  3. `commit()` stamps `Sample.litByTorch = state.torchOn`.
- **Exit criteria:** unit + 100% coverage on touched files; `flutter analyze` clean.
- **Acceptance gate:** un-pend AC-2; `TestAC02_ReadingLabelledTorchLit` green (and all earlier un-pended ACs).

## Phase CAPTURE-4 — behavior: multi-point sampling (AC-3)

- **Kind:** behavior
- **Target AC:** AC-3 (full)
- **Depends on:** CAPTURE-3 (same controller file — serial), ITEST-4 (G-2) · **Blocks:** SCREEN-3, CAPTURE-5
- **Files:** `capture_controller.dart`, `capture_state.dart`
- **Tasks:**
  1. `markPoint(x,y)` appends to `markedPoints`; `clearMarkedPoints()` empties it.
  2. `sampleMarkedPoints()` samples the current frame at each marked point via `sampleAreaAverage`, producing
     one `MultiPointReading{position, coordinates}` per point into `markedReadings`.
- **Exit criteria:** unit + 100% coverage on touched files; `flutter analyze` clean.
- **Acceptance gate:** un-pend AC-3; `TestAC03_MultiPointSamplesAllAtOnce` green (and all earlier un-pended
  ACs).

## Phase CAPTURE-5 — behavior: send two readings to a comparison (AC-5)

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** CAPTURE-4 (marked readings), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `capture_controller.dart`, `router.dart`
- **Tasks:**
  1. `sendPairToComparison(i, j)` builds a `Sample` from `markedReadings[i]` and `[j]` and pushes
     `router.toComparisonPair(a, b)` so the comparison opens with both slots filled.
- **Exit criteria:** unit + 100% coverage on touched files; `flutter analyze` clean.
- **Acceptance gate:** un-pend AC-5; `TestAC05_TwoPointsToComparison` green (and all earlier un-pended ACs).

### Result — CAPTURE-2  <!-- 2026-10-12 -->

- **Shell signatures + commit plumbing only — behaviour unchanged.** Added `Sample.colorSpace`
  (`CaptureColorSpace?`), `Sample.litByTorch` (`bool`, default false), `Sample.captureMode` (`CaptureMode?`) —
  all nullable/off, wired into `copyWith` and `toString` (`sample.dart`).
- **`CaptureState` fields** (`capture_state.dart`): `torchOn` (false), `torchWarning` (`String?`), `markedPoints`
  (`List<MarkedPoint>`, const []), `markedReadings` (`List<MultiPointReading>`, const []), wired into
  `copyWith`/`==`/`hashCode` (lists via `listEquals`/`Object.hashAll`). Added supporting value types
  `MarkedPoint{x,y}` and `MultiPointReading{position, coordinates}` (both with `==`/`hashCode`/`toString`).
- **Controller command stubs** (`capture_controller.dart`): `turnTorchOn/Off`, `acknowledgeTorchWarning`
  (CAPTURE-3), `markPoint(x,y)`, `clearMarkedPoints`, `sampleMarkedPoints` (CAPTURE-4), `sendPairToComparison(i,j)`
  (CAPTURE-5) — each `throw UnimplementedError('<phase>')`, matching the file's stated deferral convention.
- **Commit threading (D-2/D-3 plumbing):** `commit()` now stamps `Sample.colorSpace = source.colorSpace`,
  `captureMode = source.captureMode`, `litByTorch = state.torchOn`. With SOURCE-1's shell defaults these are
  `srgb`/`processed`/`false`, so bs-02 commit behaviour is unchanged until SOURCE-2/3 + CAPTURE-3 give them meaning.
- **Router:** added `AppRouter.toComparisonPair(a, b)` → `ComparisonHomeScreen(initialA: a, initialB: b)` (D-5);
  `toComparison`/others untouched.
- **Deviations (both deliberate, consistent with surrounding code):** (1) the plan said `Sample` fields wired into
  `==`, but `Sample` has **no** value `==` in the existing code (identity equality, relied on by
  `CaptureState.==`/`emit` dedup) — added the fields to `copyWith`/`toString` only, not a new `==`, to avoid
  changing equality semantics. (2) `capture_read_endpoint.dart` was **not** edited: it already exposes the
  `CaptureController`, so the new `CaptureState`/`Sample` getters are observable through it unchanged (module
  Interface reconciliation says the new getters ride on it).
- **Gates:** `flutter analyze` clean. Unit `flutter test --coverage` → **877 passed** (858 baseline + 19 new).
  Coverage gate `dart run tool/coverage_gate.dart main` → **100%** on all 6 touched lib files (`sample.dart`,
  `capture_state.dart`, `capture_controller.dart`, `router.dart`, plus SOURCE-1's `capture_source.dart` /
  `software_capture_source.dart`, still 100%). Existing integration `flutter test integration_test/ -d <iPhone 17>`
  under the verify lock → **131 passed**, exit 0 (no regression). Acceptance/grades: n/a (shell — no bs-09 AC tests
  until ITEST-1).
- Fix passes: 0/3 (coverage gate flagged the two `const` constructor lines on first run — fixed by a non-const
  construction in each type's test, per the repo's existing precedent; counted as finishing the first pass, not a
  gate failure).

### Checkpoint / Handoff — CAPTURE-2

- **Frozen for SCREEN-1 / ITEST / behaviour phases:**
  - `Sample.colorSpace` / `litByTorch` / `captureMode` carry the capture tags; `commit()` stamps them.
  - `CaptureState.torchOn` / `torchWarning` / `markedPoints` / `markedReadings` are the observable torch +
    multi-point state (all default off/empty). `MarkedPoint{x,y}` and `MultiPointReading{position, coordinates}`
    are the element types.
  - Controller stubs exist with their final signatures: `turnTorchOn()`, `turnTorchOff()`,
    `acknowledgeTorchWarning()` (CAPTURE-3); `markPoint(int x, int y)`, `clearMarkedPoints()`,
    `sampleMarkedPoints()` (CAPTURE-4); `sendPairToComparison(int i, int j)` (CAPTURE-5) — all throw
    `UnimplementedError` until their phase.
  - `AppRouter.toComparisonPair(Sample a, Sample b)` opens the comparison with both slots filled.
- **GOTCHA for CAPTURE-3:** `CaptureState.copyWith` keeps the repo's set-forward-only `x ?? this.x` merge, so it
  **cannot clear `torchWarning` back to null**. `turnTorchOff()`/`acknowledgeTorchWarning()` must clear it by
  constructing a fresh `CaptureState` (CAPTURE-3 owns `capture_state.dart` and may add a clear-capable seam if it
  prefers). The torch control also needs to call `source.turnTorchOn()/Off()` (SOURCE-1 froze those).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`
  (host, no sim). Integration under the lock: `coord.sh with-lock bs-09-advanced-capture <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs09 && export PATH=…/flutter/bin:$PATH && flutter test integration_test/ -d
  5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'`. (No `timeout` on this macOS — plain `git push`.)
- **Known gaps:** every new control is an inert `UnimplementedError` stub; commit tags are the SOURCE-1 shell
  defaults (srgb/processed/torch-off) until SOURCE-2/3 + CAPTURE-3; no Capture-screen wiring yet (SCREEN-1); no
  bs-09 AC tests yet (ITEST-1). **Next shell: SCREEN-1** (Capture screen placeholders — torch control + warning,
  multi-point markers + readings list, send-to-comparison).

### Result — CAPTURE-3  <!-- 2026-10-12 -->

- **Torch mechanism implemented (AC-2 full; AC-1's Given made real).** `turnTorchOn()` lights
  `source.turnTorchOn()`, sets `CaptureState.torchOn`, and raises
  `CaptureController.torchColorTemperatureWarning` ("Torch on — its colour temperature biases the measured
  colour.") into `state.torchWarning`. `turnTorchOff()` extinguishes the source, clears `torchOn`, and drops
  the warning. `acknowledgeTorchWarning()` drops the warning while leaving `torchOn` true. `commit()` already
  stamped `litByTorch = state.torchOn` (CAPTURE-2 plumbing) — verified, no change needed.
- **Clear-capable seam:** `CaptureState.copyWith` gained `bool clearTorchWarning = false`; when true it forces
  `torchWarning` to null past the repo's set-forward `x ?? this.x` merge (the GOTCHA from CAPTURE-2's handoff).
  Existing callers are unaffected (flag defaults false → identical to before).
- **Un-pended AC-2** (deleted its row in `integration_test/bs09/pending.dart`). AC-2 now runs green.
- **Test-artifact change (recorded):** the ITEST-1 scaffold guard `pending map covers exactly AC-1..AC-10`
  would fail the moment any AC is un-pended, so it was converted to the established bs-06 complement pattern —
  an `unpended = {AC-2}` set, asserting the pending map is the exact complement across AC-1..AC-10 plus a
  length check. This strengthens (not weakens) the guard; it still rejects a stray/typo'd/missing entry and
  now also enforces that exactly the un-pended set is absent. The grows-one-per-phase set mirrors bs-06.
- **Gates:** `flutter analyze` clean. Unit `flutter test --coverage` → **896 passed** (877 baseline + 19 new:
  4 controller torch tests, 1 state clear-seam test, 2 rewritten control tests replacing the 2 stub-throw
  tests + existing). Coverage gate `dart run tool/coverage_gate.dart main` → **100%** line on all 10 touched
  lib files. Acceptance (default, on booted iPhone 17 sim under the verify lock):
  `flutter test integration_test/advanced_capture_test.dart -d 5AB9D06D…` → **All tests passed** (+12 passed /
  9 skipped — AC-2 runs green, the other 9 ACs still pending/skipped).
- **Grade gate:** fresh independent subagent re-graded the only un-pended AC test, **AC-2
  (`ReadingLabelledTorchLit`) = A** (no downgrade; the in-test torch-off control still rejects "stamp-all", the
  positive Then rejects "never-stamp"). No neighbour drift (AC-2 is the only un-pended bs-09 AC; its test file
  + harnesses unmodified). Section appended to `behavior-test-completeness-bs-09-advanced-capture.md`.
- Augmentations: none assigned to CAPTURE-3; none newly enabled (AC-2's own test already carries its G5
  control, and no already-green bs-09 AC test can assert more from the torch mechanism).
- Fix passes: 1/3 (first full run: the scaffold guard failed as designed once AC-2 was un-pended; fixed by the
  complement-pattern conversion above, then green).
- Tokens / Time: 10,436,918 · 15m 55s (active = wall, single session).
- Closed by: unit + 100% coverage; acceptance AC-2 green; grade A.

### Checkpoint / Handoff — CAPTURE-3

- **Frozen for SCREEN-2 / CAPTURE-4:**
  - `CaptureController.turnTorchOn()/turnTorchOff()/acknowledgeTorchWarning()` are live. `turnTorchOn` sets
    `state.torchWarning` to `CaptureController.torchColorTemperatureWarning` (contains "temperature" and
    "biases") — **SCREEN-2 displays this string in the `CaptureLiveView.torchWarningKey` banner** (AC-1); the
    string already satisfies AC-1's text assertions, so SCREEN-2 is wiring/rendering only.
  - `acknowledgeTorchWarning()` is the banner's dismiss action (torch stays lit). SCREEN-2 wires a dismiss
    affordance to it; the harness already drives it via the controller.
  - `CaptureState.copyWith(clearTorchWarning: true)` is the seam to null-out `torchWarning`; use it rather than
    constructing a fresh state.
  - `commit()` stamps `litByTorch` from `state.torchOn` — unchanged; CAPTURE-4 must not disturb it.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host). Acceptance under the lock (booted sim, `-d <udid>` mandatory): `coord.sh with-lock
  bs-09-advanced-capture <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs09 && export
  PATH=…/flutter/bin:$PATH && flutter test integration_test/advanced_capture_test.dart -d
  5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'`; run-pending adds `--dart-define=BS09_RUN_PENDING=true`. No `timeout`
  on this macOS. **The scaffold guard's `unpended` set (in `advanced_capture_test.dart`) must gain each AC a
  behaviour phase un-pends** — SCREEN-2 adds AC-1, CAPTURE-4 adds AC-3, etc.
- **Known gaps:** torch warning banner not yet rendered on screen (SCREEN-2 owns `CaptureLiveView` wiring);
  multi-point sampling still stubs (CAPTURE-4); colour-space/RAW/normalization tags still shell defaults
  (SOURCE-2/3/4). CAPTURE-4 (AC-3) and SCREEN-2 (AC-1) are both unblocked by this phase; SOURCE-2 is
  independently startable.

### Result — CAPTURE-4  <!-- 2026-10-12 -->

- **Multi-point sampling implemented (AC-3 full).** `markPoint(x, y)` appends a `MarkedPoint` to
  `CaptureState.markedPoints`; `clearMarkedPoints()` empties it (via `copyWith(markedPoints: const [])`, which
  the set-forward merge honours since the empty list is non-null). `sampleMarkedPoints()` area-averages the
  **most recent live frame** (`_recentFrames.last`) at each marked point at the current `radiusPx` — the same
  `sampleAreaAverage` a single reading uses — producing one `MultiPointReading{position, coordinates}` per
  point into `markedReadings`. A no-op before any frame has arrived (empty buffer). Each reading keeps its own
  position so SCREEN-3 can show each point with its value (AC-4) and CAPTURE-5 can send any two to a comparison
  (AC-5).
- **`capture_state.dart` needed no change** — CAPTURE-2 already shipped `markedPoints`/`markedReadings` +
  `copyWith`/`==`/`hashCode`; only `capture_controller.dart` carried behaviour this phase.
- **Un-pended AC-3** (deleted its row in `integration_test/bs09/pending.dart`; added `'AC-3'` to the
  `unpended` scaffold-guard set in `advanced_capture_test.dart`).
- **Cross-file rendering fix (recorded):** filling `markedReadings` for the first time surfaced a `RenderFlex`
  overflow (209 px) in `lib/widgets/color_chip.dart` — the readings-list label (position + full CIELAB value)
  is wider than the region and a bare `Text` in a `mainAxisSize.min` Row cannot wrap. Fixed by wrapping that
  `Text` in `Flexible` so it wraps instead of overflowing (ColorChip is consumed only by `CaptureReadingsList`;
  its label format/AC-4 assertions are unaffected — substring match on `Point (x, y)`). Added a long-label wrap
  test to `color_chip_test.dart`. Also flipped `capture_controls_test.dart`'s "Sample points" test from
  asserting the deferred `UnimplementedError` to asserting live behaviour (no exception), mirroring the
  CAPTURE-3 torch-control precedent in the same file.
- **Gates:** `flutter analyze` clean. Unit `flutter test --coverage` → **900 passed**. Coverage gate
  `dart run tool/coverage_gate.dart main` → **100%** on all 11 touched lib files (incl. `color_chip.dart`).
  Acceptance (default mode, booted iPhone 17 sim under the verify lock):
  `flutter test integration_test/advanced_capture_test.dart -d 5AB9D06D…` → **All tests passed** (14 passed /
  7 pending-skipped) — AC-3 green alongside AC-1/AC-2; AC-4..10 still pending.
- **Grade gate:** fresh adversarial subagent re-graded every un-pended AC test — **AC-3
  (`MultiPointSamplesAllAtOnce`) = A**, AC-1/AC-2 = A (no drift). Whole suite **24 A / 0 below A**; nothing to
  fix. AC-3's Then (length exactly 3 + position set equals the 3 distinct marked points) rejects both
  "centre-only" and "one averaged reading"; per-point value correctness is AC-4's job (G6). Drift confirmed
  none: AC-1/AC-2 are torch tests with empty readings lists, so no ColorChip mounts. Section appended to
  `behavior-test-completeness-bs-09-advanced-capture.md`.
- Augmentations: none assigned to CAPTURE-4; none newly enabled (multi-point is disjoint from the torch
  mechanism, so no already-green bs-09 AC test can assert more).
- Fix passes: 1/3 (first full run: host gates green; the acceptance run then caught the readings-list overflow,
  fixed in one pass by the `Flexible` wrap + wrap test, then green. The analyze lint on the first host run — an
  underscore-prefixed local — was a same-pass cleanup, not a gate failure.)
- Tokens / Time: 9,233,826 · 23m 46s.
- Closed by: unit + 100% coverage; acceptance AC-3 green; grade A.

### Checkpoint / Handoff — CAPTURE-4

- **Frozen for CAPTURE-5 / SCREEN-3:**
  - `CaptureController.markPoint(x, y)` / `clearMarkedPoints()` / `sampleMarkedPoints()` are live.
    `markedReadings` holds one `MultiPointReading{position, coordinates}` per marked point, indexed in
    mark order (so `sendPairToComparison(i, j)` can resolve `markedReadings[i]`/`[j]`).
  - `sampleMarkedPoints()` samples `_recentFrames.last` at `radiusPx`; it is a no-op with no buffered frame.
  - `ColorChip` now wraps long labels (`Flexible(Text)`); `CaptureReadingsList` renders one `ColorChip` per
    reading. SCREEN-3 (AC-4) owns the shown-rows rendering/labelling; the list already renders real readings.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host). Acceptance under the lock (booted sim, `-d <udid>` mandatory): `coord.sh with-lock
  bs-09-advanced-capture <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs09 && export
  PATH=…/flutter/bin:$PATH && flutter test integration_test/advanced_capture_test.dart -d
  5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'`; run-pending adds `--dart-define=BS09_RUN_PENDING=true`. No `timeout`
  on this macOS. Each un-pend still (a) deletes its `bs09/pending.dart` row and (b) adds its AC to the
  `unpended` set in `advanced_capture_test.dart`.
- **Known gaps:** readings rows not yet position-labelled on screen as AC-4 requires (SCREEN-3);
  `sendPairToComparison` still a CAPTURE-5 stub; colour-space/RAW/normalization tags still SOURCE-2/3/4 shell
  defaults. **Next in this module: CAPTURE-5** (AC-5, `sendPairToComparison` — serial on `capture_controller.dart`).
  SCREEN-3 (AC-4) is independently startable now that real readings exist.
