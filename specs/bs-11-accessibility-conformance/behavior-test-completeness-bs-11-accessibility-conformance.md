# bs-11 Accessibility conformance — behaviour-test completeness

**Phase graded: GATE-2 (un-pended AC tests AC-1,2,3,4,5,6,7,8).** Independent,
adversarial re-grade of **every currently un-pended automated AC test** against
the code as it now stands on `feat/bs-11-accessibility-conformance` (worktree
`/Users/matthew.quirk/Nuance-bs11`). **What GATE-2 changed:** it delivered
**AC-7** (the eyes-free semantics-only driver) by implementing `eyesFreeComplete`
in `integration_test/conformance/eyes_free.dart` (previously a stub throwing
`UnimplementedError`). The real driver, for each step label: finds the control via
`find.bySemanticsLabel(label)` and returns `false` if absent; resolves the
`SemanticsNode` via `tester.semantics.find`; returns `false` if the node has no
`SemanticsAction.tap`; otherwise dispatches the tap via
`node.owner!.performAction(...)` and pumps — returning `true` only when every step
was located and activated **by semantics alone** (never key/type/coordinate, D-6).
It disposes its own `SemanticsHandle` in a `finally`. GATE-2 then un-pended AC-7 in
`bs11/pending.dart` (deleted its row; pending set is now **`{AC-9, AC-11}`**,
length 2) and updated the scaffold-guard in `accessibility_test.dart` to expect the
new set and assert `!containsKey('AC-7')`. It also fixed the AC-7 test's handle
disposal — `addTearDown(semantics.dispose)` → an explicit `semantics.dispose()` at
the end of the test body (repo convention: the integration binding's end-of-test
invariant runs *before* `addTearDown`, so a parked handle leaks) — **no assertion
changed**. The behaviour phase re-grades **AC-1, AC-2, AC-3, AC-4, AC-5, AC-6,
AC-7, AC-8**. The grader ran nothing and edited nothing but this file.

**AC-1..6 and AC-8 are unchanged by GATE-2 — and structurally cannot be disturbed
by it (verified):** their rules and test bodies are byte-for-byte the ones graded
A under A11Y-7, re-confirmed against the current code. GATE-2 touched **only**
`eyes_free.dart` (the AC-7 driver), `pending.dart` (removed the AC-7 row), the
pending-gate guard test, and AC-7's own `semantics.dispose()` placement — it did
**not** touch any conformance rule or any AC-1..6/8 test body. Decisively, GATE-2
did **not** add `eyesFree` to the aggregate `runConformanceCheck`: that function
still composes exactly the **seven** sweep rules
(`contrastAA`/`tapTarget48`/`fontScale200`/`colourCue`/`noBareDot`/`meaningfulLabel`/`noTimeout`),
so the `ConformanceResult` every AC-1..6/8 test reads is identical to the A11Y-7
baseline. AC-7 is driven by the **separate** `eyesFreeComplete` driver, not a
conformance rule, so it shares no state with the sweep: it opens its own subject
(Readout), enables its own semantics, and reads only the driver's boolean —
nothing it does can leak into another test's `outcomeFor(...)` / `failing` reads.
(The `eyesFree` enum value exists in `ConformanceRuleId` but is left unpopulated by
the aggregate; whether the barrier must populate it is a **GATE-3/AC-9** question,
out of scope here and not graded.)

**Special attention — the NEW test (AC-7) genuinely discriminates (verified):**
- **G5 — the positive+control pair rejects the two named wrong drivers.** Positive
  leg: driving `['Speak this readout']` returns `completed isTrue`. Control leg:
  driving `['__no control exposes this label__']` (a label on no control) returns
  `blocked isFalse`. This pair rejects **(a) an always-true driver** — it would
  return `true` on the bogus-label control ⇒ `blocked` true ⇒ the control leg
  fails; **(b) an always-false driver** — it would return `false` on the real step
  ⇒ `completed` false ⇒ the positive leg fails; and **(c) a
  coordinate/position-fallback driver** — one that ignores the semantic label and
  taps the first interactive widget by position/order would "complete" the
  bogus-label step ⇒ `blocked` true ⇒ the control leg fails. Only a strictly
  semantics-by-label driver that *stops* when no node carries the label passes both
  legs — exactly D-6's intent. G5 satisfied.
- **G1 — every discriminating Given is checked before the When.** Readout open:
  `expect(readout.screen, findsOneWidget)`. Entry control present *by label*:
  `expect(find.bySemanticsLabel('Speak this readout'), findsOneWidget)` — this
  simultaneously confirms **semantics is active** (the test called
  `tester.ensureSemantics()`; `find.bySemanticsLabel` resolves nothing with
  semantics off), so the "screen reader is active" Given is verified through the
  public surface, not merely enabled. Both discriminating Givens are asserted
  before `whenCompletedEyesFree`.
- **G2** the behaviour under test comes from the real shipped driver over the real
  `buildApp` Readout screen and its real `'Speak this readout'` control (bs-08
  speech), not a fake/scripted structure. **G4** asserts the exact booleans
  (`completed isTrue`, `blocked isFalse`) at the step's grain — a single labelled
  step located and activated. **G6** exactly one AC (only the eyes-free driver is
  exercised). **G3** N/A (no negative-after-settle Then; the control is a
  discriminator, not a timed persistence check). **Handle hygiene:** the test holds
  its own `SemanticsHandle` and disposes it explicitly at the body's end, and the
  driver disposes its own in `finally` — no leak on the happy path.
- **Minor honesty note (not a downgrade, consistent with the prior ITEST-3 A):**
  the test comment says the terminal state is "observed via the read endpoint
  inside the driver", but the driver actually returns `true` once every labelled
  step is located and `tap`-activated — it does not read a downstream task-output
  endpoint. For AC-7 ("the task is *operable* eyes-free") the right observable is
  reachability-and-activation by semantics, which is exactly what the driver
  proves; the comment slightly overstates the mechanism but the assertion is at the
  correct grain for the AC. Recorded as a wording blemish, not a G-rule failure.

| AC | Test | Grade | Justification (failing G-rule if below A) |
|---|---|---|---|
| **AC-7** | `a core task completes eyes-free under the screen reader` (owner GATE-2), un-pended; driver = **real** `eyesFreeComplete` (find each step's control **by semantic label**, require a `tap` action, dispatch via `node.owner!.performAction` — never key/type/coordinate, D-6) | **A** | **G1** both discriminating Givens asserted before the When — Readout open (`readout.screen findsOneWidget`) and the entry control present *by label* (`find.bySemanticsLabel('Speak this readout') findsOneWidget`, which also confirms semantics is active under the test's `ensureSemantics()`). **G2** real driver over the real `buildApp` Readout + real `'Speak this readout'` control, not a fake. **G4** exact booleans at step grain (`completed isTrue`; control `blocked isFalse`). **G5** the positive+control pair rejects **all three** plausible wrong drivers — always-true (control leg), always-false (positive leg), and **coordinate/position-fallback** (the bogus-label control leg: a non-semantics driver would progress and make `blocked` true). **G6** one AC only. **G3** N/A. Handle disposed explicitly in-body (+ driver's own `finally`). Comment overstates the terminal-state mechanism ("read endpoint") but the assertion grain is correct — a wording blemish, not a downgrade. |
| **AC-1** | `every colour-coded element carries a non-colour cue` (owner A11Y-5), un-pended; rule = `checkColourCue` | **A** | Unchanged by GATE-2 (rule + body untouched). Re-confirmed against the identical seven-rule aggregate; reads only `failing.contains(colourCue)`. Sweep passes on 6 real screens + `ColorChip` reference; `control_bareDot` fails. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-2** | `a status is never rendered as a bare colour dot` (owner A11Y-5), un-pended; rule = `checkNoBareDot` | **A** | Unchanged by GATE-2. Re-confirmed; reads only `noBareDot`. Sweep + `StatusBadge` reference pass; `control_bareDot` fails. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-3** | `the layout survives 200% font scaling without breaking` (owner A11Y-4), un-pended; rule = `checkFontScale200` | **A** | Unchanged by GATE-2. Re-confirmed; reads only `fontScale200`. Sweep + reference pass; `control_overflow200` (180dp > 100dp box) fails. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-4** | `interactive targets meet the 48dp minimum` (owner A11Y-3), un-pended; rule = `checkTapTarget48` | **A** | Unchanged by GATE-2. Re-confirmed; reads only `tapTarget48`. Sweep + 48dp reference pass; `control_smallTarget` (24dp) fails. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-5** | `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2), un-pended; rule = `checkContrastAA` | **A** | Unchanged by GATE-2. Re-confirmed; reads only `contrastAA`. **G2 decisive, still satisfied** — contrast pinned to the shipped `AppTheme.light().colorScheme` on every swept screen + reference; `control_lowContrast` fails. **G1/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-6** | `every control exposes a meaningful screen-reader label` (owner A11Y-6), un-pended; rule = `checkMeaningfulLabel` over `labeledTapTargetGuideline` | **A** | Unchanged by GATE-2. Re-confirmed; reads only `meaningfulLabel`. Sweep + tooltipped reference pass; `control_unlabelled` fails. Documented non-empty-vs-meaningful limit (carried by manual AC-10/AC-12) unchanged. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-8** | `nothing auto-dismisses or imposes a time limit` (owner A11Y-7), un-pended; rule = `checkNoTimeout` | **A** | Unchanged by GATE-2 (rule + body untouched). Re-confirmed; reads only `noTimeout`. **G3 fully satisfied** — real 10s fake-clock settle past the 4s SnackBar window, the "still present" Then taken only after the advance, and a change-control (`control_autoDismiss`'s SnackBar **is gone** after the identical advance) proving the reading can move. `AccessibleNotice` reference persists and passes; `control_autoDismiss` fails `noTimeout`. **G1/G4/G5/G6** met. No downgrade. |

## Verdict

**8 A / 0 B — PASS (all A).** Every currently un-pended automated AC test meets
the bar against the code as it now stands. **The NEW GATE-2 test (AC-7) is A —
earned, not nominal:** the real `eyesFreeComplete` driver genuinely discriminates
via the positive+control pair — the real `'Speak this readout'` step completes
(`completed isTrue`) while a step whose label is on no control blocks
(`blocked isFalse`) — and that pair rejects **all three** plausible wrong drivers:
an always-true driver (fails the control leg), an always-false driver (fails the
positive leg), and a **coordinate/position-fallback** driver (would progress past
the bogus-label control ⇒ `blocked` true ⇒ fails the control leg), exactly D-6's
intent. Every discriminating Given is checked before the When (Readout open; the
entry control present *by label*, which also confirms semantics is active), it
asserts the exact booleans at step grain (G4), and covers one AC (G6). The one
wording blemish — the "read endpoint" comment overstating the terminal-state
mechanism — does not change the assertion grain and is not a downgrade.

**AC-1..6 and AC-8 hold their prior A, un-weakened and structurally
un-interfered-with by GATE-2.** GATE-2 added the AC-7 driver as a *separate*
artifact and did **not** touch any conformance rule, any AC-1..6/8 test body, or
the aggregate `runConformanceCheck` (still the same seven sweep rules) — so the
`ConformanceResult` each of those tests reads is identical to the A11Y-7 baseline,
and each reads only its own `outcomeFor(itsId)` / `failing.contains(itsId)`. AC-7's
driver shares no state with the sweep (own subject, own semantics, own boolean).
No un-pended test references a still-pending rule id (AC-9/AC-11 remain pending,
owned by GATE-3/GATE-4). AC-10 and AC-12 are pure-manual gates (no automated test),
closed at SIGNOFF-1 (G-3/G-4).

**No B rows — nothing must change for this phase to pass.**

---

<!-- Historical context: prior grade grids, most recent first. -->

# bs-11 Accessibility conformance — behaviour-test completeness (prior grids)

## A11Y-7 — re-grade of un-pended AC tests (AC-1,2,3,4,5,6,8)

**Phase graded: A11Y-7 (un-pended AC tests AC-1,2,3,4,5,6,8).** Independent,
adversarial re-grade of **every currently un-pended automated AC test** against
the code as it now stands on `feat/bs-11-accessibility-conformance` (worktree
`/Users/matthew.quirk/Nuance-bs11`). **What A11Y-7 changed:** it implemented the
**AC-8 no-timeout rule** in the new `integration_test/conformance/checks/no_timeout.dart`
— `checkNoTimeout` (`ConformanceRuleId.noTimeout`). Detection is **by
re-render**, not by catching a live surface at an arbitrary instant: a transient
notice may be raised through a post-frame callback and then removed by its own
timer, so by the time a check runs the surface may already be gone. The rule
therefore re-renders the subject (`tester.element(screen).markNeedsBuild()` +
three bounded pumps ending with `pump(500ms)`) so any notice raised on render is
present during the check, then flags any `SnackBar` in the rendered tree
(`find.byType(SnackBar)`) as a timed auto-dismiss surface (its `duration` is a
finite `Duration` that schedules its own removal); otherwise OK. It composed that
rule into the aggregate `runConformanceCheck` as the **seventh** live rule,
running **LAST** (after contrast/tapTarget/fontScale/colourCue/noBareDot/meaningfulLabel).
It dropped AC-8 from `bs11/pending.dart` (pending set is now **`{AC-7,AC-9,AC-11}`**;
the scaffold-guard in `accessibility_test.dart` now expects **3** pending and
asserts `!containsKey('AC-8')`). **No `lib/` change** — the D-1 sweep found no
auto-dismissing surface in production code (`AccessibleNotice`, the SI's timerless
notice primitive, is the compliant surface). The behaviour phase re-grades
**AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-8**. The grader ran nothing and edited
nothing but this file.

**AC-1..6 are unchanged by A11Y-7** — their rules and test bodies are untouched;
they are re-confirmed against the now **seven-rule** aggregate. **Adding
`checkNoTimeout` cannot disturb them (verified against both interference vectors):**
1. **Within one `runConformanceCheck` call**, `noTimeout` runs **last** (line 63
   of `conformance_check.dart`): the six prior rules' outcomes are computed and
   frozen into the `outcomes` map **before** `noTimeout` re-renders the subject,
   so its `markNeedsBuild` + pumps cannot retro-alter any of
   `contrastAA`/`tapTarget48`/`fontScale200`/`colourCue`/`noBareDot`/`meaningfulLabel`.
2. **Each AC-1..6 test reads only its own** `outcomeFor(itsId)?.pass` /
   `failing.contains(itsId)` (never result equality), so the extra `noTimeout`
   entry in the map is invisible to them; and **every tree/finder assertion in
   AC-1..6 is taken BEFORE `whenCheckedForConformance`** (screen open, reference
   element present, control subtree present), so the re-render that happens
   *inside* the check leaves no post-check assertion to disturb.
`noTimeout` also never leaks a failing id into their control fixtures: none of
`control_lowContrast` / `control_bareDot` / `control_smallTarget` /
`control_unlabelled` / `control_overflow200` raises a `SnackBar` on re-render, so
`noTimeout` simply **passes** on each and is absent from their `failing` sets.
No un-pended test references a still-pending rule id (`eyesFree` is never read by
AC-1..6/AC-8). Empirically confirmed: default suite `+16 ~3` all passed, exit 0.

**Special attention — the NEW test (AC-8) genuinely discriminates (verified):**
- **Settle + control pair (G3), proper.** Reference leg: `givenCompliantReference`,
  the descendant `AccessibleNotice` asserted present **before** the settle, then
  `whenWaited(10s)` (a real fake-clock advance, well past the 4s `SnackBar`
  default), then the `AccessibleNotice` asserted **still present after the
  advance** (the negative Then taken only after the moment passed), then
  `outcomeFor(noTimeout).pass isTrue`. Control leg: `control_autoDismiss`'s
  standard `SnackBar` asserted present first (`find.text('Auto-dismissing notice')
  findsOneWidget`), then — after the **identical** 10s advance — asserted **gone**
  (`findsNothing`). So the control proves the reading **can change** (a timed
  surface does vanish within the window), which makes the reference's persistence
  a real observation, not a stuck frame. This is a textbook settle+control pair.
- **G5 discriminator, honest (the keystone concern).** The rule passes on all six
  real `buildApp` screens **and** on the compliant `AccessibleNotice` reference,
  and **fails on `control_autoDismiss`** (`failing contains noTimeout`). At
  check-entry the control's `SnackBar` is already gone — the rule catches it only
  because `_AutoDismissControl` re-shows the SnackBar via a post-frame callback in
  its `build`, which the rule's `markNeedsBuild` + pumps re-trigger. This is **not
  a trick coupled to the control**: it is the rule's designed semantics (it models
  the real Flutter idiom of a transient surface raised on render), and the control
  **exactly mirrors that idiom**. Crucially the data rejects **two** plausible
  wrong rules, not one: (a) an always-pass rule (ignores SnackBars) makes the
  control pass ⇒ the `failing contains noTimeout` leg fails; (b) a naive
  "inspect the current frame" rule finds **no** SnackBar (it auto-dismissed before
  the check) ⇒ the control passes ⇒ that leg fails too. So the control forces a
  rule that both flags timed surfaces **and** re-renders to catch an
  already-dismissed one — exactly `checkNoTimeout`'s two defining properties.
- **Documented limitation (acceptable, not a downgrade).** The rule detects
  `SnackBar`-typed surfaces re-raised on re-render, not an arbitrary timed widget
  that neither is a `SnackBar` nor re-raises itself on rebuild. This is scoped to
  the SI's named non-conformant pattern (SnackBar/toast on a timer); the D-1 sweep
  found no such surface in `lib`, and the sweep's job is to pass the clean shipped
  screens (which it does). This mirrors the accepted AC-6 limitation (non-empty vs
  semantically-meaningful label): an inherent limit of the automatable check, with
  the residue carried by the pure-manual gates AC-10/AC-12 at SIGNOFF-1. The rule
  still rejects the most plausible wrong implementations, so G5 holds.

| Test | What it checks | Grade | Rule notes |
|---|---|---|---|
| **AC-8** `nothing auto-dismisses or imposes a time limit` (owner A11Y-7), un-pended; rule = **real** `checkNoTimeout` (re-render the subject, flag any `SnackBar` as a timed surface; `AccessibleNotice` carries no timer and is never flagged) | Sweep: for each of the 6 `realScreens`, `givenScreen` opens it (Given `screen findsOneWidget`), the check runs, `outcomeFor(noTimeout).pass isTrue`. Reference: Given a descendant `AccessibleNotice findsOneWidget` **before** the settle; **settle point** `whenWaited(10s)` (past the 4s SnackBar default); Then the `AccessibleNotice` is **still present after the advance** and `noTimeout` passes. Control: `control_autoDismiss`'s SnackBar present first (`find.text('Auto-dismissing notice') findsOneWidget`), **gone** (`findsNothing`) after the same 10s advance, and `failing contains noTimeout`. | **A** | **G3 fully satisfied (the task's live question):** a real settle point (fake clock advanced 10s, well past the 4s auto-dismiss window), the negative "still present" Then taken **only after** the advance, and a change-control (the standard SnackBar **is gone** after the identical advance) proving the reading can move — the reference's persistence is a real observation, not a stuck frame. **G5 genuine, honest discriminator:** passes on all 6 real screens **and** the `AccessibleNotice` reference; **fails on `control_autoDismiss`** (`failing contains noTimeout`). The control rejects **both** an always-pass rule **and** a naive current-frame rule (the SnackBar is gone at check entry; only a re-rendering rule that flags the re-raised SnackBar catches it) — so it forces exactly `checkNoTimeout`'s two defining properties. **G1** every discriminating Given checked through the public surface before its When/settle — each swept screen's home finder `findsOneWidget`, the reference's descendant `AccessibleNotice findsOneWidget` (present before the 10s advance), the control's SnackBar text `findsOneWidget` (present before the advance). **G4** exact `ConformanceRuleId.noTimeout` `.pass isTrue` at step grain on **every** swept screen; persistence asserted via the specific `AccessibleNotice` finder, dismissal via the specific `find.text`, failure via `failing` **contains** `noTimeout` — raw observables, not a derived proxy. **G6** exactly one AC — only `noTimeout` is read; the SnackBar-gone / notice-persists finder assertions are the G3 change-control for the **same** AC, not a second AC. **Documented limitation:** detection is scoped to `SnackBar`-typed surfaces re-raised on re-render (SI's named pattern); residue on arbitrary timed widgets is carried by the manual AC-10/AC-12 gates — acceptable, mirrors the accepted AC-6 limitation, not a G-rule failure. Deterministic (fake-clock `pump`, bounded pumps — never `pumpAndSettle` inside the rule so a steady-state animation cannot hang it); honest comments matching the real rule. |
| **AC-1** `every colour-coded element carries a non-colour cue` (owner A11Y-5), un-pended; rule = `checkColourCue` | Sweep over 6 `realScreens` + reference pass `colourCue`; `control_bareDot` fails. | **A** | Unchanged by A11Y-7 (body + rule untouched); re-confirmed against the **seven-rule** aggregate. `noTimeout` runs last and cannot retro-alter `colourCue`; `control_bareDot` raises no SnackBar on re-render ⇒ `noTimeout` passes on it and is absent from its `failing`; AC-1 reads only `failing.contains(colourCue)`. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-2** `a status is never rendered as a bare colour dot` (owner A11Y-5), un-pended; rule = `checkNoBareDot` | Sweep + `StatusBadge` reference pass `noBareDot`; `control_bareDot` fails. | **A** | Unchanged by A11Y-7; re-confirmed. Same non-interference as AC-1 (shared `control_bareDot`, no SnackBar). Reads only `noBareDot`. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-3** `the layout survives 200% font scaling without breaking` (owner A11Y-4), un-pended; rule = `checkFontScale200` | Sweep + reference pass `fontScale200`; `control_overflow200` fails. | **A** | Unchanged by A11Y-7; re-confirmed. `control_overflow200` raises no SnackBar ⇒ `noTimeout` passes on it; AC-3 reads only `fontScale200`. Note: `checkFontScale200` runs **before** `noTimeout` and restores its own text-scale override, so the re-render in `noTimeout` sees the restored scale — no cross-rule scale leak. **G4/G5/G6** met; **G3** N/A; **G1/G2** met. No downgrade. |
| **AC-4** `interactive targets meet the 48dp minimum` (owner A11Y-3), un-pended; rule = `checkTapTarget48` | Sweep + 48dp reference pass `tapTarget48`; `control_smallTarget` (24dp) fails. | **A** | Unchanged by A11Y-7; re-confirmed. `control_smallTarget` raises no SnackBar; reads only `tapTarget48`. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-5** `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2), un-pended; rule = `checkContrastAA` | Sweep (G2 pins `AppTheme.light().colorScheme`) + reference pass `contrastAA`; `control_lowContrast` fails. | **A** | Unchanged by A11Y-7; re-confirmed. `control_lowContrast` raises no SnackBar; reads only `contrastAA`. **G2 decisive, still satisfied** (contrast pinned to the shipped theme). **G1/G4/G5/G6** met; **G3** N/A. No downgrade. |
| **AC-6** `every control exposes a meaningful screen-reader label` (owner A11Y-6), un-pended; rule = `checkMeaningfulLabel` over `labeledTapTargetGuideline` | Sweep + tooltipped reference pass `meaningfulLabel`; `control_unlabelled` fails. | **A** | Unchanged by A11Y-7 (A11Y-6's prior A re-confirmed); `control_unlabelled` raises no SnackBar on re-render ⇒ `noTimeout` passes on it and is absent from its `failing`; AC-6 reads only `meaningfulLabel`. The documented non-empty-vs-meaningful limitation (carried by manual AC-10/AC-12) is unchanged. **G1/G2/G4/G5/G6** met; **G3** N/A. No downgrade. |

## Verdict

**7 A / 0 B — PASS (all A).** Every currently un-pended automated AC test meets
the bar against the code as it now stands. **The NEW A11Y-7 test (AC-8) is A —
earned, not nominal:** `checkNoTimeout` genuinely discriminates — the compliant
`AccessibleNotice` reference **passes** and the timed `control_autoDismiss`
SnackBar **fails** (`failing contains noTimeout`) — and the test nails **G3**
with a true settle point (10s fake-clock advance past the 4s window), the
negative "still present" Then taken only after it, and a change-control (the
SnackBar *is* gone after the identical advance) proving the reading can move. The
control honestly rejects **both** an always-pass rule and a naive current-frame
rule, because the SnackBar is already dismissed at check entry and only a
re-rendering rule that flags the re-raised surface catches it — exactly
`checkNoTimeout`'s design. It asserts exactly `noTimeout` at step grain (G4),
covers one AC (G6), and checks every discriminating Given before its When/settle
(G1). The one honest limitation — detection scoped to `SnackBar`-typed,
re-render-raised surfaces (the SI's named pattern) — mirrors the accepted AC-6
limitation and is carried by the pure-manual AC-10/AC-12 gates; it does not drop
the grade.

**AC-1..6 hold their prior A, un-weakened and un-interfered-with** by the seventh
aggregate rule. `checkNoTimeout` runs **last**, so it cannot retro-alter the six
prior outcomes within a check; each AC test reads only its own
`outcomeFor(itsId)` / `failing.contains(itsId)` and takes every tree assertion
**before** the check; and none of their control fixtures raises a `SnackBar` on
re-render, so `noTimeout` simply passes over each and never leaks a failing id.
No un-pended test references a still-pending rule id (`eyesFree`). Empirically
confirmed green: default `+16 ~3` all passed, run-pending `+16 -3` (AC-8 passes;
the 3 reds are exactly the still-pending AC-7/AC-9/AC-11, failing as designed);
unit 1041/1041; analyze clean; coverage 100% on touched lib (no lib change).

**No B rows — nothing must change for this phase to pass.**

## A11Y-6 — re-grade of un-pended AC tests (AC-1,2,3,4,5,6)

**Phase graded: A11Y-6 (un-pended AC tests AC-1,2,3,4,5,6).** Independent,
adversarial re-grade of **every currently un-pended automated AC test** against
the code as it now stands on `feat/bs-11-accessibility-conformance` (worktree
`/Users/matthew.quirk/Nuance-bs11`). **What A11Y-6 changed:** it implemented the
**AC-6 meaningful-label rule** in the new `integration_test/conformance/checks/labels.dart`
— `checkMeaningfulLabel` (`ConformanceRuleId.meaningfulLabel`) wraps
`tester.ensureSemantics()` around Flutter's own `labeledTapTargetGuideline`,
which walks the semantics tree and fails any node that has a tap/long-press
action, is not a text field and is not merged/hidden, yet carries **neither a
`label` nor a `tooltip`** — exactly AC-6's "every interactive control carries a
meaningful semantic label". It composed that rule into the aggregate
`runConformanceCheck` as the **sixth** live rule (beside
`contrastAA`/`tapTarget48`/`fontScale200`/`colourCue`/`noBareDot`), swept `lib`
and wrapped three previously-unlabelled tappables —
`DisplaySettingsButton` + the panel close `IconButton`
(`lib/display/settings_screen.dart`) and the repeat `IconButton`
(`lib/display/spoken_output_panel.dart`) — each in
`MergeSemantics(child: Semantics(label:…, button:true, child: IconButton…))` so
the label lands on the tappable node (no `Tooltip`, as these sit above the
Navigator Overlay), with new unit assertions in the two `test/display/*` files.
It dropped AC-6 from `bs11/pending.dart` (pending set is now
**`{AC-7,AC-8,AC-9,AC-11}`**; the scaffold-guard in `accessibility_test.dart`
now expects 4 pending and asserts `!containsKey('AC-6')`). The behaviour phase
re-grades **AC-1, AC-2, AC-3, AC-4, AC-5, AC-6**. The grader ran nothing and
edited nothing but this file.

**AC-1..5 are unchanged by A11Y-6** — their rules (`checkColourCue`,
`checkNoBareDot`, `checkFontScale200`, `checkTapTarget48`, `checkContrastAA`) and
test bodies are untouched; they are re-confirmed against the now **six-rule**
aggregate. Adding `meaningfulLabel` does not disturb them: each AC test reads
**only its own** `outcomeFor(itsId)?.pass isTrue` / `failing.contains(itsId)`
(never result equality), so a failing or passing `meaningfulLabel` on any
subject cannot leak into their assertions. Verified the new rule does not throw
over any AC-1..5 subject: on each of their controls the only tappable node is
either absent (`control_lowContrast`/`control_bareDot`/`control_overflow200` have
no tap action) or already labelled (`control_smallTarget` carries
`Semantics(label:'Tiny action', button:true)`), so `meaningfulLabel` simply
**passes** on those subjects and never appears in their `failing` set — no new
id leaks anywhere. And no un-pended test reads a still-pending rule's id
(`eyesFree`, `noTimeout` are never referenced by AC-1..6).

**Special attention — the NEW test (AC-6) genuinely discriminates (verified):**
- **control_unlabelled** = `IconButton(onPressed: …, icon: Icon(settings))` at
  48×48 with **no `tooltip` and no `Semantics(label:)`**. It has a tap action,
  is not a text field, is not merged — and carries neither label nor tooltip —
  so `labeledTapTargetGuideline` **fails** it → `meaningfulLabel` is in
  `failing`. This is the canonical failing case for the guideline, and the exact
  shape of the real accessibility bug (an `IconButton` shipped with no tooltip).
  An always-pass rule would leave `failing` empty and fail this control leg.
- **compliantReference**'s tappable is an `IconButton` with `tooltip: 'Add
  sample'` → it carries a tooltip → the guideline **passes** it. The reference's
  other elements (`ColorChip`, `StatusBadge`) are **not tappable** —
  non-interactive `Semantics(label, excludeSemantics:true)` wrappers with no
  tap action (verified: no `GestureDetector`/`onTap`/`InkWell`/`button` in
  either widget) — so the guideline does not apply to them, and the reference
  passes `meaningfulLabel` on the strength of its single labelled control. So
  the rule is neither vacuous (it fails the unlabelled control) nor over-eager
  (it accepts a tooltip-labelled control and ignores non-interactive swatches).
- **Documented limitation (acceptable, not a downgrade):** `labeledTapTargetGuideline`
  checks that a tappable node's label/tooltip is **non-empty**, not that the
  text is *semantically meaningful* ("describes what it does"). A control
  labelled `"button"` or `"x"` would pass the automated rule. This is an
  inherent limit of any automatable label check — meaningfulness is a human
  judgment — and is **deliberately covered by the pure-manual gates** AC-10
  (manual eyes-free walkthrough, G-3) and AC-12 (on-device VoiceOver/TalkBack
  parity, G-4), performed at SIGNOFF-1. The automated rule rejects the most
  plausible wrong implementation (a missing label), so G5 is satisfied; the
  meaningfulness gap is a genuine but acceptable limit, not a test defect.

| Test | What it checks | Grade | Rule notes |
|---|---|---|---|
| **AC-6** `every control exposes a meaningful screen-reader label` (owner A11Y-6), un-pended; rule = **real** `checkMeaningfulLabel` over `labeledTapTargetGuideline` (every tappable semantic node must carry a non-empty `label`/`tooltip`) | Sweep: for each of the 6 `realScreens`, `givenScreen` opens it (Given `screen findsOneWidget`), the check runs, `outcomeFor(meaningfulLabel).pass isTrue`. Reference: Given a descendant `IconButton findsOneWidget` (an interactive control present — tooltip `Add sample`), then passes `meaningfulLabel`. Control: `control_unlabelled` (Given subtree `findsOneWidget`) has `meaningfulLabel` in `failing`. | **A** | **G5 genuine discriminator (the keystone concern), satisfied:** the real rule passes on all 6 `buildApp` screens **and** the reference, and **fails on `control_unlabelled`** (a tappable `IconButton` with no tooltip/label — the canonical `labeledTapTargetGuideline` failure). Verified non-vacuous (the control truly fails: tappable node, no label/tooltip) and non-over-eager (the tooltipped reference IconButton passes; the non-interactive `ColorChip`/`StatusBadge` wrappers carry no tap action so the guideline skips them). An always-pass rule would leave `failing` empty and fail the control leg; a real screen leaking an unlabelled tappable fails the sweep. **G1** every discriminating Given checked through the public surface before the When — each swept screen's home finder `findsOneWidget`, the reference's descendant `IconButton findsOneWidget` (non-vacuous positive — a control is actually present to be labelled), the control's keyed subtree `findsOneWidget`. **G2** the label behaviour under test comes from the real shipped widgets rendered on the real screens via `buildApp` (A11Y-6 wrapped the live `IconButton`s in `lib/display/*` with `MergeSemantics`+`Semantics(label:)`), not a test-injected structure; the reference's tooltip is an in-harness positive control over the same `AppTheme`. **G4** asserts the exact `ConformanceRuleId.meaningfulLabel` outcome `.pass isTrue` (not merely non-null) at step grain, on **every** of the six `realScreens` (size/identity pinned by ITEST-1's fixture guard), and `failing` **contains** `meaningfulLabel` on the control. **G6** exactly one AC — only `meaningfulLabel` is read/asserted (extra failing ids on the control don't affect `contains`). **G3** N/A (no negative-after-settle Then). **Documented limitation:** the rule asserts non-empty label, not semantic meaningfulness — the meaningfulness judgment is reserved for the pure-manual AC-10/AC-12 gates (acceptable, not a G-rule failure). Deterministic (`buildApp` launchers + `pumpAndSettle`, no sleeps); `ensureSemantics` held for the walk and disposed in `finally`; comments match the real rule. |
| **AC-1** `every colour-coded element carries a non-colour cue` (owner A11Y-5), un-pended; rule = `checkColourCue` (flag a filled circular colour dot with no labelled `Semantics` ancestor) | Sweep: each of the 6 `realScreens` opened (Given `screen findsOneWidget`), `outcomeFor(colourCue).pass isTrue`. Reference: Given a descendant `ColorChip findsOneWidget`, passes `colourCue`. Control: `control_bareDot` (Given subtree `findsOneWidget`) has `colourCue` in `failing`. | **A** | Unchanged by A11Y-6 (body + rule untouched); re-confirmed against the six-rule aggregate. **G5** passes on all 6 screens + reference, fails on `control_bareDot` (a filled 16dp circle with no labelled `Semantics` ancestor); `ColorChip`'s labelled circle passes because the walk is over the widget tree, unaffected by `excludeSemantics`. The new `meaningfulLabel` rule does not interfere: `control_bareDot` has no tappable node, so `meaningfulLabel` passes on it and is absent from `failing`, and AC-1 reads only `failing.contains(colourCue)` anyway. **G1** every Given (six finders, reference `ColorChip` descendant, control subtree) checked before the When. **G2** real `ColorChip`/`StatusBadge` primitives via `buildApp`. **G4** exact `colourCue` `.pass isTrue`, every screen; control `failing` **contains** `colourCue`. **G6** one AC. **G3** N/A. No downgrade. |
| **AC-2** `a status is never rendered as a bare colour dot` (owner A11Y-5), un-pended; rule = `checkNoBareDot` (same traversal, own outcome id) | Sweep: each real screen opened, `outcomeFor(noBareDot).pass isTrue`. Reference: Given a descendant `StatusBadge findsOneWidget` (status as text+icon), passes `noBareDot`. Control: `control_bareDot` has `noBareDot` in `failing`. | **A** | Unchanged by A11Y-6 (body + rule untouched); re-confirmed. The AC-2-specific positive Given (`StatusBadge`) is pinned distinct from AC-1's (`ColorChip`), and reusing `control_bareDot` as the shared negative is legitimate (a bare dot violates both). `meaningfulLabel` is irrelevant to this control (no tappable node) and AC-2 reads only its own id. **G1** reference Given asserts the status is a `StatusBadge` before the When. **G4** exact `noBareDot` `.pass isTrue`, every screen; control `failing` **contains** `noBareDot`. **G5** passes on real screens + `StatusBadge` reference, fails on the bare-dot control. **G6** one AC (asserted independently of `colourCue` though they share one traversal). **G2** real primitives; **G3** N/A. No downgrade. |
| **AC-3** `the layout survives 200% font scaling without breaking` (owner A11Y-4), un-pended; rule = `checkFontScale200` (re-render at `textScaler 2.0`, measure first `RenderFlex` overflow) | Sweep: each of the 6 `realScreens` opened (Given `screen findsOneWidget`), `outcomeFor(fontScale200).pass isTrue`. Reference passes `fontScale200`. Control: `control_overflow200` (100dp column of three `textScaler`-sized rows → 180dp at 200%; Given subtree `findsOneWidget`) has `fontScale200` in `failing`. | **A** | Unchanged by A11Y-6 (body + rule untouched); re-confirmed against the six-rule aggregate. `control_overflow200` has no tappable node, so `meaningfulLabel` passes on it and adds nothing to its `failing`; AC-3 reads only `fontScale200`. **G5** passes on all 6 screens + reference, fails on `control_overflow200` (children 180 > box 100 ⇒ `over=80>0.5`). **G4** exact `fontScale200` `.pass isTrue`, every screen. **G6** one AC. **G3** N/A (200% pump + restore live inside the rule). **G1** discriminating Givens (every swept finder + control subtree) checked before the When; the reference leg's omitted `findsOneWidget` is non-blocking (the rule's `tester.renderObject(screen)` throws on a missing finder ⇒ no vacuous pass). **G2** real screens via `buildApp`. No downgrade. |
| **AC-4** `interactive targets meet the 48dp minimum` (owner A11Y-3), un-pended; rule = `checkTapTarget48` (android 48×48 `&&` iOS 44×44 → 48dp floor) | Sweep: each real screen opened (Given `screen findsOneWidget`), `outcomeFor(tapTarget48).pass isTrue`. Reference: descendant `IconButton findsOneWidget` (Given), passes `tapTarget48`. Control: `control_smallTarget` (24dp, Given subtree `findsOneWidget`) has `tapTarget48` in `failing`. | **A** | Unchanged by A11Y-6 (body + rule untouched); re-confirmed. **Note on the shared control shape:** `control_smallTarget` is a 24dp `GestureDetector` **wrapped in `Semantics(label:'Tiny action', button:true)`**, so it carries a label — the new `meaningfulLabel` rule therefore **passes** on it (it fails only `tapTarget48`), keeping the control single-rule as documented; AC-4 reads only `failing.contains(tapTarget48)` regardless. **G1** every Given (six finders, reference `IconButton` descendant, control subtree) checked before the When. **G2** sweep drives the shipped `buildApp` assembly carrying the padded `AppTheme`/`materialTapTargetSize`. **G4** exact `tapTarget48` `.pass isTrue`, every screen; control `failing` **contains** `tapTarget48`. **G5** passes on the 48dp reference + six real padded screens, fails on the 24dp control. **G6** one AC. **G3** N/A. No downgrade. |
| **AC-5** `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2), un-pended; rule = `checkContrastAA` over `textContrastGuideline` at the AA floor | Sweep: each real screen opened; **G2 Given** asserts `Theme.of(element).colorScheme == AppTheme.light().colorScheme`, then `outcomeFor(contrastAA).pass isTrue`. Reference: same theme asserted, passes `contrastAA`. Control: `control_lowContrast` (~1.6:1 grey-on-white) has `contrastAA` in `failing`. | **A** | Unchanged by A11Y-6 (body + rule untouched); re-confirmed. `control_lowContrast` has no tappable node, so `meaningfulLabel` passes on it; AC-5 reads only `contrastAA`. **G2 (decisive, satisfied)** — contrast pinned to the shipped `AppTheme.light().colorScheme` (content-equal `ColorScheme`) on every swept screen and the reference, not a test-injected theme; `tester.element(finder)` fails unless the finder resolves, so the reference leg is non-vacuous. **G1** screen-open + theme-source Givens before the When. **G4** exact `contrastAA` `.pass isTrue`, every screen; control `failing` **contains** `contrastAA`. **G5** passes on the AA reference + six real screens, fails on `control_lowContrast` (below 4.5:1). **G6** one AC. **G3** N/A. No downgrade. |

## Verdict

**6 A / 0 B — PASS (all A).** Every currently un-pended automated AC test meets
the bar against the code as it now stands. **The NEW A11Y-6 test (AC-6) is A —
earned, not nominal:** `checkMeaningfulLabel` (delegating to Flutter's
`labeledTapTargetGuideline` under a held `SemanticsHandle`) genuinely
discriminates — `control_unlabelled` (a tappable `IconButton` with no
tooltip/label) **fails** the rule (`failing` contains `meaningfulLabel`), while
the tooltip-labelled reference IconButton **passes** and the non-interactive
`ColorChip`/`StatusBadge` swatches are correctly skipped (no tap action). The
sweep asserts the rule PASSES on every one of the six real `buildApp` screens
(`.pass isTrue`, not non-null), driven by the live widgets A11Y-6 relabelled in
`lib/display/*` (G2). It asserts exactly `meaningfulLabel` at step grain (G4),
covers one AC (G6), checks every discriminating Given before the When (G1), and
has no negative-after-settle Then (G3 N/A). The one honest limitation — the
automated rule proves a label is **non-empty**, not that it is *semantically
meaningful* — is an inherent limit of any automatable label check and is
deliberately carried by the pure-manual AC-10/AC-12 gates at SIGNOFF-1; it does
not drop the grade, because the rule still rejects the most plausible wrong
implementation (a missing label).

**AC-1/AC-2/AC-3/AC-4/AC-5 hold their prior A, un-weakened and
un-interfered-with** by the sixth aggregate rule: each reads only its own
`outcomeFor(itsId).pass` / `failing.contains(itsId)`, and the new
`meaningfulLabel` rule simply passes (never throws, never leaks a failing id)
over each of their control fixtures — verified `control_lowContrast`,
`control_bareDot` and `control_overflow200` have no tappable node, while
`control_smallTarget` carries its own `Semantics(label:)` so it fails only
`tapTarget48`. No un-pended test references a still-pending rule id (`eyesFree`,
`noTimeout`). G1/G2/G4/G6 met across all six, G3 N/A (no negative-after-settle
Then in this set; that remains AC-8's, still pending).

**No B rows — nothing must change for this phase to pass.**

## A11Y-5 — re-grade of un-pended AC tests (AC-1,2,3,4,5)

**Phase graded: A11Y-5 (un-pended AC tests AC-1,2,3,4,5).** Independent,
adversarial re-grade of **every currently un-pended automated AC test** against
the code as it then stood. **What A11Y-5 changed:** it implemented the two
colour-vocabulary rules in the new `integration_test/conformance/checks/colour_cue.dart`
— `checkColourCue` (`ConformanceRuleId.colourCue`, AC-1: every colour-coded
element carries a non-colour cue) and `checkNoBareDot` (`ConformanceRuleId.noBareDot`,
AC-2: no status is a bare colour dot) — which share one render-tree traversal
(`_bareColourDots`): a **filled circular** `BoxDecoration` (`Container`/`DecoratedBox`
with `shape: BoxShape.circle` and non-null `color`) that has **no labelled
`Semantics` ancestor within the checked subtree** is a *bare* dot and fails both
rules. It wired both into the aggregate `runConformanceCheck` beside
`contrastAA`/`tapTarget48`/`fontScale200`, and dropped AC-1 + AC-2 from
`bs11/pending.dart` (the scaffold-guard then expected the other five —
`{AC-6,AC-7,AC-8,AC-9,AC-11}`).

**Special attention — the two NEW tests (AC-1, AC-2) genuinely discriminate (verified):**
- **control_bareDot** = `Container(16×16, BoxDecoration(color: 0xFFC62828, shape: circle))` with **no `Semantics` wrapper**. Walking element ancestors from the dot up to the checked-subtree root finds no labelled `Semantics` → it is **bare → fails both `colourCue` and `noBareDot`** (`failing` contains each). So an always-pass rule would leave `failing` empty and fail both control legs.
- **ColorChip** (AC-1's positive) and **StatusBadge** (AC-2's positive) each wrap their swatch in `Semantics(label: …, excludeSemantics: true)`; the rule walks the **widget/element** tree (not the semantics tree), so `excludeSemantics` does **not** hide the labelled node → the swatch is **not bare → passes**. The rule is therefore neither vacuous (it fails the bare dot) nor over-eager (it does not wrongly fail a labelled swatch).
- **Reusing `control_bareDot` for both AC-1 and AC-2 is legitimate**: a bare coloured dot genuinely violates *both* "colour carries meaning with no cue" (AC-1) and "a status drawn as a bare dot" (AC-2). Each test still pins its **own** positive Given (AC-1 ⇒ a descendant `ColorChip` present; AC-2 ⇒ a descendant `StatusBadge` present) and asserts its **own** `ConformanceRuleId` (G6), so the two are not duplicates.

| Test | What it checks | Grade | Rule notes |
|---|---|---|---|
| **AC-1** `every colour-coded element carries a non-colour cue` (owner A11Y-5), un-pended; rule = **real** `checkColourCue` | Sweep over 6 `realScreens` + reference pass `colourCue`; `control_bareDot` fails. | **A** | **G5** real rule passes on all 6 screens + reference, fails on `control_bareDot` (not vacuous, not over-eager). **G1/G2/G4/G6** met; **G3** N/A. |
| **AC-2** `a status is never rendered as a bare colour dot` (owner A11Y-5), un-pended; rule = **real** `checkNoBareDot` | Sweep + `StatusBadge` reference pass `noBareDot`; `control_bareDot` fails. | **A** | **G1** reference Given asserts `StatusBadge` (the status=text/icon primitive). **G5/G4/G6** met; **G3** N/A. |
| **AC-3** 200% scaling (owner A11Y-4) | Unchanged; re-confirmed against the five-rule aggregate. | **A** | New dot rules don't flag `control_overflow200`; reads only `fontScale200`. No downgrade. |
| **AC-4** 48dp targets (owner A11Y-3) | Unchanged; re-confirmed. | **A** | `control_smallTarget` not a circle `Container`; reads only `tapTarget48`. No downgrade. |
| **AC-5** AA contrast (owner A11Y-2) | Unchanged; re-confirmed (G2 pinned to shipped theme). | **A** | `control_lowContrast` not a circle; reads only `contrastAA`. No downgrade. |

### A11Y-5 verdict

**5 A / 0 B — PASS (all A).** The two NEW A11Y-5 tests earned A (real rules
genuinely discriminate via `control_bareDot`); AC-3/4/5 held their prior A,
un-weakened by the two new aggregate rules.

## ITEST-2 — AC tests: structural rules (AC-1,2,4,5,6)

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

### ITEST-2 verdict

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

## A11Y-2 — AC-5 re-grade (behaviour: AC-5 un-pended, contrast rule real)

Independent, adversarial re-grade of **AC-5** (`'text meets the WCAG 2.2 AA
contrast floor'`) now that A11Y-2 has made its rule real and un-pended it. The
aggregate `runConformanceCheck` no longer returns `ConformanceResult.empty`: it
composes `checkContrastAA` (`integration_test/conformance/checks/contrast.dart`),
which delegates to Flutter's own `textContrastGuideline` pinned to the WCAG 2.2 AA
ratios (`kMinimumRatioNormalText` 4.5 / `kMinimumRatioLargeText` 3.0, D-5) and
reports a `ConformanceRuleOutcome`. AC-5 is removed from `bs11/pending.dart`
(the scaffold-guard test now expects the other nine and asserts
`!containsKey('AC-5')`), so the test runs — and passes — in the default on-device
run. Only the AC-5 row is graded here; ITEST-1/2/3 rows above are not re-graded.
The grader ran nothing and edited nothing but this file.

Working-tree phase (uncommitted) atop **ITEST-4 / G-2** on
`feat/bs-11-accessibility-conformance` (worktree `/Users/matthew.quirk/Nuance-bs11`).
Verified: the A11Y-2 working-tree diff to `accessibility_test.dart` touches **only**
the pending-gate guard test at the top of the file — the AC-5 `acTestWidgets` body
(lines ~328–368) is **byte-for-byte identical** to the ITEST-2 version graded A, so
un-pending weakened no assertion. `conformance_check.dart` now wires in the real
`checkContrastAA`; `contrast.dart` is new this phase.

| AC | Test | Grade | Justification against G1–G6 |
|---|---|---|---|
| **AC-5** | `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2), un-pended; rule = real `checkContrastAA` over `textContrastGuideline` at the AA floor | **A** | **G1** every Given checked through the public surface before the When — each swept screen's home finder `findsOneWidget`, the control's keyed subtree `findsOneWidget`; the reference and sweep theme-source Givens read `tester.element(finder)`, which itself fails unless the finder resolves to exactly one element (so the reference leg is not vacuous despite having no separate `findsOneWidget`). **G2 (decisive, satisfied):** the configured Given is the one that answers — on **every** swept screen and on the reference the test asserts `Theme.of(element).colorScheme == AppTheme.light().colorScheme`, so the contrast under test comes from the **shipped** `AppTheme.light().colorScheme`, not a test-injected `ThemeData`; `ColorScheme` has content `==`, so a screen wired to a default/ad-hoc theme would fail this Given. **G3** N/A — a structural contrast check has no negative-after-settle Then (noted). **G4** asserts the exact `ConformanceRuleId.contrastAA` outcome, at step grain, on **every** real screen (loop over all six `realScreens`, whose size/identity ITEST-1's fixture guard pins) and on the reference, and the control's `failing` **contains** `contrastAA`. **G5** genuine discriminator against the **real** rule: passes on the AA `compliantReference` and all six real screens, and **fails on `control_lowContrast`** (~1.6:1 grey `0xFFBDBDBD` on white, below 4.5:1). **G6** exactly one AC. Deterministic; comments match the real rule. |

### A11Y-2 re-grade verdict

**AC-5: A — PASS.** AC-5 holds its prior A now that A11Y-2 has made the rule real
and un-pended the test. The decisive contrast rule **G2** is satisfied — contrast
is pinned to the shipped `AppTheme.light().colorScheme` on every swept screen and
the reference — and the real `checkContrastAA` makes the sweep a true positive
sweep and the `control_lowContrast` leg a true discriminator. G1/G4/G6 met, G3
N/A. No downgrade; no fix required.

## A11Y-3 re-grade (un-pended AC tests: AC-4, AC-5)

Independent, adversarial re-grade of the two currently un-pended automated AC
tests — **AC-4** and **AC-5** — against the code as it then existed. **What
changed:** A11Y-3 implemented the **AC-4 tap-target rule** in the new
`integration_test/conformance/checks/target.dart` (`checkTapTarget48`), which
combines Flutter's `androidTapTargetGuideline` (48×48) and `iOSTapTargetGuideline`
(44×44) with `Evaluation.operator +` (`passed` is `&&`) so the stricter Android
48dp bound is the effective floor on every platform (D-5); product code was
padded (`lib/app/theme.dart` `materialTapTargetSize.padded`, plus two region
widgets). Neither test body changed. The grader ran nothing and edited nothing but
this file.

| Test | Grade | Rule notes |
|---|---|---|
| **AC-4** `interactive targets meet the 48dp minimum` (owner A11Y-3), un-pended; rule = real `checkTapTarget48` | **A** | **G1/G2/G4/G5/G6** met (sweep over the padded shipped assembly; reference 48dp passes; `control_smallTarget` 24dp fails). **G3** N/A. Body unchanged from the ITEST-2 version graded A. No downgrade. |
| **AC-5** `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2), un-pended | **A** | Unchanged by A11Y-3. **G2** pinned to shipped theme. No downgrade. |

### A11Y-3 verdict

**2 A / 0 B — PASS.** AC-4 earned A (real rule + padded targets); AC-5 held its
prior A, un-weakened. Nothing must change.

## A11Y-4 — re-grade of un-pended AC tests (AC-3, AC-4, AC-5)

Independent, adversarial re-grade of the three currently un-pended automated AC
tests. **What A11Y-4 changed:** it implemented the real **AC-3 font-scaling rule**
in `integration_test/conformance/checks/scaling.dart` (`checkFontScale200`) — a
*measurement-based* overflow detector that re-renders the subject at `textScaler
2.0`, swallows the paint-time RenderFlex error, then walks the render tree and
flags the first `RenderFlex` whose children's summed main-axis extent exceeds its
own (`over > 0.5`), skipping `Wrap`/scrollables by construction — and wired it into
`runConformanceCheck`. It **replaced** the old ITEST-1 AC-3 control (a fixed-height
`Row` with its label in `Expanded`, which flex-shrinks/silently clips and reports
**no** overflow — non-discriminating) with `control_overflow200`, a fixed-height
(100dp) `Column` of three rows each sized by `MediaQuery.textScaler.scale(30)`
(30dp→60dp at 200%), so 3×60=180dp deterministically overflows the 100dp box.
**AC-4 and AC-5 bodies unchanged.** The grader ran nothing and edited nothing but
this file.

| Test | Grade | Rule notes |
|---|---|---|
| **AC-3** `the layout survives 200% font scaling without breaking` (owner A11Y-4), un-pended; rule = real `checkFontScale200` | **A** | **G5 genuine discriminator (satisfied):** passes on all 6 real screens + reference, fails on `control_overflow200` (children 180 > box 100 ⇒ `over=80>0.5`). **G4** exact `fontScale200` `.pass isTrue`, every screen; **G6** one AC; **G3** N/A (pump+restore inside the rule); **G1** discriminating Givens checked (reference-leg omitted `findsOneWidget` is non-blocking — `tester.renderObject(screen)` throws on a missing finder ⇒ no vacuous pass); **G2** real screens via `buildApp`. No downgrade — the earlier ITEST-3 A was against a stub + non-discriminating control; now **earned**. |
| **AC-4** `interactive targets meet the 48dp minimum` (owner A11Y-3), un-pended | **A** | Unchanged by A11Y-4; re-confirmed. No downgrade. |
| **AC-5** `text meets the WCAG 2.2 AA contrast floor` (owner A11Y-2), un-pended | **A** | Unchanged by A11Y-4; re-confirmed (G2 pinned to shipped theme). No downgrade. |

### A11Y-4 re-grade verdict

**3 A / 0 B — PASS.** AC-3 is A — now earned (real `checkFontScale200` +
deterministic `control_overflow200`); AC-4 and AC-5 hold their prior A, unchanged
and un-weakened. Nothing must change for the phase to pass.
