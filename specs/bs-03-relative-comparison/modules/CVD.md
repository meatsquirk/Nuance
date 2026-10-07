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
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-7, AC-8 | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

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
