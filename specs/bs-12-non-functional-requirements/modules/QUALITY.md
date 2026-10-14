# Module QUALITY — measured & behavioural targets (accuracy, performance, reliability)

**Status:** In progress — QUALITY-1 + QUALITY-2 + QUALITY-3 done (AC-9, AC-13 delivered); next QUALITY-4 (AC-10/11/12) then QUALITY-5 (AC-3/4) — sequence (shared `nfr_test.dart`)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/nfr/quality/` (accuracy harness + `syntheticAccuracySet`, performance harness — reusable test-support), and the **one `lib/` product change**: the AC-9 downgrade seam/triggers in `lib/capture/` (`capture_accuracy.dart`, `capture_controller.dart`, and the live-view label surface). Shares `integration_test/bs12/nfr_harness.dart` + `nfr_test.dart`.
**Depends on:** GUARD (shells) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| QUALITY-1 | shell | — | ✅ Done | 9.16M | 20m 33s |
| QUALITY-2 | behavior | AC-9 | ✅ Done | 14.38M | 24m 36s |
| QUALITY-3 | behavior | AC-13 | ✅ Done | 6.08M | 11m 42s |
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
- **Result (✅ Done 2026-10-13):**
  - **Quality scaffolds** under `integration_test/nfr/quality/` (test-support, no behaviour — D-7):
    - **`synthetic_accuracy_set.dart`** — the fixture shape `AccuracyCondition` {cardControlled ≤3 / cardlessDaylight ≤8 / recipeVsSwatch ≤5} (each carries its `maxDeltaE`), `SyntheticAccuracySample` {id, condition, input, expected, expectApproximate}, `SyntheticGamutTarget` {id, target, inGamut}; plus a **deterministic seed set** `syntheticAccuracySet` (one sample per condition, inputs inside each bound) and `syntheticGamutTargets` (one in-gamut control + one out-of-gamut). QUALITY-4 expands to the full held-out set with perturbed inputs.
    - **`accuracy_harness.dart`** — `AccuracyGrade` {sampleId, condition, deltaE, maxDeltaE, `withinBound`} and `AccuracyHarness` (`deltaE`, `grade`, `gradeAll`) grading each sample's input vs expected with the **independent** `referenceDeltaE00` (imported `show referenceDeltaE00` from `../../comparison_harness.dart`, never the product metric against itself — D-2). Stub grades the fixture input directly; QUALITY-4 feeds inputs through the real pipeline.
    - **`perf_harness.dart`** — the CI regression budgets `kCaptureSettleCiBudget`/`kRecipeSearchCiBudget` (10s — generous, *not* the device ~1–2s), candidate-count bounds `kMinTopCandidates=3`/`kMaxTopCandidates=5` + `isTopCandidateCount`, `PerfProbe` {label, elapsed, budget, `withinBudget`} and `PerfHarness.measure(label, budget, body)` timing a body under a `Stopwatch`. QUALITY-5 wraps a real commit / recipe search. Scaffolds are **unreferenced** by any test/lib yet → acceptance build unchanged; ITEST-1's smoke test calls each.
  - **AC-9 seam (the one `lib/` change — D-5, behaviour byte-for-byte unchanged, no trigger logic):**
    - `lib/capture/capture_accuracy.dart` — new `enum AccuracyDowngradeReason` {lowLight, exposureUnlocked, missingReferenceCard}, each with a user-facing `label` (words, not colour — bs-01 contract). The first-class representation of all three poor conditions AC-9 names (today only lighting downgrades; exposure/card went unenforced).
    - `lib/capture/capture_controller.dart` — new read-only `activeDowngradeReasons` getter reporting which of the three hold at the source (`lighting==low`, `!locks.allLocked`, `!referenceCardPresent`); empty in the trustworthy case. Purely observational — a `commit` still states exactly the accuracy it always did. QUALITY-2 consumes it to force a reading approximate + surface the reason.
  - **Verification:** `flutter analyze` → No issues. Unit `flutter test --coverage` → **1228 passed** (baseline 1220 + 8 new: 2 `AccuracyDowngradeReason` + 6 `activeDowngradeReasons` incl. the side-effect-free default-wired proof). Coverage gate (`dart run tool/coverage_gate.dart main`) → **100% on the 2 touched `lib/capture` files** (`capture_accuracy.dart`, `capture_controller.dart`). Acceptance `flutter test integration_test -d <iPhone 17 sim>` under `coord.sh with-lock` → **197 passed, exit 0** (bs-02 capture ACs green; teardown flake did not recur).
  - **Fix passes:** 0/3 (analyze + unit + coverage + acceptance all green first pass).
  - **Tokens / Time:** see Dashboard / master ledger (QUALITY-1 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** `cd /Users/matthew.quirk/Nuance-bs12`; `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-12 <PHASE> --wait N -- bash -c 'cd …/Nuance-bs12 && flutter test integration_test -d <booted-udid>'` (shared device lane → lock mandatory; booted `-d` mandatory; run ~8m — redirect to a file, don't tail foreground).
  - **Frozen for ITEST-1 / QUALITY-2..5:**
    - `synthetic_accuracy_set.dart`: `AccuracyCondition`, `SyntheticAccuracySample`, `SyntheticGamutTarget`, `syntheticAccuracySet`, `syntheticGamutTargets`.
    - `accuracy_harness.dart`: `AccuracyGrade`, `AccuracyHarness` (`deltaE`/`grade`/`gradeAll`).
    - `perf_harness.dart`: `kCaptureSettleCiBudget`, `kRecipeSearchCiBudget`, `kMinTopCandidates`, `kMaxTopCandidates`, `isTopCandidateCount`, `PerfProbe`, `PerfHarness.measure`.
    - `lib/capture`: `AccuracyDowngradeReason` + `CaptureController.activeDowngradeReasons`.
  - **Known gaps / next:** **ITEST-1 is now unblocked** (both GUARD-2 and QUALITY-1 done) — it builds `nfr_harness.dart`/`nfr_test.dart` and the never-pending smoke test over the GUARD + QUALITY stubs. QUALITY-2 (the AC-9 trigger that consumes `activeDowngradeReasons` at commit + surfaces the reason in the live view) and QUALITY-3/4/5 stay blocked on G-2 (decided at ITEST-4). `AccuracyHarness` imports the whole `comparison_harness.dart` via `show referenceDeltaE00` — if a later name clash appears, extract the reference into its own file.

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

### Result (✅ Done 2026-10-14)

- **The one `lib/capture` behaviour change (D-5).** `commit()` now forces the committed reading's stated accuracy to `CaptureAccuracy.approximate` whenever any `activeDowngradeReasons` holds (poor lighting, AE/AWB/AF not locked, or no reference card); a reading with no active reason keeps the tier it earned (an explicit card calibration stays `calibrated`). Closes the AC-9 gap where only lighting downgraded — unlocked exposure and a missing card were unenforced. The committed-accuracy decision is computed once and applied to both the live-average and imported-photo commit branches.
- **Reason surfaced in the live view.** `CaptureLiveView` gained a `downgradeReasons` param (keyed `downgradeReasonsKey`) rendering each active reason in words; `CaptureScreen` feeds it `controller.activeDowngradeReasons` (rebuilt each notify). No `CaptureState` change — kept the state shape and its equality untouched.
- **AC-9 un-pended** (`integration_test/bs12/pending.dart`); pending map 7→6. Pending-gate guard updated (`expectedPending` drops AC-9, length 7→6, AC-9 `containsKey` false added).
- **Test reconciliation (recorded, not a weakening).** The new AC-9 contract makes a calibrated-but-unsettled reading non-trustworthy, so three bs-02 tests that calibrated→committed **without** locking gained a `lock` step to keep demonstrating the calibrated tier — unit `test/capture/capture_controller_test.dart` (AC-8 "committing after calibration"); integration `integration_test/capture_test.dart` (AC-6 calibrated control + AC-8). Assertions unchanged; a precondition added (settle before calibrate), the natural capture flow. D-5 sanctioned ("bs-02 AC-6/7/8 stay green").
- **Verification.** `flutter analyze` → No issues. Unit `flutter test --coverage` → **1233 pass** (+5: 3 controller AC-9 downgrade + 2 live-view reason region). Coverage gate `dart run tool/coverage_gate.dart main` → **100% on all 4 touched `lib/capture` files** (`capture_accuracy.dart` unchanged, `capture_controller.dart`, `capture_live_view.dart`, `capture_screen.dart`). Acceptance `-d flutter-tester`: AC-9 un-pended + **green** (`TestAC09`), full bs-12 nfr suite **27 pass / 6 pending-skip / exit 0**; regression bs-02 `capture_test.dart` **19/0**, `advanced_capture_test.dart` **21/0** (the only two commit consumers expecting `calibrated` are `capture_test`/`nfr_test`, both green).
- **Grade gate:** fresh independent grader (prior grid as context) → **1 A / 0 B pending / 0 ordinary B** — AC-9 closes *B pending QUALITY-2* → **A**. Discriminates both a low-light-only (pre-fix) impl (via the unlocked-exposure branch) and a blanket force-to-approximate (via the trustworthy control). Grid appended to `behavior-test-completeness-…md` (QUALITY-2 §).
- **Fix passes:** 0/3 (analyze + unit + coverage + acceptance + grade all green first pass).

### Checkpoint / Handoff

- **Verification commands:** `cd /Users/matthew.quirk/Nuance-bs12`; `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; acceptance `flutter test integration_test/bs12/nfr_test.dart -d flutter-tester` (default) / `--dart-define=BS12_RUN_PENDING=true` (run-pending). **bs-12 nfr runs on `-d flutter-tester` (host), no device lane.**
- **Frozen for QUALITY-3/4/5:** `lib/capture` AC-9 behaviour is final — `CaptureController.commit()` downgrades on `activeDowngradeReasons`; `CaptureLiveView.downgradeReasons` + `downgradeReasonsKey`. The remaining QUALITY phases touch only `integration_test/nfr/quality/*` + `nfr_test.dart` (no further `lib/` change).
- **Known gaps / next:** QUALITY-3 (AC-13 out-of-gamut — un-pend+guard, green at baseline), QUALITY-4 (AC-10/11/12 accuracy, synthetic set — carries the "synthetic ≠ physical ground truth" D-2 gap), QUALITY-5 (AC-3/4 performance — un-pend+guard; CI budget is a regression ceiling, not the target-hardware ~1–2s, D-3). All three remain; **they share `nfr_test.dart` + `pending.dart` → sequence (one/session, `/clear` between)**. AC-5 is manual-only (G-3 at SIGNOFF-1). Then SIGNOFF-1.

## QUALITY-3 — AC-13 out-of-gamut (un-pend + guard)

### Result (✅ Done 2026-10-14)

- **Un-pend + guard only — no `lib/` change.** AC-13 (out-of-gamut target identified, no false recipe) is satisfied by bs-04 ENGINE-5 already on `main`; QUALITY-3 un-pends its ITEST-3 test and keeps it green. The AC-13 test body is unchanged (the ITEST-3 in-phase banner-marker fix stands): the real engine solves the `neon-cyan` out-of-gamut target via `givenTheApp(flow: NfrFlow.recipes, recipeTarget:)`, asserts `recipeState.outOfGamut` + the shown `GamutBanner.markerText` + every returned `Recipe.outOfGamut` (nearest-not-a-match); the in-gamut `warm-earth` control is not flagged, shows no marker, and returns recipes.
- **AC-13 un-pended** (`integration_test/bs12/pending.dart`); pending map 6→5. Pending-gate guard updated (`expectedPending` drops AC-13, length 6→5, AC-13 `containsKey` false added).
- **Verification.** `flutter analyze` → No issues. Unit `flutter test --coverage` → **1233 pass** (unchanged — integration-test-only phase). Coverage gate `dart run tool/coverage_gate.dart main` → **100% on all touched files, PASS** (no `lib/` touched this phase; the branch's merged-lib coverage holds). Acceptance `-d flutter-tester`: AC-13 un-pended + **green**, full bs-12 nfr suite **28 pass / 5 pending-skip / exit 0** (was 27/6); run-pending `--dart-define=BS12_RUN_PENDING=true` → **30 pass / 3 fail** — the 3 fails are exactly AC-10/11/12 (QUALITY-4's clean red baseline); AC-3/4 (QUALITY-5, green at baseline) and AC-13 pass green.
- **Grade gate:** fresh independent grader (prior grid as context) → **1 A / 0 B — PASS**. AC-13 stays **A**: un-pending altered no assertion (byte-identical to the A-graded ITEST-3 body); G1–G6 all ✓ — the marker-text assertion discriminates a "flags state but renders no banner" impl (the collapsed `SizedBox.shrink` carries no Text), the `every outOfGamut` assertion kills a false-match impl, and the in-gamut control is a real positive/negative pair. Grid appended to `behavior-test-completeness-…md` (QUALITY-3 §).
- **Augmentations:** none owed — AC-13 was green-at-baseline A with no augmentation row (ITEST *Test augmentations* carries no AC-13 entry).
- **Fix passes:** 0/3 (analyze + unit + coverage + acceptance + grade all green first pass).

### Checkpoint / Handoff

- **Verification commands:** unchanged from QUALITY-2 (above).
- **Frozen:** AC-13 delivered + un-pended; `integration_test/nfr/quality/*` untouched this phase (the AC-13 test drives the engine directly via the harness, not `accuracy_harness`).
- **Known gaps / next:** **QUALITY-4 (AC-10/11/12 accuracy)** then **QUALITY-5 (AC-3/4 performance)** remain — both un-pend in the shared `integration_test/bs12/pending.dart` and edit the shared `nfr_test.dart` → **sequence (one/session, `/clear` between)**. QUALITY-5 is un-pend+guard (AC-3/4 green at baseline); QUALITY-4 builds the full synthetic held-out set (carries the "synthetic ≠ physical ground truth" D-2 gap). Then SIGNOFF-1 (G-3 manual AC-5 + AC-3/4 device evidence). Pending map now holds AC-3/4/10/11/12 (5 ACs).
