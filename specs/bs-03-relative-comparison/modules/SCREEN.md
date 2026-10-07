# Module SCREEN — comparison screen

**Status:** Not started
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
| 1 | shell | — | ⬜ Todo | | |

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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
