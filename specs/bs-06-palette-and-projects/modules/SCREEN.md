# Module SCREEN — Palette screen

**Status:** In progress — SCREEN-1 ✅ done (shell); SCREEN-2 (AC-1) / SCREEN-3 (AC-11) startable once G-2 resolves
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/palette/palette_screen.dart` + its region widgets, `lib/app/build_app.dart` (PaletteScreen entry marker + home selection), `lib/app/router.dart` (route to bs-07 entry placeholder)
**Depends on:** PALETTE (controller + read endpoint), PROJECT (controller + read endpoint), bs-03/07 `CvdProfile` · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 12,251,452 | 17m 44s |
| 2 | behavior | AC-1 | ✅ Done | 5,271,492 | 30m 22s |
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

### Result

- **Landed (AC-1):** `PaletteScreen` is now a `StatefulWidget` (the toggle needs mutable UI state that survives controller `notifyListeners` rebuilds — a `StatelessWidget` + `StatefulBuilder` cannot persist it across the enclosing `ListenableBuilder`). A private `_PaletteView { myPaints, projects }` holds which E31 view is shown (My paints to begin with); the two E31 `TextButton`s are now wired (`onPressed` → `setState`). The screen shows **one view at a time**: the My-paints view (`PaintListRegion` + `ProvenanceLegendRegion` + `PaletteSelectorRegion`) *or* the Projects view (`ProjectsRegion`), via a `if (showMyPaints) [...] else ProjectsRegion`, so the hidden view's regions leave the tree (`findsNothing`). `VisionProfileCard` (E30) and the E31 selector stay always-visible. **Scope kept tight for the SCREEN-3 merge:** the `const VisionProfileCard()` line, imports, router and region internals are untouched; only the class kind, the selector `onPressed`, and the region layout changed.
- **AC un-pended:** AC-1 removed from `integration_test/bs06/pending.dart`. Suite edits forced by the toggle (recorded per the "record any other change to a test" rule; none weaken an AC test): the never-pending **smoke test** in `palette_test.dart` asserted "both views' regions present at once" — a SCREEN-1 *shell* invariant AC-1 directly supersedes (`findsNothing` vs `findsOneWidget` at the same state) — so it now asserts the My-paints view initially + reaches `ProjectsRegion` by switching; the two scaffold-guard tests that hard-coded `'AC-1'` (the pending-set and `pendingSkipReason` guards) were repointed to a still-pending AC (`'AC-2'`) and the un-pended-so-far comment updated. `test/palette/palette_screen_test.dart` widget tests updated for the toggle (regions reached per view) + a new `AC-1: the E31 selector toggles …` unit test.
- **Verification:** `flutter analyze` clean. `flutter test --coverage` → **695 passing** (was 688). Coverage gate vs `main`: **100%** on all 24 touched `lib/` files (incl. `lib/palette/palette_screen.dart`). Acceptance `flutter test integration_test/palette_test.dart -d <iPhone 17 sim>` (under the global lock): **14 passing, 9 pending, 0 failing** — AC-1 un-pended + green, AC-4 still green; the 9 remaining ACs (2,3,5,6,7,8,9,10,11) correctly skipped as pending.
- **Grade gate:** AC-1 — **A**; AC-4 (re-graded for regression) — **A (with caveat)**, confirmed not regressed by the toggle (AC-4 runs in the default My-paints view). **Counts: 2×A, 0×B pending — PASS** (no unsanctioned B, no downgrade). Independent fresh-subagent grade; grid: `behavior-test-completeness-bs-06-palette-and-projects.md`, § *Phase graded: SCREEN-2*.
- **Augmentations:** none owed by AC-1 (the both-ways control is in the test already); no already-green neighbour (AC-4) can assert more from the toggle.
- **Fix passes:** 1/3 — pass 1: the acceptance `pendingSkipReason` scaffold guard used `'AC-1'` as its example pending AC, which SCREEN-2 un-pends → repointed to `'AC-2'`. Unit gates were clean on the first run; the implementation was correct from the first run.
- **Justified exclusions:** none — 100% on touched files.
- Tokens: see master ledger (SCREEN-2 row). **Phase total: 5,271,492, 30m 22s active.**

### Checkpoint / Handoff

- **Frozen interfaces:** `PaletteScreen` is now a `StatefulWidget` with the **same public constructor** (`{required paletteController, required projectController}`) and the **same `static const viewSelectorKey`** — no API change for callers or the harness. The E31 selector toggles `_PaletteView` (private); the My-paints view = `PaintListRegion` + `ProvenanceLegendRegion` + `PaletteSelectorRegion`, the Projects view = `ProjectsRegion`, shown **instead of** each other (the hidden view's regions are not in the tree). `VisionProfileCard` (E30) and the E31 Row are always mounted.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`. Acceptance: `flutter test integration_test/palette_test.dart -d <booted-udid>` via `coord.sh with-lock` (global sim lock). Flutter SDK `/Users/matthew.quirk/development/flutter/bin`.
- **Known gaps / deferred:** `VisionProfileCard` still a placeholder (no `CvdProfile` estimate) and `retakeKey` unwired — **SCREEN-3** (AC-11). ⚠️ **Projects-view reachability for PROJECT phases:** `ProjectsRegion` (and its `openProjectKey`/`exportKey`) is now **absent in the default My-paints view**; the harness `whenOpenProject`/`whenExportProject` tap `ProjectsRegion` keys **without first switching to the Projects view**, so AC-7/8/9/10 (PROJECT-4/5/6) must switch to Projects first (e.g. call `whenSwitchToProjects()` in those drivers/tests, or have `whenOpenProject` switch) or they will not find the control at their un-pend run. AC-6 (PROJECT-3) already calls `whenSwitchToProjects()`.
- **⚠️ Merge with SCREEN-3:** SCREEN-3 also edits `lib/palette/palette_screen.dart` (VisionProfileCard estimate + router wiring) and `test/palette/palette_screen_test.dart`. SCREEN-2 changed `PaletteScreen` `StatelessWidget`→`StatefulWidget` (build body moved into `_PaletteScreenState`, `paletteController`→`widget.paletteController`); the `const VisionProfileCard()` line is left unchanged to ease SCREEN-3's edit. Expect a 3-way conflict at the class/State declaration — resolve by keeping the StatefulWidget shell and folding SCREEN-3's `VisionProfileCard(...)` + router callback onto the moved build method.
- **Next phase:** SCREEN-3 (AC-11) is the only remaining SCREEN phase; it and the PALETTE/PROJECT chains run per the master graph. SIGNOFF-1 last.

## Phase 3 — AC-11 vision-profile card

- **Kind:** behavior · **Target AC:** AC-11 (full) · **Depends on:** SCREEN-1, ITEST-4 (G-2) · **Blocks:** —
- **Files:** `lib/palette/palette_screen.dart` (vision-profile card widget), `lib/app/router.dart`
- **Tasks:** the vision-profile card shows the current estimate from the injected `CvdProfile` (e.g. "deutan-type, moderate"); choosing "retake the self-assessment" navigates to the bs-07 self-assessment entry placeholder.
- **Acceptance gate:** un-pend AC-11; suite green — the estimate text is shown AND navigation to the self-assessment entry is observed.

### Result  <!-- filled on completion -->
### Checkpoint / Handoff  <!-- filled on completion -->
