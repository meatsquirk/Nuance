# Module FLOW — Compare + Recipes screen swaps

**Status:** In progress — FLOW-1 ✅ (AC-6 straight A); next FLOW-2 (AC-7).
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/compare/**`, `lib/recipes/**` (screen/region/control widgets only — not controllers, sources, read endpoints or `recipes/engine/**`).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| FLOW-1 | behavior | AC-6 | ✅ Done | 10.99M | 25m 25s (25m 25s) |
| FLOW-2 | behavior | AC-7 | ⬜ Todo | | |

## Interface reconciliation

Consumes the bs-17 wrappers. Changes only the Compare/Recipes control and region widgets; comparison and
recipe controllers, the difference/statement/confusion logic, `recipes/engine/**` and the read endpoints are
frozen (D-2). Ranked-by / out-of-gamut copy is unchanged — only its text style moves to the design system.

## Open gates

G-2 blocks both phases. FLOW-1 and FLOW-2 touch disjoint dirs (`lib/compare` vs `lib/recipes`) and may run in
either order or in parallel once G-2 is open.

## Phase FLOW-1 — behavior: Compare (AC-6)

- **Kind:** behavior
- **Target AC:** AC-6 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/compare/actions_bar.dart`, `slots_region.dart`, `difference_region.dart`, `statement_region.dart`, `confusion_region.dart`, `comparison_screen.dart`.
- **Tasks:**
  1. "Compare as A"/"Compare as B" → `PillButton.secondary`; "Find mixing recipes" → `PillButton.primary`; the speak action → `SpeakButton`.
  2. Wrap the difference and statement regions in `SurfaceCard`; remove the superseded `OutlinedButton`/`TextButton`/`Card`.
- **Exit criteria:** `lib/compare` suite + bs-03 relative-comparison suite green.
- **Acceptance gate:** un-pend AC-6; `TestAC06_Compare` green with earlier ACs; sibling suites green.

### Result — FLOW-1 (✅ Done)

- **Landed (production, presentation-only, D-2):** `lib/readout/actions_bar.dart` — "Compare as A/B" → `PillButton.secondary` (outline), "Find mixing recipes" → `PillButton.primary` (ink-filled, wraps `FilledButton`); keys stay on the pills so every sibling that drives these handoffs by key is unchanged; acknowledge/justCaptured untouched (resolves the headline **G-2 AC-6 cross-screen ownership** item — the three named actions physically live in the READ module's `actions_bar.dart`). `lib/compare/comparison_screen.dart` — difference + statement regions each wrapped in a `SurfaceCard` ancestor (new `_carded` helper, region keys kept; no mono eyebrow, the regions carry their own heading); "Speak whole comparison" moved to the screen's always-visible `Scaffold.floatingActionButton` as a `SpeakButton` keyed `ComparisonActionsBar.speakKey`, rebuilt under a `ListenableBuilder` so it is enabled only when `state.comparison != null`. `lib/compare/actions_bar.dart` — dropped the in-bar speak `TextButton`; added the `speakKey` anchor; "Open readout for A/B" stay `TextButton` (not named in the tasks, not superseded by any named component). Regions carded **in the screen** (not in `difference_region.dart`/`statement_region.dart`) so the bs-05 Correction screen, which reuses `DifferenceRegion`, is unaffected.
- **Un-pended:** AC-6 (`integration_test/visual_application/pending.dart` row removed).
- **Augmentation made (G-2 reviewer item "AC-6 A/B outline weight"):** AC-6 body gained a loop asserting `subtreeHas<FilledButton>` is **false** for compareA/B — they are the outline/secondary pills, not the ink-filled primary. Closes the ITEST-3 ◑-on-G4; promotes `TestAC06_Compare` to a fully-specified straight-A test.
- **Tests (sibling maintenance for the swap, no behaviour weakened):** `test/compare/comparison_screen_test.dart` — the `ComparisonActionsBar` isolated group kept its open-readout-A/B TextButton tests; the speak enabled/tap tests moved to a new screen-level group that pumps the full `ComparisonScreen` and drives the `SpeakButton` FAB by `speakKey` (both enabled and disabled branches, speaks-once wiring preserved). `test/readout/readout_screen_test.dart` — the compareA/B/recipes enabled check reads `PillButton.onPressed` instead of `OutlinedButton.enabled`. `integration_test/comparison_harness.dart` `whenSpeak` taps the FAB by `ComparisonActionsBar.speakKey`. `integration_test/visual_application/smoke_test.dart` — the ITEST-1 pending-gate exemplar/seed re-pointed from AC-6 to AC-7 (AC-6 added to the un-pended set). `integration_test/visual_application/harness.dart` `pumpShell` pumps a device-tall 1000×3200 surface (reset on teardown) — the tall-surface gotcha, see Checkpoint.
- **Verification:** `flutter analyze` (6 items) clean. Unit `flutter test --coverage test/` → **1676 pass**. Coverage gate `dart run tool/coverage_gate.dart e2f1bda` → **100% on all 3 touched lib files** (`compare/actions_bar.dart`, `compare/comparison_screen.dart`, `readout/actions_bar.dart`). Acceptance (`-d flutter-tester`): `compare_test.dart` (AC-6) **1✅**. Siblings re-verified one suite at a time: bs-18 `chrome_test` 2✅, `readout_test` (AC-5) 1✅, `smoke_test` 13✅/1-skip; bs-03 `comparison_test` **26✅** (incl. AC-9 speak via the FAB); readout siblings `integration_test/readout_test` 12✅, `harness_test` 5✅, bs-11 `accessibility_test` 19✅.
- **Grade gate: PASS** (independent fresh-subagent grader; grid `../behavior-test-completeness-bs-18-apply-visual-components.md`): AC-6 **straight A** (ITEST-3 ◑-on-G4 resolved by the outline augmentation); AC-1..AC-5 carry prior **A** forward (bodies untouched); **A=6, A-core/B-pending=0, plain-B=0**.
- **Fix passes: 2/3** — both **test-infra only, lib code unchanged across both**: (1) AC-6 first run red at `find.byKey(compareAKey)` on `pumpShell` (the carded readout's actions bar is below the fold on an 800px surface) → device-tall `pumpShell`; (2) `smoke_test` red because its ITEST-1 pending-gate exemplar was AC-6, now un-pended → re-pointed to AC-7.

### Checkpoint / Handoff — after FLOW-1

- **Frozen interfaces (this phase):** readout `ActionsBar` renders compareA/B as `PillButton.secondary` and recipes as `PillButton.primary` (keys on the pills; recipes' `FilledButton` is the AC-6 primary discriminator). `ComparisonScreen` cards the difference + statement regions in `SurfaceCard`s and renders speak as a `Scaffold.floatingActionButton` `SpeakButton` keyed `ComparisonActionsBar.speakKey` (semantic label "Speak whole comparison", enabled only with a comparison). `ComparisonActionsBar` no longer renders speak (the `speakKey` const stays as the shared anchor); "Open readout for A/B" remain `TextButton`. A later phase that restyles the Compare screen must keep difference+statement under a `SurfaceCard` ancestor and keep the compare speak a `SpeakButton` at `speakKey`, or AC-6 reddens.
- **Tall-surface gotcha (test-infra):** the bs-18 `pumpShell` now pumps `Size(1000, 3200)` (reset on teardown) because the carded Readout (READ-3) is taller than the short flutter-tester surface, so its in-scroll actions bar — the compare/recipes handoffs AC-6 reads — is below the fold on an 800px surface and a lazy `ListView` never builds it. READ-3's note "pumpShell needs no change" held only for AC-5 (top-of-list cards + FAB); AC-6 is the first below-fold shell read. AC-1/AC-2 (Scaffold nav/top bar) and AC-5 (top cards + FAB) are unaffected — a taller surface only reveals more. A future FLOW/ORG/CFG phase reading below-fold shell content inherits this.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout` on macOS): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <BASE>`; AC-6 `flutter test -d flutter-tester integration_test/visual_application/compare_test.dart`; bs-03 `flutter test -d flutter-tester integration_test/comparison_test.dart` (run suites one at a time; the whole `visual_application/` dir won't launch at once under load).
- **Known gaps / next:** **FLOW-2** (AC-7, `lib/recipes/**`) is now startable — recipe rows → `SurfaceCard`, ranked-by note / out-of-gamut banner → design-system mono/body, recipe actions → `PillButton`; its exit criteria add the bs-04 mixing-recipes + bs-05 correction-loop suites. ORG-1 (AC-8) and CFG-1 (AC-10) remain startable concurrently in separate `--parallel` sessions (disjoint dirs). GUARD-1/2/3 run last. Non-blocking ◑-adjacent note (not owed): the AC-6 compare speak is asserted `speakButtons findsWidgets` rather than `findsOneWidget`/at-anchor-type — blocks no catalogue Reject.

## Phase FLOW-2 — behavior: Recipes (AC-7)

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/recipes/recipe_list_region.dart`, `target_region.dart`, `controls_region.dart`, `gamut_banner.dart`, `recipes_screen.dart`.
- **Tasks:**
  1. Render each recipe row in a `SurfaceCard`; the ranked-by note and out-of-gamut banner in the design-system mono/body styles; recipe actions as `PillButton`.
  2. Remove the ad-hoc `Card`/`ListTile`/buttons these superseded.
- **Exit criteria:** `lib/recipes` suite + bs-04 mixing-recipes + bs-05 correction-loop suites green.
- **Acceptance gate:** un-pend AC-7; `TestAC07_Recipes` green with earlier ACs; sibling suites green.
