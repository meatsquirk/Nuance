# Module GATE — the conformance gate + eyes-free driver

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/a11y/conformance/conformance_result.dart`, `lib/a11y/conformance/acceptance.dart` (pure domain: `ConformanceResult`, `ConformanceRuleId`, `AcceptanceDecision`, `WcagLevel`, `acceptanceDecision`, `recordedLevel`); `integration_test/conformance/conformance_check.dart` (the aggregate `runConformanceCheck` that composes A11Y's per-rule rules into a `ConformanceResult`); `integration_test/conformance/eyes_free.dart` (the semantics-only driver).
**Depends on:** A11Y (the per-rule check rules; the aggregate needs all of them) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| GATE-1 | shell | — | ⬜ Todo | | |
| GATE-2 | behavior | AC-7 | ⬜ Todo | | |
| GATE-3 | behavior | AC-9 | ⬜ Todo | | |
| GATE-4 | behavior | AC-11 | ⬜ Todo | | |

## Interface reconciliation

- `ConformanceResult` — an immutable map `ConformanceRuleId → ConformanceRuleOutcome{pass, detail}`; `bool get passed` ⇔ every rule passed. Pure domain (`lib/`), no `flutter_test` import.
- `ConformanceRuleId` — enum over the automated rules: `colourCue`, `noBareDot`, `fontScale200`, `tapTarget48`, `contrastAA`, `meaningfulLabel`, `eyesFree`, `noTimeout`. (AC-10/AC-12 are **not** rules — manual, D-2.)
- `AcceptanceDecision acceptanceDecision(ConformanceResult)` → `accepted` iff `result.passed`, else `notAccepted` (AC-9). Pure.
- `WcagLevel { below, aa22 }`; `WcagLevel recordedLevel(ConformanceResult)` → `aa22` iff `result.passed`, else `below` (AC-11). The check's thresholds are the WCAG 2.2 AA constants (D-5); `recordedLevel` names the floor those thresholds encode.
- `runConformanceCheck(WidgetTester, Finder)` (test-support, `integration_test/`) composes A11Y's per-rule `check<Rule>` functions into a `ConformanceResult` for a rendered screen. This is the reusable artifact every other feature's gate can import (D-3).
- `eyesFreeComplete(WidgetTester, {steps})` (test-support) drives a task by semantic label + `SemanticsAction` only (D-6), returning whether the terminal state was reached.
- GATE touches **no** feature screen and no `lib/app/theme.dart` → disjoint from the A11Y sweep (may run ∥ one A11Y phase), except GATE-3 which *reads* every A11Y rule (barrier).

## Open gates

**G-2** (approve tests) blocks GATE-2..4. The two manual gates **G-3** (AC-10) and **G-4** (AC-12) are resolved at SIGNOFF-1, not in GATE (D-2).

## Phase GATE-1 — shell: conformance model + check stub

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CONF-1 · **Blocks:** ITEST-1, GATE-2..4
- **Files:** `lib/a11y/conformance/conformance_result.dart`, `lib/a11y/conformance/acceptance.dart`, `integration_test/conformance/conformance_check.dart`, `integration_test/conformance/eyes_free.dart`
- **Tasks:**
  1. Define `ConformanceResult`, `ConformanceRuleId`, `ConformanceRuleOutcome`, `AcceptanceDecision`, `WcagLevel` (types only; `acceptanceDecision`/`recordedLevel` present but stubbed — throw `UnimplementedError`).
  2. `runConformanceCheck` stub returning an empty/all-absent result (so AC tests compile and fail on their Then at baseline).
  3. `eyesFreeComplete` stub.
- **Exit criteria:** unit gate on new `lib/a11y/conformance/**` lines (the stub domain); suites stay green; no behaviour change.

## Phase GATE-2 — AC-7 eyes-free walkthrough (automated)

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/conformance/eyes_free.dart`
- **Tasks:**
  1. Implement `eyesFreeComplete`: locate controls by semantic label, activate via `SemanticsAction` (no keys/coordinates — D-6), advance a core task (e.g. open a sample's Readout) to its terminal state.
  2. Assert completion via the feature read endpoint.
- **Exit criteria / Acceptance gate:** un-pend AC-7; `TestAC07_EyesFreeWalkthroughCompletes` green — the core task completes by semantics alone; the control (a required step with no semantic label) cannot progress; earlier ACs green.

## Phase GATE-3 — AC-9 automated-gate acceptance (barrier)

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** ITEST-4 (G-2) **and** every A11Y rule (A11Y-2..7) · **Blocks:** GATE-4, SIGNOFF-1
- **Files:** `integration_test/conformance/conformance_check.dart` (compose all rules), `lib/a11y/conformance/acceptance.dart` (`acceptanceDecision`)
- **Tasks:**
  1. Implement `runConformanceCheck` to compose all A11Y per-rule outcomes into a populated `ConformanceResult`.
  2. Implement `acceptanceDecision` (accepted iff `result.passed`).
- **Exit criteria / Acceptance gate:** un-pend AC-9; `TestAC09_FailedAutomatedCheckNotAccepted` green — a partially-failing result ⇒ `notAccepted`; a fully-passing reference ⇒ `accepted`; earlier ACs green.
- **Augments:** closes the AC-9 *B pending GATE-3* baseline grade (the aggregate can now discriminate).

## Phase GATE-4 — AC-11 recorded WCAG 2.2 AA floor

- **Kind:** behavior
- **Target AC:** AC-11 (full)
- **Depends on:** GATE-3 · **Blocks:** SIGNOFF-1
- **Files:** `lib/a11y/conformance/acceptance.dart` (`recordedLevel`, threshold constants)
- **Tasks:**
  1. Implement `recordedLevel` (→ `aa22` iff `result.passed`).
  2. Pin the WCAG 2.2 AA threshold constants (D-5) and assert the check rules use exactly them.
- **Exit criteria / Acceptance gate:** un-pend AC-11; `TestAC11_RecordedFloorIsWcag22AA` green — a passing result records `aa22` and thresholds equal the AA constants; a failing result records `below`; earlier ACs green.
- **Augments:** closes the AC-11 *B pending GATE-4* baseline grade.

### Result  <!-- filled on completion; one block per phase -->

### Checkpoint / Handoff  <!-- filled on completion -->
