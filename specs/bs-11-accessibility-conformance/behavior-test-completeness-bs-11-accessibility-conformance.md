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
