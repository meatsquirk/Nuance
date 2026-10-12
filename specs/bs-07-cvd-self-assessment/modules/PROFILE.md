# Module PROFILE — persist the one CVD profile + pipeline wiring

**Status:** In progress — PROFILE-1 (shell) ✅ Done; next PROFILE-2 (AC-13, blocked by ITEST-4/FLOW-5/ENGINE-7)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/store/cvd_profile_store.dart` (profile source over `PersistentStore`), `lib/onboarding/cvd_profile_read_endpoint.dart`; wiring in `lib/app/build_app.dart` (`AppDependencies.cvdProfile` loaded from the store). Reuses `lib/a11y/cvd/cvd_profile.dart` unchanged.
**Depends on:** ENGINE (estimate → profile projection) · **Blocks:** FLOW-1 (save seam), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 7,782,453 | 20m 30s |
| 2 | behavior | AC-13 | ⬜ Todo | | |

## Interface reconciliation

- **One stored profile.** Collection `cvd_profile`, single document id `current`, body `{type: <CvdType.name>, severity: <0..1>}` over the bs-06 `PersistentStore` (`StoredDocument = ({String id, Map<String,Object?> data})`), matching `source_photo_store.dart` (D-2).
- **The shared seam.** `AppDependencies.cvdProfile` currently is `const CvdProfile(type: CvdType.deutan)`. PROFILE-1 changes app assembly to **load** the stored profile at startup, falling back to the const default when the store has none (D-3). bs-03's `DichromatConfusionCheck` and the `projectDichromat` projection (reused by bs-08/bs-10) read this one value — so configuring it configures the pipeline.
- **Read endpoint.** `CvdProfileReadEndpoint` exposes the persisted profile and a count, so the acceptance suite can assert "exactly one profile written" and its fields without reaching into the store.
- **Save ≠ shell.** PROFILE-1 provides `put`/`get` + the read endpoint + startup load (no user-visible save). The actual save action and pipeline reconfiguration is AC-13 behaviour (PROFILE-2), triggered from the result step.

## Open gates

- **G-4** (decision) ✅ Resolved 2026-10-12 (Matt Quirk) — approved as proposed: collection `cvd_profile`/id `current`, body `{type, severity}`, `CvdProfile` reused unchanged; `severity = slider/100`; bands mild `[0,0.45)` / moderate `[0.45,0.75)` / strong `[0.75,1.0]`.

## Phase 1 — shell: profile store + read endpoint + startup wiring

- **Kind:** shell
- **Target AC:** —
- **Depends on:** ENGINE-1 · **Blocks:** FLOW-1, ITEST-1, PROFILE-2
- **Files:** `lib/store/cvd_profile_store.dart`, `lib/onboarding/cvd_profile_read_endpoint.dart`, `lib/app/build_app.dart` (startup load)
- **Tasks:**
  1. `CvdProfileStore` over `PersistentStore`: `Future<void> save(CvdProfile)` (writes `cvd_profile/current`), `Future<CvdProfile?> load()`, `Future<int> count()`; serialize/deserialize `{type, severity}`.
  2. `CvdProfileReadEndpoint` exposing the loaded profile + count for the acceptance suite.
  3. In `build_app.dart`, load the stored profile at assembly and use it for `AppDependencies.cvdProfile`, defaulting to the const when absent — **behaviour unchanged** when no profile is stored (existing suite stays green).
  4. Unit tests: round-trip save/load, absent→null, count; 100% line coverage (the generated drift `.g.dart` is exempt).
- **Exit criteria:** unit gate green; 100% coverage on touched files; existing suite green (default profile path unchanged); no save UI.

### Result — ✅ Done (shell)

- **Landed (G-4 resolved as proposed, 2026-10-12):**
  - `lib/store/cvd_profile_store.dart` — `CvdProfileStore` over `PersistentStore`: `save(CvdProfile)` / `load()→CvdProfile?` / `count()→int`, collection `cvd_profile` id `current`, body `{type: <CvdType.name>, severity: <double>}`. `CvdProfile` reused unchanged (bs-03). `load` casts severity via `num.toDouble()` (JSON round-trip may hand back an int-valued num).
  - `lib/onboarding/cvd_profile_read_endpoint.dart` — `CvdProfileReadEndpoint` InheritedWidget exposing the `CvdProfileStore` (`of`, `endpointKey`, `updateShouldNotify`), mirroring bs-06's read endpoints. Defined, not yet mounted — FLOW-1 wraps the onboarding host in it.
  - `lib/app/build_app.dart` — added top-level `loadCvdProfile(CvdProfileStore)` → saved profile or `const CvdProfile(type: CvdType.deutan)` default (D-3). `buildApp`/`AppDependencies` behaviour unchanged.
  - `lib/main.dart` (**beyond the listed files — the only place async store I/O happens**) — `productionDependencies` loads the profile via `loadCvdProfile(CvdProfileStore(store))` and threads it into `assembleDependencies`, which gained an optional `cvdProfile` param (defaulting to the deutan const). Empty store → default, so shipped behaviour is unchanged until a profile is saved.
  - `test/smoke_test.dart` extended to assert the default `cvdProfile` wiring (keeps `main.dart` at 100%).
- **Gate (shell):** `flutter analyze` clean · unit **923 passed** (+11: 6 store, 3 endpoint, 2 loadCvdProfile) · coverage gate vs `main` **100% on all 8 touched lib files** (incl. the 4 touched here) · integration suite (host, default) **134 passed** — existing cross-feature suite green. No acceptance/grade gate (shell). Fix passes: 0/3 (green on first full run).
- **No save UI** (AC-13 behaviour is PROFILE-2). `CvdProfileReadEndpoint` is not mounted yet (FLOW-1).
- **Tokens / time:** 7,782,453 · 20m 30s.

### Checkpoint / Handoff

- **Frozen interfaces:** `CvdProfileStore(PersistentStore)` with `save`/`load`/`count` + `collection`/`documentId` consts; `CvdProfileReadEndpoint({required store})` with `endpointKey` / `of` / `updateShouldNotify`; `loadCvdProfile(CvdProfileStore)` in `build_app.dart`; `assembleDependencies(..., CvdProfile cvdProfile = const CvdProfile(type: CvdType.deutan))`.
- **For FLOW-1 (next startable):** mount `CvdProfileReadEndpoint` (store = `CvdProfileStore(deps.store!)`) over the onboarding host so the acceptance suite can read the persisted profile + count; the `OnboardingController` owns assessment state. The read endpoint and store are ready to wire.
- **For PROFILE-2 (AC-13):** project the final `CvdEstimate` → `CvdProfile {type, severity}`, `save` it (exactly one doc), and update the live `AppDependencies.cvdProfile` so bs-03's `ConfusionCheck` uses it immediately.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$PATH:/Users/matthew.quirk/development/flutter/bin"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · `flutter test integration_test/` (host). `severity` persists 0..1; slider→severity normalization and the band function are ENGINE-7/FLOW-7 (G-4 bands: mild `[0,0.45)` / moderate `[0.45,0.75)` / strong `[0.75,1.0]`).
- **Known gaps:** endpoint unmounted until FLOW-1; no save path until PROFILE-2.

## Phase 2 — AC-13: saving the profile configures the pipeline

- **Kind:** behavior · **Target AC:** AC-13 (full)
- **Depends on:** ITEST-4 (G-2), PROFILE-1, FLOW-5 (estimate at the result step), ENGINE-7 (band → "moderate") · **Blocks:** SIGNOFF-1
- **Files:** `lib/store/cvd_profile_store.dart` (if needed), `onboarding_controller.dart` save action + live-dependency update, `build_app.dart` (propagate the saved profile to the live `cvdProfile`/`confusionCheck`)
- **Tasks:**
  1. Project the final `CvdEstimate` onto `CvdProfile {type, severity}` and persist it via `CvdProfileStore` (exactly one document).
  2. Update the live `AppDependencies.cvdProfile` so bs-03's `ConfusionCheck` uses the saved profile immediately.
  3. Assert the shared seam (D-8): `fixedPair`'s confusability changes from the default to the saved profile. Sim/daltonization behaviour is a known gap (bs-08/bs-10).
- **Exit criteria + Acceptance gate:** un-pend AC-13; suite green (`TestAC13_*` + all earlier ACs); coverage 100% touched; grade A (writes exactly one profile; pipeline moves off the default — control: before save).
- **Augments:** confirm AC-13's confusion-check assertion discriminates (it would pass against the pre-save default only by accident — control proves it). No other AC's test touched (G6).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
