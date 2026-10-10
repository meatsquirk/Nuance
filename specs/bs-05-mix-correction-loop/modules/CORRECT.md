# Module CORRECT — correction engine

**Status:** In progress — CORRECT-1 done; CORRECT-2 next (behavior, gated by G-2 + G-4)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/correction/engine/correction_engine.dart` (interface + `Difference`/`Correction` types), `lib/correction/engine/correction_engine_impl.dart` (the v1 impl), `lib/correction/engine/correction_words.dart` (verdict band + value-leading phrasing)
**Depends on:** bs-04 `MixingEngine`/`Paint`/`PaintPalette`/`Recipe` · bs-03 `deltaE00` (`lib/compare/difference.dart`) · color-science (`labToCielch`, `hueFamilyWord`, `words.dart`) · CORRECT-1 is a shell (stub wired by LOOP via `AppDependencies.correctionEngine`) · **Blocks:** LOOP-2 (needs the types), SCREEN-1, the CORRECT-2/3/4 behaviour phases

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 5,968,811 | 11m 31s |
| 2 | behavior | AC-2, AC-3 | ⬜ Todo | | |
| 3 | behavior | AC-4, AC-5 | ⬜ Todo | | |
| 4 | behavior | AC-6 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes** `abstract interface class CorrectionEngine { Difference difference(Sample mixedSwatch, Sample target); Correction correct(Sample mixedSwatch, Sample target, Recipe currentMix, PaintPalette palette); }` — two seams so the difference (AC-2/3) is computable before the correction (AC-4/5) and the within-tolerance case (AC-6) can short-circuit `correct`.
  - `class Difference { final double deltaE00; final String verdict; final String valueReading; /* "too dark by 6" */ final String hueReading; /* "shifted toward green" */ final bool withinTolerance; }` — `valueReading` is the **leading** reading (D-5).
  - `class Correction { final List<CorrectionAddition> additions; bool get isEmpty; } class CorrectionAddition { final Paint paint; final double parts; final bool isTrace; final String? techniqueNote; }`.
- **Consumes** bs-04 `MixingEngine.forward(Map<Paint,double>, {dry})` to score candidate additions, `deltaE00(ColorCoordinates,ColorCoordinates)`, `labToCielch`, `hueFamilyWord`.
- **Verdict band vs bs-03/bs-04:** bs-05 owns its band (D-4) in `correction_words.dart`; it does **not** import bs-03's private `_verdictBands` nor bs-04's engine bands. Exact words ("noticeably off", "very close") and the tolerance (ΔE00 ≤ 2) are G-4(b).
- **Reference vs product:** the acceptance harness grades ΔE00 against its own independent `referenceDeltaE00`; the engine uses the product `deltaE00`. They must agree to 0.1 (D-10).

## Open gates

- **G-4** (blocks CORRECT-2/3/4 + ITEST-3): verdict words + tolerance (b), trace threshold (c), illustrative amounts (a). Resolve before un-pending AC-2..AC-6. See the master plan's *Open gates*.

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
