# Module GATE — the conformance gate + eyes-free driver

**Status:** ◐ In progress (GATE-1, GATE-2 done)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/a11y/conformance/conformance_result.dart`, `lib/a11y/conformance/acceptance.dart` (pure domain: `ConformanceResult`, `ConformanceRuleId`, `AcceptanceDecision`, `WcagLevel`, `acceptanceDecision`, `recordedLevel`); `integration_test/conformance/conformance_check.dart` (the aggregate `runConformanceCheck` that composes A11Y's per-rule rules into a `ConformanceResult`); `integration_test/conformance/eyes_free.dart` (the semantics-only driver).
**Depends on:** A11Y (the per-rule check rules; the aggregate needs all of them) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| GATE-1 | shell | — | ✅ Done | 3,553,802 | 17m 14s |
| GATE-2 | behavior | AC-7 | ✅ Done | 10,094,248 | 23m 31s |
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

**GATE-1 — shell: conformance model + check stub** (✅ Done, 17m 14s / 3,553,802)

- **`lib/a11y/conformance/conformance_result.dart` (pure domain, no `flutter_test`):** `ConformanceRuleId` enum over the 8 automated rules (`colourCue`, `noBareDot`, `fontScale200`, `tapTarget48`, `contrastAA`, `meaningfulLabel`, `eyesFree`, `noTimeout`) — AC-10/AC-12 deliberately absent (manual, D-2); `ConformanceRuleOutcome{pass, detail}` value type (+ `.ok()`/`.fail(detail)` consts, content equality); `ConformanceResult` immutable map `ConformanceRuleId → ConformanceRuleOutcome` (`Map.unmodifiable`) with `outcomeFor`, `failing`, content equality, and the gate predicate **`bool get passed` ⇒ true iff every `ConformanceRuleId` has an outcome and all pass** (completeness required, so the empty/partial baseline reads not-conformant). `const ConformanceResult.empty()` is the all-absent result.
- **`lib/a11y/conformance/acceptance.dart` (pure domain):** `AcceptanceDecision{accepted, notAccepted}` (AC-9), `WcagLevel{below, aa22}` (AC-11); `acceptanceDecision(ConformanceResult)` and `recordedLevel(ConformanceResult)` **present but stubbed → throw `UnimplementedError`** (implemented GATE-3 / GATE-4). Signatures frozen so stage-3 AC tests compile and fail their Then at the red baseline.
- **`integration_test/conformance/conformance_check.dart` (test-support):** `Future<ConformanceResult> runConformanceCheck(WidgetTester, Finder)` stub returns `ConformanceResult.empty` (⇒ not `passed`) — the reusable per-screen check (D-3) that GATE-3 populates by composing the A11Y per-rule checks.
- **`integration_test/conformance/eyes_free.dart` (test-support):** `Future<bool> eyesFreeComplete(WidgetTester, {required List<String> steps})` stub throws `UnimplementedError` — the semantics-only driver (D-6) GATE-2 implements.
- **Gates:** `flutter analyze` (new files) clean; unit **1034/1034** (1018 baseline + 16 new covering every branch of the domain types + both stub throws); coverage gate **100% line** on all 9 touched `lib/**` files (the 2 new conformance files + the A11Y-1 files vs `main`). **Full cross-feature regression** (last shell phase): all 9 integration suites on booted iPhone 17 sim via `coord.sh with-lock` → **173/173, exit 0** (advanced_capture, capture, comparison, correction, display, harness, palette, readout, recipes) — confirms the new files broke nothing (they are unwired: no `lib/**` production code imports them, the test-support stubs are imported by no test yet). **Fix passes:** 0/3 (all gates green first run).
- **No behaviour change:** the new domain is referenced by no production code; the test-support stubs by no test — purely additive shells.

**GATE-2 — AC-7 eyes-free walkthrough (automated)** (✅ Done, 23m 31s / 10,094,248)

- **`integration_test/conformance/eyes_free.dart` — `eyesFreeComplete` implemented** (was the GATE-1 stub). For each step label it: finds the control via `find.bySemanticsLabel(label)` (returns `false` if the accessibility tree exposes no such node — "a screen-reader user cannot land here"); resolves the merged `SemanticsNode` via `tester.semantics.find`; returns `false` if the node reports no `SemanticsAction.tap` ("labelled but inert"); else dispatches the tap through `node.owner!.performAction(id, SemanticsAction.tap)` — the real assistive-tech path, **never** a key/type/coordinate tap (D-6) — and pumps. Returns `true` once every step is located and activated (terminal state reached eyes-free). Enables semantics for the run and disposes its own `SemanticsHandle` in a `finally`, so it is standalone and leaks nothing.
- **AC-7 un-pended** — deleted its row in `bs11/pending.dart` (pending set now `{AC-9, AC-11}`, length 2); updated the pending-gate scaffold guard in `accessibility_test.dart` (`expected` set → `{AC-9, AC-11}`, `hasLength(2)`, `!containsKey('AC-7')`).
- **Test-disposal fix (recorded, non-weakening):** the AC-7 test disposed its `SemanticsHandle` via `addTearDown(semantics.dispose)`; the integration binding runs its end-of-test invariant check **before** `addTearDown` callbacks, so once the driver completed (no longer throwing) the handle was flagged leaked. Changed to an explicit `semantics.dispose()` at the end of the test body — the repo convention for `SemanticsHandle` (e.g. `provenance_region_test`). **No assertion changed.** Also tightened one AC-7 comment that claimed the terminal state is "observed via the read endpoint inside the driver" to match what the code checks (reachability + semantics activation).
- **GATE-2 did NOT touch the aggregate** `runConformanceCheck` (still the 7 sweep rules); AC-7 runs through the separate `eyesFreeComplete` driver, sharing no state with the sweep. Composing the `eyesFree` `ConformanceRuleId` into the aggregate is GATE-3's job (barrier).
- **Gates:** `flutter analyze` clean; unit **1041/1041** (no unit-test change — the driver is test-support; its branches are exercised by the AC-7 positive + control legs); coverage gate **PASS** — GATE-2 adds no `lib/**` code, so the gate is vacuous (all 18 feature-touched lib files remain 100%). Acceptance (default mode, booted iPhone 17 sim via `coord.sh with-lock`): **17 pass / 2 skip** (AC-9 pending GATE-3, AC-11 pending GATE-4), exit 0 — AC-7 green, suite green with only later ACs pending. **Grade gate (fresh adversarial subagent, every un-pended AC test AC-1..8): 8 A / 0 B**, no downgrades; AC-7's positive+control pair rejects always-true/always-false and coordinate-fallback drivers (G5) and every Given is checked (G1). **Fix passes: 1/3** (first full run surfaced the handle-disposal leak; fixed; second run green).
- **Augmentations:** none (AC-7 was graded A at the ITEST-3 red baseline; no augmentation row).

### Checkpoint / Handoff  <!-- filled on completion -->

**After GATE-2 (branch `feat/bs-11-accessibility-conformance`):**

- **Frozen interface:** `eyesFreeComplete(WidgetTester, {required List<String> steps})` is now implemented and reusable test-support (D-6): semantics-only, returns `true` iff every step label resolves to a tap-activatable node and is activated. A caller need not pre-enable semantics (the driver does), but must still open the subject screen and assert its own Givens.
- **Verification commands** (from `../Nuance-bs11`, `flutter` at `/Users/matthew.quirk/development/flutter/bin`): analyze `flutter analyze`; unit+coverage `flutter test --coverage`; coverage gate `dart run tool/coverage_gate.dart main`; acceptance `flutter test integration_test/bs11/accessibility_test.dart -d <booted-udid>` under `coord.sh with-lock` (booted `-d` mandatory). Grade via a fresh adversarial subagent against G1–G6, writing `specs/.../behavior-test-completeness-bs-11-accessibility-conformance.md`.
- **Known gaps / next:** **GATE-3 (AC-9) is the barrier** — it implements `runConformanceCheck` to compose **all 8** `ConformanceRuleId`s into a populated `ConformanceResult` (so `passed` can be true) **and** `acceptanceDecision`. It must decide how the aggregate obtains an **`eyesFree`** outcome (the enum id exists but the current 7-rule aggregate never populates it; `ConformanceResult.passed` requires all 8 present) — e.g. by running `eyesFreeComplete` over a defined core-task flow and mapping its bool to a `ConformanceRuleOutcome`. Closes TestAC09's *B pending GATE-3*. Then **GATE-4 (AC-11)** implements `recordedLevel` + pins the WCAG 2.2 AA constants (closes TestAC11's *B pending GATE-4*) → **SIGNOFF-1**.

### GATE-1 Checkpoint / Handoff

**After GATE-1 (branch `feat/bs-11-accessibility-conformance`):**

- **Frozen interfaces for the next phases:**
  - `ConformanceRuleId` (8 ids), `ConformanceRuleOutcome{pass, detail}`, `ConformanceResult` (`passed` ⇒ all 8 ids present & passing; `outcomeFor`, `failing`, `.empty()`) in `lib/a11y/conformance/conformance_result.dart`.
  - `AcceptanceDecision`, `WcagLevel`, and the signatures `acceptanceDecision(ConformanceResult)` / `recordedLevel(ConformanceResult)` in `lib/a11y/conformance/acceptance.dart` — **A11Y phases do not touch these**; GATE-3 implements `acceptanceDecision` (accepted iff `result.passed`), GATE-4 `recordedLevel` (`aa22` iff `result.passed`) + the WCAG 2.2 AA threshold constants.
  - `runConformanceCheck(WidgetTester, Finder)` in `integration_test/conformance/conformance_check.dart` — A11Y-2..7 each add a per-rule `check<Rule>` the harness/GATE-3 compose here; GATE-3 populates every `ConformanceRuleId`.
  - `eyesFreeComplete(WidgetTester, {required List<String> steps})` in `integration_test/conformance/eyes_free.dart` — GATE-2 implements; it owns this file and may refine the `steps` shape if the driver needs richer per-step data.
- **Verification commands** (from `../Nuance-bs11`, `flutter` at `/Users/matthew.quirk/development/flutter/bin`): analyze `flutter analyze`; unit+coverage `flutter test --coverage`; coverage gate `dart run tool/coverage_gate.dart main`; acceptance/regression `flutter test integration_test/<suite>_test.dart -d <booted-udid>` (or the whole `integration_test` dir) under `coord.sh with-lock` — booted `-d` mandatory (no `-d` ⇒ false green).
- **Known gaps / next:** **both shells (A11Y-1 + GATE-1) are now complete ⇒ ITEST-1 unblocks** (the acceptance harness over the wired shells + the reusable conformance check). GATE-2/3/4 remain blocked by **G-2** (approve the tests at ITEST-4). G-3 (AC-10) / G-4 (AC-12) are manual, resolved at SIGNOFF-1.
