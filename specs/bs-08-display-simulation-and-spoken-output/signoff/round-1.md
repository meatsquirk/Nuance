# Sign-off packet — Display, simulation and spoken output (bs-08) — Round 1

**Feature:** bs-08-display-simulation-and-spoken-output · **Spec:** [bs-08-display-simulation-and-spoken-output.feature](../../bs-08-display-simulation-and-spoken-output.feature)
**Prepared:** 2026-10-12 (SIGNOFF-1) · **At code:** `feat/bs-08-display-simulation-and-spoken-output` @ `5e5c531` (SPEECH-4; the sign-off commit is stamped on the decision)
**Decision:** ⏸ **Awaiting sign-off** — a human records Approved or Changes requested (the agent never approves).

All 10 acceptance criteria are coded, un-pended and green by default (nothing pending); the full
cross-feature regression (bs-01/02/03/04/05/06 + bs-08) is green; a fresh independent full-suite grade grid
is **21×A, 0 below A**. This packet is the evidence for the decision.

To record the decision:
`/feature-next-phase --signoff bs-08-display-simulation-and-spoken-output approved | changes "<items>"`
(`bs08` also resolves.)

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 18/18 build phases ✅ Done (DISPLAY / SETTINGS / SPEECH / ITEST modules all complete) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-10 all ✅ Done |
| Pending list empty | ✅ `integration_test/bs08/pending.dart` `pendingACs = {}` |
| No open row in ITEST *Test augmentations* | ✅ the one row (AC-7 → DISPLAY-8) is ✅ Closed 2026-10-12 |
| Fresh whole-suite grade grid all A | ✅ 21×A / 0 below A (fresh independent adversarial grader, this session) |
| No open decision/dependency gates | ✅ G-1 (spec) and G-2 (acceptance-test review) both ✅ Resolved |

---

## 2. Full verification (bs-08 worktree checkout, this session)

Toolchain: Flutter 3.47.6 stable (framework 5fc346839b); iOS sim iPhone 17 `5AB9D06D…51685`; both integration
runs under the verify lock (`coord.sh with-lock bs-08 SIGNOFF-1`). Machine-readable results produced on the
first run (`flutter test … --machine`) for both integration runs; the summary page (§8) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze lib test` | **No issues found** (clean, 5.1s) |
| Unit + coverage | `flutter test --coverage` | **931 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all **14** touched bs-08 `lib/` files (first run; no flake) |
| Acceptance — all features (default) | `flutter test integration_test/ -d <udid> --machine` | **152 passed, 0 failed, 0 pending** |
| Acceptance — bs-08 (run-pending) | `flutter test integration_test/display_test.dart -d <udid> --dart-define=BS08_RUN_PENDING=true --machine` | **21 passed, 0 failed, 0 skipped** — identical to default (nothing pending) |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **21×A, 0 below A — PASS** (10 AC tests + 2 smoke + 6 fixture guards + 3 pending-gate guards) |

**Full-regression breakdown (152):** bs-01 harness `harness_test.dart` 5 · bs-01 readout `readout_test.dart` 12 ·
bs-02 `capture_test.dart` 19 · bs-03 `comparison_test.dart` 26 · bs-04 `recipes_test.dart` 24 ·
bs-05 `correction_test.dart` 22 · bs-06 `palette_test.dart` 23 · **bs-08 `display_test.dart` 21**.
(bs-07 lives on its own unmerged branch and is not in this checkout — see §6.)

**The 14 touched `lib/` files at 100%:** `a11y/repeatable_speech.dart`, `app/build_app.dart`,
`color_science/conversions.dart`, `display/{color_simulation, display_controller, display_read_endpoint,
display_scope, display_settings, grayscale_filter, settings_screen, spoken_output_panel}.dart`,
`readout/{readout_controller, value_region}.dart`, `widgets/color_chip.dart`.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green. The simulated colour (AC-3/AC-4) and the simulated-reading
swatch (AC-7) are graded against the harness's **independent** `referenceProjectDichromat` (a literal
Viénot-1999 published-matrix projection), never the shipped `projectDichromat` — same discipline as bs-03's
AC-7. Only the CVD-neutral colour-space conversion is shared, by design.

| AC | Scenario | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | The painter opens the display and simulation settings | `TestAC01_OpenDisplaySettings` | SETTINGS-2 | ✅ green |
| AC-2 | With simulation off, displayed colour is shown as a trichromat sees it | `TestAC02_SimOffTrichromat` | DISPLAY-3 | ✅ green |
| AC-3 | The painter simulates a chosen deficiency type alongside the original (protan/deutan/tritan) | `TestAC03_SimulateTypeAlongsideOriginal` | DISPLAY-4 | ✅ green |
| AC-4 | The painter sets the simulation strength with the severity slider | `TestAC04_SeveritySlider` | DISPLAY-5 | ✅ green |
| AC-5 | Turning on grayscale clears an active simulation | `TestAC05_GrayscaleClearsSimulation` | DISPLAY-6 | ✅ green |
| AC-6 | The value-only view greys the camera and the palettes as well as the readings | `TestAC06_GrayscaleWholeApp` | DISPLAY-7 | ✅ green |
| AC-7 | A reading under simulation keeps its numeric value and label | `TestAC07_ReadingKeepsValueAndLabel` | DISPLAY-8 | ✅ green |
| AC-8 | The painter repeats the last spoken output | `TestAC08_RepeatSpokenOutput` | SPEECH-2 | ✅ green |
| AC-9 | Readings and comparisons are spoken through one consistent phrasing | `TestAC09_OneConsistentPhrasing` | SPEECH-3 | ✅ green |
| AC-10 | The spoken-output panel stays until the painter leaves it | `TestAC10_PanelNeverAutoDismisses` | SPEECH-4 | ✅ green |

**Grade grid:** `../behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md` — a fresh
SIGNOFF-1 full-suite re-grade (fresh-context adversarial grader that did not write the tests) found
**21×A, 0 below A**. The grader traced every Given/When/Then into the real production widgets/controllers,
confirmed each AC rejects a named wrong implementation, and verified the AC-3/4/7 comparisons use the
independent reference, not the shipped projection.

---

## 4. Augmentations made (closed)

One limited AC test was scheduled for strengthening; the behaviour phase that produced the real output closed
it (ITEST *Test augmentations* table, ✅ Closed):

- **TestAC07** (DISPLAY-8) — the sim-off test could not yet reject AC-7's real wrong implementation (a
  simulated reading that shows a colour **swatch with no value/label**), because no simulated swatch existed
  until DISPLAY-4. DISPLAY-8 strengthened it to assert the **simulated swatch** (`≈ referenceProjectDichromat`)
  coexists **alongside** the original swatch **and** the numeric value (`"55"`) + plain-language label — "not
  colour alone." AC-7 re-graded **B-pending-DISPLAY-8 → A**.

Every other AC test was green at baseline (the shells had already wired the behaviour) and was confirmed
discriminating without augmentation.

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A (21×A); nothing was closed by user acceptance of a gap.

Two **non-grade-affecting** grader notes are recorded for transparency (neither owes an augmentation):

- **Owner-guard terminal state (test #2, pending-gate guards).** `every pending AC is owned by a real
  behaviour phase` now iterates an empty `pendingACs` map, so it passes with zero iterations. This is the
  by-design terminal end state: its sibling guard asserts `pendingACs` is **exactly `{}`**, and a third guard
  asserts the gate runs every AC in both modes — so emptiness is pinned non-vacuously elsewhere. The owner
  guard checked real owners for the whole lifecycle until the final phase. (The bs-06 sign-off recorded the
  same pattern; no downgrade.)
- **Cosmetic doc-comment.** `integration_test/fakes/fake_haptics.dart` carries a stale "AC-12" reference (a
  non-bs-08 AC); harmless — no bs-08 AC exercises haptics. Comment-only, left untouched so the signed-off tree
  equals the verified tree; worth sweeping in a future touching change.

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** G-1 (spec approval, 2026-10-11) and G-2 (acceptance-test review, 2026-10-12 — Matt Quirk) both
✅ Resolved. No open or recorded-but-unresolved gates.

**Open known flakes** (carried from the bs-01/06 foundation; neither observed this session):

| Test | Symptom | Mitigation |
|---|---|---|
| coverage_gate const-constructor line | `flutter test --coverage` can intermittently record a const-folded constructor line as uncovered | re-run once; green on re-run ⇒ ignore. Did not occur this session (gate PASS first run). |
| integration without `-d <udid>` | a device-less run executes zero tests and still exits 0 (false green) | always pass `-d <booted-udid>`. Done — sim booted, the suite actually ran (152 / 21). |

**Known gaps / deferred by design (not defects):**

- **bs-07 populates the stored CVD profile (D-2, soft dependency, not a blocker).** bs-08 reads the painter's
  type/severity from `AppDependencies.cvdProfile`. Until bs-07 (CVD self-assessment) merges to `main`, that
  profile defaults to the const **deutan** profile; the simulation **setting** carries its own
  `simulationType`/`simulationSeverity` and the painter may still select **any** type (AC-3), so no AC depends
  on the stored profile. bs-07 is complete on its own branch and merges separately.
- **Theme control is a presentation affordance only (D-11).** AC-1 requires the theme control to be *shown*
  in the panel, and it is; its light/dark behaviour is explicitly out of the spec's scope and is not wired.
- **Spoken output is non-vocal in this build (bs-01 D-1).** `RepeatableSpeech` wraps the existing
  `NoopSpeech` seam — it records and re-speaks the last utterance (the observable AC-8/9/10 behaviour) but
  does not drive a native TTS engine yet. The acceptance suite injects `FakeSpeech` and observes the utterance
  log; a real voice engine is a later, seam-compatible upgrade.
- **Value-only grayscale is a single root-level `ColorFiltered` (D-5).** It greys the whole app — camera
  preview, palette swatches and readings — from one chokepoint; AC-6 asserts the filter is an ancestor of
  `MaterialApp` (root), rejecting a per-surface filter.

---

## 7. Cost and tokens

From the *Token usage* ledger (24 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 181,744,971 tokens — input 2,832 · cache write 4,331,950 · cache read 176,383,783 · output 1,026,406.
- **Cost (API list rates, 2026-09-25):** **$152.40** (cache read $88.19 · cache write $38.53 · output $25.66 · input $0.01). 21 of 24 sessions priced from their transcripts; 3 estimated at their ledger model (PLAN, DISPLAY-7, DISPLAY-8 — the two forks' marks were lost to parallel timing).
- **Span:** 2026-10-11 21:46 EDT → 2026-10-12 22:36 EDT — **Σ active 6h 34m** (Σ wall 7h 44m).
- **By stage:** scaffold $4.58 · shells $20.25 · acceptance tests $27.36 · test review $1.71 · behaviour (direct) $60.53 · sign-off $9.19 · activities (plan/reconcile) $28.79.
- **Per-AC (fully loaded, sums to the feature total):** shared work $9.19/AC; fully loaded $13.01 (AC-1) … $19.44 (AC-3), mean ≈ $15.24; direct behaviour $3.82 (AC-1) … $10.25 (AC-3).
- *Attribution note:* bs-08's module dashboards carry the full phase id in the `Phase` cell while `ac_cost.py` keys on a bare number, so the direct/fully-loaded split was computed against a format-normalized copy with identical ledger data; every figure reconciles with the master ledger's feature total.

---

## 8. Summary page

Acceptance-suite summary page (built from this session's machine-readable results):
**→ https://claude.ai/artifact/HRCron2pCDFGB5iAWwLNwb** — "bs-08 Sign-off Scorecard" (verification headline,
10 ACs with grades, augmentation, cost). Private to the owner; share from the page's Share menu for other
reviewers. Its headline (unit 931 · coverage 14/14 · regression 152 · bs-08 21 default + 21 run-pending ·
21×A) matches this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the bs-08 worktree root; the app opens on the Capture screen.
The display & simulation controls live in the settings panel reached by the **E2** entry (top-level, on any
screen): E47 CVD simulation selector, E48 simulation severity slider, E46 value-only grayscale toggle, and a
theme control. The **E50** spoken-output panel shows the last spoken phrase and its repeat control. To watch
the whole contract run green end to end: `flutter test integration_test/display_test.dart -d <booted-udid>`
(21 tests).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| Display & simulation settings are reached from any screen | Tap **E2** "Open display and simulation settings" from a reading. | The panel opens showing all three controls: the **E47** simulation selector, the **E46** value-only grayscale toggle, **and** a theme control. |
| The app can simulate the painter's CVD type over displayed colour | With simulation **off**, read the displayed swatch; then pick **deutan** (or protan/tritan) in **E47**. | Off: one swatch, the true (trichromat) colour. On: the simulated swatch (projected for the chosen type) appears **alongside** the untouched original — two distinct swatches. |
| The simulation strength follows a severity slider | With deutan selected, drag the **E48** severity slider to 60. | The simulated swatch strengthens to the 60%-severity projection (severity 0 = the original; full severity = the strongest shift). |
| Simulation & value-only grayscale are mutually exclusive | With a simulation active, turn on **E46** value-only grayscale. | The simulation turns **off** (one view at a time) and the app greys. Turning grayscale back off does **not** silently re-enable the simulation. |
| The whole app can be shown in value-only grayscale | With **E46** on, look at the camera preview and a palette. | The camera feed, the palette swatches **and** the readings are all greyed — one root filter, not just the readings. |
| Colour meaning never stands alone under any view | Under simulation, read a reading. | The reading still shows its **numeric value** and its **plain-language label** beside the swatch — never colour alone. |
| Spoken output uses consistent phrasing and can be repeated | Speak a reading, then speak a comparison; then tap **E50** "Repeat spoken output". | Both the reading and the comparison are spoken through the one shared speech service (one phrasing path); tapping repeat re-speaks the **same** last utterance verbatim. With nothing spoken yet, repeat is inert. |
| Spoken output never dismisses itself | Open the **E50** panel for a reading and leave the app idle. | The panel and its last-spoken phrase stay put — no timer dismisses it; it is removed only when the painter navigates away. |

A reviewer who wants to see the tests fail honestly can run with `--dart-define=BS08_RUN_PENDING=true`
(identical to default now — nothing pending) or revert a behaviour phase's un-pend and re-run: that AC's test
goes red on its own Then, confirming the tests discriminate.

---

## 10. Decision

Reviewer: **________________**  Date: **____________**  Decision: ☐ **Approved**  ☐ Changes requested

Record via `/feature-next-phase --signoff bs-08-display-simulation-and-spoken-output approved | changes "<items>"`.

- **Approved** → SIGNOFF-1 ✅; feature `Status: Done — signed off <date> by <reviewer> at <commit>`.
- **Changes requested** → each item becomes a new phase before a fresh SIGNOFF-2; this round's file stays as history.
