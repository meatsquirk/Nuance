# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/visual_application/` (harness, fixtures, one pending test per AC); the `BS18_RUN_PENDING` pending mechanism.
**Depends on:** CHROME-2 (the shell under test) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| ITEST-2 | acceptance-tests | AC-1,2,3,4,5 | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-6,7,8,9,10 | ⬜ Todo | | |
| ITEST-4 | acceptance-tests | AC-11,12,13,14 | ⬜ Todo | | |
| ITEST-5 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** each screen is pumped through its production builder (`CaptureScreen`, `ReadoutScreen`, `ComparisonScreen`, `RecipesScreen`, `PaletteScreen`, `AppShell`, `SettingsScreen`, onboarding steps) over in-memory fixture sources (the sibling features' fakes). Real rendering, real theme, real wrappers; no network/camera/platform channels.
- **Observation points:** the pumped widget tree — `find.byType(<wrapper>)` and `find.byType(<superseded ad-hoc widget>)` scoped to the control under test; the CHROME-2 shell keys (`bottomNavKey`, destination keys, active-marker key); `SwatchCaption.captionKey`; warning render rects (`tester.getRect`); and, for AC-13/AC-14, the reused bs-11 checks and bs-17 source-scan.
- **Pending gate:** a pending test is guarded by `BS18_RUN_PENDING` (default run skips it green; `--dart-define=BS18_RUN_PENDING=true` runs it for the red baseline). Un-pending = deleting one guard, done by the owning behavior phase.

## Open gates

G-2 (ITEST-5's review) blocks every behavior phase.

## Phase ITEST-1 — acceptance-tests: harness

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** CHROME-2 · **Blocks:** ITEST-2, ITEST-3, ITEST-4
- **Files:** `integration_test/visual_application/harness.dart`, `fixtures.dart`, a smoke test.
- **Tasks:** build the pump harness + the six fixtures (`aReading`, `aComparison`, `recipesForTarget`, `aPalette`, `aProject`, `anOnboardingStep`); wire the `BS18_RUN_PENDING` gate; one smoke test that pumps the shell.
- **Exit criteria:** harness green; pending mechanism proven (a planted pending test is skipped by default, runs under the flag).

## Phase ITEST-2 — acceptance-tests: AC-1..5 (pending) + red baseline

- **Kind:** acceptance-tests · **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5 (all pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5 · **Parallel:** ITEST-3, ITEST-4
- **Files:** `integration_test/visual_application/{chrome,capture,readout}_test.dart`.
- **Tasks:** author `TestAC01_BottomNav`, `TestAC02_TopBar`, `TestAC03_CaptureControls`, `TestAC04_CaptureWarnings`, `TestAC05_Readout` per the catalogue (present wrapper + absent ad-hoc + the AC-4 rect-non-overlap). Record the run-pending red baseline per AC.
- **Exit criteria:** suite green with the five pending; red baseline recorded (each fails for the catalogued reason); grade gate passed.

## Phase ITEST-3 — acceptance-tests: AC-6..10 (pending) + red baseline

- **Kind:** acceptance-tests · **Target AC:** AC-6, AC-7, AC-8, AC-9, AC-10 (all pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5 · **Parallel:** ITEST-2, ITEST-4
- **Files:** `integration_test/visual_application/{compare,recipes,palette,projects,config}_test.dart`.
- **Tasks:** author `TestAC06_Compare`, `TestAC07_Recipes`, `TestAC08_Palette`, `TestAC09_Projects`, `TestAC10_DisplayOnboarding` per the catalogue; record the red baseline.
- **Exit criteria:** suite green with the five pending; red baseline recorded; grade gate passed.

## Phase ITEST-4 — acceptance-tests: AC-11..14 (pending) + red baseline

- **Kind:** acceptance-tests · **Target AC:** AC-11, AC-12, AC-13, AC-14 (all pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5 · **Parallel:** ITEST-2, ITEST-3
- **Files:** `integration_test/visual_application/guards_test.dart` (+ reuse bs-11 checks / bs-17 source-scan).
- **Tasks:** author `TestAC11_SingleTheme`, `TestAC12_SwatchCaption`, `TestAC13_A11yPreserved`, `TestAC14_NoHardcodedPalette`. Note AC-11/AC-14 may be green at baseline (control-case rows) — add the discriminating control so they still earn their grade.
- **Exit criteria:** suite green with the four pending (or control-case-justified); red baseline recorded; grade gate passed.

## Phase ITEST-5 — test-review

- **Kind:** test-review · **Target AC:** — · **Depends on:** ITEST-2, ITEST-3, ITEST-4 · **Blocks:** every behavior phase
- **Tasks:** assemble the test-review packet (catalogue vs authored tests, red baseline, grades, augmentations); route to the human.
- **Exit criteria:** G-2 recorded (approved, or changes → `ITEST` change phases + a fresh review).

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_BottomNav | _tbd_ FAIL | no bottom nav | CHROME-3 | _tbd_ |
| AC-2 | TestAC02_TopBar | _tbd_ FAIL | no shared top bar | CHROME-4 | _tbd_ |
| AC-3 | TestAC03_CaptureControls | _tbd_ FAIL | ad-hoc capture buttons | READ-1 | _tbd_ |
| AC-4 | TestAC04_CaptureWarnings | _tbd_ FAIL | warning rects overlap | READ-2 | _tbd_ |
| AC-5 | TestAC05_Readout | _tbd_ FAIL | regions not carded | READ-3 | _tbd_ |
| AC-6 | TestAC06_Compare | _tbd_ FAIL | ad-hoc A/B + rows | FLOW-1 | _tbd_ |
| AC-7 | TestAC07_Recipes | _tbd_ FAIL | recipe rows not carded | FLOW-2 | _tbd_ |
| AC-8 | TestAC08_Palette | _tbd_ FAIL | add ad-hoc / badges missing | ORG-1 | _tbd_ |
| AC-9 | TestAC09_Projects | _tbd_ FAIL | entries not carded | ORG-2 | _tbd_ |
| AC-10 | TestAC10_DisplayOnboarding | _tbd_ FAIL | ad-hoc config controls | CFG-1 | _tbd_ |
| AC-11 | TestAC11_SingleTheme | _tbd_ (may pass — control case) | — | GUARD-2 | _tbd_ |
| AC-12 | TestAC12_SwatchCaption | _tbd_ FAIL | captions only on 3 screens | GUARD-1 | _tbd_ |
| AC-13 | TestAC13_A11yPreserved | _tbd_ (guards post-swap) | — | GUARD-3 | _tbd_ |
| AC-14 | TestAC14_NoHardcodedPalette | _tbd_ (may pass — control case) | — | GUARD-2 | _tbd_ |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC03 | `capture_screen.dart` is already partly swapped, so a present-only check pre-passes | READ-1 | "superseded ad-hoc widget absent" for every capture control | ⬜ Open |
| TestAC05 | `value_region.dart` is already partly swapped | READ-3 | "old Card / plain speak IconButton absent" for all readout regions | ⬜ Open |
| TestAC08 | `paint_list_region.dart` is already partly swapped | ORG-1 | per-row `ProvenanceBadge` present + "old add button absent" | ⬜ Open |
| TestAC12 | `SwatchCaption` already on 3 screens | GUARD-1 | enumerate ALL swatch-bearing screens in the sweep | ⬜ Open |
| TestAC11 | no screen nests a Theme today, so the check may pass before any work | GUARD-2 | a control case (a deliberately-nested Theme fixture the check catches) | ⬜ Open |
| TestAC14 | source-scan is clean today | GUARD-2 | a control case (a planted literal the scan catches) | ⬜ Open |
