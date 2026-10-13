# Module QUALITY — measured & behavioural targets (accuracy, performance, reliability)

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/nfr/quality/` (accuracy harness + `syntheticAccuracySet`, performance harness — reusable test-support), and the **one `lib/` product change**: the AC-9 downgrade seam/triggers in `lib/capture/` (`capture_accuracy.dart`, `capture_controller.dart`, and the live-view label surface). Shares `integration_test/bs12/nfr_harness.dart` + `nfr_test.dart`.
**Depends on:** GUARD (shells) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| QUALITY-1 | shell | — | ⬜ Todo | | |
| QUALITY-2 | behavior | AC-9 | ⬜ Todo | | |
| QUALITY-3 | behavior | AC-13 | ⬜ Todo | | |
| QUALITY-4 | behavior | AC-10, AC-11, AC-12 | ⬜ Todo | | |
| QUALITY-5 | behavior | AC-3, AC-4 | ⬜ Todo | | |

## Interface reconciliation

- **AC-9 downgrade seam:** today `CaptureAccuracy` {approximate ≤8 / calibrated ≤3}; `capture_controller.dart` downgrades only on `Lighting.low`; `calibrate()` is a silent no-op when `referenceCardPresent` is false; `CaptureLocks`/`lock()` drives *settling*, not the tier. The fix (D-5) adds **two explicit downgrade/label triggers**: exposure/AWB/focus **not** locked at commit, and reference card **missing** — each forces the stated accuracy to `approximate` (or a labelled downgrade) rather than returning the reading as trustworthy. Preserve the "downgrade, never refuse" policy (bs-02 AC-6/7/8 stay green). This is the **only** coverage-gated `lib/` change.
- **Accuracy (D-2):** `syntheticAccuracySet` is a deterministic fixture (no device, no spectrophotometer) with, per condition, an input and a known expected colour / ΔE. Grade it with the **independent** `referenceDeltaE00` (from `comparison_harness.dart`), never the product `deltaE00` against itself. Carry the "synthetic ≠ physical ground truth" gap to sign-off.
- **Performance (D-3):** settle is frame-count (`kStabilityFrameTarget=12`), not wall-clock; search is `topK=5`. Assert the mechanism (indicator shown + reaches STABLE; 3–5 candidates) and a **generous CI budget** (`Stopwatch` ceiling that catches pathological regressions on the sim, explicitly not the target-hardware figure). AC-5 (live-preview fps) has no timed feed → no automated test.
- **Observation points:** `CaptureReadEndpoint` (stated accuracy, settling state), `RecipeReadEndpoint` (candidates, `outOfGamut`), the single `deltaE00` over the synthetic set.

## Open gates

- **G-2** (approve acceptance tests) blocks **QUALITY-2..QUALITY-5**.
- **G-3** (AC-5 device frame rate + AC-3/AC-4 target-hardware timings) is a SIGNOFF-1 manual gate, not owned here (QUALITY-5 delivers only the automated side of AC-3/AC-4).

## Phase QUALITY-1 — shell: quality scaffolds + AC-9 seam

- **Kind:** shell
- **Target AC:** —
- **Depends on:** GUARD-1 · **Blocks:** ITEST-1 · **∥ GUARD-2**
- **Files:** `integration_test/nfr/quality/accuracy_harness.dart`, `integration_test/nfr/quality/synthetic_accuracy_set.dart`, `integration_test/nfr/quality/perf_harness.dart`; `lib/capture/capture_accuracy.dart` + `lib/capture/capture_controller.dart` (AC-9 seam, behaviour unchanged)
- **Tasks:**
  1. `synthetic_accuracy_set.dart`: the fixture shape (per-condition samples + expected values) with a small deterministic seed set (expanded in QUALITY-4).
  2. `accuracy_harness.dart` / `perf_harness.dart`: signatures + stubs the ITEST smoke test can call.
  3. AC-9 seam: extend the capture surface so "exposure unlocked" and "card missing" are **representable** downgrade/label inputs (new fields/params, default-wired so current behaviour is byte-for-byte unchanged); no trigger logic yet.
- **Exit criteria:** compiles; existing suite green (incl. bs-02 capture ACs); coverage on the touched `lib/capture` lines 100% (the seam is exercised by a unit test asserting defaults preserve current behaviour).

## Phase QUALITY-2 — AC-9 reliability downgrade fix

- **Kind:** behavior
- **Target AC:** AC-9 (full) — the one real `lib/` behaviour build (D-5)
- **Depends on:** ITEST-4 (G-2), QUALITY-1 · **Blocks:** SIGNOFF-1 · **∥ one GUARD behavior phase** (disjoint files)
- **Files:** `lib/capture/capture_controller.dart`, `lib/capture/capture_accuracy.dart`, `lib/capture/capture_live_view.dart` (label), `test/capture/*`; `nfr_test.dart` (un-pend AC-9)
- **Tasks:** make unlocked exposure (AE/AWB/focus not locked at commit) and missing reference card each **downgrade the stated accuracy / set an explicit approximate label**, never returning a trustworthy reading; keep "downgrade, never refuse"; surface the reason in the live view. Assert all three poor conditions downgrade; `control_trustworthyPoor` is rejected.
- **Exit criteria (gates):** unit + coverage (touched `lib/capture` 100%, every branch of the new triggers); bs-02 capture ACs stay green; acceptance `TestAC09_*` green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-9; `TestAC09_PoorConditionsDowngradeAccuracy` + all earlier green.

## Phase QUALITY-3 — AC-13 out-of-gamut

- **Kind:** behavior
- **Target AC:** AC-13 (full)
- **Depends on:** ITEST-4 (G-2), QUALITY-1 · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/quality/accuracy_harness.dart`; `nfr_test.dart` (un-pend AC-13)
- **Tasks:** run an out-of-gamut target + `control_inGamut` through the real engine; assert the out-of-gamut target is identified (`RecipeReadEndpoint.outOfGamut`/banner) and **no recipe is offered as a match**; the in-gamut control is not flagged and does return recipes. (Behaviour exists — bs-04 ENGINE-5; this phase proves and guards it.)
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-13; `TestAC13_OutOfGamutNoFalseRecipe` + all earlier green.

## Phase QUALITY-4 — AC-10 + AC-11 + AC-12 accuracy (synthetic)

- **Kind:** behavior
- **Target AC:** AC-10, AC-11, AC-12 (full) — against the synthetic set (D-2)
- **Depends on:** ITEST-4 (G-2), QUALITY-1 · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/quality/synthetic_accuracy_set.dart` (full set), `accuracy_harness.dart` (real asserts); `nfr_test.dart` (un-pend AC-10, AC-11, AC-12)
- **Tasks:** build the deterministic synthetic held-out set for the three conditions; run the card+controlled path (assert ΔE00 ≤ 3 vs expected, graded by `referenceDeltaE00`), the card-less daylight path (ΔE00 ≤ 8 **and** labelled approximate), the recipe-vs-swatch path (ΔE00 ≤ 5 for in-gamut); add the discriminating perturbation controls. Record the "synthetic ≠ physical ground truth" gap in the Result for sign-off.
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-10, AC-11, AC-12; `TestAC10/11/12_*` + all earlier green.

## Phase QUALITY-5 — AC-3 + AC-4 performance (mechanism + CI budget)

- **Kind:** behavior
- **Target AC:** AC-3, AC-4 (automated side; D-3)
- **Depends on:** ITEST-4 (G-2), QUALITY-1 · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/quality/perf_harness.dart`; `nfr_test.dart` (un-pend AC-3, AC-4)
- **Tasks:** AC-3 — commit a reading through the real controller, assert the stability indicator shows (SETTLING n/12) then reaches STABLE and commits, with elapsed under the generous CI budget. AC-4 — run a recipe search for a seeded target, assert 3–5 ranked candidates return under the CI budget. Document that the literal ~1–2s target-hardware figures are owner evidence at SIGNOFF (not asserted in CI).
- **Exit criteria (gates):** unit + coverage; acceptance green; grade gate (note the deliberate CI-budget ≠ device-figure limitation in the Result).
- **Acceptance gate:** un-pend AC-3, AC-4; `TestAC03_ReadingSettlesWithIndicator`, `TestAC04_RecipeSearchReturnsTopCandidates` + all earlier green.

### Result  <!-- filled on completion; ≤ ~20 lines -->

### Checkpoint / Handoff  <!-- filled on completion -->

- **Verification commands:** `flutter analyze` · `flutter test` · `dart tool/coverage_gate.dart` · `flutter test integration_test/bs12/nfr_test.dart -d <udid>` (default) / `--dart-define=BS12_RUN_PENDING=true` (run-pending)
- **Known gaps:** AC-10/11/12 proven against the synthetic set, not physical ground truth (D-2); AC-3/AC-4 CI budget is a regression ceiling, not the target-hardware ~1–2s (D-3); AC-5 is manual-only.
