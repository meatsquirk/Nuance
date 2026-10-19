# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-2 done (AC-1..5 authored); next ITEST-3/4 (parallel, disjoint AC files) then ITEST-5 (test review, G-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/visual_application/` (harness, fixtures, one pending test per AC); the `BS18_RUN_PENDING` pending mechanism.
**Depends on:** CHROME-2 (the shell under test) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 5.35M | 13m (13m) |
| ITEST-2 | acceptance-tests | AC-1,2,3,4,5 | ✅ Done | 8.78M | 22m (22m) |
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

### Result — ITEST-1 ✅ Done (2026-10-19)

- **Landed:** `integration_test/visual_application/fixtures.dart` (the six catalogue fixtures `aReading`, `aComparison`, `recipesForTarget`, `aPalette`, `aProject`, `anOnboardingStep` — small immutable holders over the shipped domain types, each exposing the in-memory source its `AppDependencies` entry is wired with); `harness.dart` (`VisualScreen` roster, `VisualHarness` with the installed-theme / CHROME-2 shell anchors / bs-17 component finders / `rectOf`, and `pumpShell` + `pumpScreen` over the single `buildApp` entry, faking only `FakeSpeech`/`FakeHaptics`/`FakeCaptureSource`; re-exports the gate + fixtures + fakes + shell/top-bar + bs-17 widgets); `smoke_test.dart` (the never-pending scaffold suite). **Deleted** CHROME-1's `pending_runner_test.dart` — folded into `smoke_test.dart` (its own header said ITEST-1 replaces it).
- **Smoke / guards (`smoke_test.dart`, all non-vacuous):** a shell smoke pumping the real app onto the nav shell (4 destination keys present, exactly one non-colour active marker under the opening Capture destination, one `MaterialApp` theme) + a destination-switch test (active marker moves under each tapped item); the pending gate both directions + integrity invariants + a planted `acTestWidgets` wiring smoke; six fixture guards (named/measured reading, two distinct compare samples, reachable+out-of-gamut recipe targets over a ≥2-paint palette, ≥3 paints spanning ≥2 provenance tiers, a named project with a note, an interior onboarding step with an active-sim Display snapshot).
- **Gates:** `dart analyze integration_test/visual_application/` → No issues. Default run `flutter test -d flutter-tester integration_test/visual_application/` → **13 pass / 1 skip** (the planted pending AC-1 smoke skipped). Run-pending `--dart-define=BS18_RUN_PENDING=true` → **14 pass / 0 skip** (the planted pending test now runs) — pending mechanism proven both directions. Unit `flutter test --coverage test/` → **1668 pass**. Coverage gate `dart run tool/coverage_gate.dart d3a1c4f` → **PASS** (this phase touched no `lib/`; CHROME-2's 5 files still 100%). No grade gate at ITEST-1 (its exit criteria is harness-green + pending-proven; grades start at ITEST-2). **Fix passes: 0/3** (first full test run green; two pre-run fixes were analyzer-caught: `../fakes/` relative path, and `SampleSource` has no public `samples` getter).
- **No sibling regression risk:** added one isolated new suite dir + deleted its own CHROME-1 self-test; touched no `lib/` and no shared harness, so no sibling suite is affected (not re-run).

### Checkpoint / Handoff — after ITEST-1

- **Frozen vocabulary (ITEST-2/3/4 build on this):** `pumpShell(tester, {initialSample})` → the nav shell (AC-1/AC-2, and AC-5's Readout = the opening Capture destination's body); `pumpScreen(tester, VisualScreen.{capture,compare,recipes,palette})` → the deep-link screen via its entry flag, wired with the fixture source. `VisualHarness` exposes `installedTheme`/`colorScheme`, `bottomNav`/`activeDestination`/`navItem(d)`, `pillButtons`/`speakButtons`/`surfaceCards`/`monoLabels`/`provenanceBadges`/`swatchCaptions`, `rectOf(finder)`. The harness re-exports `pending.dart`, `fixtures.dart`, the fakes, the shell/top-bar types and the bs-17 widgets — an AC test imports only `harness.dart`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/`gtimeout`): default `flutter test -d flutter-tester integration_test/visual_application/`; red baseline add `--dart-define=BS18_RUN_PENDING=true`; analyze `dart analyze integration_test/visual_application/`; unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart d3a1c4f`.
- **Known gaps / next:** the **CFG** screens (Display settings — reached through the app chrome's settings entry, present on every route; onboarding — pushed onto the running app, no home entry) have **no `pumpScreen` case yet**: ITEST-3 extends the harness with their pump when it authors AC-10 (the `anOnboardingStep` fixture + `DisplaySettings` snapshot are ready). The whole `integration_test/visual_application/` dir launches at once on `flutter-tester` (proven here) — unlike the whole `integration_test/` root. **Next:** ITEST-2 (AC-1..5), ITEST-3 (AC-6..10), ITEST-4 (AC-11..14) run in parallel over disjoint `*_test.dart` files; each un-pends nothing (authors pending tests) and records its red baseline + grade. All three block ITEST-5 (the G-2 review).

## Phase ITEST-2 — acceptance-tests: AC-1..5 (pending) + red baseline

- **Kind:** acceptance-tests · **Target AC:** AC-1, AC-2, AC-3, AC-4, AC-5 (all pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5 · **Parallel:** ITEST-3, ITEST-4
- **Files:** `integration_test/visual_application/{chrome,capture,readout}_test.dart`.
- **Tasks:** author `TestAC01_BottomNav`, `TestAC02_TopBar`, `TestAC03_CaptureControls`, `TestAC04_CaptureWarnings`, `TestAC05_Readout` per the catalogue (present wrapper + absent ad-hoc + the AC-4 rect-non-overlap). Record the run-pending red baseline per AC.
- **Exit criteria:** suite green with the five pending; red baseline recorded (each fails for the catalogued reason); grade gate passed.

### Result — ITEST-2 ✅ Done (2026-10-19)

- **Landed:** `integration_test/visual_application/chrome_test.dart` (AC-1 `TestAC01_BottomNav`, AC-2 `TestAC02_TopBar`), `capture_test.dart` (AC-3 `TestAC03_CaptureControls`, AC-4 `TestAC04_CaptureWarnings`), `readout_test.dart` (AC-5 `TestAC05_Readout`) — five *pending* `acTestWidgets` tests over the ITEST-1 harness (`pumpShell`/`pumpScreen`, the component finders, the six fixtures). No `lib/` touched (presentation ACs assert structure over the real assembled app). Imports only `harness.dart` + the few production key-holders the anchors need (`capture_controls`/`capture_live_view`; `value_region`/`name_header`/`space_selector`).
- **Default run** (per file — the `flutter-tester` lane reliably runs the first entrypoint then flakes relaunching for the rest, so each `*_test.dart` runs in its own invocation, as the sibling suites do): `smoke` 13✅/1 skip; `chrome`/`capture`/`readout` all skipped (AC-1..5 pending) → **suite green with the five pending**. `dart analyze integration_test/visual_application/` → No issues.
- **Red baseline** (`--dart-define=BS18_RUN_PENDING=true`, per file) — recorded above:
  - **AC-1 green at baseline (PASS)** — CHROME-2 already shipped the conformant nav (4 destinations, filled-vs-outline active marker, theme-token colours). Kept **pending** (owner CHROME-3 un-pends + keeps green), consistent with this feature's all-14-pending model; the test design fully discriminates both catalogue Rejects (see grade). Surfaced for the ITEST-5 (G-2) review.
  - AC-2 FAIL — `AppTopBar` on no screen; AC-3 FAIL — shutter 74.3px≠88 (ad-hoc `TextButton`); AC-4 FAIL — stability∩lock banner rects overlap @200% text scale; AC-5 FAIL — colour-name region has no `SurfaceCard` ancestor. Each fails on a Then for its catalogued reason.
- **Grade gate PASS** (independent grader, did not author; grid `../behavior-test-completeness-bs-18-apply-visual-components.md`): straight **A** = AC-1, AC-2, AC-4; **A-core / B pending** = AC-3→READ-1, AC-5→READ-3 (both match the pre-seeded augmentation table — legitimate later-only limits); **plain-B = 0**. AC-2's omitted "back/close where needed" clause graded acceptable scoping (the 5 pumped surfaces are top-level nav roots needing no back; the CFG back/close is AC-10's).
- **Coverage gate** `dart run tool/coverage_gate.dart 438feb6` → **PASS** (no touched `lib/**`; unit baseline 1668 unchanged — an integration-test-only phase, so the unit suite was not re-run). **Fix passes: 0/3** (first full red-baseline run failed each test at its intended assertion; AC-1's green-at-baseline is the expected, recorded outcome, not a fix).
- **Augmentations confirmed:** TestAC03→READ-1 and TestAC05→READ-3 (the "ad-hoc widget absent" sweeps) confirmed open. No new augmentation owed for AC-1/AC-2/AC-4.

### Checkpoint / Handoff — after ITEST-2

- **Authored anchors (behavior phases satisfy these):** AC-1 reads `AppShell.bottomNavKey`/`activeDestinationKey` + `AppDestination.navItemKey` + the filled/outline `selectedIcon`/`icon` + `DecoratedBox` colours==`surfaceContainerLowest`/`outline`. AC-2 reads `find.byType(AppTopBar)` + `AppTopBar.titleKey` (family==installed `titleLarge`) + `AppTopBar.themeToggleKey`, over all 5 primary surfaces. AC-3 anchors the shutter on `CaptureControls.captureKey` (asserts rendered ~88×88 — **READ-1 must put the 88px round shutter on `captureKey`**), `PillButton` present, torch/import (`torchKey`/`importKey`) not `TextButton`. AC-4 anchors on `CaptureLiveView.{stabilityKey,lockIndicatorKey,accuracyKey}`, pairwise-rect non-overlap at `textScaleFactorTestValue=2.0` (**READ-2's D-6 single-vertical-run fix passes it**). AC-5 anchors `ValueRegion.regionKey`/`NameHeader.headerKey`/`SpaceSelector.selectorKey` → `SurfaceCard` ancestor + `MonoLabel` eyebrow per region + one `SpeakButton`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/`gtimeout`; **run each `*_test.dart` individually** — the lane flakes relaunching across entrypoints): default `flutter test -d flutter-tester integration_test/visual_application/<file>_test.dart`; red baseline add `--dart-define=BS18_RUN_PENDING=true`; analyze `dart analyze integration_test/visual_application/`; gate `dart run tool/coverage_gate.dart <base>`.
- **Known gaps / next:** ITEST-3 still **extends the harness** with the CFG Display/onboarding `pumpScreen` case (AC-10) — no case exists yet. ITEST-3 (AC-6..10) and ITEST-4 (AC-11..14) remain startable in parallel over their disjoint files; both block ITEST-5 (G-2). AC-1 green-at-baseline is a review item for ITEST-5: the human may choose to un-pend it now instead of at CHROME-3 (would require editing `pending.dart` + the `smoke_test.dart` seed/exemplar + the AC-coverage status).

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
| AC-1 | TestAC01_BottomNav | **PASS — green at baseline** | — (CHROME-2 nav already conformant: 4 destinations, non-colour active marker, theme-token colours) | CHROME-3 (un-pends + keeps green) | A |
| AC-2 | TestAC02_TopBar | FAIL | `find.byType(AppTopBar)` findsNothing — no shared top bar mounted on any of the 5 primary surfaces | CHROME-4 | A |
| AC-3 | TestAC03_CaptureControls | FAIL | shutter width 74.3px ≠ ~88 (capture action is the ad-hoc `TextButton`, no `PillButton`) | READ-1 | A-core / B pending READ-1 |
| AC-4 | TestAC04_CaptureWarnings | FAIL | stability banner `Rect(8,64,179,104)` overlaps lock banner `Rect(8,88,259,128)` @ 200% text scale | READ-2 | A |
| AC-5 | TestAC05_Readout | FAIL | colour-name region has no `SurfaceCard` ancestor (regions bare Padding/Column; no mono eyebrow; speak is `OutlinedButton`) | READ-3 | A-core / B pending READ-3 |
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
| TestAC03 | present/size checks catch the named Rejects but don't sweep every capture control (dismiss/lock/calibrate/value-only/radius/sample/send all `TextButton` today) | READ-1 | "superseded ad-hoc widget absent" for every capture control | ⬜ Open (confirmed ITEST-2 — graded A-core / B pending READ-1) |
| TestAC05 | present-side checks catch the named Rejects but don't assert the superseded `Card`/plain speak `IconButton` ABSENT, so a partial swap carrying both new+old would pass | READ-3 | "old Card / plain speak IconButton absent" for all readout regions | ⬜ Open (confirmed ITEST-2 — graded A-core / B pending READ-3) |
| TestAC08 | `paint_list_region.dart` is already partly swapped | ORG-1 | per-row `ProvenanceBadge` present + "old add button absent" | ⬜ Open |
| TestAC12 | `SwatchCaption` already on 3 screens | GUARD-1 | enumerate ALL swatch-bearing screens in the sweep | ⬜ Open |
| TestAC11 | no screen nests a Theme today, so the check may pass before any work | GUARD-2 | a control case (a deliberately-nested Theme fixture the check catches) | ⬜ Open |
| TestAC14 | source-scan is clean today | GUARD-2 | a control case (a planted literal the scan catches) | ⬜ Open |
