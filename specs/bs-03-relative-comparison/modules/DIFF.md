# Module DIFF — comparison color-science

**Status:** In progress
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/compare/difference.dart` (ΔE00, verdict, the `Comparison` / `RelationalStatement`
value types, the LCh decomposition). Reuses bs-01's `lib/color_science/words.dart` (`hueFamilyWord`) and
`lib/domain/color_coordinates.dart`. Does **not** touch bs-01's `lib/color_science/decomposition.dart`.
**Depends on:** bs-01 color-science (LCh, `hueFamilyWord`) · **Blocks:** COMPARE-2 (consumes the types), the
comparison-difference regions in SCREEN

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 2,538,094 | 6m 48s |
| 2 | behavior | AC-4 | ⬜ Todo | | |
| 3 | behavior | AC-5, AC-6 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes** a pure `Comparison compare(Sample a, Sample b)` producing `{ deltaE00: double, verdict: String,
  lightness: String, saturation: String, hue: String }` — the overall ΔE00 + plain verdict and the three
  decomposition lines. All side-effect free, so the controller, the screen and the acceptance suite share it
  unchanged.
- **ΔE00** is CIEDE2000, promoted from the verified private `_deltaE00` in `integration_test/capture_test.dart`
  (verified against Sharma et al.). The acceptance suite keeps its own independent reference ΔE00 so the test
  does not grade the implementation against itself.
- **Decomposition** is in LCh (D-3): `labToCielch` (bs-01) gives L\*/C\*/h for each sample; the deltas are
  ΔL\*, ΔC\*ab and the signed circular Δh°; the direction word is `hueFamilyWord` of the hue moved toward.
- **Verdict bands** (D-n in Phase 2): ΔE00 thresholds → plain words ("barely different" / "clearly different"
  / … ); the exact band edges are set in DIFF-2 and recorded here.

## Open gates

- **G-4 (spec-data reconciliation)** blocks **DIFF-2**: the expected ΔE00 literal for AC-4 ("14.2" vs the
  computed ≈ 13.05) must be settled before the overall-difference text can be pinned. See the master plan.

## Phase 1 — Comparison color-science shell (DIFF-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** COMPARE-1 · **Blocks:** COMPARE-2, DIFF-2, DIFF-3
- **Files:** `lib/compare/difference.dart`
- **Tasks:**
  1. Declare the `Comparison` value type ({ `deltaE00`, `verdict`, `lightness`, `saturation`, `hue` }) with
     value equality, and a `compare(Sample a, Sample b)` entry returning a fixed placeholder `Comparison`.
  2. Declare the private helper signatures (ΔE00, verdict band, per-dimension line) as stubs that the
     behaviour phases fill. No real math yet.
  3. Dartdoc each surface naming the AC it serves and the LCh basis (D-3), the ΔE00 basis (D-2).
- **Exit criteria:** `flutter analyze` clean; the type is constructible; unit gate passes (100% on the new
  file — the placeholder has no branches); existing suites stay green.
- **Acceptance gate:** *(shell — none)*

### Result

Landed `lib/compare/difference.dart`: the `Comparison` value type
(`{ deltaE00, verdict, lightness, saturation, hue }`) with const ctor, value
equality (`==`/`hashCode`), `toString`; a pure `compare(Sample a, Sample b)`
entry returning a fixed, branch-free placeholder; and the five private stubs
the behaviour phases fill — `_deltaE00`/`_verdictBand` (DIFF-2) and
`_lightnessLine`/`_saturationLine`/`_hueLine` (DIFF-3). Dartdoc names the AC and
the D-2/D-3 basis on each surface. No real math.

- **Tests:** `test/compare/difference_test.dart` (6 new) — equality true/false
  per field, non-`Comparison` inequality, field getters + `toString`, and the
  placeholder `compare` output.
- **Unit gate:** 202 green (196 → 202, +6). **Coverage:** `dart run
  tool/coverage_gate.dart main` → 100% on the one touched file
  (`lib/compare/difference.dart`), PASS (placeholder has no branches).
- **Existing suites green:** `flutter analyze` clean; `flutter test` 202 green;
  `flutter test integration_test/` 17 green (bs-01 readout + harness, iOS sim).
- **Acceptance gate:** none (shell). **Augmentations:** none.
- **Fix passes:** 0/3 (passed first run). **Tokens / Time:** 2,538,094 / 6m 48s.

### Checkpoint / Handoff

- **Frozen for consumers (COMPARE-2, DIFF-2, DIFF-3):** `Comparison` with named
  fields `deltaE00` (double), `verdict`, `lightness`, `saturation`, `hue`
  (String); value equality. Entry `Comparison compare(Sample a, Sample b)`,
  pure. Import `package:paint_color_assistant/compare/difference.dart`.
- **To fill in behaviour phases (same file):** DIFF-2 implements `_deltaE00`
  (CIEDE2000, mirror the verified `_deltaE00` in
  `integration_test/capture_test.dart`) and `_verdictBand`; DIFF-3 implements
  the three dimension-line stubs (LCh ΔL\*/ΔC\*ab/signed Δh° + `hueFamilyWord`,
  with the "Same …" zero-delta branch). Each returns a placeholder today.
- **Verification commands** (export PATH first —
  `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
  `flutter test --coverage` · `flutter test integration_test/` ·
  `dart run tool/coverage_gate.dart main`.
- **Known gaps:** placeholder values only — `compare` returns ΔE00 0.0 and empty
  strings until DIFF-2/DIFF-3. **G-4** still blocks DIFF-2 (the AC-4 ΔE00
  literal). Carry-over bs-01 flake: a const-ctor line can intermittently read
  uncovered on `--coverage`; re-run once.
- **Next:** DIFF-2 (needs G-4 + COMPARE-3 Givens); CVD-1 is the other startable
  shell, disjoint dir.

## Phase 2 — Overall difference: ΔE00 + plain verdict (DIFF-2)

- **Kind:** behavior
- **Target AC:** AC-4
- **Depends on:** DIFF-1, COMPARE-3 (Givens), **G-4** · **Blocks:** DIFF-3
- **Files:** `lib/compare/difference.dart`; `lib/compare/difference_region.dart` (render "delta-E00 N" +
  verdict).
- **Tasks:**
  1. Implement CIEDE2000 ΔE00 (mirror the verified `_deltaE00`; cover each branch — the C=0 / hue-mean
     wraparound / `Rt` cases).
  2. Implement the plain-verdict bands (≥ 2 bands so the verdict tracks distance, not a constant).
  3. Render the overall-difference line on the screen as the exact string the pinned G-4 value dictates.
- **Exit criteria:** unit gate (100% on touched code incl. every ΔE00 branch); `TestAC04_OverallDelta` green
  run-pending; earlier ACs still green.
- **Acceptance gate:** un-pend AC-4; `BS03_RUN_PENDING=1 flutter test integration_test/comparison_test.dart`
  green for `TestAC04_OverallDelta` and all earlier ACs.
- **Augments:** `TestAC04`: add a near-identical control pair asserting a **different** verdict band (so a
  constant verdict string fails).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Relational decomposition + unchanged dimension (DIFF-3)

- **Kind:** behavior
- **Target AC:** AC-5, AC-6
- **Depends on:** DIFF-2 · **Blocks:** COMPARE-5, CVD-3
- **Files:** `lib/compare/difference.dart`; `lib/compare/statement_region.dart` (the three lines; COMPARE-3
  already added the empty-B invite here — keep it).
- **Tasks:**
  1. Compute ΔL\* → "Lighter/Darker by n", ΔC\*ab → "More/Less saturated by n", signed Δh° → "Hue shifted n
     degrees toward <family>" using `hueFamilyWord` for the direction.
  2. A rounded delta of 0 in any dimension reads "Same lightness / saturation / hue" (AC-6), leaving the
     other two dimensions stating their deltas.
  3. Render the three lines in the statement region.
- **Exit criteria:** unit gate (100% on touched code, incl. both signs and the "Same" branch of each
  dimension); `TestAC05_Decompose` and `TestAC06_SameHue` green run-pending; earlier ACs green.
- **Acceptance gate:** un-pend AC-5, AC-6; suite green for those tests and all earlier ACs.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
