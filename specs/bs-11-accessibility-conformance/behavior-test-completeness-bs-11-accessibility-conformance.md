# bs-11 Accessibility conformance — behaviour-test completeness

**Phase graded: ITEST-2 (acceptance-suite AC tests: AC-1,2,4,5,6).** Independent,
adversarial grade of the five *pending* `acTestWidgets` ITEST-2 added to the new
`group('bs-11 acceptance criteria — structural rules (ITEST-2)', …)` in
`integration_test/bs11/accessibility_test.dart` — the structural-rule AC tests
for **AC-1, AC-2, AC-4, AC-5, AC-6** only. The ITEST-1 harness, fixture and smoke
tests already passed at **12 A** (prior grid, below the git history) and are
**not** re-graded here. The `runConformanceCheck` is still the GATE-1 stub
returning `ConformanceResult.empty`, so each AC test fails at the red baseline on
its first positive Then — the correct red baseline for a rule not yet
implemented; each row is graded against whether the test, once its owning
behaviour phase (A11Y-2/3/5/6) lands the rule, would pass **only** on a correct
implementation (G1–G6). The grader ran nothing and edited nothing but this file.

Working-tree phase (uncommitted) atop **ITEST-1** on
`feat/bs-11-accessibility-conformance` (worktree `/Users/matthew.quirk/Nuance-bs11`).
Files: `integration_test/bs11/accessibility_test.dart` (the five new AC tests);
vocabulary/fixtures in `integration_test/bs11/accessibility_harness.dart`;
domain types in `lib/a11y/conformance/conformance_result.dart`.

Grade key: **A** = meets the bar; **B (rule)** = fails a named rule (G1–G6). None
of these five are "B pending": each carries a discriminating control (compliant
reference passes / targeted control fails) that separates a correct rule from a
vacuous one, so the correct grade for a well-built one is **A** even though the
rule is stubbed at the red baseline. (The only B-pending rows in this feature are
AC-9→GATE-3 and AC-11→GATE-4, which are in ITEST-3, not this phase.)

| Test | What it checks | Grade | Rule notes |
|---|---|---|---|
| **AC-1** `every colour-coded element carries a non-colour cue` (owner A11Y-5) | Sweep: for each of the 6 `realScreens`, `givenScreen` opens it (Given: `screen findsOneWidget`), the check runs, and `outcomeFor(colourCue).pass isTrue`. Then the `compliantReference` (Given: a descendant `ColorChip` `findsOneWidget`) passes `colourCue`. Control: `control_bareDot` (Given: subtree `findsOneWidget`) has `colourCue` in `failing`. | A | **G1** every Given checked through the public surface before the When — each real screen's home finder, the reference's `ColorChip` descendant, and the control's keyed subtree are all asserted present first. **G4** asserts the exact `ConformanceRuleId.colourCue` outcome, and at step grain (every swept screen, not one). **G5** genuine discriminator: the rule must pass on all 6 real screens **and** the compliant reference **and** fail on `control_bareDot` (a bare coloured dot with no text/icon) — a rule that never flags anything fails the control leg, a real screen that leaks a bare swatch fails the sweep. **G6** one AC. **G3** N/A (no negative-after-wait Then). Sweep loop is over `realScreens`, whose size/identity ITEST-1's fixture guard pins (non-vacuous). Comments claim only what is asserted; deterministic (launchers/`pumpAndSettle`, no sleeps). |
| **AC-2** `a status is never rendered as a bare colour dot` (owner A11Y-5) | Sweep: each real screen opened and `outcomeFor(noBareDot).pass isTrue`. Reference (Given: a descendant `StatusBadge` `findsOneWidget` — status as text+icon, not a dot) passes `noBareDot`. Control: `control_bareDot` has `noBareDot` in `failing`. | A | **G1** the reference Given specifically asserts the status is a `StatusBadge` (the public "status = text/icon" primitive, D-7), not merely that something rendered — the configured Given that answers the scenario. **G4** exact `noBareDot` id, every screen. **G5** discriminating: passes on real screens + `StatusBadge` reference, fails on the bare-dot control — rejects a rule that accepts a coloured `Container`/dot with no text/icon (the catalogue's named wrong impl). **G6** one AC. Correctly reuses `control_bareDot` (documented as failing both AC-1 and AC-2) while pinning the AC-2-specific positive (`StatusBadge`) distinct from AC-1's (`ColorChip`). Deterministic; honest comments. |
| **AC-4** `interactive targets meet the 48dp minimum` (owner A11Y-3) | Sweep: each real screen opened and `outcomeFor(tapTarget48).pass isTrue`. Reference (Given: a descendant `IconButton` `findsOneWidget` — an interactive target is present) passes `tapTarget48`. Control: `control_smallTarget` (a 24dp tappable) has `tapTarget48` in `failing`. | A | **G1** reference Given asserts an actual interactive target exists before measuring — so a "pass" can't be vacuous on a screen with no targets. **G4** exact `tapTarget48` id, swept over every screen. **G5** discriminating: 48dp reference passes, 24dp control fails — rejects a rule that never applies the 48dp guideline (the catalogue's wrong impl). **G6** one AC. **G3** N/A. Non-vacuous sweep; deterministic; comments match code. |
| **AC-5** `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2) | Sweep: each real screen opened; **G2 Given asserts `Theme.of(screen).colorScheme == AppTheme.light().colorScheme`** (the shipped AA theme is the source), then `outcomeFor(contrastAA).pass isTrue`. Reference asserts the same theme, then passes `contrastAA`. Control: `control_lowContrast` (~1.6:1 grey-on-white) has `contrastAA` in `failing`. | A | **G2 (the decisive rule here) satisfied:** contrast is asserted to come from the real, shipped `AppTheme.light().colorScheme` on each swept screen and the reference — not a test-injected `ThemeData` a test could over-tune. `ColorScheme` has content `==`, so the equality is meaningful and would fail a screen wired to the default/ad-hoc theme (exactly the pre-A11Y-2 state the catalogue warns of). **G1** screen-open + theme-source Givens checked before the When. **G4** exact `contrastAA` id, every screen. **G5** discriminating: passes on AA reference, fails on `control_lowContrast` (below 4.5:1) — rejects a rule that never applies the contrast guideline. **G6** one AC. **G3** N/A. Deterministic; honest comments. |
| **AC-6** `every control exposes a meaningful screen-reader label` (owner A11Y-6) | Sweep: each real screen opened and `outcomeFor(meaningfulLabel).pass isTrue`. Reference (Given: a descendant `IconButton` `findsOneWidget`, tooltip `Add sample`) passes `meaningfulLabel`. Control: `control_unlabelled` (an `IconButton` with no tooltip/label) has `meaningfulLabel` in `failing`. | A | **G1** reference Given asserts an interactive control is actually present before checking it carries a label — no vacuous pass on a control-free subtree. **G4** exact `meaningfulLabel` id, every screen. **G5** discriminating: labelled reference passes, unlabelled `IconButton` control fails — rejects a rule that accepts an empty/absent semantic label (the catalogue's wrong impl). **G6** one AC. **G3** N/A. Non-vacuous sweep; deterministic; comments match code. |

## Verdict

**5 A / 0 B — PASS (all A).** Every one of the five ITEST-2 structural AC tests
is built to the bar. Each follows the same discriminating shape the catalogue
mandates: the rule must pass on **all six real `buildApp` screens** (the D-1
sweep) **and** on the compliant positive control, and **fail on its targeted
`control_*` fixture** — so a rule that always passes (ignores the violation)
fails the control leg, and a real screen that leaks the violation fails the sweep
leg (G5). No vacuous passes: every Given is checked through the public surface
before the When (screen open, the reference's expected element present, the
control's subtree rendered), and the sweep loops are over `realScreens`, whose
size/identity ITEST-1's fixture guard pins (G1). Each asserts the specific
`ConformanceRuleId` outcome at the step's grain (G4) and covers exactly one AC
(G6). AC-5 additionally satisfies G2, the rule that most often sinks a contrast
test: it asserts the contrast source is the shipped `AppTheme.light().colorScheme`
(content-equal `ColorScheme`), not a test-injected theme. G3 is N/A for all five
(no negative-after-settle Then — those are AC-8's and live in ITEST-3).
Deterministic throughout (`pumpAndSettle`/tree-resetting `given…` helpers, no
fixed sleeps), and comments claim only what the code checks (each honest that, at
the GATE-1 stub, the Then fails because the rule is absent — the correct red
baseline). Nothing must change for this phase to pass.

No B rows.

## ITEST-3 — AC tests: scaling, eyes-free, timing, gate, floor (AC-3, AC-7, AC-8, AC-9, AC-11)

**Phase graded: ITEST-3 (acceptance-suite AC tests: AC-3,7,8,9,11).** Independent,
adversarial grade of the five *pending* `acTestWidgets` ITEST-3 added to the new
`group('bs-11 acceptance criteria — scaling, eyes-free, timing, gate, floor (ITEST-3)', …)`
in `integration_test/bs11/accessibility_test.dart`. The ITEST-1 harness/smoke
(12 A) and the ITEST-2 structural AC tests (5 A, above) are **not** re-graded. At
the red baseline the GATE-1 stubs are still in place — `runConformanceCheck` →
`ConformanceResult.empty`, `eyesFreeComplete` throws `UnimplementedError`, and
`acceptanceDecision`/`recordedLevel` throw `UnimplementedError` — so AC-3/AC-8
fail on their first positive **Then** (null rule outcome), AC-7 fails at the
**When** (driver stub throws, message names GATE-2), and AC-9/AC-11 fail at a
**Given precondition** (an empty aggregate result cannot be partial/fully-passing;
reason names GATE-3/GATE-4). Grade key: **A** = meets the bar; **B (rule)** =
fails a named rule; **B pending <phase>** = well-built but can only be *limited*
now because the discriminating state cannot exist until a later phase, with a
matching augmentation row owned by that phase. The grader ran nothing and edited
nothing but this file.

| Test | What it checks | Grade | Rule notes |
|---|---|---|---|
| **AC-3** `the layout survives 200% font scaling without breaking` (owner A11Y-4) | Sweep: for each of the 6 `realScreens`, `givenScreen` opens it (Given: `screen findsOneWidget`), the check runs, and `outcomeFor(fontScale200).pass isTrue` — the 200% pump + overflow capture live **inside** the rule (A11Y-4), so the test reads the `fontScale200` outcome over the unscaled subject rather than pre-scaling (honest comment; `whenScaledTo` is left for A11Y-4's rule-level tests). Reference passes `fontScale200`. Control: `control_overflow200` (a fixed-height row that clips once text doubles; Given: subtree `findsOneWidget`) has `fontScale200` in `failing`. | A | **G4** asserts the exact `ConformanceRuleId.fontScale200` at step grain, every swept screen. **G5** genuine discriminator: passes on all 6 real screens **and** the reference, **fails on `control_overflow200`** — rejects a rule that never applies the 200% check. **G6** one AC. **G3** N/A (no negative-after-settle Then). **G1** the two *discriminating* Givens are asserted through the public surface before the When — every swept screen's home finder and the control's keyed subtree. Minor, non-blocking asymmetry vs ITEST-2 / AC-8: the reference leg does **not** assert `compliantReferenceFinder findsOneWidget` before its check (scaling has no rule-specific element to pin, unlike `colourCue`'s `ColorChip`). This is **not** a G1 failure — the reference leg is a redundant positive, the test's discrimination (reject a rule that ignores overflow) rests entirely on the fully-checked control + sweep, and at baseline the reference leg fails honest-red on a null `fontScale200` Then rather than passing vacuously. Deterministic; comments match code. |
| **AC-7** `a core task completes eyes-free under the screen reader` (owner GATE-2) | `ensureSemantics()` (+ `addTearDown(dispose)`). Given: Readout opened via `buildApp` (`readout.screen findsOneWidget`) and the entry control present **by its semantic label** (`find.bySemanticsLabel('Speak this readout') findsOneWidget`). When: `whenCompletedEyesFree(steps: ['Speak this readout'])` → `eyesFreeComplete` driver (labels + `SemanticsAction`, never keys/coords, D-6). Then: `completed isTrue`. Control: the same driver given a step whose label is on no control (`'__no control exposes this label__'`) returns `blocked isFalse`. | A | **G1** both Givens checked through the semantics surface before the When (screen present; entry control present **by label**, not by key/type). **When** goes through the real driver, not coordinates. **Then** asserts the task reached terminal state (`completed`, the driver's read-endpoint-backed observable, D-6). **G5** the label-less control is the real discriminator: a driver that ignored labels and progressed by widget position/order would also "complete" the bogus step ⇒ `blocked` true ⇒ test fails — so the control **rejects a coordinate/position-fallback driver** (and an always-true driver), exactly D-6's intent. **G6** one AC. **Not B-pending**: no augmentation row, and the test discriminates fully the moment GATE-2 lands the driver (its single owning phase) — like AC-1..6 whose rules are stubbed. Baseline fails at the When via the stub's deliberate `UnimplementedError` (message names GATE-2), the suite's accepted pending signal, not a harness error. |
| **AC-8** `nothing auto-dismisses or imposes a time limit` (owner A11Y-7) | Sweep: each real screen opened and `outcomeFor(noTimeout).pass isTrue`. Reference: Given a descendant `AccessibleNotice findsOneWidget` asserted **before** the settle; **settle point** `whenWaited(10s)` (past the SnackBar 4s default); Then the `AccessibleNotice` is **still present after the advance** and `noTimeout` passes. Control: `control_autoDismiss`'s SnackBar present first (`find.text('Auto-dismissing notice') findsOneWidget`), then **gone** (`findsNothing`) after the same 10s advance, and `failing contains noTimeout`. | A | **G3 fully satisfied** — the task's live question: there is a real settle point (fake clock advanced 10s, well past the 4s auto-dismiss window), the negative "still present" Then is taken **only after** the advance, and the control proves the reading can change (the standard SnackBar **is gone** after the identical advance) — so the reference's persistence is a real observation, not a stuck frame. **G1** reference and control Givens (`AccessibleNotice` present; SnackBar present) asserted before their settle/advance; sweep screens checked. **G4** exact `noTimeout` id at step grain, every screen; persistence asserted via the specific `AccessibleNotice` finder, dismissal via `find.text`. **G5** `control_autoDismiss` fails `noTimeout`; reference passes — rejects a rule that never flags a timer. **G6** one AC (the SnackBar-gone assertion is the G3 change-control for the same AC, not a second AC). Deterministic (fake-clock `pump`); honest comments. |
| **AC-9** `a feature failing the automated check is not accepted` (owner GATE-3) | Given: `control_partialFail` run through the check yields a **genuinely partial** result — `partial.failing isNotEmpty` **and** `anyPassing` (≥1 `ConformanceRuleId` passes), both asserted through the public check surface, reasons naming GATE-3 + the sub-rules. When: `acceptanceDecision(partial)`. Then: `notAccepted`. Control: a fully-passing result (reference, `full.passed isTrue`) ⇒ `acceptanceDecision(full) == accepted`. | **B pending GATE-3** | Legitimately *limited* now: the aggregate `acceptanceDecision` cannot discriminate, and the partial-result Given cannot hold, until every sub-rule exists (A11Y-2..7 + GATE-2) and GATE-3 composes them in `runConformanceCheck`. At baseline the empty stub makes `partial.failing` empty ⇒ the test fails on the **Given precondition** whose reason names GATE-3 (the honest limit). Otherwise fully built: **G1** every Given asserted via the public surface; **G5** discriminating — partial ⇒ `notAccepted` vs full ⇒ `accepted`, rejecting a constant `notAccepted` and a decision that accepts a partial result or inspects only one rule; **G4** exact `AcceptanceDecision` values; **G6** one AC. Matching augmentation row **TestAC09 → GATE-3** present in `modules/ITEST.md` (status ⬜ Open); re-graded A once GATE-3 closes it. |
| **AC-11** `WCAG 2.2 AA is the recorded accepted floor` (owner GATE-4) | Given: a fully-passing `ConformanceResult` (reference, `passing.passed isTrue` asserted), reason naming GATE-4. When: `recordedLevel(passing)`. Then: `WcagLevel.aa22`. Control: a failing result (`control_partialFail`, `failing.passed isFalse`) records `WcagLevel.below`. | **B pending GATE-4** | Legitimately *limited* now: `recordedLevel` is a throwing stub until GATE-4, and a fully-passing result needs every sub-rule to exist — so the Given cannot hold yet. At baseline the empty stub makes `passing.passed` false ⇒ the test fails on the **Given precondition** before the throwing `recordedLevel` is reached, reason naming GATE-4. Otherwise fully built: **G1** both Givens (`passed`/`!passed`) asserted via the public surface; **G5** discriminating — passing ⇒ `aa22` vs failing ⇒ `below`, rejecting a constant `aa22` and recording AA for a result that failed a rule; **G6** one AC. The catalogue's "thresholds equal the WCAG 2.2 AA constants" assertion is correctly **deferred to the augmentation**, not asserted here. Matching augmentation row **TestAC11 → GATE-4** present in `modules/ITEST.md` (status ⬜ Open); re-graded A once GATE-4 closes it. |

### ITEST-3 verdict

**3 A / 2 B-pending — PASS.** AC-3, AC-7 and AC-8 are grade **A**: fully built,
each with a discriminating control (overflow row fails `fontScale200`; a
label-less step blocks the eyes-free driver; the SnackBar auto-dismisses while the
`AccessibleNotice` persists) and asserting its exact observable at step grain, one
AC each. **AC-8 nails G3** — a true settle point (10s fake-clock advance past the
4s window), the negative Then taken only after it, and a change-control (the
SnackBar *is* gone) proving the reading can move. **AC-7** is correctly **A, not
B-pending**: it has no augmentation row and discriminates fully as soon as its one
owning phase (GATE-2) lands the driver, exactly like the stubbed-rule AC-1..6.
**AC-9 (B pending GATE-3)** and **AC-11 (B pending GATE-4)** are legitimate
B-pending: the aggregate `acceptanceDecision` / `recordedLevel` and a genuinely
partial / fully-passing result cannot exist until every sub-rule plus the owning
GATE phase land, so each fails red on a **Given precondition naming its phase**;
both are otherwise well-built (G1/G4/G5/G6 met) and each has a matching
augmentation row owned by the named phase in `modules/ITEST.md` (TestAC09→GATE-3,
TestAC11→GATE-4, both ⬜ Open), to be re-graded A when closed.

**No ordinary B rows — nothing needs a fix in this phase.** The one noted blemish
(AC-3's reference leg omits a `findsOneWidget` assertion that ITEST-2 and AC-8
include) does not reach a G1 failure: the discriminating Givens (every swept
screen + the control subtree) are all checked and the baseline is honest-red, not
a vacuous pass. It is recorded as an optional symmetry improvement, not a required
fix.
