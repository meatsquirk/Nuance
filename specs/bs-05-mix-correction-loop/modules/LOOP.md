# Module LOOP — correction loop controller + wiring

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/correction/correction_controller.dart`, `lib/correction/correction_state.dart`, `lib/correction/correction_read_endpoint.dart`, `lib/correction/correction_speech.dart`, the `CorrectionEntry`/`CorrectionHomeScreen` branch in `lib/app/build_app.dart`, `AppRouter.toCorrection` in `lib/app/router.dart`, the provenance promotion (via `Sample.copyWith` + `EvidencePoint`; the confirmed-tier label per G-4(d))
**Depends on:** bs-02 capture (`CaptureController`/`CaptureSource`), bs-03 `deltaE00`/`SampleSource`, domain `Provenance`/`Sample`/`EvidencePoint`, `Speech`, CORRECT (engine) · **Blocks:** SCREEN-1, SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-1 (*enabler*) | ⬜ Todo | | |
| 4 | behavior | AC-7 | ⬜ Todo | | |
| 5 | behavior | AC-8 | ⬜ Todo | | |
| 6 | behavior | AC-9, AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **`CorrectionController extends ChangeNotifier`**, ctor `{required CaptureSource captureSource, required Sample target, required Recipe currentMix, required PaletteSource paletteSource, required CorrectionEngine correctionEngine, MixingEngine mixingEngine = const SubtractiveMixingEngine(), SampleSource sampleSource = const InMemorySampleSource(), Speech speech = const NoopSpeech(), AppRouter router = const AppRouter()}`. Actions: `checkMix()` (photograph + compare), `rephotograph()` (re-check), `speakCorrection()`, `saveConfirmed()`.
- **`CorrectionState`** fields: `target` (Sample), `currentMix` (Recipe), `mixedSwatch` (Sample?), `difference` (Difference?), `correction` (Correction?), `savedProvenance` (Provenance?), plus `bool get hasChecked => mixedSwatch != null`. Promotion writes a confirmed `Sample` back to `sampleSource` (or exposes it for the readout).
- **`CorrectionReadEndpoint extends InheritedWidget`** with `static const Key endpointKey = Key('correction-read-endpoint')` and `static CorrectionController of(context)` — mirrors `RecipeReadEndpoint`.
- **`CorrectionEntry{const CorrectionEntry({required Sample target, required Recipe currentMix});}`** + `AppDependencies.correctionEntry` + the `buildApp` `home:` branch + `CorrectionHomeScreen` (owns the controller, wraps the endpoint) — symmetric to `RecipesEntry`/`RecipesHomeScreen`.
- **`AppRouter.toCorrection(Sample target, Recipe currentMix)`** — new route following `toRecipes`.
- **Capture reuse (D-2):** `checkMix()` drives the `CaptureSource` to a measured `Sample` (the `CaptureController.importPhoto`/`commit` seam gives `Provenance(measured)`), then `correctionEngine.difference(...)`/`correct(...)`.
- **Provenance promotion (D-8/G-4(d)):** `saveConfirmed()` → `target.copyWith(provenance: Provenance(ProvenanceTier.confirmed, note: '<confirmed after you photographed your own swatch>'), evidence: [...target.evidence, EvidencePoint(coordinates: mixedSwatch.coordinates, source: 'own swatch')])`, persisted to `sampleSource`. The label "Confirmed — you measured this" is G-4(d) (shared `Provenance.label` change vs note).

## Open gates

- **G-4(d)** (blocks LOOP-6): the confirmed-tier label string / shared-label change. See the master plan.

## Phase 1 — Scaffold (LOOP-1)

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (gated by **G-1** spec approval + **G-3** bs-04 merged to `main`) · **Blocks:** CORRECT-1
- **Files:** branch only + `integration_test/bs05/pending.dart`
- **Tasks:**
  1. Branch `feat/bs-05-mix-correction-loop` from `main` @ the bs-04 merge; record `BASE`.
  2. Baseline: `flutter analyze`; `flutter test` (unit) + the four existing integration suites green; record counts.
  3. Confirm the coverage gate (`tool/coverage_gate.dart`) passes clean and FAILs on a planted gap.
  4. Seed `integration_test/bs05/pending.dart` (flag `BS05_RUN_PENDING`, `pendingACs` = all 10, `behaviorPhases` = the behaviour phase ids), mirroring `bs04/pending.dart`. **No product code.**
- **Exit criteria:** tooling proven both ways; baseline recorded; no `lib/` change.

## Phase 2 — Controller + state + endpoint + entry/route (LOOP-2)

- **Kind:** shell
- **Target AC:** — (adds the read endpoint the acceptance tests observe)
- **Depends on:** CORRECT-1 · **Blocks:** SCREEN-1
- **Files:** `correction_controller.dart` (inert), `correction_state.dart`, `correction_read_endpoint.dart`, `build_app.dart` (`CorrectionEntry`/`CorrectionHomeScreen` branch), `router.dart` (`toCorrection`)
- **Tasks:**
  1. `CorrectionState` + an inert `CorrectionController` (actions present, no behaviour) over the ctor seams above.
  2. `CorrectionReadEndpoint` with `endpointKey`/`of`.
  3. `CorrectionEntry` + `AppDependencies.correctionEntry` + the `buildApp` branch + `CorrectionHomeScreen` wrapping the endpoint; `AppRouter.toCorrection`.
  4. 100% coverage on touched files; the existing suite (incl. bs-04 handoff tests) stays green.
- **Exit criteria:** `flutter analyze` clean; unit + coverage gate pass; behavior unchanged.

## Phase 3 — Check photographs + compares (LOOP-3, enabler)

- **Kind:** behavior
- **Target AC:** AC-1 (full) — **enabler** for every other behaviour phase's Given (a checked mix)
- **Depends on:** LOOP-2, CORRECT-1 (types), G-2 · **Blocks:** CORRECT-2, LOOP-4, LOOP-5, LOOP-6
- **Files:** `correction_controller.dart` (`checkMix()`), SCREEN-1's `CheckRegion` (E26)
- **Tasks:**
  1. `checkMix()` drives the `CaptureSource`/`CaptureController` to a measured `Sample`, stores it as `state.mixedSwatch`, and computes `state.difference = correctionEngine.difference(mixedSwatch, target)` (ΔE00 only is enough for AC-1; the verdict/decomposition detail is CORRECT-2).
  2. Wire E26 "Check my mix" to `checkMix()`.
  3. Unit-test the capture → compare wiring with a configured fake source.
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-1; `TestAC01_CheckPhotographsAndCompares` green under run-pending.

## Phase 4 — Speak the correction (LOOP-4)

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** CORRECT-3 (a computed correction) · **Blocks:** SIGNOFF-1
- **Files:** `correction_speech.dart` (`correctionSpeech(CorrectionState)`), `correction_controller.dart` (`speakCorrection()` — small, coordinate with LOOP-5/6), SCREEN-1's `SpeakRegion` (E27)
- **Tasks:**
  1. `correctionSpeech` builder = the difference (verdict + value/hue) + the paints to add; mirror `recipeSpeech`/`comparisonSpeech`.
  2. `speakCorrection()` calls `speech.speak(correctionSpeech(state))` exactly once; wire E27.
  3. Unit-test the utterance contents.
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-7; `TestAC07_SpeakCorrection` green (exactly one utterance stating the difference + paints).

## Phase 5 — Re-photograph re-checks (LOOP-5)

- **Kind:** behavior
- **Target AC:** AC-8 (full)
- **Depends on:** LOOP-3 · **Blocks:** SIGNOFF-1 (serial with LOOP-6 — both edit the controller)
- **Files:** `correction_controller.dart` (`rephotograph()`), SCREEN-1's `RephotographRegion` (E28)
- **Tasks:**
  1. `rephotograph()` re-drives capture to a new measured swatch and recomputes `difference`/`correction`, replacing the prior state; wire E28.
  2. Unit-test that a new scene yields an updated difference/verdict.
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-8; `TestAC08_RephotographRechecks` green (the difference/verdict update across two scenes).

## Phase 6 — Save confirmed → promote provenance; later readout (LOOP-6)

- **Kind:** behavior
- **Target AC:** AC-9 (full), AC-10 (full)
- **Depends on:** LOOP-3, G-4(d) · **Blocks:** SIGNOFF-1 (serial with LOOP-5)
- **Files:** `correction_controller.dart` (`saveConfirmed()`), the provenance promotion (domain `Provenance` label per G-4(d)), SCREEN-1's `SaveRegion` (E29), `ProvenanceBadge` reuse for the readout
- **Tasks:**
  1. `saveConfirmed()` promotes the target to `ProvenanceTier.confirmed`, label "Confirmed — you measured this", a note recording it was confirmed after the painter's own swatch photo, appending the measured swatch as an `EvidencePoint`; persist to `sampleSource` (D-8).
  2. **Honest-provenance guard:** refuse promotion without a measured swatch (`state.mixedSwatch` present) — never graduate on anything but the painter's own photographic evidence.
  3. The later readout (`router.toReadout(confirmedSample)`) shows the confirmed provenance via `ProvenanceBadge`; wire E29.
  4. Unit-test the promotion (tier, label, note, evidence appended) and the guard (no swatch → no promotion).
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-9, AC-10; `TestAC09_SaveConfirmed`, `TestAC10_ConfirmedInReadout` green; full suite (all 10 ACs) green.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
