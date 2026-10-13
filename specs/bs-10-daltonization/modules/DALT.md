# Module DALT — daltonization remap engine + display injection

**Status:** In progress — DALT-1 (scaffold) done; next DALT-2 (shell)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/a11y/cvd/daltonize.dart` (+ `test/a11y/cvd/daltonize_test.dart`); the daltonization
additions to bs-08's display pipeline (`lib/display/display_settings.dart`, `display_controller.dart`,
`display_scope.dart`, `display_read_endpoint.dart` — exact paths confirmed in DALT-1 against merged bs-08) and
the daltonization branch of the shared `lib/widgets/color_chip.dart` display-transform.
**Depends on:** bs-07 (stored profile), bs-08 (display pipeline) — both via G-3/G-4 · **Blocks:** CONTROL (shell method), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| DALT-1 | scaffold | — | ✅ Done | 4.07M | 21m 20s |
| DALT-2 | shell | — | ⬜ Next | | |
| DALT-3 | behavior | AC-1 | ⬜ Todo | | |
| DALT-4 | behavior | AC-5 | ⬜ Todo | | |
| DALT-5 | behavior | AC-7 | ⬜ Todo | | |
| DALT-6 | behavior | AC-2 | ⬜ Todo | | |
| DALT-7 | behavior | AC-8 | ⬜ Todo | | |
| DALT-8 | behavior | AC-9 | ⬜ Todo | | |
| DALT-9 | behavior | AC-3 | ⬜ Todo | | |
| DALT-10 | behavior | AC-4 | ⬜ Todo | | |
| DALT-11 | behavior | AC-6 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `ColorCoordinates daltonize(ColorCoordinates c, CvdProfile profile)` (pure, `lib/a11y/cvd/daltonize.dart`),
  mirroring `projectDichromat`'s signature; `DisplaySettings.daltonization` (bool, default false) +
  `DisplayController.setDaltonization(bool)`; `DisplayReadEndpoint.daltonization` + the effective displayed colour.
- **Consumes:** bs-08 `DisplayController`/`DisplaySettings`/`DisplayScope`/`ColorChip` display-transform/
  `DisplayReadEndpoint`; bs-07 `AppDependencies.cvdProfile` (live) + `CvdProfileStore` (for the AC-6 recompute
  listener); `projectDichromat` + `CvdProfile` (bs-03).
- **Reconciliation:** bs-08/bs-07 are now merged to `main` (@ `ecd3a9e`). DALT-1 confirmed the real surface
  against merged `main` — the names hold, with these **path drifts** to use when DALT-2 edits them:
  - `DisplaySettings` → `lib/display/display_settings.dart` (fields today: `CvdType? simulationType`,
    `double simulationSeverity`, `bool grayscale`; `const` ctor + `==`/`hashCode`/`toString` — DALT-2 adds
    `bool daltonization` default false to all four).
  - `DisplayController extends ChangeNotifier` → `lib/display/display_controller.dart` (has
    `setSimulationType` / `setSimulationSeverity` / `setGrayscale` — DALT-2 adds `setDaltonization(bool)`).
  - `DisplayReadEndpoint extends InheritedWidget` → `lib/display/display_read_endpoint.dart` (exposes
    `DisplaySettings get settings => controller.settings`; DALT-2 surfaces `daltonization` + the effective
    displayed colour here).
  - `ColorChip` → `lib/widgets/color_chip.dart` — the chokepoint reads `DisplayScope.maybeOf(context)?.settings`
    and maps `color` through **`simulateColor`** (from `lib/display/color_simulation.dart`), drawing the
    original alongside when simulation is on. DALT-2 adds the `daltonization` branch here (the one transform
    path, D-1), not a second chip.
  - `projectDichromat(ColorCoordinates c, CvdProfile profile)` lives in **`lib/a11y/cvd/confusion_check.dart`**
    (not a standalone file); `CvdProfile {CvdType type; double severity}` + `enum CvdType` in
    `lib/a11y/cvd/cvd_profile.dart`. `daltonize.dart` is net-new alongside them.
  - `AppDependencies.cvdProfile` (+ `withCvdProfile`) is in **`lib/app/build_app.dart`** (field at ~l216); the
    live profile is seeded there and reconfigured at the app root (bs-07). `CvdProfileStore` →
    **`lib/store/cvd_profile_store.dart`**; `CvdProfileReadEndpoint` → **`lib/onboarding/cvd_profile_read_endpoint.dart`**
    (DALT-4/AC-10 read `hasSavedProfile` from it, D-4).
  The remap extends the **one** chokepoint bs-08 built (D-1) — it does not add a second transform path.
  Daltonization reads the **stored** profile (D-3), unlike simulation which carries its own painter-chosen
  `simulationType`.

## Open gates

- DALT-1: **G-1** (spec approval) ✅ Resolved 2026-10-13 — approved by Matt Quirk; **G-3** (bs-08 merged) ✅
  Resolved 2026-10-13 — merge `0900d44` is an ancestor of `main`; **G-4** (bs-07 merged) ✅ Resolved
  2026-10-13 — merge `ecd3a9e` is an ancestor of `main` (verified from git in DALT-1). DALT-1 is unblocked
  and done. All behavior phases are additionally blocked by **G-2** (acceptance tests approved, at ITEST-3).

## Phase DALT-1 — scaffold

- **Kind:** scaffold
- **Target AC:** — · **Depends on:** G-1, G-3, G-4 · **Blocks:** DALT-2
- **Files:** `integration_test/bs10/pending.dart`; no product code
- **Tasks:**
  1. Branch `feat/bs-10` off the updated `main` (bs-07 + bs-08 merged); record `BASE`.
  2. Re-confirm the merged bs-08 display-pipeline surface + bs-07 profile-store surface against `main`; note
     any drift from this plan's names in *Interface reconciliation*.
  3. Prove the existing coverage gate (passes on a clean tree, fails on a planted gap) and the integration
     runner still work; record the baseline test counts.
  4. Seed `integration_test/bs10/pending.dart` exposing `acTestWidgets`, `pendingACs` (all 10 ACs → owning
     phase) and `pendingSkipReason`, gated by `--dart-define=BS10_RUN_PENDING=true`.
- **Exit criteria:** `feat/bs-10` builds; the gate proof passes; baseline recorded; no product code changed.

### Result — DALT-1  <!-- 2026-10-13 -->

- Branched `feat/bs-10` off `main` @ `ecd3a9e` (bs-07 merge `ecd3a9e` + bs-08 merge `0900d44` both confirmed
  ancestors of `main`; `main` in sync with origin) in worktree `/Users/matthew.quirk/Nuance-bs10`. `BASE = ecd3a9e`.
- **G-4 resolved** (dependency): bs-07 signed off + merged to `main` @ `ecd3a9e` — verified from git, not a
  human decision. G-1 ✅ + G-3 ✅ already held, so DALT-1 was fully unblocked.
- **Surface re-confirmed against merged `main`** — all bs-07/bs-08 names hold; path drifts recorded in
  *Interface reconciliation* (chief: `projectDichromat` lives in `confusion_check.dart`; the `ColorChip`
  chokepoint maps through `simulateColor`; `CvdProfileStore`→`lib/store/`, `CvdProfileReadEndpoint`→
  `lib/onboarding/`; `AppDependencies.cvdProfile` in `lib/app/build_app.dart`).
- **Baseline (green):** `flutter test --coverage` → **1220 unit passed**, `coverage/lcov.info` produced.
  `flutter test integration_test/ -d <iPhone 17 5AB9D06D…>` (default, pending skipped) → **197 passed**,
  exit 0, run under the verify lock (`coord.sh with-lock bs-10-daltonization DALT-1`). `flutter analyze` →
  no issues.
- **Coverage gate proven both ways:** clean tree (no touched `lib/`) → `nothing to gate. PASS` (exit 0);
  planted `lib/_gate_probe.dart` + under-covering test → `FAIL … 2/3 lines covered — uncovered lines: 6`
  (exit 1); probe files removed → no product code remains.
- **Pending gate added:** `integration_test/bs10/pending.dart` (modelled on `bs09/pending.dart`) — all 10 ACs
  seeded pending → owning phases (AC-1→DALT-3, AC-2→DALT-6, AC-3→DALT-9, AC-4→DALT-10, AC-5→DALT-4,
  AC-6→DALT-11, AC-7→DALT-5, AC-8→DALT-7, AC-9→DALT-8, AC-10→CONTROL-2); `behaviorPhases`, `acTestWidgets`,
  `pendingSkipReason`, `runPending` via `BS10_RUN_PENDING`. Analyzes clean.
- Coverage (touched `lib/`): none — scaffold owns no product code → gate PASS. Acceptance: n/a (no AC tests
  yet; ITEST-1 builds the harness, ITEST-2/3 register per-AC tests).
- Fix passes: 0/3 (all gates green on first run).
- Closed by: gate proven both ways; baseline recorded green; no product code.

### Checkpoint / Handoff — DALT-1

- **Frozen for DALT-2:** `integration_test/bs10/pending.dart` is the un-pend registry — a behaviour phase
  un-pends its AC by deleting that AC's row. DALT-2 is the first shell (identity `daltonize` stub +
  `DisplaySettings.daltonization` + chokepoint branch + `DisplayReadEndpoint.daltonization`); render must stay
  unchanged (identity remap), suite green.
- **Verification commands** (Flutter SDK `/Users/matthew.quirk/development/flutter/bin`, not on default PATH —
  prepend it): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`
  (host, no sim). Acceptance (needs a booted sim, always pass `-d <udid>` — no device ⇒ zero tests, false
  green): `flutter test integration_test/daltonization_test.dart -d <udid>` once ITEST-1 creates it;
  run-pending adds `--dart-define=BS10_RUN_PENDING=true`. Run sim commands under
  `coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`
  (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`; `with-lock` runs from the coord repo). macOS has **no**
  `timeout`; redirect long sim runs to a file, don't tail a foreground run.
- **Known gaps:** no product code, no `daltonize`/`DisplaySettings.daltonization`/read-endpoint field yet
  (DALT-2), no bs-10 harness or `daltonization_test.dart` yet (ITEST-1), no toggle/no-profile control yet
  (CONTROL-1/CONTROL-2). Carries the D-8 sim/dalt gap note only as context — out of bs-10 scope (D-5).

## Phase DALT-2 — shell: remap stub + pipeline wiring

- **Kind:** shell
- **Target AC:** — · **Depends on:** DALT-1 · **Blocks:** CONTROL-1, ITEST-1
- **Files:** `lib/a11y/cvd/daltonize.dart`, the bs-08 display-pipeline files, `lib/widgets/color_chip.dart`
- **Tasks:**
  1. `ColorCoordinates daltonize(ColorCoordinates c, CvdProfile profile)` returning `c` unchanged (identity stub).
  2. Add `bool daltonization` (default false) to `DisplaySettings` + `DisplayController.setDaltonization(bool)`.
  3. Extend the shared `ColorChip`/`DisplayScope` display-transform: when `daltonization` is on, route the
     swatch colour through `daltonize(c, AppDependencies.cvdProfile)` (identity for now); when off, leave it.
  4. Expose `daltonization` and the effective displayed colour on `DisplayReadEndpoint` (the read endpoint the
     acceptance tests observe).
- **Exit criteria:** unit gate passes; the existing suite stays green; render unchanged (identity remap); the
  flag + read endpoint observable. **No behaviour yet** (remap is identity).

## Phase DALT-3 — AC-1: remap for the painter's type (keystone)

- **Kind:** behavior
- **Target AC:** AC-1 (full; Scenario Outline over protan/deutan/tritan) · **Depends on:** DALT-2, ITEST-3 (G-2) · **Blocks:** DALT-4
- **Files:** `lib/a11y/cvd/daltonize.dart` (+ unit test)
- **Tasks:** implement the real error-redistribution remap (D-2) over `projectDichromat`, scaled by severity,
  producing a type-specific distinguishing remap; the chokepoint (from DALT-2) now renders remapped colours
  when daltonization is on, per the painter's stored type.
- **Exit criteria:** unit gate; chokepoint shows a non-identity, type-specific remap.
- **Acceptance gate:** un-pend AC-1; `daltonization_test.dart` green with `TestAC01_RemapForType` passing for
  each of protan/deutan/tritan (remapped != original, == `referenceDaltonize`), all other ACs still pending.

## Phase DALT-4 — AC-5: remap uses the stored type + severity

- **Kind:** behavior
- **Target AC:** AC-5 · **Depends on:** DALT-3 · **Blocks:** DALT-5
- **Files:** display chokepoint (profile read) (+ unit test)
- **Tasks:** the chokepoint drives the remap from the **stored** profile's type **and** severity
  (`AppDependencies.cvdProfile`), not a default; verify severity scales the remap.
- **Acceptance gate:** un-pend AC-5; `TestAC05_UsesStoredProfile` green (== `referenceDaltonize` at the stored
  type+severity; control: a stronger stored severity → a stronger remap).

## Phase DALT-5 — AC-7: distinct from simulation

- **Kind:** behavior
- **Target AC:** AC-7 · **Depends on:** DALT-3 · **Blocks:** DALT-6
- **Files:** `daltonize.dart` / chokepoint (+ unit test)
- **Tasks:** establish and assert that the remap is distinct from the simulation projection — the remapped
  swatch aids distinction, it is not `projectDichromat(c, profile)` (how the painter sees).
- **Acceptance gate:** un-pend AC-7; `TestAC07_DistinctFromSimulation` green (remapped != `projectDichromat`
  for the same colour + profile).

## Phase DALT-6 — AC-2: off shows the original

- **Kind:** behavior
- **Target AC:** AC-2 · **Depends on:** DALT-3 · **Blocks:** DALT-7
- **Files:** chokepoint (+ unit test)
- **Tasks:** make the off path explicit (no remap when `daltonization` false → the stored original is shown).
- **Acceptance gate:** un-pend AC-2; `TestAC02_OffShowsOriginal` green.
- **Augments:** `TestAC02`: add the control (turning daltonization on remaps the swatch) now that the real
  remap exists — closes its green-at-baseline limit.

## Phase DALT-7 — AC-8: stored values unchanged

- **Kind:** behavior
- **Target AC:** AC-8 · **Depends on:** DALT-3 · **Blocks:** DALT-8
- **Files:** chokepoint / `SampleSource` read path (+ unit test)
- **Tasks:** ensure the remap is applied only at render and never written back; assert the stored
  `Sample`/`ColorCoordinates` are unchanged after a remapped render.
- **Acceptance gate:** un-pend AC-8; `TestAC08_StoredValuesUnchanged` green.
- **Augments:** `TestAC08`: add the control (the displayed swatch *did* change while the stored value did not)
  now that the real remap exists.

## Phase DALT-8 — AC-9: every screen

- **Kind:** behavior
- **Target AC:** AC-9 · **Depends on:** DALT-3 · **Blocks:** DALT-9
- **Files:** verify the shared chokepoint reaches capture/readout/palette (+ unit test if a screen bypasses it)
- **Tasks:** confirm the remap is injected at the one shared `ColorChip`/`DisplayScope` chokepoint so every
  screen gets it; fix any screen that renders a swatch outside the chokepoint.
- **Acceptance gate:** un-pend AC-9; `TestAC09_EveryScreen` green (the known swatch remapped on capture,
  readout and palette).

## Phase DALT-9 — AC-3: label + value kept

- **Kind:** behavior
- **Target AC:** AC-3 · **Depends on:** DALT-3 · **Blocks:** DALT-10
- **Files:** chokepoint / label-contract widgets (+ unit test)
- **Tasks:** ensure a remapped colour-coded element still renders its label text + numeric value (only the
  swatch colour changes).
- **Acceptance gate:** un-pend AC-3; `TestAC03_LabelAndValueKept` green.
- **Augments:** `TestAC03`: assert the swatch colour changed *while* the label + value stayed, now that the
  real remap exists.

## Phase DALT-10 — AC-4: provenance badge readable

- **Kind:** behavior
- **Target AC:** AC-4 · **Depends on:** DALT-3 · **Blocks:** DALT-11
- **Files:** chokepoint / `provenance_badge.dart` rendering (+ unit test)
- **Tasks:** ensure a provenance badge stays readable from its label + icon (not colour) under the remap.
- **Acceptance gate:** un-pend AC-4; `TestAC04_ProvenanceBadgeReadable` green.
- **Augments:** `TestAC04`: assert the badge colour is remapped *while* its label + icon stay, now that the
  real remap exists.

## Phase DALT-11 — AC-6: profile change recomputes the remap

- **Kind:** behavior
- **Target AC:** AC-6 · **Depends on:** DALT-3, bs-07 `CvdProfileStore` · **Blocks:** SIGNOFF-1
- **Files:** display pipeline (listen to the profile store) (+ unit test)
- **Tasks:** make the daltonization render read the **live** profile — listen to `CvdProfileStore` so a saved
  profile change (e.g. deutan → protan) re-renders with the recomputed remap.
- **Acceptance gate:** un-pend AC-6; `TestAC06_ProfileChangeRecomputes` green (after a save settles, the remap
  recomputes to the new type; control: it was the old type's remap before the save).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
