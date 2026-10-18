# Module ITEST — acceptance integration suite

**Status:** ✅ Module done — all 4 ITEST phases complete; G-2 approved 2026-10-17 (Matt Quirk); behavior stage open
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/design_system_harness.dart` (new), `integration_test/design_system_test.dart` (new), the shared source-scan helper the AC-14 rule uses (under `integration_test/conformance/` or alongside the harness).
**Depends on:** THEME-2, COMPONENTS-1 (the shells it observes) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness) | ✅ Done | 9,741,639 | 14m 48s |
| ITEST-2 | acceptance-tests | AC-1..AC-6 | ✅ Done | 5,081,339 | 15m 37s |
| ITEST-3 | acceptance-tests | AC-7..AC-15 | ✅ Done | 8,124,050 | 28m 38s |
| ITEST-4 | test-review | — (G-2) | ✅ Done | 1,479,183 | 3m 27s |

## Interface reconciliation

- **Boundary:** the suite pumps the production `buildApp` through the same fake capture/IO deps sibling harnesses use; the real `AppTheme`, component widgets and screens are under test. Only platform capture/IO is faked (infrastructure), never the design system itself.
- **Observation points:** `Theme.of(context)` (`ColorScheme`, `TextTheme`, component themes, `AppTheme` token accessors) for the token/shape/font ACs; `find.byType(PillButton/SpeakButton/SurfaceCard/MonoLabel/ProvenanceBadge)` + resolved render objects for component ACs; the `screenRoster` walk + the `lib/`-source-scan for AC-14; swatch subtree/semantics for AC-15.
- **Pending gate:** the project's established per-feature pending mechanism — one pending test per AC behind a `BS17_RUN_PENDING` guard; **un-pend = delete that AC's guard row** (same ritual as sibling features). Red-baseline target: `flutter test -d flutter-tester integration_test/design_system_test.dart --dart-define=BS17_RUN_PENDING=true`.

## Open gates

- **G-2:** ITEST-4 is the test review; the owner approves the acceptance tests before any behavior phase runs. **Status: ✅ Resolved 2026-10-17: approved — all 15 AC tests accepted as-is (13 straight A, 2 A-core/B-pending AC-7/AC-14 deferrals accepted, AC-15 screen-grain caption intended) — Matt Quirk.** Behavior phases unblocked (THEME-3 next).

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

### Result — ITEST-2 (2026-10-17)

- **Landed (test-only — one file, `integration_test/design_system_test.dart`; no `lib/` change):** six pending AC tests registered through `acTestWidgets` (so the default run skips them, `--dart-define=BS17_RUN_PENDING=true` runs them), each reading what the real assembled app renders via `pumpApp` and the one installed theme (`Theme.of` — the single D-7 chokepoint):
  - **AC-1 Surfaces (THEME-3):** `colorScheme.surface == WarmPaper.background` (`--bg`), `surfaceContainerLowest == WarmPaper.surface` (`--sf`), `surfaceContainer == WarmPaper.sunken` (`--sf2`) + `isNot(stock.surface)` control.
  - **AC-2 Neutrals (THEME-3):** `onSurface == ink`, `onSurfaceVariant == muted`, `outline`/`outlineVariant == line` + `isNot(stock)` controls on onSurface/outline.
  - **AC-3 Accent (THEME-3):** `primary == accent` (`#2F55C8`), `onPrimary == accentInk` (white) + `isNot(stock.primary)` control.
  - **AC-4 Contrast floor (THEME-3):** Given-precondition (warm-paper surface/ink/accent installed) **naming THEME-3**; then bs-11's mirrored WCAG math (`_luminance`/`_contrast`, `_aaNormal = 4.5`) over 7 meaningful text-on-surface pairings (ink & muted on background/paper-white/sunken, accentInk on accent) each `≥ 4.5` — discriminates a below-AA warm-paper edit.
  - **AC-5 Next font (THEME-4):** 8 prose/heading `textTheme` roles each `fontFamily == 'Atkinson Hyperlegible Next'` (mono roles excluded, AC-6's) + `isNot(null)` control.
  - **AC-6 Mono font (THEME-4):** `AppTheme.monoLabel.fontFamily == 'Atkinson Hyperlegible Mono'` (the D-7 single source MonoLabel renders from; nothing mounts a MonoLabel on a screen until APPLY) + `isNot(Next)`/`isNot(null)` controls.
- **Verification** (Flutter on `~/development/flutter/bin`; `flutter-tester` lane; no `timeout` on macOS):
  - `flutter analyze integration_test/design_system_test.dart` — **No issues found**.
  - Default `flutter test -d flutter-tester integration_test/design_system_test.dart` — **11/11 scaffold pass, 6 AC tests skipped** (pending).
  - Run-pending `--dart-define=BS17_RUN_PENDING=true` — **red baseline: all 6 AC tests FAIL** at the expected assertion (AC-4 first on its THEME-3 Given precondition). Recorded in the *Red baseline* table below.
  - Unit `flutter test --coverage` — **1435/1435**; coverage gate vs `53a238a` **PASS** (*no touched `lib/**` — nothing to gate*, test-only phase).
- **Grade gate:** independent fresh-subagent grader (did not author the tests) — **6/6 straight A, 0 B, PASS**. Grid: [`behavior-test-completeness-bs-17-visual-design-system.md`](../behavior-test-completeness-bs-17-visual-design-system.md). No augmentation owed for AC-1..AC-6 (consistent with the pre-seeded augmentation table scheduling augmentations only for AC-7/AC-10/AC-12/AC-14).
- **Fix passes: 0/3** — first full run clean in both modes; analyze clean on first write.
- **Tokens / Time:** see dashboard row (ledger `ITEST-2`).

### Checkpoint / Handoff — ITEST-2 (→ ITEST-3)

- **Shared file clash:** ITEST-3 adds AC-7..AC-15 to the **same** `integration_test/design_system_test.dart`. ITEST-3 appends its two AC groups after the ITEST-2 AC groups (before `main`'s closing `}`); the WCAG helpers (`_luminance`/`_contrast`/`_aaNormal`) and `dart:math` import are already present at file top (added by ITEST-2) — **reuse them, do not redeclare**.
- **Patterns to reuse:** `acTestWidgets('AC-n', '<scenario>', (tester) async {…})` with a `# UX:` comment per AC; read the installed theme through `pumpApp` + `harness.colorScheme/textTheme/installedTheme`; component finders (`pillButtons`/`speakButtons`/`surfaceCards`/`monoLabels`/`provenanceBadges`) for AC-7/10/11/12/13; `residualPaletteLiterals(...)` + `screenRoster` walk for AC-14; AC-14 is **PARTIAL** at baseline (one-theme passes; no-hardcode FAILs on residual `lib/` literals) → note it in the red baseline (augmented by APPLY-1).
- **Verification commands:** unchanged from ITEST-1's checkpoint (default + run-pending suite, unit+coverage, gate, analyze).
- **Known gaps:** none for AC-1..AC-6. After ITEST-3, ITEST-4 assembles the test-review packet for all 15 → **G-2** (blocks every behaviour phase).

## Phase ITEST-3 — acceptance-tests: AC-7..AC-15 (pending) + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-7..AC-15 (pending)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4 · ∥ ITEST-2
- **Files:** `integration_test/design_system_test.dart`
- **Tasks:** one pending test per AC-7..AC-15 (shape/border/label, component, AC-14 one-theme+source-scan, AC-15 swatch caption); record the red baseline; note AC-14's partial-green baseline (augmented by APPLY-1); grade each test.
- **Exit criteria:** suite green by default; run-pending baseline recorded; grade gate passed.

### Result — ITEST-3 (2026-10-17)

- **Landed (test-only — one file, `integration_test/design_system_test.dart`; no `lib/` change):** nine pending AC tests (AC-7..AC-15) in three groups mirroring the feature Rules, registered through `acTestWidgets` (default run skips; `--dart-define=BS17_RUN_PENDING=true` runs them), plus four ITEST-3 helpers (`_themed` mounts a component through the production `AppTheme.light().themeData`; `_buttonMaterial`; `_cardDecoration`; `_badgeSignature`). Reused the file-top WCAG helpers / `dart:math` (not redeclared); added imports for `domain/provenance.dart`, `widgets/color_chip.dart`, `widgets/provenance_icon.dart`.
  - **AC-7 Shape (THEME-5):** installed-theme `filledButtonTheme`/`outlinedButtonTheme` shapes resolve `StadiumBorder`; `cardTheme.shape` is a `RoundedRectangleBorder` with radius in [16,22]. Theme-grain (D-7); rendered-instance inheritance deferred to COMPONENTS-2/4 (augmentation).
  - **AC-8 Borders (THEME-5):** `dividerTheme.thickness == 1` (hairline), `outlinedButtonTheme` side width `== 2` (standard); `AppTheme.emphasisBorderWidth == 3` + strict `1<2<3` scale control.
  - **AC-9 Mono-label (THEME-5):** mounts a real `MonoLabel('srgb')` → renders `'SRGB'` (upper-case control; `'srgb'` findsNothing), `AppTheme.monoLabel.fontWeight == w700`, `letterSpacing/fontSize ≈ 0.06` (±0.012).
  - **AC-10 Pills (COMPONENTS-2):** mounts `PillButton.primary`/`.secondary` through the theme → primary `Material.color == onSurface` (ink), paper label, no border; secondary transparent, 2px `onSurface` border, ink label; primary≠secondary fill control.
  - **AC-11 Speak FAB (COMPONENTS-3):** mounts `SpeakButton` → `CircleBorder`, `fillColor == WarmPaper.accent` (== `cs.primary`), `Icons.volume_up`, `bySemanticsLabel('Speak')` control.
  - **AC-12 Cards (COMPONENTS-4):** mounts the three `SurfaceCard` variants → ordinary surface fill + 2px line border; emphasis surface fill + 2px ink border; inverted ink fill + no border + paper text; ordinary≠emphasis border + inverted≠surface controls.
  - **AC-13 Provenance signature (COMPONENTS-5):** per `ProvenanceTier`, mounts `ProvenanceBadge` → each badge carries a colour-independent signature (border/fill/custom); glyph set distinct (4) + signature set ≥2 distinct (rejects colour-only).
  - **AC-14 One theme + no hardcode (APPLY-1, PARTIAL):** walks `screenRoster` — one `MaterialApp`/screen, every scheme/text `==` the chokepoint; then `residualPaletteLiterals(exempt: {theme authority} ∪ D-4)` `isEmpty`.
  - **AC-15 Swatch caption (APPLY-2):** walks `screenRoster`, finds every `ColorChip` with a colour; each swatch-bearing screen must show an "approx" caption; `totalSwatches > 0` non-vacuity guard.
- **Verification** (Flutter on `~/development/flutter/bin`; `flutter-tester` lane; no `timeout` on macOS):
  - `flutter analyze integration_test/design_system_test.dart` — **No issues found**.
  - Default `flutter test -d flutter-tester integration_test/design_system_test.dart` — **11 scaffold pass, 15 AC tests skipped** (pending).
  - Run-pending `--dart-define=BS17_RUN_PENDING=true` — **red baseline: all 9 new AC tests FAIL** at the documented assertion (AC-14 PARTIAL: one-theme passes, no-hardcode fails on **12** residual `lib/` literals). Recorded in the *Red baseline* table below.
  - Unit `flutter test --coverage` — **1435/1435**; coverage gate vs `bd5b5dd` **PASS** (*no touched `lib/**` — test-only phase*).
- **Grade gate:** independent fresh-subagent grader (did not author the tests) — **7 straight A** (AC-8/9/10/11/12/13/15), **2 A-core / B pending** (AC-7 → COMPONENTS-2+COMPONENTS-4; AC-14 → APPLY-1) matching the pre-seeded augmentation table, **0 plain-B → PASS**. Grid: [`behavior-test-completeness-bs-17-visual-design-system.md`](../behavior-test-completeness-bs-17-visual-design-system.md) (ITEST-3 section).
- **Augmentation confirmations:** TestAC07 stays **open** (owner COMPONENTS-2 pill + COMPONENTS-4 card — rendered-instance inheritance). TestAC14 stays **open** (owner APPLY-1 — zero residuals + pin D-4 set). **TestAC10 / TestAC12 → closed**: the ITEST-3 tests already mount both pill variants / all three card variants and assert rendered fill/border/label divergence, so no later augmentation is owed (COMPONENTS-2/4 just un-pend + keep green).
- **Fix passes: 0/3** — clean on first full run (analyze, default, run-pending, unit all passed first try).
- **Tokens / Time:** see dashboard row (ledger `ITEST-3`).

### Checkpoint / Handoff — ITEST-3 (→ ITEST-4)

- **Suite complete:** all 15 AC tests + 11 scaffold tests live in `integration_test/design_system_test.dart`. Default run green (15 skipped); run-pending red baseline verified for all 15. ITEST-4 assembles the test-review packet (all 15 ACs) for **G-2**; no test code changes expected there.
- **Owner note for APPLY-2 (AC-15):** the AC-15 test asserts **screen-grain** co-presence of an `'approx'` caption (faithful to APPLY-2's "shared caption" design + the wireframe's single app-level disclaimer). If APPLY-2 instead goes **per-swatch**, an augmentation asserting each swatch's subtree/semantics association would then be owed — add a row then.
- **Verification commands:** unchanged from ITEST-2's checkpoint (default + run-pending suite, unit+coverage, gate, analyze).
- **Known gaps:** none new for AC-7..AC-15. AC-7/AC-14 carry their open augmentations (COMPONENTS-2/4, APPLY-1).

## Phase ITEST-4 — test-review (G-2)

- **Kind:** test-review
- **Target AC:** — (review packet for all 15 AC tests)
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the test-review packet (each AC → its test → Given/When/Then assertions → Rejects → grade; the red baseline; the augmentation plan); present for G-2.
- **Exit criteria:** a human records the G-2 decision. "Changes requested" spawns ITEST change phase(s) + a fresh review.

### Result — ITEST-4 (2026-10-17): test-review packet → G-2

**Phase kind:** `test-review` — no behavior or test code written; this phase assembles the acceptance-suite review packet for all 15 ACs and presents it for the human **G-2** decision. The suite (`integration_test/design_system_test.dart`) is frozen as delivered by ITEST-2/ITEST-3: 15 AC tests + 11 scaffold tests. Default run green (15 skipped behind `BS17_RUN_PENDING`); run-pending red baseline verified for all 15 (table below).

**Reviewer — look here first:**
1. **AC-4** — the one AC that *references but does not restate* bs-11's accessibility floor. Confirm it is right that bs-17 re-measures WCAG contrast over the warm-paper tokens (7 text-on-surface pairings ≥ 4.5) rather than owning a new accessibility rule. This is the spec's explicit boundary (feature §Boundary).
2. **AC-7 & AC-14** — the two **A-core / B pending** rows (not straight A). Each is a *later-only* limit with a named owner, not a weak test: AC-7 proves the theme *declares* the stadium pill / 16–22 card radius but defers rendered-instance inheritance to COMPONENTS-2/4; AC-14's no-hardcode half fails red on 12 residual `lib/` literals that only APPLY-1 can remove. Confirm these deferrals are acceptable to approve now.
3. **AC-15 grain** — asserts **screen-grain** co-presence of an "approx" caption (faithful to APPLY-2's *shared* caption + the wireframe's single app-level disclaimer), not per-swatch subtree association. Confirm the shared-caption design is intended; if per-swatch is wanted, an augmentation is owed (noted in APPLY-2 handoff).
4. **TestAC10 / TestAC12** — the plan-mode augmentation table pre-seeded divergence augmentations for these, but the authored tests already mount the real components and assert rendered divergence, so both grade straight A and the augmentation rows are **closed** (COMPONENTS-2/4 just un-pend + keep green).

**Packet — every AC → its test → Given / When / Then / Rejects → owner → grade** (full per-assertion detail in the grade grid; red-baseline failure point per row in the *Red baseline* table below):

| AC | Test | Given (observed) | When | Then (key assertions) | Rejects | Owner | Grade |
|---|---|---|---|---|---|---|---|
| AC-1 | `Surfaces use the warm-paper palette` | app assembled: `MaterialApp` findsOne, `installedTheme`≠null, `Scaffold` rendered | surfaces rendered → read installed `ColorScheme` | `surface==WarmPaper.background`(--bg), `surfaceContainerLowest==surface`(--sf), `surfaceContainer==sunken`(--sf2); +`isNot(stock.surface)` | stock M3 surfaces; wrong token values; a per-screen scheme | THEME-3 | **A** |
| AC-2 | `Ink, muted text and hairlines use the warm-paper neutrals` | `Text` findsWidgets; theme resolved | rendered | `onSurface==ink`, `onSurfaceVariant==muted`, `outline`&`outlineVariant==line`; +`isNot(stock)` controls | stock neutrals; wrong values; `outlineVariant` left stock | THEME-3 | **A** |
| AC-3 | `The primary action colour is the cobalt accent` | theme installed (transitive via `installedTheme` getter) | read `primary`/`onPrimary` | `primary==accent`(#2F55C8), `onPrimary==accentInk`(#FFFFFF); +`isNot(stock.primary)` | stock primary; wrong accent; non-white label | THEME-3 | **A** |
| AC-4 | `The warm-paper palette still meets the accessibility contrast floor` | **precondition (THEME-3):** `surface==background`, `onSurface==ink`, `primary==accent` | measure every text-on-surface pairing (bs-11 mirrored WCAG math) | 7 pairings each `≥4.5` (ink×{bg,paper,sunken}, muted×{bg,paper,sunken}, accentInk/accent) + `_aaNormal==4.5` sanity | a below-AA warm-paper edit; a non-warm-paper scheme; a mis-mirrored ratio | THEME-3 | **A** |
| AC-5 | `Prose and headings render in Atkinson Hyperlegible Next` | `Text` findsWidgets; `textTheme` resolved | read `TextTheme` roles | 8 prose/heading roles each `fontFamily=='Atkinson Hyperlegible Next'` (mono excluded) | stock Roboto/SF (null); non-Atkinson; partial application | THEME-4 | **A** |
| AC-6 | `Micro-labels and numeric readouts render in Atkinson Hyperlegible Mono` | theme source `AppTheme.monoLabel`; `installedTheme`≠null | read `AppTheme.monoLabel.fontFamily` | `=='Atkinson Hyperlegible Mono'`; +`isNot(Next)`/`isNot(null)` controls | stock (null); left in sans Next; any wrong family | THEME-4 | **A** |
| AC-7 | `Buttons render as fully-rounded pills and cards as rounded panels` | `installedTheme` deref (theme-shape grain) | read filled/outlined button & card shapes | filled & outlined `isA<StadiumBorder>`; `cardTheme.shape isA<RoundedRectangleBorder>` radius∈[16,22] | stock button radius; stock/unset card radius; radius outside 16–22 (**not yet:** component overriding theme shape → deferred) | THEME-5 | **A-core / B pending COMPONENTS-2, COMPONENTS-4** |
| AC-8 | `Borders follow the weight scale` | `installedTheme` deref | read divider/outlined-side widths | `dividerTheme.thickness==1` (hairline), outlined side `width==2` (standard); `emphasisBorderWidth==3` + `1<2<3` (const controls) | unset/0 divider; non-2px side; a dropped 1-vs-2 distinction | THEME-5 | **A** |
| AC-9 | `Monospace micro-labels render uppercase with wide letter-spacing` | mount real `MonoLabel('srgb')`, settle | rendered | renders `'SRGB'` (`find.text('srgb') findsNothing` control), `fontWeight==w700`, `letterSpacing/fontSize≈0.06`(±0.012) | mixed-case; non-bold; un-tracked | THEME-5 | **A** |
| AC-10 | `Primary actions render as ink-filled pills and secondary as outline pills` | mount real `PillButton.primary` & `.secondary` through theme | rendered | primary `Material.color==onSurface`(ink), label `==surface`(paper), no border; secondary transparent fill + 2px `onSurface` border + ink label; primary≠secondary fill | accent-filled primary; identical/colour-swapped variants; secondary with a fill or no border | COMPONENTS-2 | **A** |
| AC-11 | `The speak action renders as a round accent floating button` | mount real `SpeakButton`, settle | rendered | `CircleBorder`; `fillColor==WarmPaper.accent` **and** `==cs.primary` (inherited); `Icons.volume_up` present; `bySemanticsLabel('Speak')` control | text/square button; non-accent fill; missing/other glyph; unlabelled | COMPONENTS-3 | **A** |
| AC-12 | `Panels render as bordered surface cards with emphasis and inverted variants` | mount `SurfaceCard` ordinary/emphasis/inverted through theme | rendered | ordinary `surface` fill + 2px `outlineVariant` border; emphasis `surface` fill + 2px `onSurface` border; inverted ink fill + no border + paper text; + divergence controls | three identical cards; 1px ordinary border; inverted not ink-filled / sunk text | COMPONENTS-4 | **A** |
| AC-13 | `Provenance badges render with the glyph-and-border signature` | per `ProvenanceTier`, mount real `ProvenanceBadge`, settle | rendered | each tier carries a non-colour signature (`border‖fill‖custom`); glyphs `hasLength 4` (distinct); signatures vary (`≥2`) | colour-only differentiation; no non-colour signature on a kind; a uniform signature across kinds | COMPONENTS-5 | **A** |
| AC-14 | `Every screen inherits the one installed theme` | walk `screenRoster` via `pumpApp`; `MaterialApp` findsOne per screen | any primary screen shown | each screen scheme/text `==` `AppTheme.light()` chokepoint; `residualPaletteLiterals isEmpty` (names offenders) | a nested theme; an overriding screen; (after APPLY-1) a hardcoded palette literal outside exclusions | APPLY-1 | **A-core / B pending APPLY-1** (PARTIAL at baseline) |
| AC-15 | `A displayed colour swatch carries its approximation caption` | walk `screenRoster`; count `ColorChip`s with a colour; `totalSwatches>0` control | swatch shown | each swatch-bearing screen shows an `'approx'` caption `Text` (screen-grain co-presence) | a swatch-bearing screen with no caption; a vacuous zero-swatch pass | APPLY-2 | **A** |

**Red baseline (run-pending):** all 15 AC tests FAIL at the documented assertion under `flutter test -d flutter-tester integration_test/design_system_test.dart --dart-define=BS17_RUN_PENDING=true`; AC-14 is PARTIAL (one-theme half passes, no-hardcode half fails on 12 residual `lib/` literals). Default run (no flag): 11 scaffold pass, 15 AC skipped. Per-row failure point in the *Red baseline* table below.

**Augmentation plan** (*Test augmentations* table below): **2 open** — TestAC07 (closed by COMPONENTS-2 pill + COMPONENTS-4 card: rendered-instance `StadiumBorder`/radius inheritance) and TestAC14 (closed by APPLY-1: zero residual literals + pin the D-4 exclusion set). **2 closed at authoring** — TestAC10, TestAC12 (the ITEST-3 tests already mount the real variants and assert rendered divergence). No augmentation owed for AC-1..AC-6, AC-8, AC-9, AC-11, AC-13, AC-15.

**Grade grid:** [`behavior-test-completeness-bs-17-visual-design-system.md`](../behavior-test-completeness-bs-17-visual-design-system.md) — ITEST-2 section (AC-1..AC-6) + ITEST-3 section (AC-7..AC-15). Combined counts: **13 straight A, 2 A-core / B pending (AC-7, AC-14), 0 plain B → gate PASS** at both AC-test phases. Each grade was set by an independent fresh-subagent grader who did not author the tests.

**Decision requested — G-2:** approve the acceptance tests so the behavior stage may begin. Recorded via:
`/feature-next-phase --gate bs-17-visual-design-system G-2 approved | "<changes requested>"`
"Changes requested" turns each item into an `ITEST` change phase before the behavior stage, then a fresh review.

**Tokens / Time:** see dashboard row (ledger `ITEST-4`).

### Checkpoint / Handoff — ITEST-4 (→ behavior stage)

- **Phase state:** ✅ Done; **G-2 approved 2026-10-17 (Matt Quirk)** — all 15 AC tests accepted as-is. No code or test changes; suite frozen as delivered by ITEST-2/3; behavior stage open.
- **On G-2 approved:** `--gate` flips ITEST-4 → ✅ Done and opens the behavior stage. Startable immediately (no inter-dependencies among them beyond the shared files noted): **THEME-3** (AC-1..4), **THEME-4** (AC-5/6), **THEME-5** (AC-7/8/9), **COMPONENTS-2** (AC-10), **COMPONENTS-3** (AC-11), **COMPONENTS-4** (AC-12), **COMPONENTS-5** (AC-13). **APPLY-1** (AC-14) and **APPLY-2** (AC-15) depend on their module predecessors — see the master plan graph. THEME-3 is the natural first behavior phase (AC-4's Given precondition + every other AC's palette/scheme sit on it).
- **On changes requested:** author the named `ITEST` change phase(s) against `integration_test/design_system_test.dart`, re-baseline, re-grade, then a fresh test-review before any behavior phase.
- **Verification commands** (unchanged; Flutter on `~/development/flutter/bin`, `flutter-tester` lane, no `timeout` on macOS): default `flutter test -d flutter-tester integration_test/design_system_test.dart`; red baseline add `--dart-define=BS17_RUN_PENDING=true`; unit `flutter test --coverage`; gate `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`.
- **Un-pend ritual (every behavior phase):** delete that AC's row in `integration_test/bs17/pending.dart`; make its assigned augmentation(s); run default (its AC now green, later ACs still skipped) + unit/coverage gate + acceptance & grade gates.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | `AC-1: Surfaces use the warm-paper palette` | FAIL (expected) | Then: `cs.surface == WarmPaper.background` (stock M3 surface) | THEME-3 | A |
| AC-2 | `AC-2: Ink, muted text and hairlines…` | FAIL (expected) | Then: `cs.onSurface == WarmPaper.ink` (stock onSurface) | THEME-3 | A |
| AC-3 | `AC-3: The primary action colour is the cobalt accent` | FAIL (expected) | Then: `cs.primary == WarmPaper.accent` (stock primary) | THEME-3 | A |
| AC-4 | `AC-4: …meets the accessibility contrast floor` | FAIL (expected) | Given-precondition (THEME-3): `cs.surface == WarmPaper.background` | THEME-3 | A |
| AC-5 | `AC-5: Prose and headings render in…Next` | FAIL (expected) | Then: `tt.*.fontFamily == 'Atkinson Hyperlegible Next'` (stock Roboto) | THEME-4 | A |
| AC-6 | `AC-6: Micro-labels and numeric readouts…Mono` | FAIL (expected) | Then: `AppTheme.monoLabel.fontFamily == 'Atkinson Hyperlegible Mono'` (stock Roboto) | THEME-4 | A |
| AC-7 | `AC-7: Buttons render as fully-rounded pills…` | FAIL (expected) | Then: `filledButtonTheme` shape `null` (expected `StadiumBorder`) | THEME-5 | A-core / B pending COMPONENTS-2, COMPONENTS-4 |
| AC-8 | `AC-8: Borders follow the weight scale` | FAIL (expected) | Then: `dividerTheme.thickness` `null` (expected 1.0) | THEME-5 | A |
| AC-9 | `AC-9: Monospace micro-labels…uppercase…` | FAIL (expected) | Then: `AppTheme.monoLabel.fontWeight` `null` (expected w700); upper-case asserts are controls | THEME-5 | A |
| AC-10 | `AC-10: Primary…ink-filled pills…secondary…outline` | FAIL (expected) | Then: primary `Material.color` == stock primary (expected `onSurface`/ink) | COMPONENTS-2 | A |
| AC-11 | `AC-11: The speak action…round accent floating button` | FAIL (expected) | Then: `SpeakButton.fillColor` == stock primary (expected `WarmPaper.accent`) | COMPONENTS-3 | A |
| AC-12 | `AC-12: Panels…surface cards…emphasis…inverted` | FAIL (expected) | Then: ordinary `SurfaceCard` border width 1.0 (expected 2.0 standard) | COMPONENTS-4 | A |
| AC-13 | `AC-13: Provenance badges…glyph-and-border signature` | FAIL (expected) | Then: measured badge signature border/fill/custom all false (expected a signature) | COMPONENTS-5 | A |
| AC-14 | `AC-14: Every screen inherits the one installed theme` | PARTIAL (one-theme passes; no-hardcode FAILs on 12 residual literals) | Then: `residualPaletteLiterals` isEmpty (12 found) | APPLY-1 | A-core / B pending APPLY-1 |
| AC-15 | `AC-15: A displayed colour swatch…approximation caption` | FAIL (expected) | Then: Readout `ColorChip` swatch renders but no `approx` caption | APPLY-2 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC14 | bs-11 already installs one theme and swept most hardcoded colours, so it is partly green at baseline | APPLY-1 | assert **zero** residual palette `Color(0x…)` outside the D-4 exclusions (already `isEmpty` at full strength) + pin the D-4 exclusion set | ⬜ Open (confirmed ITEST-3) |
| TestAC07 | theme-grain test proves the theme *declares* the stadium pill / 16–22 card radius, but not that a rendered `PillButton`/`SurfaceCard` inherits it | ~~COMPONENTS-2 (pill)~~ ✅, COMPONENTS-4 (card) | assert the rendered pill `StadiumBorder` and card radius on real mounted instances | 🔄 Pill half ✅ Closed COMPONENTS-2 (AC-10 test mounts both variants, asserts `isA<StadiumBorder>`); **card half still Open** (COMPONENTS-4, AC-12 mounts `SurfaceCard`) |
| TestAC10 | ~~both pill variants absent until COMPONENTS-2~~ | COMPONENTS-2 | ~~assert primary-vs-secondary fill/border divergence on rendered buttons~~ | ✅ Closed ITEST-3 — the test already mounts both variants and asserts rendered fill/border/label divergence; COMPONENTS-2 only un-pends + keeps green |
| TestAC12 | ~~the three card variants absent until COMPONENTS-4~~ | COMPONENTS-4 | ~~assert surface/emphasis/inverted divergence on rendered cards~~ | ✅ Closed ITEST-3 — the test already mounts all three variants and asserts rendered divergence; COMPONENTS-4 only un-pends + keeps green |
