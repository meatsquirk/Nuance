# Module CAPTURE — controller: torch, multi-point, send-to-comparison, colour-space stamp

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_controller.dart`, `lib/capture/capture_state.dart`,
`lib/capture/capture_read_endpoint.dart`, `lib/domain/sample.dart` (new fields),
`lib/app/router.dart` (pair handoff); the scaffold (CAPTURE-1) owns no product code
**Depends on:** SOURCE-1 (new source getters), bs-02 controller, bs-03 comparison (both on `main`) ·
**Blocks:** SCREEN-1/2/3, ITEST-*, SOURCE-2/4 (threading)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CAPTURE-1 | scaffold | — | ⬜ Todo | | |
| CAPTURE-2 | shell | — | ⬜ Todo | | |
| CAPTURE-3 | behavior | AC-2 | ⬜ Todo | | |
| CAPTURE-4 | behavior | AC-3 | ⬜ Todo | | |
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
by G-2) but CAPTURE-1 is blocked by **G-1** (spec approval).

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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
