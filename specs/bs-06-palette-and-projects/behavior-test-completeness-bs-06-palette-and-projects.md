# bs-06 Palette and projects — behaviour-test completeness

**Phase graded: ITEST-1 (acceptance-suite *harness*).** This is an independent,
adversarial grade of the harness phase only — the Given/When/Then vocabulary,
the fixtures, the independent confusion reference, the never-pending smoke
tests, the fixture guards, and the pending-gate scaffold guards. ITEST-1 writes
**no per-AC tests** (those are ITEST-2/3), so each row is graded against
ITEST-1's own bar: no vacuous passes, comments that claim only what the code
checks, determinism, and valid fixtures/independent reference for the downstream
ACs.

Grade key: **A** = meets the bar; **B (rule)** = fails the named rule.

| Test / Artifact | Grade | Justification |
|---|---|---|
| **Smoke:** `the assembled app boots to the Palette screen showing every region` | A | Asserts the real `buildApp` boots to the `Palette` AppBar, both read endpoints mount, and all six region keys resolve (verified the shells mount `VisionProfileCard.regionKey`, `viewSelectorKey`, `PaintListRegion.regionKey`, `ProvenanceLegendRegion.regionKey`, `PaletteSelectorRegion.regionKey`, `ProjectsRegion.regionKey`). Also pins the shell resting state through the live endpoints (`myPaints`/`palettes`/`selectedPalette`/`projects`/`openedProject`/`confusionPairs`/`lastExport`/`selfAssessmentOpen` empty/null/false, no speech, 0 haptics). Each assertion would fail against a mis-wired shell; deterministic (`pumpAndSettle`, no sleeps). |
| **Smoke:** `seeded sources are read back through the endpoints` | A | Seeds `twoPalettes` + `harborProject` + a photo through the **production persistent sources** and asserts round-trip through the controllers: palette order `['My paints','Travel set']`, `selectedPalette == 'My paints'` (first), `myPaints` containsAll `['Titanium White','Raw Umber']`, projects `['Harbor at Dusk']`. Would fail if the source dropped/reordered or the endpoint were unwired. Photo round-trips via the sink **and** `photos.writes == 0` pins that seeding is not a recorded save. Deterministic. |
| **Fixture guard:** `reviewedDataset carries the AC-2 and AC-4 paints` | A | `firstWhere` throws if "Titanium White" is absent, then pins brand/line/medium/`PW6`/`provenance == ProvenanceTier.measured` (verified `Paint.provenance` is a `ProvenanceTier`, so the comparison is type-correct and passes against shipped `kReviewedPaints`), and asserts "Ultramarine Blue" present for AC-4. Not vacuous — a wrong dataset fails it. |
| **Fixture guard:** `twoPalettes are named "My paints"/"Travel set" and disjoint` | A | Pins both names/order, asserts each palette non-empty (so the disjointness check cannot pass on empty sets), and asserts the id-set intersection is empty. Verified fixtures are genuinely disjoint by id (`pw6/py42/pbr7/pbk9` vs `pb29/py35/pr108`). The non-empty guards close the vacuous-empty-set hole. |
| **Fixture guard:** `harborProject has the counts, note and photo AC-6..AC-10 assume` | A | Pins name, size `"24×30 in"` (AC-6), `samples.length == 6`, `recipes.length == 3`, note, `sourcePhotoRef`, and `lastEdited != null`; plus `samples.length == recipes.length` is `isFalse` so an impl that swaps the two counts is caught. Matches AC-6/7/8/10 fixture needs. |
| **Fixture guard:** `exactly one harbor sample pair is confusable for a deutan (AC-9)` | A | Loops all 15 pairs of the const 6-sample list (cannot be empty), cross-checks shipped `DichromatConfusionCheck` vs the harness `referenceConfusable` on **every** pair, then pins the flagged set to exactly `{'Mid Raw Umber/Ultramarine Shadow'}` — pins both count **and** identity. I re-ran the Viénot projection + CIEDE2000 independently: exactly that pair flags (projected ΔE00 ≈ 0.77, normal ≈ 22.0); all others are well clear. Guard is genuinely green and non-vacuous. |
| **Fixture guard:** `the confusion pair is a deutan collapse, not a plain near-match` | A | Independent-reference normal ΔE00 `> 10` (verified ≈ 22.0, so not a trivial near-match); flagged under `deutanDichromat` (`isTrue`) but **not** under `deutanModerate` (`isFalse`, verified projected ≈ 9.7 > 3.0); and a real control — `Mid Raw Umber`/`Hull Red` — is `isFalse` (verified projected ≈ 5.95). This is the genuine non-flag control and it justifies the full-dichromat choice for AC-9. |
| **Fixture guard:** `the vision-profile fixtures are the deutan profiles their ACs name` | A | Pins `deutanModerate` = deutan/0.6 (AC-11 "moderate") and `deutanDichromat` = deutan/1.0 (AC-9 full collapse). Matches the spec: AC-11 names "deutan-type, moderate"; AC-9 names only "the painter's confusion line" (no severity), and the shipped detector's fixed 3.0 projected-ΔE threshold only fires near full dichromacy (confirmed: moderate does not collapse the pair). The split-profile choice is sound and guard-backed, not a smell. |
| **Fixture guard:** `FakeFileSink records saves and round-trips; seed does not count` | A | Pins `writes == 0` after construction and after `seed` (seed pre-stores without a save), round-trips seeded bytes, then a real `save` bumps `writes` to 1, records the ref in `saved`, and round-trips. Distinguishes seed from save exactly as the smoke test relies on. Deterministic. |
| **Pending-gate guard:** `pending map covers exactly AC-1..AC-11` | A | Pins `pendingACs.keys` to exactly the AC-1..AC-11 set — a missing/extra/typo'd AC fails. Verified `bs06/pending.dart` seeds exactly those 11. |
| **Pending-gate guard:** `every pending AC is owned by a real behaviour phase` | A | Asserts every owner is in the non-empty `behaviorPhases` set (verified it lists the 9 real bs-06 behaviour phases; the PROJECT-2 enabler is correctly excluded as owning no AC). Catches a stale/typo'd owner. Non-vacuous (map is non-empty). |
| **Pending-gate guard:** `pendingSkipReason skips a pending AC by default, runs it when forced` | A | Asserts both directions — pending AC skipped by default (non-null), run when forced (`forceRunPending: true` → null) — and that an un-pended/absent AC (`AC-999`) always runs. `forceRunPending` keeps it deterministic without touching the environment. |
| **Artifact:** Given/When/Then vocabulary (`PaletteHarness`, `when…`, `givenPalette`) | A | Every `when…` drives a real control that the SCREEN-1 shell mounts as **inert** (verified each key — `viewSelectorKey` 'Projects'/'My paints' `TextButton`s, `addPaintKey`, `openProjectKey`, `exportKey`, `retakeKey` — is present with `onPressed: null`), so `tap(..., warnIfMissed: false)` finds exactly one widget and no-ops instead of throwing "zero widgets found"; it never panics at the red baseline. `whenSelectPalette` instead asserts a precondition naming PALETTE-4, so an AC-5 test fails cleanly. Read seams (`paletteController`/`projectController` via endpoints, `palettes`/`selectedPalette`/`myPaints`/`projects`/`openedProject`/`confusionPairs`/`lastExport`/`selfAssessmentOpen`) are all real getters. `givenPalette` rebuilds a fresh app each call and uses `pumpAndSettle` throughout — deterministic. Minor (non-failing) note: `whenOpenProject(name)` ignores `name` and taps the single shell control; harmless as an inert forward-driver, but PROJECT-4 will need per-project keys to honour the docstring. |
| **Artifact:** Fixtures + independent confusion reference (`referenceConfusable`, reused bs-03 `referenceDeltaE00`/`referenceDeutanProjectedDeltaE00`) | A | Fixtures are stable constants (samples/palettes `const`; recipes/photo bytes `final`), named to match the plan catalogue. The confusion reference is genuinely separate code from the shipped detector: `referenceConfusable` re-implements the D-5 predicate and feeds it the bs-03 reference ΔE00 (an independent CIEDE2000, externally validated upstream against Sharma et al.), so the detector's threshold/direction/metric are cross-checked against code it does not call. **Documented caveat (noted, not failing):** the reference *projection* (`referenceDeutanProjected`) uses the identical Viénot 1999 LMS coefficients as the shipped `projectDichromat` and, at severity 1.0, is bit-for-bit the same mapping — so a transcription error in those shared matrices would not be caught by the cross-check, and the projection reference is validated only by invariants (grey-unchanged, idempotent), not external vectors. This is inherited from the bs-03 harness and is consistent with the codebase's reference-implementation standard; the ΔE00 metric and the predicate logic remain independently checked. |
| **Artifact:** `FakeFileSink` recording `SourcePhotoStore` | A | Faithful recording fake: copies bytes in/out (no aliasing, matching the production contract), `seed` pre-stores without counting, `save` records refs in order, `writes`/`saved`/`lastBytes`/`read`/`exists`/`delete` are honest seams. Doc-comment claims match behaviour (it explicitly notes the AC-10 PDF export is *not* routed here — it is read off `ProjectController.lastExport`), so no overstatement. |

## Verdict

**15 A, 0 B — PASS (all A).** No vacuous passes: every loop guards its set's
size/identity and the one-confusable-pair guard pins the exact pair; every smoke
assertion and fixture guard would fail against a wrong shell/fixture (verified
the AC-9 math independently — exactly one pair flags). Comments claim only what
the code checks. Deterministic throughout (`pumpAndSettle`, stable constant
fixtures, no sleeps or wall-clock ordering). The only substantive weakness — the
AC-9 reference *projection* shares the shipped Viénot coefficients, so AC-9's
projection step is effectively graded against a clone — is documented and
inherited from bs-03; it does not rise to a vacuous pass or a false comment, so
it is recorded as a caveat rather than a B. Nothing must change for this phase to
pass. (Follow-on, not blocking: when PROJECT-5 lands the real detector,
consider giving the projection reference external numeric validation, and have
PROJECT-4 wire per-project open keys so `whenOpenProject(name)` honours its
docstring.)

## Phase graded: ITEST-2 (AC tests — AC-1,2,3,4,5,11)

This is an **independent, adversarial** grade of the ITEST-2 per-AC tests only —
the six `acTestWidgets` in `group('palette ACs (ITEST-2)', …)` for AC-1, AC-2,
AC-3, AC-4, AC-5 and AC-11. I did not write these tests. I graded the test
*design* — whether each would discriminate a wrong implementation once the
behaviour exists — against rules G1–G6, judging the code as it stands today
(pending or not). I re-read the authoritative AC text, the harness
vocabulary/fixtures, the reviewed dataset, and every SCREEN-1 shell each test is
wired to. The ITEST-1 harness/smoke/fixture rows above are unchanged. Two tests
are **B pending** against existing augmentation rows (TestAC02→PALETTE-3,
TestAC05→PALETTE-4, both ⬜ Open in `modules/ITEST.md`); no test is an
unsanctioned B, so the phase passes. One finding (AC-2 medium subsumption) is
recorded below and must widen the PALETTE-3 augmentation.

| Test | Grade | Justification |
|---|---|---|
| **AC-1** `switch between the My paints and Projects views` | A | Given checked through the public surface (`PaintListRegion.regionKey` present after `givenPalette(twoPalettes)`). When drives the real E31 control (`whenSwitchToProjects`). Then asserts the spec's "instead of" grain exactly: `ProjectsRegion` present **and** `PaintListRegion` `findsNothing` after a `pumpAndSettle` settle point — rejects the shell's both-at-once layout (the actual red-baseline failure) and a toggle that shows both. Paired control switches back and asserts the mutually-exclusive inverse, proving the reading changes **both** ways (G3). Rejects: non-toggling, one-way, and show-both impls. |
| **AC-2** `each paint lists its identity and provenance badge` | B pending PALETTE-3 | Given fully checked via `myPaints` (brand/line/medium/pigmentIndex/provenance). Then asserts identity strings + a "Measured" badge scoped to the paint-list region, rejecting the shell's name-only row. **Limited (sanctioned):** every reviewed paint is `measured` and `Paint.provenance` defaults to `measured`, so a hardcoded-"Measured" badge passes — the exact-tier discrimination needs a differently-tiered paint, scheduled as the PALETTE-3 augmentation (TestAC02, row exists). **Additional defect this grader found (not yet in the augmentation):** the medium sub-assertion `find.textContaining('Oil')` is subsumed by the line `"Artists' Oil"`, so an impl that renders brand/line/pigment but **omits the medium entirely** still passes. The PALETTE-3 augmentation must be widened to assert the medium at a non-subsumed grain (e.g. a dedicated medium label/widget), not only the provenance tier. |
| **AC-3** `the provenance legend explains the four confidence tiers` | A | Given checks the legend region is present. Then asserts all four tiers by their **exact** spec strings scoped to the legend region, including the long forms `'Estimated — not yet verified'` and `'Confirmed — you measured this'` (not the short `label` getters) — rejects a legend missing any tier or using the abbreviated label. The four strings are static explanatory copy, so asserting fixed text is correct (not a data-derived value). Rejects the shell placeholder and any partial/renamed legend. |
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat) | Given checked (`myPaints` empty), add flow opened via the real E32 control, and the picker precondition (`'Ultramarine Blue'` offered) asserted before the When — all through public flows (G2: the real `kReviewedPaints` via the real controller, no fake override). Then asserts full `Paint` **value-equality** to the exact dataset entry, so it rejects a free-hand / blanked / fabricated / wrong-masstone / dropped-pigment-index paint. **Caveat (verified, non-blocking):** the reviewed dataset is uniformly `ProvenanceTier.measured` and `Paint.provenance` defaults to `measured`, so "provenance preserved" cannot be separated from a hardcoded-measured impl — but no non-measured reviewed paint exists in v1 to build a control from, and value-equality is the strongest available assertion and does pin the measured value that is the dataset's. A-with-caveat, not B: it rejects the realistic wrong impls and asserts the named observable at full grain. If a non-measured reviewed paint is ever shipped, add a preserved-tier control. |
| **AC-5** `selecting a palette re-points recipe search at it` | B pending PALETTE-4 | Given checked (palette order + `selectedPalette == 'My paints'` as the initial active). When drives selection through the harness precondition that names PALETTE-4. Then asserts the **active-palette re-point** (`selectedPalette == 'Travel set'` and its disjoint id-set) — a proxy, **not** the spec's named observable "recipe search solves only against Travel set". **Limited (sanctioned):** no recipe-solving surface is mounted on the Palette screen until PALETTE-4, so an impl that moves the active pointer but does not re-point the solver would pass now; the "every recipe's paints ⊆ selected palette" control is the PALETTE-4 augmentation (TestAC05, row exists). |
| **AC-11** `the vision-profile card shows the estimate and opens the self-assessment` | A | Given checks the card is present and `selfAssessmentOpen` is false (the baseline for the navigation control). Estimate Then asserts the exact string `'deutan-type, moderate'` scoped to the card region, driven by the **injected** `deutanModerate` profile (configured Given, G2 — the test sets the input profile, not the card text). Navigation Then asserts `selfAssessmentOpen` flips false→true after `whenRetakeAssessment`, with the pre-check acting as its before/after control (G3). Rejects a blank card, a wrong estimate, and a no-op retake. **Recommended hardening (non-blocking):** only one profile is exercised, so a card that ignores the profile and prints a constant `'deutan-type, moderate'` would pass the estimate step; a second-profile control (e.g. a protan/severe `CvdProfile`, asserting a different rendered estimate) would prove the label tracks the injected profile. Graded A — it rejects multiple plausible wrong impls and asserts the exact named observable from the configured Given — but the control is cheap and should be added. |

**Counts: 4×A, 2×B pending — PASS (no unsanctioned B).** AC-1/AC-3/AC-4/AC-11
meet the bar; AC-2 (PALETTE-3) and AC-5 (PALETTE-4) are B against existing,
confirmed augmentation rows. Blocking finding: none. Required fold-in: the
PALETTE-3 augmentation for TestAC02 must also assert the **medium** at a
non-subsumed grain (today `'Oil'` is satisfied by the line `"Artists' Oil"`), in
addition to the exact provenance tier.

## Phase graded: ITEST-3 (AC tests — AC-6,7,8,9,10)

This is an **independent, adversarial** grade of the ITEST-3 per-AC tests only —
the five `acTestWidgets` in `group('project ACs (ITEST-3)', …)` for AC-6, AC-7,
AC-8, AC-9 and AC-10. A fresh grader (not the author) graded against G1–G6, with
the ITEST-2 grid above for continuity. Red baseline confirmed clean: all five
fail on a Then / Given-precondition (TestFailure, no harness/compile error) at
the cited lines. The ITEST-1/ITEST-2 rows above are unchanged.

| Test | Grade | Justification |
|---|---|---|
| **AC-6** `projects list shows size, counts and last edit` | A | G1: every Given checked through the read endpoint before the When — name, `size=='24×30 in'`, `samples.length==6`, `recipes.length==3`, `lastEdited` non-null and `inDays==0`. G4 at grain: Thens assert the exact size string, `'6 samples'` and `'3 recipes'` scoped to `ProjectsRegion` (6≠3 so a count-swap is caught), plus a case-insensitive `'today'` Text. Rejects the shell's name-only row (the red-baseline failure at `:489`). **Residual (non-blocking, same class as ITEST-2's AC-11):** the `'today'` Then asserts the literal value, so a PROJECT-3 impl that hardcodes `Text('today')` rather than computing from `lastEdited` passes — a cheap older-second-project control is recommended for PROJECT-3 (recorded as a non-blocking handoff follow-on, matching AC-11's treatment). |
| **AC-7** `opening a project shows its note and source photo` | B pending PROJECT-4 | G1 control: `openedProject` null to begin with; note round-trips via the sink. Note Then is strong — `find.textContaining(harborNote)` verbatim (the note string is long/distinctive). **Limited (sanctioned, new row):** "the source photo is shown" rests on a type-only, unscoped `find.byType(Image)` (`lib/` has zero `Image`s today, so it does catch "no photo", but a wrong PROJECT-4 rendering a decorative/wrong-bytes image passes); tying the shown photo to `harborPhotoRef`/`harborPhotoBytes` can only discriminate once PROJECT-4 mounts the open-project view. Added as the **TestAC07 → PROJECT-4** augmentation row. Red baseline fails at the opened-project Then (`:535`). |
| **AC-8** `a note kept is retained when reopened` | A | G4-tight: asserts `openedProject?.note==harborNote` at the model grain **and** the verbatim rendered note, with a `harborNote.isNotEmpty` guard closing the vacuous-`""` hole — rejects a default/placeholder/truncated note (red baseline `:567`). G6 holds: distinct from AC-7 (AC-7 never asserts `openedProject.note`; AC-8 never asserts the photo). **Caveat (documented, non-blocking):** "retained across *reopen*" is carried by `givenPalette`'s persistent seed→load round-trip, not an app-driven edit/close/reopen cycle — it really tests "the exact persisted note is shown on open", still a distinct discriminating assertion → A. Noted in the review packet so the reviewer isn't misled by the comment. |
| **AC-9** `confusable pair flagged within a project` | B pending PROJECT-5 | G2 exemplary: injected `deutanDichromat` drives the flag and the Given pair is confirmed via the harness's **independent** `referenceConfusable`, never the shipped `DichromatConfusionCheck` it grades. Then asserts the exact pair by name via `anyElement(unorderedEquals(...))` plus a `'check'` warning; red baseline fails on the empty `confusionPairs` (`:615`). **Limited (sanctioned):** `anyElement` can't reject an over-flagging impl until PROJECT-5 computes — the "clearly-distinct pair is NOT flagged" control is the existing **TestAC09 → PROJECT-5** row. |
| **AC-10** `export a project as a PDF studio sheet` | B pending PROJECT-6 | Given checks name/6 samples/3 recipes, the `lastExport==null` control, **and** (G1 fix folded in this phase) the opened-project precondition naming PROJECT-4 after `whenOpenProject` — so the spec's "has opened the project" Given is checked; it is the clean red-baseline failure (`:660`, open inert; PROJECT-4 precedes PROJECT-6 so it passes by the un-pend run). Then asserts a real PDF: `isNotNull` + `%PDF-` magic bytes — rejects null/empty/placeholder blobs. **Limited (sanctioned):** the sheet's content ("references each sample and each recipe") needs a real PDF — the existing **TestAC10 → PROJECT-6** row. |

**Counts: 2×A, 3×B pending — PASS (no unsanctioned B).** AC-6/AC-8 meet the bar;
AC-7 (PROJECT-4, new row), AC-9 (PROJECT-5) and AC-10 (PROJECT-6) are B against
augmentation rows. Blocking finding: none (the grader's one unsanctioned B —
AC-7's bare `find.byType(Image)` — was resolved by adding the TestAC07 → PROJECT-4
augmentation row; AC-10's G1 Given-check was folded in this phase). Non-blocking
follow-on: a PROJECT-3 older-second-project control to kill a hardcoded-`'today'`
cheat on AC-6.

---

## Phase graded: PALETTE-2 (behavior — AC-4 un-pended)

Independent adversarial re-grade (fresh subagent, given the ITEST-2 grid + G1–G6)
of the **un-pended** AC-4 test, now running green against the real
`addPaintFromDataset` + E32 picker. Only un-pended AC in scope this phase.

| Test | Grade | Justification |
|---|---|---|
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat) | **G1** Givens checked through the public surface before the When: `myPaints` empty asserted; `whenAddPaint()` drives the real E32 control (`addPaintKey` → `_openDatasetPicker` → `showModalBottomSheet`, now wired, not inert); picker precondition ("Ultramarine Blue" offered) asserted before the tap. **G2** The picker reads `controller.reviewedDataset` = shipped `kReviewedPaints` (not a fake override); `addPaintFromDataset` appends the exact tapped `Paint` (`[...?current?.paints, paint]`, no field rewriting) and persists via `PersistentPaletteSource.savePalette`, so provenance genuinely flows through. **G4** full `Paint` value-equality to the exact dataset entry + explicit `provenance` equality (`Paint.==` includes provenance). **G5** rejects a free-hand / blanked / fabricated / wrong-masstone / dropped-pigment-index paint. **G6** asserts AC-4 only. **Caveat (verified, non-blocking, unchanged from ITEST-2):** every `kReviewedPaints` entry is `measured` and `Paint.provenance` defaults to `measured`, so "provenance preserved" cannot be separated from a hardcoded-`measured` impl — no non-measured reviewed paint exists in v1 to build a control from. Non-blocking: the shipped impl preserves the exact object (no per-field reconstruction), value-equality is the strongest assertion the data supports, and the controller unit tests add a non-measured dataset paint (`estimated`) that *would* catch a hardcoded-`measured` bug at the unit level. If a non-measured reviewed paint is ever shipped, add a preserved-tier control to the AC-4 acceptance test. |

**Counts: 1×A (with caveat), 0×B — PASS.** No downgrade from ITEST-2; the
PALETTE-2 implementation preserves provenance exactly, and the caveat is the same
uniform-measured-dataset limit the ITEST-2 grid already recorded (no augmentation
owed — the remaining ITEST-2 augmentations TestAC02/TestAC05 belong to PALETTE-3 /
PALETTE-4).

---

## SCREEN-3 grade (AC-4, AC-11 — un-pended)

Independent, adversarial re-grade (fresh subagent, given the prior grid + G1–G6)
of the two currently un-pended AC tests — **AC-4** (owner PALETTE-2) and **AC-11**
(just delivered by SCREEN-3). Graded against what the code does now: for AC-4 the
real `addPaintFromDataset` + E32 `showModalBottomSheet` picker; for AC-11 the real
`VisionProfileCard` reading the injected `CvdProfile` and the `router.toSelfAssessment`
navigation to `SelfAssessmentEntryScreen`. SCREEN-3 also added a second-profile
control (protan/mild) to the AC-11 test. No other rows touched.

| Test | Grade | Justification |
|---|---|---|
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat) | Verified against the live PALETTE-2 impl. **G1** every Given checked through the public surface before the When: `myPaints` empty asserted; `whenAddPaint()` drives the real E32 control (`addPaintKey` → `_openDatasetPicker` → `showModalBottomSheet`, now wired); the picker precondition ("Ultramarine Blue" offered) asserted before the tap. **G2** the configured Given answers: the picker lists `controller.reviewedDataset` = shipped `kReviewedPaints` (no fake override), the tapped `ListTile` pops the exact `Paint`, and `addPaintFromDataset` appends it verbatim (`[...?current?.paints, paint]`, no field rewriting) and persists via `PersistentPaletteSource.savePalette`. **G3** n/a (no negative/"never" Then). **G4** at grain/value: full `Paint` value-equality to the exact dataset entry plus explicit `provenance` equality (`Paint.==` includes provenance). **G5** rejects a free-hand / blanked / fabricated / wrong-masstone / dropped-pigment-index paint, and a picker that offers nothing. **G6** asserts AC-4 only. **Caveat (unchanged, non-blocking):** every `kReviewedPaints` entry is `measured` and `Paint.provenance` defaults to `measured`, so "provenance preserved" cannot be separated from a hardcoded-`measured` impl — no non-measured reviewed paint exists in v1 to build a control from; value-equality is the strongest assertion the data supports. No downgrade from PALETTE-2's A-with-caveat; the caveat is a data limit, not a G-rule violation. |
| **AC-11** `the vision-profile card shows the estimate and opens the self-assessment` | A | **G1** every Given checked through the public surface before the When: the card region is present, `selfAssessmentOpen` is false to begin with, and the estimate Then ("deutan-type, moderate" scoped to `VisionProfileCard.regionKey`) is asserted *before* `whenRetakeAssessment` — the configured profile Given surfaced through the card. **G2** the configured Given answers: the estimate is rendered by the card from the injected `deutanModerate` (`'${profile.type.name}-type, ${_severityWord(profile.severity)}'`), not a script/fake overriding it; the second-profile control proves the text tracks the injected `CvdProfile`. **G3** negative Thens settled with controls: `selfAssessmentOpen` false→true across the `whenRetakeAssessment` settle point (before/after control), and the control app's `find.textContaining('deutan-type, moderate'), findsNothing` is asserted after a fresh `givenPalette(protan)` `pumpAndSettle`, paired with the positive `'protan-type, mild'` assertion that shows the reading can change. **G4** at grain/value: exact estimate strings (`'deutan-type, moderate'`, `'protan-type, mild'`) scoped to the card region; `selfAssessmentOpen` boolean at the navigation grain. **G5** rejects a blank card, a wrong estimate, a no-op retake, and — via the SCREEN-3 second-profile control — a card that hard-codes a constant estimate string (this closes the ITEST-2 grader's recommended second-profile hardening). **G6** asserts AC-11 only (estimate display + navigation; the second profile strengthens only AC-11). **No downgrade** — upgrade in strength over ITEST-2's A: the recommended-but-missing control is now present, so AC-11 is a clean A with no residual. |

**Counts: 2×A, 0×B — PASS (all A).** AC-4 holds at A (with the same unchanged,
non-blocking uniform-measured-dataset caveat — a data limit, not a G-rule
violation, so not a B). AC-11 is a clean A: SCREEN-3's second-profile control
(protan/mild) closes the only ITEST-2 hardening note (G5), proving the estimate
reads the injected `CvdProfile` rather than a hard-coded string. No B rows; no
augmentation owed by either test; no downgrade from the prior grid.
