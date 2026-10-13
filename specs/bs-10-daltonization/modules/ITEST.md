# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/daltonization_harness.dart`, `integration_test/daltonization_test.dart`,
`integration_test/bs10/pending.dart` (seeded in DALT-1), reuse of `integration_test/fakes/fake_speech.dart`,
`fake_haptics.dart` and bs-07's `InMemoryPersistentStore` double.
**Depends on:** all shell phases (DALT-2, CONTROL-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ⬜ Todo | | |
| ITEST-2 | acceptance-tests | AC-1..10 (pending) | ⬜ Todo | | |
| ITEST-3 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the whole app assembled through `buildApp(deps)` — real `DisplayController`, real `daltonize`,
  real `ColorChip`/chokepoint rendering, real `CvdProfileStore`, real capture/readout/palette screens. Faked
  infrastructure only: `FakeSpeech`, `FakeHaptics`, `InMemoryPersistentStore` (behind the production
  `PersistentStore` contract). The remap (AC-1/5) is graded against an **independent** in-harness
  `referenceDaltonize`, never the shipped `daltonize`; AC-7's contrast uses the shipped `projectDichromat`.
- **Observation points:**
  - AC-1/5/7/9 → the rendered swatch colours (original + remapped, read off `ColorChip`/`Container`
    decoration) + `DisplayReadEndpoint.daltonization`; AC-1/5 graded vs `referenceDaltonize`, AC-7 vs
    `projectDichromat`; AC-9 samples the swatch on capture, readout and palette.
  - AC-2 → `DisplayReadEndpoint.daltonization == false` + rendered swatch == stored original.
  - AC-3/AC-4 → the label text + numeric value (AC-3) / the provenance badge label + icon (AC-4) still present
    while the swatch colour is remapped.
  - AC-6 → the rendered remap before vs after a `CvdProfileStore` save (recomputes to the new type).
  - AC-8 → `SampleSource` read of the stored `Sample` == original after a remapped render settles.
  - AC-10 → the keyed no-saved-profile region's message present (store empty) / absent (store saved), and no
    remap applied when empty.
- **Pending gate:** `bs10/pending.dart` exposes `acTestWidgets`, `pendingACs` (AC → owning phase) and
  `pendingSkipReason`; a pending AC is skipped by default and runs under `--dart-define=BS10_RUN_PENDING=true`.
  Un-pend = delete that AC's row (its owning behavior phase does this).
- **Environment:** device lane shared/contended → serialise device runs through `coord.sh with-lock`
  (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`); macOS has no `timeout` → redirect long sim runs to a file,
  don't tail a >120s foreground run; `flutter` is not on the default PATH (`export ~/development/flutter/bin`).

## Phase ITEST-1 — harness + fixtures + pending gate + smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** DALT-2, CONTROL-1 · **Blocks:** ITEST-2
- **Files:** `integration_test/daltonization_harness.dart`, `integration_test/daltonization_test.dart`,
  `integration_test/bs10/pending.dart`
- **Tasks:** build the Given/When/Then vocabulary over the wired shells (turn daltonization on via the control
  toggle; save/clear a profile via `CvdProfileStore`; read the rendered swatch + read endpoints); the fixtures
  (`savedProfile`, `noProfile`, `referenceDaltonize`, `screenColours`); re-export the pending gate + fakes; a
  never-pending smoke test proving the shells wire end to end (toggle reaches the controller, the chokepoint
  calls `daltonize`, the profile store is reachable), plus guard tests over the pending gate (every AC test
  exists; every pending key names a real phase) and fixtures.
- **Exit criteria:** suite green with all 10 ACs pending (skipped) by default; smoke + guards pass; `-d <udid>`
  documented.

## Phase ITEST-2 — AC-1..10 pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1..AC-10 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-3
- **Files:** `integration_test/daltonization_test.dart` (+ `bs10/pending.dart`)
- **Tasks:** one *pending* `acTestWidgets` per AC per the master-plan catalogue; record each one's run-pending
  red baseline (where it fails / that it is green at baseline) in **Red baseline** below; grade each against
  grade-A design. For the four green-at-baseline tests (AC-2/3/4/8), confirm the **Test augmentations** rows
  and keep the test as strong as it can be until its behavior phase adds the control.
- **Exit criteria:** suite green with the new tests pending; run-pending shows each non-trivial test failing on
  its Then / named Given precondition, and the four green-at-baseline tests passing (augmentation rows open);
  grade gate passed (all A, or *B pending <phase>* with a row).

## Phase ITEST-3 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue, red baseline, grades, fixtures, real-vs-faked, the four
  pre-seeded augmentations and which phase closes each) for a human. On **approved**, G-2 resolves and this
  phase is done; **changes requested** turns each item into an ITEST change phase before behavior, then a
  fresh review.
- **Exit criteria:** a human records the G-2 decision.

## Red baseline  <!-- filled by ITEST-2 (run-pending) -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_RemapForType | FAIL (expected) | Then: remapped != original (identity stub) | DALT-3 | — |
| AC-2 | TestAC02_OffShowsOriginal | green at baseline (limited) | — (off default + identity) → augment | DALT-6 | — |
| AC-3 | TestAC03_LabelAndValueKept | green at baseline (limited) | — (text always rendered) → augment | DALT-9 | — |
| AC-4 | TestAC04_ProvenanceBadgeReadable | green at baseline (limited) | — (label+icon always rendered) → augment | DALT-10 | — |
| AC-5 | TestAC05_UsesStoredProfile | FAIL (expected) | Then: remap == reference at stored type+severity | DALT-4 | — |
| AC-6 | TestAC06_ProfileChangeRecomputes | FAIL (expected) | Then: recompute after save (no listener yet) | DALT-11 | — |
| AC-7 | TestAC07_DistinctFromSimulation | FAIL (expected) | Then: remapped != projectDichromat (identity stub) | DALT-5 | — |
| AC-8 | TestAC08_StoredValuesUnchanged | green at baseline (limited) | — (display-only by construction) → augment | DALT-7 | — |
| AC-9 | TestAC09_EveryScreen | FAIL (expected) | Then: remapped on each screen (identity stub) | DALT-8 | — |
| AC-10 | TestAC10_NoProfileNeedsAssessment | FAIL (expected) | Then: no-profile message (placeholder empty) | CONTROL-2 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by ITEST-2; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC02 | Off == original holds at the shell (identity remap), so it can't yet show a *real* remap differs | DALT-6 | control: turning daltonization on remaps the swatch (changes from original) | ⬜ Open |
| TestAC03 | Label + value always render, so the test can't yet show they survive a *real* colour change | DALT-9 | assert the swatch colour changed while the label + numeric value stayed | ⬜ Open |
| TestAC04 | Badge label + icon always render, so the test can't yet show they survive a *real* colour change | DALT-10 | assert the badge colour is remapped while its label + icon stayed | ⬜ Open |
| TestAC08 | Display-only holds trivially while the remap is identity | DALT-7 | control: the displayed swatch did change while the stored value did not | ⬜ Open |
