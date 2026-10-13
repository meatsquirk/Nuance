# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-2 (AC-1..10 pending + red baseline + grades) done; next ITEST-3 (test review, G-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/daltonization_harness.dart`, `integration_test/daltonization_test.dart`,
`integration_test/bs10/pending.dart` (seeded in DALT-1), reuse of `integration_test/fakes/fake_speech.dart`,
`fake_haptics.dart` and bs-07's `InMemoryPersistentStore` double.
**Depends on:** all shell phases (DALT-2, CONTROL-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 5.74M | 27m 19s |
| ITEST-2 | acceptance-tests | AC-1..10 (pending) | ✅ Done | 12.25M | 34m 01s |
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

### Result — ITEST-1  <!-- 2026-10-13 -->

- **New `integration_test/daltonization_harness.dart`:** the Given/When/Then vocabulary over the wired shells —
  `givenDaltonization` assembles the real app via `buildApp` (Readout entry) with faked `FakeSpeech`/`FakeHaptics`,
  an injected `DisplayController`, and an `InMemoryPersistentStore` behind the production `CvdProfileStore`; the
  `DaltonizationHarness` exposes `whenOpenSettings`/`whenSetDaltonization(on:)` (the CONTROL-1 toggle),
  `whenSaveProfile`/`whenClearProfile` (the real store write-side), and the read seams `daltonization`,
  `displayedColor`, `displayedSwatches`, and finders for the toggle + no-profile region + provenance badge.
- **Fixtures:** `savedProfile(type, {severity})` + `noProfile` (store states the given persists/leaves empty);
  `screenSample` (reuses bs-08's proven in-gamut olive `L55/a-25/b30`, measured provenance); `screenSwatchColor`
  + `displayColorOf`/`colorNear`/`displaySwatches` colour helpers.
- **Independent reference `referenceDaltonize`:** an error-redistribution remap built on bs-08's independent
  `referenceProjectDichromat` (imported with `show`, then re-exported) — rotates the chroma the dichromat loses
  90° in a*/b* and adds it back scaled by severity, preserving lightness; identity at severity 0. Never grades
  the shipped `daltonize` against itself (D-2).
- **Pending gate / fakes re-exported** from the harness so an AC test imports only it. `display_harness.dart` is
  **not** re-exported wholesale (its `bs08/pending.dart` names would collide with bs-10's) — only
  `referenceProjectDichromat` + `labDistance` are, via `show`.
- **`daltonization_test.dart`:** 3 pending-gate scaffold guards (map is exactly the 10 pending ACs, `hasLength(10)`
  — non-vacuous; every owner a real behaviour phase; skips pending by default / runs under run-pending), 9 fixture
  guards over `referenceDaltonize` (identity@0, grey stays grey, lightness preserved, clear shift, distinct from
  projection, monotone severity, near-black finite) + the colour helpers, and 3 never-pending smoke tests (toggle
  reaches the controller; the one chokepoint routes through `daltonize` when on, winning over an active simulation
  per D-5; the profile store is reachable — saved persists, empty reports none, clear empties it). No `acTestWidgets`
  yet (ITEST-2).
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1239 unit pass** (unchanged — no product/unit
  code touched) · `dart run tool/coverage_gate.dart main` → **100% on all touched files** (branch-vs-main
  cumulative set; ITEST-1 touched no `lib/`) · full `integration_test/` on booted iPhone 17 (`-d 5AB9D06D…`, under
  `coord.sh with-lock`) → **212 pass** (197 prior + 15 new), exit 0, all bs-10 ACs skipped (none registered yet).
- Coverage (touched `lib/`): n/a (no product code). Acceptance: suite green, 0 ACs registered. Fix passes: 0/3
  (all gates green on first run; the 12 host-runnable guards verified on host before the sim run).
- Tokens/time: 5.74M · 27m 19s (1 session).
- Closed by: analyze + unit + coverage gates green; new suite green on the sim with the smoke + guards passing;
  existing 197 integration tests unchanged.

### Checkpoint / Handoff — ITEST-1

- **Frozen for ITEST-2:**
  - `givenDaltonization(tester, {sample, storedProfile, initialSettings})` → `DaltonizationHarness`; the AC tests
    drive it. `storedProfile: savedProfile(type, severity)` persists + injects that profile; `storedProfile:
    noProfile` leaves the store empty (const-default fallback) for AC-10.
  - Grade the remap only against `referenceDaltonize(_, h.storedProfile)` (AC-1/AC-5), never the shipped
    `daltonize`; AC-7's contrast uses the re-exported `referenceProjectDichromat`. Read the displayed colour via
    `h.displayedColor(original)` and the rendered swatch via `h.displayedSwatches` / `displaySwatches(tester)`.
  - `bs10/pending.dart` (re-exported) is the un-pend registry; `acTestWidgets('AC-n', …)` auto-skips pending ACs.
    ITEST-2 registers one per AC and adds a guard that **every** AC-1..10 test exists (the "no vacuous pass" rule).
- **ITEST-2 writes** one pending `acTestWidgets` per AC per the master-plan catalogue, records each one's
  run-pending red baseline in the **Red baseline** table below (AC-2/3/4/8 are expected *green at baseline* — the
  identity remap keeps all text/icons and off==original; their controls come in DALT-6/9/10/7), and grades them.
  **Known seams ITEST-2/behaviour must wire:** `CvdProfileReadEndpoint` has **no `hasSavedProfile` getter yet** and
  is mounted only by the onboarding host (not the main `buildApp` tree) — AC-10 (CONTROL-2) adds the getter and
  mounts the endpoint above the settings panel; the harness reads the store directly (`h.profileStore`) until then.
  AC-6's live recompute (DALT-11) needs the chokepoint to listen to `CvdProfileStore` — `whenSaveProfile` only
  writes the store today, so the pending AC-6 fails at red baseline on its Then (no re-render), as planned.
  AC-9's three-screen navigation (capture/readout/palette) is not yet in the harness — ITEST-2 extends it (the
  Readout shows the swatch through the shared `ColorChip` chokepoint; capture/palette entries are `captureSource`
  / `paletteEntry`).
- **Verification commands:** unchanged from CONTROL-1 — Flutter SDK not on default PATH (prepend
  `/Users/matthew.quirk/development/flutter/bin`); `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (host); the pure `test()` guards run on host (fast feedback), but the
  `testWidgets` smoke/AC tests need a **booted** sim (`flutter test integration_test/daltonization_test.dart -d
  5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`, run-pending adds `--dart-define=BS10_RUN_PENDING=true`) under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash -c
  'cd /Users/matthew.quirk/Nuance-bs10 && …'`. macOS has no `timeout`; redirect long sim runs to a file (the full
  suite exceeds a 600s foreground budget).

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

### Result — ITEST-2  <!-- 2026-10-13 -->

- Registered one *pending* `acTestWidgets` per AC (AC-1..AC-10) in `daltonization_test.dart` (appended after
  ITEST-1's harness + smoke), plus top-level grade helpers `_remapOf` + `_expectKnownSwatchRemapped` that grade
  the *rendered* swatch against the independent `referenceDaltonize` (never the shipped `daltonize`).
- Extended the harness (ITEST owns it) for AC-9's three screens: `givenDaltonizationOnCapture`
  (`FakeCaptureSource` over `captureScene`, bounded-frame settle — the live feed never idles, so no
  `pumpAndSettle`) and `givenDaltonizationOnPalette` (one-paint `screenPalette` via `InMemoryPaletteSource`),
  both sharing a new private `_assembleDaltonization` core with `givenDaltonization`. New fixtures `captureScene`,
  `screenPaint`, `screenPalette`. AC-9 seeds `DisplaySettings(daltonization: true)` (its toggle is AC-1/AC-2's
  concern) so the capture leg needs no tap on the live-feed screen.
- **Gates:** `flutter analyze` clean (whole project) · `flutter test --coverage` **1239 unit pass** (unchanged —
  no `lib/` touched) · `coverage_gate.dart main` **100% on all 8 cumulative touched files** (ITEST-2 touched no
  `lib/`) · default sim run (iPhone 17, `coord.sh with-lock`) **+15 / 10 pending** suite green · run-pending red
  baseline **+19 / −6** (EXIT 1 expected): AC-2/3/4/8 green-at-baseline, AC-1/5/6/7/9/10 each fail on its tight
  Then/precondition (identity remap; empty no-profile placeholder) — all assertion failures, no harness errors.
- **Grades (fresh independent grader):** **6 A / 4 B-pending** — A: AC-1/5/6/7/9/10; B pending: AC-2→DALT-6,
  AC-3→DALT-9, AC-4→DALT-10, AC-8→DALT-7 (the planned green-at-baseline limits; each augmentation row confirmed
  open). No below-A rubric defects. Grid: `behavior-test-completeness-bs-10-daltonization.md`.
- **Correction vs the ITEST-1 handoff:** the provenance badge is *not* on the Readout (`ProvenanceBadge` lives
  only in palette paint rows); the Readout states provenance via `ProvenanceRegion` text ('Measured'). AC-4
  asserts that tier label (still green at baseline). No AC weakened; `h.provenanceBadge` left in place for DALT-10.
- Coverage (touched `lib/`): n/a (no product code). Acceptance: suite green, 0 ACs un-pended (all 10 stay pending
  per plan; behaviour phases un-pend). Fix passes: 0/3 (two host-caught compile fixes before the first sim run —
  a missing `widgets.dart` import and AC-4 badge→region; all gates green on the first sim run).
- Tokens/time: 12.25M · 34m 01s (1 session).
- Closed by: analyze + unit + coverage green; default suite green with all 10 ACs pending; run-pending red
  baseline matches the table; grade gate 6 A / 4 B-pending with open augmentation rows.

### Checkpoint / Handoff — ITEST-2

- **Frozen:** the 10 `acTestWidgets` and `bs10/pending.dart` are the un-pend registry; each behaviour phase
  deletes its AC's row *and* adds its AC to the `unpended` set in the scaffold guard in `daltonization_test.dart`.
- **DALT-3 (AC-1 keystone):** `_expectKnownSwatchRemapped` asserts the rendered swatch is
  `colorNear(displayColorOf(referenceDaltonize(SCREEN_SAMPLE_LAB, profile)))` and that none equals the original —
  so the shipped `daltonize` must agree with the independent `referenceDaltonize` within `colorNear` (summed
  ≈24/255) or AC-1/5/9 will not go green (disclosed design coupling, D-2; the G-2 review confirms the reference is
  a fair grader). AC-1 iterates all three `CvdType.values`.
- **DALT-8 (AC-9):** the capture/palette legs are first *exercised* once DALT-3 makes the readout leg pass. DALT-8
  must surface the known swatch through the shared `ColorChip` chokepoint on capture (`CaptureReadingsList`'s
  `ColorChip` currently carries no `color`) and palette (`palette_screen`/`paint_list_region` render no `ColorChip`
  swatch today), so both remap like the Readout.
- **DALT-11 (AC-6):** the test reads the *rendered* swatch (not `h.displayedColor`, which uses the build-time
  profile), so DALT-11's live `CvdProfileStore` listener is what turns it green; `whenSaveProfile` only writes the
  store today.
- **CONTROL-2 (AC-10):** reads `h.profileStore` directly (`CvdProfileReadEndpoint` still has no `hasSavedProfile`
  and is unmounted); CONTROL-2 fills the keyed `noProfileRegion` with the self-assessment message (empty
  placeholder today → the test fails on it) and the control (saved profile → no message).
- **Verification commands:** unchanged from ITEST-1 (analyze/unit/coverage on host; sim run under
  `coord.sh with-lock`, `--dart-define=BS10_RUN_PENDING=true` for run-pending; macOS no `timeout` → redirect).
- **Next:** ITEST-3 (test review, **G-2**) — assemble the packet from these 10 tests; a human approves G-2 before
  any behaviour phase (DALT-3..11, CONTROL-2) may start.

## Phase ITEST-3 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue, red baseline, grades, fixtures, real-vs-faked, the four
  pre-seeded augmentations and which phase closes each) for a human. On **approved**, G-2 resolves and this
  phase is done; **changes requested** turns each item into an ITEST change phase before behavior, then a
  fresh review.
- **Exit criteria:** a human records the G-2 decision.

## Red baseline  <!-- filled by ITEST-2 (run-pending) -->

Confirmed on the run-pending sim run (iPhone 17, under `coord.sh with-lock`): **+19 / −6** — the four
green-at-baseline tests pass; the six behaviour-pending tests each fail on a tight Then/precondition (no
harness/compile errors). Default run **+15 / 10 pending** (suite green). Grid:
[behavior-test-completeness-bs-10-daltonization.md](../behavior-test-completeness-bs-10-daltonization.md).

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_RemapForType | FAIL (confirmed) | Then: swatch == referenceDaltonize per type (identity stub leaves it original) | DALT-3 | A |
| AC-2 | TestAC02_OffShowsOriginal | green at baseline (limited) | — (off default + identity) → augment | DALT-6 | B pending DALT-6 |
| AC-3 | TestAC03_LabelAndValueKept | green at baseline (limited) | — (label+value text always rendered) → augment | DALT-9 | B pending DALT-9 |
| AC-4 | TestAC04_ProvenanceBadgeReadable | green at baseline (limited) | — (provenance tier label always rendered) → augment | DALT-10 | B pending DALT-10 |
| AC-5 | TestAC05_UsesStoredProfile | FAIL (confirmed) | Then: swatch == reference at stored type+severity (identity stub) | DALT-4 | A |
| AC-6 | TestAC06_ProfileChangeRecomputes | FAIL (confirmed) | Then/before: deutan remap (identity stub; no listener for the saved change) | DALT-11 | A |
| AC-7 | TestAC07_DistinctFromSimulation | FAIL (confirmed) | precond: the remap moves the colour (identity stub) | DALT-5 | A |
| AC-9 | TestAC09_EveryScreen | FAIL (confirmed) | Then: readout swatch == referenceDaltonize (identity stub; capture/palette legs reached once readout passes) | DALT-8 | A |
| AC-8 | TestAC08_StoredValuesUnchanged | green at baseline (limited) | — (display-only; off→on→off round-trip) → augment | DALT-7 | B pending DALT-7 |
| AC-10 | TestAC10_NoProfileNeedsAssessment | FAIL (confirmed) | Then: no-profile region reports self-assessment (placeholder empty) | CONTROL-2 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by ITEST-2; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC02 | Off == original holds at the shell (identity remap), so it can't yet show a *real* remap differs | DALT-6 | control: turning daltonization on remaps the swatch (changes from original) | ⬜ Open |
| TestAC03 | Label + value always render, so the test can't yet show they survive a *real* colour change | DALT-9 | assert the swatch colour changed while the label + numeric value stayed | ⬜ Open |
| TestAC04 | Badge label + icon always render, so the test can't yet show they survive a *real* colour change | DALT-10 | assert the badge colour is remapped while its label + icon stayed | ⬜ Open |
| TestAC08 | Display-only holds trivially while the remap is identity | DALT-7 | control: the displayed swatch did change while the stored value did not | ⬜ Open |
