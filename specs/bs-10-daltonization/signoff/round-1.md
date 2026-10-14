# Sign-off packet — Daltonization and colour-distinction aids (bs-10) — Round 1

**Feature:** bs-10-daltonization · **Spec:** [bs-10-daltonization.feature](../../bs-10-daltonization.feature)
**Prepared:** 2026-10-14 (SIGNOFF-1) · **At code:** `feat/bs-10` @ `8442885` (CONTROL-2; sign-off commit stamped on the decision)
**Decision:** ⏸ **Awaiting** — record via `/feature-next-phase --signoff bs10 approved | changes "<items>"`

All 10 acceptance criteria are coded, un-pended and green by default (nothing pending); the full
cross-feature regression (bs-01…bs-10) is **222 / 0 / 0**; a fresh independent whole-suite grade grid is
**10 A / 0 below A**. This packet is the evidence for the decision. The agent does not approve — a human does.

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 16/16 build phases ✅ Done (DALT 1–11, CONTROL 1–2, ITEST 1–3) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-10 all ✅ Done |
| Pending list empty | ✅ `integration_test/bs10/pending.dart` → `pendingACs = {}`; scaffold guard asserts isEmpty + every AC-1..10 runs in **both** default and run-pending modes |
| No open row in ITEST *Test augmentations* | ✅ all four closed — TestAC02→DALT-6, TestAC08→DALT-7, TestAC03→DALT-9, TestAC04→DALT-10 (the last two cells were stale "Open" and corrected this session after verifying both augmentations are present in `daltonization_test.dart`) |
| Fresh whole-suite grade grid all A | ✅ 10 A / 0 B (fresh-context adversarial grader, this session; appended to the completeness grid) |
| No open decision/dependency gates | ✅ G-1 (spec) ✅, G-2 (test review) ✅, G-3 (bs-08 merged) ✅, G-4 (bs-07 merged) ✅ |

---

## 2. Full verification (worktree `Nuance-bs10` on `feat/bs-10` @ `8442885`, this session)

Toolchain: Flutter (project-local, `~/development/flutter`); iOS sim iPhone 17 `5AB9D06D…51685` (booted);
the integration runs executed under the shared device lane via `coord.sh with-lock`. Machine-readable results
(`flutter test --machine`) produced on this run; the summary page (§8) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found!** (clean, 33.7s) |
| Unit + coverage | `flutter test --coverage` | **1279 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all **19** touched bs-10 `lib/` files (first run; no flake) |
| Acceptance — all features (default) | `flutter test integration_test/ -d <udid> --machine` | **222 passed, 0 failed, 0 skipped** (bs-01…bs-10; `done.success=true`) |
| Acceptance — bs-10 (run-pending) | `flutter test integration_test/daltonization_test.dart -d <udid> --dart-define=BS10_RUN_PENDING=true --machine` | **25 passed, 0 failed, 0 skipped** — identical to default (the pending map is empty) |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **10 A / 0 below A — PASS** (10 AC tests + scaffold/pending guards + fixture guards + smoke + harness artifacts) |

The 19 touched `lib/` files at 100%: `a11y/cvd/daltonize.dart`, `app/build_app.dart`,
`capture/{capture_current_reading,capture_screen}.dart`,
`display/{color_simulation,display_controller,display_read_endpoint,display_settings,settings_screen}.dart`,
`onboarding/cvd_profile_read_endpoint.dart`, `palette/paint_list_region.dart`, `readout/provenance_region.dart`,
`store/{cvd_profile_store,drift_persistent_store,persistent_store}.dart`,
`widgets/{color_chip,paint_row,provenance_badge,provenance_icon}.dart`.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green; the colour-remap ACs are graded against an **independent
in-harness `referenceDaltonize`** (never the shipped `daltonize`), and each test carries a discriminating
control. AC-1/AC-5/AC-6/AC-7/AC-9/AC-10 had a genuine red baseline (the DALT-2 identity shell).

| AC | Scenario | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | Daltonization remaps displayed colours for the painter's type (protan/deutan/tritan) | `TestAC01_RemapForType` | DALT-3 | ✅ green |
| AC-2 | With daltonization off, colours are shown unremapped | `TestAC02_OffShowsOriginal` | DALT-6 | ✅ green |
| AC-3 | A remapped element still shows its label and value | `TestAC03_LabelAndValueKept` | DALT-9 | ✅ green |
| AC-4 | A provenance badge stays distinguishable under daltonization | `TestAC04_ProvenanceBadgeReadable` | DALT-10 | ✅ green |
| AC-5 | The remap uses the type and severity from the stored profile | `TestAC05_UsesStoredProfile` | DALT-4 | ✅ green |
| AC-6 | Changing the profile updates the remap | `TestAC06_ProfileChangeRecomputes` | DALT-11 | ✅ green |
| AC-7 | Daltonization remaps to help, where simulation shows how they see | `TestAC07_DistinctFromSimulation` | DALT-5 | ✅ green |
| AC-8 | Daltonization changes only what is shown, not stored values | `TestAC08_StoredValuesUnchanged` | DALT-7 | ✅ green |
| AC-9 | Daltonization applies on every screen while it is on | `TestAC09_EveryScreen` | DALT-8 | ✅ green |
| AC-10 | Without a stored profile, daltonization offers no remap | `TestAC10_NoProfileNeedsAssessment` | CONTROL-2 | ✅ green |

**Grade grid:** `../behavior-test-completeness-bs-10-daltonization.md` — fresh SIGNOFF-1 whole-suite re-grade
appended: **10 A / 0 B — PASS**. The grader traced every Given/When/Then to the real shipped surfaces
(`daltonize`/`daltonizeColor`, the `displayedSwatchColor` chokepoint in `color_simulation.dart`, `ColorChip`,
the reactive `PersistentStore.changes` → `_AppState` → `withCvdProfile` path, `CvdProfileStore.hasSavedProfile`
through the app-root `CvdProfileReadEndpoint`) and confirmed each AC rejects a named wrong implementation, with
nothing passing vacuously.

---

## 4. Augmentations made

The plan pre-seeded four augmentation rows for the tests that were **green at the identity-remap shell** — each
closed by its behaviour phase once the real remap existed:

- **TestAC02 → DALT-6** — control: turning daltonization on remaps the swatch (changes from the original). ✅ Closed.
- **TestAC03 → DALT-9** — the off→on toggle moves the swatch off the original while the label `'Displayed colour'` and the `'55'` reading stay. ✅ Closed.
- **TestAC04 → DALT-10** — the off→on toggle remaps the provenance tint while the tier word and its glyph (a shape) stay. ✅ Closed.
- **TestAC08 → DALT-7** — control: the displayed swatch did change while the stored value did not. ✅ Closed.

TestAC01/05/06/07/09/10 carried no augmentation — grade-A at ITEST-2 and running on shipped behaviour. (The
ITEST *Test augmentations* cells for TestAC03/TestAC04 read "Open" through DALT-9/DALT-10; the augmentation
code was in place but the status cells had not been flipped — corrected to ✅ Closed this session after
verifying the assertions in `daltonization_test.dart`.)

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A (10 A). Nothing was closed by user acceptance of a gap.

Two standing honest caveats the fresh grader recorded as **A-with-caveat** (correct grain, with a stronger
discriminator behind each — not sub-A grades, and no augmentation owed):
- **AC-7** — the Then asserts the remap is *distinct* from the simulation projection (and that the colour
  moved), not that it equals the correct remap; remap correctness is proved at the AC grain by AC-1/AC-5, and
  for the spec's "not shown as the painter perceives them" the distinctness grain is the right one.
- **Widget units (DALT-9 `ColorChip`, DALT-10 `ProvenanceIcon`)** — these grade against the shipped
  `daltonizeColor`, so they assert the **widget-routing** contract (swatch == chokepoint output; label/glyph
  survive), not remap correctness. That correctness is proved independently only at the AC grain via
  `referenceDaltonize`. A legitimate division of labour.

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** G-1 (spec approval), G-2 (acceptance-test review), G-3 (bs-08 signed off + merged to `main`, merge
`0900d44`) and G-4 (bs-07 signed off + merged to `main`, merge `ecd3a9e`) all ✅ Resolved 2026-10-13. No open
or recorded-but-unresolved gates.

**Open known flakes:** none recorded for bs-10; none observed this session (coverage gate PASS first run; the
integration suite ran on a **booted** device and actually executed its 222 tests — not a false green).

**Known gaps / deferred by design (not defects):**

- **Daltonization × simulation interaction is out of scope (D-5 / bs-07 D-8).** The two display aids are
  independent toggles; AC-7 pins that the remap differs from the simulation projection, but the *combined*
  render when **both** are on is not a bs-10 AC. This is the D-8 sim/dalt gap bs-07 deferred — it belongs to a
  future cross-aid increment, not to this feature.
- **Daltonization × grayscale is out of scope (D-5).** No bs-10 AC covers the remap under bs-08 grayscale.
- **The remap matrix is a replaceable design decision (D-2), not a gate.** The shipped remap is
  error-redistribution daltonization over the existing `projectDichromat`
  (`daltonize(c,p) = c + redistribute(c − projectDichromat(c,p))`, scaled by severity), a pure
  `ColorCoordinates daltonize(ColorCoordinates, CvdProfile)` in `lib/a11y/cvd/daltonize.dart`, swappable behind
  the CVD module. It is display-only and never validated against measured CVD-viewer distinguishability — the
  owner may review or replace the exact matrix at sign-off without touching any AC.
- **Severity is a scalar on the stored profile (D-3).** The remap reads type + severity from the stored
  profile (bs-07); AC-5 proves a stronger severity yields a different (stronger) remap, but there is no
  per-axis calibration — the severity model is the shipped `CvdProfile.severity`.
- **No-profile affordance keys off the store's document count (D-4).** `hasSavedProfile` = `count() > 0`;
  because bs-07 defaults the injected `cvdProfile` to a const deutan when none is saved, the affordance must
  (and does) consult the **store**, not the injected profile.

---

## 7. Cost and tokens

From the *Token usage* ledger (20 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 156,275,235 tokens — input 2,496 · cache write 3,922,956 · cache read 151,386,000 · output 963,783.
- **Cost (API list rates, 2026-09-25):** **$134.47** (cache read $75.69 · cache write $34.67 · output $24.09 · input $0.01). All 20 sessions priced from their transcripts.
- **Span:** 2026-10-12 22:32 EDT → 2026-10-14 13:20 EDT — **Σ active 6h 54m** (Σ wall 7h 30m).
- **By stage:** scaffold $3.61 · shell $9.66 · acceptance tests $17.90 · test review $1.92 · behavior (direct $88.26) · sign-off $8.18 · activities (plan/gate) $4.93.
- **Per-AC (fully loaded, sums to the feature total):** shared work $4.62/AC; direct behavior $4.70 (AC-7) … $14.51 (AC-9), so fully loaded ≈ $9.32 (AC-7) … $19.13 (AC-9), mean ≈ $13.45/AC.

*(The cost report was generated from a normalized copy of the plan: `ac_cost.py` expects each module
dashboard's Phase cell to be a bare ordinal, while bs-10's dashboards spell the full phase name — the same
non-blocking plan-tooling quirk noted for bs-09. The token figures reconcile exactly with the ledger's Feature
total; a future tidy could renumber the dashboards to bare ordinals.)*

---

## 8. Summary page

Acceptance-suite summary page (built from this session's machine-readable results):
**→ https://claude.ai/artifact/2DYm5XZ4bLiVrrApLvjHcQ** — "Daltonization Sign-off" scorecard (verification
headline, 10 ACs with grades, controls, gates, cost). Private to the owner; share from the page's Share menu
for other reviewers. Its headline (unit 1279 · coverage 19/19 · integration 222 + bs-10 25 · 10 A) matches
this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the `Nuance-bs10` worktree root. Daltonization lives in the
shared **display-settings** panel (the `DisplaySettingsButton` in the app chrome, present on every screen).
Inside the panel: the **daltonization** on/off toggle (`display-bs10-daltonization`) and the
**no-saved-profile** region (`display-bs10-no-profile`). To watch the whole contract run green end to end:
`flutter test integration_test/daltonization_test.dart -d <booted-udid>` (25 tests).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| The UI can remap colours to maximise distinguishability for the painter's type | With a saved profile, open display settings and toggle **daltonization on**; off again. | On: the shown swatch colours **change** to a remap computed for the painter's **type** (protan/deutan/tritan each remap differently); off: colours return to their **original** values. The remap is display-only. |
| Remapping never removes the meaning carried in text or number | With daltonization on, look at a colour-coded reading and a provenance badge. | The swatch colour is remapped, but the element still shows its **text label** and **numeric value**; the provenance badge still shows its **tier word** and its **icon (a shape)** — readable without relying on colour. |
| Daltonization follows the painter's stored profile | Save a deutan-moderate profile, enable daltonization; then re-save the profile as protan. | The remap is computed for **deutan at moderate severity**; raising severity yields a **stronger** remap; re-saving as protan **recomputes the shown remap live** (no restart) — it follows the stored profile. |
| Daltonization is a display-only aid, distinct from simulation | With a sample that has stored colour values, enable daltonization, then read the stored values back. | The remapped swatch is **distinct** from what the simulation would show (daltonization aids *distinction*, not *perception*); the **stored colour values are unchanged** after the remap — only the display moved. |
| Daltonization is injected across every screen | With daltonization on, move between the **capture**, **readout** and **palette** screens. | The same known colour is remapped **on each screen** — the remap is applied at the one shared `ColorChip`/display chokepoint, not wired into a single screen. |
| Daltonization needs a profile to remap against | With **no** CVD profile saved, open the daltonization control. | The no-profile region reports that a **self-assessment is needed** before colours can be remapped, and **no remap** is applied; with a profile saved, that message is **absent** and the remap applies. |

A reviewer who wants to see the tests fail honestly can revert a behaviour phase's un-pend (re-add its AC to
`bs10/pending.dart` and remove it from the `unpended` set) and re-run: that AC's test goes red on its own Then.
AC-1/AC-5/AC-6/AC-7/AC-9/AC-10 were genuinely red at the DALT-2 identity shell; the real remap (DALT-3) and the
reactive store + no-profile affordance (DALT-11/CONTROL-2) are what turn them green.

---

## 10. Decision

Reviewer: **____________**  Date: **__________**  Decision: ☐ **Approved**  ☐ Changes requested

Record via `/feature-next-phase --signoff bs10 approved | changes "<items>"`.

- **Approved** → SIGNOFF-1 ✅; feature `Status: Done — signed off <date> by <reviewer> at <commit>`; merge
  `feat/bs-10` → `main` (throwaway worktree on `main` — the primary checkout on `feat/bs-04` has stale
  untracked specs that abort `checkout main`; `git merge -F <file>`, not stdin). This closes **bs-07 D-8**'s
  daltonization-behaviour deferral.
- **Changes requested** → each item becomes a new phase before a fresh SIGNOFF-2; this round's file stays as
  history.
