# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 + ITEST-2 + ITEST-3 (all 12 ACs have a pending test) done; next ITEST-4 (review, G-3). G-4 resolved.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/comparison_test.dart` (AC tests), `integration_test/comparison_harness.dart`
(Given/When/Then vocabulary, fixtures, pending gate, `buildApp` driver with the comparison entry); reuses
bs-01's `integration_test/fakes/fake_speech.dart`.
**Depends on:** all shell phases (DIFF-1, CVD-1, COMPARE-2, SCREEN-1) · **Blocks:** every behavior phase (via G-3)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 5,939,625 | 19m 08s |
| 2 | acceptance-tests | AC-1,2,3,10,11,12 | ✅ Done | 7,878,822 | 27m 54s |
| 3 | acceptance-tests | AC-4,5,6,7,8,9 | ✅ Done | 15,032,038 | 29m 57s |
| 4 | test-review | — (G-3) | ⬜ Next | | |

## Interface reconciliation

- **Boundary:** the assembled app via bs-01's production `buildApp(deps)` with the comparison entry (D-8),
  driven by `WidgetTester`. Real: the `SampleSource` catalogue, `CvdProfile`, ΔE00/verdict, the LCh
  decomposition, the confusion detector, the controller, the screen and routing (incl. the bs-01 Readout).
  Faked (infrastructure only): bs-01's `FakeSpeech` (records utterances). No colour, ΔE00 or confusion math is
  faked.
- **Observation points:** AC-1/AC-2 — slot text + L/C/h; AC-3 — slot names + the re-expressed statement after
  swap; AC-4 — overall-difference text + the `deltaE00`/verdict on the read endpoint; AC-5/AC-6 — the three
  statement lines (text) + the read endpoint's decomposition; AC-7/AC-8 — the confusion-warning widget +
  `confusable` on the read endpoint; AC-9 — the `FakeSpeech` log (one utterance containing statement +
  warning); AC-10/AC-11 — the Readout route rendering the chosen sample's name; AC-12 — absence of the
  statement + the choose-B invite affordance.
- **Pending gate:** a `pendingACs` map (AC → owning phase) + `ac('AC-n')` calling `markTestSkipped('AC-n
  pending <phase>')` unless `BS03_RUN_PENDING=1`. Un-pending an AC = delete its map row. Default
  `flutter test integration_test/comparison_test.dart` skips pending; run-pending executes them.

## Open gates

- **G-3 (approve acceptance tests)** — recorded here on ITEST-4.
- **G-4 (spec-data reconciliation)** ✅ **Resolved 2026-10-07: option (a) — correct the overall to the
  computed value "delta-E00 13.1" — Matt Quirk (spec author).** The stated LCh coords compute to CIEDE2000
  ΔE00 ≈ 13.05 (→ "13.1" displayed); the spec's old "14.2" was the error. Spec line 48 amended; AC-4's test
  pins "delta-E00 13.1" (no placeholder).
- **Confusion-pair reconciliation** ✅ **Resolved 2026-10-07: rename sample B to "Terre Verte Shadow" (a
  green earth), keep the deutan profile — Matt Quirk (spec author).** The old "Mid Raw Umber / Ultramarine
  Shadow" pair is a blue↔yellow difference, which no dichromacy confuses (verified: it *expands* under
  deutan/protan/tritan projection). ITEST-3 repinned `SAMPLE_UMBER`=(40,18,16) and
  `SAMPLE_TERRE_VERTE`=(40,−10,18) — normal ΔE00 ≈ 28, deutan-projected ΔE00 ≈ 1.4 — a genuine deutan
  confusion pair (verified against the independent `referenceDeutanProjected`). Spec line 72 amended.

## Phase 1 — Harness (ITEST-1)

- **Kind:** acceptance-tests
- **Target AC:** — (harness)
- **Depends on:** DIFF-1, CVD-1, COMPARE-2, SCREEN-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/comparison_harness.dart`; reuse `integration_test/fakes/fake_speech.dart`.
- **Tasks:**
  1. A `buildApp` driver assembling the real app with the comparison entry (injected `SampleSource`
     `CATALOGUE`, a `CvdProfile`, `FakeSpeech`), opened on the Comparison screen.
  2. Given/When/Then helpers: `givenComparison({profile})`, `whenChooseA(name)`, `whenChooseB(name)`,
     `whenSwap()`, `whenSpeak()`, `whenOpenReadout(slot)`; the fixtures (`CATALOGUE`, `SAMPLE_A_TERRACOTTA`,
     `SAMPLE_B_SIENNA`, `SAMPLE_A_PRIME`, `SAMPLE_UMBER`, `SAMPLE_ULTRAMARINE`, `CVD_DEUTAN`) with their known
     coordinates; an **independent** reference ΔE00 (so AC-4/AC-7 don't grade the impl against itself).
  3. The pending gate with **all 12 ACs pending**, and a never-pending **smoke test** proving the shells wire
     end to end (the app boots to the Comparison screen and renders all five regions).
  4. Grade the scaffold tests: the pending map has exactly 12 keys each naming a real phase; the smoke test
     asserts concrete rendered regions; deterministic (`pumpAndSettle`/polling, no fixed sleeps).
- **Exit criteria:** `flutter test integration_test/comparison_test.dart` green (all AC tests pending, smoke
  passes); harness tests graded A.
- **Acceptance gate:** smoke green; pending gate in place (12 pending).

### Result

**Landed.** The bs-03 acceptance harness over the wired shells, driving the real assembled app through
`buildApp` with the comparison entry (D-8):
- `integration_test/comparison_harness.dart` — fixtures (`CATALOGUE` + `SAMPLE_A_TERRACOTTA`,
  `SAMPLE_B_SIENNA`, `SAMPLE_A_PRIME`, `SAMPLE_UMBER`, `SAMPLE_ULTRAMARINE`, `CVD_DEUTAN`), the
  Given/When/Then vocabulary (`givenComparison`, `ComparisonHarness.{state,controller,whenChooseA/B,whenSwap,
  whenSpeak,whenOpenReadout}`), and the **independent** `referenceDeltaE00` (a complete inline CIEDE2000, not
  the product metric — AC-4/AC-7 grade `deltaE00` against it). Re-exports the pending gate + fakes.
- `integration_test/bs03/pending.dart` — `pendingACs` seeded with all **12** ACs → owning phase (AC-1/2/12→
  COMPARE-3, AC-3→COMPARE-5, AC-4→DIFF-2, AC-5/6→DIFF-3, AC-7/8→CVD-2, AC-9→CVD-3, AC-10/11→COMPARE-6).
- `integration_test/comparison_test.dart` — the never-pending smoke test (app boots to the Comparison screen;
  all five region keys + endpoint render; opened empty state) + guards (gate dual-mode via `forceRunPending`;
  fakes record; fixtures recover their LCh C/h; `referenceDeltaE00` vs 5 Sharma/Wu/Dalal published pairs +
  self-distance 0). ITEST-2/3 append the per-AC `acTestWidgets` rows here.

**Gates.** `flutter analyze` clean. Unit **247 green** (`flutter test --coverage`); coverage gate PASS — no
touched `lib/**` files (harness is test-only). Acceptance: `flutter test integration_test/comparison_test.dart`
**10/10 green** (smoke + 9 guards, iOS sim); full `flutter test integration_test/` **27/27** (17 bs-01 + 10
bs-03). **Test grades: 10×A, 0×B** — graded by an independent fresh subagent against the scaffold rubric (no
vacuous passes, honest comments, deterministic, reference provably independent); grid at
`../behavior-test-completeness-bs-03-relative-comparison.md`. **Fix passes: 0/3.** No coverage exclusions.

**Deviations / notes.** `SAMPLE_UMBER`/`SAMPLE_ULTRAMARINE` carry **provisional** CIELAB — ITEST-3/CVD-2
construct & verify the deutan confusion-line property (D-5) and may repin them (`TODO(ITEST-3)` in the
harness). The `when…` helpers target the shells' inert controls by widget text; ITEST-2 wires
`whenChooseA/B` against COMPARE-3's real picker (E49). Grader's optional-only suggestions (an `isNotEmpty`
guard on the gate's second test; a FakeHaptics record guard) left for ITEST-2/3 — not rubric failures.

### Checkpoint / Handoff

**Frozen for ITEST-2/3 (the AC-test phases):**
- Boot a scenario: `final h = await givenComparison(tester, profile: CVD_DEUTAN, confusionCheck: …);`
  (confusionCheck defaults to the inert `NoopConfusionCheck`; AC-7/8/9 inject CVD-2's real detector once it
  lands — forward dep).
- Observe: `h.state` (slots, `comparison` ΔE00/verdict/3 lines, `confusable`) via the read endpoint;
  `h.speech.utterances` (AC-9); rendered region text/keys. Grade ΔE00 against `referenceDeltaE00(a, b)`.
- Act: `h.whenChooseA/B(name)`, `h.whenSwap()`, `h.whenSpeak()`, `h.whenOpenReadout(ComparisonSlot.a/.b)`.
- Register each AC: `acTestWidgets('AC-n', '…', (tester) async {…});` in `comparison_test.dart`. Default run
  skips pending; red baseline = `--dart-define=BS03_RUN_PENDING=true flutter test
  integration_test/comparison_test.dart`. Un-pend by deleting the AC's row in `bs03/pending.dart`.
- **AC-4 literal:** blocked by **G-4** — the stated LCh pair computes ΔE00 ≈ **13.05** (confirmed by the
  reference), not the spec's 14.2; write AC-4's expected string as `TODO(G-4)` and keep it pending until G-4.

**Verification commands** (`export PATH="$HOME/development/flutter/bin:$PATH"`):
`flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart <base>` ·
`flutter test integration_test/comparison_test.dart` (default) ·
`--dart-define=BS03_RUN_PENDING=true flutter test integration_test/comparison_test.dart` (run-pending).
Integration runs on the iOS sim (exclusive lane — `coord.sh with-lock` in parallel sessions).

**Next:** ITEST-2 (AC-1,2,3,10,11,12) ∥ ITEST-3 (AC-4,5,6,7,8,9) — disjoint catalogue rows in the same
file; coordinate the shared `comparison_test.dart` / harness-vocabulary edits.

## Phase 2 — AC-1,2,3,10,11,12 (ITEST-2)

- **Kind:** acceptance-tests
- **Target AC:** AC-1, AC-2, AC-3, AC-10, AC-11, AC-12 (selection / swap / open-readout / invite)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/comparison_test.dart` (these rows); may extend the harness vocabulary.
- **Tasks:** write one *pending* test per AC per the catalogue (exact Thens + Rejects); record the red
  baseline (run-pending) for each; grade each A (Given built via public flows and asserted; the Then at the
  step's grain; a real Rejects).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended Then
  / precondition; grades recorded.
- **Acceptance gate:** *(acceptance-tests — suite green with new tests pending; red baseline recorded; grade
  gate passed)*

### Result

**Landed.** One *pending* `acTestWidgets` per AC in `integration_test/comparison_test.dart` (new "ITEST-2 —
selection / swap / open-readout / invite" group), driving the real assembled app via the harness:
- **AC-1** `TestAC01_ChooseA` — opens the picker (E3→E49), asserts it lists all 5 catalogue samples (Given),
  picks "Warm Terracotta", asserts `state.slotA` = it / `slotB` null and the slots region renders
  `Slot A: Warm Terracotta` **and** the exact `L 58, C 34, h 42 degrees` (name-only slot rejected).
- **AC-2** `TestAC02_ChooseB` — Given A via the AC-1 flow (asserted), chooses B, asserts `slotB` = Raw Sienna
  Light, `slotA` unchanged (B-into-A rejected), slots show `L 70, C 25, h 60 degrees`.
- **AC-3** `TestAC03_Swap` — Given A+B with the A→B statement reading `Lighter by 12` (DIFF-3 precondition);
  swaps; asserts slots exchanged (read endpoint + `Slot A: Raw Sienna Light`) and the statement flips to
  `Darker by 12` **and** `isNot(Lighter by 12)` (rejects a relabel-only / no-op swap).
- **AC-10/AC-11** `TestAC10_OpenReadoutA` / `TestAC11_OpenReadoutB` — a control pair: each selects the one
  slot, opens its readout, asserts the Readout screen (`find.text('Readout')`) shows the sample's name in
  `NameHeader.headerKey` (wrong-sample / no-nav rejected; the pair rejects an always-one-slot impl).
- **AC-12** `TestAC12_InviteSecond` — Given A only; asserts `hasBothSlots` false, `comparison` null, no
  decomposition line in the statement region, and an **enabled** `Choose sample B` control (rejects a
  one-sample statement and the inert shell button).

**Harness vocabulary** (comparison_harness.dart): added `whenOpenPicker(slot)` (open E3/E5 without picking,
for AC-1's Given) and made `_choose` baseline-safe — it opens the picker then `expect`s the picker lists the
name (reason names COMPARE-3) **before** tapping the entry, so a not-yet-built picker fails on that
precondition instead of panicking on a missing widget. `whenChooseA/B` now take a `ComparisonSlot`.

**Gates.** `flutter analyze` clean. Unit **247 green**; coverage gate **PASS** (no touched `lib/**` — tests
only). Acceptance default `flutter test integration_test/comparison_test.dart` **green: 10 pass + 6 pending
(skipped)**. Red baseline (`--dart-define=BS03_RUN_PENDING=true`) **10 pass / 6 fail**, each on a clean
`expect` (see *Red baseline*), no panic/compile error. **Grades: 6×A, 0×B** — graded by an independent fresh
subagent against G1–G6; grid appended at `../behavior-test-completeness-bs-03-relative-comparison.md`.
**Fix passes: 0/3.** No coverage exclusions. No augmentation rows assigned to ITEST-2's ACs (the one
pre-seeded augmentation, TestAC04, is ITEST-3/DIFF-2's).

**Deviations / notes.** All six fail at the **COMPARE-3 selection** Given precondition at baseline (the
picker lists nothing in the shell): AC-1/2/12 fail at their own owning phase; AC-3 (COMPARE-5) and
AC-10/11 (COMPARE-6) stack on COMPARE-3's selection first, and AC-3 also stacks DIFF-3's `Lighter by 12`
Given — honest and acceptable (a Given precondition naming its owning phase). **Toolchain gotcha** (see
Checkpoint): `coord.sh with-lock` runs its command from `FNP_COORD_REPO` (the primary checkout), so a
worktree integration run must `cd` into the worktree inside the locked command or it silently tests the
primary's committed file.

### Checkpoint / Handoff

**Frozen for ITEST-3 and the behaviour phases:**
- The six ITEST-2 tests live in the "ITEST-2 — …" group at the end of `comparison_test.dart`'s `main`.
  ITEST-3 appends its AC-4..AC-9 group below them (shared file — merge-risky pair; keep edits anchored).
- Harness additions ITEST-3 inherits: `whenOpenPicker(ComparisonSlot)`; `whenChooseA/B(name)` now open the
  picker, **assert it lists `name`** (reason: COMPARE-3), then pick — so any AC whose Given chooses a sample
  fails cleanly at that precondition until COMPARE-3 lands, not with a panic.
- Behaviour-phase contracts these tests pin (un-pend by deleting the AC's row in `bs03/pending.dart`):
  COMPARE-3 must render `Slot A: <name>` / `Slot B: <name>` **and** `L 58, C 34, h 42 degrees` style lines,
  drive the E49 picker over `savedSamples`, enable the Choose-B control + suppress the statement with one
  slot; COMPARE-5's swap must re-express direction (`Lighter`↔`Darker`); COMPARE-6 wires `AppRouter.toReadout`
  so Open-readout pushes the bs-01 Readout showing the sample's stored name.

**⚠ Verification in a worktree (parallel sessions).** `coord.sh with-lock` first `cd`s to `$FNP_COORD_REPO`
(the primary checkout, where the shared lock lives), then runs your command **there** — so a bare
`flutter test …` under the lock tests the *primary's committed* code, not your worktree. Run integration
tests as:
`$C with-lock <FEATURE> <PHASE> --wait 900 -- bash -c "cd <WORKTREE> && flutter test <args>"`.
(Unit tests / `flutter analyze` were run directly in the worktree, no lock needed — shared lane.)

**Verification commands** (`export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
`flutter test --coverage` · `dart run tool/coverage_gate.dart <base>` · default + run-pending integration as
above (iOS sim, exclusive lane). `--dart-define=BS03_RUN_PENDING=true` **does** reach the sim binary
(verified) — the earlier "+10 all passed, nothing skipped" was the with-lock cwd bug, not the define.

**Next:** ITEST-3 (AC-4,5,6,7,8,9) — the remaining AC-test phase; then ITEST-4 (test review, G-3).

## Phase 3 — AC-4,5,6,7,8,9 (ITEST-3)

- **Kind:** acceptance-tests
- **Target AC:** AC-4, AC-5, AC-6, AC-7, AC-8, AC-9 (difference / decomposition / confusion / speak)
- **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/comparison_test.dart` (these rows); harness fixtures.
- **Tasks:**
  1. Write one *pending* test per AC per the catalogue; record the red baseline.
  2. **Construct and verify** `SAMPLE_UMBER`/`SAMPLE_ULTRAMARINE` as a genuine deutan confusion-line pair
     (projected ΔE00 below the confusion threshold while normal ΔE00 is clearly-different); if no such pair
     can be found, raise it to the spec author.
  3. AC-4: write the expected ΔE00 literal as a `TODO(G-4)` placeholder until G-4 resolves; keep the pair's
     deltas (12/9/18) assertable regardless.
  4. Grade each A (ΔE00/confusion checked against the harness's independent reference, not the impl).
- **Exit criteria:** default suite green (these pending); run-pending shows each failing at its intended
  Then; grades recorded; the confusion-line pair verified.
- **Acceptance gate:** *(acceptance-tests — as ITEST-2)*

### Result

**Landed.** One *pending* `acTestWidgets` per AC (AC-4..AC-9) in the new "ITEST-3 — difference /
decomposition / confusion / speak" group of `integration_test/comparison_test.dart`, driving the real
assembled app via the harness; observed through rendered region text + the `ComparisonReadEndpoint` state
(`comparison` ΔE00/verdict/3 lines, `confusable`) and `FakeSpeech`:
- **AC-4** `TestAC04_OverallDelta` (→DIFF-2) — A=Terracotta,B=Sienna; asserts the difference region reads
  `delta-E00 13.1` **and** `clearly different`, and `state.comparison.deltaE00` `closeTo` the independent
  `referenceDeltaE00` (≈13.05, ±0.1) with verdict `clearly different` — so a ΔE76/Euclidean metric fails.
  *Limited* (one pair can't show the verdict tracks distance); DIFF-2 augments with a near-identical control.
- **AC-5** `TestAC05_Decompose` (→DIFF-3) — exact `Lighter by 12` / `Less saturated by 9` /
  `Hue shifted 18 degrees toward yellow` in the statement region **and** on `state.comparison.{lightness,
  saturation,hue}` (the 12/9/18 only come out in LCh; rejects a*/b* Euclidean and inverted signs).
- **AC-6** `TestAC06_SameHue` (→DIFF-3) — A=Terracotta,B=Terracotta Tint (both h 42°); `state.comparison.hue
  == 'Same hue'` while lightness/saturation still state deltas; rejects a tiny non-zero shift
  (`isNot(contains('Hue shifted'))`) **and** whole-statement suppression (lightness line still present).
- **AC-7** `TestAC07_ConfusionFlagged` (→CVD-2) — deutan; A=Umber,B=Terre Verte; asserts profile deutan +
  both set + the pair's normal ΔE00 clearly-different (independent reference) → `state.confusable` true and the
  warning region says `identical` … `different`. Control: AC-8.
- **AC-8** `TestAC08_NotConfusable` (→CVD-2) — deutan; A=Terracotta,B=Sienna (off-line) → `state.confusable`
  false and no `identical` warning after settle; rejects an always-warn detector.
- **AC-9** `TestAC09_SpeakIncludesWarning` (→CVD-3) — warning shown for the confusable pair, speech empty;
  `whenSpeak` → exactly one utterance containing **both** `identical` (warning) and `Hue shifted` (statement);
  rejects omitting the warning, speaking nothing, multiple utterances, and speaking only the warning.

**Confusion-pair construct-and-verify (plan task 2).** The old `SAMPLE_UMBER`/`SAMPLE_ULTRAMARINE`
(brown/blue) are **not** a confusion pair under any dichromacy — verified they *expand* under the Viénot-1999
deutan/protan/tritan projections (blue↔yellow is preserved). Raised to the spec author → renamed B to
`SAMPLE_TERRE_VERTE` "Terre Verte Shadow", keeping deutan. Repinned `SAMPLE_UMBER`=(40,18,16),
`SAMPLE_TERRE_VERTE`=(40,−10,18): normal ΔE00 ≈ 28, deutan-projected ΔE00 ≈ 1.4 — a genuine deutan confusion
pair. Added an **independent** `referenceDeutanProjected` (Viénot 1999, test-only, the deutan analogue of
`referenceDeltaE00`) and a guard group proving: the pair collapses under the projection while staying
clearly-different normally; the AC-8 off-line control does **not** collapse; and the projection is
well-formed (neutral grey fixed, idempotent). CATALOGUE + the catalogue-guard name updated; spec lines 48
(G-4) and 72 (rename) amended.

**Harness.** `givenComparison`'s `confusionCheck` made optional (null ⇒ the app's shipped default applies),
so AC-7/8/9 exercise CVD-2's real detector automatically once it ships — with no forward reference to a
not-yet-built class.

**Gates.** `flutter analyze` clean. Unit **247 green**; coverage gate **PASS** (no touched `lib/**` — tests
only). Acceptance default `flutter test integration_test/comparison_test.dart` **14 pass + 12 pending
(skipped)** (14 = smoke + guards, incl. the 3 new deutan-pair guards + the AC-7 geometry guard). Red baseline
(`--dart-define=BS03_RUN_PENDING=true`) **14 pass / 12 fail**, each AC-4..9 on a clean `expect` at the
COMPARE-3 selection Given precondition (see *Red baseline*), no panic/compile error. **Grades: 6×A AC + A
guards, 0×B** — graded by an independent fresh subagent against G1–G6; grid appended at
`../behavior-test-completeness-bs-03-relative-comparison.md`. **Fix passes: 0/3.** No coverage exclusions.

**Deviations / notes.** All six fail at baseline on the **COMPARE-3** selection Given (the picker lists
nothing in the shell), *upstream* of each test's own owning phase — the same owning-phase precondition
stacking accepted for ITEST-2's AC-3/10/11 (a Given precondition naming a real phase; clean `expect`, no
panic). Run in a **worktree** (`/Users/matthew.quirk/Nuance-wt-bs03-ITEST-3`, branch
`phase/bs-03-relative-comparison/ITEST-3`) because the primary checkout was occupied by a live bs-02 session;
master-plan rollup deferred (reconcile from the primary).

### Checkpoint / Handoff

**Frozen for ITEST-4 (test review) and the behaviour phases:**
- All **12** ACs now have one pending, grade-A `acTestWidgets` in `comparison_test.dart` (ITEST-2 group:
  AC-1,2,3,10,11,12; ITEST-3 group: AC-4..9). Un-pend by deleting the AC's row in `bs03/pending.dart`.
- **Behaviour-phase contracts these tests pin:** DIFF-2 → difference region renders `delta-E00 13.1` +
  verdict `clearly different`, and `Comparison.deltaE00` is CIEDE2000 (matches `referenceDeltaE00` ±0.1);
  DIFF-3 → `Comparison.{lightness,saturation,hue}` = `Lighter by 12` / `Less saturated by 9` /
  `Hue shifted 18 degrees toward yellow`, and `Same hue` when the hue is unchanged (no "Hue shifted 0…");
  CVD-2 → `ConfusionCheck` real deutan projection making `state.confusable` true for Umber/Terre Verte and
  false for Terracotta/Sienna, and `ConfusionRegion` renders a warning containing `identical` … `different`
  when true / nothing when false; **CVD-2 must also make its real detector the app's shipped default
  `AppDependencies.confusionCheck`** (the harness no longer forces `NoopConfusionCheck`); CVD-3 → `whenSpeak`
  emits exactly one `Speech.speak` utterance containing both the statement and the warning text.
- **Fixtures:** `SAMPLE_UMBER` / `SAMPLE_TERRE_VERTE` are the deutan confusion pair (verified); CVD-2's
  shipped detector must agree with `referenceDeutanProjected` (threshold 2.0 projected / 15 normal).
- **AC-4 augmentation** (DIFF-2): add a near-identical control pair reading a *different* verdict band.

**⚠ Verification in a worktree** (unchanged from ITEST-2): `coord.sh with-lock` runs its command from
`$FNP_COORD_REPO` (the primary checkout), so a worktree integration run must
`bash -c "cd <WORKTREE> && flutter test …"`. Unit / `flutter analyze` run directly in the worktree.

**Verification commands** (`export PATH="$HOME/development/flutter/bin:$PATH"`): `flutter analyze` ·
`flutter test --coverage` · `dart run tool/coverage_gate.dart <base>` · default + run-pending integration
(`-d <iOS-sim>`, under the lock) as above.

**Next:** ITEST-4 (test review → G-3) — assemble the packet for all 12 ACs, run the full regression, present
for the human G-3 decision. Blocks every behaviour phase.

## Phase 4 — Test review (ITEST-4)

- **Kind:** test-review
- **Target AC:** — (G-3)
- **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (per-AC test + exact Thens + Rejects, the red baseline, the grade
  grid, the pre-seeded augmentation, the G-4 placeholder); run the full regression; present for the human
  decision (G-3).
- **Exit criteria:** packet assembled; full suite green (AC tests pending); grade grid complete.
- **Acceptance gate:** human records G-3.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_ChooseA | ❌ fails | Given: picker lists the saved samples (COMPARE-3 E49) — `find.text('Warm Terracotta')` findsWidgets | COMPARE-3 | A |
| AC-2 | TestAC02_ChooseB | ❌ fails | Given: choose A via the picker (COMPARE-3) — `_choose` picker-lists-"Warm Terracotta" precondition | COMPARE-3 | A |
| AC-3 | TestAC03_Swap | ❌ fails | Given: choose A (COMPARE-3) — picker precondition (stacks before swap/DIFF-3 Then) | COMPARE-5 | A |
| AC-4 | TestAC04_OverallDelta | ❌ fails | Given: choose A (COMPARE-3) — `_choose` picker-lists-"Warm Terracotta" precondition (stacks before the DIFF-2 Then) | DIFF-2 | A |
| AC-5 | TestAC05_Decompose | ❌ fails | Given: choose A (COMPARE-3) — picker precondition (stacks before the DIFF-3 Then) | DIFF-3 | A |
| AC-6 | TestAC06_SameHue | ❌ fails | Given: choose A (COMPARE-3) — picker precondition (stacks before the DIFF-3 Then) | DIFF-3 | A |
| AC-7 | TestAC07_ConfusionFlagged | ❌ fails | Given: choose A "Mid Raw Umber" (COMPARE-3) — picker precondition (stacks before the CVD-2 Then) | CVD-2 | A |
| AC-8 | TestAC08_NotConfusable | ❌ fails | Given: choose A (COMPARE-3) — picker precondition (stacks before the CVD-2 Then) | CVD-2 | A |
| AC-9 | TestAC09_SpeakIncludesWarning | ❌ fails | Given: choose A "Mid Raw Umber" (COMPARE-3) — `_choose` precondition (stacks before the CVD-3 speak Then) | CVD-3 | A |
| AC-10 | TestAC10_OpenReadoutA | ❌ fails | Given: choose A (COMPARE-3) — picker precondition (stacks before the COMPARE-6 Then) | COMPARE-6 | A |
| AC-11 | TestAC11_OpenReadoutB | ❌ fails | Given: choose B (COMPARE-3) — picker-lists-"Raw Sienna Light" precondition | COMPARE-6 | A |
| AC-12 | TestAC12_InviteSecond | ❌ fails | Given: choose A (COMPARE-3) — picker precondition (before the invite Then) | COMPARE-3 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC04 | one sample pair at write time cannot show the verdict tracks distance (a constant verdict string would pass) | DIFF-2 | a near-identical control pair asserting a **different** verdict band | ⬜ Open |
