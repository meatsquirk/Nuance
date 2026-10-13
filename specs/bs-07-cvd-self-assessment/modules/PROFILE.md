# Module PROFILE — persist the one CVD profile + pipeline wiring

**Status:** ✅ Done — PROFILE-1 (shell) + PROFILE-2 (AC-13, save configures the pipeline) ✅; module complete
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/store/cvd_profile_store.dart` (profile source over `PersistentStore`), `lib/onboarding/cvd_profile_read_endpoint.dart`; wiring in `lib/app/build_app.dart` (`AppDependencies.cvdProfile` loaded from the store). Reuses `lib/a11y/cvd/cvd_profile.dart` unchanged.
**Depends on:** ENGINE (estimate → profile projection) · **Blocks:** FLOW-1 (save seam), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 7,782,453 | 20m 30s |
| 2 | behavior | AC-13 | ✅ Done | 14,408,911 | 22m 50s |

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

### Result — ✅ Done (AC-13)

- **Landed:**
  - `lib/onboarding/onboarding_controller.dart` — `save()` implemented (was a throwing stub): projects the confirmed estimate onto `CvdProfile {type: estimate.type (post FLOW-6 override), severity: calibratedSeverity ?? estimate.severity (D-6)}`, writes it through `profileStore` (one doc), sets `OnboardingState.saved`, and hands the saved profile to a new optional `onProfileSaved` callback. Guards `estimate == null` (no-op before the result step), like the other result actions.
  - `lib/app/build_app.dart` — the live-pipeline seam (D-3): `buildApp` now returns a stateful `_App` root holding the live `CvdProfile`; a save calls back through the new `LiveProfileScope` (InheritedWidget above the `MaterialApp`) → `_App` re-injects the measured profile on `AppDependencies.cvdProfile` so bs-03's `ConfusionCheck` + the bs-08/bs-10 projection (the single shared seam, D-8) reconfigure immediately. Added `AppDependencies.withCvdProfile` (copy with only the profile replaced). The startup tree still injects the exact deps object until a save (bs-01..06 wiring unchanged — `identical` AppScope test green).
  - `lib/onboarding/screens/onboarding_host.dart` — wires `onProfileSaved: LiveProfileScope.of(context)` into the controller (null outside `buildApp`, e.g. bare unit tests).
  - `lib/onboarding/screens/result_step.dart` — the E43 save button is live on the assembled result (`onPressed: () => controller.save()`); the placeholder branch stays inert.
  - Tests: controller save group (no-op before estimate / one-profile projection + live callback / D-6 calibrated severity / bare no-throw), `withCvdProfile` + `LiveProfileScope` (of found/null, updateShouldNotify) + a `buildApp` live-reconfiguration widget test; a result-step save-tap test + its inert control. Acceptance: un-pended AC-13 (deleted its `pending.dart` row; scaffold-guard set shrunk to `{AC-14}`); added the **live-pipeline augmentation** assertions to `TestAC13` (before: `liveProfile == default`, confusable true; after: `liveProfile == saved`, confusable false) and a harness `liveProfile` accessor; fixed `whenSave` to `ensureVisible` the below-fold control.
- **Gate:** `flutter analyze` clean · unit **1067 passed** (+10) · coverage gate vs `main` **100% on all touched files** (incl. `build_app.dart`, `onboarding_controller.dart`, `result_step.dart`, `onboarding_host.dart`) · acceptance (sim iPhone 17) default **23 pass / 1 skip** (AC-14 still pending on G-5), run-pending **24 / 0** — AC-13 green, all 14 ACs pass. **Grade A** (discriminating before/after controls; graded vs the independent `referenceBand` + the shipped `DichromatConfusionCheck`; the live-dep augmentation closed). Grid **14 A / 0**. **Fix passes: 1/3** (harness `whenSave` missed the off-screen save button → added `ensureVisible`).
- **Augmentation closed:** TestAC13 now asserts the live `AppDependencies.cvdProfile`, not just the stored value (the Reject "leaves the pipeline on the default" is covered). Sim/dalt behavioural assertions remain the out-of-scope bs-08/bs-10 known gap (D-8).

### Checkpoint / Handoff

- **Frozen interfaces:** `OnboardingController({..., ValueChanged<CvdProfile>? onProfileSaved})` + `Future<void> save()` (projects estimate → profile, persists one doc, marks `saved`, calls `onProfileSaved`); `AppDependencies.withCvdProfile(CvdProfile)`; `LiveProfileScope({required ValueChanged<CvdProfile> onProfileSaved})` with `of(context)` (nullable); `buildApp` root is the stateful `_App` holding the live profile.
- **For SIGNOFF-1 (next):** all 14 ACs delivered **except AC-14** (FLOW-2, blocked on **G-5**); 13/14 behaviour ACs green, suite **14 A / 0**. The sign-off packet must record AC-14/FLOW-2 as the one carried-open item (G-5, four-step vs five-tier, routed to the spec author) and the sim/dalt D-8 known gap. No build phase remains besides FLOW-2.
- **Verification commands** (worktree `../Nuance-bs07`, `export PATH="$PATH:/Users/matthew.quirk/development/flutter/bin"`): `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · acceptance via `coord.sh with-lock bs-07 <PHASE> -- flutter test integration_test/self_assessment_test.dart -d <booted-udid>` (add `--dart-define=BS07_RUN_PENDING=true` for the run-pending pass).
- **Known gaps:** AC-14 not built (G-5); behavioural sim/dalt owned by bs-08/bs-10 (D-8).
