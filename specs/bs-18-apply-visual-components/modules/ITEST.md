# Module ITEST — acceptance integration suite

**Status:** ✅ Done — all 5 ITEST phases complete; G-2 approved 2026-10-19 (Matt Quirk). Behavior stage open.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/visual_application/` (harness, fixtures, one pending test per AC); the `BS18_RUN_PENDING` pending mechanism.
**Depends on:** CHROME-2 (the shell under test) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 5.35M | 13m (13m) |
| ITEST-2 | acceptance-tests | AC-1,2,3,4,5 | ✅ Done | 8.78M | 22m (22m) |
| ITEST-3 | acceptance-tests | AC-6,7,8,9,10 | ✅ Done | 11.88M | 35m (35m) |
| ITEST-4 | acceptance-tests | AC-11,12,13,14 | ✅ Done | 6.41M | 22m (22m) |
| ITEST-5 | test-review | — (G-2) | ✅ Done | 1.08M | 2m 43s (2m 43s) |

## Interface reconciliation

- **Boundary:** each screen is pumped through its production builder (`CaptureScreen`, `ReadoutScreen`, `ComparisonScreen`, `RecipesScreen`, `PaletteScreen`, `AppShell`, `SettingsScreen`, onboarding steps) over in-memory fixture sources (the sibling features' fakes). Real rendering, real theme, real wrappers; no network/camera/platform channels.
- **Observation points:** the pumped widget tree — `find.byType(<wrapper>)` and `find.byType(<superseded ad-hoc widget>)` scoped to the control under test; the CHROME-2 shell keys (`bottomNavKey`, destination keys, active-marker key); `SwatchCaption.captionKey`; warning render rects (`tester.getRect`); and, for AC-13/AC-14, the reused bs-11 checks and bs-17 source-scan.
- **Pending gate:** a pending test is guarded by `BS18_RUN_PENDING` (default run skips it green; `--dart-define=BS18_RUN_PENDING=true` runs it for the red baseline). Un-pending = deleting one guard, done by the owning behavior phase.

## Open gates

G-2 (ITEST-5's review) blocks every behavior phase. **✅ Resolved 2026-10-19 19:48 EDT: approved — Matt Quirk** (14 pending acceptance tests approved as-is; 6 non-blocking reviewer items carry to their owning phases — notably AC-6 cross-screen ownership for FLOW-1).

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

### Result — ITEST-3 ✅ Done (2026-10-19)

- **Landed:** `integration_test/visual_application/{compare,recipes,palette,projects,config}_test.dart` — five *pending* `acTestWidgets` tests (AC-6..AC-10) over the ITEST-1 harness + the `expectPill`/`subtreeHas` helpers; **extended `harness.dart`** with the CFG pumps `pumpDisplaySettings` (opens the panel through the real E2 chrome entry, seeded from the fixture's deutan-sim snapshot) and `pumpOnboarding` (pushes the host via `router.toSelfAssessment()`, store + `InactivePeerTransport` wired for determinism), two new `VisualScreen` values, and the shared component assertions. No `lib/` touched (presentation ACs assert structure over the real assembled app).
- **Default run** (per file — the `flutter-tester` lane flakes relaunching across entrypoints, so each `*_test.dart` runs alone): `smoke` 13✅/1 skip; `compare`/`recipes`/`palette`/`projects`/`config` all skipped (AC-6..10 pending) → **suite green with the five pending**. `dart analyze integration_test/visual_application/` → No issues.
- **Red baseline** (`--dart-define=BS18_RUN_PENDING=true`, per file) — recorded in the Red baseline table: AC-6 fails at `expectPill(compareAKey)`; AC-7 at the recipe-row `SurfaceCard` ancestor; AC-8 at `expectPill(addPaintKey)`; AC-9 at the project-entry `SurfaceCard` ancestor; AC-10 at `expectPill(simOff)`. Each fails on a Then for its catalogued reason; every GIVEN passes (the CFG pumps, the Projects view-switch and the readout/compare anchors all render). `pumpOnboarding`'s step render verified by a throwaway probe (deleted).
- **Grade gate PASS** (independent grader, did not author; grid `../behavior-test-completeness-bs-18-apply-visual-components.md`): straight **A** = AC-6, AC-9, AC-10; **A-core / B pending** = AC-7→FLOW-2, AC-8→ORG-1; **plain-B = 0**. Augmentations: TestAC07→FLOW-2 **added**; TestAC08→ORG-1 **confirmed**.
- **Coverage gate** `dart run tool/coverage_gate.dart e85c4c9` → **PASS** (no touched `lib/**`; integration-test-only phase, unit suite not re-run). **Fix passes: 0/3** (first full red-baseline run failed each test at its intended assertion; four pre-run analyzer fixes: a const-default on the CFG pump + three unused `material` imports).
- **G-2 review items surfaced (see Checkpoint):** AC-6 cross-screen ownership; AC-6 A/B-outline weight; AC-7 "ranked by" note absence; AC-9 create-vs-export.

### Checkpoint / Handoff — after ITEST-3

- **Authored anchors (behavior phases satisfy these):** AC-6 reads readout `ActionsBar.{compareAKey,compareBKey,recipesKey}` as `PillButton`s (recipes = primary/`FilledButton`) + Compare `DifferenceRegion.regionKey`/`StatementRegion.regionKey` → `SurfaceCard` ancestor + a compare `SpeakButton`. AC-7 reads `RecipeListRegion.{regionKey,cardKey(0)}` → `SurfaceCard` ancestor, no Material `Card` under the region, no ad-hoc `TextButton` in a card, a `SpeakButton`|`PillButton` action. AC-8 reads `PaintListRegion.regionKey` + `PaintRow.rowKeyFor(id)`×3 each with a `ProvenanceBadge`, `expectPill(PaintListRegion.addPaintKey)`. AC-9 switches to the Projects view (`find.text('Projects')` under `PaletteScreen.viewSelectorKey`) → `ProjectsRegion.projectRowKey('proj-harbor')` → `SurfaceCard` ancestor + `expectPill(openProjectKey/exportKey)`. AC-10 `pumpDisplaySettings` → `expectPill(simulationOptionKey(null|deutan))`; `pumpOnboarding` → `LightingStep.regionKey` → `SurfaceCard` ancestor + `expectPill(LightingStep.continueKey/OnboardingScreen.seeResultKey)`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/`gtimeout`; **run each `*_test.dart` individually**): default `flutter test -d flutter-tester integration_test/visual_application/<file>_test.dart`; red baseline add `--dart-define=BS18_RUN_PENDING=true`; analyze `dart analyze integration_test/visual_application/`; gate `dart run tool/coverage_gate.dart <base>`.
- **G-2 REVIEW ITEMS for ITEST-5 (put these in the packet):**
  1. **AC-6 cross-screen ownership.** "Compare as A/B" + "Find mixing recipes" physically live in `lib/readout/actions_bar.dart` (READ module), but FLOW-1 (AC-6) owns `lib/compare/**`. No current phase swaps those readout actions. Reviewer decides: expand FLOW-1's file ownership to that file, reassign to READ-3, or add an augmentation — else AC-6 can't be un-pended green by FLOW-1 alone.
  2. **AC-6 A/B outline weight.** The test asserts A/B are pills + recipes is primary, but not that A/B are specifically *secondary/outline* (spec says outline). Cheap strengthening available (`expect(subtreeHas<FilledButton>(..compareA/B), isFalse)`); grader held AC-6 to A without it.
  3. **AC-7 "ranked by" note.** No such note exists in `lib/`; whether FLOW-2 introduces one is a scope decision (augmentation row added, owned by FLOW-2).
  4. **AC-9 create-vs-export.** `projects_region.dart` has Open + Export, no "create project" control; the test asserts the two real actions become pills.
- **Known gaps / next:** ITEST-4 (AC-11..14) is the last AC-test phase; both it and ITEST-3 block ITEST-5 (the G-2 review). ITEST-4 may find AC-11/AC-14 green at baseline (control-case rows per its tasks).

## Phase ITEST-4 — acceptance-tests: AC-11..14 (pending) + red baseline

- **Kind:** acceptance-tests · **Target AC:** AC-11, AC-12, AC-13, AC-14 (all pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5 · **Parallel:** ITEST-2, ITEST-3
- **Files:** `integration_test/visual_application/guards_test.dart` (+ reuse bs-11 checks / bs-17 source-scan).
- **Tasks:** author `TestAC11_SingleTheme`, `TestAC12_SwatchCaption`, `TestAC13_A11yPreserved`, `TestAC14_NoHardcodedPalette`. Note AC-11/AC-14 may be green at baseline (control-case rows) — add the discriminating control so they still earn their grade.
- **Exit criteria:** suite green with the four pending (or control-case-justified); red baseline recorded; grade gate passed.

### Result — ITEST-4 ✅ Done (2026-10-19)

- **Landed:** `integration_test/visual_application/guards_test.dart` — four *pending* `acTestWidgets` tests (AC-11..AC-14) over the ITEST-1 harness, **reusing the shipped bs-17 source-scan** (`residualPaletteLiterals`, `../design_system_source_scan.dart`) and **bs-11 conformance check** (`runConformanceCheck`, `../conformance/conformance_check.dart`) rather than re-deriving them. No `lib/` touched (cross-cutting guards assert structure over the real assembled app). A small `_roster` helper (all 7 pumpable screens) + a `_schemeOverridingThemes` helper + a `_fixtureApp` control-builder are local to the file.
- **Ground truth (ITEST-4 probes, deleted):** all four invariants ALREADY HOLD at baseline — `lib/` scan residual **0**; every roster screen installs exactly **one** `MaterialApp` with **no** scheme-overriding `Theme`; every ColorChip-bearing reachable screen (Readout/Capture/Palette/Display) carries exactly **one** `SwatchCaption`; every screen passes `tapTarget48` + `contrastAA`. So all four are **green at baseline** (the AC-1 precedent), each strengthened with a discriminating **control** (G5) so the guard is non-vacuous.
- **Default run** (per file): `guards` → **4 skipped** (AC-11..14 pending) → suite green. `dart analyze integration_test/visual_application/guards_test.dart` → No issues.
- **Red baseline** (`--dart-define=BS18_RUN_PENDING=true`, per file) — recorded in the Red baseline table: **4 pass / 0 skip — green at baseline**. Each control's discriminating assertion fires inside the passing test (`…pass isFalse` / `findsNothing` / `findsNWidgets(2)` / `hasLength(1)`), so a non-discriminating control would have turned its test red — the controls provably fire.
- **Grade gate PASS** (independent grader, did not author; grid `../behavior-test-completeness-bs-18-apply-visual-components.md`): **straight A = AC-11, AC-12, AC-13, AC-14**; A-core/B pending = 0; **plain-B = 0**. No fix owed this phase.
- **Augmentations:** the three pre-seeded ITEST-4 augmentation rows (TestAC11/TestAC12/TestAC14 controls) are **SATISFIED** by the authored controls + dynamic full-roster sweep — **none owed forward**; owners GUARD-1/2/3 just un-pend (delete the `pending.dart` row) and keep green.
- **Coverage gate** `dart run tool/coverage_gate.dart 8fa1e0f` → **PASS** (no touched `lib/**`; integration-test-only phase, unit suite not re-run — ITEST-2/3 precedent). **Fix passes: 0/3** (first full red-baseline run green; one post-grade cleanup — removed a tautological `expect(h.colorScheme, scheme)` (`expect(x,x)`) in AC-11 per the grader's non-blocking note, re-ran 4✅/0; discrimination lives in the one-MaterialApp + scheme-override checks + the control, so the removal neither strengthens nor weakens the test).
- **G-2 review item surfaced:** all four guards are green-at-baseline — the reviewer may choose to **un-pend them now** (edit `pending.dart` + the AC-coverage status) for continuous regression cover during the behaviour phases, instead of at GUARD-1/2/3.

### Checkpoint / Handoff — after ITEST-4

- **Authored anchors (behaviour phases satisfy these):** **AC-11** (GUARD-2) — exactly one `MaterialApp` per screen + `_schemeOverridingThemes` empty across the 7-screen roster; control = a nested `MaterialApp`+scheme that flags both. **AC-12** (GUARD-1) — exactly one `SwatchCaption.captionKey` on each `ColorChip`-bearing roster screen (dynamic sweep, `containsAll{Readout,Capture,Palette}` floor); controls = an uncaptioned chip (`findsNothing`) + two captions in distinct parents (`findsNWidgets(2)`). **AC-13** (GUARD-3) — `runConformanceCheck` `tapTarget48.pass && contrastAA.pass` on each screen; controls = a 24dp target + ~1.6:1 text, each flagged. **AC-14** (GUARD-2) — `residualPaletteLiterals(['lib'], exempt {kThemeAuthorityFile, ...kCaptureDeviceLiteralFiles})` empty; control = a planted `Color(0x..)` temp file flagged, comment/string masked. Each owner just un-pends + keeps green (the controls + sweeps already discriminate).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/`gtimeout`; **run each `*_test.dart` individually**): default `flutter test -d flutter-tester integration_test/visual_application/guards_test.dart`; red baseline add `--dart-define=BS18_RUN_PENDING=true`; analyze `dart analyze integration_test/visual_application/`; gate `dart run tool/coverage_gate.dart <base>`.
- **Known gaps / next:** ITEST-4 was the **last AC-test phase**. All of ITEST-2, ITEST-3, ITEST-4 are done → **ITEST-5 (test review, gate G-2) is now startable**; G-2 blocks every behaviour phase. The packet must carry the ITEST-2/3 review items PLUS the ITEST-4 item (all four guards green-at-baseline; option to un-pend now).

## Phase ITEST-5 — test-review

- **Kind:** test-review · **Target AC:** — · **Depends on:** ITEST-2, ITEST-3, ITEST-4 · **Blocks:** every behavior phase
- **Tasks:** assemble the test-review packet (catalogue vs authored tests, red baseline, grades, augmentations); route to the human.
- **Exit criteria:** G-2 recorded (approved, or changes → `ITEST` change phases + a fresh review).

### Status — ✅ Done · G-2 approved (2026-10-19, Matt Quirk)

Packet assembled below, routed to the human, **approved as-is**. The 14 pending acceptance tests are the approved governing suite for every behavior phase; the 6 reviewer decisions below are non-blocking and carry to their owning phases (headline: AC-6 cross-screen ownership → FLOW-1). The behavior stage (CHROME-3/4, READ, FLOW, ORG, CFG, GUARD) is now open.

---

## G-2 Test-review packet

**What this gate approves:** the 14 pending acceptance tests that will govern every behavior phase of bs-18. This is a *presentation-application* feature (swap ad-hoc widgets for finished bs-17 wrappers; build the nav shell; fix the Capture warning overlap) — no behavior, data, numbers or semantics change. The tests therefore assert **structure**: the design-system wrapper is **present** AND the superseded ad-hoc widget is **absent** for each named control/region (D-3).

### Suite at a glance

- **Where:** `integration_test/visual_application/` — `harness.dart` + `fixtures.dart` + `smoke_test.dart` (ITEST-1) and one `*_test.dart` per AC group: `chrome` (AC-1/2), `capture` (AC-3/4), `readout` (AC-5), `compare` (AC-6), `recipes` (AC-7), `palette` (AC-8), `projects` (AC-9), `config` (AC-10), `guards` (AC-11..14).
- **How it runs** (`flutter-tester` lane; **run each `*_test.dart` in its own `flutter test` invocation** — the lane flakes relaunching across entrypoints): default `flutter test -d flutter-tester integration_test/visual_application/<file>_test.dart` skips the pending tests green; red baseline adds `--dart-define=BS18_RUN_PENDING=true`. Un-pending = deleting one `pending.dart` guard, done by the owning behavior phase.
- **What's real / faked:** every screen is pumped through its production builder (`buildApp`) over in-memory fixture sources; real rendering, real theme, real wrappers. Only `FakeSpeech`/`FakeHaptics`/`FakeCaptureSource` are faked. No network/camera/platform channels.
- **Catalogue vs. authored:** all 14 catalogue entries (master plan *Test catalogue*) are authored 1:1 as named `acTestWidgets` tests; no catalogue row is unauthored and no test lacks a catalogue row.

### Grade grid

- **Path:** [`../behavior-test-completeness-bs-18-apply-visual-components.md`](../behavior-test-completeness-bs-18-apply-visual-components.md) (independent grader, did not author).
- **Counts (whole suite):** straight **A = 10** (AC-1, 2, 4, 6, 9, 10, 11, 12, 13, 14); **A-core / B pending `<phase>` = 4** (AC-3→READ-1, AC-5→READ-3, AC-7→FLOW-2, AC-8→ORG-1 — each a legitimate later-only limit with an augmentation row); **plain-B = 0** (nothing handed to the reviewer as an "optional fix").

### Per-AC summary (test · Given checks · When · Then / Rejects · baseline · grade · owner)

| AC | Test | Given (checked via public surface) | When | Then — key assertions · Rejects | Baseline (run-pending) | Grade | Un-pended by |
|---|---|---|---|---|---|---|---|
| AC-1 | `TestAC01_BottomNav` | app pumped on default route; nav shell present | chrome renders | 4 destination keys (Capture/Compare/Recipes/Palette); non-colour active marker; nav colours == `surfaceContainerLowest`/`outline` tokens · *Rejects:* colour-only active state, a missing destination | **green** (CHROME-2 nav already conformant) | A | CHROME-3 |
| AC-2 | `TestAC02_TopBar` | app pumped on each of 5 primary surfaces | screen renders | `AppTopBar` present; title family == installed `titleLarge` (Atkinson); theme-toggle present · *Rejects:* ad-hoc header without toggle, hardcoded title style | FAIL — no `AppTopBar` mounted | A | CHROME-4 |
| AC-3 | `TestAC03_CaptureControls` | Capture pumped with `aReading`; shutter/torch/import finders | controls render | shutter on `captureKey` renders ~88×88 round; actions are `PillButton`; torch/import not `TextButton` · *Rejects:* an un-swapped `ElevatedButton`/`TextButton` action | FAIL — shutter 74.3px, ad-hoc `TextButton` | A-core / **B pending READ-1** | READ-1 |
| AC-4 | `TestAC04_CaptureWarnings` | Capture pumped with ≥2 active warnings @ 200% text scale | warnings render | each banner distinct; render rects do **not** intersect (`!rectA.overlaps(rectB)`) · *Rejects:* same-origin `Positioned` banners that intersect (the current bug) | FAIL — stability∩lock rects overlap | A | READ-2 |
| AC-5 | `TestAC05_Readout` | Readout pumped with `aReading`; region finders | reading renders | value/name/space regions each have `SurfaceCard` ancestor; each eyebrow `MonoLabel`; one `SpeakButton` · *Rejects:* bare `Column`s; speak as `IconButton` | FAIL — no `SurfaceCard` ancestor | A-core / **B pending READ-3** | READ-3 |
| AC-6 | `TestAC06_Compare` | Compare pumped with `aComparison`; control finders | comparison renders | A & B are `PillButton`, "Find recipes" primary (`FilledButton`); diff & statement under `SurfaceCard`; a `SpeakButton` · *Rejects:* one of A/B/find left ad-hoc; rows not carded | FAIL — readout "Compare as A" is bare `OutlinedButton` | A | FLOW-1 |
| AC-7 | `TestAC07_Recipes` | Recipes pumped with `recipesForTarget`; recipe & note finders | list renders | each recipe row under `SurfaceCard`; no Material `Card`/ad-hoc `TextButton` under the region; a pill/speak action · *Rejects:* ad-hoc `Card`/`ListTile` rows | FAIL — rows are Material `Card`s | A-core / **B pending FLOW-2** | FLOW-2 |
| AC-8 | `TestAC08_Palette` | Palette pumped with `aPalette`; row/badge/add finders | list renders | 3 paint rows each with a `ProvenanceBadge`; add-from-dataset is a `PillButton` · *Rejects:* a row without `ProvenanceBadge`; add left ad-hoc | FAIL — add is bare `TextButton` | A-core / **B pending ORG-1** | ORG-1 |
| AC-9 | `TestAC09_Projects` | Palette view switched to Projects; `aProject` row present | list renders | each project entry under `SurfaceCard`; open/export are `PillButton` · *Rejects:* bare `GestureDetector`/`Column` entries; ad-hoc actions | FAIL — entries bare, no `SurfaceCard` | A | ORG-2 |
| AC-10 | `TestAC10_DisplayOnboarding` | `pumpDisplaySettings` (real chrome entry) + `pumpOnboarding` (pushed host) | screens render | sim options are `PillButton`; onboarding step content under `SurfaceCard`; next/back pills · *Rejects:* a setting/onboarding nav left `TextButton`/`ElevatedButton` | FAIL — sim options bare `TextButton` | A | CFG-1 |
| AC-11 | `TestAC11_SingleTheme` | 7-screen roster each pumped on the installed theme | it renders | exactly one `MaterialApp`; every `Theme.colorScheme` == installed scheme, per screen · **control:** nested `MaterialApp`+scheme flags both checks · *Rejects:* a screen nesting its own app/theme | **green** (invariant already holds) | A | GUARD-2 |
| AC-12 | `TestAC12_SwatchCaption` | full-roster dynamic sweep; a screen "bears a swatch" iff it renders a `ColorChip` (floor: Readout/Capture/Palette) | it renders | exactly one `SwatchCaption` per swatch-bearer · **controls:** uncaptioned chip `findsNothing` + two captions `findsNWidgets(2)` · *Rejects:* zero or duplicate captions | **green** (3 screens already captioned) | A | GUARD-1 |
| AC-13 | `TestAC13_A11yPreserved` | 7-screen roster; reused bs-11 `runConformanceCheck` per screen | measured | `tapTarget48.pass && contrastAA.pass` per screen · **controls:** a 24dp target and ~1.6:1 text each flagged · *Rejects:* a swap dropping a target <48dp or a sub-AA pairing | **green** (all pass app-wide) | A | GUARD-3 |
| AC-14 | `TestAC14_NoHardcodedPalette` | `lib/` scanned via reused bs-17 `residualPaletteLiterals` + the bs-17 AC-14 exclusion set | scan runs | residual == 0 · **control:** a planted `Color(0x..)` temp file returns exactly 1 hit with the right rule tag (comment/string masked) · *Rejects:* a screen re-introducing a palette literal | **green** (`lib/` clean) | A | GUARD-2 |

### Red baseline summary

- **9 FAIL (fail on a Then for the catalogued reason):** AC-2, 3, 4, 5, 6, 7, 8, 9, 10.
- **5 green at baseline (invariant/structure already holds on the live tree):** AC-1 (nav shipped by CHROME-2) + the four guards AC-11/12/13/14 — each strengthened with a proven discriminating **control** (G5) so the test is non-vacuous. Full per-test table above in *Red baseline*.
- No compile error, panic or harness error at baseline; every GIVEN renders (CFG pumps, Projects view-switch, readout/compare anchors all pass).

### Augmentations scheduled (closed by behavior phases)

| AC test | Limited because | Closed by | Add |
|---|---|---|---|
| `TestAC03` | present/size checks don't sweep *every* capture control (dismiss/lock/calibrate/… all `TextButton` today) | READ-1 | "superseded ad-hoc widget absent" for every capture control |
| `TestAC05` | doesn't yet assert the old `Card`/plain speak `IconButton` ABSENT (a partial swap carrying both would pass) | READ-3 | "old Card / plain speak IconButton absent" for all readout regions |
| `TestAC07` | no "ranked by" note exists in `lib/` yet; out-of-gamut note vacuous on the reachable-target pump | FLOW-2 | assert ranked-by + out-of-gamut notes render in `MonoLabel`/body style |
| `TestAC08` | `paint_list_region.dart` already partly swapped | ORG-1 | per-row `ProvenanceBadge` present + "old add button absent" |
| `TestAC11` / `TestAC12` / `TestAC14` | — | — | **✅ already satisfied at ITEST-4** (controls + dynamic sweep); GUARD-1/2/3 only un-pend + keep green — none owed forward |

### Decisions for the reviewer (none block approval; each is a scope/strengthening call)

1. **Un-pend the 5 green-at-baseline tests now?** AC-1 + AC-11/12/13/14 already hold on the live tree. The reviewer may un-pend any of them *now* for continuous regression cover during the behavior phases (editing `pending.dart` + the AC-coverage status), rather than leaving them to their owning phase. Default plan: owner un-pends.
2. **AC-6 cross-screen ownership (headline).** "Compare as A/B" + "Find mixing recipes" physically live in `lib/readout/actions_bar.dart` (READ module), but FLOW-1 (AC-6) owns `lib/compare/**`, and no current phase swaps those readout actions. Decide: expand FLOW-1's file ownership to that file, reassign to READ-3, or add an augmentation — else AC-6 can't be un-pended green by FLOW-1 alone.
3. **AC-6 A/B outline weight.** The test asserts A/B are pills + recipes is primary, but not that A/B are specifically *secondary/outline* (spec says outline). Cheap strengthening available; grader held AC-6 to A without it.
4. **AC-7 "ranked by" note.** No such note exists in `lib/`; whether FLOW-2 introduces one is a scope decision (augmentation row already owns it).
5. **AC-9 create-vs-export.** `projects_region.dart` has Open + Export, no "create project" control; the test asserts the two real actions become pills (the catalogue said "open/create").
6. **AC-11 tautological line (non-blocking cleanup).** `TestAC11` carries one dead `expect(h.colorScheme, scheme)` assert (`expect(x,x)`); discrimination lives in the one-`MaterialApp` + scheme-override checks (both proven by the control). Grader recommends dropping it; does not lower the grade.

### Result — ITEST-5 ⏸ Awaiting review (2026-10-19)

- **Landed:** this G-2 test-review packet (above) — the catalogue↔authored 1:1 check, the suite-at-a-glance, the per-AC Given/When/Then/Rejects table with baseline+grade+owner, the red-baseline summary (9 FAIL / 5 green-at-baseline-with-controls), the augmentation schedule, the grid path + counts (A=10, A-core/B-pending=4, plain-B=0), and 6 reviewer decisions (none gate-blocking). No `lib/`, no tests and no gate commands run (a test-review phase assembles and routes; the suites were proven by ITEST-1..4). Phase set `⏸ Awaiting review`; G-2 set *awaiting decision* in both plans.
- **Preconditions met:** ITEST-2/3/4 all ✅ Done; whole-suite grade grid all **A** or **A-core / B pending `<phase>`** with an augmentation row — **zero plain-B** to fix first.
- **Fix passes:** n/a (no implementation).
- **Routed to the human.** Decision command: `/feature-next-phase --gate bs-18-apply-visual-components G-2 approved | "<changes>"`. "Changes requested" turns each item into an `ITEST` change phase before the behavior stage, then a fresh review.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_BottomNav | **PASS — green at baseline** | — (CHROME-2 nav already conformant: 4 destinations, non-colour active marker, theme-token colours) | CHROME-3 (un-pends + keeps green) | A |
| AC-2 | TestAC02_TopBar | FAIL | `find.byType(AppTopBar)` findsNothing — no shared top bar mounted on any of the 5 primary surfaces | CHROME-4 | A |
| AC-3 | TestAC03_CaptureControls | FAIL | shutter width 74.3px ≠ ~88 (capture action is the ad-hoc `TextButton`, no `PillButton`) | READ-1 | A-core / B pending READ-1 |
| AC-4 | TestAC04_CaptureWarnings | FAIL | stability banner `Rect(8,64,179,104)` overlaps lock banner `Rect(8,88,259,128)` @ 200% text scale | READ-2 | A |
| AC-5 | TestAC05_Readout | FAIL | colour-name region has no `SurfaceCard` ancestor (regions bare Padding/Column; no mono eyebrow; speak is `OutlinedButton`) | READ-3 | A-core / B pending READ-3 |
| AC-6 | TestAC06_Compare | FAIL | `expectPill(compareAKey)` false — readout "Compare as A" is a bare `OutlinedButton`, no `PillButton` (GIVENs pass: compareA/B/recipes present on the readout; diff/statement present on Compare) | FLOW-1 | A |
| AC-7 | TestAC07_Recipes | FAIL | "the recipe row sits inside a SurfaceCard" — 0 `SurfaceCard` ancestors (recipe rows are Material `Card`s today) | FLOW-2 | A-core / B pending FLOW-2 |
| AC-8 | TestAC08_Palette | FAIL | `expectPill(addPaintKey)` false — add-from-dataset is a bare `TextButton` (rows + per-row `ProvenanceBadge` already present — partly swapped) | ORG-1 | A-core / B pending ORG-1 |
| AC-9 | TestAC09_Projects | FAIL | "the project entry sits inside a SurfaceCard" — entries are bare `GestureDetector`/`Column` (view-switch to Projects + project row GIVENs pass) | ORG-2 | A |
| AC-10 | TestAC10_DisplayOnboarding | FAIL | `expectPill(simOff)` false — the simulation options are bare `TextButton`s (Display panel opens via `pumpDisplaySettings`; `pumpOnboarding` step render verified by probe) | CFG-1 | A |
| AC-11 | TestAC11_SingleTheme | **PASS — green at baseline** | — (1 MaterialApp + no scheme-overriding Theme on all 7 roster screens; control: nested app+theme flags both) | GUARD-2 (un-pends + keeps green) | A |
| AC-12 | TestAC12_SwatchCaption | **PASS — green at baseline** | — (Readout/Capture/Palette/Display already captioned; control: uncaptioned chip `findsNothing` + two-caption `findsNWidgets(2)`) | GUARD-1 (un-pends + keeps green) | A |
| AC-13 | TestAC13_A11yPreserved | **PASS — green at baseline** | — (every roster screen passes 48dp + AA; control: 24dp target + ~1.6:1 text each flagged) | GUARD-3 (un-pends + keeps green) | A |
| AC-14 | TestAC14_NoHardcodedPalette | **PASS — green at baseline** | — (`lib/` residual 0 outside bs-17 exclusions; control: planted `Color(0x..)` temp file flagged, comment/string masked) | GUARD-2 (un-pends + keeps green) | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC03 | present/size checks catch the named Rejects but don't sweep every capture control (dismiss/lock/calibrate/value-only/radius/sample/send all `TextButton` today) | READ-1 | "superseded ad-hoc widget absent" for every capture control | ✅ Closed READ-1 (2026-10-20) — exhaustive "superseded ad-hoc widget absent" sweep over every capture control + `expectPill` on the six action controls; red-baselined against BASE (10 ad-hoc `TextButton`s); AC-3 re-graded straight A |
| TestAC05 | present-side checks catch the named Rejects but don't assert the superseded `Card`/plain speak `IconButton` ABSENT, so a partial swap carrying both new+old would pass | READ-3 | "old Card / plain speak IconButton absent" for all readout regions | ✅ Closed READ-3 (2026-10-20) — asserts the widget at `ActionsBar.speakKey` `isA<SpeakButton>()` + old `Card`/plain speak absent across readout regions; discriminates the pre-READ-3 tree; AC-5 re-graded straight A |
| TestAC07 | no "ranked by" note exists in `lib/` yet (grep-confirmed) and the out-of-gamut note is vacuous on the reachable-target pump, so the scenario's "notes in design-system mono/body style" clause can't discriminate now | FLOW-2 | once the ranked-by note exists + an out-of-gamut target is pumped, assert both the ranked-by and out-of-gamut notes render in `MonoLabel`/body style | ✅ Closed FLOW-2 (2026-10-20) — ranked-by `MonoLabel` + out-of-gamut `MonoLabel` (pumped via `pumpRecipes(outOfGamutTarget)`) both asserted; AC-7 re-graded straight A |
| TestAC08 | `paint_list_region.dart` is already partly swapped | ORG-1 | per-row `ProvenanceBadge` present + "old add button absent" | ✅ Closed ORG-1 — "old add button absent" sweep added, red-baselined against BASE; AC-8 re-graded straight A |
| TestAC12 | `SwatchCaption` already on 3 screens | GUARD-1 | enumerate ALL swatch-bearing screens in the sweep | ✅ Satisfied at ITEST-4 — the test dynamically sweeps every `ColorChip`-bearing roster screen (auto-covers any new swatch screen a swap adds) + a missing/duplicate-caption control; GUARD-1 just un-pends + keeps green |
| TestAC11 | no screen nests a Theme today, so the check may pass before any work | GUARD-2 | a control case (a deliberately-nested Theme fixture the check catches) | ✅ Satisfied at ITEST-4 — nested `MaterialApp`+scheme control flags both the one-MaterialApp and scheme-override checks; GUARD-2 just un-pends + keeps green |
| TestAC14 | source-scan is clean today | GUARD-2 | a control case (a planted literal the scan catches) | ✅ Satisfied at ITEST-4 — planted `Color(0x..)` temp-file control flagged (comment/string masked); GUARD-2 just un-pends + keeps green |
