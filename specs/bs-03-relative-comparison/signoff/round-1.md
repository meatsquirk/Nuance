# Sign-off packet — Relative comparison (bs-03), round 1

**Feature:** [bs-03-relative-comparison.feature](../../bs-03-relative-comparison.feature) · **Master plan:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**At code:** `44da743` (CVD-3) — no product code changed during sign-off; this is a verification-only phase.
**Assembled:** 2026-10-08 by SIGNOFF-1 · **Decision:** ✅ **Approved 2026-10-08 by Matt Quirk (owner)** at code `44da743`

The agent never approves. Record the decision with:
`/feature-next-phase --signoff bs-03-relative-comparison approved | changes "<items>"`

---

## 1. Verdict at a glance

All 12 acceptance criteria are green on the iOS simulator, in **default and run-pending mode identically**;
every touched lib file is 100% line-covered and the whole lib is 100% (772/772 lines, 40 files); static
analysis is clean; and an independent fresh grader rated every un-pended test **A** (12×A, 0×B). No open
gates, no open test augmentations, no phases closed by user acceptance, no non-A grades.

| Precondition (signoff.md) | State |
|---|---|
| Every non-sign-off phase done | ✅ 16/16 (COMPARE, DIFF, CVD, SCREEN, ITEST all ✅) |
| Every AC ✅ in the coverage table | ✅ 12/12 |
| Pending list empty | ✅ `pendingACs` empty — all 12 run by default; default ≡ run-pending (43/43 each) |
| No open ITEST *Test augmentations* | ✅ none open — the one pre-seeded row (TestAC04) closed by DIFF-2 (verified in-test) |
| Fresh whole-suite grid grades every row A | ✅ 12×A, 0×B — independent fresh grader, 2026-10-08 (SIGNOFF-1 re-grade) |

---

## 2. Acceptance criteria — per-AC result

Suite: Flutter `integration_test` driving the assembled app via `buildApp(deps)` with the bs-03 comparison
entry (an injected `SampleSource` catalogue + `CvdProfile` + the real `DichromatConfusionCheck`), observed
through `WidgetTester`, the `ComparisonReadEndpoint` state seam, the `FakeSpeech` log and the current route,
on a booted iOS simulator (iPhone 17, `5AB9D06D-…`). Result below is from this session's run, **default mode**
(all 12 live) and **run-pending mode** — identical, **43/43 each** (12 ACs + bs-01's 12 Readout ACs carried on
the same branch + harness/smoke/pending-gate guards).

| AC | Scenario | Integration test | Result | Grade |
|---|---|---|---|---|
| AC-1 | Choose sample A from the saved samples | `TestAC01_ChooseA` | ✅ pass | A |
| AC-2 | Choose sample B from the saved samples | `TestAC02_ChooseB` | ✅ pass | A |
| AC-3 | Swapping exchanges the samples + re-expresses | `TestAC03_Swap` | ✅ pass | A |
| AC-4 | Overall difference as ΔE00 + plain verdict | `TestAC04_OverallDelta` | ✅ pass | A |
| AC-5 | Decompose into lightness, saturation, hue | `TestAC05_Decompose` | ✅ pass | A |
| AC-6 | An unchanged dimension reads "Same hue" | `TestAC06_SameHue` | ✅ pass | A |
| AC-7 | A confusable pair is flagged for the CVD type | `TestAC07_ConfusionFlagged` | ✅ pass | A |
| AC-8 | A clearly distinct pair is not flagged | `TestAC08_NotConfusable` | ✅ pass | A |
| AC-9 | Speaking the comparison includes the warning | `TestAC09_SpeakIncludesWarning` | ✅ pass | A |
| AC-10 | Open the full readout for sample A | `TestAC10_OpenReadoutA` | ✅ pass | A |
| AC-11 | Open the full readout for sample B | `TestAC11_OpenReadoutB` | ✅ pass | A |
| AC-12 | With no second sample, invite one | `TestAC12_InviteSecond` | ✅ pass | A |

Plus bs-01's 12 Readout ACs (carried on this branch) and the harness/smoke/pending-gate guards — all green.

---

## 3. Verification results (this session, machine-readable)

| Suite | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found** (ran in 30.8s) |
| Unit + coverage | `flutter test --coverage --reporter=json` | **303 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **100% line on all 14 touched files — PASS** |
| Coverage (whole lib) | from `coverage/lcov.info` | **772/772 lines = 100.00% across 40 files; 0 files below 100%** |
| Acceptance (default) | `flutter test integration_test/ -d <udid> --reporter=json` | **43/43 passed, 0 skipped** |
| Acceptance (run-pending) | `… --dart-define=BS03_RUN_PENDING=true` | **43/43 passed — identical** |

**Full cross-feature regression:** on this branch (`feat/bs-03-relative-comparison`, cut from `main` @
`c793839`) the product code is bs-01's foundation + bs-03's comparison. bs-02…bs-14 are spec files only (bs-02
lives on its own un-merged branch, not here). So the unit suite (303) + the whole `integration_test/` directory
(43: bs-01 Readout ACs + bs-03 Comparison ACs + harness/guards) **is** the whole regression on this branch; all
green, both modes. Raw JSON results captured this session (`unit.json`, `integ_default.json`,
`integ_pending.json`).

> ⚠️ `flutter test integration_test/` **without** `-d <udid>` runs **zero** tests and still exits 0 (a false
> green, carried from bs-01). This session always passed the booted simulator udid.

---

## 4. Test-completeness grade

Grid: [behavior-test-completeness-bs-03-relative-comparison.md](../behavior-test-completeness-bs-03-relative-comparison.md)
(§ *Sign-off re-grade (SIGNOFF-1) — 2026-10-08*). An independent fresh-context grader (did not write the code or
tests) re-graded **all 12 un-pended tests against the live behaviour** on 2026-10-08.

- **Counts: 12×A, 0×B. No downgrades** — every prior A holds against live behaviour; no drift between any
  asserted literal and what the widgets/controller emit (all fixture-derived values independently recomputed:
  terracotta/sienna ΔE00 = 13.05 → "delta-E00 13.1"; sienna/tint = 6.71 → "slightly different"; umber/terre-verte
  normal = 27.99, deutan-projected ≈ 1.4; LCh deltas +12 / −9 / +18° toward yellow).
- Each grade cites the rules it satisfies (G1–G6) and names the wrong implementations it rejects — e.g. AC-4's
  numeric match to the independent CIEDE2000 reference kills a ΔE76/Euclidean metric; AC-7/AC-8 are a control
  pair (on-line vs off-line under the same deutan profile) grounded by the independent D-5 projection guards;
  AC-10/AC-11 are a control pair that kills any "always opens one slot".

---

## 5. Augmentations, acceptances, exceptions

- **Test augmentations made:** `TestAC04` was augmented by **DIFF-2** with a near-identical control pair
  (Raw Sienna Light vs Terracotta Tint, ΔE00 ≈ 6.71 → the lower band "slightly different", `isNot('clearly
  different')`, endpoint verdict + ΔE00 against the independent reference), so a constant verdict string now
  fails — the pre-seeded one-pair limitation is **closed in-test**. **No augmentations remain open.**
- **Phases closed by user acceptance (with gaps):** none.
- **Non-A grades accepted:** none.

---

## 6. Open gates, flakes, and deferred items

**Open gates:** none. All five resolved — G-1 (spec approval) and G-3 (acceptance-test approval) by owner
Matt Quirk; G-2 (bs-01 foundation merged at `c793839`); **G-4** (AC-4 overall corrected to the computed
"delta-E00 13.1" — the spec's old 14.2 was the error) and **G-5** (deutan confusion pair corrected to
"Terre Verte Shadow", verified) by the spec author Matt Quirk. The spec was amended for G-4 and G-5.

**Open Known flakes (1):**

| Test | Symptom | Status |
|---|---|---|
| `coverage_gate` — a `const` constructor line in `lib/**` | Carried from bs-01: `flutter test --coverage` can intermittently record a const-folded constructor line as uncovered, so the gate may FAIL on a file the phase never touched. | Open. Re-run `flutter test --coverage` once; green on re-run ⇒ ignore. **This session's coverage run was green on the first pass** — the flake did not trigger (772/772 = 100%). |

**Known gaps / deferred by design:**
- **Production `SampleSource` is empty until bs-06 (D-7).** The comparison picker lists whatever the injected
  `SampleSource` holds; production (`productionDependencies()`) injects none, so the shipped app reaches the
  Comparison screen only via the Readout → "Compare as A/B" carry-in (bs-01 AC-9/10), with the catalogue picker
  offering no saved samples yet. All selection, difference, decomposition, confusion and speak behaviour is
  fully wired and exercised through the injected `CATALOGUE` catalogue; **bs-06** supplies the persistent store
  behind the unchanged `SampleSource` interface.
- **`CvdProfile` is a fixed deutan default until bs-07 (D-4).** The profile is introduced minimally behind the
  `ConfusionCheck` seam (the Viénot-1999 / Brettel–Viénot–Mollon dichromat projection is real and runs);
  **bs-07** populates it from self-assessment, **bs-08/bs-10** reuse the projection — all behind these seams.
- **`NoopSpeech` is still the production TTS sink (D-1, carried from bs-01).** The spoken comparison (what to
  say, when) is fully built, exercised and observed via `FakeSpeech`; a later feature swaps a platform-backed
  implementation behind the unchanged `Speech` seam, so the shipped app does not yet audibly speak.
- **Summary page / cost-per-line omitted — tooling absent in this environment.** `/behavior-test-check summary`
  and its `feature_loc.py` are not installed here (same as bs-01's sign-off), so no hosted summary page URL and
  no per-AC cost-per-line are produced. The machine-readable JSON results and the cost-per-AC report below carry
  the same figures.

---

## 7. Token usage & cost per AC

Full report: [cost-per-ac-round-1.md](cost-per-ac-round-1.md) (prices every session from its own transcript).

- **Feature total:** 148,908,292 tokens over 24 sessions — **$136.65** at API list rates (2026-09-25).
- **By type:** input $0.01 · cache write $38.82 · cache read $71.78 · output $26.04.
  (tokens: input 2,458 · cache write 4,295,243 · cache read 143,569,043 · output 1,041,548)
- **Time:** Σ active **5h 58m** (Σ wall 15h 42m); first start 2026-10-07 07:43 EDT → last end 2026-10-08 10:45 EDT.
- **Per-stage subtotals:** scaffold $2.38 · shells $21.37 · acceptance-tests $30.39 · test-review $3.28 ·
  sign-off $9.17 · activities (plan/reconcile/sign-off-decision) $10.85 · behaviour (direct) $59.22.
- **Per-AC (fully loaded):** AC-1/AC-2/AC-12 $9.74 each · AC-3 $12.55 · AC-4 $16.79 · AC-5/AC-6 $9.78 ·
  AC-7/AC-8 $11.25 · AC-9 $15.47 · AC-10/AC-11 $10.28.
- **Production code:** 16 comparison/CVD lib files net-new or changed for bs-03 (~1,510 lines); whole lib
  40 files / 3,218 lines, 100% covered. 15 test/tool files touched (~3,241 lines).
  (Per-AC cost-per-line is omitted — `feature_loc.py` is not installed in this environment.)

---

## 8. Manual walkthrough — how a reviewer sees each Rule working

**Run the suite yourself** (PATH first):

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd /Users/matthew.quirk/Nuance
xcrun simctl boot 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685   # iPhone 17; ok if already booted
flutter analyze                                          # no issues
flutter test --coverage                                  # unit + coverage → coverage/lcov.info
dart run tool/coverage_gate.dart main                    # 100% on touched files
flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685                               # default: 43/43
flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685 --dart-define=BS03_RUN_PENDING=true   # identical: 43/43
```

> ⚠️ Without `-d <udid>` the integration run executes **zero** tests and exits 0 (a false green). Always pass
> the simulator udid.

**Launch the app to click through it:** `flutter run -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` opens on the
bs-01 Readout for the demo "Warm Terracotta" sample; tap **Compare as A** to enter the Comparison screen with
that sample in slot A. (The saved-sample picker's catalogue is injected by the acceptance harness, not by the
production build yet — bs-06, §6 — so to exercise every Rule against a known catalogue, the integration suite is
the authoritative walkthrough; each test below is a scripted click-through of one Rule.)

| Rule (spec) | What you see / do | Where it shows |
|---|---|---|
| The painter chooses the two samples to compare | Tap "Sample picker" for slot A / B → pick a saved sample; the slot shows the name **and** "L .., C .., h .. degrees" | slots region; `TestAC01`, `TestAC02` |
| The comparison can be reversed | Tap "Swap A and B" → the slots exchange and the relational statement re-expresses new-A→new-B ("Lighter by 12" becomes "Darker by 12") | slots region + statement; `TestAC03` |
| The comparison states an overall difference with a plain verdict | The overall region reads "delta-E00 13.1" and "clearly different"; a nearer pair reads "slightly different" (the verdict tracks distance) | difference region; `TestAC04` |
| The comparison decomposes into lightness, saturation and hue | "Lighter by 12", "Less saturated by 9", "Hue shifted 18 degrees toward yellow" | statement region; `TestAC05` |
| A dimension that does not change is stated as unchanged | For a pair sharing the hue angle, the hue line reads "Same hue" while lightness/saturation still state their deltas | statement region; `TestAC06` |
| A pair that collides on the painter's confusion line is flagged | For the deutan confusion pair (Mid Raw Umber / Terre Verte Shadow) a warning states the two look identical to the painter but are clearly different to others | confusion region; `TestAC07` (control: `TestAC08` off-line pair shows no warning) |
| The comparison can be spoken, including any confusion warning | Tap "Speak whole comparison" → one utterance carrying the relational statement **and** the confusion warning (recorded by `FakeSpeech`; `NoopSpeech` in prod, §6) | actions bar; `TestAC09` |
| Either sample can be opened in full from the comparison | Tap "Open readout for A" / "Open readout for B" → the bs-01 Readout opens for that sample | actions bar; `TestAC10`, `TestAC11` |
| A comparison needs two samples | With only sample A chosen, no relational statement is shown and an enabled "Choose sample B" invite is offered | slots/statement region; `TestAC12` |

---

## 9. Decision

Reviewer: **Matt Quirk (owner)**  Date: **2026-10-08**  Decision: ☑ Approved  ☐ Changes requested

Recorded via `/feature-next-phase --signoff bs-03-relative-comparison approved`.

- **Approved** ✅ — SIGNOFF-1 complete; feature `Status: Done — signed off 2026-10-08 by Matt Quirk at 44da743`.
  All 12 ACs green (12×A/0×B), full verification green, no open gates/augmentations/non-A grades. The known
  gaps in §6 are deferred-by-design dependencies on later features (bs-06 store, bs-07 CVD profile, platform
  TTS), accepted as part of this approval.
