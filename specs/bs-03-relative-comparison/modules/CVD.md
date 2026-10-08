# Module CVD — confusion profile & detector

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/a11y/cvd/cvd_profile.dart` (`CvdProfile` { type, severity }),
`lib/a11y/cvd/confusion_check.dart` (`ConfusionCheck` interface + the dichromat-projection detector),
`lib/a11y/cvd/comparison_speech.dart` (the spoken-utterance builder). Extends `lib/app/build_app.dart`
(`AppDependencies.cvdProfile`). Reuses bs-01's `Speech` seam and DIFF's ΔE00.
**Depends on:** bs-01 color-science + `Speech`, DIFF (ΔE00) · **Blocks:** COMPARE-2 (injects the profile), the
confusion-warning + speak regions in SCREEN

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 3,816,225 | 8m 30s |
| 2 | behavior | AC-7, AC-8 | ✅ Done | 10,847,797 | 27m 02s |
| 3 | behavior | AC-9 | ⬜ Todo | | |

## Interface reconciliation

- **`CvdProfile`** { `type` ∈ { protan, deutan, tritan }, `severity` 0–1 } is introduced **here** (D-4),
  minimal, and injected via `AppDependencies.cvdProfile`. **bs-07** (CVD self-assessment) later *populates*
  this profile from its tests — bs-03 commits to the shape, not the assessment; the reconciliation is: bs-07
  must write into this same `CvdProfile` rather than inventing its own.
- **`ConfusionCheck`** interface: `bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile p)`.
  The impl projects both colours through the profile's dichromat simulation (Viénot 1999 / Brettel–Viénot–
  Mollon LMS, D-4) and returns true when the projected ΔE00 is below a small threshold while the normal ΔE00
  is clearly-different (D-5). **bs-08/bs-10** (simulation & daltonization) reuse this projection — the
  reconciliation is: the projection lives behind this interface so those features extend it, not re-derive it.
- **Spoken utterance** (`comparison_speech.dart`): builds one string = the relational statement (from DIFF's
  `Comparison`) plus, when a warning is present, the confusion-warning text — spoken once through bs-01's
  `Speech` seam (AC-9).

## Open gates

- None of this module's own. (Fixture construction for `SAMPLE_UMBER`/`SAMPLE_ULTRAMARINE` — a real deutan
  confusion-line pair — is done and verified in ITEST-3 and consumed here; if no such pair can be constructed
  that also reads clearly-different normally, raise it to the spec author then.)

## Phase 1 — Profile + detector shell (CVD-1)

- **Kind:** shell
- **Target AC:** —
- **Depends on:** COMPARE-1 · **Blocks:** COMPARE-2, CVD-2
- **Files:** `lib/a11y/cvd/cvd_profile.dart`, `lib/a11y/cvd/confusion_check.dart`, `lib/app/build_app.dart`
- **Tasks:**
  1. `CvdProfile` value type (type enum + severity), with value equality and a sensible default.
  2. `ConfusionCheck` interface + a `NoopConfusionCheck` (always returns false) as the shipped default, so the
     app assembles with confusion detection wired but inert until CVD-2.
  3. Add `AppDependencies.cvdProfile` (defaulting to a deutan profile) and a `confusionCheck` field; wire both
     through `buildApp`/`AppScope` without changing behaviour.
  4. Dartdoc each surface naming the AC, D-4/D-5, and the bs-07/bs-08/bs-10 reconciliation.
- **Exit criteria:** `flutter analyze` clean; unit gate 100% on new files; existing suites green (the inert
  default changes nothing).
- **Acceptance gate:** *(shell — none)*

### Result

- **Landed:** `lib/a11y/cvd/cvd_profile.dart` (`CvdType` { protan, deutan, tritan }
  + `CvdProfile` { type, severity 0–1, default severity 1.0 }, value equality);
  `lib/a11y/cvd/confusion_check.dart` (`ConfusionCheck` interface
  `bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile p)` +
  inert `NoopConfusionCheck` → always false); `lib/app/build_app.dart` gains
  `AppDependencies.cvdProfile` (default deutan) and `confusionCheck` (default
  `NoopConfusionCheck`), wired through the existing `AppScope`. Behaviour
  unchanged — the default detector flags nothing. Dartdoc on each surface names
  D-4/D-5, AC-7/AC-8, and the bs-07 (populate profile) / bs-08 / bs-10 (reuse
  projection) reconciliation.
- **Tests:** `test/a11y/cvd/cvd_profile_test.dart` (8), `test/a11y/cvd/confusion_check_test.dart`
  (2), and 3 new cases in `test/app/build_app_test.dart` (default profile,
  default check, explicit injection).
- **Unit gate:** 215 green (202 → 215, +13). **Coverage:** `dart run
  tool/coverage_gate.dart main` → 100% on all touched files
  (`cvd_profile.dart`, `confusion_check.dart`, `build_app.dart`,
  `difference.dart`), PASS.
- **Existing suites green:** `flutter analyze` clean; `flutter test integration_test/`
  17 green (iOS sim) — the inert default changes nothing.
- **Acceptance gate:** none (shell). **Augmentations:** none.
- **Fix passes:** 0/3 (passed first run). **Tokens / Time:** 3,816,225 / 8m 30s.

### Checkpoint / Handoff

- **Frozen for consumers (COMPARE-2, CVD-2, CVD-3):**
  `CvdType` { protan, deutan, tritan }; `CvdProfile({required type, severity = 1.0})`
  with value equality (import `package:paint_color_assistant/a11y/cvd/cvd_profile.dart`);
  `ConfusionCheck.confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile p) → bool`
  with `NoopConfusionCheck` the shipped default
  (`package:paint_color_assistant/a11y/cvd/confusion_check.dart`);
  `AppDependencies.cvdProfile` (default deutan) and `.confusionCheck` (default
  `NoopConfusionCheck`), both injected via `AppScope`.
- **To fill in behaviour phases:** CVD-2 adds the real dichromat-projection
  detector (Viénot/BVM LMS, D-4/D-5) as a new `ConfusionCheck` impl and injects
  it, replacing `NoopConfusionCheck` in the comparison assembly; the fixture
  `SAMPLE_UMBER`/`SAMPLE_ULTRAMARINE` deutan pair is constructed/verified in
  ITEST-3 and consumed here. CVD-3 adds `comparison_speech.dart` reusing the
  `Speech` seam.
- **Verification commands** (export PATH first —
  `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
  `flutter test --coverage` · `flutter test integration_test/` ·
  `dart run tool/coverage_gate.dart main`.
- **Known gaps:** detection is inert (`NoopConfusionCheck`) until CVD-2; the
  injected `CvdProfile` is a fixed deutan default until bs-07 populates it.
  Carry-over bs-01 flake: a const-ctor line can intermittently read uncovered on
  `--coverage`; re-run once.
- **Next:** COMPARE-2 is now unblocked (needs DIFF-1 **and** CVD-1 — both done):
  `ComparisonController`/state, `SampleSource` + in-memory catalogue,
  `ComparisonReadEndpoint`, and the `buildApp` comparison entry/route.

## Phase 2 — Confusion detector + warning (CVD-2)

- **Kind:** behavior
- **Target AC:** AC-7, AC-8
- **Depends on:** CVD-1, COMPARE-3 (Givens) · **Blocks:** CVD-3
- **Files:** `lib/a11y/cvd/confusion_check.dart`; `lib/compare/confusion_region.dart`; the `confusable` flag
  on the controller's `Comparison`/read endpoint.
- **Tasks:**
  1. Implement the dichromat projection for each `CvdProfile.type` (deutan path required for the scenarios;
     protan/tritan covered for the unit gate).
  2. Implement `confusable` per D-5 (projected ΔE00 below threshold AND normal ΔE00 clearly-different).
  3. Expose the flag on the controller and render the confusion-warning text when true; render nothing when
     false (AC-8).
- **Exit criteria:** unit gate 100% on touched code (each type's projection, the true/false branches, the
  threshold boundaries); `TestAC07_ConfusionFlagged` + `TestAC08_NotConfusable` green run-pending; earlier
  ACs green.
- **Acceptance gate:** un-pend AC-7, AC-8; suite green for those tests and all earlier ACs.

### Result

- **Landed:** `DichromatConfusionCheck` (the shipped `ConfusionCheck`) in
  `lib/a11y/cvd/confusion_check.dart` — a Viénot 1999 / Brettel–Viénot–Mollon LMS
  dichromat projection (`projectDichromat`, one plane per `CvdType`, severity
  blended) + the D-5 decision: `confusable` ⇔ normal ΔE00 ≥ 10 **and** projected
  ΔE00 < 3. Reuses DIFF's one CIEDE2000 metric via a new public
  `deltaE00(ColorCoordinates, ColorCoordinates)` in `lib/compare/difference.dart`
  (re-exposes the existing `_ciede2000`; no change to `compare`). The canonical
  `confusionWarningMessage` lives here (reused by CVD-3). `confusion_region.dart`
  now states the warning when `state.confusable`, nothing otherwise (AC-8).
  `build_app.dart` makes `DichromatConfusionCheck` the shipped default
  (`AppDependencies` + `ComparisonHomeScreen`), replacing `NoopConfusionCheck`.
- **Measured separation** (product = reference, same Viénot matrix): umber/terre-
  verte normal 27.99 / projected 1.357 → flagged; terracotta/sienna normal 13.05
  / projected 9.28 → not flagged.
- **Unit gate:** 286 green (272 → 286). **Coverage:** `dart run
  tool/coverage_gate.dart main` → 100% line+branch on all 15 touched files, PASS.
- **Acceptance gate:** AC-7, AC-8 un-pended (`bs03/pending.dart` rows deleted +
  added to `comparison_test.dart`'s `unpended` set). `flutter test
  integration_test/` on the iOS sim: **39 pass / 4 skipped** (AC-3, AC-5, AC-6,
  AC-9 still pending) — AC-7, AC-8 now run and pass against the real detector.
- **Grades:** independent fresh-context grade of all 8 un-pended ACs →
  **8×A, 0×B**, PASS; no neighbour grade changed. One recorded G5 limitation (the
  AC-7/AC-8 pair cannot reject a detector that omits the normal-ΔE00 gate — no
  bs-03 fixture is projected-close *and* normal-close; kept A, consistent with the
  ITEST-3 grid on unchanged fixtures). Grid:
  `behavior-test-completeness-bs-03-relative-comparison.md` § CVD-2.
- **Augmentations:** none (AC-8 is AC-7's discriminating control, per plan).
- **Fix passes:** 1/3 (pass 1 made `NoopConfusionCheck`'s const ctor run at
  runtime in its test — now every production use is compile-time `const`, so the
  line read uncovered; constructed non-`const` in the test).
- **Tokens / Time:** 10,847,797 / 27m 02s.

### Checkpoint / Handoff

- **Frozen for consumers (CVD-3, bs-07, bs-08/bs-10):**
  `DichromatConfusionCheck()` is the shipped `ConfusionCheck`
  (`package:paint_color_assistant/a11y/cvd/confusion_check.dart`); the projection
  is `projectDichromat(ColorCoordinates, CvdProfile) → ColorCoordinates`
  (exposed, not private — bs-08/bs-10 reuse it); the decision thresholds
  (normal ≥ 10, projected < 3) are private to the detector. The on-screen /
  spoken warning copy is `confusionWarningMessage` — **CVD-3 must reuse this
  constant**, not re-author the sentence. `deltaE00(ColorCoordinates,
  ColorCoordinates)` is now public in `difference.dart`.
- **To fill in CVD-3 (AC-9):** add `comparison_speech.dart` building one utterance
  = the relational statement (DIFF's `Comparison`) + `confusionWarningMessage`
  when `state.confusable`; wire the E6 speak control (in `actions_bar.dart`) to
  call the injected `Speech.speak` exactly once. CVD-3 depends on **DIFF-3** too
  (the statement text — AC-9's test asserts the spoken output contains
  `'Hue shifted'`), so CVD-3 is startable only after both DIFF-3 and this phase.
- **Verification commands** (export PATH first —
  `export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
  `flutter test --coverage` · `dart run tool/coverage_gate.dart main` ·
  `flutter test integration_test/ -d <ios-sim-id>` (device-bound: the verify
  lane).
- **Known gaps:** the injected `CvdProfile` is a fixed deutan default until bs-07
  populates it; the Viénot projection is graded against the harness's same-method
  reference (a consistency check, not an independent scientific authority — the
  ΔE00 metric half *is* externally validated). Carry-over flake: a `const`-ctor
  line can read uncovered on `--coverage`; re-run once (hit this phase and fixed
  by exercising the ctor at runtime).

## Phase 3 — Speak the whole comparison (CVD-3)

- **Kind:** behavior
- **Target AC:** AC-9
- **Depends on:** CVD-2, DIFF-3 (the statement) · **Blocks:** SIGNOFF-1
- **Files:** `lib/a11y/cvd/comparison_speech.dart`; the speak control (E6) in `lib/compare/actions_bar.dart`
  (COMPARE-6 already added the open-readout buttons here — keep them) + the controller's speak action.
- **Tasks:**
  1. Build the spoken utterance = relational statement + confusion-warning text (when present).
  2. Wire the E6 speak control to call bs-01's injected `Speech.speak` exactly once with that utterance.
- **Exit criteria:** unit gate 100% on touched code (with-warning and without-warning branches);
  `TestAC09_SpeakIncludesWarning` green run-pending; earlier ACs green.
- **Acceptance gate:** un-pend AC-9; suite green for that test and all earlier ACs.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
