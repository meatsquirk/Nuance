# Module CHROME — app chrome (scaffold, bottom nav, top bar)

**Status:** In progress — CHROME-1 done; next CHROME-2 (shell)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/app/build_app.dart`, `lib/app/theme.dart` (nav/appbar theme tokens only), new `lib/app/app_shell.dart` (nav scaffold) and `lib/app/app_destinations.dart`; the `BS18_RUN_PENDING` runner + coverage gate tooling it establishes (scaffold).
**Depends on:** — · **Blocks:** ITEST (CHROME-2), all screen modules (they wire through `build_app.dart`)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| CHROME-1 | scaffold | — | ✅ Done | 5.04M | 16m (16m) |
| CHROME-2 | shell | — | ⬜ Todo | | |
| CHROME-3 | behavior | AC-1 | ⬜ Todo | | |
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

G-1 (approve the spec) ✅ Resolved 2026-10-19 07:33 EDT: approved — Matt Quirk; CHROME-1 startable. G-2 (approve the tests) blocks CHROME-3, CHROME-4.

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

## Phase CHROME-3 — behavior: bottom navigation (AC-1)

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** CHROME-4, GUARD-1
- **Files:** `lib/app/app_shell.dart`, `lib/app/theme.dart`, `lib/app/build_app.dart`.
- **Tasks:**
  1. Finalise the NavigationBar treatment to the design system (surface fill, ink/accent tokens, Atkinson labels, selected glyph) and the non-colour-only active indicator (selected label weight + filled glyph).
  2. Ensure all 4 destinations are reachable and the active one is marked.
- **Exit criteria:** see acceptance gate; run alone (owns `build_app.dart`).
- **Acceptance gate:** un-pend AC-1; `TestAC01_BottomNav` green with all earlier ACs; sibling suites green.

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
