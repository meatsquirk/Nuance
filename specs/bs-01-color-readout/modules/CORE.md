# Module CORE — scaffold, domain model, app assembly, navigation

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** the Flutter project root (`pubspec.yaml`, `analysis_options.yaml`, `.gitignore`),
`lib/domain/` (`sample.dart`, `provenance.dart`, `color_coordinates.dart`), `lib/app/` (`build_app.dart`,
routing), `lib/compare/compare_stub.dart`, `lib/recipes/recipes_stub.dart`, the coverage-gate script under
`tool/`.
**Depends on:** — · **Blocks:** COLOR, A11Y, READOUT, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
| 2 | shell | — | ⬜ Todo | | |

## Interface reconciliation

- **`Sample`** (domain): `name` (nullable until named), `ColorCoordinates` (canonical CIELAB, from which all
  spaces derive), `Provenance`, and a `justCaptured` flag. Append-ready: a `Sample` keeps a list of evidence
  points, each source-tagged (SI D9), so the future P2P layer is a data-merge, not a schema change.
- **`Provenance`** enum/tier: `measured` / `calculated` / `estimated` / `confirmed`, each with its
  user-facing label and optional note. Required, non-null on every `Sample`.
- **Navigation** exposes typed routes `toComparison(sample, slot)` and `toRecipes(target)`. For bs-01 the
  Comparison and Recipes destinations are **stub screens** that render the handed-off sample + slot/target so
  the acceptance tests can observe the handoff; bs-03 / bs-04 replace the stubs with the real screens via the
  same route arguments.
- **`buildApp(deps)`**: the single production assembly entry (injects `ColorScience`, `Speech`, `Haptics`).
  ITEST-1 calls the same entry, swapping only the faked platform sinks.

## Open gates

- **G-1 (approve the spec)** blocks Phase 1 (scaffold).

## Phase 1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1 must be resolved first) · **Blocks:** CORE-2, COLOR-1, A11Y-1
- **Files:** `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `tool/coverage_gate.dart` (or shell),
  `test/smoke_test.dart`, CI workflow stub.
- **Tasks:**
  1. Confirm the Flutter SDK is available (not on PATH at planning — installing it is a machine change; get
     the user's yes first). Create the feature branch `feat/bs-01-color-readout` from `main`.
  2. `flutter create` the app at the repo root (or adopt the existing root), Android-first; add
     `analysis_options.yaml` (lints) and a Flutter `.gitignore`.
  3. Establish the unit test + coverage command (`flutter test --coverage` → `coverage/lcov.info`) and a
     coverage-gate tool that enforces 100% line coverage on touched files. **Note:** `flutter test --coverage`
     emits line coverage only (Dart tooling does not produce branch coverage); record this limit per
     `references/verification.md` and gate on lines + require explicit per-branch unit tests by review.
  4. Add the `integration_test` package dev-dependency so stage 3 has a runner; no tests yet beyond smoke.
  5. Prove the gate: it passes on the clean tree and fails on a planted uncovered line; record the baseline
     test run.
- **Exit criteria:** `flutter analyze` clean; `flutter test` green; coverage gate passes clean and fails on a
  planted gap; branch pushed.
- **Acceptance gate:** *(n/a — scaffold)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 2 — Shell: domain, assembly, navigation, stub screens

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-1 · **Blocks:** READOUT-1, ITEST-1, READOUT-5 (provenance types), READOUT-6 (nav)
- **Files:** `lib/domain/sample.dart`, `lib/domain/provenance.dart`, `lib/domain/color_coordinates.dart`,
  `lib/app/build_app.dart`, `lib/app/router.dart`, `lib/compare/compare_stub.dart`,
  `lib/recipes/recipes_stub.dart`.
- **Tasks:**
  1. Define `Sample`, `ColorCoordinates` (canonical CIELAB + helpers to hold derived spaces), `Provenance`
     (tiers + labels + note), and the append-ready evidence list (behaviour deferred; shape only).
  2. `buildApp(deps)` assembles the app with injected `ColorScience`/`Speech`/`Haptics` (interfaces from
     COLOR-1 / A11Y-1); production `main.dart` calls it with real impls.
  3. Routing with typed `toComparison(sample, slot)` / `toRecipes(target)`; **stub** Comparison and Recipes
     screens that render the passed sample + slot/target as findable text (the read endpoint for AC-9/10/11).
     Behaviour unchanged elsewhere.
- **Exit criteria:** unit gate passes on the new domain code; `flutter test` green; app builds and launches
  to a placeholder Readout route.
- **Acceptance gate:** *(n/a — shell)*

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
