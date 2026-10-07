# Module COMPARE — comparison controller & assembly

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/compare/comparison_controller.dart`, `lib/compare/comparison_state.dart`,
`lib/compare/comparison_read_endpoint.dart`, `lib/compare/sample_source.dart` (interface + in-memory
catalogue). Replaces `lib/compare/compare_stub.dart`. Extends `lib/app/build_app.dart` (comparison entry) and
reuses `lib/app/router.dart` (`toComparison`, `toReadout`). Carries the scaffold (COMPARE-1).
**Depends on:** bs-01 domain/router/Speech/Readout, DIFF (`Comparison`), CVD (`CvdProfile`/`ConfusionCheck`) ·
**Blocks:** SCREEN, ITEST, every behaviour phase

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-1, AC-2, AC-12 | ⬜ Todo | | |
| 5 | behavior | AC-3 | ⬜ Todo | | |
| 6 | behavior | AC-10, AC-11 | ⬜ Todo | | |

(Phase numbers skip to align with the feature-wide session log: DIFF/CVD own the other behaviour phases.)

## Interface reconciliation

- **`ComparisonController`** holds slot A / slot B (`Sample?` each) and derives a `Comparison?` via DIFF's
  `compare` + CVD's `confusable` — null when either slot is empty (drives AC-12). `swap()` exchanges the slots
  and the derived statement re-expresses automatically (AC-3). `openReadout(slot)` returns via
  `AppRouter.toReadout`.
- **`SampleSource`** (D-7): `List<Sample> savedSamples()`; the in-memory catalogue is the bs-03 impl, injected
  via `AppDependencies.sampleSource`. **bs-06** later supplies a persistent store behind this same interface.
- **`ComparisonReadEndpoint`** (D-6): an `InheritedWidget` (mirroring bs-02's `CaptureReadEndpoint`) exposing
  slot A/B and the derived `Comparison?` (ΔE00, verdict, the three lines, `confusable`) to the acceptance
  suite. Kept reachable across the Readout push (AC-10/11) so a test reading state after navigation doesn't
  throw.
- **Comparison entry** (D-8): `AppDependencies.comparisonEntry` (a sample source + profile) opens the app on
  the Comparison screen owning the controller, symmetric to bs-02's `captureSource`.

## Open gates

- None of this module's own (feature gates G-1/G-3 gate the scaffold and behaviour via the master plan).

## Phase 1 — Scaffold (COMPARE-1)

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (feature gate G-1 approve-spec, G-2 bs-01 merged) · **Blocks:** DIFF-1, CVD-1
- **Files:** branch only + `integration_test/bs03/pending.dart` (the pending runner); no product code.
- **Tasks:**
  1. Cut `feat/bs-03-relative-comparison` from `main` @ c793839 (confirm bs-01 foundation present).
  2. Baseline run: record unit + integration counts and coverage on a clean tree.
  3. Confirm the coverage gate (`tool/coverage_gate.dart`) passes clean and fails on a planted gap (prove both
     ways), as bs-01/bs-02 run it.
  4. Add the BS03 pending runner mirroring `integration_test/bs02/pending.dart` (env flag `BS03_RUN_PENDING`).
- **Exit criteria:** branch cut; baseline recorded; gate proven both ways; pending runner in place; existing
  suites green.
- **Acceptance gate:** *(scaffold — tooling works, baseline recorded)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Controller / state / source / endpoint / entry shell (COMPARE-2)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** DIFF-1, CVD-1 · **Blocks:** SCREEN-1
- **Files:** `lib/compare/comparison_controller.dart`, `comparison_state.dart`, `comparison_read_endpoint.dart`,
  `sample_source.dart`; `lib/app/build_app.dart` (comparison entry); remove/replace `compare_stub.dart` behind
  `AppRouter.toComparison`.
- **Tasks:**
  1. `ComparisonState` (slots + derived `Comparison?`) and `ComparisonController` (selectA/selectB/swap/
     openReadout) wired to DIFF/CVD, all returning the shells' placeholders.
  2. `SampleSource` interface + an empty in-memory catalogue impl.
  3. `ComparisonReadEndpoint` exposing the state; comparison entry in `buildApp`; route `toComparison` to the
     real (empty) screen shell host.
  4. Keep behaviour unchanged: with no real math, the screen shows empty slots and no statement.
- **Exit criteria:** `flutter analyze` clean; unit gate 100% on new files; the app assembles and opens on the
  comparison entry; existing suites green.
- **Acceptance gate:** *(shell — none)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Sample selection + invite (COMPARE-3)

- **Kind:** behavior
- **Target AC:** AC-1, AC-2, AC-12
- **Depends on:** ITEST-4 (G-3) · **Blocks:** COMPARE-5, COMPARE-6, DIFF-2, CVD-2 (Givens)
- **Files:** `sample_source.dart` (populate the catalogue), `comparison_controller.dart` (selectA/selectB),
  `slots_region.dart` (picker E3/E5/E49 + slot-A/B render), `statement_region.dart` (the empty-B choose-B
  invite).
- **Tasks:**
  1. Populate the in-memory catalogue with the named saved samples (the fixtures' subjects).
  2. Implement selectA/selectB placing a chosen sample into its slot; render the slot name + "L n, C n, h n
     degrees" (LCh via bs-01 `labToCielch`, rounded).
  3. When slot B is empty, render no relational statement and a findable, enabled choose-sample-B invite
     (AC-12).
- **Exit criteria:** unit gate 100% on touched code; `TestAC01_ChooseA`, `TestAC02_ChooseB`,
  `TestAC12_InviteSecond` green run-pending; the smoke + earlier green stay green.
- **Acceptance gate:** un-pend AC-1, AC-2, AC-12; suite green for those tests.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 5 — Swap A / B (COMPARE-5)

- **Kind:** behavior
- **Target AC:** AC-3
- **Depends on:** DIFF-3 (a statement to re-express) · **Blocks:** SIGNOFF-1
- **Files:** `comparison_controller.dart` (`swap`), the E4 swap control in `slots_region.dart`.
- **Tasks:**
  1. `swap()` exchanges slots A and B; the derived `Comparison` recomputes so the statement re-expresses
     new-A → new-B (a direction flips, e.g. "Lighter by 12" → "Darker by 12").
  2. Wire the E4 control.
- **Exit criteria:** unit gate 100% on touched code; `TestAC03_Swap` green run-pending; earlier ACs green.
- **Acceptance gate:** un-pend AC-3; suite green for that test and all earlier ACs.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 6 — Open readout for A / B (COMPARE-6)

- **Kind:** behavior
- **Target AC:** AC-10, AC-11
- **Depends on:** COMPARE-3 · **Blocks:** SIGNOFF-1
- **Files:** `comparison_controller.dart` (`openReadout`), the E7/E8 controls in `actions_bar.dart`.
- **Tasks:**
  1. Wire E7 → `AppRouter.toReadout(slotA)` and E8 → `toReadout(slotB)`; keep the read endpoint reachable
     across the push (D-6).
  2. Controls enabled only when the corresponding slot is set.
- **Exit criteria:** unit gate 100% on touched code; `TestAC10_OpenReadoutA`, `TestAC11_OpenReadoutB` green
  run-pending; earlier ACs green.
- **Acceptance gate:** un-pend AC-10, AC-11; suite green for those tests and all earlier ACs.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
