# Sign-off packet — CVD self-assessment (onboarding) (bs-07) — Round 1

**Feature:** bs-07-cvd-self-assessment · **Spec:** [bs-07-cvd-self-assessment.feature](../../bs-07-cvd-self-assessment.feature)
**Prepared:** 2026-10-13 (SIGNOFF-1) · **At code:** `feat/bs-07-cvd-self-assessment` @ `df530dd` (FLOW-2; the sign-off commit is stamped on the decision)
**Decision:** ⏸ **Awaiting sign-off** — a human records Approved or Changes requested (the agent never approves).

All 14 acceptance criteria are coded, un-pended and green by default (nothing pending); the full
cross-feature regression (bs-01/02/03/04/05/06 + bs-07) is green; a fresh independent full-suite grade grid
is **14×A, 0 below A**. This packet is the evidence for the decision.

To record the decision:
`/feature-next-phase --signoff bs-07-cvd-self-assessment approved | changes "<items>"`
(`bs07` also resolves.)

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 21/21 build phases ✅ Done (ENGINE / PROFILE / FLOW / ITEST modules all complete) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-14 all ✅ Done |
| Pending list empty | ✅ `integration_test/bs07/pending.dart` `pendingACs = {}` |
| No open row in ITEST *Test augmentations* | ✅ all 7 driver/behaviour rows ✅ Closed (ENGINE-4/5, FLOW-4 ×3, FLOW-6, PROFILE-2); the one remaining row (sim/dalt) is explicitly **out of scope** (bs-08/bs-10) |
| Fresh whole-suite grade grid all A | ✅ 14×A / 0 below A (fresh independent adversarial grader, this session) |
| No open decision/dependency gates | ✅ G-1 (spec), G-2 (test review), G-3/G-4 (foundation merges), G-5 (four-step reconciliation) all ✅ Resolved |

---

## 2. Full verification (bs-07 worktree checkout, this session)

Toolchain: Flutter 3.47.6 stable (framework 5fc346839b, 2026-09-30); iOS sim iPhone 17 `5AB9D06D…51685`; both
integration runs under the verify lock (`coord.sh with-lock bs-07-cvd-self-assessment SIGNOFF-1`).
Machine-readable results produced on the first run (`flutter test … --machine`) for both integration runs; the
summary page (§8) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze lib test` | **No issues found** (clean, 31s) |
| Unit + coverage | `flutter test --coverage` | **1069 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all touched bs-07 `lib/` files (first run; no flake) |
| Acceptance — all features (default) | `flutter test integration_test/ -d <udid> --machine` | **155 passed, 0 failed, 0 skipped** |
| Acceptance — bs-07 (run-pending) | `flutter test integration_test/self_assessment_test.dart -d <udid> --dart-define=BS07_RUN_PENDING=true --machine` | **24 passed, 0 failed, 0 skipped** — identical to default (nothing pending) |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **14×A, 0 below A — PASS** (14 AC tests; fresh independent adversarial grader) |

**Full-regression breakdown (155):** bs-01 harness `harness_test.dart` 5 · bs-01 readout `readout_test.dart` 12 ·
bs-02 `capture_test.dart` 19 · bs-03 `comparison_test.dart` 26 · bs-04 `recipes_test.dart` 24 ·
bs-05 `correction_test.dart` 22 · bs-06 `palette_test.dart` 23 · **bs-07 `self_assessment_test.dart` 24**.
(bs-08 and bs-09 merged to `main` after bs-07 branched, so they are not in this checkout — see §6.)

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green. The scoring outputs are graded against the harness's
**independent** references, never the product function that computes them (same discipline as bs-03's AC-7):
screening direction (AC-5) against the fixtures' declared axes (pinned by a never-pending guard
`screeningPlates*.map(axis) == ScreeningStep.plateDeck`); threshold severity ordering (AC-9) against the
fixtures' independent detection-ordering; the plain-language band (AC-11) against a hand-written
`referenceBand`; the confusion-pipeline reconfiguration (AC-13) against the shipped `DichromatConfusionCheck`
on `fixedPair` plus the live `AppDependencies.cvdProfile` value.

| AC | Scenario | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | The estimate is labelled approximate and a clinical test is recommended | `TestAC01_EstimateLabelledApproximate` | FLOW-8 | ✅ green |
| AC-2 | The lighting setup must be confirmed before testing begins | `TestAC02_LightingConfirmedBeforeTesting` | FLOW-3 | ✅ green |
| AC-3 | An intake answer contributes to the starting prior | `TestAC03_IntakeAnswerToPrior` | ENGINE-3 | ✅ green |
| AC-4 | A prior clinical diagnosis entered at intake seeds the prior | `TestAC04_DiagnosisSeedsPrior` | ENGINE-4 | ✅ green |
| AC-5 | Screening yields presence and the red-green versus blue-yellow direction | `TestAC05_ScreeningPresenceAndDirection` | ENGINE-5 | ✅ green |
| AC-6 | The painter places colour caps in hue order | `TestAC06_PlaceCapNextPosition` | FLOW-4 | ✅ green |
| AC-7 | Starting over clears the arrangement | `TestAC07_StartOverClearsArrangement` | FLOW-4 | ✅ green |
| AC-8 | The painter skips the arrangement for now | `TestAC08_SkipArrangement` | FLOW-4 | ✅ green |
| AC-9 | Threshold probing yields a severity along the confusion line | `TestAC09_ThresholdSeverity` | ENGINE-6 | ✅ green |
| AC-10 | The painter adjusts the estimated type by hand | `TestAC10_AdjustTypeByHand` | FLOW-6 | ✅ green |
| AC-11 | The severity value sets a plain-language band | `TestAC11_SeverityBand` | ENGINE-7 | ✅ green |
| AC-12 | The severity slider doubles as subjective self-calibration | `TestAC12_SelfCalibration` | FLOW-7 | ✅ green |
| AC-13 | Saving the profile configures simulation, daltonization and confusion warnings | `TestAC13_SaveConfiguresPipeline` | PROFILE-2 | ✅ green |
| AC-14 | The current step is shown against the total | `TestAC14_ProgressStepOfTotal` | FLOW-2 | ✅ green |

**Grade grid:** `../behavior-test-completeness-bs-07-cvd-self-assessment.md` — a fresh SIGNOFF-1 full-suite
re-grade (fresh-context adversarial grader that did not write the tests) found **14×A, 0 below A**. The
grader traced every Given/When/Then into the real production widgets/controllers/engine, confirmed each AC
rejects a named wrong implementation, and verified the scoring ACs (AC-5/9/11/13) grade against the
independent reference, not the shipped scorer.

---

## 4. Augmentations made (closed)

Seven AC tests were scheduled for strengthening at the test review (limited only by behaviour/driver not yet
built); each was closed by the behaviour phase that produced the real output (ITEST *Test augmentations*
table). The re-graded test is A in every case:

- **TestAC04** (ENGINE-4) — `whenReportDiagnosis` gained a `CvdType` argument; a fresh-flow **protan control**
  now discriminates the seeded type. B-pending → A.
- **TestAC05** (ENGINE-5) — `whenScreenPlates` feeds a full per-plate response fixture; a **B-Y direction
  control** + a **no-deficiency presence control** discriminate presence and axis against the independent
  fixture axes. B-pending → A.
- **TestAC06 / TestAC07 / TestAC08** (FLOW-4) — `whenPlaceCap` + the `arrangementResult` observable let the
  place grain (exact arranged list, ±1 pool), start-over (full pool restored) and skip-vs-complete be driven
  and discriminated. B-pending → A.
- **TestAC10** (FLOW-6) — `whenAdjustType(CvdType)` taps a specific per-type choice; a true 3-way type
  discrimination with a deutan control. B-pending → A.
- **TestAC13** (PROFILE-2) — the reconfiguration is now asserted at the **live** `AppDependencies.cvdProfile`
  (and the `confusable(fixedPair, liveProfile)` flip), not only the saved value — rejecting a save that
  persists but leaves the pipeline on the default. B-pending → A.

Every other AC test (AC-1, 2, 3, 9, 11, 12, 14) was green at baseline once its behaviour landed and was
confirmed discriminating without augmentation.

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A (14×A); nothing was closed by user acceptance of a gap.

One **non-grade-affecting** grader note is recorded for transparency (it owes no augmentation):

- **Terminal pending-gate guard (pending-gate guards group).** With every AC delivered, `pendingACs` is now
  the empty map, so the guard `every pending AC is owned by a real behaviour phase` iterates zero entries and
  passes vacuously. This is the by-design terminal end state and is pinned **non-vacuously** by its two
  sibling guards in the same group: `pending map is exactly the still-pending ACs` asserts
  `pendingACs.keys.toSet() == {}` (exact empty, not a subset), and `pendingSkipReason skips pending ACs by
  default and runs them forced` asserts each delivered AC (AC-1…AC-14 enumerated) returns a null skip-reason
  in both default and forced modes, plus that an absent id runs in both. (bs-06 and bs-08 recorded the same
  terminal pattern; no downgrade.)

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** all resolved — G-1 (spec approval), G-2 (acceptance-test review, 2026-10-12 — Matt Quirk),
G-3/G-4 (bs-05+bs-06 foundation merge to `main`), and G-5 (four-step-vs-five-tier reconciliation,
2026-10-13 — Matt Quirk: the four counted steps are Lighting / Intake / Vision tests / Result). No open or
recorded-but-unresolved gates.

**Open known flakes** (carried from the bs-01/05/06 foundation; neither observed this session):

| Test | Symptom | Mitigation |
|---|---|---|
| coverage_gate const-constructor line | `flutter test --coverage` can intermittently record a const-folded constructor line as uncovered | re-run once; green on re-run ⇒ ignore. Did not occur this session (gate PASS first run). |
| integration without `-d <udid>` | a device-less run executes zero tests and still exits 0 (false green) | always pass `-d <booted-udid>`. Done — sim booted, the suite actually ran (155 / 24). |

**Known gaps / deferred by design (not defects):**

- **Behavioural simulation/daltonization is out of scope (D-8).** AC-13 requires that saving "configures
  simulation, daltonization and confusion warnings." The saved `CvdProfile` is written to the one shared seam
  (`AppDependencies.cvdProfile`) that all three consumers read, and the test asserts the **confusion-warning**
  reconfiguration behaviourally (bs-03's `DichromatConfusionCheck` on `fixedPair` flips, and the live
  dependency equals the saved profile). The **simulation** and **daltonization** consumers are bs-08 and
  bs-10, which live on `main` but are not in this unmerged branch, so their behaviour is verified at the
  shared profile seam only — a deliberate, documented gap owned by bs-08/bs-10, not a bs-07 defect.
- **The result step's simulated-vs-original colour pair is an illustrative stand-in (D-8).** The *simulated*
  swatch collapses toward grey as severity rises (an in-feature placeholder); the real per-channel CVD
  projection is bs-08/bs-10 behind `ConfusionCheck`. AC-12 grades the kept calibration value, not the pair's
  pixels, so this does not affect any AC.
- **bs-07 lives on its own unmerged branch.** It branched from `main` after the bs-05+bs-06 merge; bs-08 and
  bs-09 merged to `main` afterwards and are not in this checkout. On sign-off, `feat/bs-07-cvd-self-assessment`
  merges to `main` — which also closes **bs-10's G-4** (bs-10 daltonization is blocked on bs-07 reaching
  `main`).
- **The four onboarding steps are a single eager layout, not a one-step-at-a-time wizard (FLOW-2 scope).**
  The screens lay every step region out in one scroll view (as the shell built them and as every acceptance
  driver relies on). AC-14 requires only that the indicator show the current step of the total, which it does
  (`Step N of 4`, driven by `stepIndex`); a stepwise presentation is not in the spec and was deliberately not
  built.

---

## 7. Cost and tokens

From the *Token usage* ledger (29 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 221,239,688 tokens — input 3,346 · cache write 5,411,229 · cache read 214,390,429 · output 1,434,684.
- **Cost (API list rates, 2026-09-25):** **$192.27** (cache read $107.20 · cache write $49.19 · output $35.87 · input $0.02). All 29 sessions priced from their transcripts.
- **Span:** 2026-10-11 21:04 EDT → 2026-10-13 11:23 EDT — **Σ active 8h 43m** (Σ wall 12h 53m).
- **By stage:** scaffold $3.51 · shells $20.42 · acceptance tests $23.94 · test review $1.32 · behaviour (direct) $110.25 · enabler (FLOW-5, no AC) $9.75 · sign-off $6.76 · activities (plan/reconcile/gate+sign-off decisions) $16.33.
- **Per-AC (fully loaded, sums to the feature total):** shared work $5.86/AC; fully loaded $9.93 (AC-6/7/8) … $18.42 (AC-5), mean ≈ $13.73; direct behaviour $4.07 (AC-6/7/8) … $12.56 (AC-5).

---

## 8. Summary page

Acceptance-suite summary page (built from this session's machine-readable results):
**→ https://claude.ai/artifact/5MC64zZMBtLL2KysJ9UCcJ** — "bs-07 Sign-off Scorecard" (verification headline, 14 ACs with grades,
augmentations, cost). Private to the owner; share from the page's Share menu for other reviewers. Its headline
(unit 1069 · coverage 100% touched · regression 155 · bs-07 24 default + 24 run-pending · 14×A) matches this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the bs-07 worktree root; open the self-assessment from the
vision-profile card (the stable `ValueKey('self-assessment-entry-screen')` anchor). To watch the whole
contract run green end to end: `flutter test integration_test/self_assessment_test.dart -d <booted-udid>`
(24 tests).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| The self-assessment estimates; it does not diagnose | Complete the flow to the result (tap "See my result"). | The result labels itself an **approximate estimate, not a clinical diagnosis** and recommends a **clinical anomaloscope test** for ground truth. |
| Tier 0 — display and lighting setup precedes testing | On the lighting step, tap **Continue** without confirming the three checks; then confirm brightness / night-light-off / daylight and tap Continue. | Unconfirmed, nothing happens (testing does not begin). With all three confirmed, the flow advances and testing starts. |
| Tier 1 — intake questions form a starting prior | Answer the confusion-frequency question "Often"; in a fresh flow, tap "I have a diagnosis" and pick **deutan**. | "Often" leans the prior red-green (non-zero weight); a reported diagnosis seeds the prior's **type** authoritatively, overriding the intake lean. |
| Tier 2 — pseudoisochromatic screening detects presence and direction | Work the plate screening with a red-green-deficient response; repeat with a blue-yellow fixture and a no-deficiency one. | Screening reports **present** with **red-green** (or **blue-yellow**) direction; a clean read reports **not present**. |
| Tier 3 — the arrangement test orders colour caps by hue | Tap caps to place them; use **Start over**; in another run use **Skip**. | Each placed cap takes the next arranged position and leaves the pool; Start over returns every cap to the pool; Skip continues the flow with **no arrangement result**. |
| Tier 4 — adaptive threshold probing yields a severity | Answer the "I can / can't see it" probes. | The highest contrast the painter failed to detect becomes the **severity** along the confusion line. |
| The result states type and severity, adjustable by the painter | On the result, tap a different type in the picker; drag the severity slider; read the band. | The **type** changes to the chosen one; the slider's value is kept as the **subjective self-calibration**; the severity shows a plain-language **band** (mild / moderate / strong) that tracks the slider. |
| Saving writes one profile that configures the CVD pipeline | Tap **Save**. | Exactly one `CvdProfile` is persisted, and the live CVD pipeline reconfigures immediately — bs-03's confusion check on a fixed colour pair now reflects the saved type/severity. |
| Progress across the steps is shown | Move through the flow. | The progress indicator reads **Step N of 4** and advances with each top-level step (Lighting → Intake → Vision tests → Result); the nested Tier 2/3/4 tests do not advance the counter. |

A reviewer who wants to see the tests fail honestly can revert a behaviour phase's un-pend (restore a row in
`integration_test/bs07/pending.dart`) and re-run: that AC's test goes red on its own Then, confirming the
tests discriminate. (Run-pending mode is identical to default now — nothing is pending.)

---

## 10. Decision

Reviewer: **________**  Date: **________**  Decision: ☐ **Approved**  ☐ Changes requested

Signed off at code `df530dd` (FLOW-2; the SIGNOFF-1 packet makes no product-code change, so the signed tree
equals the verified tree). On **Approved**, `feat/bs-07-cvd-self-assessment` merges to `main` (closes bs-10 G-4).

Record via `/feature-next-phase --signoff bs-07-cvd-self-assessment approved | changes "<items>"`.

- **Approved** → SIGNOFF-1 ✅; feature `Status: Done — signed off <date> by <reviewer> at <commit>`.
- **Changes requested** → each item becomes a new phase before a fresh SIGNOFF-2; this round's file stays as history.
