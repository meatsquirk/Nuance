# Module PROFILE — persist the one CVD profile + pipeline wiring

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/store/cvd_profile_store.dart` (profile source over `PersistentStore`), `lib/onboarding/cvd_profile_read_endpoint.dart`; wiring in `lib/app/build_app.dart` (`AppDependencies.cvdProfile` loaded from the store). Reuses `lib/a11y/cvd/cvd_profile.dart` unchanged.
**Depends on:** ENGINE (estimate → profile projection) · **Blocks:** FLOW-1 (save seam), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-13 | ⬜ Todo | | |

## Interface reconciliation

- **One stored profile.** Collection `cvd_profile`, single document id `current`, body `{type: <CvdType.name>, severity: <0..1>}` over the bs-06 `PersistentStore` (`StoredDocument = ({String id, Map<String,Object?> data})`), matching `source_photo_store.dart` (D-2).
- **The shared seam.** `AppDependencies.cvdProfile` currently is `const CvdProfile(type: CvdType.deutan)`. PROFILE-1 changes app assembly to **load** the stored profile at startup, falling back to the const default when the store has none (D-3). bs-03's `DichromatConfusionCheck` and the `projectDichromat` projection (reused by bs-08/bs-10) read this one value — so configuring it configures the pipeline.
- **Read endpoint.** `CvdProfileReadEndpoint` exposes the persisted profile and a count, so the acceptance suite can assert "exactly one profile written" and its fields without reaching into the store.
- **Save ≠ shell.** PROFILE-1 provides `put`/`get` + the read endpoint + startup load (no user-visible save). The actual save action and pipeline reconfiguration is AC-13 behaviour (PROFILE-2), triggered from the result step.

## Open gates

- **G-4** (decision) blocks **PROFILE-1**: confirm collection/id/body shape and that `CvdProfile` is reused unchanged.

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
