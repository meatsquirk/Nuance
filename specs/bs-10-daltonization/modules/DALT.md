# Module DALT — daltonization remap engine + display injection

**Status:** In progress — DALT-8 (AC-9) done; capture, readout and palette now all surface a colour swatch through the one shared `ColorChip` chokepoint (new `CaptureCurrentReading`; `PaintRow` masstone swatch), so daltonization reaches every screen — AC-9 un-pended and green, full integration suite 218/0/4. DALT-9..11 (serial behind DALT-3) and CONTROL-2 (other module, AC-10) are startable; DALT-9 is next.
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
| DALT-2 | shell | — | ✅ Done | 9.32M | 23m 50s |
| DALT-3 | behavior | AC-1 | ✅ Done | 8.76M | 29m 28s |
| DALT-4 | behavior | AC-5 | ✅ Done | 7.12M | 25m 17s |
| DALT-5 | behavior | AC-7 | ✅ Done | 5.04M | 24m 20s |
| DALT-6 | behavior | AC-2 | ✅ Done | 7.51M | 25m 22s |
| DALT-7 | behavior | AC-8 | ✅ Done | 9.21M | 21m 10s |
| DALT-8 | behavior | AC-9 | ✅ Done | 19.44M | 31m 48s |
| DALT-9 | behavior | AC-3 | ⬜ Next | | |
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

### Result — DALT-2  <!-- 2026-10-13 -->

- **New `lib/a11y/cvd/daltonize.dart`:** pure `ColorCoordinates daltonize(ColorCoordinates, CvdProfile)` —
  **identity stub** (returns `c`), mirroring `projectDichromat`'s signature (D-2); plus the Color-level bridge
  `Color daltonizeColor(Color, CvdProfile)` (srgb→lab→`daltonize`→srgb, symmetric to `simulateColor`).
- **`DisplaySettings`:** added `bool daltonization` (default false) — into the `const` ctor, `==`, `hashCode`,
  `toString`. **`DisplayController`:** added `setDaltonization(bool)` (change-or-no-op + notify; an independent
  axis — does **not** clear simulation/grayscale, D-5), and threaded `daltonization` through the three existing
  setters so they preserve it.
- **One chokepoint (D-1):** added `displayedSwatchColor(Color, DisplaySettings, CvdProfile)` to
  `color_simulation.dart` — the single display-transform decision: daltonization on → `daltonizeColor`, else →
  `simulateColor`. `ColorChip` now draws the primary swatch through it, reading the stored profile via the new
  `AppScope.maybeOf(context)?.cvdProfile` (deutan fallback for standalone chips; daltonization off there anyway).
  `DisplayReadEndpoint` exposes `daltonization` + `displayedColor(Color, CvdProfile)` (same chokepoint) for the
  acceptance suite. **No second transform path, no second swatch.**
- **Render unchanged (identity):** daltonization defaults off, so `displayedSwatchColor` == `simulateColor` for
  the whole existing suite; with it on, the remap is identity (an sRGB round-trip) — no behaviour yet.
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1237 unit pass** (+17: daltonize 7,
  settings 3, controller 3, color_simulation 3, color_chip 1, read_endpoint 2, AppScope.maybeOf 1) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 7 touched files** · full `integration_test/`
  on booted iPhone 17 (`-d 5AB9D06D…`, under `coord.sh with-lock`) → **197 pass** (unchanged — nothing broke).
  Acceptance: n/a (no bs-10 AC tests until ITEST; defaults keep every other feature's suite green).
- Coverage (touched `lib/`): 100% (7 files). Fix passes: 0/3 (all gates green on first run).
- Tokens/time: 9.32M · 23m 50s active (1 session).
- Closed by: unit + coverage gates green; existing unit + integration suites green; identity render confirmed.

### Checkpoint / Handoff — DALT-2

- **Frozen for DALT-3 / CONTROL-1 / ITEST-1:**
  - `daltonize(ColorCoordinates, CvdProfile)` (`lib/a11y/cvd/daltonize.dart`) — DALT-3 replaces **only this
    body** with the real error-redistribution remap (D-2); callers (`daltonizeColor`, the chokepoint, the
    endpoint) do not change. The identity stub makes AC-2/3/4/8 green at baseline (their controls come later).
  - `DisplaySettings.daltonization` (bool, default false) + `DisplayController.setDaltonization(bool)` — the
    control CONTROL-1's toggle drives.
  - `displayedSwatchColor(Color, DisplaySettings, CvdProfile)` (`color_simulation.dart`) — the **one** render
    chokepoint; `ColorChip` and `DisplayReadEndpoint.displayedColor` both route through it (D-1). DALT-8 (AC-9
    every screen) verifies every surface reaches it.
  - `DisplayReadEndpoint.daltonization` + `displayedColor(Color, CvdProfile)` — the acceptance observation seam.
  - `AppScope.maybeOf(context)` (`lib/app/build_app.dart`) — null-safe deps lookup for standalone surfaces.
- **Verification commands** (Flutter SDK not on default PATH — prepend
  `/Users/matthew.quirk/development/flutter/bin`): `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (host, no sim). Integration on a **booted** sim only (no `-d <udid>`
  ⇒ zero tests, false green): `flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`, run
  under `FNP_COORD_REPO=/Users/matthew.quirk/Nuance ~/.claude/skills/feature-next-phase/scripts/coord.sh
  with-lock bs-10-daltonization <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`.
  macOS has no `timeout`; redirect long sim runs to a file, don't tail.
- **Known gaps:** the remap is identity (DALT-3); no daltonization control/toggle UI yet (CONTROL-1) and no
  no-saved-profile affordance (CONTROL-2, reads `CvdProfileReadEndpoint.hasSavedProfile`, D-4); no bs-10
  harness/`daltonization_test.dart` yet (ITEST-1); AC-6 live recompute (DALT-11) relies on `AppScope` rebuilding
  when the live profile changes (bs-07 `withCvdProfile`) — wired, unverified until DALT-11. Carries the D-8
  sim/dalt gap note only as context — out of bs-10 scope (D-5).

### Result — DALT-3  <!-- 2026-10-13 -->

- **Real remap (keystone).** Replaced `daltonize`'s identity body (`lib/a11y/cvd/daltonize.dart`) with the
  error-redistribution remap (D-2), mirroring the harness's independent `referenceDaltonize`: take the painter's
  **full** dichromat view (`projectDichromat` at severity 1 — taken at full strength so the lost chroma is the
  true confusion error, not a pre-scaled one), compute the a*/b* chroma lost to that collapse, rotate it 90°
  (`(lostA,lostB)→(lostB,−lostA)`) and add it back scaled by `profile.severity`, **preserving lightness**.
  Identity at severity 0; type-specific via the cone the projection drops. Callers unchanged (the `daltonizeColor`
  bridge, the `displayedSwatchColor` chokepoint, the read endpoint) — only this body changed, as DALT-2 froze.
- **Coupling verified exact.** At the AC-1 fixtures (screen sample, severity 0.6) the shipped remap equals
  `referenceDaltonize` to the **8-bit swatch** (summed sRGB Δ = 0.0000 for protan/deutan/tritan) — the shipped
  `projectDichromat` and bs-08's independent `referenceProjectDichromat` agree to the displayed byte, so the
  ratified grading coupling (≈8/channel) holds with margin to spare.
- **AC-1 un-pended** (deleted its row in `integration_test/bs10/pending.dart`); the scaffold guard's `unpended`
  set + length updated (`10 − unpended.length`). `TestAC01_RemapForType` green for all three types.
- **Two frozen-test calibrations, both recorded with reason** (not weakenings):
  1. **`colorNear` tightened 0.094 → 0.05** in `daltonization_harness.dart` — the latitude that helper's own doc
     reserved for behaviour phases ("may tighten it against the shipped render"). The real remap shifts the
     sample ≈0.078 (protan) / 0.106 (deutan) / 0.510 (tritan) summed-sRGB; the scaffold's 0.094 could **not**
     separate the protan remap from the original (0.078 < 0.094), defeating AC-1's "it changed" half. 0.05 sits
     above the measured round-trip rounding (0.0) and below the smallest real remap, so all three register as
     changed while an unremapped swatch still reads as original. Makes the suite **stricter**.
  2. **Identity-shell smoke test updated** (`daltonization_test.dart`, "chokepoint routes … when on"): it
     asserted daltonization-on leaves the swatch at the original (true only for the DALT-2 identity stub, as its
     own comment flagged — "the *real* remap … is DALT-3's pending AC"). Rewritten to assert the swatch is now
     the real remap (`displayColorOf(referenceDaltonize(_, storedProfile))`), not the original and not the
     simulation projection — still proving the daltonization branch wins over an active simulation (D-5).
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1246 unit pass** (daltonize 13: identity@0,
  lightness, visible shift, type-specific, severity-monotonic, distinct-from-projection, grey, clamp>1,
  clamp<0, near-black, bridge shifted/round-trip@0/opaque) · `dart run tool/coverage_gate.dart main` → **100%
  on all 8 touched files**. Acceptance (booted iPhone 17 `5AB9D06D…`, under `coord.sh with-lock`): default
  `daltonization_test.dart` → **+16 / ~9 pending / 0 fail** (AC-1 passes, guards + smoke green); full
  `integration_test/` → **+213 / ~9 / 0** (no regression).
- **Red baseline (`--dart-define=BS10_RUN_PENDING=true`):** +23 / −2 — AC-1 passes, and the keystone already
  satisfies AC-2..AC-8 (they ride the one shared chokepoint); only **AC-9** (capture/palette not yet confirmed
  to reach the chokepoint — Actual `[]`, owned by DALT-8) and **AC-10** (no-profile region still the empty
  placeholder — owned by CONTROL-2) fail, as designed.
- Coverage (touched `lib/`): 100% (8 files, vs `main`). Fix passes: 0/3 (every gate green on the first full run;
  the two calibrations above were made during implementation, before the first acceptance run, not as fixes).
- Tokens/time: 8.76M · 29m 28s active (1 session).
- Closed by: unit + coverage + acceptance (AC-1) + grade gates green; full integration suite green.

### Checkpoint / Handoff — DALT-3

- **Frozen for DALT-4..11 / CONTROL-2:**
  - `daltonize(ColorCoordinates, CvdProfile)` (`lib/a11y/cvd/daltonize.dart`) is the **real** remap now — the
    keystone every other DALT phase asserts against. Its design: full-strength `projectDichromat` → lost a*/b*
    chroma → 90° rotation added back × severity, lightness preserved. DALT-4 (AC-5) does **not** change this
    body — it verifies the chokepoint already drives it from the **stored** type+severity (the run-pending
    baseline shows AC-5 already green), and adds the stronger-severity control.
  - `colorNear(..., {tol = 0.05})` in `daltonization_harness.dart` — the tightened display-colour tolerance all
    bs-10 AC tests use. A later phase may tighten further against the shipped render but should not loosen it.
  - `integration_test/bs10/pending.dart` now holds **9** ACs (AC-1 removed); the scaffold guard's `unpended`
    set is `{'AC-1'}`. Each phase deletes its AC's row and adds it to that set.
- **Verification commands** (Flutter SDK not on default PATH — prepend `/Users/matthew.quirk/development/flutter/bin`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` (host). Acceptance on
  a **booted** sim only (no `-d <udid>` ⇒ zero tests, false green): `flutter test
  integration_test/daltonization_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (run-pending adds
  `--dart-define=BS10_RUN_PENDING=true`), under `FNP_COORD_REPO=/Users/matthew.quirk/Nuance
  ~/.claude/skills/feature-next-phase/scripts/coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`. macOS has **no** `timeout`; the full `integration_test/` run
  exceeds the 120s foreground cap — redirect to a file and run in the background, don't tail.
- **Known gaps:** AC-9 (every-screen reach — capture/palette swatches not yet confirmed through the chokepoint)
  owned by **DALT-8**; AC-10 (no-saved-profile affordance, reads `CvdProfileReadEndpoint.hasSavedProfile`, not
  yet mounted) owned by **CONTROL-2**; AC-6 live recompute (DALT-11) relies on `AppScope` rebuilding on a live
  profile change — wired, unverified until DALT-11. AC-2..AC-8 pass at the keystone but stay **pending** until
  their phases un-pend them and add their controls/augmentations. Carries the D-8 sim/dalt gap as context only
  (out of bs-10 scope, D-5).

### Result — DALT-4  <!-- 2026-10-13 -->

- **Verification phase — no `lib/` body changed (D-3).** DALT-4's AC (AC-5) was already satisfied by DALT-3's
  keystone: the one chokepoint `displayedSwatchColor` is fed the painter's stored profile via
  `AppScope.maybeOf(context)?.cvdProfile` (`lib/widgets/color_chip.dart`) and passes it **whole** to
  `daltonizeColor(original, profile)`, so the remap already uses the stored **type and severity**, never a
  default. DALT-4 confirms this and un-pends AC-5; it touches no product code.
- **AC-5 un-pended** (deleted its row in `integration_test/bs10/pending.dart`; the scaffold guard's `unpended`
  set in `daltonization_test.dart` is now `{'AC-1', 'AC-5'}`, length `10 − 2 = 8`). `TestAC05_UsesStoredProfile`
  (with its stronger-severity control, already written at ITEST-2) runs green in the default suite.
- **Unit tests added** (`test/display/color_simulation_test.dart`, chokepoint group): the chokepoint forwards
  the stored profile **type** (protan ≠ deutan remap; each == `daltonizeColor` for that profile) and the stored
  **severity** (severity 0 → the original; stronger severity remaps **further** from the original than mild — so
  the severity is read and scales the shift, rejecting a hard-coded default). These strengthen the suite at the
  unit grain without touching the chokepoint body.
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1248 unit pass** (+2 vs DALT-3) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 8 touched files**. Acceptance (booted iPhone 17
  `5AB9D06D…`, under `coord.sh with-lock`): default `daltonization_test.dart` → **+17 / ~8 pending / 0 fail**
  (AC-5 now runs green, up from DALT-3's +16/~9); run-pending (`--dart-define=BS10_RUN_PENDING=true`) →
  **+23 / −2** — unchanged from DALT-3's red baseline (only AC-9/DALT-8 and AC-10/CONTROL-2 fail, as designed);
  full `integration_test/` → **+214 / ~8 / 0** (vs DALT-3's +213/~9 — one more pass, one fewer skip, from
  un-pending AC-5; no regression).
- **Grade gate** (fresh independent subagent, re-graded the whole suite against the previous ITEST-3 grid; grid
  rewritten at `behavior-test-completeness-bs-10-daltonization.md`): **6 A / 4 B-pending** — A: AC-1, AC-5, AC-6,
  AC-7, AC-9, AC-10; B-pending: AC-2→DALT-6, AC-3→DALT-9, AC-4→DALT-10, AC-8→DALT-7 (each the planned
  shell-baseline limitation with its open augmentation row). Supporting guards/smoke/harness all A. No row
  downgraded for a rubric reason; stale "all ten pending" framing corrected to the shipped AC-1/AC-5 behaviour.
- Coverage (touched `lib/`): 100% (8 files, vs `main` — unchanged; DALT-4 added no `lib/` line). Fix passes:
  0/3 (every gate green on the first full run).
- Tokens/time: see dashboard cell.
- Closed by: unit + coverage + acceptance (AC-5) + grade gates green; full integration suite green.

### Checkpoint / Handoff — DALT-4

- **Frozen for DALT-5..11 / CONTROL-2:**
  - The chokepoint contract is unchanged from DALT-3: `displayedSwatchColor(original, settings, profile)` →
    `daltonizeColor(original, profile)` when `settings.daltonization`, fed `AppScope.cvdProfile`. AC-5 is now a
    settled fact (stored type + severity drive the remap); later phases rely on it but don't re-assert it.
  - `integration_test/bs10/pending.dart` now holds **8** ACs (AC-1, AC-5 removed); scaffold guard `unpended`
    is `{'AC-1', 'AC-5'}`. Each remaining phase deletes its AC's row and adds it to that set.
  - Unit coverage of the chokepoint's type/severity forwarding lives in `test/display/color_simulation_test.dart`
    (the two new chokepoint tests) — DALT-5 (AC-7) asserts distinctness from the simulation at the same chokepoint.
- **Verification commands:** unchanged from DALT-3 — `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (Flutter at `/Users/matthew.quirk/development/flutter/bin`). Acceptance
  on the **booted** sim only (`-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`; macOS has no `timeout`; the full `integration_test/` run
  exceeds the 120s foreground cap → redirect to a file and background it, don't tail.
- **Known gaps:** unchanged — AC-9 (every-screen reach) owned by **DALT-8**; AC-10 (no-saved-profile affordance,
  reads a not-yet-added `CvdProfileReadEndpoint.hasSavedProfile`, not yet mounted) owned by **CONTROL-2**; AC-6
  live recompute (DALT-11). AC-2/3/4/7/8 pass at the keystone but stay **pending** until their phases un-pend
  them and add controls/augmentations. Carries the D-8 sim/dalt gap as context only (out of bs-10 scope, D-5).

### Result — DALT-5  <!-- 2026-10-13 -->

- **Verification phase — no `lib/` body changed (D-3).** DALT-5's AC (AC-7: the remap is *distinct from the
  simulation projection*) was already satisfied by DALT-3's keystone **by construction**: `daltonize`
  (`lib/a11y/cvd/daltonize.dart`) rotates the a*/b* chroma lost to the full dichromat collapse 90° and adds it
  back (aiding distinction), rather than collapsing it the way `projectDichromat` does (perception). DALT-5
  verifies this at the chokepoint grain and un-pends AC-7; it touches no product code.
- **AC-7 un-pended** (deleted its row in `integration_test/bs10/pending.dart`; the scaffold guard's `unpended`
  set in `daltonization_test.dart` is now `{'AC-1', 'AC-5', 'AC-7'}`, length `10 − 3 = 7`).
  `TestAC07_DistinctFromSimulation` runs green in the default suite.
- **Unit test added** (`test/display/color_simulation_test.dart`, chokepoint group): a **shipped-vs-shipped**
  distinctness check — `displayedSwatchColor(daltonization on)` vs `displayedSwatchColor(simulation on)` /
  `simulateColor` for the same colour + profile — both non-identity, `_channelDistance > 2`. Its oracle is the
  *separate product simulation path*, not the daltonize path, so a refactor routing daltonization through the
  projection fails here. This closes the residual the DALT-4 grid flagged (the pure-function test in
  `daltonize_test.dart` compares shipped `daltonize` to shipped `projectDichromat`; this adds the chokepoint
  grain with no projection-model assumption).
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1249 unit pass** (+1 vs DALT-4) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 8 touched files** (no `lib/` line added). Acceptance
  (booted iPhone 17 `5AB9D06D…`, under `coord.sh with-lock`): default `daltonization_test.dart` →
  **+18 / ~7 pending / 0 fail** (AC-7 now runs green, up from DALT-4's +17/~8); run-pending
  (`--dart-define=BS10_RUN_PENDING=true`) → **+23 / −2** — unchanged red baseline (only AC-9/DALT-8 and
  AC-10/CONTROL-2 fail, as designed); full `integration_test/` → **+215 / ~7 / 0** (vs DALT-4's +214/~8 — one
  more pass, one fewer skip from un-pending AC-7; no regression).
- **Grade gate** (fresh independent subagent, re-graded the whole suite against the DALT-4 grid; grid rewritten
  at `behavior-test-completeness-bs-10-daltonization.md`): **6 A / 4 B-pending** — A: AC-1, AC-5, AC-6, AC-7,
  AC-9, AC-10; B-pending: AC-2→DALT-6, AC-3→DALT-9, AC-4→DALT-10, AC-8→DALT-7. AC-7 moved from
  *pending/red-at-baseline* to *un-pended/delivered*, staying A (band unchanged). Reviewer confirmed both AC-7
  oracles non-circular (acceptance test vs independent `referenceProjectDichromat`; new unit test vs the
  separate product simulation path) and found no grade-affecting weakness. One doc nit recorded, not a test
  defect: the harness header (lines 22–24) says AC-7's contrast "uses the shipped projection directly" —
  accurate for the new unit test, but the acceptance test uses `referenceProjectDichromat`; left for a later
  touch of the harness.
- Coverage (touched `lib/`): 100% (8 files, vs `main` — unchanged; DALT-5 added no `lib/` line). Fix passes:
  0/3 (every gate green on the first full run).
- Tokens/time: see dashboard cell.
- Closed by: unit + coverage + acceptance (AC-7) + grade gates green; full integration suite green.

### Checkpoint / Handoff — DALT-5

- **Frozen for DALT-6..11 / CONTROL-2:**
  - The chokepoint contract is unchanged from DALT-3/DALT-4: `displayedSwatchColor(original, settings, profile)`
    → `daltonizeColor(original, profile)` when `settings.daltonization`, fed `AppScope.cvdProfile`. AC-7
    (distinct from simulation) is now a settled fact; later phases rely on it but don't re-assert it.
  - `integration_test/bs10/pending.dart` now holds **7** ACs (AC-1, AC-5, AC-7 removed); scaffold guard
    `unpended` is `{'AC-1', 'AC-5', 'AC-7'}`. Each remaining phase deletes its AC's row and adds it to that set.
  - DALT-6 (AC-2, off = original) is next and serial behind here (shared `daltonization_test.dart` + the
    chokepoint's off path). **CONTROL-2** (AC-10) stays independently startable (`settings_screen.dart`; key
    gap: `CvdProfileReadEndpoint.hasSavedProfile` still absent and the endpoint not mounted in the main tree).
- **Verification commands:** unchanged from DALT-4 — `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (Flutter at `/Users/matthew.quirk/development/flutter/bin`). Acceptance
  on the **booted** sim only (`-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`; macOS has no `timeout`; the full `integration_test/` run
  exceeds the 120s foreground cap → redirect to a file and background it, don't tail.
- **Known gaps:** unchanged — AC-9 (every-screen reach) owned by **DALT-8**; AC-10 (no-saved-profile affordance)
  owned by **CONTROL-2**; AC-6 live recompute (DALT-11). AC-2/3/4/8 pass at the keystone but stay **pending**
  until their phases un-pend them and add controls/augmentations. Carries the D-8 sim/dalt gap as context only
  (out of bs-10 scope, D-5).

### Result — DALT-6  <!-- 2026-10-13 -->

- **Verification + augmentation phase — no `lib/` body changed.** AC-2's off path was already explicit at the
  chokepoint from DALT-2: `displayedSwatchColor` is `settings.daltonization ? daltonizeColor(original, profile)
  : simulateColor(original, settings)`, so with daltonization off the colour routes to `simulateColor` (the
  stored original when no simulation is set) — colours off are shown with their original values (AC-2). DALT-6
  confirms this, un-pends AC-2 and adds its control; it touches no product code.
- **AC-2 un-pended** (deleted its row in `integration_test/bs10/pending.dart`; the scaffold guard's `unpended`
  set in `daltonization_test.dart` is now `{'AC-1', 'AC-5', 'AC-7', 'AC-2'}`, length `10 − 4 = 6`).
  `TestAC02_OffShowsOriginal` runs green in the default suite.
- **Augmentation closed (TestAC02 → DALT-6).** Replaced the test's LIMITED note with the planned **control**:
  now the real remap ships, turning daltonization ON through the shipped panel toggle (`whenSetDaltonization`)
  moves the swatch away from the original — `h.displayedColor(screenSwatchColor)` is now `colorNear(_remapOf(
  storedProfile))` and **not** `colorNear(screenSwatchColor)`, and `_expectKnownSwatchRemapped` holds. This
  discriminates (against the DALT-2 identity shell the on-control would still show the original and fail),
  proving the "off" assertions above show the *unremapped* original, not merely an identity shell. Strengthens
  AC-2 only (G6). The ITEST *Test augmentations* row is marked ✅ Closed (DALT-6).
- **Unit test added** (`test/display/color_simulation_test.dart`, chokepoint group): "daltonization off → the
  original regardless of the stored profile" — a strong protan@1 profile (which produces a large remap when on)
  still leaves the colour unchanged while off (the off branch never consults the profile), paired with an
  on-control showing that same profile *does* move the colour. Strengthens the existing off/off case (which
  used only a default-severity deutan).
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1250 unit pass** (+1 vs DALT-5) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 8 touched files** (no `lib/` line added). Acceptance
  (booted iPhone 17 `5AB9D06D…`, under `coord.sh with-lock`): default `daltonization_test.dart` →
  **+19 / ~6 pending / 0 fail** (AC-2 now runs green with its control, up from DALT-5's +18/~7); run-pending
  (`--dart-define=BS10_RUN_PENDING=true`) → **+23 / −2** — unchanged red baseline (only AC-9/DALT-8 and
  AC-10/CONTROL-2 fail, as designed); full `integration_test/` → **+216 / ~6 / 0** (vs DALT-5's +215/~7 — one
  more pass, one fewer skip from un-pending AC-2; no regression).
- **Grade gate** (fresh independent subagent, re-graded the whole suite against the DALT-5 grid; grid rewritten
  at `behavior-test-completeness-bs-10-daltonization.md`): **7 A / 3 B-pending** — A: AC-1, AC-2, AC-5, AC-6,
  AC-7, AC-9, AC-10; B-pending: AC-3→DALT-9, AC-4→DALT-10, AC-8→DALT-7. **AC-2 promoted B pending → A** (the
  grader independently verified the on-control discriminates against the identity shell). No row below A for a
  rubric reason; the new DALT-6 chokepoint unit test graded A.
- Coverage (touched `lib/`): 100% (8 files, vs `main` — unchanged; DALT-6 added no `lib/` line). Fix passes:
  0/3 (every gate green on the first full run).
- Tokens/time: see dashboard cell.
- Closed by: unit + coverage + acceptance (AC-2) + grade gates green; full integration suite green.

### Checkpoint / Handoff — DALT-6

- **Frozen for DALT-7..11 / CONTROL-2:**
  - The chokepoint contract is unchanged from DALT-3..5: `displayedSwatchColor(original, settings, profile)` →
    `daltonizeColor(original, profile)` when `settings.daltonization`, else `simulateColor` (the stored original
    with no simulation). AC-2 (off = original) is now a settled fact; later phases rely on it but don't re-assert it.
  - `integration_test/bs10/pending.dart` now holds **6** ACs (AC-1, AC-5, AC-7, AC-2 removed); scaffold guard
    `unpended` is `{'AC-1', 'AC-5', 'AC-7', 'AC-2'}`. Each remaining phase deletes its AC's row and adds it to that set.
  - **DALT-7** (AC-8, stored values unchanged) is next and serial behind here (shared `daltonization_test.dart`
    + the chokepoint's render-only path). Its augmentation (TestAC08 → DALT-7) is still open: assert the
    displayed swatch *did* change while the stored `Sample`/`ColorCoordinates` stayed — now that the real remap
    moves the readout swatch. **CONTROL-2** (AC-10) stays independently startable (`settings_screen.dart`; key
    gap: `CvdProfileReadEndpoint.hasSavedProfile` still absent and the endpoint not mounted in the main tree).
- **Verification commands:** unchanged from DALT-5 — `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (Flutter at `/Users/matthew.quirk/development/flutter/bin`). Acceptance
  on the **booted** sim only (`-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`; macOS has no `timeout`; the full `integration_test/` run
  exceeds the 120s foreground cap → redirect to a file and background it, don't tail. Device lane is contended
  (bs-12 also uses the sim) — the lock serialises.
- **Known gaps:** unchanged — AC-9 (every-screen reach) owned by **DALT-8**; AC-10 (no-saved-profile affordance)
  owned by **CONTROL-2**; AC-6 live recompute (DALT-11). AC-3/4/8 pass at the keystone but stay **pending** until
  their phases un-pend them and add controls/augmentations. Carries the D-8 sim/dalt gap as context only (out of
  bs-10 scope, D-5).

### Result — DALT-7  <!-- 2026-10-14 -->

- **Verification + augmentation phase — no `lib/` body changed.** AC-8 holds structurally: the remap is a pure
  render-time transform. `displayedSwatchColor` (→ `daltonizeColor`) is a pure function of `(original, settings,
  profile)` called only by `ColorChip` (render) and `DisplayReadEndpoint` (the test seam); nothing writes a
  remapped colour back to the stored `Sample`/`ColorCoordinates` or to any store, and the Readout's numeric
  reading is derived from `Sample.coordinates` via `readoutForSpace`, never the remap. DALT-7 confirms this,
  un-pends AC-8 and adds its control; it touches no product code (`git diff --name-only` vs base = four test
  files only).
- **AC-8 un-pended** (deleted its row in `integration_test/bs10/pending.dart`; the scaffold guard's `unpended`
  set in `daltonization_test.dart` is now `{'AC-1', 'AC-5', 'AC-7', 'AC-2', 'AC-8'}`, length `10 − 5 = 5`).
  `TestAC08_StoredValuesUnchanged` runs green in the default suite.
- **Augmentation closed (TestAC08 → DALT-7).** Replaced the test's LIMITED note with the planned **control**:
  the test now captures the Readout's numeric stored-values reading off (new harness getter `storedValuesText`
  over `SpaceSelector.valuesKey`, derived from `Sample.coordinates`), turns daltonization ON through the shipped
  panel toggle and asserts that reading is **unchanged** while on, with the control that the displayed swatch
  *did* move away from the stored original to `_remapOf(storedProfile)` (and no swatch is still the original);
  turning off restores the swatch and the reading still holds. This discriminates against both the no-op/identity
  shell (the swatch would stay the original) and a write-back bug (it would move the derived numeric reading).
  Strengthens AC-8 only (G6). The ITEST *Test augmentations* row is marked ✅ Closed (DALT-7).
- **Harness seam added** (`daltonization_harness.dart`): `String get storedValuesText` reads the Readout's
  `SpaceSelector.valuesKey` Text — a public read of the sample's *stored* colour values as rendered text, the
  observable AC-8's "stored unchanged" Then asserts (ITEST plan's `SampleSource`-read idea realised through the
  on-screen numeric reading). Required `import '…/readout/space_selector.dart'`.
- **Unit test added** (`test/display/color_simulation_test.dart`, chokepoint group): "daltonization on remaps
  only the returned colour; a later off render still yields the original (no write-back, AC-8)" — the on render
  moves the colour (control), a following off render returns the original, and repeating the on render yields the
  same remap (a pure function carrying no state between calls). Pins the no-write-back at the chokepoint grain.
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1251 unit pass** (+1 vs DALT-6) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 8 touched files** (no `lib/` line added). Acceptance
  (booted iPhone 17 `5AB9D06D…`, under `coord.sh with-lock`): default `daltonization_test.dart` →
  **+20 / ~5 pending / 0 fail** (AC-8 now runs green with its control, up from DALT-6's +19/~6); run-pending
  (`--dart-define=BS10_RUN_PENDING=true`) → **+23 / −2** — unchanged red baseline (only AC-9/DALT-8 and
  AC-10/CONTROL-2 fail, as designed; AC-8 now passes un-pended).
- **Grade gate** (fresh independent subagent, re-graded the whole suite against the DALT-6 grid; grid rewritten
  at `behavior-test-completeness-bs-10-daltonization.md`): **8 A / 2 B-pending** — A: AC-1, AC-2, AC-5, AC-6,
  AC-7, AC-8, AC-9, AC-10; B-pending: AC-3→DALT-9, AC-4→DALT-10. **AC-8 promoted B pending → A** (the grader
  independently verified the control discriminates against the no-op/identity shell and the write-back bug, and
  that the numeric reading is independent of the remap). No row below A for a rubric reason; the new DALT-7
  chokepoint unit test graded A.
- Coverage (touched `lib/`): 100% (8 files, vs `main` — unchanged; DALT-7 added no `lib/` line). Fix passes:
  0/3 (every gate green on the first full run).
- Tokens/time: see dashboard cell.
- Closed by: unit + coverage + acceptance (AC-8) + grade gates green.

### Checkpoint / Handoff — DALT-7

- **Frozen for DALT-8..11 / CONTROL-2:**
  - The chokepoint contract is unchanged from DALT-3..6: `displayedSwatchColor(original, settings, profile)` →
    `daltonizeColor(original, profile)` when `settings.daltonization`, else `simulateColor`. AC-8 (display-only,
    stored values unchanged) is now a settled fact; later phases rely on it but don't re-assert it.
  - `integration_test/bs10/pending.dart` now holds **5** ACs (AC-3, AC-4, AC-6, AC-9, AC-10); scaffold guard
    `unpended` is `{'AC-1', 'AC-5', 'AC-7', 'AC-2', 'AC-8'}`. Each remaining phase deletes its AC's row and adds
    it to that set.
  - New reusable seam: `DaltonizationHarness.storedValuesText` (the Readout's numeric space reading) — available
    to any later phase that needs the stored-values observable.
  - **DALT-8** (AC-9, every screen) is next and serial behind here (shared `daltonization_test.dart` + the
    chokepoint). Its test is already **A** and **red at baseline** (the remap must reach capture/readout/palette
    through the one shared chokepoint; `_expectKnownSwatchRemapped` on each). **CONTROL-2** (AC-10) stays
    independently startable (`settings_screen.dart`; key gap: `CvdProfileReadEndpoint.hasSavedProfile` still
    absent and the endpoint not mounted in the main tree).
- **Verification commands:** unchanged from DALT-6 — `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (Flutter at `/Users/matthew.quirk/development/flutter/bin`). Acceptance
  on the **booted** sim only (`-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`; macOS has no `timeout`; the full `integration_test/` run
  exceeds the 120s foreground cap → redirect to a file and background it, don't tail. Device lane is contended
  (bs-12 also uses the sim) — the lock serialises.
- **Known gaps:** unchanged — AC-9 (every-screen reach) owned by **DALT-8**; AC-10 (no-saved-profile affordance)
  owned by **CONTROL-2**; AC-6 live recompute (DALT-11); AC-3/AC-4 pass at the keystone but stay **pending**
  until DALT-9/DALT-10 un-pend them and add their controls. Carries the D-8 sim/dalt gap as context only (out of
  bs-10 scope, D-5).

### Result — DALT-8  <!-- 2026-10-14 -->

- **Surfaced the known swatch on every screen through the one chokepoint (AC-9).** The remap was already injected
  at the single `ColorChip`/`DisplayScope` chokepoint (DALT-2/3); DALT-8 made capture and palette actually
  *render a colour swatch* there so daltonization reaches them (the Readout already did). First behaviour phase
  since DALT-3 to change `lib/` bodies.
  - **Capture:** new `lib/capture/capture_current_reading.dart` — `CaptureCurrentReading` renders
    `CaptureState.currentSample`'s colour through `ColorChip` (sRGB via `AppScope.colorScience`), labelled with
    the CIELAB reading so the swatch never stands alone (SI §5.1); renders nothing before a sample exists or with
    no scope. Wired into `capture_screen.dart`'s readings column.
  - **Palette:** `PaintRow` gained optional `swatchColor` — when supplied it routes the paint name through a
    `ColorChip` masstone swatch; `PaintListRegion` computes it from `AppScope.maybeOf(context)?.colorScience`
    per paint. Null (no scope) keeps the pre-bs-10 plain-name row, so standalone `PaintRow` tests are unchanged.
- **AC-9 un-pended** (deleted its row in `integration_test/bs10/pending.dart`; scaffold guard's `unpended` set in
  `daltonization_test.dart` is now `{'AC-1','AC-5','AC-7','AC-2','AC-8','AC-9'}`, length `10 − 6 = 4`).
  `TestAC09_EveryScreen` runs green in the default suite (readout + capture + palette).
- **Harness fixture fix (recorded).** `daltonization_harness.dart`'s `screenPalette` renamed `'Screen palette'`
  → `PaletteController.myPaintsName` ("My paints"). Reason: `PaletteController.myPaints` (what `PaintListRegion`
  renders) filters for the palette named "My paints"; under any other name the paint never reaches the list, so
  the AC-9 palette Given would not hold. The Then (`_expectKnownSwatchRemapped` on each screen) is **unchanged** —
  not a weakening. Added `import '…/palette/palette_controller.dart'`.
- **Unit tests added:** `test/capture/capture_current_reading_test.dart` (null → shrink; no-scope → shrink;
  under scope → labelled swatch at the reading's sRGB) and `test/palette/paint_list_region_test.dart` (empty
  placeholder; no-scope row has no swatch; under-scope row renders the masstone swatch through `ColorChip`); a
  `swatchColor` case added to `test/widgets/paint_row_test.dart`.
- **Gates:** `flutter analyze` clean · `flutter test --coverage` **1258 unit pass** (+7 vs DALT-7) ·
  `dart run tool/coverage_gate.dart main` → **100% on all 12 touched files**. Acceptance (booted iPhone 17
  `5AB9D06D…`, under `coord.sh with-lock`): default `daltonization_test.dart` → **+21 / ~4 pending / 0 fail**
  (AC-9 now green, up from DALT-7's +20/~5); **full `integration_test/` regression → 218 pass / 4 skip / 0 fail**
  (the 4 skips are the still-pending AC-3/AC-4/AC-6/AC-10) — no regression on the capture/palette/display screens
  the swatches were added to.
- **Grade gate** (fresh independent subagent, re-graded the whole suite against the DALT-7 grid; grid rewritten
  at `behavior-test-completeness-bs-10-daltonization.md`): **8 A / 2 B-pending** — A: AC-1, AC-2, AC-5, AC-6,
  AC-7, AC-8, AC-9, AC-10; B-pending: AC-3→DALT-9, AC-4→DALT-10. **No band change** — AC-9 was already A while
  pending and stays A on shipped behaviour; the grader independently judged the fixture rename a legitimate Given
  fix and confirmed AC-9 rejects a one-screen-only remap (G5). The three new DALT-8 unit tests graded A.
- Fix passes: 0/3 (every gate green on the first full run).
- Tokens/time: see dashboard cell.
- Closed by: unit + coverage + acceptance (AC-9) + grade gates green; full integration suite green.

### Checkpoint / Handoff — DALT-8

- **Frozen for DALT-9..11 / CONTROL-2:**
  - The chokepoint contract is unchanged. Every screen now surfaces its colour through `ColorChip`: Readout
    (`ValueRegion`), Capture (`CaptureCurrentReading`), Palette (`PaintRow` masstone). `displaySwatches(tester)`
    reads a rendered swatch on each of the three screens. AC-9 (every-screen reach) is now a settled fact.
  - `integration_test/bs10/pending.dart` now holds **4** ACs (AC-3, AC-4, AC-6, AC-10); scaffold guard `unpended`
    is `{'AC-1','AC-5','AC-7','AC-2','AC-8','AC-9'}`. Each remaining phase deletes its AC's row and adds it.
  - `PaintRow.swatchColor` + `PaintRow.swatchKeyFor(id)` and `CaptureCurrentReading.readingKey` are the new
    render seams. **DALT-9 (AC-3)** should assert, now that the real remap renders on the palette/capture swatch,
    that a colour-coded element keeps its label + numeric value while the swatch colour changes; **DALT-10 (AC-4)**
    that the provenance badge stays readable from label + icon under the remap. Both share the chokepoint and
    `daltonization_test.dart`, so they are serial behind here.
  - **CONTROL-2** (AC-10) stays independently startable (`settings_screen.dart`; key gap unchanged:
    `CvdProfileReadEndpoint.hasSavedProfile` still absent and the endpoint not mounted in the main tree).
- **Verification commands:** unchanged — `flutter analyze` · `flutter test --coverage` ·
  `dart run tool/coverage_gate.dart main` (Flutter at `/Users/matthew.quirk/development/flutter/bin`). Acceptance
  on the **booted** sim only (`-d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), under
  `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-10-daltonization <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs10 && …'`; macOS has no `timeout`; the full `integration_test/` run
  exceeds the 120s foreground cap → redirect to a file and background it, don't tail. Device lane is contended
  (bs-12 also uses the sim) — the lock serialises.
- **Known gaps:** AC-3/AC-4 pass at the keystone but stay **pending** until DALT-9/DALT-10 un-pend them and add
  their controls; AC-6 live recompute (DALT-11); AC-10 no-saved-profile affordance (CONTROL-2). Carries the D-8
  sim/dalt gap as context only (out of bs-10 scope, D-5).
