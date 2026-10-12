# Module LOOP — correction loop controller + wiring

**Status:** ✅ Complete — LOOP-1..LOOP-6 all done; AC-1/AC-7/AC-8/AC-9/AC-10 un-pended + green (the full behaviour stage, all 10 ACs, is complete); feature SIGNOFF-1 approved 2026-10-11 by Matt Quirk at `83554a9` — feature Done
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/correction/correction_controller.dart`, `lib/correction/correction_state.dart`, `lib/correction/correction_read_endpoint.dart`, `lib/correction/correction_speech.dart`, the `CorrectionEntry`/`CorrectionHomeScreen` branch in `lib/app/build_app.dart`, `AppRouter.toCorrection` in `lib/app/router.dart`, the provenance promotion (via `Sample.copyWith` + `EvidencePoint`; the confirmed-tier label per G-4(d))
**Depends on:** bs-02 capture (`CaptureController`/`CaptureSource`), bs-03 `deltaE00`/`SampleSource`, domain `Provenance`/`Sample`/`EvidencePoint`, `Speech`, CORRECT (engine) · **Blocks:** SCREEN-1, SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 2,465,803 | 11m 57s |
| 2 | shell | — | ✅ Done | 11,995,702 | 19m 40s (52m 25s) |
| 3 | behavior | AC-1 (*enabler*) | ✅ Done | 15,659,660 | 29m 27s |
| 4 | behavior | AC-7 | ✅ Done | 18,028,310 | 1h 02m |
| 5 | behavior | AC-8 | ✅ Done | 7,036,729 | 28m 15s |
| 6 | behavior | AC-9, AC-10 | ✅ Done | 22,315,250 | 1h 30m |

## Interface reconciliation

- **`CorrectionController extends ChangeNotifier`**, ctor `{required CaptureSource captureSource, required Sample target, required Recipe currentMix, required PaletteSource paletteSource, required CorrectionEngine correctionEngine, MixingEngine mixingEngine = const SubtractiveMixingEngine(), SampleSource sampleSource = const InMemorySampleSource(), Speech speech = const NoopSpeech(), AppRouter router = const AppRouter()}`. Actions: `checkMix()` (photograph + compare), `rephotograph()` (re-check), `speakCorrection()`, `saveConfirmed()`.
- **`CorrectionState`** fields: `target` (Sample), `currentMix` (Recipe), `mixedSwatch` (Sample?), `difference` (Difference?), `correction` (Correction?), `savedProvenance` (Provenance?), plus `bool get hasChecked => mixedSwatch != null`. Promotion writes a confirmed `Sample` back to `sampleSource` (or exposes it for the readout).
- **`CorrectionReadEndpoint extends InheritedWidget`** with `static const Key endpointKey = Key('correction-read-endpoint')` and `static CorrectionController of(context)` — mirrors `RecipeReadEndpoint`.
- **`CorrectionEntry{const CorrectionEntry({required Sample target, required Recipe currentMix});}`** + `AppDependencies.correctionEntry` + the `buildApp` `home:` branch + `CorrectionHomeScreen` (owns the controller, wraps the endpoint) — symmetric to `RecipesEntry`/`RecipesHomeScreen`.
- **`AppRouter.toCorrection(Sample target, Recipe currentMix)`** — new route following `toRecipes`.
- **Capture reuse (D-2):** `checkMix()` drives the `CaptureSource` to a measured `Sample` (the `CaptureController.importPhoto`/`commit` seam gives `Provenance(measured)`), then `correctionEngine.difference(...)`/`correct(...)`.
- **Provenance promotion (D-8/G-4(d)):** `saveConfirmed()` → `target.copyWith(provenance: Provenance(ProvenanceTier.confirmed, note: '<confirmed after you photographed your own swatch>'), evidence: [...target.evidence, EvidencePoint(coordinates: mixedSwatch.coordinates, source: 'own swatch')])`, persisted to `sampleSource`. The label "Confirmed — you measured this" is G-4(d) (shared `Provenance.label` change vs note).

## Open gates

- **G-4(d)** ✅ Resolved 2026-10-10 17:35 EDT — Matt Quirk: keep the shared `Provenance.label` for `confirmed` = "Confirmed" (unchanged for bs-04); LOOP-6 sets the confirmed `Provenance.note` to carry **"Confirmed — you measured this"**, rendered by the readout's provenance region (label + note). No shared-label change. LOOP-6 unblocked. See the master plan.

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

### Result — LOOP-1

Scaffold complete; no product code (`lib/**`) touched — only `integration_test/bs05/pending.dart` added.

- **Branch / worktree:** `feat/bs-05-mix-correction-loop` in worktree `/Users/matthew.quirk/Nuance-bs05`,
  based at `main` **@ `2684ac6`** (the bs-04 merge; G-3). `BASE = 3390b27` (the branch tip = `main` tip: the
  bs-05 `PLAN`/`G-1`/`G-3` commits are plan-only — `git diff 2684ac6 3390b27 -- lib` empty — so the `lib` base
  is identical to the bs-04 merge). No product code committed this phase.
- **Baseline (Flutter 3.47.6 stable, iPhone 17 sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`):** `flutter analyze`
  clean; unit **579 green** (`flutter test --coverage`); integration **86 green**
  (`flutter test integration_test/ -d <sim>` — bs-01 readout/harness + bs-02 capture + bs-03 comparison +
  bs-04 recipes, under the verify lock). All existing suites green.
- **Coverage gate proven both ways:** `dart run tool/coverage_gate.dart main` — PASS clean ("no touched
  lib/**.dart files", exit 0); FAIL (exit 1) on a planted untracked `lib/_gate_probe.dart` ("NO COVERAGE
  DATA"); probe removed, tree clean.
- **BS05 pending runner:** `integration_test/bs05/pending.dart` added (mirror of `bs04/pending.dart`), keyed
  `BS05_RUN_PENDING`. Unlike bs-04 (empty at scaffold), per this phase's plan `pendingACs` is **seeded with all
  10 ACs** mapped to the phase that un-pends each: AC-1→LOOP-3; AC-2,3→CORRECT-2; AC-4,5→CORRECT-3;
  AC-6→CORRECT-4; AC-7→LOOP-4; AC-8→LOOP-5; AC-9,10→LOOP-6. `behaviorPhases` = {LOOP-3, LOOP-4, LOOP-5, LOOP-6,
  CORRECT-2, CORRECT-3, CORRECT-4}. `flutter analyze` clean with it present.
- **Coverage gate for this phase:** no `lib` touched ⇒ nothing to gate, PASS. **Fix passes: 0/3** (passed first run).
- **Tokens / Time:** 2,465,803 · 11m 57s.

### Checkpoint / Handoff — LOOP-1

- **Frozen for shells:** the pending-gate API in `integration_test/bs05/pending.dart` — `pendingACs`,
  `behaviorPhases`, `runPending`, `pendingSkipReason(acId, {forceRunPending})`,
  `acTestWidgets(acId, description, body)`. Un-pend flag `BS05_RUN_PENDING`. The bs-05 integration test file
  will be `integration_test/correction_test.dart` (ITEST-1/2/3), harness `integration_test/correction_harness.dart`.
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration on the
  iOS sim under the verify lock:
  `$C with-lock bs-05-mix-correction-loop <PHASE> --wait 900 -- bash -c "export PATH=…; cd /Users/matthew.quirk/Nuance-bs05 && flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
  Run-pending (on-device): `flutter test integration_test/correction_test.dart -d <sim> --dart-define=BS05_RUN_PENDING=true`.
- **Next phase:** CORRECT-1 (shell) — `CorrectionEngine` interface + `Difference`/`Correction` types + stub
  engine wired into `AppDependencies`. LOOP-2 follows CORRECT-1 (needs its types); SCREEN-1 follows LOOP-2.
- **Known gaps / notes:** no product code yet. Carry-over flake (master plan *Known flakes*): a `const`
  constructor line can intermittently read uncovered on `flutter test --coverage` — re-run once if the gate
  flags an untouched file. Always pass `-d <booted-udid>` to the integration suite (no device ⇒ zero tests,
  false green). Untracked bs-06..bs-14 specs + `docs/` sit in the tree from a prior branch; not part of bs-05
  and not committed by this phase.

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
- **Files:** `correction_controller.dart` (`saveConfirmed()`), the provenance promotion (set the confirmed `Provenance.note` = "Confirmed — you measured this" per G-4(d) — **do not** change the shared `Provenance.label`), SCREEN-1's `SaveRegion` (E29), and the readout's provenance region extended to render the confirmed note (label + note)
- **Tasks:**
  1. `saveConfirmed()` promotes the target to `ProvenanceTier.confirmed`, label "Confirmed — you measured this", a note recording it was confirmed after the painter's own swatch photo, appending the measured swatch as an `EvidencePoint`; persist to `sampleSource` (D-8).
  2. **Honest-provenance guard:** refuse promotion without a measured swatch (`state.mixedSwatch` present) — never graduate on anything but the painter's own photographic evidence.
  3. The later readout (`router.toReadout(confirmedSample)`) shows the confirmed provenance via `ProvenanceBadge`; wire E29.
  4. Unit-test the promotion (tier, label, note, evidence appended) and the guard (no swatch → no promotion).
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-9, AC-10; `TestAC09_SaveConfirmed`, `TestAC10_ConfirmedInReadout` green; full suite (all 10 ACs) green.

### Result — LOOP-2

Inert shell complete: the correction controller, its state and read endpoint, and the `CorrectionEntry` /
`CorrectionHomeScreen` / `toCorrection` wiring — no behaviour yet (every action throws until its phase).

- **Landed (`lib/`):** `correction_state.dart` (`CorrectionState`: `target`, `currentMix`, `mixedSwatch?`,
  `difference?`, `correction?`, `savedProvenance?`, `hasChecked`, value-equal); `correction_controller.dart`
  (`CorrectionController extends ChangeNotifier` over the frozen CORRECT-1 seams; the four actions `checkMix` /
  `rephotograph` / `speakCorrection` / `saveConfirmed` throw `UnimplementedError` naming their phase, mirroring
  the RECIPE-2 shell); `correction_read_endpoint.dart` (`CorrectionReadEndpoint` + `endpointKey` + `of`).
  `build_app.dart` gains `CorrectionEntry{target, currentMix}`, `AppDependencies.correctionEntry`, the
  `CorrectionHomeScreen` (owns the controller, wraps the endpoint, placeholder "Correction" body until SCREEN-1)
  and the `home:` branch; `router.dart` gains `toCorrection(target, currentMix)`.
- **Design note (recorded):** the correction loop *reuses* `AppDependencies.captureSource` as its camera (D-2),
  but that field also selects bs-02's Capture screen — so the `correctionEntry` branch is checked **before**
  `captureSource` in `buildApp`, and the harness injects both a correction entry and a (fake) capture source.
  `captureSource` is the one `CorrectionHomeScreen` seam without a const default (a camera is scene-specific),
  so it is `required`; `toCorrection` reads it from the enclosing `AppScope` (as `toReadout` reads its services).
- **Gate:** `flutter analyze` clean; unit **623 green** (`flutter test --coverage`, +25 new: state 6, controller
  7, endpoint 3, build_app 7 incl. the correction-wins-over-capture branch, router 1, plus the CorrectionEntry
  ctor); coverage gate **100% on all 7 touched `lib/` files** (`dart run tool/coverage_gate.dart main` — the 7
  include CORRECT-1's engine files, absent from `main`, still fully covered). Existing suite stayed green:
  **integration 86 green** on the iPhone 17 sim under the verify lock (shared `build_app.dart` / `router.dart`
  changed, so the bs-01–04 suites were re-run). **Fix passes: 0/3** (passed first run).
- **Augmentations:** none (shell adds no AC coverage; no acceptance test touched). **Tokens / Time:**
  11,995,702 · 19m 40s (52m 25s).

### Checkpoint / Handoff — LOOP-2

- **Frozen for the next phases (SCREEN-1 then the behaviour phases):**
  - `CorrectionController({required CaptureSource captureSource, required Sample target, required Recipe
    currentMix, required PaletteSource paletteSource, required CorrectionEngine correctionEngine, MixingEngine
    mixingEngine = const SubtractiveMixingEngine(), SampleSource sampleSource = const InMemorySampleSource(),
    Speech speech = const NoopSpeech(), AppRouter router = const AppRouter()})`. Read getters: `state`,
    `savedSamples`. Actions throw until: `checkMix`→LOOP-3, `rephotograph`→LOOP-5, `speakCorrection`→LOOP-4,
    `saveConfirmed`→LOOP-6. The first real mutation adds the `_emit`/notify path (RECIPE pattern).
  - `CorrectionState({required target, required currentMix, mixedSwatch, difference, correction,
    savedProvenance})` + `hasChecked`.
  - `CorrectionReadEndpoint.endpointKey = Key('correction-read-endpoint')`, `CorrectionReadEndpoint.of(context)`.
  - `CorrectionHomeScreen` (in `build_app.dart`): ctor takes the seams (captureSource required); it is where the
    SCREEN-1 Correction screen replaces the placeholder body. `CorrectionEntry{target, currentMix}` +
    `AppRouter.toCorrection(target, currentMix)`.
- **Verification commands:** unchanged from LOOP-1 (export PATH; `flutter analyze`; `flutter test --coverage`;
  `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`).
- **Next phase:** SCREEN-1 (shell) — the Correction screen scaffold (E26–E29 + difference/correction/provenance
  regions) bound to the controller, replacing `CorrectionHomeScreen`'s placeholder body. SCREEN-1 closes the
  shell stage; ITEST-1/2/3 (acceptance) and the ITEST-4 test review (G-2) follow.
- **Known gaps / notes:** no behaviour yet (actions inert). The `const`-constructor coverage flake from LOOP-1
  still applies — re-run `flutter test --coverage` once if the gate flags an untouched file. Always pass
  `-d <booted-udid>` to the integration suite.

### Result — LOOP-3

The check is live (AC-1): `CorrectionController.checkMix` photographs the mixed swatch and reads its
difference from the target, and E26 "Check my mix" is wired to it.

- **Landed (`lib/`):** `correction_controller.dart` — `checkMix()` drives the injected `captureSource` through
  a fresh bs-02 `CaptureController` (its finite feed drained via a zero-delay timer, then `commit()`), stores
  the committed **measured** `Sample` as `state.mixedSwatch`, and sets `state.difference =
  correctionEngine.difference(swatch, target)`; a frameless feed leaves the state untouched. Added the private
  `_emit(next)` mutation/notify seam (bs-04 `RecipeController` pattern) and dropped the shell's
  `prefer_final_fields` ignore. `engine/correction_engine_impl.dart` — `SubtractiveCorrectionEngine.difference`
  now returns the **real** ΔE00 via bs-03's shipped `deltaE00(…coordinates)` (verdict / value / hue readings
  and the within-tolerance flag stay inert for CORRECT-2 / CORRECT-4). `regions/check_region.dart` — E26 button
  enabled, `onPressed: () => controller.checkMix()`.
- **Scope note (engine touch):** the LOOP-3 plan lists only the controller + CheckRegion, but AC-1's
  `TestAC01` reads `state.difference.deltaE00` as the real swatch→target distance, and the design requires the
  controller to read it *through* the engine (D-2, "never computes that math itself"). So LOOP-3 fills the
  engine's ΔE00 line ("ΔE00 only is enough for AC-1" in the phase plan); CORRECT-2 (serial, next on the engine)
  completes `difference()` with the verdict + value-leading decomposition. No file-ownership clash (serial).
- **Gate:** `flutter analyze` clean; unit **633 green** (`flutter test --coverage`, +1 net: controller +2
  checkMix tests, engine impl test updated to the real-ΔE00 assertion, screen test now taps the enabled
  control); coverage gate **100% on all touched files** (`dart run tool/coverage_gate.dart main` — reports the
  14 correction files the branch adds vs `main`; this phase changed `correction_controller.dart`,
  `engine/correction_engine_impl.dart`, `regions/check_region.dart`). **Acceptance (iPhone 17 sim under the
  verify lock):** AC-1 un-pended in `bs05/pending.dart`; `TestAC01_CheckPhotographsAndCompares` green —
  run-pending **13 pass / 9 fail** (was 12/10; AC-1 flipped green, AC-2…AC-10 still fail cleanly), default
  **99 pass / 9 skip** (was 98/10; no regression across bs-01…bs-04). **Grade:** AC-1 retains its ITEST-2 **A**
  (test body unchanged — only the pending row + the `unpended` guard set moved); no augmentation assigned to
  LOOP-3. **Fix passes: 1/3** (first `--coverage` run flagged the two SCREEN-1 shell tests asserting the check
  control *disabled* and one uncovered closure line in `check_region.dart`; fixed by enabling the control in
  those tests and tapping it — no product change).
- **Tokens / Time:** 15,659,660 · 29m 27s.

### Checkpoint / Handoff — LOOP-3

- **Frozen for the next phases:**
  - `CorrectionController.checkMix()` now sets `state.mixedSwatch` (measured) + `state.difference` and notifies
    through `_emit`. It reads the difference **only**; `state.correction` stays null after a check.
  - `SubtractiveCorrectionEngine.difference()` returns the real ΔE00 with empty verdict/value/hue and
    `withinTolerance: false`.
- **⚠ Carry-forward for CORRECT-3 (and before LOOP-4):** a check must also populate `state.correction` for
  `TestAC04`/`TestAC05` (CORRECT-3) and `TestAC07`'s Given (LOOP-4, which reads `state.correction` non-empty).
  LOOP-3 deliberately did not — CORRECT-3 owns `correct()` and must **extend `checkMix` to also call
  `correctionEngine.correct(mixedSwatch, target, currentMix, palette)` and store the result** (the palette
  comes from `paletteSource`). This is a controller edit landing in CORRECT-3; LOOP-4's Given depends on it.
- **Verification commands:** unchanged (export PATH; `flutter analyze`; `flutter test --coverage`;
  `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; bs-05 run-pending via
  `flutter test integration_test/correction_test.dart -d <sim> --dart-define=BS05_RUN_PENDING=true`).
- **Next phases:** CORRECT-2 (AC-2/AC-3, next on the engine) ∥ LOOP-5 (AC-8) ∥ LOOP-6 (AC-9/AC-10) — LOOP-5 and
  LOOP-6 both depend on LOOP-3 only and are serial with each other (both edit the controller). LOOP-4 (AC-7)
  waits on CORRECT-3. In-feed draining idiom reused from LOOP-3's `checkMix` for LOOP-5's `rephotograph`.
- **Known gaps / notes:** the `const`-constructor coverage flake still applies — re-run `--coverage` once if
  the gate flags an untouched file. Always pass `-d <booted-udid>` to the integration suite.

### Result — LOOP-5

The re-photograph loop is live (AC-8): `CorrectionController.rephotograph` re-drives the camera to a fresh
measured swatch and re-reads its difference from the target, replacing the prior reading, and E28
"Re-photograph swatch" is wired to it. Run in **parallel** (worktree `Nuance-bs05-LOOP5`, branch
`phase/bs-05-mix-correction-loop/LOOP-5`, based at the bs-05 tip `a4f97b7`) while CORRECT-2 held the engine
strand — disjoint ownership (controller + rephotograph region vs engine + difference/words).

- **Landed (`lib/`):** `correction_controller.dart` — `rephotograph()` mirrors `checkMix`'s bs-02 capture idiom
  (fresh `CaptureController`, drain the finite feed via a zero-delay timer, `commit()` the measured swatch),
  then `_emit`s a new state with the re-measured `mixedSwatch` + a fresh `correctionEngine.difference(...)`;
  a frameless feed leaves the state untouched; like the check it reads the difference only and clears any prior
  `correction` (a fresh photo invalidates it — CORRECT-3 will add the correction to both paths). `checkMix` was
  **not** touched, so the merge with CORRECT-3's `checkMix` extension stays clean. `regions/rephotograph_region.dart`
  — E28 `TextButton` enabled, `onPressed: () => controller.rephotograph()`, now takes the controller.
  `correction_screen.dart` — passes the controller to `RephotographRegion` (line change only).
- **Scope note (shared assembly file):** `correction_screen.dart` is the shared region-assembly surface both
  strands wire into; LOOP-5 touched only its `RephotographRegion(...)` line (CORRECT-2 touches the
  `DifferenceRegion(...)` line), different lines → clean merge.
- **Gate:** `flutter analyze` clean; unit **634 green** (`flutter test --coverage`, +1 net: controller −1 inert
  throw-test +2 rephotograph tests, screen RephotographRegion test now taps the enabled control); coverage gate
  **100% on all touched files** (`dart run tool/coverage_gate.dart main` — reports the 14 correction files vs
  `main`; this phase changed `correction_controller.dart`, `regions/rephotograph_region.dart`,
  `correction_screen.dart`). **Acceptance (iPhone 17 sim `5AB9D06D…` under the verify lock):** AC-8 un-pended in
  `bs05/pending.dart`; `TestAC08_RephotographRechecks` green — run-pending **14 pass / 8 fail** (was 13/9; AC-8
  flipped green, AC-2…AC-7/AC-9/AC-10 still fail cleanly), default **100 pass / 8 skip** (was 99/9; no regression
  across bs-01…bs-04 + AC-1). **Grade:** AC-8 retains its ITEST-2 **A** — `TestAC08`'s body is unchanged; the
  only acceptance-file edits were the standard un-pend bookkeeping (the `pending gate` group's `unpended` set
  `{'AC-1'}`→`{'AC-1','AC-8'}` and dropping the AC-8 row in `bs05/pending.dart`), never a weakening. No
  augmentation assigned to LOOP-5. **Fix passes: 1/3** (first run-pending flagged the `pending gate` guard
  "AC-8 must still have a pending entry" — expected un-pend bookkeeping; fixed by adding AC-8 to `unpended`; no
  product change).
- **Tokens / Time:** 7,036,729 · 28m 15s.

### Checkpoint / Handoff — LOOP-5

- **Frozen for the next phases:**
  - `CorrectionController.rephotograph()` re-drives capture → sets `state.mixedSwatch` (measured) +
    `state.difference` and notifies through `_emit`, replacing the prior reading; it reads the difference only
    and leaves `state.correction` null (same as `checkMix` at this tip).
  - `RephotographRegion({required CorrectionController controller})` — E28 enabled, wired to `rephotograph()`.
- **⚠ Carry-forward for CORRECT-3 (the merge):** CORRECT-3 extends `checkMix` to also compute + store
  `state.correction` (per LOOP-3's handoff). `rephotograph` deliberately duplicates the capture idiom rather
  than share a helper, to keep this parallel branch's merge with CORRECT-3's `checkMix` edit clean. **Once both
  land, a follow-up should extend `rephotograph` the same way (compute the correction) and may unify the two via
  a shared private `_photographAndCheck()` helper** — AC-8 does not read `correction`, so LOOP-5 did not need it.
- **⚠ Merge note (LOOP-6, serial on the controller):** LOOP-6 (`saveConfirmed`) also edits
  `correction_controller.dart`; it lands after LOOP-5 on its own branch and merges the `saveConfirmed` stub
  region — disjoint from the `rephotograph` method body.
- **Verification commands:** unchanged (export PATH; `flutter analyze`; `flutter test --coverage`;
  `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; bs-05 run-pending via
  `flutter test integration_test/correction_test.dart -d <sim> --dart-define=BS05_RUN_PENDING=true`).
- **Next phases:** LOOP-6 (AC-9/AC-10) startable now (depends on LOOP-3); CORRECT-2 → CORRECT-3 → CORRECT-4 on
  the engine strand (CORRECT-2 was in flight this session); LOOP-4 (AC-7) after CORRECT-3.
- **Known gaps / notes:** the `const`-constructor coverage flake still applies — re-run `--coverage` once if the
  gate flags an untouched file. Always pass `-d <booted-udid>` to the integration suite. This phase's branch
  must be merged into `feat/bs-05-mix-correction-loop` and rolled up (`--reconcile`) before the master plan
  reflects it.

### Result — LOOP-4

The spoken correction is live (AC-7): `CorrectionController.speakCorrection` speaks the difference and the
paints to add as a single utterance through the injected `Speech` seam, and E27 "Speak correction" is wired to
it — enabled once the mix is checked. Run **sequentially** in the primary bs-05 worktree (`Nuance-bs05`);
reconciled inline.

- **Landed (`lib/`):** NEW `correction/correction_speech.dart` — `String? correctionSpeech(CorrectionState)`:
  null before a check (`difference` null), else one utterance stating the difference (verdict + ΔE00 + the
  value-leading decomposition, mirroring `DifferenceRegion`) and the correction — each addition as
  `add about N parts of <paint>` (AC-4) or trace `a touch of <paint>` (AC-5), or `No paints to add.` for the
  within-tolerance empty/null correction (AC-6). Reuses `CorrectionRegion`'s phrasing so heard = seen; the
  spoken counterpart of `comparisonSpeech`/`recipeSpeech`. `correction_controller.dart` — `speakCorrection()`
  now builds via `correctionSpeech(_state)` and calls `speech.speak(...)` exactly once when non-null (inert
  otherwise, like `ComparisonController.speak`), replacing the `UnimplementedError` stub.
  `regions/speak_region.dart` — E27 `TextButton` takes the controller, enabled iff
  `correctionSpeech(controller.state) != null` (nothing to speak before a check — the bs-03 E6 pattern), wired
  to `speakCorrection()`. `correction_screen.dart` — passes the controller to `SpeakRegion` (one line).
- **Gate:** `flutter analyze` clean; unit **663 green** (`flutter test --coverage`, +29 net: new
  `correction_speech_test.dart` 6, controller +2 speakCorrection tests −1 inert throw-test, screen SpeakRegion
  group now 2 tests, plus the rebalanced region/controller tests); coverage gate **100% on all 16 touched
  files** (`dart run tool/coverage_gate.dart main` — includes the new `correction_speech.dart` and
  `speak_region.dart`). **Acceptance (iPhone 17 sim `5AB9D06D…` under the verify lock):** AC-7 un-pended in
  `bs05/pending.dart`; `TestAC07_SpeakCorrection` green — run-pending **20 pass / 2 fail** (AC-9/AC-10 still
  fail cleanly on their LOOP-6 Given preconditions; red baseline intact), default **106 pass / 2 skip** (was
  105/3; AC-7 flipped green, no regression across bs-01…bs-04 + AC-1..AC-6/AC-8).
- **Grade:** independent re-grade of every un-pended AC test (AC-1..AC-8) → **8×A / 0×B**, no blocker; AC-7 = A
  (holds the real builder/controller to the AC and rejects silent / multiple / omitted-difference /
  omitted-paint impls; traced the real SCENE_OFF utterance = verdict "noticeably off" + one Titanium White
  addition). No drift; the grid's LOOP-4 re-grade section records it.
- **Augmentations:** none assigned to LOOP-4, and none newly enabled — AC-7 speaks existing readings, adding no
  stronger assertion to another already-green AC (G6). **Fix passes: 1/3** (the first `--coverage` run flagged
  the SpeakRegion "enables + speaks" widget test, which called `await controller.checkMix()` directly in a
  `testWidgets` body — a zero-delay capture timer that never fires without a pump; rewritten to pump the full
  screen and tap "Check my mix" then "Speak correction", the proven idiom; no product change).
- **Tokens / Time:** 18,028,310 · 1h 02m.

### Checkpoint / Handoff — LOOP-4

- **Frozen for the next phase (LOOP-6, then SIGNOFF-1):**
  - `correctionSpeech(CorrectionState)` — null until checked; otherwise the one-utterance difference + paints
    (or "No paints to add." within tolerance). Pure; reuses `CorrectionRegion` phrasing.
  - `CorrectionController.speakCorrection()` speaks `correctionSpeech(_state)` once when non-null, inert
    otherwise; does not notify (speaking doesn't change the reading).
  - `SpeakRegion({required CorrectionController controller})` — E27 enabled iff there is something to speak.
- **⚠ Merge note (LOOP-6, serial on the controller):** LOOP-6 (`saveConfirmed`) edits
  `correction_controller.dart` too; `speakCorrection` is a self-contained method body and the new
  `correction_speech.dart` import is additive, so LOOP-6's `saveConfirmed` body merges cleanly. LOOP-6 also
  touches `correction_screen.dart` (wiring `SaveRegion`) — a different line than this phase's `SpeakRegion`
  line.
- **Verification commands:** unchanged (export PATH; `flutter analyze`; `flutter test --coverage`;
  `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; bs-05 run-pending via
  `flutter test integration_test/correction_test.dart -d <sim> --dart-define=BS05_RUN_PENDING=true`).
- **Next phase:** LOOP-6 (AC-9/AC-10 — save confirmed → provenance promotion + later readout) is the last
  behaviour phase; after it, SIGNOFF-1. LOOP-6 depends on LOOP-3 + G-4(d) (both resolved) and is file-disjoint
  from this phase.
- **Known gaps / notes:** the `const`-constructor coverage flake still applies — re-run `--coverage` once if the
  gate flags an untouched file. Always pass `-d <booted-udid>` to the integration suite. Carry-forward (from
  LOOP-5): `rephotograph` still reads the difference only and clears `state.correction`; a later pass may unify
  it with `checkMix`'s correction path via a shared `_photographAndCheck()` helper — not AC-blocking.

### Result — LOOP-6

Save-confirmed is live (AC-9) and a confirmed value carries its provenance into a later readout (AC-10) — the
**last behaviour phase**. The full behaviour stage (all 10 ACs) is complete. Run sequentially in the primary
bs-05 worktree (`Nuance-bs05`); reconciled inline.

- **Landed (`lib/`):** `correction_controller.dart` — `saveConfirmed()` promotes the checked `state.target`
  to `ProvenanceTier.confirmed` via `Sample.copyWith`, carrying the note **"Confirmed — you measured this,
  after photographing your own swatch."** (G-4(d): the phrase rides `Provenance.note`; the shared
  `Provenance.label` for `confirmed` is left "Confirmed", unchanged for bs-04), and appends the measured
  swatch as an append-only `EvidencePoint(source: 'own swatch')` (D9). The **honest-provenance guard** (D-8)
  refuses promotion when `state.mixedSwatch` is null — no value graduates to Confirmed without the painter's
  own measured swatch. The promoted sample is exposed through a controller-local `_confirmedSaves` list merged
  into `savedSamples` (see the persistence note below); `_emit` records `savedProvenance` and notifies. The
  now-unused `_deferred` shell helper was removed (all four actions are implemented). `regions/save_region.dart`
  — E29 `ElevatedButton` takes the controller, enabled iff `controller.state.hasChecked`, wired to
  `saveConfirmed()`. `correction_screen.dart` — passes the controller to `SaveRegion` (one line).
  `readout/provenance_region.dart` — `noteFor` now surfaces a **confirmed** reading's carried
  `Provenance.note` (previously only `estimated` carried a note); `measured`/`calculated` still show none, so
  AC-6/AC-7 are unaffected. A confirmed value's readout now reads "Confirmed" + the carried note (AC-10).
- **Persistence note (D-8, plan-sanctioned):** `SampleSource` is the read-only bs-03 seam (bs-06 owns the
  persistent catalogue), so LOOP-6 takes the plan's explicit alternative — LOOP.md *"writes a confirmed Sample
  back to sampleSource **(or exposes it for the readout)**"* — exposing the confirmed mix through the
  controller's `savedSamples` (injected catalogue ++ `_confirmedSaves`) rather than mutating the shared
  read-only source. AC-9/AC-10 observe `controller.savedSamples`, which carries it; **bs-06** will back
  `savedSamples` with the persistent store so a confirmed mix also reaches other screens.
- **Gate:** `flutter analyze` clean; unit **668 green** (`flutter test --coverage`, +5 net: controller
  −1 inert throw-test +3 saveConfirmed tests, provenance_region +2 confirmed-note tests, screen SaveRegion
  group now 2 tests); coverage gate **100% on all touched files** (`dart run tool/coverage_gate.dart main` —
  reports 17 correction/readout files vs `main`; this phase changed `correction_controller.dart`,
  `regions/save_region.dart`, `correction_screen.dart`, `readout/provenance_region.dart`).
  **Acceptance (iPhone 17 sim `5AB9D06D…` under the verify lock):** AC-9 + AC-10 un-pended in `bs05/pending.dart`
  (the pending map is now **empty** — behaviour stage complete); `TestAC09_SaveConfirmed` + `TestAC10_
  ConfirmedInReadout` green — run-pending **22 pass / 0 fail** (all 10 ACs green; was 20/2 at LOOP-4), default
  full suite **108 pass / 0 skip** (was 106/2; AC-9/AC-10 flipped green, no regression across bs-01…bs-05).
- **Grade:** independent re-grade in a fresh subagent of **every** un-pended AC test (AC-1..AC-10) →
  **10×A / 0×B**, no blocker; AC-9 = A (holds the real `saveConfirmed` to the AC — tier/note/evidence/
  persistence + the honest-provenance control), AC-10 = A. **No augmentation** open or newly required (the sole
  ever-opened row, TestAC02, was closed by CORRECT-4). Grid: `behavior-test-completeness-bs-05-mix-correction-loop.md`.
- **Test change recorded (not a weakening):** AC-10's `_showInLaterReadout` helper awaited
  `navigator.push(...)`, whose Future completes only when the route is **popped**, so it blocked the test
  forever (surfaced only now — at red baseline AC-10 failed its Given precondition before reaching the helper).
  Fixed to `unawaited(navigator.push(...)); await tester.pumpAndSettle();` — fire-and-forget the push, pump the
  transition. The Then assertions are unchanged; confirmed via a throwaway widget-test repro (pass in 1s) that
  the product code is correct and only the helper's `await` was the defect. The rewritten second pending-gate
  test asserts the behaviour-complete end state (empty map; every AC runs in both modes) — graded A.
- **Augmentations:** none assigned to LOOP-6, none newly enabled. **Fix passes: 1/3** (the first run-pending
  integration run hung on AC-10's `await navigator.push`; fixed the test helper — no product change — second
  run green).
- **Tokens / Time:** 22,315,250 · 1h 30m.

### Checkpoint / Handoff — LOOP-6

- **Behaviour stage complete.** All 10 ACs un-pended + green; `integration_test/bs05/pending.dart`'s
  `pendingACs` map is empty. The only remaining phase is **SIGNOFF-1** (sign-off packet + summary page +
  manual approval).
- **Frozen for sign-off:**
  - `CorrectionController.saveConfirmed()` promotes the checked target to `confirmed` (note
    "Confirmed — you measured this, after photographing your own swatch.", measured swatch appended as
    evidence), guarded on `state.mixedSwatch != null`; inert otherwise. `savedSamples` =
    `sampleSource.savedSamples()` ++ the session's confirmed saves (unmodifiable).
  - `SaveRegion({required CorrectionController controller})` — E29 enabled iff `state.hasChecked`.
  - `ProvenanceRegion.noteFor` returns a confirmed reading's `Provenance.note` (shared `Provenance.label`
    unchanged).
- **Verification commands:** unchanged (export PATH; `flutter analyze`; `flutter test --coverage`;
  `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; bs-05 run-pending via
  `flutter test integration_test/correction_test.dart -d <sim> --dart-define=BS05_RUN_PENDING=true`).
- **Next phase:** none — SIGNOFF-1 approved 2026-10-11 by Matt Quirk at `83554a9`; feature is Done.
- **Known gaps / notes (for sign-off):** (1) **Persistence** — a confirmed mix is exposed via the controller's
  `savedSamples`, not written to the shared read-only `SampleSource`; bs-06 (palette & projects) owns the
  persistent catalogue and will back `savedSamples` so a confirmed value reaches other screens. (2) The
  carry-forward from LOOP-5 remains: `rephotograph` reads the difference only and clears `state.correction`; a
  later pass may unify `checkMix`/`rephotograph` via a shared `_photographAndCheck()` helper — not AC-blocking.
  (3) The `const`-constructor coverage flake still applies — re-run `--coverage` once if the gate flags an
  untouched file. Always pass `-d <booted-udid>` to the integration suite.
