# Sign-off packet — Palette and projects (bs-06) — Round 1

**Feature:** bs-06-palette-and-projects · **Spec:** [bs-06-palette-and-projects.feature](../../bs-06-palette-and-projects.feature)
**Prepared:** 2026-10-11 (SIGNOFF-1) · **At code:** `feat/bs-06-palette-and-projects` @ `6ab1440` (PROJECT-6; sign-off commit stamped on decision)
**Decision:** ✅ **Approved** — Matt Quirk, 2026-10-11 (recorded via `--signoff`).

All 11 acceptance criteria are coded, un-pended and green by default (nothing pending); the full
cross-feature regression (bs-01/02/03/04/06) is green; a fresh independent full-suite grade grid is
**26×A, 0 below A**. This packet is the evidence for the decision.

To record the decision:
`/feature-next-phase --signoff bs-06-palette-and-projects approved | changes "<items>"`

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 19/19 build phases ✅ Done (DATA/PALETTE/PROJECT/SCREEN/ITEST modules all done) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-11 all ✅ |
| Pending list empty | ✅ `integration_test/bs06/pending.dart` `pendingACs = {}` |
| No open row in ITEST *Test augmentations* | ✅ all 5 augmentation rows closed (TestAC02/05/07/09/10) — the AC02/AC10 status cells were stale (the work landed in PALETTE-3 / PROJECT-6 and is verified in the test code); flipped to ✅ Closed this session |
| Fresh whole-suite grade grid all A | ✅ 26×A / 0 below A (fresh-context grader, this session) |
| No open decision/dependency gates | ✅ G-1…G-4 all ✅ Resolved |

---

## 2. Full verification (worktree checkout, this session)

Toolchain: Flutter 3.47.6 stable; iOS sim iPhone 17 `5AB9D06D…51685`; integration run under the verify lock.
Machine-readable results produced on the first run (`flutter test --machine`) for both integration runs; the
summary page (§8) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze lib test` | **No issues found** (clean, 12.1s) |
| Unit + coverage | `flutter test --coverage` | **760 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all **29** touched bs-06 `lib/` files (first run; no flake) |
| Acceptance — all features (default) | `flutter test integration_test/ -d <udid> --machine` | **109 passed, 0 failed, 0 pending** (bs-01 harness 5 + readout 12 · capture 19 · comparison 26 · recipes 24 · palette 23) |
| Acceptance — bs-06 (run-pending) | `flutter test integration_test/palette_test.dart -d <udid> --dart-define=BS06_RUN_PENDING=true --machine` | **23 passed, 0 failed, 0 skipped** — identical to default (nothing pending) |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **26×A, 0 below A — PASS** (11 AC tests + 2 smoke + 7 fixture guards + 3 pending-gate guards + 3 harness artifacts) |

The 29 touched `lib/` files at 100%: `app/{build_app,router}.dart`, `compare/sample_source.dart`,
`domain/paint.dart`, `main.dart`, `palette/{paint_dataset,paint_list_region,palette_controller,
palette_read_endpoint,palette_screen,palette_selector_region,projects_region,provenance_legend_region,
self_assessment_entry_screen,vision_profile_card}.dart`, `projects/{confusion_pairs,project,
project_controller,project_export,project_read_endpoint,project_source,project_summary}.dart`,
`recipes/palette_source.dart`, `store/{app_database,drift_persistent_store,persistent_store,
source_photo_store}.dart`, `widgets/{paint_row,provenance_legend}.dart`.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green; the confusion-pair detection (AC-9) is graded against the
harness's **independent** `referenceConfusable` (CIEDE2000 + Viénot-1999 deutan projection), never the
product detector.

| AC | Scenario | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | Switch between the My paints and Projects views | `TestAC01_SwitchViews` | SCREEN-2 | ✅ green |
| AC-2 | Each paint is listed with its identity and provenance badge | `TestAC02_PaintIdentityProvenance` | PALETTE-3 | ✅ green |
| AC-3 | The provenance legend explains the four confidence tiers | `TestAC03_ProvenanceLegend` | PALETTE-3 | ✅ green |
| AC-4 | The painter adds a paint from the shipped dataset | `TestAC04_AddPaintFromDataset` | PALETTE-2 | ✅ green |
| AC-5 | Selecting a palette makes recipes solve against it | `TestAC05_SelectedPaletteDrivesRecipes` | PALETTE-4 | ✅ green |
| AC-6 | The projects list shows size, counts and last edit | `TestAC06_ProjectsListSummary` | PROJECT-3 | ✅ green |
| AC-7 | Opening a project shows its notes and source photo | `TestAC07_OpenProjectNotePhoto` | PROJECT-4 | ✅ green |
| AC-8 | A note is retained when the project is reopened | `TestAC08_NoteRetainedOnReopen` | PROJECT-4 | ✅ green |
| AC-9 | A confusable pair of saved samples is flagged | `TestAC09_ConfusionPairFlagged` | PROJECT-5 | ✅ green |
| AC-10 | The painter exports a project as a PDF studio sheet | `TestAC10_ExportPdfStudioSheet` | PROJECT-6 | ✅ green |
| AC-11 | The vision-profile card shows the estimate and opens the self-assessment | `TestAC11_VisionCardEstimateAndOpen` | SCREEN-3 | ✅ green |

**Grade grid:** `../behavior-test-completeness-bs-06-palette-and-projects.md` — fresh SIGNOFF-1 full-suite
re-grade appended: **26×A, 0 below A — PASS** (11 AC tests + 2 smoke + 7 fixture guards + 3 pending-gate
guards + 3 harness artifacts). The grader traced every Given/When/Then to the real production
widgets/controllers and confirmed each AC rejects a named wrong implementation.

---

## 4. Augmentations made (all closed)

Each limited AC test was strengthened by the behaviour phase that produced the real output, so the test
discriminates against the pre-phase code (ITEST *Test augmentations* table, all ✅ Closed):

- **TestAC02** (PALETTE-3) — asserts the **exact rendered provenance tier** and the **medium at a
  non-subsumed grain** (a dedicated medium label widget `PaintRow.mediumKeyFor`, not the "Artists' Oil" line
  text), with a differently-tiered, different-medium control paint — rejecting a hardcoded Measured/Oil badge.
- **TestAC05** (PALETTE-4) — asserts **every returned recipe's paints ⊆ the selected palette** with a
  disjoint-palette control, so an impl that ignores the selection fails.
- **TestAC07** (PROJECT-4) — the source photo is asserted via a widget scoped to `openProjectViewKey` and
  tied to `harborPhotoBytes` (`isA<MemoryImage>()` + `.bytes == harborPhotoBytes`), not a bare `Image` match.
- **TestAC09** (PROJECT-5) — adds a clearly-distinct control pair (Mid Raw Umber / Hull Red) asserted **not**
  flagged, plus `hasLength(1)`, rejecting both a no-op and an over-flagging impl.
- **TestAC10** (PROJECT-6) — asserts the produced PDF references **each** sample (by name) and **each** recipe
  (by its ` + `-joined component paint-list); each recipe carries a unique paint, so an omission is caught.

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A (26×A); nothing was closed by user acceptance of a gap.

Four standing documented caveats are recorded by the fresh grader as **A-with-caveat** data/design limits — not
sub-A grades, and no augmentation is owed:
- **AC-4** — every paint in the shipped reviewed dataset is `measured` (a data limit; the TestAC02 differently-tiered control still guards the badge).
- **AC-9** — the harness's reference deutan *projection* shares the shipped Viénot-1999 coefficients (inherited from the bs-03 harness); the ΔE00 metric and the predicate logic remain independently checked.
- **AC-10** — content is matched in the PDF `/Info` metadata rather than the laid-out content stream; production also renders every sample and recipe visibly.
- **AC-6** — `'1 recipe'` is a substring of `'1 recipes'`; the exact count value and a swap are still pinned, so this does not weaken the assertion.

One cheap hardening the grader suggested (non-blocking): add `expect(pendingACs, isEmpty)` inside the
"every pending AC is owned by a real behaviour phase" guard, now that the map is correctly drained; the
sibling guard already pins `pendingACs == {}`.

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** G-1 (spec approval), G-2 (acceptance-test review), G-3 (bs-04-merged dependency), G-4 (data
contracts + project-local deps) all ✅ Resolved. No open or recorded-but-unresolved gates.

**Open known flakes** (carried from the bs-01/03/04 foundation; neither observed this session):

| Test | Symptom | Mitigation |
|---|---|---|
| coverage_gate const-constructor line | `flutter test --coverage` can intermittently record a const-folded constructor line as uncovered | re-run once; green on re-run ⇒ ignore. Did not occur this session (gate PASS first run). |
| integration without `-d <udid>` | a device-less run executes zero tests and still exits 0 (false green) | always pass `-d <booted-udid>`. Done — sim booted, the suite actually ran. |

**Known gaps / deferred by design (not defects):**

- **bs-07 self-assessment is a placeholder (D-7).** AC-11's "retake the self-assessment" navigates to a
  `self_assessment_entry_screen` placeholder; the real CVD self-assessment is bs-07 (unbuilt). bs-06 only
  *reads* the injected `CvdProfile` estimate and navigates — it never writes the profile.
- **AC-8 "reopen" is a persistent seed→load round-trip (accepted at G-2).** The app has no in-session
  close/reopen yet; AC-8 asserts the exact persisted note is shown on open (a distinct discriminating
  assertion from AC-7), seeded through the persistent save flow, not an app-driven close/reopen cycle.
- **AC-4 uniform-measured-dataset data caveat.** Every paint in the shipped reviewed dataset is `measured`
  (D-3 default), so AC-2's badge could in principle be satisfied by a hardcoded tier — mitigated by the
  TestAC02 differently-tiered control. A multi-tier reviewed dataset is a later data concern, not a defect.
- **AC-10 PDF content proxy (documented, non-blocking).** The content assertion matches each sample/recipe
  string in the PDF `/Info` metadata (the `pdf` package lays the visible content stream out word-by-word, so
  literals are not contiguous there); the sheet **also** renders every sample and recipe visibly via
  `pw.Bullet`, so the metadata match is a sound documented proxy for "references each sample and each recipe".
- **Source photo stored as a reference (D-10).** The project holds a `sourcePhotoRef`; the photo bytes live
  in the injected `SourcePhotoStore`. Tests assert presence/round-trip and byte identity, never pixel content.
- **Measured optical (K/S) paint data deferred (D-2).** `Paint` gained `brand`/`line`/`provenance` as
  additive fields with safe defaults; spectral mixing data stays a later upgrade behind the same interfaces.
- **Real device share faked in tests.** The `printing` share seam (`PdfShareSink`) is wired in `main` and
  faked/null in the acceptance suite — the produced-artifact signal (`ProjectController.lastExport` bytes) is
  the observable, per D-6 (no real disk/share I/O in tests).

---

## 7. Cost and tokens

From the *Token usage* ledger (25 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 210,892,472 tokens — input 3,176 · cache write 5,291,425 · cache read 204,439,746 · output 1,158,125.
- **Cost (API list rates, 2026-09-25):** **$179.76** (cache read $102.22 · cache write $48.57 · output $28.95 · input $0.02). 20 of 25 sessions priced from their transcripts; 5 estimated at their ledger model.
- **Span:** 2026-10-10 06:10 EDT → 2026-10-11 20:21 EDT — **Σ active 8h 26m** (Σ wall 23h 05m).
- **By stage:** scaffold $4.42 · shells $29.67 · acceptance tests $27.39 · test review $1.96 · behavior (enabler $3.77 + direct $87.88) · sign-off $9.92 · activities (plan/reconcile/gate) $14.74.
- **Per-AC (fully loaded, sums to the feature total):** shared work $8.35/AC; fully loaded $11.29 (AC-2/AC-3) … $24.12 (AC-5), mean ≈ $16.3; direct behavior $2.93 (AC-2/3) … $15.76 (AC-5).

---

## 8. Summary page

Acceptance-suite summary page (built from this session's machine-readable results):
**→ https://claude.ai/artifact/EWvLAX4Lef1kz5hyiniS47** — "Palette & Projects Sign-off" scorecard (verification
headline, 11 ACs with grades, augmentations, cost). Private to the owner; share from the page's Share menu for
other reviewers. Its headline (unit 760 · coverage 29/29 · integration 109 + 23 run-pending · 26×A) matches
this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the repo root; the app opens on the Capture screen, then
reach **Palette** (the home-screen Palette entry). The Palette screen regions are the E30 vision-profile
card, the E31 view selector (My paints ⇄ Projects), the paint list with E32 "Add paint", the provenance
legend, the palette selector, and the Projects list with E33 "Open" and E34 "Export". To watch the whole
contract run green end to end: `flutter test integration_test/palette_test.dart -d <booted-udid>` (23 tests).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| Keep paints and projects in two views | Tap the **E31** selector and switch to **Projects**, then back to **My paints**. | One view at a time: switching to Projects shows the saved projects and hides the paint list; switching back shows the paints and hides the projects. |
| Every paint shows its provenance, never colour alone | Read the My-paints list row for **Titanium White**. | The row shows brand "Winsor & Newton", line "Artists' Oil", medium "Oil", pigment "PW6" **and** a "Measured" provenance badge — not a colour swatch alone. |
| The provenance legend explains the four tiers | Read the provenance legend below the paint list. | Four tiers spelled out: "Measured", "Calculated", "Estimated — not yet verified", "Confirmed — you measured this". |
| Build a palette from the reviewed dataset | Tap **E32** "Add paint" and choose **Ultramarine Blue** from the reviewed dataset picker. | "Ultramarine Blue" is added to My paints carrying its dataset provenance (not a blank/free-hand value). No free-hand paint entry is offered (v1 boundary). |
| The selected palette drives recipes | With palettes "My paints" and "Travel set" present, select **Travel set** as active. | Recipe search re-points to Travel set — every offered recipe uses only Travel-set paints (the two palettes are disjoint, so this is visible). |
| Projects list shows size, counts and last edit | Open the **Projects** view and read the **Harbor at Dusk** row. | "24×30 in", "6 samples", "3 recipes", and "edited today". |
| Opening a project shows its notes and source photo | Tap **E33** (or the Harbor row) to open it. | The open-project view shows the project's note verbatim and its source photo. |
| A note is retained on reopen | Navigate away and reopen **Harbor at Dusk**. | The note "Keep the hull and wall values 2 steps apart." is still shown — it was persisted, not held in memory. |
| A project flags confusion pairs | Open **Harbor at Dusk** (vision profile a deutan collapse). | The pair **Mid Raw Umber / Ultramarine Shadow** is flagged as a confusion pair "to check by value"; a clearly-distinct pair is not flagged. |
| A project exports as a printable sheet | With Harbor open, tap **E34** "Export to device". | A PDF studio sheet of the project's samples and recipes is produced (every sample and every recipe appears on the sheet). |
| Reach the CVD self-assessment from the palette | Read the **E30** vision-profile card, then tap "retake the self-assessment". | The card shows the current estimate "deutan-type, moderate"; tapping navigates to the CVD self-assessment entry (bs-07 placeholder). |

A reviewer who wants to see the tests fail honestly can run with `--dart-define=BS06_RUN_PENDING=true`
(identical to default now — nothing pending) or revert a behaviour phase's un-pend and re-run: that AC's
test goes red on its own Then, confirming the tests discriminate.

---

## 10. Decision

Reviewer: **Matt Quirk**  Date: **2026-10-11**  Decision: ☑ **Approved**  ☐ Changes requested

Record via `/feature-next-phase --signoff bs-06-palette-and-projects approved | changes "<items>"`.

- **Approved** → SIGNOFF-1 ✅; feature `Status: Done — signed off 2026-10-11 by Matt Quirk at 6ab1440`. ✅ **Recorded.**
- **Changes requested** → each item becomes a new phase before a fresh SIGNOFF-2; this round's file stays as history. *(not taken)*
