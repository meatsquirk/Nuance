# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/display_harness.dart`, `integration_test/display_test.dart`, `integration_test/bs08/pending.dart` (seeded in DISPLAY-1), reuse of `integration_test/fakes/fake_speech.dart` + `fake_haptics.dart`.
**Depends on:** all shell phases (DISPLAY-2, SETTINGS-1, SPEECH-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| ITEST-2 | acceptance-tests | AC-1..7 (pending) | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-8,9,10 (pending) | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the whole app assembled through `buildApp(deps)` — real `DisplayController`, real `projectDichromat`, real `ColorChip`/root-grayscale rendering, real readout/comparison/recipes speech paths. Faked infrastructure only: `FakeSpeech`, `FakeHaptics`. The simulated colour (AC-3/AC-4) is graded against an **independent** in-harness `referenceProjectDichromat`, never the shipped projection.
- **Observation points:**
  - AC-1 → keyed finders for the settings entry (E2) and the panel's three controls (E46/E47/E48 + theme).
  - AC-2/AC-3/AC-4/AC-7 → the rendered swatch colours (original + simulated, read off `ColorChip`/`Container` decoration) + `DisplayReadEndpoint` (`simulationType`, `simulationSeverity`); AC-3/AC-4 graded vs `referenceProjectDichromat`.
  - AC-5 → `DisplayReadEndpoint` (`simulationType == null` after grayscale on) + the root grayscale filter active.
  - AC-6 → sampled rendered colours of the camera surface, a palette swatch and a reading are all achromatic (root saturation-0 filter).
  - AC-8/AC-9 → `FakeSpeech` log (utterance count + text equality; both reading and comparison recorded by the one sink).
  - AC-10 → the spoken-output panel (E50) still found after a long pump + settle.
- **Pending gate:** `bs08/pending.dart` exposes `acTestWidgets`, `pendingACs` and `pendingSkipReason`; a pending AC is skipped by default and runs under `--dart-define=BS08_RUN_PENDING=true`. Un-pend = delete that AC's row (its owning behavior phase does this).

## Phase ITEST-1 — harness + fixtures + pending gate + smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** SPEECH-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/display_harness.dart`, `integration_test/display_test.dart`, `integration_test/bs08/pending.dart`
- **Tasks:** build the Given/When/Then vocabulary over the wired shells; the fixtures (incl. `referenceProjectDichromat`); re-export the pending gate + fakes; a never-pending smoke test proving the shells wire end to end (settings open, controller reachable, speech wrapped), plus guard tests over the pending gate + fixtures.
- **Exit criteria:** suite green with all 10 ACs pending (skipped) by default; smoke + guards pass; `-d <udid>` documented.

## Phase ITEST-2 — AC-1..7 (display) pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1..AC-7 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/display_test.dart` (+ `bs08/pending.dart`)
- **Tasks:** one *pending* `acTestWidgets` per AC-1..7 per the catalogue; record each one's run-pending red baseline (where it fails) in **Red baseline** below; grade each against grade-A design.
- **Exit criteria:** suite green with the new tests pending; run-pending shows each failing on its Then / named Given precondition; grade gate passed. **Runs sequentially with ITEST-3** (shared test file).

## Phase ITEST-3 — AC-8,9,10 (speech) pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-8,9,10 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/display_test.dart` (+ `bs08/pending.dart`)
- **Tasks:** one *pending* `acTestWidgets` per AC-8..10; red baseline; grade. Shares the test file with ITEST-2 → sequence them.
- **Exit criteria:** as ITEST-2, for the speech ACs.

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue, red baseline, grades, fixtures, real-vs-faked) for a human. On **approved**, G-2 resolves and this phase is done; **changes requested** turns each item into an ITEST change phase before behavior, then a fresh review.
- **Exit criteria:** a human records the G-2 decision.

## Red baseline  <!-- filled by the AC-test phases (run-pending) -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_OpenDisplaySettings | FAIL (expected) | Then: three controls shown / Given: no settings surface (SETTINGS-2) | SETTINGS-2 | — |
| AC-2 | TestAC02_SimOffTrichromat | FAIL (expected) | Then: displayed == original identity path | DISPLAY-3 | — |
| AC-3 | TestAC03_SimulateTypeAlongsideOriginal | FAIL (expected) | Then: projected swatch + original alongside | DISPLAY-4 | — |
| AC-4 | TestAC04_SeveritySlider | FAIL (expected) | Then: render at severity 0.60 | DISPLAY-5 | — |
| AC-5 | TestAC05_GrayscaleClearsSimulation | FAIL (expected) | Then: grayscale on ⇒ sim off | DISPLAY-6 | — |
| AC-6 | TestAC06_GrayscaleWholeApp | FAIL (expected) | Then: camera + palettes + readings achromatic | DISPLAY-7 | — |
| AC-7 | TestAC07_ReadingKeepsValueAndLabel | FAIL (expected) | Then: value + label present under sim | DISPLAY-8 | — |
| AC-8 | TestAC08_RepeatSpokenOutput | FAIL (expected) | Then: identical utterance replayed | SPEECH-2 | — |
| AC-9 | TestAC09_OneConsistentPhrasing | FAIL (expected) | Then: both via the one sink | SPEECH-3 | — |
| AC-10 | TestAC10_PanelNeverAutoDismisses | FAIL (expected) | Then: panel present after long pump | SPEECH-4 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| — | none pre-seeded: each AC test discriminates at baseline on its own Then or a Given precondition naming its single owning behavior phase | — | — | — |
