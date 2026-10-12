# Module DISPLAY — cross-cutting display pipeline (simulation + grayscale)

**Status:** In progress — DISPLAY-8 done (AC-7 un-pended + green; test-only augmentation — the simulated swatch coexists with the reading's value + label, "not colour alone", D-7; AC-7 re-graded B-pending-DISPLAY-8 → A, no `lib/` change); DISPLAY-7 (AC-6 root grayscale) still startable
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/display_settings.dart`, `lib/display/display_controller.dart`, `lib/display/display_scope.dart`, `lib/display/display_read_endpoint.dart`, `lib/display/color_simulation.dart` (thin reuse of `projectDichromat`), `lib/display/grayscale_filter.dart`; integration points in `lib/widgets/color_chip.dart` and `lib/app/build_app.dart` (root grayscale wrapper + `DisplayScope` wiring). Unit tests under `test/display/`.
**Depends on:** — · **Blocks:** SETTINGS (needs `DisplayController`), ITEST (needs the read endpoint + rendering), SPEECH (scaffold only)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| DISPLAY-1 | scaffold | — | ✅ Done | 4,979,118 | 14m 13s (15m 17s) |
| DISPLAY-2 | shell | — | ✅ Done | 8,485,201 | 15m 04s (15m 04s) |
| DISPLAY-3 | behavior | AC-2 | ✅ Done | 10,542,090 | 20m 03s (20m 03s) |
| DISPLAY-4 | behavior | AC-3 | ✅ Done | 12,709,944 | 23m 20s (23m 20s) |
| DISPLAY-5 | behavior | AC-4 | ✅ Done | 5,665,722 | 11m 49s (11m 49s) |
| DISPLAY-6 | behavior | AC-5 | ✅ Done | 4,583,088 | 13m 00s (13m 00s) |
| DISPLAY-7 | behavior | AC-6 | ⬜ Todo | | |
| DISPLAY-8 | behavior | AC-7 | ✅ Done | 7,504,305 | 0m 00s |

## Interface reconciliation

- **Exposes:** `DisplaySettings` (value type: `CvdType? simulationType`, `double simulationSeverity` 0..1, `bool grayscale`; `simulationType == null` ⇔ simulation off); `DisplayController extends ChangeNotifier` with `setSimulationType(CvdType?)`, `setSimulationSeverity(double)`, `setGrayscale(bool)`; `DisplayScope` (`InheritedNotifier<DisplayController>`) with `DisplayScope.of(context)`; `DisplayReadEndpoint` (keyed, exposes the live `DisplaySettings`).
- **Consumes:** `projectDichromat(ColorCoordinates, CvdProfile)` and `CvdProfile`/`CvdType` from `lib/a11y/cvd/` (frozen; reused, never re-derived — D-1); `AppDependencies.cvdProfile` for the settings default (D-2); the shared `ColorChip` as the colour-render chokepoint (D-4).
- **Rendering split (D-4/D-5):** simulation is a **per-swatch** transform (original + simulated side by side, through `ColorChip` reading `DisplayScope`); value-only grayscale is a **single root** `ColorFiltered` in `buildApp` (greys everything, incl. the live camera). The two are mutually exclusive (D-3): `setGrayscale(true)` nulls `simulationType`.
- **Conflict (spec vs architecture):** the spec's Rule names "simulate the painter's CVD type" but its scenario lets the painter *choose* a type; resolved by D-2 — the setting carries its own `simulationType`, defaulting from `AppDependencies.cvdProfile`.

## Open gates

- **G-1** (spec approval) — ✅ Resolved 2026-10-11: spec approved; Draft banner replaced with approval line — Matt Quirk. Unblocked DISPLAY-1.
- **G-2** (acceptance tests approved) — ✅ Resolved 2026-10-12: acceptance tests approved (ITEST-4 test review) — Matt Quirk. Unblocked DISPLAY-3..8 (all behavior).

## Phase DISPLAY-1 — scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — · **Blocks:** DISPLAY-2
- **Files:** branch only; `integration_test/bs08/pending.dart` (seed), ledger/plan files
- **Tasks:**
  1. Branch `feat/bs-08-display-simulation-and-spoken-output` from `main` @ `4d4aedd`.
  2. Record the baseline (unit suite + coverage) on a clean tree; confirm the coverage gate passes clean and fails on a planted uncovered line (`tool/coverage_gate.dart`).
  3. Confirm the integration runner over an empty bs08 suite (a smoke run with `-d <udid>`).
  4. Seed `integration_test/bs08/pending.dart` with the 10 ACs → owning phases and the `BS08_RUN_PENDING` flag mechanics (mirroring `bs02/pending.dart`).
- **Exit criteria:** gate passes on clean tree + fails on planted gap; baseline recorded; pending gate lists all 10 ACs; no product code.

### Result — DISPLAY-1 (2026-10-11)

- **Branch:** `feat/bs-08-display-simulation-and-spoken-output` from `main` @ `a695e4c` (current HEAD; code tree identical to the planned `4d4aedd` base — the two commits between are plan-only, `git diff 4d4aedd a695e4c -- . ':(exclude)specs/'` empty — but `a695e4c` is where the bs-08 plan + spec landed, so the branch must start here to carry them). Worktree `/Users/matthew.quirk/Nuance-bs08`.
- **Gate decision G-1 (folded into this session):** spec approved — `specs/bs-08-…feature` line 1 Draft banner → `# Approved 2026-10-11 by Matt Quirk (G-1) …`.
- **Baseline:** `flutter analyze` clean (No issues found); `flutter test --coverage` = **849 unit tests pass**; `coverage/lcov.info` produced.
- **Coverage gate confirmed both ways:** clean tree → `no touched lib/**.dart files vs "main" — nothing to gate. PASS` (exit 0); planted gap (a never-called `lib/_gate_probe.dart` function with a test covering only one function) → `FAIL — … uncovered lines: 5, 7, 8` (exit 1). Probe removed; tree clean.
- **Integration runner smoke:** `flutter test integration_test/display_test.dart -d 5AB9D06D-…` (iPhone 17 sim) → Xcode build + **3 scaffold-guard tests pass** (pending map covers exactly AC-1..AC-10; every owner a real behaviour phase; skip/force semantics).
- **Seeded:** `integration_test/bs08/pending.dart` with all **10 ACs** → owners (AC-1 SETTINGS-2, AC-2..7 DISPLAY-3..8, AC-8 SPEECH-2, AC-9 SPEECH-3, AC-10 SPEECH-4) + `BS08_RUN_PENDING` flag mechanics (mirrors `bs06/pending.dart`); `integration_test/display_test.dart` smoke runner + scaffold guard.
- **No product code** (only `integration_test/` + plan/spec edits). Fix passes: 0/3 (coverage-gate planted-gap probe needed a second form — a simple folded `if/return` records no 0-hit line; a never-called function does — not a gate failure).
- **Drift noted & corrected:** master plan ITEST prose said the pending gate is "seeded in ITEST-1"; the module plan + session log put it in DISPLAY-1 (where it was in fact seeded). Trusted the module plan; corrected the master prose.

### Checkpoint / Handoff — DISPLAY-1

- **Frozen for DISPLAY-2:** the pending gate API in `integration_test/bs08/pending.dart` — `pendingACs` (10 ACs), `behaviorPhases`, `pendingSkipReason(acId, {forceRunPending})`, `acTestWidgets(acId, description, body)`, `BS08_RUN_PENDING`. The runner `integration_test/display_test.dart` holds only the scaffold guard group; ITEST-1 adds the harness + a never-pending smoke test; ITEST-2/3 register the per-AC `acTestWidgets`.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d <booted-udid>` (default, pending skipped) / add `--dart-define=BS08_RUN_PENDING=true` (run-pending / red baseline). Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH; booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Next (DISPLAY-2):** the shell — `DisplaySettings` / `DisplayController` / `DisplayScope` / `DisplayReadEndpoint` + `buildApp` wiring + inert `color_simulation`/`grayscale_filter` seams + `ColorChip` reading `DisplayScope` (identity). Touches `lib/app/build_app.dart` → merge-risky with SETTINGS-1/SPEECH-1 (run shells in order).
- **Known gap:** none beyond the standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase DISPLAY-2 — shell: display settings state + controller + scope + endpoint

- **Kind:** shell
- **Target AC:** —
- **Depends on:** DISPLAY-1 · **Blocks:** SETTINGS-1, SPEECH-1, ITEST-1, DISPLAY-3
- **Files:** `lib/display/display_settings.dart`, `display_controller.dart`, `display_scope.dart`, `display_read_endpoint.dart`, `color_simulation.dart` (inert), `grayscale_filter.dart` (inert), `lib/app/build_app.dart` (wrap the tree in `DisplayScope` + the root grayscale wrapper, both inert), `lib/widgets/color_chip.dart` (read `DisplayScope` but apply no transform yet). Tests under `test/display/`.
- **Tasks:**
  1. Define `DisplaySettings` + `DisplayController` (setters present; they update state + notify, but no rendering consumes them yet) + `DisplayScope` + `DisplayReadEndpoint`.
  2. Wire `DisplayController` into `AppDependencies`/`buildApp` (new optional dep, defaulting to a fresh controller) and wrap the app in `DisplayScope` and an inert root grayscale wrapper.
  3. `ColorChip` reads `DisplayScope.of(context)` but the transform is identity (behaviour unchanged).
- **Exit criteria:** unit gate passes (100% on the new files); the existing unit + integration suites stay green; no visible behaviour change (sim/grayscale still no-ops). Read endpoint reports the default settings.

### Result — DISPLAY-2 (2026-10-12)

- **Landed (all inert / behaviour unchanged):** `lib/display/display_settings.dart` (`DisplaySettings` value type — `CvdType? simulationType`, `double simulationSeverity` 0..1, `bool grayscale`, `simulationOn` getter, value equality); `display_controller.dart` (`DisplayController extends ChangeNotifier` with `setSimulationType/Severity/Grayscale` — pure setters, no-op guards, notify; `defaultSimulationType` seeded from the profile per D-2; **no** cross-field rules yet — DISPLAY-6 adds the D-3 clear-on-grayscale); `display_scope.dart` (`DisplayScope extends InheritedNotifier<DisplayController>` with `of`/`maybeOf`); `display_read_endpoint.dart` (keyed `DisplayReadEndpoint`, `of`, `settings` convenience); `color_simulation.dart` (`simulateColor(Color, DisplaySettings)` — inert identity, D-4 chokepoint); `grayscale_filter.dart` (`GrayscaleFilter` — inert root pass-through, D-5).
- **Wiring:** `AppDependencies` gains optional `displayController`; `buildApp` wraps the tree in a stateful `_DisplayRoot` → `DisplayScope` → `DisplayReadEndpoint` (keyed) → inert `GrayscaleFilter` → `MaterialApp` (scope above `MaterialApp`, so pushed routes read it). A null `displayController` → `buildApp` creates+owns a default whose `defaultSimulationType = deps.cvdProfile.type` and disposes it with the tree; an injected one is left for its injector. `ColorChip` now reads `DisplayScope.maybeOf` and maps its swatch through `simulateColor` (identity) — one Container still, true colour; falls back to defaults with no scope (its standalone tests unchanged).
- **Verification:** `flutter analyze` clean (No issues found); `flutter test --coverage` = **885 unit pass** (849 baseline + 36 new); coverage gate **100% on all 8 touched lib files** (PASS); bs08 integration suite green on sim (see Checkpoint). Fix passes: 0/3 (green on first full run).
- **Tokens / Time:** see dashboard row (ledger `DISPLAY-2`).

### Checkpoint / Handoff — DISPLAY-2

- **Frozen for SETTINGS-1 / SPEECH-1 / ITEST-1 / DISPLAY-3:** `DisplayController` (`settings`, `defaultSimulationType`, the three setters), `DisplaySettings` (fields + `simulationOn`), `DisplayScope.of` / `DisplayScope.maybeOf`, `DisplayReadEndpoint` (`endpointKey = Key('display-read-endpoint')`, `of`, `settings`), `simulateColor(Color, DisplaySettings)` and `GrayscaleFilter({required child})`. SETTINGS-1 binds the panel controls to the `DisplayController` setters (and reads `defaultSimulationType` for the pre-selected type, D-2); DISPLAY-3/4 fill `simulateColor` (projection via `projectDichromat`) and the alongside-original render in `ColorChip`; DISPLAY-7 makes `GrayscaleFilter` read the scope and wrap in a saturation-0 `ColorFiltered`.
- **Merge-risk:** DISPLAY-2 edited `lib/app/build_app.dart` (the `_DisplayRoot` wrapper + the `displayController` dep) — SETTINGS-1 and SPEECH-1 touch the same file; run the shells in order.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default; pending skipped) / add `--dart-define=BS08_RUN_PENDING=true` (run-pending). Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH; booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase DISPLAY-3 — AC-2 simulation off = trichromat (identity)

- **Kind:** behavior
- **Target AC:** AC-2 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** DISPLAY-4
- **Files:** `lib/display/color_simulation.dart`, `lib/widgets/color_chip.dart`
- **Tasks:** establish the display-transform path through `ColorChip`: when `simulationType == null`, the displayed colour is the original (explicit identity, one swatch). This is the chokepoint DISPLAY-4 extends.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-2; `display_test.dart` green (`TestAC02_SimOffTrichromat`).

### Result — DISPLAY-3 (2026-10-12)

- **Landed (AC-2, identity path live):** the Readout now renders the sample's **true colour** as one chromatic `ColorChip` swatch, routed through `simulateColor` (the D-4 chokepoint). With simulation off this maps the colour unchanged — "the colour as a trichromat sees it". `lib/readout/readout_controller.dart` gains `SRGBColor get displayColor => colorScience.toSRGB(_sample.coordinates)` (mirrors `grayscale`); `lib/readout/value_region.dart` renders `ColorChip(label: 'Displayed colour', color: …displayColor)`. `simulateColor` stays the identity (`=> original`) — doc updated to mark it live for AC-2; **no new branch** (DISPLAY-4 adds the `simulationType != null` projection branch, keeping coverage clean). `color_chip.dart` unchanged (its scope-read swatch, from DISPLAY-2, was already correct).
- **File-ownership note (drift):** the plan listed this phase's files as `color_simulation.dart` + `color_chip.dart`, but those seams were already complete from the DISPLAY-2 shell; AC-2 could not pass until a chromatic `ColorChip` was actually placed on the live render path, which no screen did (the Readout showed only the *neutral* lightness rectangle, never the true colour). The real deliverable was wiring the chokepoint into the Readout: touched `readout/value_region.dart` + `readout/readout_controller.dart` (+ a doc-only touch of `color_simulation.dart`); `color_chip.dart` not changed. The swatch label is deliberately generic (`'Displayed colour'`) so it never duplicates the colour name (which `name_header` owns and `readout_screen_test` asserts appears exactly once).
- **Verification:** `flutter analyze` clean; `flutter test --coverage` = **916 unit pass** (2 new: controller `displayColor`, value-region single-chromatic-swatch); coverage gate **100% on all 13 touched bs-08 lib files** (PASS). Acceptance (device `5AB9D06D…`, under the verify lock): default `display_test.dart` **green — AC-2 executes and passes**, the other nine ACs skipped/pending (12 pass / 9 skip). Fix passes: **0/3** (green on first full run).
- **Grade gate:** fresh independent grader (did not write the tests) re-graded the un-pended AC-2 test and the modified scaffold guard against G1–G6 → **2 A / 0 below A**; AC-2's prior design-grade A upheld now the render realises it; sanity check confirmed the still-pending AC-3..AC-7 remain red-at-baseline on their own Thens (adding the identity swatch breaks none of them). Grid: `behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md` § *Phase graded: DISPLAY-3*.
- **Augmentations:** none assigned to DISPLAY-3. Noted for DISPLAY-8: a swatch is now rendered pre-DISPLAY-4, so the AC-7 augmentation has a swatch to assert against earlier than planned.
- **Tokens / Time:** see dashboard row (ledger `DISPLAY-3`).

### Checkpoint / Handoff — DISPLAY-3

- **Frozen for DISPLAY-4:** the render chokepoint is live — the Readout's `ValueRegion` shows the true colour via one `ColorChip` reading `DisplayScope` → `simulateColor`. DISPLAY-4 extends `simulateColor` to project via `projectDichromat` when `simulationType != null` (scaled by severity) **and** makes `ColorChip` render the simulated swatch **alongside** the untouched original (two circular swatches) so AC-3's `swatches.length >= 2` + `any(≈ reference)` + `any(≈ original)` all hold. `_displaySwatches` reads exactly these `ColorChip` circles (the grayscale preview is a rectangle).
- **Interfaces:** `ReadoutController.displayColor` (sRGB of the sample, live); `ColorChip(label, color)` maps `color` through `simulateColor(color, DisplayScope.settings)`; `simulateColor(Color, DisplaySettings)` is the single body the simulation phases change.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default; pending skipped) / add `--dart-define=BS08_RUN_PENDING=true` (run-pending). Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH. Device lane shared/contended → `coord.sh with-lock` (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`).
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase DISPLAY-4 — AC-3 simulate a chosen type alongside the original

- **Kind:** behavior
- **Target AC:** AC-3 (full; Scenario Outline protan/deutan/tritan)
- **Depends on:** DISPLAY-3 · **Blocks:** DISPLAY-5, DISPLAY-6, DISPLAY-8
- **Files:** `lib/display/color_simulation.dart`, `lib/widgets/color_chip.dart`
- **Tasks:** when `simulationType != null`, render the simulated swatch (colour = `projectDichromat(original, CvdProfile(type: simulationType, severity: simulationSeverity))`, D-1) **alongside** the untouched original swatch. Works for all three types.
- **Exit criteria:** unit gate (100% incl. each type branch); existing suites green.
- **Acceptance gate:** un-pend AC-3; `display_test.dart` green (`TestAC03_SimulateTypeAlongsideOriginal` over all 3 examples + AC-2).

### Result — DISPLAY-4 (2026-10-12)

- **Landed (AC-3, simulate-alongside-original live):** `simulateColor` now projects when `simulationType != null` — reverses the rendered sRGB swatch to CIELAB (`srgbToLab`, the new inverse of the readout's own `labToSrgb`), projects through the shipped `projectDichromat` at `CvdProfile(type, severity: simulationSeverity)` (D-1, reused unmodified; severity falls out for DISPLAY-5/AC-4), and maps back with `labToSrgb`. With `simulationType == null` it stays the identity (AC-2 unchanged). `ColorChip` now renders **two** circular swatches when `settings.simulationOn` — the simulated colour *and* the untouched original alongside it — and exactly one (the identity) when off, so `_displaySwatches` reads 1 off / 2 on deterministically. Added `srgbToLab` to `color_science/conversions.dart` (via `color_models` `RgbColor.toLabColor()`, SI D4 — no hand-rolled colour maths); round-trips `labToSrgb` on the 8-bit grid.
- **Files:** `lib/display/color_simulation.dart` (projection branch), `lib/widgets/color_chip.dart` (alongside pair), `lib/color_science/conversions.dart` (`srgbToLab`). Tests: `test/display/color_simulation_test.dart` (rewritten — identity + per-type projection + severity scaling), `test/widgets/color_chip_test.dart` (sim-off one-swatch identity + sim-on two-swatch alongside), `test/color_science/conversions_test.dart` (`srgbToLab` + round-trip). Un-pended AC-3 in `integration_test/bs08/pending.dart`; updated the scaffold-guard `unpended` set to `{AC-2, AC-3}` in `integration_test/display_test.dart`.
- **Verification:** `flutter analyze` clean; `flutter test --coverage` = **926 unit pass** (+10 vs 916); coverage gate **100% on all 14 touched lib files** (PASS). Acceptance (device `5AB9D06D…`, under the shared-lane lock): default `display_test.dart` **green — AC-2 + AC-3 execute and pass**, the other eight ACs skipped/pending (13 pass / 8 skip). Fix passes: **1/3** (first full run had a tritan control failing — tritan barely shifts a low-blue terracotta at 8-bit; switched the unit fixture to a saturated cyan-blue that all three dichromacies shift; no product change).
- **Grade gate:** fresh independent grader (did not write the tests) re-graded the un-pended **AC-2 + AC-3** against G1–G6 → **2 A / 0 below A**. Confirmed `_displaySwatches` reads exactly the `ColorChip` circles (grayscale preview is a rectangle; the only other `BoxShape.circle` is the Capture eyedropper on another screen) and that the shipped `projectDichromat` is **never graded against itself** — AC-3 grades the rendered swatch against the harness's independent `referenceProjectDichromat`; only the CVD-neutral `toSRGB`/`labToSrgb` is shared. Grid: `behavior-test-completeness-bs-08-…md` § *Phase graded: DISPLAY-4*.
- **Augmentations:** none assigned to DISPLAY-4; the behaviour built enables no stronger assertion on an already-green AC (AC-2's sim-off count stays pinned at 1). DISPLAY-8 still owns the AC-7 augmentation (simulated swatch alongside value+label) — a swatch pair now renders under simulation, ready for it.
- **Tokens / Time:** see dashboard row (ledger `DISPLAY-4`).

### Checkpoint / Handoff — DISPLAY-4

- **Frozen for DISPLAY-5/6/8:** `simulateColor(Color, DisplaySettings)` projects through `projectDichromat` at `settings.simulationSeverity` — **DISPLAY-5 (AC-4)** needs no change to the projection (severity already flows); it only has to drive the E48 slider → `setSimulationSeverity` and assert the rendered swatch tracks it (the AC-4 test is already written against `referenceProjectDichromat(..., severity: 0.60)`). **DISPLAY-6 (AC-5)** adds the clear-on-grayscale rule in `display_controller.dart` (`setGrayscale(true)` nulls `simulationType`) — does not touch `simulateColor`/`ColorChip`. **DISPLAY-8 (AC-7)** augments the AC-7 test to assert the simulated swatch coexists with the value + label; the pair renders now.
- **Interfaces:** `ColorChip` draws `simulateColor(color, settings)` always, plus the untouched `color` alongside when `settings.simulationOn` (two circles); off → one circle (identity). `srgbToLab(SRGBColor) → ColorCoordinates` is the inverse of `labToSrgb` (shared conversions).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default; pending skipped) / add `--dart-define=BS08_RUN_PENDING=true` (run-pending). Device lane shared/contended → `coord.sh with-lock` (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`).
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase DISPLAY-5 — AC-4 severity slider sets simulation strength

- **Kind:** behavior
- **Target AC:** AC-4 (full)
- **Depends on:** DISPLAY-4 · **Blocks:** —
- **Files:** `lib/display/color_simulation.dart` (if any), `display_controller.dart` (severity→projection already wired via D-6)
- **Tasks:** ensure `simulationSeverity` (0..1, from the 0..100 slider, D-6) feeds the projection's severity, so the simulated render varies with it (0 → original; 1 → full dichromat).
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-4; `display_test.dart` green (`TestAC04_SeveritySlider` + AC-2, AC-3).

### Result — DISPLAY-5 (2026-10-12)

- **Landed (AC-4, severity-slider strength — test-only un-pend, no lib change):** the AC-4 behaviour was already live end-to-end at HEAD — the E48 slider (SETTINGS-1) calls `setSimulationSeverity(value / 100)`, the controller stores `simulationSeverity`, and DISPLAY-4's `simulateColor` already projects through the shipped `projectDichromat` at `CvdProfile(type, severity: simulationSeverity)`. DISPLAY-5 un-pended AC-4 by deleting its `pendingACs` row in `integration_test/bs08/pending.dart` and adding `AC-4` to the scaffold guard's `unpended` set in `integration_test/display_test.dart` (now `{AC-2, AC-3, AC-4}`; guard stays non-vacuous — the expected pending set is exactly the 7 remaining keys). No `lib/` file changed.
- **Verification:** `flutter analyze` clean · unit **926 pass**, coverage gate **100% on all 14 touched lib files** (vs `main`) · acceptance (device `5AB9D06D`, under `coord.sh with-lock`) **all passed — 14 pass / 7 skip**: AC-4 moved from skip → pass, running in the default suite alongside AC-2/AC-3; only later phases' ACs (AC-1, AC-5..AC-10) remain pending. First full run green — **fix passes: 0/3**.
- **Grade gate:** fresh independent grader (did not write/un-pend the tests) re-graded the un-pended **AC-2 + AC-3 + AC-4** against G1–G6 → **3 A / 0 below A**. Confirmed AC-4 does not grade the shipped projection against itself (the harness `referenceProjectDichromat` uses literal transcribed inverse matrices; shipped inverts at runtime via `_inv3`; only the CVD-neutral `toSRGB` is shared) and that it discriminates at severity 0.60 (rejects a slider stuck at original / a fixed-1.0 render; the severity-0 control rejects a fixed-non-zero severity). Grid: `behavior-test-completeness-bs-08-…md` § *Phase graded: DISPLAY-5*.
- **Augmentations:** none assigned to DISPLAY-5; the behaviour built (severity feeding the projection) enables no stronger assertion on an already-green neighbour (AC-2 is sim-off; AC-3's full-severity shift is unchanged). AC-4's own test already asserts the 0.60 render + severity-0 control at grade A, so no augmentation row is owed.
- **Tokens / Time:** see dashboard row (ledger `DISPLAY-5`).

### Checkpoint / Handoff — DISPLAY-5

- **Frozen for DISPLAY-6:** the simulation-severity path is complete and graded. **DISPLAY-6 (AC-5)** adds the clear-on-grayscale rule in `display_controller.dart` — `setGrayscale(true)` must also null `simulationType` (D-3 mutual exclusion), and toggling grayscale off must **not** re-enable the simulation. It touches only `display_controller.dart` (shares that file with this phase's domain but this phase changed no lib, so there is no conflict) and un-pends AC-5. The AC-5 test (`TestAC05_GrayscaleClearsSimulation`) is already written with the restore-off control.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default; pending skipped — AC-4 now runs here) / add `--dart-define=BS08_RUN_PENDING=true` for run-pending. Device lane shared/contended → `coord.sh with-lock` (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`). `flutter` on PATH via `/Users/matthew.quirk/development/flutter/bin`.
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase DISPLAY-6 — AC-5 grayscale clears an active simulation

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** DISPLAY-4 · **Blocks:** —
- **Files:** `lib/display/display_controller.dart`
- **Tasks:** `setGrayscale(true)` sets `grayscale = true` **and** `simulationType = null` (mutually exclusive views, D-3/D-5). Toggling grayscale off does not re-enable the simulation.
- **Exit criteria:** unit gate (incl. the clear-on-grayscale branch); existing suites green.
- **Acceptance gate:** un-pend AC-5; `display_test.dart` green (`TestAC05_GrayscaleClearsSimulation` + earlier ACs).

### Result — DISPLAY-6 (2026-10-12)

- **Landed (AC-5, clear-on-grayscale — one production rule):** `DisplayController.setGrayscale` now enforces the D-3 mutual exclusion — turning grayscale **on** also nulls `simulationType` (`simulationType: grayscale ? null : _settings.simulationType`), and turning it **off** leaves the simulation off (never re-enabled; the painter must re-select a type). `simulationSeverity` is preserved across the clear. The no-op guard (unchanged `grayscale`) is untouched. This is the **only** `lib/` change — `simulateColor`/`ColorChip`/the root filter are not touched (so AC-2/3/4 cannot regress; the grader confirmed no regression).
- **Files:** `lib/display/display_controller.dart` (the ternary clears the type on grayscale-on). Tests: `test/display/display_controller_test.dart` — **replaced** the shell-era `setters preserve the other fields` unit test (it asserted `simulationType` survived `setGrayscale(true)`, which the D-3 rule now intentionally changes; the test even noted "DISPLAY-6 will make grayscale clear the simulation") and **added** two unit tests (clear-on-grayscale-on + no-re-enable-on-off, covering both ternary arms). Un-pended AC-5 in `integration_test/bs08/pending.dart`; scaffold-guard `unpended` set → `{AC-2,AC-3,AC-4,AC-5}` in `integration_test/display_test.dart`.
- **Test change recorded (per ground rule):** the only AC/test *body* change is the un-pend + guard-set edit; no AC test was weakened. The replaced unit test is a shell-era placeholder whose premise (no cross-field rule) the delivered behaviour reverses — changed for correctness, reason noted here.
- **Verification:** `flutter analyze` clean; `flutter test --coverage` = **928 unit pass** (926 at DISPLAY-5; one shell-era test replaced in place + two new AC-5 tests → +2 net); coverage gate **100% on all 14 touched lib files** vs `main` (PASS). Acceptance (device `5AB9D06D…`, under `coord.sh with-lock`): default `display_test.dart` **green — AC-2/3/4/5 execute and pass, 15 pass / 6 skip** (AC-1, AC-6..AC-10 still pending). Fix passes: **0/3** (green on first full run).
- **Grade gate:** fresh independent grader (did not write the tests) re-graded the un-pended **AC-2 + AC-3 + AC-4 + AC-5** and the modified scaffold guard against G1–G6 → **5 A / 0 below A**, no rule failures. AC-5 is A — Given (deutan) set through the real selector and asserted via the live `DisplayReadEndpoint` before the When (G1), the configured setting answers (G2), `whenSetGrayscale` settles before the negative Then `simulationType == null` and the observable demonstrably changes deutan→null (G3), asserts the exact raw state `grayscale == true` + `simulationType == null` (G4), rejects both a toggle that leaves both views active and a re-enable-on-off impl via the control (G5), one AC only (G6). AC-5 fails **cleanly at baseline** (shell's `setGrayscale` set only the flag) and passes only via the real production rule. AC-2/3/4 unchanged → A, not regressed. Grid: `behavior-test-completeness-bs-08-…md` § *Phase graded: DISPLAY-6*.
- **Augmentations:** none assigned to DISPLAY-6; the behaviour built (clear-on-grayscale) enables no stronger assertion on an already-green neighbour. AC-7's augmentation remains owned by DISPLAY-8 (noted *B pending DISPLAY-8* in ITEST-2, out of scope here).
- **Tokens / Time:** see dashboard row (ledger `DISPLAY-6`).

### Checkpoint / Handoff — DISPLAY-6

- **Frozen for DISPLAY-7 / DISPLAY-8:** the D-3 mutual-exclusion rule now lives in `DisplayController.setGrayscale` (grayscale-on ⇒ `simulationType = null`; off ⇒ no re-enable). **DISPLAY-7 (AC-6)** is independent of this — it makes the root `GrayscaleFilter`/`ColorFiltered` active when `grayscale` is set (`lib/display/grayscale_filter.dart` + `lib/app/build_app.dart`); it does not touch `display_controller.dart`, so it is safe to run in parallel with any other DISPLAY phase. **DISPLAY-8 (AC-7)** augments the AC-7 integration test to assert the simulated swatch coexists with the reading's value + label (the swatch pair already renders from DISPLAY-4); it touches `color_chip.dart`/`readout/*` guard-only, not the controller.
- **Interfaces:** `DisplayController` setters unchanged in shape — `setSimulationType(CvdType?)`, `setSimulationSeverity(double)`, `setGrayscale(bool)` (now with the D-3 clear). `DisplaySettings` fields + `simulationOn` unchanged.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (default; pending skipped — AC-5 now runs here) / add `--dart-define=BS08_RUN_PENDING=true` (run-pending). Device lane shared/contended → `coord.sh with-lock` (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance`). `flutter` on PATH via `/Users/matthew.quirk/development/flutter/bin`.
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase DISPLAY-7 — AC-6 value-only grayscale greys the whole app

- **Kind:** behavior
- **Target AC:** AC-6 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** —  *(independent of the simulation chain; may run in parallel)*
- **Files:** `lib/display/grayscale_filter.dart`, `lib/app/build_app.dart`
- **Tasks:** make the root `ColorFiltered` (saturation-0 matrix) active when `grayscale` is set, wrapping the whole app so the camera feed, palette swatches and readings all render achromatic (D-5).
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-6; `display_test.dart` green (`TestAC06_GrayscaleWholeApp`).

## Phase DISPLAY-8 — AC-7 a reading under simulation keeps its value and label

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** DISPLAY-4 · **Blocks:** —
- **Files:** `lib/widgets/color_chip.dart` / `lib/readout/*` as needed (guard only)
- **Tasks:** ensure the simulated view still renders the reading's numeric value + plain-language label (the label contract, D-7) — the simulated swatch is additive, never a replacement for the text.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-7; `display_test.dart` green (`TestAC07_ReadingKeepsValueAndLabel` + earlier ACs).

### Result

- **Landed (test-only — no `lib/` change):** AC-7 un-pended (row deleted from `integration_test/bs08/pending.dart`) and its scheduled **augmentation** made in `integration_test/display_test.dart`: under deutan simulation the test now asserts the simulated swatch coexists with the reading's value + label — `_displaySwatches` contains a swatch `_colorNear` `referenceProjectDichromat(sample, deutan)` (independent reference) **and** the original, *while* a `ValueReading` with the numeric value + non-empty word is present ("not colour alone", D-7). This closes the *B pending DISPLAY-8* limitation (at ITEST-2 no swatch existed to reject "a colour swatch with no text"). No production code needed — the label contract (bs-01) and the alongside-swatch render (DISPLAY-4) already hold.
- **Also updated (scaffold guard, 1 fix pass):** added `AC-7` to the `unpended` set in `display_test.dart`'s pending-gate guard (`{AC-2,AC-3,AC-4,AC-5,AC-7}`) — the first acceptance run failed only on that guard (expected pending set no longer matched after the un-pend); the re-run is all green.
- **Gates:** `flutter analyze` clean; **unit 928 pass**; coverage gate **PASS** — no `lib/` file touched, so the cumulative touched-set (14 bs-08 files vs `main`) stays at 100%. Acceptance on sim `5AB9D06D` under the verify lock: **16 pass / 5 skipped** (AC-2/3/4/5/7 execute + pass; AC-1/6/8/9/10 pending for SETTINGS-2/DISPLAY-7/SPEECH-2/3/4). Grade (self-graded by the parallel worker against G1–G6; independent full-suite re-grade deferred to SIGNOFF-1): **5 A / 0 below A**, **AC-7 B-pending-DISPLAY-8 → A**. Fix passes: **1/3**.
- **Tokens / Time:** 7,504,305 / 0m 00s.

### Checkpoint / Handoff

- **AC-7 is closed (A).** The suite has **no open B-pending grade**; every un-pended AC (AC-2/3/4/5/7) is A. Remaining display AC: **AC-6 (DISPLAY-7)**.
- **Frozen:** the AC-7 augmentation reads the simulation chokepoint through `_displaySwatches` + the independent `referenceProjectDichromat`; don't grade the simulated swatch against the shipped projection.
- **Parallel note:** DISPLAY-8 is test-only and touched no production file, so it cannot regress AC-6/DISPLAY-7. Both DISPLAY-7 and DISPLAY-8 edit `display_test.dart` (the AC group + the scaffold guard `unpended` set) and `bs08/pending.dart` (their AC rows) and this module plan (Status + dashboard) — expected overlap; reconcile unions the two `unpended` entries (`{…,AC-6,AC-7}`) and both appended grid sections.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d <udid>` (default) / `--dart-define=BS08_RUN_PENDING=true` (run-pending)
