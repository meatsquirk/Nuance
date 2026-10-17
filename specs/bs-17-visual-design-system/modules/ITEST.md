# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 done; next ITEST-2 ∥ ITEST-3
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/design_system_harness.dart` (new), `integration_test/design_system_test.dart` (new), the shared source-scan helper the AC-14 rule uses (under `integration_test/conformance/` or alongside the harness).
**Depends on:** THEME-2, COMPONENTS-1 (the shells it observes) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 9,741,639 | 14m 48s |
| ITEST-2 | acceptance-tests | AC-1..AC-6 | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-7..AC-15 | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the suite pumps the production `buildApp` through the same fake capture/IO deps sibling harnesses use; the real `AppTheme`, component widgets and screens are under test. Only platform capture/IO is faked (infrastructure), never the design system itself.
- **Observation points:** `Theme.of(context)` (`ColorScheme`, `TextTheme`, component themes, `AppTheme` token accessors) for the token/shape/font ACs; `find.byType(PillButton/SpeakButton/SurfaceCard/MonoLabel/ProvenanceBadge)` + resolved render objects for component ACs; the `screenRoster` walk + the `lib/`-source-scan for AC-14; swatch subtree/semantics for AC-15.
- **Pending gate:** the project's established per-feature pending mechanism — one pending test per AC behind a `BS17_RUN_PENDING` guard; **un-pend = delete that AC's guard row** (same ritual as sibling features). Red-baseline target: `flutter test -d flutter-tester integration_test/design_system_test.dart --dart-define=BS17_RUN_PENDING=true`.

## Open gates

- **G-2:** ITEST-4 is the test review; the owner approves the acceptance tests before any behavior phase runs.

## Phase ITEST-1 — acceptance-tests: harness

- **Kind:** acceptance-tests
- **Target AC:** — (harness + pending gate + smoke test)
- **Depends on:** THEME-2, COMPONENTS-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/design_system_harness.dart`, `integration_test/design_system_test.dart`
- **Tasks:** `pumpApp` (production `buildApp` + sibling fakes); the `screenRoster` navigator; token-reading and component-finding helpers; the source-scan helper; wire the pending gate; one always-green smoke test (app pumps, theme resolves).
- **Exit criteria:** suite green with no AC tests yet; pending gate demonstrably hides pending tests by default and runs them under the flag.

### Result — ITEST-1 (2026-10-17)

- **Landed (test-only — no `lib/` change; `buildApp` is already the single D-6/D-7 entry):**
  - `integration_test/bs17/pending.dart` — the `BS17_RUN_PENDING` pending gate (sibling-mirror), seeding **all 15 ACs** → owning behaviour phase (AC-1..4 THEME-3, AC-5/6 THEME-4, AC-7/8/9 THEME-5, AC-10 COMPONENTS-2, AC-11 COMPONENTS-3, AC-12 COMPONENTS-4, AC-13 COMPONENTS-5, AC-14 APPLY-1, AC-15 APPLY-2); `acTestWidgets` / `pendingSkipReason` / `behaviorPhases`.
  - `integration_test/design_system_source_scan.dart` — the **AC-14** no-hardcoded-palette scan: `residualPaletteLiterals({roots, exempt})` flags `Color(0x…)` / `Color.fromARGB(` / `Color.fromRGBO(` in `lib/`, reusing bs-12's `maskCommentsAndStrings` (comments/strings never false-positive) + `SourceOffender`. Exempts `kThemeAuthorityFile` (`lib/app/theme.dart`, D-7) by default; `kCaptureDeviceLiteralFiles` (D-4) is the seam APPLY-1 combines.
  - `integration_test/design_system_harness.dart` — `pumpApp(tester, {screen})` boots the real app through `buildApp` on each `DesignScreen` (readout/capture/compare/recipes/palette) via its entry flag, faking only `FakeSpeech`/`FakeHaptics`/`FakeCaptureSource`; `DesignSystemHarness.installedTheme`/`colorScheme`/`textTheme` (the one chokepoint), top-level component finders (`pillButtons`/`speakButtons`/`surfaceCards`/`monoLabels`/`provenanceBadges`), `effectiveTextStyleOf` (AC-5/6), the `WarmPaper` token table (expected hexes), `screenRoster`. Re-exports the gate, fakes, scan, theme + widget surfaces.
  - `integration_test/design_system_test.dart` — **11 scaffold tests, no AC tests:** 5 never-pending smoke (each roster screen boots through `buildApp` under one `AppTheme.light()` chokepoint — scheme+textTheme identical, render quiet) + 2 pending-gate guards (map is exactly AC-1..15/real owners/all pending; hides pending by default, admits under the flag) + 2 fixture guards (roster = `DesignScreen.values`; the 7 palette roles distinct, accentInk≡surface white) + 2 source-scan guards (planted literal flagged; comment/string masked; exempt + missing-root honoured; fromARGB/fromRGBO detected).
- **Verification:** `flutter analyze integration_test/` clean. bs-17 suite `flutter test -d flutter-tester integration_test/design_system_test.dart` **11/11** default **and** **11/11** under `--dart-define=BS17_RUN_PENDING=true` (gate demonstrated; nothing toggles — no AC tests yet). Unit `flutter test --coverage` **1435/1435**; coverage gate vs `b3d6ea3` **PASS** — *no touched `lib/**` files, nothing to gate*.
- **No red baseline / grade grid this phase:** no AC tests written (they land in ITEST-2/3). Scaffold discipline met — no vacuous passes (exact-set/`hasLength` assertions, source-scan discriminated by a planted control), honest comments, deterministic (`pumpAndSettle`, no sleeps). **Fix passes: 1/3** — the WarmPaper distinctness guard (fixed to exclude accentInk≡surface white); the analyze import fixes were pre-first-run.
- **Tokens / Time:** see dashboard row (ledger `ITEST-1`).

### Checkpoint / Handoff — ITEST-1 (→ ITEST-2, ITEST-3)

- **Frozen suite surface (ITEST-2/3 import only `design_system_harness.dart`):**
  - `pumpApp(tester, {DesignScreen screen = readout})` → `DesignSystemHarness`; `screen.label` for messages; `screenRoster` = all five screens.
  - `DesignSystemHarness.installedTheme` / `.colorScheme` / `.textTheme` (the one `MaterialApp` theme) — token/font ACs read these; `effectiveTextStyleOf(tester, textFinder)` for AC-5/6 family.
  - component finders `pillButtons` / `speakButtons` / `surfaceCards` / `monoLabels` / `provenanceBadges`.
  - `WarmPaper.{background,surface,sunken,ink,muted,line,accent,accentInk}` — the expected token hexes AC-1/2/3 assert against (target values; stock scheme fails them at baseline).
  - `residualPaletteLiterals({roots, exempt})` for AC-14; un-pend = delete the AC's row in `bs17/pending.dart`.
- **Verification commands** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS; flutter-tester lane, no exclusive device):
  acceptance `flutter test -d flutter-tester integration_test/design_system_test.dart` (add `--dart-define=BS17_RUN_PENDING=true` for the red baseline); unit `flutter test --coverage`; gate `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`.
- **Known gaps:** none. The token/font/shape values are stock-derived until THEME-3/4/5 land; `WarmPaper` holds the *targets*. AC-14 will be PARTIAL at baseline (residual `lib/` literals exist → scan non-empty) and is closed by APPLY-1, which pins the D-4 exclusion set.
- **Next:** ITEST-2 (AC-1..AC-6 pending tests + red baseline) ∥ ITEST-3 (AC-7..AC-15). Both blocked only by ITEST-1 (now done); G-2 (ITEST-4) still blocks every behaviour phase.

## Phase ITEST-2 — acceptance-tests: AC-1..AC-6 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1..AC-6 (pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-3
- **Files:** `integration_test/design_system_test.dart`
- **Tasks:** one pending test per AC-1..AC-6 per the catalogue (token + font assertions); record the run-pending red baseline; grade each test.
- **Exit criteria:** suite green by default (tests pending); run-pending baseline recorded (all FAIL — stock scheme/fonts); grade gate passed.

### Result

### Checkpoint / Handoff

## Phase ITEST-3 — acceptance-tests: AC-7..AC-15 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-7..AC-15 (pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/design_system_test.dart`
- **Tasks:** one pending test per AC-7..AC-15 (shape/border/label, component, AC-14 one-theme+source-scan, AC-15 swatch caption); record the red baseline; note AC-14's partial-green baseline (augmented by APPLY-1); grade each test.
- **Exit criteria:** suite green by default; run-pending baseline recorded; grade gate passed.

### Result

### Checkpoint / Handoff

## Phase ITEST-4 — test-review (G-2)

- **Kind:** test-review
- **Target AC:** — (review packet for all 15 AC tests)
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the test-review packet (each AC → its test → Given/When/Then assertions → Rejects → grade; the red baseline; the augmentation plan); present for G-2.
- **Exit criteria:** a human records the G-2 decision. "Changes requested" spawns ITEST change phase(s) + a fresh review.

### Result

### Checkpoint / Handoff

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_Surfaces | FAIL (expected) | Then: surfaces == warm paper | THEME-3 | pending |
| AC-2 | TestAC02_Neutrals | FAIL (expected) | Then: ink/muted/line tokens | THEME-3 | pending |
| AC-3 | TestAC03_Accent | FAIL (expected) | Then: primary == #2F55C8 | THEME-3 | pending |
| AC-4 | TestAC04_ContrastFloor | FAIL (expected) | Then: AA floor on warm-paper tokens | THEME-3 | pending |
| AC-5 | TestAC05_NextFont | FAIL (expected) | Then: family == Atkinson Next | THEME-4 | pending |
| AC-6 | TestAC06_MonoFont | FAIL (expected) | Then: family == Atkinson Mono | THEME-4 | pending |
| AC-7 | TestAC07_Shape | FAIL (expected) | Then: StadiumBorder / card 16–22 | THEME-5 | pending |
| AC-8 | TestAC08_BorderWeights | FAIL (expected) | Then: 1/2/3px scale | THEME-5 | pending |
| AC-9 | TestAC09_MonoLabel | FAIL (expected) | Then: uppercase/700/tracked | THEME-5 | pending |
| AC-10 | TestAC10_Pills | FAIL (expected) | Then: primary/secondary pill variants | COMPONENTS-2 | pending |
| AC-11 | TestAC11_SpeakFab | FAIL (expected) | Then: round accent + speaker icon | COMPONENTS-3 | pending |
| AC-12 | TestAC12_Cards | FAIL (expected) | Then: surface/emphasis/inverted | COMPONENTS-4 | pending |
| AC-13 | TestAC13_ProvenanceSignature | FAIL (expected) | Then: glyph + border per kind | COMPONENTS-5 | pending |
| AC-14 | TestAC14_OneThemeNoHardcode | PARTIAL (one-theme passes; no-hardcode FAILs on residual literals) | Then: zero residual palette literals | APPLY-1 | pending |
| AC-15 | TestAC15_SwatchCaption | FAIL (expected) | Then: every swatch has a caption | APPLY-2 | pending |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC14 | bs-11 already installs one theme and swept most hardcoded colours, so it is partly green at baseline | APPLY-1 | assert **zero** residual palette `Color(0x…)` outside the D-4 exclusions | ⬜ Open |
| TestAC07 | no `PillButton`/`SurfaceCard` instances render until the component phases exist | COMPONENTS-2, COMPONENTS-4 | assert the rendered pill `StadiumBorder` and card radius on real instances | ⬜ Open |
| TestAC10 | both pill variants absent until COMPONENTS-2 | COMPONENTS-2 | assert primary-vs-secondary fill/border divergence on rendered buttons | ⬜ Open |
| TestAC12 | the three card variants absent until COMPONENTS-4 | COMPONENTS-4 | assert surface/emphasis/inverted divergence on rendered cards | ⬜ Open |
