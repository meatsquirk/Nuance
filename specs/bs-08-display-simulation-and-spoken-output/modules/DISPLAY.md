# Module DISPLAY — cross-cutting display pipeline (simulation + grayscale)

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/display/display_settings.dart`, `lib/display/display_controller.dart`, `lib/display/display_scope.dart`, `lib/display/display_read_endpoint.dart`, `lib/display/color_simulation.dart` (thin reuse of `projectDichromat`), `lib/display/grayscale_filter.dart`; integration points in `lib/widgets/color_chip.dart` and `lib/app/build_app.dart` (root grayscale wrapper + `DisplayScope` wiring). Unit tests under `test/display/`.
**Depends on:** — · **Blocks:** SETTINGS (needs `DisplayController`), ITEST (needs the read endpoint + rendering), SPEECH (scaffold only)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| DISPLAY-1 | scaffold | — | ⬜ Next | | |
| DISPLAY-2 | shell | — | ⬜ Todo | | |
| DISPLAY-3 | behavior | AC-2 | ⬜ Todo | | |
| DISPLAY-4 | behavior | AC-3 | ⬜ Todo | | |
| DISPLAY-5 | behavior | AC-4 | ⬜ Todo | | |
| DISPLAY-6 | behavior | AC-5 | ⬜ Todo | | |
| DISPLAY-7 | behavior | AC-6 | ⬜ Todo | | |
| DISPLAY-8 | behavior | AC-7 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `DisplaySettings` (value type: `CvdType? simulationType`, `double simulationSeverity` 0..1, `bool grayscale`; `simulationType == null` ⇔ simulation off); `DisplayController extends ChangeNotifier` with `setSimulationType(CvdType?)`, `setSimulationSeverity(double)`, `setGrayscale(bool)`; `DisplayScope` (`InheritedNotifier<DisplayController>`) with `DisplayScope.of(context)`; `DisplayReadEndpoint` (keyed, exposes the live `DisplaySettings`).
- **Consumes:** `projectDichromat(ColorCoordinates, CvdProfile)` and `CvdProfile`/`CvdType` from `lib/a11y/cvd/` (frozen; reused, never re-derived — D-1); `AppDependencies.cvdProfile` for the settings default (D-2); the shared `ColorChip` as the colour-render chokepoint (D-4).
- **Rendering split (D-4/D-5):** simulation is a **per-swatch** transform (original + simulated side by side, through `ColorChip` reading `DisplayScope`); value-only grayscale is a **single root** `ColorFiltered` in `buildApp` (greys everything, incl. the live camera). The two are mutually exclusive (D-3): `setGrayscale(true)` nulls `simulationType`.
- **Conflict (spec vs architecture):** the spec's Rule names "simulate the painter's CVD type" but its scenario lets the painter *choose* a type; resolved by D-2 — the setting carries its own `simulationType`, defaulting from `AppDependencies.cvdProfile`.

## Open gates

- **G-1** (spec approval) blocks DISPLAY-1 (the whole feature's scaffold).
- **G-2** (acceptance tests approved) blocks DISPLAY-3..8 (all behavior).

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

## Phase DISPLAY-3 — AC-2 simulation off = trichromat (identity)

- **Kind:** behavior
- **Target AC:** AC-2 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** DISPLAY-4
- **Files:** `lib/display/color_simulation.dart`, `lib/widgets/color_chip.dart`
- **Tasks:** establish the display-transform path through `ColorChip`: when `simulationType == null`, the displayed colour is the original (explicit identity, one swatch). This is the chokepoint DISPLAY-4 extends.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-2; `display_test.dart` green (`TestAC02_SimOffTrichromat`).

## Phase DISPLAY-4 — AC-3 simulate a chosen type alongside the original

- **Kind:** behavior
- **Target AC:** AC-3 (full; Scenario Outline protan/deutan/tritan)
- **Depends on:** DISPLAY-3 · **Blocks:** DISPLAY-5, DISPLAY-6, DISPLAY-8
- **Files:** `lib/display/color_simulation.dart`, `lib/widgets/color_chip.dart`
- **Tasks:** when `simulationType != null`, render the simulated swatch (colour = `projectDichromat(original, CvdProfile(type: simulationType, severity: simulationSeverity))`, D-1) **alongside** the untouched original swatch. Works for all three types.
- **Exit criteria:** unit gate (100% incl. each type branch); existing suites green.
- **Acceptance gate:** un-pend AC-3; `display_test.dart` green (`TestAC03_SimulateTypeAlongsideOriginal` over all 3 examples + AC-2).

## Phase DISPLAY-5 — AC-4 severity slider sets simulation strength

- **Kind:** behavior
- **Target AC:** AC-4 (full)
- **Depends on:** DISPLAY-4 · **Blocks:** —
- **Files:** `lib/display/color_simulation.dart` (if any), `display_controller.dart` (severity→projection already wired via D-6)
- **Tasks:** ensure `simulationSeverity` (0..1, from the 0..100 slider, D-6) feeds the projection's severity, so the simulated render varies with it (0 → original; 1 → full dichromat).
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-4; `display_test.dart` green (`TestAC04_SeveritySlider` + AC-2, AC-3).

## Phase DISPLAY-6 — AC-5 grayscale clears an active simulation

- **Kind:** behavior
- **Target AC:** AC-5 (full)
- **Depends on:** DISPLAY-4 · **Blocks:** —
- **Files:** `lib/display/display_controller.dart`
- **Tasks:** `setGrayscale(true)` sets `grayscale = true` **and** `simulationType = null` (mutually exclusive views, D-3/D-5). Toggling grayscale off does not re-enable the simulation.
- **Exit criteria:** unit gate (incl. the clear-on-grayscale branch); existing suites green.
- **Acceptance gate:** un-pend AC-5; `display_test.dart` green (`TestAC05_GrayscaleClearsSimulation` + earlier ACs).

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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d <udid>` (default) / `--dart-define=BS08_RUN_PENDING=true` (run-pending)
