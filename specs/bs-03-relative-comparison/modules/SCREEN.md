# Module SCREEN — comparison screen

**Status:** Done — SCREEN-1 shipped (module exit; the behaviour phases fill the regions from COMPARE/DIFF/CVD).
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/compare/comparison_screen.dart` (the host) and the **per-region widget files** it
composes — `slots_region.dart` (slots A/B + pickers E3/E5/E49 + swap E4), `difference_region.dart` (overall
ΔE00 + verdict), `statement_region.dart` (the three decomposition lines + "Same …" + the choose-B invite),
`confusion_region.dart` (the warning), `actions_bar.dart` (speak E6, open-readout E7/E8). The host and each
region are created as placeholders in SCREEN-1; the behaviour phases in **COMPARE / DIFF / CVD** fill their
**own** region file (disjoint ownership — see the master plan's parallel windows).
**Depends on:** COMPARE-2 (controller + read endpoint) · **Blocks:** ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 6,544,654 | 12m 51s |

(SCREEN has only the scaffold phase. Each region's behaviour is owned by the logic module that computes what
the region shows: slots/invite/swap/open-readout → COMPARE-3/5/6; difference → DIFF-2; statement/"Same …" →
DIFF-3; confusion → CVD-2; speak → CVD-3. This keeps every behaviour phase on a disjoint file.)

## Interface reconciliation

- The screen is a pure view over `ComparisonController`/`ComparisonState` (read through `AppScope` +
  `ComparisonReadEndpoint`); it holds no comparison logic. Region widgets take the already-computed values and
  callbacks, so a behaviour phase changes one region's rendering without touching the others.
- The comparison **layout** (Ledger / Sentence / Scales) is presentation and out of scope (spec Boundary);
  tests assert the strings/affordances are findable, not a particular arrangement.

## Open gates

- None.

## Phase 1 — Comparison screen scaffold (SCREEN-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** COMPARE-2 · **Blocks:** ITEST-1
- **Files:** `lib/compare/comparison_screen.dart` + `slots_region.dart`, `difference_region.dart`,
  `statement_region.dart`, `confusion_region.dart`, `actions_bar.dart` (all under `lib/compare/`).
- **Tasks:**
  1. The host `ComparisonScreen(controller)` composing the five region widgets, each a labelled placeholder
     bound to the controller/read endpoint (E3–E8, E49 present but inert).
  2. Each region renders a findable placeholder (empty slots, no statement, no warning, disabled actions) so
     the smoke test can confirm the wiring and later phases have a seam to fill.
  3. Keep behaviour unchanged (no selection, no math) — the shells still return placeholders.
- **Exit criteria:** `flutter analyze` clean; unit gate 100% on the new widgets; the app opens on the
  comparison entry and renders all five regions; existing suites green.
- **Acceptance gate:** *(shell — none)*

### Result

Landed `lib/compare/comparison_screen.dart` — `ComparisonScreen(controller)`, a pure view that lays out the
five regions in a scrolling body under the `Comparison` scaffold — and the five region widgets, each a
`StatelessWidget` taking the `ComparisonController` with a stable `regionKey`:
`SlotsRegion` (Slot A/B lines read from `state`; inert Choose A [E3] / Choose B [E5] / Sample picker [E49] /
Swap [E4]), `DifferenceRegion` (overall-difference placeholder, E-S1.R1), `StatementRegion` (relational-
statement placeholder), `ConfusionRegion` (warning placeholder) and `ComparisonActionsBar` (inert Speak [E6] /
Open readout A [E7] / Open readout B [E8]). `ComparisonHomeScreen.build` now renders `ComparisonScreen` under
the existing `ComparisonReadEndpoint`; the `_ComparisonShellBody` placeholder and the now-unused
`comparison_state` import are removed. The slot lines keep COMPARE-2's exact `Slot A: <name>` / `(empty)`
rendering, so every bs-01 handoff / build_app / router test stays green unedited.

- **Gates:** `flutter analyze` clean; unit **247 green** (was 241 — +6 new widget tests in
  `test/compare/comparison_screen_test.dart`), **100% line coverage on all six new files**; integration **17
  green** (bs-01 AC-9/AC-10 handoff lands on the real screen, behaviour preserved).
- **Acceptance gate:** none (shell).
- **Deviation from the file-ownership note:** Swap [E4] is placed in `SlotsRegion` (not the actions bar), per
  this plan's own ownership line (slots own E3/E5/E49 + swap E4; actions bar owns E6/E7/E8) — so COMPARE-5's
  swap stays on the slots file.
- **Fix passes:** 0/3 (all gates green on the first full run).
- **Tokens / Time:** 6,544,654 · 12m 51s.

### Checkpoint / Handoff

- **Frozen for the behaviour phases:** the screen is a pure view over `ComparisonController`. Each region is a
  `StatelessWidget` on a **disjoint file** with a `static const Key regionKey`; a behaviour phase fills its own
  region's rendering without touching the others. Controls are `TextButton(onPressed: null)` placeholders —
  enabling one is a region-local change.
  - Region → phase: `SlotsRegion` (Choose/invite seam, Swap) → COMPARE-3 / COMPARE-5; `DifferenceRegion` →
    DIFF-2; `StatementRegion` (decomposition + "Same …" + choose-B invite) → DIFF-3 / COMPARE-3;
    `ConfusionRegion` → CVD-2; `ComparisonActionsBar` (Speak, Open readout A/B) → CVD-3 / COMPARE-6.
  - Region keys: `comparison-slots-region`, `-difference-region`, `-statement-region`, `-confusion-region`,
    `comparison-actions-bar`. Placeholder bodies render the heading + `—`.
- **Known gaps (intended):** all controls inert; difference/statement/confusion show `—`; no invite logic yet
  (COMPARE-3 adds the AC-12 invite in `StatementRegion`). The `controller` field on the four placeholder
  regions is held for the binding but unread until its behaviour phase.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `flutter test integration_test/`.
- **Next:** ITEST-1 (acceptance-tests) — the harness over the wired shells can now find all five regions by
  key and the slot lines by text.
