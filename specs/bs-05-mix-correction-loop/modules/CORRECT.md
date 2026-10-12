# Module CORRECT — correction engine

**Status:** ✅ Complete — CORRECT-1/2/3/4 done (AC-2/AC-3/AC-4/AC-5/AC-6 ✅; TestAC02 augmentation closed at CORRECT-4)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/correction/engine/correction_engine.dart` (interface + `Difference`/`Correction` types), `lib/correction/engine/correction_engine_impl.dart` (the v1 impl), `lib/correction/engine/correction_words.dart` (verdict band + value-leading phrasing)
**Depends on:** bs-04 `MixingEngine`/`Paint`/`PaintPalette`/`Recipe` · bs-03 `deltaE00` (`lib/compare/difference.dart`) · color-science (`labToCielch`, `hueFamilyWord`, `words.dart`) · CORRECT-1 is a shell (stub wired by LOOP via `AppDependencies.correctionEngine`) · **Blocks:** LOOP-2 (needs the types), SCREEN-1, the CORRECT-2/3/4 behaviour phases

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 5,968,811 | 11m 31s |
| 2 | behavior | AC-2, AC-3 | ✅ Done | 13,621,264 | 32m 47s |
| 3 | behavior | AC-4, AC-5 | ✅ Done | 26,610,719 | 1h 03m |
| 4 | behavior | AC-6 | ✅ Done | 10,423,853 | 1h 06m |

## Interface reconciliation

- **Exposes** `abstract interface class CorrectionEngine { Difference difference(Sample mixedSwatch, Sample target); Correction correct(Sample mixedSwatch, Sample target, Recipe currentMix, PaintPalette palette); }` — two seams so the difference (AC-2/3) is computable before the correction (AC-4/5) and the within-tolerance case (AC-6) can short-circuit `correct`.
  - `class Difference { final double deltaE00; final String verdict; final String valueReading; /* "too dark by 6" */ final String hueReading; /* "shifted toward green" */ final bool withinTolerance; }` — `valueReading` is the **leading** reading (D-5).
  - `class Correction { final List<CorrectionAddition> additions; bool get isEmpty; } class CorrectionAddition { final Paint paint; final double parts; final bool isTrace; final String? techniqueNote; }`.
- **Consumes** bs-04 `MixingEngine.forward(Map<Paint,double>, {dry})` to score candidate additions, `deltaE00(ColorCoordinates,ColorCoordinates)`, `labToCielch`, `hueFamilyWord`.
- **Verdict band vs bs-03/bs-04:** bs-05 owns its band (D-4) in `correction_words.dart`; it does **not** import bs-03's private `_verdictBands` nor bs-04's engine bands. Exact words ("noticeably off", "very close") and the tolerance (ΔE00 ≤ 2) are G-4(b).
- **Reference vs product:** the acceptance harness grades ΔE00 against its own independent `referenceDeltaE00`; the engine uses the product `deltaE00`. They must agree to 0.1 (D-10).

## Open gates

- **G-4** ✅ Resolved 2026-10-10 17:35 EDT — Matt Quirk: (a) amounts **illustrative** (assert properties, not literals); (b) verdict words **"noticeably off" / "very close"** binding, tolerance **ΔE00 ≤ 2** (named constant); (c) trace threshold **0.02** (2% by volume, reuse bs-04's idiom). CORRECT-2/3/4 and ITEST-3 unblocked. Full decision in the master plan's *Open gates*.

## Phase 1 — Engine interface + types (CORRECT-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** LOOP-1 · **Blocks:** LOOP-2, SCREEN-1, CORRECT-2
- **Files:** `lib/correction/engine/correction_engine.dart`, a stub `correction_engine_impl.dart`, `AppDependencies.correctionEngine` wiring
- **Tasks:**
  1. Define `CorrectionEngine`, `Difference`, `Correction`, `CorrectionAddition` (value-equal, const where possible).
  2. A stub `SubtractiveCorrectionEngine` (or similar) returning an inert `Difference`/empty `Correction` — no real math yet — wired into `AppDependencies.correctionEngine` (default `const`), symmetric to `mixingEngine`.
  3. 100% unit coverage of the new types; existing suite stays green.
- **Exit criteria:** `flutter analyze` clean; unit + coverage gate pass on touched files; the app still builds (behavior unchanged).

## Phase 2 — Difference: ΔE00 + verdict + value-leading decomposition (CORRECT-2)

- **Kind:** behavior
- **Target AC:** AC-2 (full), AC-3 (full)
- **Depends on:** LOOP-3 (a checked mix exists) · **Blocks:** CORRECT-3
- **Files:** `correction_engine_impl.dart` (`difference(...)`), `correction_words.dart` (band + value/hue phrasing), the difference-body region (SCREEN-1's `DifferenceRegion`)
- **Tasks:**
  1. `difference()` = `deltaE00(mixed,target)` + verdict band (D-4) + `valueReading` "too dark/light by N" from ΔL* + `hueReading` "shifted toward <family>" from the signed hue delta + `hueFamilyWord` (D-5), value **first**.
  2. Render the difference body leading with value; show ΔE00 + verdict.
  3. Unit-test the band boundaries and the value/hue phrasing (both signs, each hue family touched).
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-2, AC-3; `flutter test integration_test/correction_test.dart -d <udid> --dart-define=BS05_RUN_PENDING=true` green for `TestAC02_DeltaEAndVerdict`, `TestAC03_ValueLeadingDecomposition` (and all earlier ACs).
- **Augments:** `TestAC02`: add a within-tolerance reading showing "very close" so the verdict is shown to track distance (closed with CORRECT-4's tolerance, or seed the control here).

## Phase 3 — Concrete correction: paint + amount; "a touch of" (CORRECT-3)

- **Kind:** behavior
- **Target AC:** AC-4 (full), AC-5 (full)
- **Depends on:** CORRECT-2 · **Blocks:** CORRECT-4, LOOP-4
- **Files:** `correction_engine_impl.dart` (`correct(...)`), the correction-body region (SCREEN-1's `CorrectionRegion`)
- **Tasks:**
  1. `correct()` = search the palette: for each paint, perturb `currentMix` parts (add a small amount), `forward`-predict, keep the addition(s) that most reduce `deltaE00` to the target; return them as `CorrectionAddition`s with parts (D-3).
  2. An addition below the trace threshold (G-4(c)) → `isTrace: true` + a static technique note; render "a touch of <paint>" (D-7), reusing bs-04's trace idiom.
  3. Render the correction body (paint names + amounts; "a touch of" for traces).
  4. Unit-test: direction (White lightens a too-dark mix), the forward-score monotonicity (the chosen addition reduces ΔE00), trace classification.
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-4, AC-5; the suite green for `TestAC04_ConcreteCorrection`, `TestAC05_TouchOf` (+ earlier ACs). AC-4's in-test control: the suggested addition must reduce the forward ΔE00.

## Phase 4 — Within tolerance → "very close" + no correction (CORRECT-4)

- **Kind:** behavior
- **Target AC:** AC-6 (full)
- **Depends on:** CORRECT-3 · **Blocks:** SIGNOFF-1
- **Files:** `correction_engine_impl.dart` (tolerance short-circuit in `difference`/`correct`), `correction_words.dart`, the correction-body region (no-correction state)
- **Tasks:**
  1. `difference().withinTolerance = deltaE00 ≤ tolerance (ΔE00 2, D-6/G-4(b))`; verdict "very close".
  2. `correct()` returns an empty `Correction` when within tolerance; the screen shows no correction.
  3. Augment `TestAC02` with the within-tolerance "very close" reading as its discriminating control.
  4. Unit-test the tolerance boundary (just inside / just outside) and the empty-correction path.
- **Exit criteria:** unit + coverage gate pass on touched files.
- **Acceptance gate:** un-pend AC-6; the suite green for `TestAC06_WithinTolerance` (+ all earlier ACs); `TestAC02`'s augmentation green.
- **Augments:** `TestAC02`: the "very close" within-tolerance control reading.

### Result — CORRECT-1

Shell complete: the `CorrectionEngine` interface + its value types, plus a stub engine wired into
`AppDependencies`. Behaviour unchanged — no real math, no screen reads it yet.

- **Landed:** `lib/correction/engine/correction_engine.dart` — `abstract interface class CorrectionEngine`
  (`difference(Sample mixedSwatch, Sample target)`, `correct(Sample, Sample, Recipe currentMix, PaintPalette)`)
  + value-equal, `const` types `Difference` (deltaE00, verdict, valueReading, hueReading, withinTolerance),
  `Correction` (`additions`; `isEmpty`), `CorrectionAddition` (paint, parts, isTrace, techniqueNote).
  `lib/correction/engine/correction_engine_impl.dart` — `const SubtractiveCorrectionEngine` stub returning an
  inert `Difference` (ΔE00 0, empty readings, not within tolerance) + empty `Correction`.
  `lib/app/build_app.dart` — `AppDependencies.correctionEngine` (default `const SubtractiveCorrectionEngine()`),
  symmetric to `mixingEngine`; no call site changed.
- **Verification (Flutter 3.47.6, iPhone 17 sim `5AB9D06D…`):** `flutter analyze` clean; unit **598 green**
  (`flutter test --coverage`); integration **86 green** (`flutter test integration_test/ -d <sim>`, under the
  verify lock) — the build_app change broke no existing acceptance suite.
- **Coverage gate:** `dart run tool/coverage_gate.dart main` — **100%** on all 3 touched files
  (`build_app.dart`, `correction_engine.dart`, `correction_engine_impl.dart`). No exclusions.
- **Tests added:** `test/correction/engine/correction_engine_test.dart` (type ctors/==/hashCode/toString, each
  field's inequality, both toString branches, runtime-const lines), `correction_engine_impl_test.dart` (stub
  inert difference + empty correction + interface type), and two `build_app_test.dart` cases (default +
  injected correction engine), mirroring the bs-04 engine-type test idiom.
- **No AC** (shell) → no acceptance/grade gate. **Fix passes: 1/3** (import of `domain/paint.dart` added after
  the first analyze; no logic change).

### Checkpoint / Handoff — CORRECT-1

- **Frozen for consumers:** `CorrectionEngine` (two seams: `difference` before `correct`), the types
  `Difference` / `Correction` / `CorrectionAddition`, and `AppDependencies.correctionEngine`. **LOOP-2**
  constructs the `CorrectionController` over `AppDependencies.correctionEngine` (do not let the controller
  compute the math itself); SCREEN-1 then binds the regions. CORRECT-2 fills `difference()`, CORRECT-3
  `correct()`, CORRECT-4 the within-tolerance short-circuit — all behind this unchanged interface.
- **Interface note:** `Difference` fields are all `required` (a reading is never silently partial); the stub
  passes explicit inert values. `Correction()` defaults to empty additions (the no-correction state).
- **Verification commands** (export PATH first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main` · integration under
  the verify lock: `$C with-lock bs-05-mix-correction-loop <PHASE> --wait 900 -- bash -c "export PATH=…; cd
  /Users/matthew.quirk/Nuance-bs05 && flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685"`.
- **Known gaps / notes:** stub only — `difference`/`correct` are inert until CORRECT-2/3/4 (G-4 gates those).
  Carry-over flake (master *Known flakes*): a `const` ctor line can intermittently read uncovered on
  `--coverage`; re-run once if the gate flags an untouched file (did not recur this phase). Untracked
  bs-06..bs-14 specs + `docs/` remain in the tree from a prior branch; not part of bs-05, not committed here.
- **Next phase:** LOOP-2 (shell) — `CorrectionController`/`CorrectionState` + `CorrectionReadEndpoint` +
  `CorrectionEntry`/`toCorrection` route in `buildApp`, consuming `AppDependencies.correctionEngine`.

### Result — CORRECT-2

The difference reading is live (AC-2, AC-3): a checked mix now shows its ΔE00 with a plain verdict and a
value-leading decomposition.

- **Landed (`lib/`):** `engine/correction_words.dart` (new) — `verdictFor(deltaE00)` (the beyond-tolerance
  band word "noticeably off"; CORRECT-4 adds the within-tolerance "very close" branch), `valueReadingFor` ("too
  dark by N" / "too light by N" / "matched on value" from `round(targetL − mixedL)`, value-leading D-5),
  `hueReadingFor` ("shifted toward <family>" via `hueFamilyWord` of the mixed hue, or "hue on target" below a
  1° shift). `engine/correction_engine_impl.dart` — `difference()` fills `verdict`/`valueReading`/`hueReading`
  (ΔE00 still bs-03's shipped `deltaE00`; hue angles via the shared `labToCielch`; `withinTolerance` stays
  false — CORRECT-4). `regions/difference_region.dart` — reads `controller.state.difference` and renders the
  ΔE00+verdict line, then value, then hue (placeholder before a check). `correction_screen.dart` — passes the
  controller to `DifferenceRegion` (one line; the screen's per-region wiring, as with `CheckRegion`).
- **Un-pended:** AC-2, AC-3 (`integration_test/bs05/pending.dart`; `unpended` set in `correction_test.dart`).
- **Gate:** `flutter analyze` clean; unit **641 green** (`flutter test --coverage`; +3: the new
  `correction_words_test.dart`, an added checked-render screen test, the engine-impl test updated to the filled
  readings); coverage gate **100% on all touched files** (`dart run tool/coverage_gate.dart main`). **Acceptance
  (iPhone 17 sim under the verify lock):** full `integration_test/` default **101 pass / 7 skip** (was 99/9 at
  LOOP-3 — AC-2 + AC-3 moved skip→pass; no bs-01..bs-04 regression); the 7 skips are the still-pending
  AC-4…AC-10.
- **Grade:** independent fresh-context re-grade of the un-pended AC tests — **AC-1 A, AC-3 A, AC-2 B pending
  CORRECT-4** (the pre-seeded limitation: a single off-reading can't show the verdict tracks distance; the
  within-tolerance "very close" control is CORRECT-4's AC-6 augmentation). No blockers, no drift. Grid appended.
- **Augmentations:** none made here (TestAC02's is owned by CORRECT-4); none newly enabled (AC-1 is a different
  AC — G6).
- **Fix passes: 1/3** (first `flutter analyze` flagged an angle-bracket doc comment in `correction_words.dart`
  and `const`-map double keys in the new unit test — both test/doc, no product/logic change).
- **Tokens / Time:** 13,621,264 · 32m 47s.

### Checkpoint / Handoff — CORRECT-2

- **Frozen for the next phases:**
  - `SubtractiveCorrectionEngine.difference()` returns a complete `Difference` — real ΔE00, `verdict`
    "noticeably off", the value-leading `valueReading`/`hueReading` — with `withinTolerance: false`.
  - `correction_words.dart`: `verdictFor` / `valueReadingFor` / `hueReadingFor` are the shared phrasing seam.
  - `DifferenceRegion(controller:)` renders the difference body from `state.difference`.
- **⚠ For CORRECT-3 (same engine file, serial next):** fill `correct()` (the palette search via
  `MixingEngine.forward`) **and extend `checkMix` to also store `state.correction`** (carried from LOOP-3's
  handoff — the controller still sets only `difference`). CORRECT-3 wires `CorrectionRegion(controller:)` into
  `correction_screen.dart` the same way this phase wired `DifferenceRegion`.
- **⚠ For CORRECT-4 (serial after CORRECT-3):** add the within-tolerance branch — set `withinTolerance =
  deltaE00 ≤ tolerance` (a **named constant**, G-4b/D-6 = ΔE00 2) and make `verdictFor` return "very close"
  within tolerance; make `correct()` return an empty `Correction` within tolerance; then **close the TestAC02
  augmentation** (add the SCENE_CLOSE "very close" control) and re-grade TestAC02 to A.
- **Verification commands:** unchanged from CORRECT-1 (export PATH; `flutter analyze`; `flutter test
  --coverage`; `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; bs-05 run-pending via `… correction_test.dart -d <sim>
  --dart-define=BS05_RUN_PENDING=true`).
- **Known gaps / notes:** AC-2 is functionally green but graded **B pending CORRECT-4** (open augmentation) —
  so AC-2 is **not** ✅ in the master AC-coverage table until CORRECT-4 closes it. The `const`-ctor coverage
  flake still applies (did not recur). Always pass `-d <booted-udid>` to the integration suite.

### Result — CORRECT-3

The concrete correction is live (AC-4, AC-5): a checked mix now names the one paint to add and how much,
"a touch of" for a trace.

- **Landed (`lib/`):** `engine/correction_engine_impl.dart` — `correct()` now searches the owned palette
  (was an inert empty `Correction`). It is **value-leading** (D-5): a too-dark mix → the palette's lightest
  paint (white), a too-light mix → the darkest, a value-matched mix → the paint whose best addition most
  reduces the distance (hue/chroma). The amount is the closing step (perturb the current mix's parts,
  `MixingEngine.forward`-predict, apply the predicted change to the *measured* swatch so the model error
  cancels, keep the amount that most reduces `deltaE00`) **scaled by how far beyond tolerance the mix sits** —
  a mix only just over tolerance gets a conservative *touch* and a re-photograph (the loop), a far mix a
  measured part. Sub-trace (< 0.02 by volume, G-4c) → `isTrace` + a static technique note (D-7, bs-04's
  idiom). The engine gained an injected `mixingEngine` (default `const SubtractiveMixingEngine`). Within
  tolerance the ramp is 0 → empty `Correction` (CORRECT-4 makes that an explicit "very close").
  `correction_controller.dart` — `checkMix` now also computes `state.correction` over the selected palette
  (the first palette the `paletteSource` lists; empty catalogue → no correction); the controller still never
  does the maths itself (D-2/D-3). `regions/correction_region.dart` — reads `controller.state.correction`:
  renders each addition as `a touch of <paint>` + note (trace) or `Add about N parts of <paint>` (measured),
  and a no-correction line when empty. `correction_screen.dart` — passes the controller to `CorrectionRegion`.
- **Un-pended:** AC-4, AC-5 (`integration_test/bs05/pending.dart`; added to the `unpended` set in
  `correction_test.dart`).
- **Gate:** `flutter analyze` clean; unit **652 green** (`flutter test --coverage`; +11 net — the new engine
  search suite, a controller correction-over-palette test, three `CorrectionRegion` render tests, less the
  retired "correct returns empty" stub test); coverage gate **100% on all 15 touched files**
  (`dart run tool/coverage_gate.dart main`). **Acceptance (iPhone 17 sim `5AB9D06D…` under the verify lock):**
  run-pending `correction_test.dart` **18 pass / 4 fail** (AC-1,2,3,4,5,8 green; only AC-6,7,9,10 still fail
  cleanly = red baseline intact); full `integration_test/` default **104 pass / 4 skip** (AC-4 + AC-5 moved
  skip→pass; the 4 skips are exactly the pending AC-6,7,9,10; no bs-01..bs-05 regression).
- **Grade:** independent fresh-context re-grade of every un-pended AC test — **AC-1 A, AC-3 A, AC-4 A, AC-5 A,
  AC-8 A, AC-2 B pending CORRECT-4** (5×A + the one pre-scheduled augmentation). AC-4's in-test forward-model
  control genuinely decreases ΔE00 (before 12.686 → after 9.493); AC-5's sub-trace ochre (0.0126 < 0.02) comes
  out of the real tolerance-scaled ramp. No downgrades, no drift. Grid: `behavior-test-completeness-…md`
  (CORRECT-3 re-grade section appended).
- **Augmentations:** none made here; none newly enabled (the sole open row, TestAC02 → CORRECT-4, is untouched).
- **Fix passes: 0/3** (analyze + all gates passed on the first full run; the only pre-run iteration was design
  verification against the real forward model via throwaway probes, since the correction amounts are
  illustrative, G-4a).
- **Tokens / Time:** 26,610,719 · 1h 03m (this session also reconciled LOOP-5 — merge `95a403e`
  + rollup `07563c9` — before the phase; see the master plan session log / RECONCILE commits).

### Checkpoint / Handoff — CORRECT-3

- **Frozen for the next phase (CORRECT-4, serial next on the same engine file):**
  - `SubtractiveCorrectionEngine.correct()` returns the single value-leading addition with its `parts`,
    `isTrace` and `techniqueNote`; it already returns an **empty** `Correction` when the mix is at/within
    tolerance (the ramp is 0 at ΔE00 ≤ 2). CORRECT-4's remaining work is on `difference()`: set
    `withinTolerance = deltaE00 ≤ tolerance` and make `verdictFor` return **"very close"** within tolerance
    (it still returns the constant "noticeably off" today — that is why AC-2 stays B). The tolerance anchor
    the ramp uses is the private `_toleranceDeltaE00 = 2.0` in `correction_engine_impl.dart` (D-6/G-4b); lift
    it to the shared named constant CORRECT-4 wants.
  - After CORRECT-4 lands the within-tolerance verdict, **close the TestAC02 augmentation** (add the
    SCENE_CLOSE "very close" control) and re-grade TestAC02 to A → AC-2 ✅.
  - `CorrectionRegion(controller:)` renders the correction body; its empty-state line ("No paints to add.")
    is where CORRECT-4 can surface the "very close / no correction needed" wording if desired.
- **⚠ Still open (noted at LOOP-5):** `rephotograph` reads the difference only and **clears** `state.correction`
  (a fresh photo invalidates the old correction). A follow-up may extend `rephotograph` to also compute the
  correction (the same `checkMix` path) and unify the two capture methods — not required by any AC.
- **Verification commands:** unchanged from CORRECT-2 (export PATH; `flutter analyze`; `flutter test
  --coverage`; `dart run tool/coverage_gate.dart main`; integration under the verify lock on the iPhone 17 sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; bs-05 run-pending via `… correction_test.dart -d <sim>
  --dart-define=BS05_RUN_PENDING=true`). **Run the `--dart-define` run before a plain run, or `flutter clean`
  between them** — flutter reuses the cached on-device build, so a stale define is a silent false result.
- **Known gaps / notes:** amounts are illustrative (G-4a) — the ACs assert direction, the trace/measured band
  and the forward-model improvement, not literals. The `const`-ctor coverage flake still applies (did not
  recur). Always pass `-d <booted-udid>` to the integration suite.

### Result — CORRECT-4

The within-tolerance short-circuit is live (AC-6): a checked mix at or within ΔE00 2 now reads **"very close"**,
is flagged `withinTolerance`, and shows no correction. This also closes the pre-seeded TestAC02 augmentation,
so **AC-2 ✅** and **AC-6 ✅**.

- **Landed (`lib/`):** `engine/correction_words.dart` — a shared `const double correctionToleranceDeltaE00 = 2.0`
  (the single named tolerance anchor, D-6/G-4b), and `verdictFor` now returns **"very close"** at or within it,
  else "noticeably off". `engine/correction_engine_impl.dart` — `difference()` sets
  `withinTolerance: distance <= correctionToleranceDeltaE00`; the private `_toleranceDeltaE00` is retired in
  favour of the shared constant (the ramp reads it, so verdict and suppression cannot drift). `correct()`
  already returned an empty `Correction` within tolerance (ramp 0) — unchanged logic, shared-constant anchor.
  The difference/correction regions already render the verdict and the empty-correction state (CORRECT-2/3), so
  no region change was needed.
- **Un-pended:** AC-6 (`integration_test/bs05/pending.dart`; added to the `unpended` set in `correction_test.dart`).
- **Augmentation made:** **TestAC02 closed** — added a within-tolerance "very close" CONTROL (SCENE_CLOSE) to
  `TestAC02_DeltaEAndVerdict`, proving the verdict *tracks* distance (discriminates against a constant
  "noticeably off"; strengthens AC-2's own verdict step only, G6). No new augmentation enabled.
- **Gate:** `flutter analyze` clean; unit **655 green** (`flutter test --coverage`; +3: two `verdictFor`
  tests — within-tolerance "very close" + the exact tolerance boundary — and a `difference()`
  within-tolerance case); coverage gate **100% on all 15 touched files** (`dart run tool/coverage_gate.dart main`).
  **Acceptance (iPhone 17 sim `5AB9D06D…` under the verify lock):** run-pending `correction_test.dart`
  **19 pass / 3 fail** (AC-6 moved fail→pass; the 3 remaining clean fails are the still-pending AC-7/AC-9/AC-10);
  full `integration_test/` default **105 pass / 3 skip** (AC-6 moved skip→pass; the 3 skips are exactly pending
  AC-7/9/10; no bs-01..bs-05 regression — full cross-feature suite "All tests passed").
- **Grade:** independent fresh-context re-grade of every un-pended AC test — **7×A, 0×B** (AC-1, AC-2, AC-3,
  AC-4, AC-5, AC-6, AC-8). **AC-2 B-pending→A** (augmentation closed; the "very close" control is a genuine
  discriminator — recomputed SCENE_CLOSE ΔE00 0.956 → "very close" vs SCENE_OFF 10.06 → "noticeably off");
  **AC-6 pending→A**; the carried five A→A (no regression on the beyond-tolerance path). Grid:
  `behavior-test-completeness-…md` (CORRECT-4 re-grade section appended). Gate recommendation PASS.
- **Fix passes: 0/3** (analyze + all gates passed on the first full run).
- **Tokens / Time:** 10,423,853 · 1h 06m (active time includes a cold Xcode rebuild after `flutter clean`).

### Checkpoint / Handoff — CORRECT-4

- **CORRECT module complete.** All four AC-6/AC-2/AC-3/AC-4/AC-5 behaviours are live behind the frozen
  `CorrectionEngine` interface; the correction stage of bs-05 is done. The remaining bs-05 behaviour phases are
  LOOP-4 (AC-7, speak) and LOOP-6 (AC-9/AC-10, save + provenance), both independent of this file.
- **Frozen for consumers:** `correctionToleranceDeltaE00` (the one tolerance anchor — read it, don't re-litter
  ΔE00 2 across the code); `verdictFor(deltaE00)` returns "very close" / "noticeably off" split on it;
  `difference().withinTolerance` is `distance <= correctionToleranceDeltaE00`. LOOP-4's speak output reads the
  existing `state.difference` / `state.correction` (a within-tolerance check has a "very close" difference and
  an empty correction — speak must handle the no-correction case).
- **Verification commands:** unchanged from CORRECT-3 (export PATH; `flutter analyze`; `flutter test --coverage`;
  `dart run tool/coverage_gate.dart main`; integration under the verify lock on sim
  `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`). **Run the `--dart-define=BS05_RUN_PENDING=true` run before a plain
  run, or `flutter clean` between them** — a stale on-device define is a silent false result (this phase ran a
  `flutter clean` between the two, which forces a slow cold Xcode rebuild; budget ~40m for the default suite
  after a clean).
- **Known gaps / notes:** the `const`-ctor coverage flake still applies (did not recur). Always pass
  `-d <booted-udid>` to the integration suite.
