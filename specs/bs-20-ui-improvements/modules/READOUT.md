# Module READOUT — Readout re-composition

**Status:** In progress — shells done (A11Y-1, READOUT-2); next the acceptance stage (ITEST-1)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/readout/` (`readout_screen.dart`, `value_region.dart`, `space_selector.dart` → removed, new `all_spaces_region.dart`, `value_scale.dart`, `space_definition.dart`, `actions_bar.dart`), user-facing copy strings in `lib/readout/`. Holds the bs-20 scaffold (READOUT-1).
**Depends on:** A11Y (READOUT-7 reads `DisplaySettings.accessibilityFeatures`) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| READOUT-1 | scaffold | — | ✅ Done | 3,024,669 | 6m 06s |
| READOUT-2 | shell | — | ✅ Done | 5,244,417 | 11m 09s |
| READOUT-3 | behavior | AC-4 | ⬜ Todo | | |
| READOUT-4 | behavior | AC-1, AC-3 | ⬜ Todo | | |
| READOUT-5 | behavior | AC-2 | ⬜ Todo | | |
| READOUT-6 | behavior | AC-5 | ⬜ Todo | | |
| READOUT-7 | behavior | AC-7, AC-8 | ⬜ Todo | | |
| READOUT-8 | behavior | AC-9 | ⬜ Todo | | |

## Interface reconciliation

- **Supersedes bs-01 AC-5** (one-space-at-a-time selector). READOUT-3 removes `SpaceSelector` and **retires the bs-01 AC-5 integration test** (`integration_test/bs01/.../*ac05*`): the one-at-a-time behaviour no longer exists. Record the retirement in READOUT-3's Result with reason (superseded by bs-20 AC-4).
- **Re-gates bs-01 AC-8** (Speak). READOUT-7 hides Speak when accessibility is off (default). bs-01's AC-8 test must be reconciled to **enable accessibility in its setup** so Speak is present; record the edit in READOUT-7's Result.
- **bs-01 AC-1 / AC-12 unchanged in meaning**: the value is still the prominent reading (now in a card) and the capture banner / Acknowledge stay as-is.
- Reads `DisplaySettings.accessibilityFeatures` through the existing `DisplayScope` (A11Y-1).

## Open gates

- **G-3** blocks READOUT-7: confirm default-hidden Speak doesn't regress bs-11 accessibility-conformance.

## Phase READOUT-1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — · **Blocks:** A11Y-1, READOUT-2
- **Files:** none in `lib/`; `integration_test/ui_improvements/` skeleton
- **Tasks:**
  1. Branch `feat/bs-20-ui-improvements` off `main` (after bs-19 merges if possible — D-1); record `BASE`.
  2. Baseline unit run (`flutter test test/`) + confirm the coverage gate passes clean and fails on a planted gap; confirm the `flutter-tester` integration runner.
  3. Create the empty suite dir `integration_test/ui_improvements/` (no tests yet).
- **Exit criteria:** branch pushed; baseline recorded; gate tooling verified; no `lib/` change.

### Result — READOUT-1

Scaffold complete; no `lib/` change. Landed:
- Branched `feat/bs-20-ui-improvements` off `main` (`BASE = 0551d5c`, the PLAN commit). D-1 advisory (branch after bs-19 merges) **not** honoured — bs-19 is still awaiting SIGNOFF-3; proceeded because this phase writes no `lib/` and so cannot collide on `build_app.dart`. bs-19 and bs-20 both touch `build_app.dart` in later phases — carry D-1 forward.
- **Baseline unit run:** `flutter test test/ --coverage` → **1643 pass / 0 fail**; `coverage/lcov.info` produced.
- **Coverage gate verified:** `dart run tool/coverage_gate.dart 0551d5c` → clean tree **PASS** (exit 0, "nothing to gate"); planted an untracked `lib/_planted_gap_bs20.dart` → **FAIL** (exit 1, "NO COVERAGE DATA"); planted file removed.
- **flutter-tester integration runner confirmed:** `flutter test -d flutter-tester integration_test/harness_test.dart` → exit 0, all passed.
- Created the empty suite dir `integration_test/ui_improvements/` with a `README.md` placeholder (git won't track an empty dir) documenting the per-file run command and the `BS20_RUN_PENDING` gate key.

Coverage gate: N/A (no `lib/` touched). Fix passes: 0/3. Tokens / time: see dashboard row.

### Checkpoint / Handoff — READOUT-1

- **Toolchain (reuse these):** `flutter` at `/Users/matthew.quirk/development/flutter/bin` (not on PATH — prepend it). Flutter 3.47.6 / Dart 3.13.5.
  - Unit + coverage: `flutter test test/ --coverage`
  - Coverage gate: `dart run tool/coverage_gate.dart <BASE>` (line coverage on touched `lib/**`; `COVERAGE_GATE_BASE` env or arg; `main` default). **Per-branch exercise is a phase/review duty, not enforced by the tool.**
  - This feature's acceptance suite (once it exists): `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart` **per file** (whole dir won't launch at once — house gotcha); pending gate `--dart-define=BS20_RUN_PENDING=true`.
  - No `timeout` on macOS (house gotcha) — run pushes/commands bare.
- **BASE for the next phase:** branch HEAD after this commit (A11Y-1 / READOUT-2 set their own `BASE=$(git rev-parse HEAD)`).
- **Known gaps:** none introduced. Carry: D-1 build_app.dart overlap with bs-19 (unmerged); 3 carried off-lane sibling flakes (bs-06 palette AC-3/5, bs-08 display AC-9, bs-07 self_assessment AC-4) per Known flakes.
- **Next:** A11Y-1 (flag + controller setter + panel toggle) ∥ READOUT-2 (readout widget shells) — different dirs, may run concurrently in separate sessions.

## Phase READOUT-2 — Readout widget shells

- **Kind:** shell
- **Target AC:** —
- **Depends on:** READOUT-1 · **Blocks:** ITEST-1
- **Files:** `lib/readout/value_region.dart`, new `value_scale.dart`, `all_spaces_region.dart`, `space_definition.dart`, `readout_screen.dart`
- **Tasks:**
  1. Introduce keyed shell widgets: value-hero card, `ValueScale` (0–10), `AllSpacesRegion` (renders every space), per-space `SpaceDefinition` reveal. Render honest placeholders; behaviour unchanged (selector still present until READOUT-3).
  2. Wire them into `ReadoutScreen` behind the existing regions without removing current behaviour.
- **Exit criteria:** unit gate passes; existing suites stay green; anchors findable.

### Result — READOUT-2

Shell complete; behaviour unchanged (the one-at-a-time `SpaceSelector` and every bs-01 reading stay).
Landed, following the capture-shell idiom (findable keyed placeholders; real content named for its
behaviour phase):
- **New `value_scale.dart`** — `ValueScale` shell (`scaleKey`); renders `SizedBox.shrink`. READOUT-5
  renders the 11-step 0..10 strip + marks the sample's step.
- **New `all_spaces_region.dart`** — `AllSpacesRegion` shell (`regionKey`); hosts one `SpaceDefinition`
  per `ReadoutSpace`. No space *values* and no duplicate name text yet (so the still-present selector's
  `find.text('Munsell')`-style finders stay unique). READOUT-3 renders the values + drops the selector.
- **New `space_definition.dart`** — `SpaceDefinition` shell (`nameKey(space)` / `definitionKey(space)`);
  renders an empty per-space anchor. READOUT-6 makes the name tappable + reveals definition + example.
- **`value_region.dart`** — added `heroCardKey`; wrapped the value content in a `KeyedSubtree` anchor
  (no visible change). READOUT-4 turns it into a real bordered card.
- **`readout_screen.dart`** — wired `ValueScale` (after the value region) and `AllSpacesRegion` (after
  the selector) into the `ListView`; updated the screen doc.

Gates: `flutter analyze lib/readout test/readout` clean; unit **1654 pass / 0** (+6 new readout tests);
coverage gate **100% on all 5 touched `lib/` files**. Existing-suite check: bs-01 readout integration
suite (`integration_test/readout_test.dart`, flutter-tester, under the verify lock) **12/12 green** —
AC-5 selector and AC-8 Speak unchanged. No AC (shell). Fix passes: 0/3.

### Checkpoint / Handoff — READOUT-2

- **Frozen anchors (for ITEST finders):** `ValueRegion.heroCardKey` (AC-1), `ValueScale.scaleKey`
  (AC-2), `AllSpacesRegion.regionKey` (AC-4), `SpaceDefinition.nameKey(space)` /
  `definitionKey(space)` (AC-5). The displayed-colour swatch (AC-3) stays the single `ColorChip` in
  `value_region.dart`; the grayscale swatch is `ValueRegion.grayscaleKey`.
- **Verification commands (reuse):** `flutter test test/ --coverage`; `dart run tool/coverage_gate.dart <BASE>`;
  per-file `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend to PATH); no `timeout` on macOS.
- **Shells carry no real behaviour** — each new widget renders an empty/invisible keyed placeholder; the
  acceptance tests for them are *pending* until their behaviour phase un-pends them. `AllSpacesRegion` and
  `ValueScale` take no controller yet (READOUT-3 / READOUT-5 add the inputs they read).
- **Next:** the acceptance stage opens — ITEST-1 (harness + fixtures + `BS20_RUN_PENDING` gate), then
  ITEST-2 ∥ ITEST-3 (the pending AC tests + red baseline), then ITEST-4 (test review, G-2). Carry: D-1 —
  bs-19 still unmerged, both features edit `build_app.dart` (bites later behavior phases, not ITEST).

## Phase READOUT-3 — All colour spaces at once (AC-4)

- **Kind:** behavior · **Target AC:** AC-4 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `all_spaces_region.dart`, `readout_screen.dart`, remove `space_selector.dart`
- **Tasks:** render CIELCh + Munsell + sRGB + CIELAB together; remove `SpaceSelector`; keep per-space labels (host for READOUT-6 definitions).
- **Acceptance gate:** un-pend AC-4; `TestAC04_AllSpaces` green; **retire bs-01 AC-5 test** (D-3) and keep bs-01 suite green.
- **Augments:** none

## Phase READOUT-4 — Hero value card + equal swatches (AC-1, AC-3)

- **Kind:** behavior · **Target AC:** AC-1 (full), AC-3 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `value_region.dart`
- **Tasks:** wrap the value in a bordered hero card with the value as the largest reading; size the displayed-colour swatch equal to the grayscale swatch.
- **Acceptance gate:** un-pend AC-1, AC-3; `TestAC01_HeroCard`, `TestAC03_EqualSwatches` green.

## Phase READOUT-5 — 0–10 value scale (AC-2)

- **Kind:** behavior · **Target AC:** AC-2 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `value_scale.dart`, `value_region.dart`
- **Tasks:** render an 11-step 0..10 scale with labels; mark the sample's Munsell value step.
- **Acceptance gate:** un-pend AC-2; `TestAC02_ValueScale` green.

## Phase READOUT-6 — Per-space definitions (AC-5)

- **Kind:** behavior · **Target AC:** AC-5 (full)
- **Depends on:** READOUT-3 (space labels exist), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `space_definition.dart`, `all_spaces_region.dart`
- **Tasks:** make each space name tappable → reveal the fuller definition + example (copy from the spec's B2 draft; owner may edit). No tap needed to see the values.
- **Acceptance gate:** un-pend AC-5; `TestAC05_Definitions` green.

## Phase READOUT-7 — Speak gating (AC-7, AC-8)

- **Kind:** behavior · **Target AC:** AC-7 (full), AC-8 (full)
- **Depends on:** A11Y-1, ITEST-4 (G-2), **G-3** · **Blocks:** SIGNOFF-1
- **Files:** `actions_bar.dart`
- **Tasks:** show the Speak control only when `accessibilityFeatures` is on (read via `DisplayScope`); hidden when off. Acknowledge/capture banner untouched.
- **Acceptance gate:** un-pend AC-7, AC-8; `TestAC07_SpeakHidden`, `TestAC08_SpeakShown` green; **reconcile bs-01 AC-8 test** (enable accessibility in setup) keeping bs-01 green.
- **Augments:** `TestAC07`: add the on→shown control so "hidden" isn't vacuous.

## Phase READOUT-8 — "Color" copy (AC-9)

- **Kind:** behavior · **Target AC:** AC-9 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** user-facing strings in `lib/readout/` (e.g. `ColorChip` label "Displayed colour" → "Displayed color", "grayscale"→"gray" where user-facing)
- **Tasks:** replace "Colour"/"colour" with "Color"/"color" in readout-screen copy; leave Dart `Color` type and code identifiers alone.
- **Acceptance gate:** un-pend AC-9; `TestAC09_ColorSpelling` green.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
