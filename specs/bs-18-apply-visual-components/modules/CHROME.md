# Module CHROME — app chrome (scaffold, bottom nav, top bar)

**Status:** In progress — CHROME-3 done (AC-1 ✅, nav is the production default); next CHROME-4 (AC-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/app/build_app.dart`, `lib/app/theme.dart` (nav/appbar theme tokens only), new `lib/app/app_shell.dart` (nav scaffold) and `lib/app/app_destinations.dart`; the `BS18_RUN_PENDING` runner + coverage gate tooling it establishes (scaffold).
**Depends on:** — · **Blocks:** ITEST (CHROME-2), all screen modules (they wire through `build_app.dart`)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CHROME-1 | scaffold | — | ✅ Done | 5.04M | 16m (16m) |
| CHROME-2 | shell | — | ✅ Done | 19.06M | 52m (1h 04m) |
| CHROME-3 | behavior | AC-1 | ✅ Done | 16.50M | 33m (8h 04m) |
| CHROME-4 | behavior | AC-2 | ⬜ Todo | | |

## Interface reconciliation

Exposes `AppShell` (a `Scaffold` holding an `IndexedStack` of the 4 destinations with a bottom
`NavigationBar`) and `AppDestination` (enum: capture/compare/recipes/palette, each with label + glyph +
screen builder). The top bar is a shared `AppTopBar` the destinations mount. Consumes the existing
destination screens unchanged (`CaptureScreen`, `ComparisonScreen`, `RecipesScreen`, `PaletteScreen`,
`ReadoutScreen`) and the bs-17 theme tokens. Deep-link entries (`deps.*Entry`) keep opening their screen
directly; only the *default* route becomes the nav shell (D-1). No change to spoken output, routing results
or controller behaviour (D-2).

## Open gates

G-1 (approve the spec) ✅ Resolved 2026-10-19 07:33 EDT: approved — Matt Quirk; CHROME-1 startable. G-2 (approve the tests) ✅ Resolved 2026-10-19 19:48 EDT: approved — Matt Quirk; CHROME-3 (done) and CHROME-4 unblocked.

## Phase CHROME-1 — scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** CHROME-2
- **Files:** branch only; `tool/` or existing test config for the `BS18_RUN_PENDING` flag; no product code.
- **Tasks:**
  1. Branch `feat/bs-18-apply-visual-components` off `main@d3a1c4f`; `flutter pub get`.
  2. Record the baseline: whole unit suite + the sibling acceptance suites that run on `flutter-tester`, noting the 4 carried known flakes (prove they reproduce at the merge-base, not regressions).
  3. Confirm the coverage gate tooling runs (passes clean, fails on a planted uncovered line) on touched files.
  4. Add the `BS18_RUN_PENDING` pending-test runner convention (mirrors bs-13's `BS13_RUN_PENDING`) so ITEST can record a red baseline.
- **Exit criteria:** branch pushed; baseline + flake reproduction recorded; gate proven both directions; no product code changed.

### Result — CHROME-1 ✅ Done (2026-10-19)

- **Landed:** branch `feat/bs-18-apply-visual-components` off `main@fa21c49` (= `d3a1c4f` + plan-only commits; verified `d3a1c4f..fa21c49` touches `specs/` only, no `lib/`). `flutter pub get` clean. No product code.
- **BS18_RUN_PENDING runner:** new `integration_test/visual_application/pending.dart` — the runner convention (mirrors bs-17's `bs17/pending.dart`): `runPending` (define + host env), `pendingSkipReason(acId, {forceRunPending})`, `acTestWidgets(...)`, `behaviorPhases` (13 bs-18 behaviour phases), and `pendingACs` seeded with all 14 ACs → owners from the master plan AC coverage table. ITEST-1 builds the harness/fixtures on top and un-pending = deleting a row.
- **Self-test:** new `integration_test/visual_application/pending_runner_test.dart` proves the runner both directions — default run **6 passed / 1 skipped** (AC-1 wiring smoke skipped; un-pended AC runs); `--dart-define=BS18_RUN_PENDING=true` run **7 passed / 0 skipped** (AC-1 now runs). Plus integrity invariants (every owner ∈ behaviorPhases; seed == AC-coverage table).
- **Coverage gate** (`tool/coverage_gate.dart`, pre-existing): proven both directions on touched files — clean tree (no touched `lib/`) → `PASS` exit 0; planted untracked uncovered `lib/_gate_probe.dart` → `FAIL` exit 1 (`NO COVERAGE DATA`); probe removed, tree clean.
- **Baseline recorded** (branch point, code-equiv `d3a1c4f`): unit suite `flutter test --coverage test/` = **1643 passed, exit 0**; `coverage/lcov.info` generated.
- **Carried flakes reproduce** (off-lane flutter-tester native fails, NOT regressions — scaffold changed no product code): `palette_test` AC-3 + AC-5 (bs-06), `self_assessment_test` AC-4 (bs-07), `display_test` AC-9 (bs-08) — each the sole failure in an otherwise-green suite. Matches the master plan Known flakes table.
- **Gates:** unit ✅; coverage gate ✅ both directions; no acceptance/grade gate (scaffold). `dart analyze` on new files exit 0. Fix passes: 0/3.

### Checkpoint / Handoff — after CHROME-1

- **Frozen interfaces (this phase):** `integration_test/visual_application/pending.dart` — `pendingACs`, `behaviorPhases`, `runPending`, `pendingSkipReason`, `acTestWidgets`. ITEST-1 consumes these; behaviour phases un-pend by deleting a `pendingACs` row.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; `flutter`/`dart` not on PATH; no `timeout`/`gtimeout` on this machine):
  - Unit + coverage: `flutter test --coverage test/`
  - Coverage gate on touched files: `dart run tool/coverage_gate.dart d3a1c4f` (base = code merge-base; `COVERAGE_GATE_BASE` also honoured)
  - Acceptance suite (default): `flutter test -d flutter-tester integration_test/visual_application/`
  - Red baseline: add `--dart-define=BS18_RUN_PENDING=true`
  - Sibling flake suites: `flutter test -d flutter-tester integration_test/{palette,self_assessment,display}_test.dart`
- **Known gaps / notes:** coverage gate is line-only (Dart emits no branch coverage — per-branch exercise is a phase/review duty). The whole `integration_test/` dir won't launch at once (per-file/per-suite only). Sibling source-scan/sim ACs fail natively off the exclusive lane — the 4 above are the expected carried set.
- **Next (CHROME-2, shell):** add `AppDestination` + `AppShell` (Scaffold + IndexedStack + NavigationBar over the 4 destination screens), test anchors (`bottomNavKey`, per-destination keys, non-colour active-marker key), and `AppTopBar`; wire the default route in `build_app.dart` to the shell; keep behaviour unchanged; existing suite green + unit/coverage gate.

## Phase CHROME-2 — shell: nav + top-bar shells

- **Kind:** shell
- **Target AC:** — (shell for AC-1/AC-2; behaviour unchanged)
- **Depends on:** CHROME-1 · **Blocks:** ITEST-1
- **Files:** `lib/app/app_destinations.dart` (new), `lib/app/app_shell.dart` (new), `lib/app/build_app.dart` (default route → `AppShell`), `lib/app/theme.dart` (NavigationBar/AppBar theme tokens).
- **Tasks:**
  1. Add `AppDestination` (enum + label/glyph/builder) and `AppShell` (Scaffold + IndexedStack + NavigationBar). Mount the 4 destination screens in the stack. Keep each screen's own content unchanged.
  2. Expose test anchors: `bottomNavKey`, a per-destination key, and an active-destination marker key (a non-colour indicator — e.g. a filled-glyph/label-weight marker) so AC-1 can observe active state without colour.
  3. Add a shared `AppTopBar` shell the destinations can mount (title + optional back/close + theme toggle slot), rendering through the theme; wire it on the 4 destinations without changing their behaviour.
  4. Leave deep-link entries routing to their screens unchanged.
- **Exit criteria:** app builds; the default route shows the shell with 4 destinations switchable; existing suite stays green (behaviour unchanged); unit + coverage gate on touched files.

### Result — CHROME-2 ✅ Done (2026-10-19)

- **Decision (user, 2026-10-19):** *additive, zero-behaviour-change* wiring. The shell is wired **only on the true fall-through** (no capture source, no deep-link entry); a wired `captureSource` and every `*Entry` still open their screen directly (unchanged), so the nav is not yet visible in the shipped app (production boots `captureSource` → Capture). Making the shell the production-visible default is deferred to CHROME-3 (AC-1, after G-2). This preserves the signed-off bs-01/bs-02/bs-14 suites.
- **Landed:** new `lib/app/app_destinations.dart` (`AppDestination` enum capture/compare/recipes/palette — label + outline/filled glyph + `navItemKey`); new `lib/app/app_shell.dart` (`AppShell` = Scaffold + lazy `IndexedStack` + custom themed bottom nav; anchors `bottomNavKey`, per-destination `navItemKey`, non-colour `activeDestinationKey` = filled glyph + bold label); new `lib/app/app_top_bar.dart` (`AppTopBar` shared top-bar shell — Atkinson title + back/close + theme-toggle slot, keys `titleKey`/`leadingKey`/`themeToggleKey`). `build_app.dart` fall-through → `_defaultShell` (Capture dest = the unchanged Readout + sharing-offer landing `_fallThroughHome`; Compare/Recipes/Palette lazy). `theme.dart` + `appBarTheme`/`navigationBarTheme` warm-paper tokens.
- **Deviations from the task wording (justified by the user decision):** (1) a **custom themed bottom bar** instead of Material `NavigationBar`, so the keys + the non-colour active marker are deterministic (Material's icon/selectedIcon cross-fade can't carry a "present-only-when-selected" keyed marker); `navigationBarTheme` tokens are added for CHROME-3 to adopt. (2) `AppTopBar` is built + unit-tested but **not yet mounted** on the destinations — mounting it would double the `AppBar` (each screen keeps its own header) and break `find.text('Readout')`; the per-destination swap is CHROME-4/AC-2. (3) lazy `IndexedStack` (not eager) so booting the fall-through mounts only the Capture body — no extra controller/read-endpoint/pending-timer on the default route.
- **Gates:** `dart analyze` (5 lib + 5 test touched files) → No issues. Unit + coverage `flutter test --coverage test/` → **1668 pass / 0 fail** (baseline 1643 + 25 new). Coverage gate `tool/coverage_gate.dart d3a1c4f` → **100% line coverage on all 5 touched files, PASS**. No acceptance/grade gate (shell). **Fix passes: 2/3** (both test-only: a `find.descendant` that excluded the keyed box; raw-vs-resolved `titleLarge` geometry).
- **Existing-suite regression check (fall-through is shared):** bs-11 accessibility **19/19** (AC-4 48dp + AC-5 AA contrast hold over the new nav chrome); bs-14 `consent_and_record` (default-route opt-in offer) **5/5**; base `harness_test` **5/5**. Carried: running the whole `integration_test/bs14/` dir, 3 files hit "Unable to start the app on the device" launch flakes under machine load — each passes run alone (confirmed on `consent_and_record`), matching the known whole-dir-won't-launch gotcha.

### Checkpoint / Handoff — after CHROME-2

- **Frozen interfaces (this phase):** `AppDestination` (enum + `label`/`icon`/`selectedIcon`/`navItemKey`); `AppShell({destinations, bodies, initialIndex})` with `bottomNavKey` / `activeDestinationKey` and lazy `IndexedStack`; `AppTopBar({title, onBack?, onClose?, themeToggle?})` with `titleKey`/`leadingKey`/`themeToggleKey`. ITEST-1/2 anchor the AC-1/AC-2 pending tests on these keys; the app-chrome theme tokens live on `AppTheme.light().themeData` (`appBarTheme`, `navigationBarTheme`).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/`gtimeout`): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart d3a1c4f`; touched tests `flutter test test/app/{app_destinations,app_shell,app_top_bar,theme,build_app}_test.dart`; regression `flutter test -d flutter-tester integration_test/{bs11/accessibility_test.dart,bs14/consent_and_record_test.dart,harness_test.dart}` (run bs14 files one at a time — the dir won't launch at once under load).
- **Known gaps / next:** the shell is NOT the shipped default yet (fall-through only) — **CHROME-3 (AC-1, after G-2)** makes it the production-visible default (route `captureSource` through it) and finalises the design-system nav treatment (adopt `navigationBarTheme`, DecoratedBox token check). **CHROME-4 (AC-2)** mounts `AppTopBar` on each destination (removing their ad-hoc headers). ITEST-1 (the acceptance harness) is the next startable phase and depends only on CHROME-2.

## Phase CHROME-3 — behavior: bottom navigation (AC-1)

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** CHROME-4, GUARD-1
- **Files:** `lib/app/app_shell.dart`, `lib/app/theme.dart`, `lib/app/build_app.dart`.
- **Tasks:**
  1. Finalise the NavigationBar treatment to the design system (surface fill, ink/accent tokens, Atkinson labels, selected glyph) and the non-colour-only active indicator (selected label weight + filled glyph).
  2. Ensure all 4 destinations are reachable and the active one is marked.
  3. **Make the shell the production-visible default (scope expansion approved by Matt Quirk, 2026-10-20).** CHROME-2 wired the shell only on the no-capture-source fall-through, so the shipped app (which boots a `captureSource`) still opened straight to a bare Capture screen and never showed the nav. Route `captureSource` (with no deep-link entry) *through* the shell: `_home` no longer short-circuits to a bare `CaptureHomeScreen`, and `_defaultShell`'s opening Capture destination hosts the real `CaptureHomeScreen` when a source is wired (else the pre-shell Readout fall-through). Deep-link entries (correction/comparison/recipes/palette) still open their screen directly (D-1); `main.dart` is unchanged (production already wires `captureSource`, which now flows into the shell's Capture destination). This changes the capture-path boot, so bs-02 (`capture_test`) and bs-09 (`advanced_capture_test`) are re-verified (D-2).
- **Exit criteria:** see acceptance gate; run alone (owns `build_app.dart`).
- **Acceptance gate:** un-pend AC-1; `TestAC01_BottomNav` green with all earlier ACs; sibling suites green (incl. the re-verified capture suites).

### Result — CHROME-3 ✅ Done (2026-10-20)

- **Scope expansion (Matt Quirk, 2026-10-20):** made the nav shell the **production-visible default**, not just the capture-less fall-through CHROME-2 shipped. Asked because the shipped app boots a `captureSource` and D-1 (default route → shell) vs D-2 (keep bs-02 green) pointed opposite ways; user chose "wire the shell as the prod default".
- **Landed (`lib/app/build_app.dart`):** `_home` no longer short-circuits a wired `captureSource` to a bare `CaptureHomeScreen` — `captureSource` (with no deep-link entry) now falls through to `_defaultShell`, whose opening Capture destination hosts the real `CaptureHomeScreen` when a source is wired and the Readout fall-through (`_fallThroughHome`) otherwise. Deep-link entries (correction/comparison/recipes/palette) still open their screen directly (D-1); the correction loop still reads `captureSource` as its camera (checked first). **No `main.dart` behaviour change** — production already wires `captureSource`, which now flows into the shell, so the shipped app shows the nav (two now-stale doc comments in `main.dart` corrected; comment-only). The nav treatment itself was already design-system-conformant from CHROME-2 (custom themed bar reading the warm-paper `surfaceContainerLowest`/`outline`/`primary` tokens, filled-glyph + bold-label non-colour active marker) — confirmed, not churned; `app_shell.dart`/`theme.dart` unchanged. `navigationBarTheme` tokens left in place (harmless; the custom bar reads `colorScheme` directly — Material `NavigationBar` can't carry the keyed present-only-when-selected active marker, so the custom bar stays, per CHROME-2).
- **AC-1 un-pended** (deleted its `pendingACs` row). `TestAC01_BottomNav` runs **green** (pumps the fall-through shell; 4 destinations, filled-vs-outline active marker, theme-token `DecoratedBox` colours). Updated the harness smoke (`smoke_test.dart`) to track the un-pend: the pending-direction proof now uses AC-2 (and asserts AC-1 never skips); the seed-drift test asserts `pendingACs == fullSeed∖{AC-1}` + `fullSeed.hasLength(14)`; the `acTestWidgets` wiring smoke uses AC-2.
- **Unit test updated** (`test/app/build_app_test.dart`): the ex-`'opens on the Capture screen'` test now asserts the wired capture source routes **through** the shell (bottom nav present, Capture active, CaptureHomeScreen shown, other 3 lazy); added a test that the capture boot reaches another destination via the nav. The capture-commit / low-light / pair-handoff tests still pass unchanged (Readout/Comparison pushed on the root navigator above the shell).
- **Sibling-suite re-verification (D-2):** my change is **byte-identical on the no-`captureSource` path**, so only the capture path is new. **bs-02 `capture_test` 19✅, bs-09 `advanced_capture_test` 21✅** (Capture works inside the shell; `AppBar`-scoped finders unaffected by nav labels), **bs-10 `daltonization_test` 25✅**, **bs-11 `accessibility_test` 19✅** (nav items clear 48dp + AA), **bs-14 `consent_and_record` 5✅**.
- **bs-01 `readout_test` AC-11 — pre-existing CHROME-2 regression fixed.** The Readout fall-through moved inside the shell in CHROME-2 (not run then), so the nav's plain-text "Recipes" label collided with AC-11's bare `find.text('Recipes')`. **Proven to fail identically at BASE `ce56fea` with my lib/test edits stashed** → not a CHROME-3 regression, but surfaced and owned under D-2 (the nav chrome is this feature's doing). Fixed by anchoring the two "is the Recipes screen shown" assertions on `find.widgetWithText(AppBar, 'Recipes')` (strictly more discriminating — the screen title is in an `AppBar`, the nav label is not) and swapping the test's `widgets.dart` import for `material.dart` (re-exports it). readout_test now **12✅**. Change recorded here per the no-weaken rule; independent grader confirmed it preserves intent (A).
- **Gates:** `dart analyze` (touched lib + tests) → No issues. Unit `flutter test --coverage test/` → **1669 pass** (1668 + net 1 new). Coverage gate `dart run tool/coverage_gate.dart d3a1c4f` → **100% on all 6 touched files** (`app_destinations`/`app_shell`/`app_top_bar`/`theme`/`build_app`/`main`), **PASS**. Acceptance: AC-1 green, AC-2..14 skip pending (pending mechanism re-proven in smoke). **Grade gate PASS** — independent fresh-subagent re-grade: AC-1 **A** (unchanged body), the 3 smoke scaffold edits **A**, the readout AC-11 finder change **A**; A=5 / B=0, no fix owed. **Fix passes: 1/3** (one post-first-run fix: the readout AC-11 `AppBar` finder needed `material.dart` — compile error caught by `dart analyze` + flutter-tester "failed to build bundle"; fixed and green).
- **Known flake:** the whole `integration_test/visual_application/` dir launches at once only on a fresh device; under sustained load (many back-to-back runs this session) every file hits the "Unable to start the app on the device" / "log reader failed" launch flake — all per-file runs above were clean run alone or in a small batch.

### Checkpoint / Handoff — after CHROME-3

- **Frozen interfaces (this phase):** the default-route contract — `buildApp` opens on `AppShell` for every non-deep-link boot; a wired `captureSource` is the shell's opening Capture destination (not a bare screen); deep-link entries (`correctionEntry`/`comparisonEntry`/`recipesEntry`/`paletteEntry`) still open their screen directly. AC-1 (`TestAC01_BottomNav`) is un-pended and must stay green.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout`/`gtimeout`): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart d3a1c4f`; AC-1 `flutter test -d flutter-tester integration_test/visual_application/chrome_test.dart`; capture re-verify `flutter test -d flutter-tester integration_test/{capture_test,advanced_capture_test,readout_test}.dart` (run one at a time under load).
- **Known gaps / next (CHROME-4, AC-2):** mounts the shared `AppTopBar` on each destination (removing each screen's ad-hoc header), finalising title/back-close/theme-toggle. **Watch:** the shell holds no top bar of its own (so no double-`AppBar`); CHROME-4 must keep the capture suites' `find.widgetWithText(AppBar, 'Capture')`-style finders valid, and the nav-label-vs-AppBar disambiguation (AC-11 pattern) applies to any new bare-text screen-title assertion. Run **alone** (owns `build_app.dart`/shared chrome). After CHROME-4 the screen modules (READ/FLOW/ORG/CFG) run in parallel.

## Phase CHROME-4 — behavior: top bar (AC-2)

- **Kind:** behavior
- **Target AC:** AC-2 (full)
- **Depends on:** CHROME-3 · **Blocks:** GUARD-1
- **Files:** `lib/app/app_shell.dart`, the 4 destination screens' header mounts, `lib/app/theme.dart`.
- **Tasks:**
  1. Finalise `AppTopBar`: Atkinson title, back/close affordance per destination, theme-toggle control through the theme.
  2. Replace each destination's ad-hoc header with `AppTopBar`.
- **Exit criteria:** see acceptance gate; run alone (touches shared chrome).
- **Acceptance gate:** un-pend AC-2; `TestAC02_TopBar` green with all earlier ACs; sibling suites green.
