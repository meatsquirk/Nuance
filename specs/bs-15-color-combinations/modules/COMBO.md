# Module COMBO — controller, accessibility and persistence seam

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/combinations/combination_controller.dart` · `combination_state.dart` · `combination_read_endpoint.dart` · `combination_anchor.dart` · `combination_reference.dart` (reference-provenance marker) · `combination_speech.dart` · `combination_confusion.dart` · `project_sink.dart` (`ProjectSink`/`InMemoryProjectSink`) · `lib/app/build_app.dart` (combinations entry) · `lib/app/router.dart` (`toCombinations`)
**Depends on:** LIB (types + `CombinationLibrary`), bs-01 `SampleSource`/`Speech`/`ConfusionCheck`/`CvdProfile`/`ColorScience`/`words.dart`, (AC-2) bs-04 `Paint`/`PaintPalette`/`PaletteSource` · **Blocks:** SCREEN, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-1 | ⬜ Todo | | |
| 3 | behavior | AC-5, AC-11 | ⬜ Todo | | |
| 4 | behavior | AC-6 | ⬜ Todo | | |
| 5 | behavior | AC-7, AC-8 | ⬜ Todo | | |
| 6 | behavior | AC-12 | ⬜ Todo | | |
| 7 | behavior | AC-2 | ⬜ Todo (G-3) | | |

## Interface reconciliation

- **Exposes:** `CombinationController` over `{CombinationLibrary, SampleSource, PaletteSource?, ConfusionCheck, CvdProfile, Speech, ProjectSink, AppRouter}`; `CombinationState {CombinationAnchor? anchor; List<CombinationSuggestion> suggestions; ColorCombination? selected; List<ConfusionPair> confusionFlags; List<ColorCombination> browseResults; List<ColorCombination> searchResults; ProjectRecord? lastSaved}`; `CombinationReadEndpoint` (test observation of all of the above); `CombinationAnchor {ColorCoordinates coordinates; String label}`; `CombinationReference` (the aesthetic-source provenance marker, **not** a `ProvenanceTier`); `ProjectSink.save(projectId, ProjectRecord)` + `InMemoryProjectSink`.
- **Consumes:** `CombinationLibrary.suggestFor/browse/search`; `ConfusionCheck.isConfusable(a,b,profile)`; `Speech.speak`; `ColorScience` for the readout; `SampleSource`/`PaletteSource` for anchors.
- **Reconciliation:** the `ProjectSink` seam is bs-15's; **bs-06** replaces `InMemoryProjectSink` with the persistent store behind the same method (D-10). `CvdProfile` is injected; a v1 default is used until **bs-07** writes the real profile (G-4(d)).

## Open gates

- **G-3** (bs-04 `Paint`/`PaintPalette`/`PaletteSource` on `main`) blocks **COMBO-3** only.
- **G-4** (provenance wording / default profile) blocks **COMBO-4** (label text) and **COMBO-6** (default profile acceptability).

## Phase 1 — Shell: controller, state, read endpoint, entry, seam (COMBO-1)

- **Kind:** shell
- **Target AC:** — (read endpoint the acceptance tests observe)
- **Depends on:** LIB-2 · **Blocks:** SCREEN-1, ITEST-1
- **Files:** `combination_controller.dart`, `combination_state.dart`, `combination_read_endpoint.dart`, `combination_anchor.dart`, `project_sink.dart`, `lib/app/build_app.dart` (combinations entry), `lib/app/router.dart` (`toCombinations`)
- **Tasks:**
  1. `CombinationState` + `CombinationController` (fields null/empty; setters pend behaviour) and `CombinationAnchor`.
  2. `CombinationReadEndpoint` exposing anchor / suggestions / selected / confusionFlags / browseResults / searchResults / lastSaved.
  3. `ProjectSink` + `InMemoryProjectSink` (`ProjectRecord` = combination + provenance; later a mix-plan too for bs-16).
  4. A `buildApp` `combinationsEntry` → `CombinationsHomeScreen` owning the controller, wrapped in a `CombinationReadEndpoint`, behind a new `AppRouter.toCombinations` route (symmetric to bs-02/03/04).
- **Exit criteria:** unit gate; existing suites green; app builds with the new route; endpoint readable; no behaviour yet.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Behaviour: saved-sample anchor (COMBO-2)

- **Kind:** behavior
- **Target AC:** AC-1
- **Depends on:** LIB-3 (the suggest query), COMBO-1 · **Blocks:** COMBO-3/4/5/6/7, LIB-4
- **Files:** `combination_controller.dart`, `combination_anchor.dart`
- **Tasks:**
  1. Choosing a saved `Sample` from `SampleSource` sets `state.anchor` (coordinates + name label) and runs `CombinationLibrary.suggestFor` → `state.suggestions`.
  2. Unit-test anchor-set + suggestions-populated + re-anchoring replaces.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-1; `TestAC01_SampleAnchor` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — Behaviour: per-colour readout + reference provenance (COMBO-4)

- **Kind:** behavior
- **Target AC:** AC-5 (name + L/C/h + warm/cool, not a swatch alone), AC-11 (Wada reference provenance)
- **Depends on:** COMBO-2, (G-4 label text) · **Blocks:** SIGNOFF-1
- **Files:** `combination_reference.dart`, `combination_controller.dart` (readout model), SCREEN per-colour row region
- **Tasks:**
  1. For each `WadaColor` build a readout: the historical name + L/C/h from `ColorScience` + a warm/cool word from `words.dart`.
  2. `CombinationReference` marker ("Sanzo Wada — A Dictionary of Color Combinations", G-4 text), rendered distinctly and **never** as a paint tier.
  3. Unit-test the readout model + the provenance marker (and that no paint-tier string is emitted).
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-5, AC-11; `TestAC05_NamedWithValues`, `TestAC11_ReferenceProvenance` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 4 — Behaviour: speak a combination (COMBO-5)

- **Kind:** behavior
- **Target AC:** AC-6
- **Depends on:** COMBO-2 · **Blocks:** SIGNOFF-1
- **Files:** `combination_speech.dart`, `combination_controller.dart`
- **Tasks:**
  1. Build one utterance: the combination's identity + each colour's name with its L, C and h; speak via `Speech`.
  2. Unit-test the utterance text + exactly-one-utterance.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-6; `TestAC06_SpeakCombination` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 5 — Behaviour: confusion-pair flag + control (COMBO-6)

- **Kind:** behavior
- **Target AC:** AC-7 (confusable pair flagged), AC-8 (no confusable pair → not flagged)
- **Depends on:** COMBO-2, (G-4 default profile) · **Blocks:** SIGNOFF-1
- **Files:** `combination_confusion.dart`, `combination_controller.dart`
- **Tasks:**
  1. Over each unordered pair of a combination's colours run `ConfusionCheck.isConfusable(a,b,profile)`; collect `ConfusionPair`s into `state.confusionFlags`.
  2. Flag only when a pair is confusable (the AC-8 control must stay unflagged).
  3. Unit-test both the confusable and non-confusable combinations under `PROFILE_DEUTAN_MOD`.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-7, AC-8; `TestAC07_ConfusionFlagged`, `TestAC08_NoConfusionNotFlagged` green.
- **Augments:** none (control is in-fixture).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 6 — Behaviour: save to a project (COMBO-7)

- **Kind:** behavior
- **Target AC:** AC-12
- **Depends on:** COMBO-2 · **Blocks:** SIGNOFF-1
- **Files:** `project_sink.dart`, `combination_controller.dart`
- **Tasks:**
  1. Save action writes a `ProjectRecord` (combination colours + `CombinationReference`) to the open project via `ProjectSink`.
  2. Unit-test the saved record content + that it targets the open project.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-12; `TestAC12_SaveToProject` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 7 — Behaviour: owned-paint anchor (AC-2) — gated by G-3 (COMBO-3)

- **Kind:** behavior
- **Target AC:** AC-2
- **Depends on:** COMBO-2, **G-3** (bs-04 `Paint`/`PaintPalette`/`PaletteSource` on `main`) · **Blocks:** SIGNOFF-1
- **Files:** `combination_anchor.dart`, `combination_controller.dart`, `lib/app/build_app.dart` (inject `PaletteSource`)
- **Tasks:**
  1. Choosing an owned `Paint` from the selected `PaintPalette` sets `state.anchor` (the paint's masstone + its name) and runs `suggestFor`.
  2. Unit-test the paint-sourced anchor + suggestions.
- **Exit criteria:** unit + coverage; **Acceptance gate** below.
- **Acceptance gate:** un-pend AC-2; `TestAC02_PaintAnchor` green.
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
