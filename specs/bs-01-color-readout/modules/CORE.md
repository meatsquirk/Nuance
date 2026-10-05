# Module CORE — scaffold, domain model, app assembly, navigation

**Status:** Done — CORE-1..3 complete; `buildApp` assembles the app and opens on the placeholder Readout route
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** the Flutter project root (`pubspec.yaml`, `analysis_options.yaml`, `.gitignore`),
`lib/domain/` (`sample.dart`, `provenance.dart`, `color_coordinates.dart`), `lib/app/` (`build_app.dart`,
routing), `lib/compare/compare_stub.dart`, `lib/recipes/recipes_stub.dart`, the coverage-gate script under
`tool/`.
**Depends on:** — · **Blocks:** COLOR, A11Y, READOUT, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 4,803,956 | 12m 33s (13m 49s) |
| 2 | shell | — | ✅ Done | 6,628,852 | 22m 29s (28m 18s) |
| 3 | shell | — | ✅ Done | 2,455,251 | 4m 44s (4m 44s) |

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
  ITEST-1 calls the same entry, swapping only the faked platform sinks. **Lands in CORE-3**, not CORE-2:
  it injects the `ColorScience`/`Speech`/`Haptics` interfaces (COLOR-1 / A11Y-1), so it must follow them,
  whereas the domain + router it assembles land in CORE-2 first. Breaking this cycle is design decision D-7.

## Open gates

- **G-1 (approve the spec)** — ✅ Resolved 2026-10-05: approved by owner Matt Quirk. Approval recorded as the spec's first line.

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

### Result

Landed: Flutter 3.47.6 / Dart 3.13.5 project scaffolded at the repo root
(`paint_color_assistant`, org `com.nuance`, platforms android + ios). Minimal
placeholder app in `lib/main.dart` (replaces the counter demo). `pubspec.yaml`
gains the `integration_test` dev-dep for stage 3. Coverage-gate tool
`tool/coverage_gate.dart` added; CI stub `.github/workflows/ci.yml` runs
analyze + `flutter test --coverage` + the gate.

Verification: `flutter analyze` clean (no issues). `flutter test` green (2
tests, `test/smoke_test.dart`). Coverage: `lib/main.dart` LF 8 / LH 8 = 100%.
Gate proven both ways — PASS on clean tree (exit 0); FAIL (exit 1) on a planted
uncovered line inside `main.dart` (reported "9/10 lines covered — uncovered
lines: 10") and on an uncovered untracked lib file ("NO COVERAGE DATA").

Coverage model: `flutter test --coverage` emits LINE coverage only (Dart has no
branch coverage) — recorded in the module checkpoint and the master plan. Gate
enforces 100% line coverage on touched `lib/**.dart`; per-branch exercise is a
review requirement, not tool-enforced.

Fix passes: 1/3 (first full run surfaced a `main()` name-collision with the
test file's own `main`; fixed by importing the app with an `as app` prefix).
No augmentations, no exclusions. G-1 (approve spec) resolved this session.
Tokens 4,803,956 · time 12m 33s active (13m 49s wall).

### Checkpoint / Handoff

- **Flutter SDK:** installed to `~/development/flutter` (stable, 3.47.6). Not on
  the default PATH — prepend `export PATH="$HOME/development/flutter/bin:$PATH"`
  before any `flutter`/`dart` command. (This carries bs-02 G-2's SDK note too.)
- **Verification commands** (run from repo root with the PATH export):
  - `flutter analyze`
  - `flutter test --coverage`  → writes `coverage/lcov.info`
  - `dart run tool/coverage_gate.dart main`  (base ref = arg, else
    `$COVERAGE_GATE_BASE`, else `main`)
- **Frozen interfaces:** app entry is `main()` + `PaintColorAssistantApp` in
  `lib/main.dart`. CORE-2 replaces the placeholder home with real app assembly
  (`buildApp(deps)`) and navigation, and adds `lib/domain/`.
- **Known gaps:** none. No product code yet (scaffold only). The `.feature`
  files for bs-02..bs-14 and `docs/` were left untracked (prior planning
  output, not this phase's to commit).
- **Next phase (CORE-2):** domain model (`Sample`, `Provenance`,
  `ColorCoordinates`), `buildApp`, router with typed routes + stub
  Comparison/Recipes screens. Keep every new `lib` file at 100% line coverage.

## Phase 2 — Shell: domain model, router + stub screens

> Rescoped by D-7: this phase is the **root shell** — domain types + navigation only, no `buildApp`
> (that moves to CORE-3). It depends on nothing from COLOR/A11Y, so COLOR-1 and A11Y-1 compile against it.

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-1 · **Blocks:** COLOR-1, A11Y-1, CORE-3, READOUT-5 (provenance types), READOUT-6 (nav)
- **Files:** `lib/domain/sample.dart`, `lib/domain/provenance.dart`, `lib/domain/color_coordinates.dart`,
  `lib/app/router.dart`, `lib/compare/compare_stub.dart`, `lib/recipes/recipes_stub.dart`.
  *(`lib/app/build_app.dart` and `main.dart` wiring are CORE-3.)*
- **Tasks:**
  1. Define `Sample`, `ColorCoordinates` (canonical CIELAB + helpers to hold derived spaces), `Provenance`
     (tiers + labels + note), and the append-ready evidence list (behaviour deferred; shape only).
  2. Routing with typed `toComparison(sample, slot)` / `toRecipes(target)`; **stub** Comparison and Recipes
     screens that render the passed sample + slot/target as findable text (the read endpoint for AC-9/10/11).
     These need only the domain types. Behaviour unchanged elsewhere; `main.dart` stays the CORE-1 placeholder.
- **Exit criteria:** unit/widget gate passes on the new domain + router + stub code (100% line coverage on
  touched `lib` files); `flutter analyze` clean; `flutter test` green; app still builds (placeholder home
  unchanged — assembly to the Readout route is CORE-3).
- **Acceptance gate:** *(n/a — shell)*

### Result

- Landed: domain layer — `Sample` (name nullable, required non-null `Provenance`, `justCaptured`,
  append-ready `EvidencePoint` list, `copyWith`), `ColorCoordinates` (canonical CIELAB L\*/a\*/b\*),
  `Provenance` (4 tiers + `label` + optional note); typed `AppRouter.toComparison(sample, slot)` /
  `toRecipes(target)` with `ComparisonSlot`; stub `ComparisonStubScreen` / `RecipesStubScreen` rendering the
  handed-off sample as findable text (read endpoint for AC-9/10/11). `main.dart`/`buildApp` untouched — CORE-3.
- Also (D-7): split the old CORE-2 into this phase + new CORE-3; COLOR-1/A11Y-1 re-pointed to depend on
  CORE-2 and defer their `buildApp` registration to CORE-3. Master plan + COLOR/A11Y module plans updated.
- Fix passes: 2/3 · Suites run: unit/widget (this feature) only; no acceptance suite yet (stage 3).
- Tests: 34 passing · Coverage (touched files): 100% line on 7 files (Dart emits line coverage only; every
  branch exercised by a test per the review requirement) · Acceptance: n/a (shell).
- Test grades: n/a (shell) · Augmentations made: none · Justified exclusions: none.
- Closed by: gate pass.
- Tokens: 3b711674: in 94 · cache write 149,678 · cache read 6,389,064 · out 90,016 · total 6,628,852
  (claude-opus-4-8) · 2026-10-05 17:00 EDT → 17:29 · wall 28m 18s · active 22m 29s · **Phase total:
  6,628,852 tokens, 22m 29s active (28m 18s wall)**

### Checkpoint / Handoff

- **Frozen:** `lib/domain/` types (`Sample`, `ColorCoordinates`, `Provenance`, `EvidencePoint`),
  `lib/app/router.dart` (`AppRouter`, `ComparisonSlot`), and the stub screens
  (`ComparisonStubScreen{sampleA,sampleB}`, `RecipesStubScreen{target}`). COLOR-1/A11Y-1 import the domain
  types; CORE-3 wires `AppRouter` into `buildApp` and registers services.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`.
- **Known gaps:** none. `buildApp` + `main.dart` wiring deferred to CORE-3; `main.dart` is still the CORE-1
  placeholder, so the app does not yet launch to the Readout route.
- **Next phase should:** run **COLOR-1 ∥ A11Y-1** (both depend on CORE-2, own disjoint files, defer `buildApp`
  registration to CORE-3). Then **CORE-3** assembles `buildApp` from the domain + both interface stubs.

## Phase 3 — Shell: `buildApp` assembly, service registration, main wiring

> Added by D-7. The assembly half of the old CORE-2. Runs after CORE-2 (domain + router) **and** COLOR-1 +
> A11Y-1 (the interfaces it injects). This is where COLOR-1/A11Y-1's deferred "register in buildApp" lands.

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-2, COLOR-1, A11Y-1 · **Blocks:** READOUT-1, ITEST-1
- **Files:** `lib/app/build_app.dart`, `lib/main.dart`.
- **Tasks:**
  1. `buildApp(deps)` — the single production assembly entry — wires the CORE-2 router into a `MaterialApp`
     and injects `ColorScience` (COLOR-1 stub), `Speech` + `Haptics` (A11Y-1 stubs). ITEST-1 calls the same
     entry, swapping only the faked platform sinks.
  2. Register the COLOR-1 / A11Y-1 stub services in `buildApp` (their Phase-1 phases deferred this step here).
  3. `main.dart` calls `buildApp` with the real/placeholder impls and launches to a placeholder Readout route.
- **Exit criteria:** unit/widget gate (100% line coverage on touched `lib` files); `flutter analyze` clean;
  `flutter test` green; app builds and launches to the placeholder Readout route via `buildApp`.
- **Acceptance gate:** *(n/a — shell)*

### Result

- Landed: `lib/app/build_app.dart` — `AppDependencies` (immutable holder: `colorScience`, `speech`,
  `haptics`, `router` defaulting to `const AppRouter()`), `AppScope` (an `InheritedWidget` exposing the deps
  via `AppScope.of(context)`), and `buildApp(deps)` — the single production assembly entry — wrapping a
  `MaterialApp` in `AppScope` and opening on a private `_ReadoutPlaceholder` (the placeholder Readout route
  READOUT-1 replaces). `lib/main.dart` rewritten: `main()` → `runApp(buildApp(productionDependencies()))`;
  `productionDependencies()` wires `ColorScienceImpl` + `NoopSpeech` + `NoopHaptics` (D-1 no native sinks).
  COLOR-1/A11Y-1's deferred "register in buildApp" step (D-7) is now discharged.
- Also: updated `test/smoke_test.dart` (the old `PaintColorAssistantApp` it asserted no longer exists) — it
  now checks `productionDependencies()` wiring and that `main()` boots to the `Readout` route; added
  `test/app/build_app_test.dart` (buildApp route + AppScope injection + `updateShouldNotify` both branches).
- Fix passes: 1/3 — first run failed `updateShouldNotify is true`: two `const AppDependencies` are
  canonicalised to one object, so the "changed" branch needs genuinely distinct (non-`const`) instances;
  added a `_freshDeps()` helper. Code unchanged; test corrected.
- Suites run: unit/widget (this feature) only; no acceptance suite yet (stage 3).
- Tests: 72 passing · Coverage (touched files): 100% line on all 15 touched `lib` files, incl. the two new/
  changed (`build_app.dart`, `main.dart`) — Dart emits line coverage only; every branch exercised by a test
  per the review requirement (`updateShouldNotify` true/false, router default vs. injected). Acceptance: n/a.
- Test grades: n/a (shell) · Augmentations made: none · Justified exclusions: none.
- App launch: the widget test boots `main()` → `buildApp` → `MaterialApp` showing `Readout`; `flutter analyze`
  clean. No full platform build run (CORE-1 proved the build pipeline; launch proven by the widget test).
- Closed by: gate pass.
- Tokens: 2,455,251 · time: 4m 44s active (4m 44s wall). **Phase total: 2,455,251 tokens, 4m 44s.**

### Checkpoint / Handoff

- **Frozen:** `lib/app/build_app.dart` — `AppDependencies{colorScience, speech, haptics, router}`,
  `AppScope.of(context) → AppDependencies`, and `Widget buildApp(AppDependencies deps)` (opens on the Readout
  route). `lib/main.dart` — `main()` + `productionDependencies() → AppDependencies`. The Readout destination
  is a private `_ReadoutPlaceholder` inside `build_app.dart` — **READOUT-1 replaces the `home:` of the
  `MaterialApp`** (and may lift the route out) with the real Readout screen behind this same entry; neither
  `main.dart` nor the harness changes.
- **Injection seam for later phases:** the Readout controller (READOUT-1) reads services via
  `AppScope.of(context)` rather than constructing them, so the same screen runs against the production stubs
  and ITEST-1's fakes. ITEST-1 calls `buildApp` with an `AppDependencies` whose `speech`/`haptics` (and, if
  needed, `colorScience`) are recording fakes (D-6).
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`.
- **Known gaps:** none. The Readout route renders only a `Readout` marker until READOUT-1.
- **Next phase should:** run **READOUT-1** (Readout screen scaffold + controller; last shell) — depends on
  CORE-3 (done), COLOR-1, A11Y-1 (done). After READOUT-1 the ITEST stage (ITEST-1) is unblocked. G-2 (approve
  acceptance tests) stays open and blocks only the behavior stage.
