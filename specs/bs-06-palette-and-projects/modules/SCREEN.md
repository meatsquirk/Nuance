# Module SCREEN — Palette screen

**Status:** In progress — SCREEN-1 ✅ done (shell); SCREEN-2 (AC-1) / SCREEN-3 (AC-11) startable once G-2 resolves
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/palette/palette_screen.dart` + its region widgets, `lib/app/build_app.dart` (PaletteScreen entry marker + home selection), `lib/app/router.dart` (route to bs-07 entry placeholder)
**Depends on:** PALETTE (controller + read endpoint), PROJECT (controller + read endpoint), bs-03/07 `CvdProfile` · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 12,251,452 | 17m 44s |
| 2 | behavior | AC-1 | ⬜ Todo | | |
| 3 | behavior | AC-11 | ⬜ Todo | | |

## Interface reconciliation

- The Palette screen is selected by a new entry marker on `AppDependencies` (same priority-ordered pattern as `captureSource`/`comparisonEntry`/`recipesEntry` in `buildApp`).
- Keyed regions (stable `static Key`s) for the paint list, provenance legend, palette selector, projects list and vision-profile card, so the ITEST harness can find them; read endpoints from PALETTE/PROJECT are mounted here.
- AC-11 reads the injected `CvdProfile` (D-7) and routes to a **bs-07 self-assessment entry placeholder** — bs-07 is unbuilt; the route target is a placeholder this module owns, replaced when bs-07 lands.

## Open gates

- **G-2** blocks Phases 2–3 (behavior). Phase 1 (shell) depends only on PALETTE-1/PROJECT-1.

## Phase 1 — Shell: screen, regions, controls, nav

- **Kind:** shell · **Target AC:** — · **Depends on:** PALETTE-1, PROJECT-1 · **Blocks:** ITEST-1, SCREEN-2, SCREEN-3
- **Files:** `lib/palette/palette_screen.dart`, region widgets in `lib/palette/` / `lib/widgets/`, `lib/app/build_app.dart`, `lib/app/router.dart`
- **Tasks:**
  1. Palette screen scaffold with keyed regions (paint list, legend, palette selector, projects list, vision-profile card) rendering placeholders; E31 selector, E32 add, E33 open, E34 export controls present but inert.
  2. Mount `PaletteReadEndpoint` + `ProjectReadEndpoint`; add the PaletteScreen entry marker + `buildApp` home selection; add a bs-07-entry placeholder route.
- **Exit criteria:** unit gate on touched files; existing suite green; screen renders with empty state and all region keys resolvable.

### Result

- **Landed (shell, no AC):** New `lib/palette/`: `palette_screen.dart` (`PaletteScreen` — pure view over a `PaletteController` + `ProjectController`, `AppBar('Palette')`, a `ListenableBuilder` over `Listenable.merge([..])`, laying out every region; `viewSelectorKey` for E31); region widgets `paint_list_region.dart` (`PaintListRegion`, `regionKey`/`addPaintKey` E32), `provenance_legend_region.dart` (`ProvenanceLegendRegion`, `regionKey`), `palette_selector_region.dart` (`PaletteSelectorRegion`, `regionKey`), `projects_region.dart` (`ProjectsRegion`, `regionKey`/`openProjectKey` E33/`exportKey` E34), `vision_profile_card.dart` (`VisionProfileCard`, `regionKey`/`retakeKey` E30); and `self_assessment_entry_screen.dart` (`SelfAssessmentEntryScreen` bs-07 placeholder, `screenKey`). All E30–E34 controls render **inert** (`onPressed: null`). `lib/app/build_app.dart`: `PaletteEntry` marker + `AppDependencies.paletteEntry`/`projectSource` (default `InMemoryProjectSource`) + a `buildApp` home branch after `recipesEntry` + `PaletteHomeScreen` (owns both controllers from `AppScope`, mounts `PaletteReadEndpoint` + `ProjectReadEndpoint`). `lib/app/router.dart`: `toSelfAssessment()` route to the placeholder (D-7). `lib/main.dart`: the **deferred production store wiring** — async `main` + `productionDependencies()` opens a file-backed `DriftPersistentStore` (`NativeDatabase` over the app-documents SQLite file via **path_provider**) + `FileSourcePhotoStore`, builds + loads `PersistentPaletteSource`/`PersistentProjectSource`, and a pure `assembleDependencies(...)` pairs them with the stubs + `demoCaptureSource` (app still opens on Capture). `pubspec.yaml` adds `path_provider` + `sqlite3_flutter_libs` (deps) and `path_provider_platform_interface` + `plugin_platform_interface` (dev, for the smoke-test path fake).
- **Deviations / notes:** (1) The shell renders **both** views' regions at once so every region key resolves (exit criterion); SCREEN-2 makes E31 toggle view visibility (AC-1). (2) Production injects the loaded persistent `paletteSource`/`projectSource` + store + photo sink but **leaves `paletteEntry` null** (opens on Capture, no shipped-screen behaviour change) — the mandated store wiring is in place and the Palette screen reads it when later nav reaches it. (3) `VisionProfileCard` is a parameterless placeholder; SCREEN-3 adds the `CvdProfile` estimate render + wires `retakeKey` → `toSelfAssessment`. (4) `smoke_test.dart` updated for the async wiring: it now tests `assembleDependencies` (pure) + `productionDependencies`/`main()` under a `MockPlatformInterfaceMixin` path_provider fake (drift's file store runs on host, DATA-2).
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **688 unit/widget passing** (was 673; +15). Coverage gate vs `main`: **100%** on all 24 touched `lib/` files (incl. new `lib/palette/*`, `lib/main.dart`, `build_app.dart`, `router.dart`). Acceptance: n/a (shell; all 11 ACs still pending — the `palette_test.dart` runner is unchanged).
- **Fix passes:** 1/3 — pass 1: `flutter analyze` flagged `Directory` undefined in `smoke_test.dart` (missing `dart:io` import); added it. Re-run clean; tests + coverage passed first try. (Implementation correct from the first run.)
- **Justified exclusions:** on-sim acceptance suites not re-run. SCREEN-1's `buildApp` change is purely additive (a new branch reached only when `paletteEntry != null`, which no existing harness sets) and `main.dart` is not used by any harness (they call `buildApp(deps)` directly); the host suite compiles `buildApp` + the new screen and is green, so the bs-01/03/04 on-sim behaviour and the bs-06 pending runner are unchanged. Consistent with PROJECT-1/DATA-2.
- **Closed by:** unit + coverage gate pass; existing suite green; screen renders empty state with every region key resolvable (tested).
- Tokens: see master ledger (SCREEN-1 row). **Phase total: 12,251,452 tokens, 17m 44s active.**

### Checkpoint / Handoff

- **Frozen interfaces:**
  - `PaletteScreen({required PaletteController paletteController, required ProjectController projectController})` — `static const viewSelectorKey = ValueKey('palette-view-selector')` (E31).
  - Region keys (stable `ValueKey`s): `PaintListRegion.regionKey` `palette-paint-list-region` + `.addPaintKey` `palette-add-paint-button` (E32); `ProvenanceLegendRegion.regionKey` `palette-provenance-legend-region`; `PaletteSelectorRegion.regionKey` `palette-selector-region`; `ProjectsRegion.regionKey` `palette-projects-region` + `.openProjectKey` `palette-open-project-button` (E33) + `.exportKey` `palette-export-project-button` (E34); `VisionProfileCard.regionKey` `palette-vision-profile-card` + `.retakeKey` `palette-retake-assessment-button` (E30). All E30–E34 controls are `TextButton(onPressed: null)` — behaviour phases wire `onPressed`.
  - `PaletteEntry` marker + `AppDependencies.paletteEntry` (null default) + `AppDependencies.projectSource` (default `const InMemoryProjectSource()`). `buildApp` opens on `PaletteHomeScreen` when `paletteEntry != null` (priority after capture/comparison/recipes). `PaletteHomeScreen` reads `paletteSource`/`projectSource` from `AppScope` and mounts both read endpoints (keys `palette-read-endpoint` / `project-read-endpoint`).
  - `AppRouter.toSelfAssessment()` → `SelfAssessmentEntryScreen` (`screenKey` `self-assessment-entry-screen`). bs-07 replaces the screen behind this route.
  - `lib/main.dart`: `assembleDependencies({store, sourcePhotoStore, paletteSource, projectSource})` (pure) + async `productionDependencies()` (opens the file store). The ITEST harness builds its own deps with a `PaletteEntry` + an in-memory-backed store, **not** `main()`.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`. Flutter SDK `/Users/matthew.quirk/development/flutter/bin`. The acceptance runner (`integration_test/palette_test.dart -d <udid>`) is unchanged — no AC un-pended yet. path_provider is faked in `smoke_test.dart` via `PathProviderPlatform.instance`.
- **Known gaps / deferred:** E31 toggle inert (SCREEN-2, AC-1); `VisionProfileCard` shows a placeholder, not the `CvdProfile` estimate, and `retakeKey` is unwired (SCREEN-3, AC-11); paint rows show name only — no brand/line/medium/pigment/badge (PALETTE-3) and legend is a placeholder (PALETTE-3); palette selection renders the active marker but has no select action (PALETTE-4); projects list shows name only — no size/counts/last-edit (PROJECT-3), open/export inert (PROJECT-4/6).
- **Next phase should:** stage 2 (component shells) is complete → the **ITEST stage** is startable: **ITEST-1** (harness over the wired shells via `buildApp` + a `PaletteEntry` + in-memory-backed store, fixtures, pending gate, smoke test), then **ITEST-2 ∥ ITEST-3**, then **ITEST-4** test review (**G-2**). All SCREEN/PALETTE/PROJECT behaviour phases remain **G-2**-blocked.

## Phase 2 — AC-1 switch views

- **Kind:** behavior · **Target AC:** AC-1 (full) · **Depends on:** SCREEN-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_screen.dart`
- **Tasks:** E31 selector toggles the screen between the My-paints view and the Projects view (one visible at a time).
- **Acceptance gate:** un-pend AC-1; `palette_test.dart` green — Projects region shown and paint-list region gone after the toggle.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->

## Phase 3 — AC-11 vision-profile card

- **Kind:** behavior · **Target AC:** AC-11 (full) · **Depends on:** SCREEN-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_screen.dart` (vision-profile card widget), `lib/app/router.dart`
- **Tasks:** the vision-profile card shows the current estimate from the injected `CvdProfile` (e.g. "deutan-type, moderate"); choosing "retake the self-assessment" navigates to the bs-07 self-assessment entry placeholder.
- **Acceptance gate:** un-pend AC-11; suite green — the estimate text is shown AND navigation to the self-assessment entry is observed.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
