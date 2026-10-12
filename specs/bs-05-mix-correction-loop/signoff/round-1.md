# Sign-off packet — Mix-correction loop (bs-05) — Round 1

**Feature:** [bs-05-mix-correction-loop.feature](../../bs-05-mix-correction-loop.feature) — 10 ACs across 7 Rules
**Code under review:** `feat/bs-05-mix-correction-loop` @ **`5b5260e`** (LOOP-6 tip; SIGNOFF-1 adds no product code)
**Decision:** ✅ **Approved — 2026-10-11 by Matt Quirk** at `83554a9` (reviewed state; product-code tip `5b5260e`). Recorded via `/feature-next-phase --signoff bs-05-mix-correction-loop approved`.

> **What this is.** Every acceptance criterion of the correction loop is coded, un-pended, and green, graded A
> by an independent fresh-context grader. This packet is the evidence a human weighs before the feature is
> Done: the per-AC results, the full regression, the grade grid, the gates, the open flakes, the deferred
> items, and a Rule-by-Rule walkthrough of how to see it working.

## 1. Per-AC results

All 10 ACs ✅ — un-pended, running in the default mode, green. Each test drives the real assembled app
(`buildApp` with a `CorrectionEntry`); ΔE00 is graded against an **independent** in-harness CIEDE2000
(`referenceDeltaE00`, five Sharma–Wu–Dalal pairs to 1e-3), never the product metric.

| AC | Rule | Test | What it proves | Status |
|---|---|---|---|---|
| AC-1 | checks a physical mix | `TestAC01_CheckPhotographsAndCompares` | "Check my mix" (E26) photographs a *measured* `Sample` and compares it to the target (ΔE00 ≈ 10.06, `closeTo` the independent reference) | ✅ |
| AC-2 | states how far off | `TestAC02_DeltaEAndVerdict` | the difference renders ΔE00 + verdict **"noticeably off"**; the in-test within-tolerance control reads **"very close"**, proving the verdict tracks distance | ✅ |
| AC-3 | states how far off | `TestAC03_ValueLeadingDecomposition` | the leading reading is value — **"too dark by 6"** — then hue **"shifted toward green"** (CVD-first ordering) | ✅ |
| AC-4 | suggests a correction | `TestAC04_ConcreteCorrection` | names **Titanium White** with a positive amount, and adding it reduces the real `forward`-predicted ΔE00 (in-test physical control) | ✅ |
| AC-5 | suggests a correction | `TestAC05_TouchOf` | a sub-trace (< 0.02) Yellow Ochre addition renders **"a touch of"** + technique note, not a measured part | ✅ |
| AC-6 | suggests a correction | `TestAC06_WithinTolerance` | a mix within ΔE00 2 reads verdict **"very close"** and **suppresses** the correction | ✅ |
| AC-7 | can be spoken | `TestAC07_SpeakCorrection` | E27 emits **exactly one** utterance stating the difference **and** the paints to add | ✅ |
| AC-8 | re-photograph re-checks | `TestAC08_RephotographRechecks` | E28 re-measures (raw L `closeTo(39,1.0)`; stale L36 fails) and the ΔE00/verdict **update** (4.95 < 10.06) | ✅ |
| AC-9 | confirmed mix saved | `TestAC09_SaveConfirmed` | E29 promotes the target to tier `confirmed`, carries **"Confirmed — you measured this"** via `note`, appends the measured swatch as evidence — and the in-test honest-provenance control proves it **refuses to promote without the painter's own swatch** | ✅ |
| AC-10 | confirmed in later readout | `TestAC10_ConfirmedInReadout` | a later `router.toReadout` renders the `ProvenanceRegion` carrying "…you measured this" | ✅ |

## 2. Full verification (this session, at `5b5260e`, from the `Nuance-bs05` checkout)

Machine-readable results captured (`flutter test --machine`) — the summary page (§7) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **clean** — No issues found |
| Unit + coverage | `flutter test --coverage` | **668 pass / 0 fail / 0 skip** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **100%** line coverage on all touched `lib/` files (17 files: the 14 `lib/correction/**`, `lib/app/build_app.dart`, `lib/app/router.dart`, `lib/readout/provenance_region.dart`) |
| Full cross-feature regression | `flutter test integration_test/ -d <iPhone-17 sim>` | **108 pass / 0 fail / 0 skip** — every shipped feature green (readout, capture, comparison, recipes) + all 10 bs-05 ACs + bs-05 smoke/guards |
| bs-05 acceptance (run-pending) | `… correction_test.dart --dart-define=BS05_RUN_PENDING=true` | **22 pass / 0 fail / 0 skip** — identical to default (nothing pending; the red baseline is fully retired) |

Run under the verify lock on the booted simulator `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685` (iPhone 17, iOS 26.5).

## 3. Grade grid

Independent fresh-context regrade for sign-off (G1–G6 rubric; read every test + the product code each
exercises; all load-bearing geometry recomputed with a standalone CIEDE2000; no device run — grading by code):

**→ [signoff/round-1-grade-grid.md](round-1-grade-grid.md) — 22 rows = 22×A / 0×B.**

- 10 AC tests — **all A**.
- 12 scaffold rows (smoke, 2 pending-gate, 2 fakes, 5 fixtures, 2 reference) — **all A**.
- **No downgrades** from the LOOP-6 grid; every A re-earned against the real code. Gate recommendation: **PASS**.

**Grader's one observation (not a defect, no downgrade):** the shipped `deltaE00`
(`lib/compare/difference.dart`) and the test `referenceDeltaE00` are the *same* CIEDE2000 algorithm in
separate source files. G5 still holds: the reference is independently validated against published Sharma–Wu–Dalal
data by the reference guard, so a wrong shipped metric (CIE76/CIE94, R_T sign slip) would still be caught by
the AC-1/AC-2 `closeTo` assertions. (The grader also corrected an arithmetic slip in the *prior* grid's prose —
12 scaffold rows, not "11" — a count only, no grade change.)

## 4. Augmentations made

| AC test | Was limited because | Augmented by | Added | Status |
|---|---|---|---|---|
| `TestAC02` | one off-reading can't show the verdict *tracks* distance (a constant "noticeably off" would pass) | CORRECT-4 | a within-tolerance "very close" control in the same test | ✅ Closed — discriminates; fails a constant-verdict impl |

No other augmentation rows were opened; none remain open.

## 5. Phases closed by user acceptance / Non-A grades accepted

**None.** Every phase passed its gates cleanly; no phase was closed with a gap by user acceptance, and no
non-A grade was accepted.

## 6. Gates, flakes, and deferred items

**Open gates:** none. All four resolved and recorded:

| Gate | Resolution |
|---|---|
| G-1 | ✅ Spec approved 2026-10-10 — Matt Quirk (`.feature` first line stamped) |
| G-2 | ✅ Acceptance tests approved 2026-10-10 21:51 EDT — Matt Quirk (ITEST-4 packet) |
| G-3 | ✅ bs-04 merged to local `main` @ `2684ac6` 2026-10-10 — Matt Quirk (bs-05 branches from it) |
| G-4 | ✅ Spec-data/engine/domain reconciliation 2026-10-10 17:35 EDT — Matt Quirk: amounts illustrative (assert properties); verdicts "noticeably off"/"very close" + tolerance ΔE00 ≤ 2; trace threshold 0.02; confirmed phrase via `note`, shared `Provenance.label` unchanged |

**Open known flakes** (carried from bs-01..bs-04; both are *avoidance* rules, neither reproduced this run):
1. `coverage_gate` may intermittently mark a const-folded constructor line uncovered → re-run `flutter test --coverage` once; green on re-run ⇒ ignore. (Did not trigger this session — coverage passed first run.)
2. `flutter test integration_test/…` **without** `-d <udid>` runs zero tests and still exits 0 (false green) → always pass a booted sim udid. (Every run here used the booted sim; counts are real.)

**Known gaps / deferred items** (recorded, with owners — none are AC-blocking, none are packet-listed defects):
1. A confirmed mix is exposed via `CorrectionController.savedSamples` (plan-sanctioned "or exposes it for the readout"), **not** the shared read-only `SampleSource`. **Owner: bs-06** (palette & projects) backs it with the persistent catalogue. AC-10 is satisfied today through the controller's exposure.
2. `rephotograph` reads the difference only and clears `state.correction`; a later pass may unify `checkMix`/`rephotograph` behind a shared `_photographAndCheck()` helper. Refactor only — behaviour is correct and tested (AC-8).

## 7. Manual walkthrough — how a reviewer sees each Rule working

**Scope note.** The Correction screen is entered via a `CorrectionEntry` (`AppRouter.toCorrection(target,
currentMix)`); the production "check my mix" nav handoff from the Recipes screen is a later increment (D-9),
so a live `flutter run` opens to Readout, not Correction. The honest way to watch the loop is the acceptance
suite, which assembles the **real** app (`buildApp`) and drives every Rule on the booted sim. A demo launcher
was considered and declined: the fixtures and `FakeCaptureSource` live in `integration_test/`, so a `lib/`
launcher would mean duplicating test infrastructure into product code — against the no-product-code rule for
sign-off, and more fragile than the suite it would imitate.

**Watch it run green, Rule by Rule:**

```
export PATH="$HOME/development/flutter/bin:$PATH"
cd /Users/matthew.quirk/Nuance-bs05
# the whole bs-05 contract on the booted sim (22 tests — smoke, guards, all 10 ACs):
flutter test integration_test/correction_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685
# the full cross-feature regression (108 tests, nothing broken elsewhere):
flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685
```

| Spec Rule | The test that exercises it | What the reviewer sees |
|---|---|---|
| **Checks a physical mix against the target** (AC-1) | `TestAC01` | Open Correction on Deep Olive Green + its current mix. Tap **E26 "Check my mix"** → the swatch is photographed to a *measured* `Sample` and compared: the difference body fills with a ΔE00 (≈10.06) to the target. No photograph, or a photograph without a compare, fails. |
| **States how far off** (AC-2, AC-3) | `TestAC02`, `TestAC03` | The difference body reads the ΔE00 with the plain verdict **"noticeably off"**, and leads with value — **"too dark by 6"** — before the hue line **"shifted toward green"**. Feed a within-tolerance swatch and the verdict flips to **"very close"**. |
| **Suggests a concrete correction** (AC-4, AC-5, AC-6) | `TestAC04`, `TestAC05`, `TestAC06` | The correction body names a real palette paint — **Titanium White**, a positive amount that actually reduces the predicted ΔE00. A sub-2% addition (Yellow Ochre) reads **"a touch of"** with a technique note. A mix within ΔE00 2 shows **no correction** at all — just "very close". |
| **Can be spoken** (AC-7) | `TestAC07` | Tap **E27 Speak correction** → exactly one spoken utterance that states both the difference and the paints to add (observed on the recording `FakeSpeech`). |
| **Re-photograph to re-check** (AC-8) | `TestAC08` | After applying the correction to the physical mix, tap **E28 Re-photograph** → a fresh measured swatch, and the ΔE00/verdict **update** toward the target (4.95 < 10.06), not a stale reading. |
| **Confirmed mix saved; provenance promoted** (AC-9) | `TestAC09` | When the swatch is satisfactory, tap **E29 Save confirmed mix** → the target value is promoted to **Confirmed — you measured this**, the note records it was confirmed after the painter photographed their own swatch, and the measured swatch is appended as evidence. Without the painter's own measured swatch, the promotion is refused (the honest-provenance rule). |
| **Confirmed value in later readouts** (AC-10) | `TestAC10` | Navigate to a later readout of Deep Olive Green → the provenance region carries **"…you measured this"**, the single-user "Confirmed · you" tier the loop is the only path to. |

## 8. Token usage & cost per AC

Full breakdown: **[signoff/cost-per-ac-round-1.md](cost-per-ac-round-1.md)**.

- **Feature total: $157.63** at API list rates (2026-09-25) — input $0.01, cache write $38.36, cache read $90.46, output $28.80. **186,328,124 tokens** over 21 sessions (21/21 priced from transcripts).
- **Time:** Σ active **9h 10m** (Σ wall **21h 26m**); first start **2026-10-10 04:37 EDT** → last end **2026-10-11 19:54 EDT**.
- **Per stage:** direct behaviour **$90.00**; shared **$67.63** = scaffold $2.66 · shell $18.42 · acceptance-tests $19.34 · test-review $3.28 · sign-off $8.69 · activities (plan/reconcile/gate-decisions) $15.25.
- **Fully-loaded per AC** (1/10 share of shared work): AC-1 $18.89 · AC-2 $12.91 · AC-3 $12.91 · AC-4 $17.53 · AC-5 $17.53 · AC-6 $15.14 · AC-7 $19.53 · AC-8 $12.95 · AC-9 $15.12 · AC-10 $15.12.
- **Code:** +1,503 / −10 lines of `lib/` across 17 files (14 net-new `lib/correction/**`; `build_app`/`router`/`provenance_region` extensions). (`feature_loc.py` was not installed this session, so per-line cost is omitted; LOC measured directly with `git diff --numstat` against the bs-04 merge base `3390b27`.)

## 9. Summary page

Acceptance-suite summary scorecard (built from this session's machine-readable results):
**→ https://claude.ai/artifact/43zBHtjcKJ6Lcjc2tmD3Ex** — "Mix-Correction Sign-off" scorecard. Its headline (unit 668 · coverage 17/17 · integration 108 · 22×A) matches this run. Private to the owner; share from the page's Share menu for other reviewers.

## 10. Sign-off decision

**✅ Approved — 2026-10-11 by Matt Quirk** at `83554a9` (reviewed branch state; product-code tip `5b5260e`).

Feature is **Done — signed off**. The two deferred items are accepted as recorded (neither AC-blocking):
1. A confirmed mix is exposed via the controller's `savedSamples`, not the shared read-only `SampleSource` — **bs-06** owns the persistent catalogue.
2. `rephotograph` may later unify with `checkMix` behind a shared `_photographAndCheck()` helper (refactor only).
