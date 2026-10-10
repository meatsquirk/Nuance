# Module SCREEN — Correction screen UI

**Status:** Done — SCREEN-1 complete; the shell stage is closed.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/correction/correction_screen.dart` + per-region keyed widgets under `lib/correction/regions/` (`check_region.dart`, `difference_region.dart`, `correction_region.dart`, `speak_region.dart`, `rephotograph_region.dart`, `save_region.dart`)
**Depends on:** LOOP (controller/state/endpoint), CORRECT (`Difference`/`Correction` types) · **Blocks:** the behaviour phases render into these regions

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 5,078,443 | 9m 25s |

(No separate SCREEN behaviour phases: each behaviour phase in LOOP/CORRECT renders into its own region widget — the master plan's *Parallel windows* explains why this keeps the screen side file-disjoint.)

## Interface reconciliation

- `CorrectionScreen({required CorrectionController controller})`, rendered inside `CorrectionReadEndpoint` by `CorrectionHomeScreen`. It lays out the regions; each region widget carries a `static const Key regionKey` the harness finds by `find.byKey(...)`, mirroring bs-04's region pattern (`TargetRegion`, `RecipeListRegion`, `GamutBanner`).
- Region → AC / element map:
  - `CheckRegion` — **E26** "Check my mix" (AC-1, filled by LOOP-3).
  - `DifferenceRegion` — the difference body: ΔE00 + verdict + the value-leading decomposition (AC-2/AC-3, CORRECT-2); the within-tolerance "very close" state (AC-6, CORRECT-4).
  - `CorrectionRegion` — the correction body: paint + amount, "a touch of" for traces (AC-4/AC-5, CORRECT-3); the **no-correction** state when within tolerance (AC-6, CORRECT-4).
  - `SpeakRegion` — **E27** "Speak correction" (AC-7, LOOP-4).
  - `RephotographRegion` — **E28** "Re-photograph swatch" (AC-8, LOOP-5).
  - `SaveRegion` — **E29** "Save confirmed mix" (AC-9, LOOP-6); the confirmed provenance surfaces in a later readout's `ProvenanceBadge` (AC-10, reused from bs-01/bs-06), not on this screen.

## Open gates

- None of its own. The region **contents** inherit G-4 (verdict words, amounts, label) from CORRECT/LOOP.

## Phase 1 — Correction screen scaffold (SCREEN-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** LOOP-2 · **Blocks:** every behaviour phase
- **Files:** `correction_screen.dart` + the six keyed region widgets, all inert (placeholder content bound to `controller`/`state`, no behaviour)
- **Tasks:**
  1. Build `CorrectionScreen` with the six region widgets, each with its `static const Key regionKey`, reading from the controller but asserting nothing yet.
  2. Ensure `CorrectionHomeScreen` (LOOP-2) renders it under the read endpoint.
  3. 100% coverage on touched files; the existing suite stays green; the smoke test (ITEST-1) can find every `regionKey`.
- **Exit criteria:** `flutter analyze` clean; unit + coverage gate pass on touched files; behavior unchanged (the screen is reachable only via the new `correctionEntry`/`toCorrection`).

### Result

Inert Correction screen complete — the shell stage is closed. `CorrectionScreen` (a pure
`ListenableBuilder` view over the frozen LOOP-2 `CorrectionController`) lays out the six region
widgets in loop order and replaces `CorrectionHomeScreen`'s placeholder body under the read
endpoint.

- **Landed:** `lib/correction/correction_screen.dart`; `lib/correction/regions/{check,difference,correction,speak,rephotograph,save}_region.dart`, each with its `static const Key regionKey`. `CheckRegion(controller:)` binds to the controller and renders the `Correction target: <name>` line (the handoff render AC-11/router rely on); the other five are inert placeholders / disabled controls (E27/E28/E29 + the difference/correction pre-check text). `build_app.dart`: `CorrectionHomeScreen.build` now renders `CorrectionScreen` (import + docstring updated); the controller ownership and `CorrectionReadEndpoint` stay there.
- **Controls disabled in the shell** (`onPressed: null`); each is wired by its behaviour phase — E26 Check → LOOP-3, E27 Speak → LOOP-4, E28 Re-photograph → LOOP-5, E29 Save → LOOP-6; the difference/correction bodies → CORRECT-2/3/4. Only `CheckRegion` takes the controller for now; the other regions gain their controller binding when their behaviour phase wires the real read (shell→behaviour ctor growth, as bs-04's regions did).
- **Gates:** `flutter analyze` clean; `flutter test --coverage` green (632 tests, +6 new in `test/correction/correction_screen_test.dart`); coverage gate **100%** on all 14 touched `lib/**` files (the six regions, the screen, `build_app.dart`, + the untouched-but-diffed correction/engine files). Existing `build_app`/`router` assertions (`Correction target: <name>`) stay green because `CheckRegion` keeps that exact text. No acceptance/grade gate (shell kind); integration suite not run (no harness until ITEST-1).
- **Fix passes:** 1/3 — first gate run had 5 failures in the *new test* only (`find.widgetWithText(ButtonStyleButton,…)` matches exact runtime type, not the abstract button); switched to `find.ancestor(of: text, matching: find.bySubtype<ButtonStyleButton>())`. No implementation change.
- **Tokens / Time:** 5,078,443 / 9m 25s (active = wall) (this phase).

### Checkpoint / Handoff

- **Frozen for the behaviour phases (LOOP-3/4/5/6, CORRECT-2/3/4):**
  - `CorrectionScreen({required CorrectionController controller})` — the Scaffold ("Correction" app bar) + `SafeArea` + `ListView` of the six regions, wrapped in a `ListenableBuilder` on the controller so a phase's state change rebuilds the regions.
  - Region widgets + anchors (find by `<Region>.regionKey`): `CheckRegion` `'correction-check-region'` (E26), `DifferenceRegion` `'correction-difference-region'`, `CorrectionRegion` `'correction-correction-region'`, `SpeakRegion` `'correction-speak-region'` (E27), `RephotographRegion` `'correction-rephotograph-region'` (E28), `SaveRegion` `'correction-save-region'` (E29). These keys are the smoke test's (ITEST-1) anchors — don't rename them.
  - Each behaviour phase rewrites **one region's body** (and adds `controller`/state reads + the real `onPressed`) — file-disjoint, so the behaviour phases stay parallel-safe. The button labels above are the current render; a phase may restyle within its region.
- **Verification commands:** unchanged from LOOP-2 (`export PATH="$HOME/development/flutter/bin:$PATH"`; `flutter analyze`; `flutter test --coverage`; `dart run tool/coverage_gate.dart main`; integration under the verify lock on sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`).
- **Next phase:** ITEST-1 (acceptance-tests) — the harness over the wired shells + fixtures/scenes + the pending gate (10 ACs) + smoke test that finds every `regionKey`. Then ITEST-2 ∥ ITEST-3 (one pending test per AC + red baseline; **G-4** gates ITEST-3), then the ITEST-4 test review (**G-2**).
- **Known gaps / notes:** no behaviour yet (every control disabled, every action still throws per LOOP-2). The `const`-constructor coverage flake from LOOP-1 still applies — re-run `flutter test --coverage` once if the gate flags an untouched file.
