# Module DIFF — comparison color-science

**Status:** ✅ Done (DIFF-1 shell, DIFF-2 AC-4, DIFF-3 AC-5/AC-6)
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
| 2 | behavior | AC-4 | ✅ Done | 12,157,763 | 31m 40s |
| 3 | behavior | AC-5, AC-6 | ✅ Done | 7,471,205 | 15m 32s |

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
- **Verdict bands** (DIFF-2): ΔE00 → plain words by ascending exclusive upper bound —
  `< 1` "no visible difference", `[1, 3)` "barely different", `[3, 10)` "slightly different",
  `[10, 50)` "clearly different", `≥ 50` "very different" (perceptual guide: ΔE00 ≈ 1 is a JND). AC-4's pair
  (ΔE00 ≈ 13.05) reads "clearly different"; the DIFF-2 augmentation's nearer control pair (ΔE00 ≈ 6.71) reads
  "slightly different", proving the verdict tracks distance.

## Open gates

- **G-4 (spec-data reconciliation)** — ✅ Resolved 2026-10-07 (master plan): option (a), the AC-4 overall is
  the computed value **"delta-E00 13.1"** (the spec's old 14.2 was the error). DIFF-2 pins it. No open gate
  blocks this module.

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

### Result

Landed the real overall difference in `lib/compare/difference.dart`: `_ciede2000` (CIEDE2000, Sharma–Wu–Dalal,
mirroring the harness's independent `referenceDeltaE00`) behind `_deltaE00(a, b)` over the samples' CIELAB
coordinates, and a five-band `_verdictBand` (bands recorded in *Interface reconciliation*). Rendered the
reading in `difference_region.dart`: when both slots are set it shows `delta-E00 N` (ΔE00 to one decimal) +
the verdict word; otherwise the placeholder. Un-pended AC-4 (`bs03/pending.dart` row deleted + `unpended`
complement set in `comparison_test.dart` updated) and made the pre-seeded augmentation.

- **Un-pended:** AC-4. **Augmentation made:** `TestAC04` now re-selects a nearer pair (Raw Sienna Light vs
  Terracotta Tint, ΔE00 ≈ 6.71 → "slightly different") and asserts a *different*, lower verdict band — a
  constant verdict string now fails (grader-verified it discriminates).
- **Unit gate:** `flutter test` 272 green (260 → 272, +12). `flutter analyze` clean. **Coverage:** `dart run
  tool/coverage_gate.dart main` → 100% line on all 15 touched `lib/` files (incl. `difference.dart`,
  `difference_region.dart`); every ΔE00 branch (C=0 short-circuits, both hue wrap signs, both mean-hue
  quadrants) and all five verdict bands are exercised by the new unit pairs in `test/compare/difference_test.dart`.
- **Acceptance gate:** default `flutter test integration_test/` → **All tests passed (+37 ~6)** (6 later-phase
  ACs skipped pending). Run-pending (`--dart-define=BS03_RUN_PENDING=true`) `comparison_test.dart` → AC-4 +
  all un-pended ACs green; the 6 unbuilt ACs (AC-3/5/6/7/8/9) hold the red baseline. iOS sim (iPhone 17),
  verify lock.
- **Grade gate:** AC-4 **clean A** (no longer "A limited" — augmentation closes the limit); AC-1/2/10/11/12
  re-confirmed A. **6×A, 0×B**, independent fresh grader; grid appended to
  `behavior-test-completeness-bs-03-relative-comparison.md`.
- **Fix passes:** 1/3 — the first full default run surfaced the ITEST-1 pending-gate complement guard failing
  (AC-4 removed from `pendingACs` but not yet added to the `unpended` set); fixed in one line, re-ran green.
- **Augmentations / exclusions:** one augmentation (TestAC04) made; no coverage exclusions.
- **Tokens / Time:** 12,157,763 / 31m 40s.

### Checkpoint / Handoff

- **Frozen for consumers:** `compare(a, b).deltaE00` is the shipped CIEDE2000 ΔE00; `.verdict` is the
  five-band plain word. The three LCh lines (`lightness`/`saturation`/`hue`) are **still placeholders** until
  DIFF-3. `DifferenceRegion` renders `delta-E00 N` + verdict when `state.comparison != null`.
- **For DIFF-3 (same file `lib/compare/difference.dart`):** fill `_lightnessLine` / `_saturationLine` /
  `_hueLine` (LCh ΔL\*/ΔC\*ab/signed Δh° + `hueFamilyWord`, with the "Same …" zero-delta branch), and render
  them in `statement_region.dart` (keep COMPARE-3's empty-B invite). DIFF-2 did not touch `statement_region`.
  Un-pend AC-5/AC-6: delete their rows in `bs03/pending.dart` **and** add `'AC-5'`/`'AC-6'` to the `unpended`
  set in `comparison_test.dart` (the pending-gate complement guard checks both — see DIFF-2's fix pass).
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration on the
  iOS sim under the verify lock: `flutter test integration_test/` (default) and
  `flutter test integration_test/comparison_test.dart --dart-define=BS03_RUN_PENDING=true` (run-pending),
  `-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gaps:** AC-5/6 (DIFF-3), AC-7/8 (CVD-2), AC-9 (CVD-3), AC-3 (COMPARE-5) still pending. Carry-over
  bs-01 const-ctor coverage flake — re-run `--coverage` once if an untouched file flags.
- **Next:** DIFF-3 (AC-5, AC-6; after DIFF-2 — same file) or CVD-2 (AC-7, AC-8; disjoint dir, startable now).

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

### Result

Filled the three LCh decomposition lines in `lib/compare/difference.dart`:
`_lightnessLine` (signed rounded ΔL\* → "Lighter/Darker by n" / "Same lightness"),
`_saturationLine` (signed rounded ΔC\*ab → "More/Less saturated by n" / "Same
saturation"), `_hueLine` (shortest signed rounded Δh° → "Hue shifted n degrees
toward <family>" with `hueFamilyWord` of B's hue / "Same hue"). Each reads L/C/h
via bs-01's `labToCielch`, so the lines agree with the slot readings. A private
`_signedHueDelta` folds the Dart `%` remainder ([0,360)) onto the shortest
(−180,180] rotation. Rendered the three lines in `statement_region.dart`'s
both-slots branch (the empty-B invite branch is untouched). Un-pended AC-5/AC-6.

- **Un-pended:** AC-5, AC-6 (`bs03/pending.dart` rows removed **and** `'AC-5'`/
  `'AC-6'` added to the `unpended` complement set in `comparison_test.dart`).
- **Unit gate:** `flutter test` 295 green (+? from 294 baseline; +9 new LCh-line
  cases). `flutter analyze` clean (one doc-comment `<family>` HTML lint fixed
  before the gate run — backticked). **Coverage:** `dart run
  tool/coverage_gate.dart main` → 100% line on all 15 touched `lib/` files; the
  new unit group in `test/compare/difference_test.dart` exercises both signs and
  the "Same" branch of each dimension, plus the `_signedHueDelta` wrap fold.
- **Acceptance gate:** default `flutter test integration_test/comparison_test.dart`
  → **All tests passed (+24 ~2)** — AC-5/AC-6 now run and pass; only AC-3
  (COMPARE-5) and AC-9 (CVD-3) skipped pending. Run-pending
  (`--dart-define=BS03_RUN_PENDING=true`) → **+24 −2**: AC-5/AC-6 green, red
  baseline held by exactly AC-3 and AC-9. iOS sim (iPhone 17), verify lock.
- **Grade gate:** AC-5 **A**, AC-6 **A**; the eight neighbours (AC-1/2/4/7/8/10/
  11/12) re-confirmed A, no neighbour regrade. **10×A, 0×B**, independent fresh
  grader; grid appended to `behavior-test-completeness-bs-03-relative-comparison.md`.
- **Augmentations / exclusions:** none made, none newly enabled; no coverage
  exclusions.
- **Fix passes:** 0/3 (gates passed first full run; the one doc-comment lint was
  fixed before the gate loop). **Tokens / Time:** 7,471,205 / 15m 32s.

### Checkpoint / Handoff

- **Frozen for consumers:** `compare(a, b)` now returns real `.lightness` /
  `.saturation` / `.hue` lines (strings), each A→B, alongside the DIFF-2
  `.deltaE00` / `.verdict`. `StatementRegion` renders the three lines when both
  slots are set, the AC-12 invite when a slot is empty. The hue direction word is
  `hueFamilyWord` of **B's** hue; magnitudes are rounded integers.
- **For COMPARE-5 (AC-3 swap + re-express):** swapping A/B must re-run `compare`
  so the statement flips direction — "Lighter by 12" ↔ "Darker by 12", hue family
  re-evaluated toward the new B. Do not re-author the line strings; read them from
  the re-derived `comparison`. COMPARE-5 owns the swap wiring (controller +
  actions/slots), not `difference.dart`.
- **For CVD-3 (AC-9 speak whole comparison):** reuse the exposed
  `comparison.lightness/saturation/hue` (and DIFF-2's `.deltaE00/.verdict`) plus
  `confusionWarningMessage` for the spoken output — do not re-derive any line.
- **Verification commands** (export PATH first —
  `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
  `flutter test --coverage` · `dart run tool/coverage_gate.dart main` ·
  integration on the iOS sim under the verify lock:
  `flutter test integration_test/` (default) and
  `flutter test integration_test/comparison_test.dart --dart-define=BS03_RUN_PENDING=true`
  (run-pending), `-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gaps:** AC-3 (COMPARE-5), AC-9 (CVD-3) still pending — the only two red
  at the run-pending baseline. Carry-over bs-01 const-ctor coverage flake — re-run
  `--coverage` once if an untouched file flags.
- **Next:** COMPARE-5 (AC-3 swap) and CVD-3 (AC-9 speak) are both startable now
  (DIFF-3 and CVD-2 are done). They may share `actions_bar.dart`; run in separate
  sessions. Then SIGNOFF-1.
