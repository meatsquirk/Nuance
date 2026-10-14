# Sign-off packet — Core non-functional requirements (bs-12) — Round 1

**Feature:** bs-12-non-functional-requirements · **Spec:** [bs-12-non-functional-requirements.feature](../../bs-12-non-functional-requirements.feature)
**Prepared:** 2026-10-14 (SIGNOFF-1) · **At code:** `feat/bs-12-non-functional-requirements` @ `3e6164a` (QUALITY-5; sign-off commit stamped on the decision)
**Decision:** ⏸ **Awaiting sign-off** — a human records the decision via `/feature-next-phase --signoff bs12 approved | changes "<items>"`. The agent does not approve.

bs-12 is a cross-cutting *verify + fix* feature (D-1): it ships reusable NFR guards as acceptance mechanism over every feature merged on `main` at the branch point (bs-01…09 + bs-07 + bs-08) and fixes the one gap they revealed (the AC-9 reliability trigger). All 16 automatable acceptance criteria are coded, un-pended and green by default (pending map empty); AC-5 (live-preview frame rate) is pure-manual and closed at **G-3** with owner on-device evidence. A fresh independent whole-suite re-grade is **16 A / 0 below A**. This packet is the evidence for the decision.

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 15/15 build phases ✅ Done (GUARD-1…6, QUALITY-1…5, ITEST-1…4) |
| Every automatable AC ✅ in the coverage table | ✅ AC-1…AC-4, AC-6…AC-17 all ✅ Done. **AC-5 is the pure-manual G-3 gate** (no automated test, D-3) — resolved at this sign-off |
| Pending list empty | ✅ `integration_test/bs12/pending.dart` → `pendingACs = {}`; both gate tests assert the empty end-state, and all 16 ACs run in **both** default and run-pending modes (33/0 == 33/0) |
| No open row in ITEST *Test augmentations* | ✅ all 8 closed — TestAC07/08→GUARD-4, AC-14/15→GUARD-5, AC-16/17→GUARD-6, AC-9→QUALITY-2, AC-10/11/12→QUALITY-4. **The last 6 cells read a stale `⬜ Open`; this session verified each augmentation is present in the test/guard code and corrected the cells to ✅ Done** |
| Fresh whole-suite grade grid all A | ✅ **16 A / 0 below A** (fresh-context adversarial grader, this session; appended to the completeness grid as "SIGNOFF-1 — whole-suite re-grade") |
| Decision/dependency gates | G-1 (spec) ✅, G-2 (test review) ✅. **G-3 (AC-5 fps + AC-3/4 device timings, D-3) is the owner on-device evidence recorded with this decision** — open by design until sign-off |

---

## 2. Full verification (worktree `Nuance-bs12` on `feat/bs-12` @ `3e6164a`, this session)

Toolchain: Flutter (project-local, `~/development/flutter`). bs-12's own acceptance suite runs on **`-d flutter-tester`** (the host VM, cwd = repo root) because its source-scan ACs (AC-7/8/16/17) read the `lib/` tree via `dart:io`, which resolves only with the repo as cwd — an iOS-sim sandbox can't see those paths. The **other features'** integration suites were authored/verified on the iOS simulator, so the cross-feature regression ran there (one booted iPhone 17, under the shared device lane via `coord.sh with-lock`). Machine-readable results (`flutter test --machine`) produced on this run; the summary page (§8) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found!** (clean) |
| Unit + coverage | `flutter test --coverage` | **1233 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all touched `lib/` files (first run; no flake) |
| Acceptance — bs-12 (default) | `flutter test integration_test/bs12/nfr_test.dart -d flutter-tester --machine` | **33 passed, 0 failed, 0 skipped** (`done.success=true`) |
| Acceptance — bs-12 (run-pending) | same `+ --dart-define=BS12_RUN_PENDING=true` | **33 passed, 0 failed, 0 skipped** — identical to default (pending map empty) |
| Cross-feature regression — other features | `flutter test integration_test/{readout,capture,comparison,correction,display,harness,palette,recipes,self_assessment,advanced_capture}_test.dart -d <iPhone 17 udid> --machine` | **197 passed, 0 failed, 0 skipped** |
| **Cross-feature regression — total** | bs-12 (flutter-tester) + other features (sim) | **230 passed, 0 failed, 0 skipped** |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **16 A / 0 below A — PASS** |

Per-suite (sim): advanced_capture 21 · capture 19 · comparison 26 · correction 22 · display 21 · harness 5 · palette 23 · readout 12 · recipes 24 · self_assessment 24 = **197**.

**The only `lib/` change bs-12 makes** (D-7) is the AC-9 reliability fix in `lib/capture` (QUALITY-2): `CaptureController.commit()` now forces the stated accuracy to `approximate` whenever any `activeDowngradeReasons` holds (poor lighting / unlocked AE·AWB·AF / missing reference card), never returning an untrustworthy reading as `calibrated`. Everything else bs-12 ships is reusable test-support under `integration_test/nfr/`.

---

## 3. Per-AC result

Each automatable AC's acceptance test is un-pended and green by default; the accuracy ACs (AC-10/11/12) are graded by an **independent in-harness `referenceDeltaE00`** (a standalone CIEDE2000, never the shipped `deltaE00`), and each guard/accuracy test carries a discriminating control. All 13 formerly-red ACs had a genuine red baseline at ITEST-2/3; AC-3/AC-4/AC-13 were green-at-baseline (satisfied by bs-02/bs-04 already on `main`) and their phases un-pend + guard them.

| AC | Scenario (Rule) | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | Offline — every core function works | `AC-1` (offline sweep) | GUARD-3 | ✅ A |
| AC-2 | No core function blocks on connectivity | `AC-2` (no-blocking) | GUARD-3 | ✅ A |
| AC-3 | Reading settles within budget with a visible indicator | `AC-3` (settle + indicator) | QUALITY-5 (un-pend+guard) | ✅ A |
| AC-4 | Recipe search returns top 3–5 within budget | `AC-4` (search budget) | QUALITY-5 (un-pend+guard) | ✅ A |
| **AC-5** | **Live capture holds a usable preview frame rate** | **— pure-manual (G-3), no automated test (D-3)** | **SIGNOFF-1 (owner evidence)** | ⏸ G-3 |
| AC-6 | Photos and samples never leave the device | `AC-6` (on-device) | GUARD-4 | ✅ A |
| AC-7 | No account and no telemetry in v1 | `AC-7` (no-account) | GUARD-4 | ✅ A |
| AC-8 | Any future sync is opt-in and explicit | `AC-8` (sync opt-in) | GUARD-4 | ✅ A |
| AC-9 | Poor conditions downgrade the stated accuracy, never fail silently | `AC-9` (downgrade) | QUALITY-2 | ✅ A |
| AC-10 | Card + controlled lighting → ΔE00 ≤ 3 | `AC-10` (ΔE≤3) | QUALITY-4 | ✅ A |
| AC-11 | No-card daylight → ΔE00 ≤ 8, labelled approximate | `AC-11` (ΔE≤8 + approximate) | QUALITY-4 | ✅ A |
| AC-12 | Recipe vs mixed swatch → ΔE00 ≤ 5 in-gamut | `AC-12` (ΔE≤5) | QUALITY-4 | ✅ A |
| AC-13 | Out-of-gamut target identified, no false recipe | `AC-13` (out-of-gamut) | QUALITY-3 (un-pend+guard) | ✅ A |
| AC-14 | Mixing engine replaceable without touching callers | `AC-14` (engine swap) | GUARD-5 | ✅ A |
| AC-15 | CVD model replaceable without touching callers | `AC-15` (CVD swap) | GUARD-5 | ✅ A |
| AC-16 | Colour-science conversions come from one tested library | `AC-16` (one library) | GUARD-6 | ✅ A |
| AC-17 | Only native capture differs per platform | `AC-17` (portability) | GUARD-6 | ✅ A |

**Grade grid:** [`../behavior-test-completeness-bs-12-non-functional-requirements.md`](../behavior-test-completeness-bs-12-non-functional-requirements.md) — fresh SIGNOFF-1 whole-suite re-grade appended: **16 A / 0 — PASS**. The grader re-ran the source scans itself over `lib/`, read `referenceDeltaE00` in full to confirm AC-10/11/12 never grade the impl against itself, and verified `commit()` rejects the old lighting-only AC-9 impl — confirming each AC rejects a named wrong implementation with nothing passing vacuously.

---

## 4. Augmentations made

The plan pre-seeded eight augmentation rows for tests whose discriminating control depended on a not-yet-built source scan / downgrade trigger / synthetic set. **All eight are now closed by their behaviour phase:**

- **TestAC07 / TestAC08 → GUARD-4** — the real resolved-pubspec/lockfile scan (`forbiddenDependencies`) and the real `offDeviceSenders` source scan; the planted `firebase_analytics` and `control_off_device_sender` are flagged. ✅ Closed (flipped at ITEST-era).
- **AC-14 / AC-15 → GUARD-5** — the real `concreteTypeReferences` scan (lib sweep empty + `control_bound_to_concrete` flagged) and a real CVD caller driving the injected `ConfusionCheck` (`confusableCalls > 0`). ✅ Closed.
- **AC-16 / AC-17 → GUARD-6** — the real `conversionOffenders`/`deltaEOffenders`/`platformOffenders` scans; lib sweeps empty (modulo the two owner-sanctioned D-4 pipelines) + the planted stray-maths / platform fixtures flagged. ✅ Closed.
- **AC-9 → QUALITY-2** — `commit()` wired to force `approximate` on any active downgrade reason, so all three conditions discriminate and `control_trustworthyPoor` stays `calibrated`. ✅ Closed.
- **AC-10/11/12 → QUALITY-4** — the full synthetic held-out set (≥3/condition incl. a perturbation/out-of-gamut control that exceeds the bound) fed through the real pipeline, graded by the independent `referenceDeltaE00`. ✅ Closed.

**Cell-correction note:** the ITEST *Test augmentations* cells for AC-9/10/11/12/14/15/16/17 read a stale `⬜ Open` through this session (the augmentation code was in place from each behaviour phase, but the status cells had not been flipped). This session verified each augmentation in `nfr_test.dart` and the guard/accuracy harnesses, then corrected the cells to ✅ Done — no code changed.

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A (16 A). Nothing was closed by user acceptance of a gap.

One standing honest caveat the fresh grader recorded as **A-with-caveat** (correct grain, not a sub-A grade, no augmentation owed):

- **AC-10** (card + controlled → ΔE00 ≤ 3) — under the software capture source the card path returns the scene ground-truth exactly (ΔE 0) and the held-out scenes carry no platform `rawColorShift`, so the ΔE≤3 leg is near-tautological. The test still rejects a plausible wrong impl via the `accuracy == calibrated` assertion (catches a mislabel / over-downgrade) and the metric perturbation control (proves the bound is non-vacuous), and real capture fidelity is exercised by AC-11's card-less round-trip. This is a **scoped instance of the disclosed D-2 gap** (synthetic ≠ physical ground truth), not a test defect — kept A, consistent with the QUALITY-4 grid's own note.

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** G-1 (spec approval) ✅ Resolved 2026-10-13 by Matt Quirk; G-2 (acceptance-test review) ✅ Resolved 2026-10-14 by Matt Quirk. **G-3 (AC-5 live-preview frame rate on device + AC-3/AC-4 target-hardware ~1–2 s timings as owner evidence, D-3) is open by design** and is resolved with this sign-off — a fail blocks acceptance. See §9 for how to gather it.

**Open known flakes (carried, not observed as failures this session):**
- *coverage_gate const-constructor line* — `flutter test --coverage` can intermittently record a const-folded line as uncovered. The gate passed **first run** this session (no flake).
- *integration suite — no `-d`* — a bare `flutter test integration_test/…` with no device runs zero tests and exits 0 (false green). Mitigated: bs-12 ran on `-d flutter-tester` and the cross-feature regression on a **booted** iPhone 17 (both actually executed their tests — 33 and 197 respectively, not zero).
- *sim `stopApp`/`terminate` teardown race* — the cross-feature sim regression completed **exit 0, 197/0/0** with no teardown race this run. (bs-12's own suite runs on flutter-tester, which has no app to terminate, so the race does not apply there.)
- *flutter-tester can't launch multiple integration suites in one invocation* (observed this session) — running the whole `integration_test/` dir on flutter-tester fails to relaunch the app between suites. Not a regression: each suite passes when run on its intended target (bs-12 per-file on flutter-tester; the others on the sim). Documented here so a future reviewer doesn't read it as a failure.

**Known gaps / deferred by design (not defects):**
- **D-2 — accuracy is proven against a *synthetic* held-out dataset, not physical ground truth.** AC-10/11/12 assert the ΔE math, the tiering and the labelling through the real pipeline, graded by an independent CIEDE2000. Physical spectrophotometer / mixed-swatch validation is **out of bs-12 scope**, owned by the Phase-0.5/Phase-1 accuracy gate. (AC-10's near-tautological card leg, §5, is the sharpest instance.)
- **D-3 — device performance figures are owner on-device evidence (G-3).** CI gates the *mechanism* (stability indicator → STABLE and commit; search returns 3–5) plus a generous regression budget — never the literal "~1–2 s on target hardware" (AC-3/AC-4) or the **live-preview frame rate (AC-5)**, which are device-only. AC-5 has no automated test and is closed by user acceptance at G-3 with the gap named.

---

## 7. Cost and tokens

From the *Token usage* ledger (18 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 163,191,710 tokens — input 2,342 · cache write 4,713,640 · cache read 157,343,535 · output 1,132,193.
- **Cost (API list rates, 2026-09-25):** **$148.19** (cache read $78.67 · cache write $41.20 · output $28.30 · input $0.01). All 18 sessions priced from their transcripts.
- **Span:** 2026-10-13 12:26 EDT → 2026-10-14 15:47 EDT — **Σ active 6h 57m** (Σ wall 11h 23m).
- **By stage:** activities (plan/gate) $5.53 · scaffold $6.46 · shell $10.87 · acceptance tests $47.27 · test review $2.30 · sign-off $12.00 · behaviour (direct, below).
- **Per-AC (fully loaded, sums to the feature total):** shared work $4.97/AC; direct behaviour ranges from $0 (AC-5, no automated phase) and ~$2.3M-token phases (AC-3/4) up to AC-9's 14.4M-token QUALITY-2 fix — so fully loaded ≈ **$4.97 (AC-5) … $16.52 (AC-9), mean ≈ $8.72/AC**.

*(As with bs-09/bs-10, the cost report was generated from a normalized copy of the plan: `ac_cost.py` expects each module dashboard's Phase cell to be a bare ordinal, while bs-12's dashboards spell the full phase name — a non-blocking plan-tooling quirk. The token figures reconcile exactly with the ledger's Feature total.)*

---

## 8. Summary page

Acceptance-suite summary scorecard (built from this session's machine-readable results):
**→ https://claude.ai/artifact/QT3vx57vaRaasdRKw5Sdki** — "bs-12 NFR Sign-off" scorecard (verification headline, 16 ACs with grades, controls, gates, cost). Private to the owner; share from the page's Share menu for other reviewers. Its headline (unit 1233 · coverage 100% · regression 230 · bs-12 33 · 16 A) matches this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the `Nuance-bs12` worktree root. To watch the whole contract run green end to end: `flutter test integration_test/bs12/nfr_test.dart -d flutter-tester` (33 tests; add `--dart-define=BS12_RUN_PENDING=true` to confirm nothing is hidden).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| **Every core function works offline** | Put the device in airplane mode; run capture → readout → compare → recipe search → save project → export. | Every flow completes and reaches its terminal state; nothing waits on or requires a connection. The acceptance guard sweeps all five flows + a capture-commit under a live network block that throws on any socket, and records **zero** attempts; a deliberate touch (the control) throws and is recorded. |
| **The app responds within the performance budget** | Commit a reading; run a recipe search. | The capture finder shows a live settling indicator (`SETTLING n/12 → STABLE 12/12`) then commits; the search returns 3–5 ranked candidates. In CI both complete under a generous regression budget. **G-3 (owner, on device):** record the live-preview **frame rate** (AC-5) and the **~1–2 s** settle/search timings on target hardware (AC-3/AC-4) — the figures CI deliberately does not assert (D-3). |
| **Data stays private and on the device** | Capture, save and export under airplane mode; inspect the dependency set. | Export hands real `%PDF-` bytes to the on-device share/print sheet (never disk/network); stored photos + SQLite are local-only; no account/auth surface is reachable; the dependency guard finds no telemetry/analytics/crash/http package; a planted forbidden package or off-device sender (the controls) are flagged. |
| **A reading is never silently untrustworthy** | Take a reading in poor light; with exposure unlocked; with no reference card. | Each returns with its stated accuracy **downgraded to approximate**, never handed back as `calibrated`; a well-lit, locked, card-calibrated reading (the control) stays `calibrated`. This is the one bs-12 product change (`lib/capture`). |
| **Accuracy meets the stated targets** | Run the accuracy harness over the synthetic held-out set. | Card + controlled ≤ ΔE00 3; card-less daylight ≤ 8 and labelled approximate; recipe-vs-swatch ≤ 5 in-gamut — each graded by an **independent** CIEDE2000, with a perturbation control that exceeds the bound. An out-of-gamut target is flagged and offered **no** recipe as a match; an in-gamut control is not flagged and returns recipes. *(Synthetic, not physical — D-2.)* |
| **The engine and models are swappable behind interfaces** | Inject an alternate `MixingEngine` / `ConfusionCheck`; run the callers. | Callers produce correct results through the interface, driving the injected alternate; a source scan proves **no caller references** the concrete `SubtractiveMixingEngine` / `DichromatConfusionCheck`, and no file outside the two colour-science authorities computes a conversion or a ΔE (the two owner-sanctioned domain pipelines aside, D-4); planted bound-to-concrete / stray-maths fixtures are flagged. |
| **One codebase serves both platforms** | Scan `lib/` for platform-conditional code. | Platform-conditional constructs (`Platform.is*` / `MethodChannel` / conditional imports) appear **only** under `lib/capture/source/`; a planted platform file elsewhere (the control) is flagged. |

A reviewer who wants to see the tests fail honestly can re-add an AC to `integration_test/bs12/pending.dart` and run run-pending, or revert the QUALITY-2 `commit()` downgrade and re-run AC-9: that test goes red on its own Then. The ITEST-2/3 red baseline (13 ACs red on exactly their control/limit) is recorded in `modules/ITEST.md`.

---

## 10. Decision

Reviewer: **________________**  Date: **____________**  Decision: ☐ Approved  ☐ Changes requested

Record via `/feature-next-phase --signoff bs12 approved | changes "<items>"`, having gathered the **G-3** on-device evidence (AC-5 frame rate; AC-3/AC-4 ~1–2 s timings).

- **Approved** → SIGNOFF-1 ✅; feature `Status: Done — signed off <date> by <reviewer> at <commit>`; then **merge `feat/bs-12` → `main`** via a throwaway worktree on `main` (the primary checkout on `feat/bs-04` has stale untracked specs that abort `checkout main`; `git merge -F <file>`, not stdin). Sequence the merge so in-flight branches rebase onto bs-12's one `lib/capture` AC-9 change; the reusable NFR guards become acceptance mechanism later features inherit.
- **Changes requested** → each item becomes a new phase before a fresh SIGNOFF-2; this round's file stays as history.
