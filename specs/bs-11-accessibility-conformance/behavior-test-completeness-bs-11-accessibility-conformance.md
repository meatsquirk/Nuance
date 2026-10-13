# bs-11 Accessibility conformance — behaviour-test completeness

**Phase graded: ITEST-1 (acceptance-suite *harness*).** Independent, adversarial
grade of the harness phase only — the Given/When/Then vocabulary, the
`realScreens` sweep subjects, the `compliantReference` + seven `control_*`
fixtures, the pending-gate scaffold guards, the harness-fixture guards, and the
never-pending smoke suite. ITEST-1 writes **no per-AC behaviour tests** (those
are ITEST-2/3), and the `runConformanceCheck` is still the GATE-1 stub returning
`ConformanceResult.empty`, so each row is graded against ITEST-1's own bar: no
vacuous passes, comments that claim only what the code checks, determinism, and
valid fixtures / discriminating controls for the downstream ACs. The grader ran
nothing and edited nothing but this file.

Working-tree phase (uncommitted) atop **GATE-1 `ff8a3a8`** on
`feat/bs-11-accessibility-conformance` (worktree `/Users/matthew.quirk/Nuance-bs11`).
Files: `integration_test/bs11/accessibility_harness.dart`,
`integration_test/bs11/accessibility_test.dart`.

Grade key: **A** = meets the bar; **B (rule)** = fails the named rule. This
phase has no behaviour to be "pending" on, so there are no "B pending" rows —
every test must stand on its own as A.

| Test / Artifact | What it checks | Grade | Rule notes |
|---|---|---|---|
| **Pending-gate guard:** `pending map is exactly the 10 automated ACs (shrinks as they land)` | `pendingACs.keys.toSet()` equals the exact `{AC-1..AC-9, AC-11}` set **and** `hasLength(10)` | A | Pins exact membership **and** cardinality, so a missing / extra / typo'd / mis-seeded AC fails. Verified `bs11/pending.dart` seeds exactly those 10 (AC-10/AC-12 absent). Not vacuous — asserts the set's contents directly, not a loop over it. Comment ("shrinks as they land") matches the un-pend-by-deleting-a-row mechanism. Deterministic (pure map read). |
| **Pending-gate guard:** `the two manual ACs are absent from the automated gate (D-2)` | `pendingACs.containsKey('AC-10')` and `'AC-12'` are both `isFalse` | A | Directly rejects an impl that wrongly enrols either pure-manual gate into the automated skip-map (D-2: AC-10 eyes-free walkthrough, AC-12 VoiceOver/TalkBack parity are closed at SIGNOFF-1, never skipped-then-run). Would fail if either were seeded. Comment claims only what is asserted. Deterministic. |
| **Pending-gate guard:** `every pending AC is owned by a real behaviour phase` | Every `pendingACs` value is `contains`-ed in `behaviorPhases` | A | Loop over `pendingACs.entries`, which is non-empty (10 rows, pinned by the row above) — cannot pass vacuously. `behaviorPhases` is a non-empty const set of the nine real bs-11 behaviour phases (A11Y-2..7 + GATE-2/3/4); SIGNOFF-1 is correctly excluded (owns no row). Catches a stale/typo'd owner, with a `reason` naming the offending key. Deterministic. |
| **Pending-gate guard:** `a pending AC skips in default mode and runs in run-pending mode` | For each pending AC: `pendingSkipReason(ac, forceRunPending:false)` non-null and `(…:true)` null; absent ACs (AC-10/AC-12/AC-999) null in both modes; ambient path agrees with `runPending` | A | Asserts **both** directions of the skip gate via the explicit `forceRunPending` override (no environment touched → deterministic, not a fixed sleep). The absent-AC leg proves an un-pended/manual AC always runs; the ambient-agreement leg ties the override path to the real `runPending`. Loop is over the non-empty pinned pending set. G6: one concern (the skip mechanism). G5: a gate that failed to skip, or that never ran under run-pending, fails it. |
| **Fixture guard:** `the sweep covers all six buildApp screens, named uniquely` | `realScreens` `hasLength(6)`, names unique (`toSet().hasLength(6)`), and the name-set equals `{Readout, Capture, Comparison, Recipes, Correction, Palette}` | A | Pins cardinality, uniqueness **and** exact identity — a dropped, duplicated or renamed sweep entry fails. This is the guard that makes the smoke loop over `realScreens` (below) non-vacuous. Verified the list holds exactly those six `RealScreen`s, each paired with a `find.byType(...HomeScreen)` finder and a feature-harness launcher. Deterministic (pure list read). |
| **Fixture guard:** `the control fixtures are the seven discriminating controls` | `controlFixtures` `hasLength(7)`, names unique, name-set equals the seven `control_*` names | A | Pins cardinality, uniqueness and exact identity of the discriminating controls — a dropped/duplicated control fails. Makes the "every control fixture renders" smoke loop non-vacuous. `compliantReference` is correctly kept out of this list (it is the positive control that must *pass*). Deterministic. |
| **Smoke (never-pending):** `every real screen opens through buildApp and the check runs over it` | For each `realScreen`: `givenScreen` opens it, `screen` finder `findsOneWidget`, `takeException` `isNull`, and `whenCheckedForConformance` returns `isA<ConformanceResult>` | A | Proves the real production `buildApp` assembly opens each swept screen and the reusable check (D-3) runs over the opened subtree — the harness is wired to the shipped app, not a bespoke one. Loop is over `realScreens`, whose exact size/identity is pinned by the fixture guard above, so it cannot pass vacuously. Comment is honest about the GATE-1 stub: it asserts "a result is produced, not that it passes" (`isA<ConformanceResult>`), an assertion that stays true when GATE-3 populates the result — no overclaim. Each leg has a `reason`. Deterministic (launchers settle; no sleeps). G3: `takeException` read after the launcher's settle, not an instant read. |
| **Smoke (never-pending):** `the compliant reference renders and the check runs over it` | `givenCompliantReference` pumps it, `compliantReferenceFinder` `findsOneWidget`, no exception, check returns a `ConformanceResult` | A | Proves the positive-control fixture (built from the real `AppTheme` + bs-11 primitives: labelled `ColorChip`, `StatusBadge`, ≥48dp labelled `IconButton`, non-dismissing `AccessibleNotice`) renders and the check runs over it. Single keyed subtree, so `findsOneWidget` is exact. Comment claims only render + check-runs (not pass), matching the GATE-1 stub. Deterministic (`pumpAndSettle`). |
| **Smoke (never-pending):** `every control fixture renders` | For each control: `givenControl` pumps it, `subtree` finder `findsOneWidget`, `takeException` `isNull` | A | Proves all seven non-compliant controls build without throwing (each is a real `MaterialApp`/`AppTheme` subtree, incl. the stateful `_AutoDismissControl` that posts a SnackBar after first frame). Loop over `controlFixtures`, size/identity pinned by the fixture guard → non-vacuous. `givenControl` resets the tree (`pumpWidget(SizedBox())`) before each so no State leaks between iterations. Each leg has a `reason`; deterministic. |
| **Artifact:** `realScreens` sweep subjects (`RealScreen`, launchers, finders) | Six subjects launched through each feature's own production `buildApp` launcher, paired with a home-widget `Finder` | A | The sweep drives the shipped assembly via each feature's re-used `given…` launcher (prefixed imports avoid the duplicate-`givenComparison` / re-export collisions the doc-comment calls out). D-1 sweep intent — every real screen must pass every rule once behaviour lands. Stable (fixed `final` list), discriminating finders (`find.byType(...HomeScreen)`). No contrast/guideline maths faked (D-3) — only the platform sinks are faked, per the doc-comment, which matches the imports (no stubbed matchers). Claims match code. |
| **Artifact:** control fixtures + `compliantReference` | One positive control that passes every rule + seven controls each failing a targeted rule (lowContrast→AC-5, smallTarget→AC-4, bareDot→AC-1/2, unlabelled→AC-6, autoDismiss→AC-8, overflow200→AC-3, partialFail→AC-9 mixed) | A | Purpose-built discriminators: a rule that never fails its control would be vacuous, and each fixture is a minimal single-failure subtree keyed for exact targeting (`KeyedSubtree` / dedicated key). `control_partialFail` correctly carries both a passing and a failing widget so AC-9's "≥1 fail **and** ≥1 pass ⇒ not accepted" decision is exercisable. `control_autoDismiss` uses a real timed SnackBar (settle-point driven by A11Y-7's clock advance, not a wall-clock sleep). Comments describe intent for rules not yet implemented (GATE-1 stub) — appropriate for a harness; no claim that a rule currently fires. Fixtures built from the real `AppTheme`, so they are stable regardless of what the sweep finds. |
| **Artifact:** Given/When/Then vocabulary (`givenScreen`, `givenControl`, `givenCompliantReference`, `whenCheckedForConformance`, `whenScaledTo`, `whenWaited`, `whenCompletedEyesFree`) | The single vocabulary ITEST-2/3 AC tests are written against, re-exporting the pending gate, the reusable check, the eyes-free driver and the pure-domain result types | A | `given…` helpers reset the tree before pumping (no State leak) and `pumpAndSettle` throughout — deterministic. `whenScaledTo` sets `platformDispatcher.textScaleFactorTestValue` and registers `addTearDown(clearTextScaleFactorTestValue)` so the override never leaks into the next test (determinism across tests). `whenWaited` advances the fake clock with `tester.pump(duration)` (a settle point for AC-8's negative "nothing auto-dismisses" Then), **not** a real sleep — correct determinism. `whenCheckedForConformance` / `whenCompletedEyesFree` are thin pass-throughs so an AC test speaks one vocabulary. Single-file import surface via the five disjoint re-exports (no collision). Doc-comments claim only what each helper does. |

## Verdict

**12 A / 0 B — PASS (all A).** No vacuous passes: the pending-gate guard pins the
map's exact 10-member contents and cardinality, and the two smoke loops that
iterate `realScreens` / `controlFixtures` are made non-vacuous by the dedicated
fixture guards that pin each list's exact size and identity in the same file.
Every assertion would fail against a mis-wired shell, a mis-seeded gate, a
dropped/duplicated fixture, or a throwing fixture. Comments claim only what the
code checks — notably the smoke tests are honest that, against the GATE-1 stub,
they assert "a result is produced, not that it passes" (`isA<ConformanceResult>`),
which stays true when GATE-3 populates the result. Deterministic throughout:
`pumpAndSettle` and tree resets in the `given…` helpers, the `forceRunPending`
override in the skip-gate guard (no environment touched), `addTearDown` cleanup
of the text-scale override, and a fake-clock `pump(duration)` rather than any
wall-clock sleep. The control fixtures are genuine discriminators (each a minimal
single-failure subtree keyed for exact targeting, plus a positive
`compliantReference` and a mixed `control_partialFail` for AC-9), ready for the
ITEST-2/3 rules. Nothing must change for this phase to pass.
