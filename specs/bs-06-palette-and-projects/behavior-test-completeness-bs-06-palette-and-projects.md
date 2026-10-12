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

## Phase graded: PALETTE-3 (behavior — AC-2 + AC-3 un-pended)

Independent adversarial re-grade (fresh subagent, given the full prior grid +
G1–G6) of every currently-un-pended AC test — AC-2 (with its new TestAC02
augmentation), AC-3, and AC-4 (regression check). The grader ran nothing and
edited nothing.

| Test | Grade | Justification |
|---|---|---|
| **AC-2** `each paint lists its identity and provenance badge` | A (clears prior *B pending PALETTE-3*) | The TestAC02 augmentation closes both recorded gaps. (a) **Exact tier via the badge widget, not a substring:** `badgeOf('pw6').provenance.tier == ProvenanceTier.measured` reads `tester.widget<ProvenanceBadge>(find.byKey(PaintRow.badgeKeyFor('pw6')))`; the badge's provenance is `Provenance(paint.provenance)`, the paint's own configured value (G2). (b) **Medium at a non-subsumed grain:** `mediumOf('pw6').data == 'Oil'` reads the dedicated `Text` keyed `PaintRow.mediumKeyFor('pw6')`, a separate widget from the identity line "Artists' Oil" — killing the old `find.textContaining('Oil')` subsumption, so an impl that omits the medium now fails. (c) **Control paint differing in both tier and medium:** "Phthalo Green" (acrylic, estimated), seeded through the persistent save flow, renders its own `estimated`/`Acrylic` and the exact word "Estimated" on its badge — rejects an impl hardcoding Measured/Oil on every row (G5). G1: both paints pinned by name-list, id, medium and provenance before the When; the exact 2-element list rejects "no other X". G6: all assertions are AC-2's identity+badge. **Discriminates:** every new assertion fails against the pre-PALETTE-3 `Text(paint.name)` row (the keyed badge/medium widgets did not exist). |
| **AC-3** `the provenance legend explains the four confidence tiers` | A (unchanged) | Asserts all four tiers by their **exact** spec strings scoped to `ProvenanceLegendRegion.regionKey`, including the long forms 'Estimated — not yet verified' and 'Confirmed — you measured this', which `ProvenanceLegend.legendText` renders verbatim — rejecting a legend that uses the short `Provenance.label` or omits a tier. Static explanatory copy, so fixed-text assertion is correct (G4). Not regressed by the AC-2 edit (independent app build, static legend). |
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat, unchanged) | Independent test; full `Paint` value-equality to the exact dataset entry + explicit provenance equality. No shared state with AC-2's edit. Caveat is the long-standing uniform-measured-dataset limit (documented, non-blocking, not owed to PALETTE-3). |

**Counts: 3×A (AC-4 with caveat) — PASS (no unsanctioned B).** AC-2 cleared from
*B pending PALETTE-3* to A via the TestAC02 augmentation (exact rendered tier +
dedicated medium label + differently-tiered/different-medium control); AC-3 and
AC-4 not regressed. No augmentation remains owed by PALETTE-3.

---

## Phase graded: SCREEN-2 (behavior — AC-1 un-pended)

Independent adversarial re-grade by a fresh subagent (not the test author), given
the prior grid above and the G1–G6 rubric, grading what the code does now. Scope
is exactly the currently **un-pended** bs-06 AC acceptance tests: AC-1 (owner
SCREEN-2, just landed) and AC-4 (owner PALETTE-2, already green). SCREEN-2 made
`PaletteScreen` a `StatefulWidget` whose E31 selector Row toggles `_PaletteView`
between `myPaints` and `projects`, rendering the My-paints regions
(`PaintListRegion` + `ProvenanceLegendRegion` + `PaletteSelectorRegion`) or the
`ProjectsRegion` via a mutually-exclusive `if (showMyPaints) … else …`. I verified
every Given/When/Then of both tests against the real widget tree; the prior
ITEST-1/2/3 and PALETTE-2 sections are unchanged.

| Test | Grade | Justification |
|---|---|---|
| **AC-1** `switch between the My paints and Projects views` | A | **G1** Given checked through the public surface before the When — `PaintListRegion.regionKey` `findsOneWidget` after `givenPalette(twoPalettes)`, i.e. the screen is genuinely resting on My paints (the real default `_view == _PaletteView.myPaints`), not assumed. **G2** The When drives the real E31 control: `whenSwitchToProjects()` taps the `'Projects'` `TextButton` descendant of `viewSelectorKey`, now wired (`onPressed: () => _show(_PaletteView.projects)` → `setState`), so the view change comes from the real toggle state, not a fake/script. **G3** Negative Then settled: `PaintListRegion` `findsNothing` is asserted only after `whenSwitchToProjects()`'s `pumpAndSettle`, and is paired with a both-ways control (`whenSwitchToMyPaints()` restores `PaintListRegion` and hides `ProjectsRegion`), proving the reading changes in both directions, not one-way/stuck. **G4** Asserts the spec's "instead of" grain exactly — `ProjectsRegion.regionKey` present **and** `PaintListRegion.regionKey` `findsNothing` (the `if/else` renders one subtree, never both). **G5** Rejects a show-both toggle (the shell's old both-at-once layout — the real red-baseline failure), a non-toggling control, and a one-way/stuck toggle. **G6** Asserts AC-1 only. No downgrade from the prior grid's A. |
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat) | Re-confirmed green and **not** regressed by SCREEN-2's toggle. **G1** `myPaints` empty checked; `whenAddPaint()` taps the real E32 `addPaintKey`, which SCREEN-2 leaves mounted in the default My-paints view (the test never switches views, so `PaintListRegion`/`addPaintKey` stay in the tree) and which PALETTE-2 wired to `_openDatasetPicker`; the picker precondition (`'Ultramarine Blue'` offered) is asserted before the tap. **G2** The picker reads `controller.reviewedDataset` = shipped `kReviewedPaints`; `addPaintFromDataset` appends the exact tapped `Paint` (`[...?current?.paints, paint]`, no field rewriting) and persists via `PersistentPaletteSource.savePalette`. **G4/G5** full `Paint` value-equality to the exact dataset entry + explicit `provenance` equality — rejects a free-hand / blanked / fabricated / wrong-masstone / dropped-pigment-index paint. **G6** AC-4 only. **Caveat (verified, non-blocking, unchanged from ITEST-2 / PALETTE-2):** every `kReviewedPaints` entry is `measured` and `Paint.provenance` defaults to `measured`, so "provenance preserved" cannot be separated from a hardcoded-`measured` impl; no non-measured reviewed paint exists in v1 to build a control from, and value-equality is the strongest assertion the data supports. If a non-measured reviewed paint is ever shipped, add a preserved-tier control. No downgrade. |

**Counts: 2× A, 0× B pending — PASS (no unsanctioned B).** AC-1 is a clean A
driving the real E31 toggle at the "instead of" grain with a both-ways control;
AC-4 holds its A-with-caveat and is unaffected by the new toggle (it runs in the
default My-paints view where the add control stays mounted). No test downgraded
from its prior grade. No defect requires a fix in SCREEN-2: AC-1 has no gap, and
AC-4's only limit is the pre-existing inherited uniform-measured-dataset caveat
(not a sub-A, and not closable by any scheduled augmentation).

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

## Phase graded: PALETTE-4 (behavior — AC-5 un-pended)

Independent adversarial re-grade (fresh grader, given the full prior grid + G1–G6)
of every currently un-pended bs-06 AC — AC-1, AC-2, AC-3, AC-4, AC-5, AC-11 —
after PALETTE-4 mounted a shared `RecipeController` under a `RecipeReadEndpoint`
on `PaletteHomeScreen`, wired `PaletteController.onPaletteSelected →
RecipeController.selectPalette`, made the selector options real tappable
`InkWell`s, and added the TestAC05 augmentation to the AC-5 test. The grader ran
nothing and edited nothing; each Given/When/Then was verified against the
production code the test exercises.

| Test | Grade | Justification |
|---|---|---|
| **AC-5** `selecting a palette re-points recipe search at it` | A (clears prior *B pending PALETTE-4*) | TestAC05 now asserts the **spec's named observable**, not the old `selectedPalette` proxy: via the `RecipeReadEndpoint`, `recipeSelectedPalette` re-points `'My paints'`→`'Travel set'` **and** every component of every returned recipe is a Travel-set paint by id, with `recipes isNotEmpty` both before and after (closes the vacuous-empty hole). **G1** every Given checked through the public surface before the When — palette order `['My paints','Travel set']`, screen `selectedPalette=='My paints'`, recipe side `recipeSelectedPalette=='My paints'` (D-5 first-listed), `recipes` non-empty, and a pre-selection control loop proving every recipe component ⊆ My-paints ids. **G2** the configured Given answers: `whenSelectPalette('Travel set')` scrolls to and taps the real `InkWell` (`onTap → controller.selectPalette`), which fires `onPaletteSelected → RecipeController.selectPalette`, which emits `recipes: _solve(engine, target, Travel set)` — no script/fake. **G5 discriminates:** the fixtures are disjoint by id (`pw6/py42/pbr7/pbk9` vs `pb29/py35/pr108`, guarded), so an impl that moved only the screen pointer and left the solver on My paints yields My-paints components, failing `expect(travelIds, contains(component.paint.id))`; and against pre-PALETTE-4 code the `RecipeReadEndpoint.of` lookup throws (no endpoint mounted), so the Given-check on `recipeSelectedPalette` fails there — the augmentation genuinely requires PALETTE-4. **G6** asserts AC-5 only. **G4** exact active-palette name, exact Travel id-set, per-component membership for every returned recipe. Note (not a limit): `inverse()` only ever builds components from `palette.paints`, so ⊆ holds by construction once the solver re-points — the load-bearing discriminators are the `recipeSelectedPalette` re-point + the disjoint-set control; the ⊆ check still asserts the raw observable and guards a stale-recipes impl. No residual. |
| **AC-1** `switch between the My paints and Projects views` | A (unchanged) | Not regressed. PALETTE-4 touched the selector region and recipe wiring, not the E31 view toggle; the mutually-exclusive `if/else` and both-ways control are intact. The new `RecipeReadEndpoint` wrapper adds a layer but changes no region key. |
| **AC-2** `each paint lists its identity and provenance badge` | A (unchanged) | Not regressed. Paint-row rendering (badge/medium keyed widgets + differently-tiered control) is untouched by the selector/recipe wiring. |
| **AC-3** `the provenance legend explains the four confidence tiers` | A (unchanged) | Not regressed. Static legend copy, independent of PALETTE-4's changes. |
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat, unchanged) | Not regressed. `addPaintFromDataset` is untouched; the new `onPaletteSelected` param is optional (default null) and `_replaceMyPaints` keeps the active palette on My paints. Same long-standing, non-blocking uniform-measured-dataset caveat. |
| **AC-11** `the vision-profile card shows the estimate and opens the self-assessment` | A (unchanged) | Not regressed. Vision card + second-profile control are independent of the selector/recipe wiring. |

**Counts: 6×A (AC-4 with caveat) — PASS (no unsanctioned B).** AC-5 clears from
*B pending PALETTE-4* to a clean **A**: the TestAC05 augmentation asserts the
real named observable (`recipeSelectedPalette` re-point + every recipe's
components ⊆ selected palette) with a disjoint-set control that discriminates
both an ignore-selection impl and pre-PALETTE-4 code (where the
`RecipeReadEndpoint` lookup throws). **TestAC05 is now closed; no augmentation
remains owed by PALETTE-4.** No test downgraded; AC-1/2/3/4/11 verified
unaffected by the palette_controller / palette_selector_region / build_app /
harness changes.

---

## Phase graded: PROJECT-3 (behavior — AC-6 un-pended)

Fresh independent adversarial re-grade, given the full prior grid and the G1–G6
rubric, of every currently un-pended bs-06 AC — **AC-6** (just un-pended by
PROJECT-3, graded hardest), plus **AC-1, AC-2, AC-3, AC-4, AC-5, AC-11** for
regression (AC-7/8/9/10 remain pending and were not graded). PROJECT-3 is
uncommitted working-tree change and touches `lib/palette/projects_region.dart`,
`lib/projects/project_controller.dart`, the new `lib/projects/project_summary.dart`,
the AC-6 test and the pending gate; each Given/When/Then was verified against the
production code the test actually exercises. The grader **ran nothing and edited
nothing** but this grid. Prior sections above are unchanged.

| Test | Grade | Justification |
|---|---|---|
| **AC-6** `the projects list shows each project size, counts and last edit` | A (clears the prior ITEST-3 hardcoded-`today` residual) | **G1** both Givens checked through the read endpoint before the When: harbor (`name=='Harbor at Dusk'`, `size=='24×30 in'`, `samples==6`, `recipes==3`, `lastEdited` non-null, `inDays==0`) **and** the new control "Old Study" (`size=='9×12 in'`, `samples==2`, `recipes==1`, `inDays==3`). **G2** the configured Given answers: the last-edit label is derived by `ProjectSummary._lastEditedLabel` (calendar-day granularity → `Edited today` / `Edited yesterday` / `Edited N days ago`) off each project's own seeded `lastEdited` via `projectSummaries`, not a script. **G3** the negative Then is settled and controlled: `inRow('old-study', saysToday) → findsNothing` is asserted after `whenSwitchToProjects`'s `pumpAndSettle`, and is paired with the positive `inRow('harbor-at-dusk', saysToday) → findsWidgets`, proving the label genuinely varies between rows. **G4** at grain/value, scoped per-row via `ProjectsRegion.projectRowKey(id)` so no reading bleeds across projects: exact size strings, `6 samples`/`3 recipes` for harbor and `2 samples`/`1 recipe` for the control. **G5 — the control genuinely discriminates a hardcode (verified against production):** I confirmed `_lastEditedLabel` renders `Edited 3 days ago` for the 3-days-ago project, which does **not** contain "today"; a row that hardcoded `Text('Edited today')` (the exact ITEST-3 follow-on cheat) would make `inRow('old-study', saysToday)` find a widget and fail — so the cheat is killed. The 6≠3 and 2≠1 count asymmetries reject a sample/recipe count swap, and the per-row scoping rejects the shell's name-only row (the red-baseline failure). **G6** AC-6 only — no open/confusion/export (AC-7..10) behaviour asserted. **Residual (non-blocking, cosmetic, not owed an augmentation):** the control's recipe assertion uses `find.textContaining('1 recipe')`, which is a substring of `'1 recipes'`, so a mis-pluralised `'1 recipes'` would still pass — the production `_plural` is correct (`'1 recipe'`), and the *count value* 1 is still pinned and the swap still caught, so this is a cosmetic grain gap, not a G-rule failure. Clears the prior hardcoded-`today` residual that ITEST-3 recorded as the PROJECT-3 follow-on. |
| **AC-1** `switch between the My paints and Projects views` | A (unchanged) | Not regressed. PROJECT-3 changed only what `ProjectsRegion` renders *inside* its subtree (rows via `projectSummaries`); `ProjectsRegion.regionKey` and the E31 view toggle in `palette_screen` are untouched, so the mutually-exclusive `if/else` presence/absence assertions and the both-ways control still hold. |
| **AC-2** `each paint lists its identity and provenance badge` | A (unchanged) | Not regressed. `paint_list_region` / `paint_row` / `provenance_badge` and the keyed badge/medium widgets plus the differently-tiered control are entirely outside PROJECT-3's touched files. |
| **AC-3** `the provenance legend explains the four confidence tiers` | A (unchanged) | Not regressed. Static legend copy in `provenance_legend_region`, untouched by the projects-row changes. |
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat, unchanged) | Not regressed. `addPaintFromDataset` and the E32 picker are untouched by PROJECT-3. Same long-standing, non-blocking uniform-measured-dataset caveat (a data limit, not a G-rule violation). |
| **AC-5** `selecting a palette re-points recipe search at it` | A (unchanged) | Not regressed. The `RecipeController` / selector / `onPaletteSelected` wiring is in different files; PROJECT-3's `projectSummaries` getter is additive to `ProjectController` and does not touch the palette/recipe surface the TestAC05 augmentation exercises. |
| **AC-11** `the vision-profile card shows the estimate and opens the self-assessment` | A (unchanged) | Not regressed. `VisionProfileCard` and the second-profile control are independent of the projects region / project controller changes. |

**Counts: 7×A (AC-4 with caveat) — PASS (no unsanctioned B).** AC-6 un-pends to a
clean **A**: the PROJECT-3 older-second-project control (Old Study, edited 3 days
ago) asserts a derived relative last-edit label that genuinely discriminates a
hardcoded "today" (production renders `Edited 3 days ago`, verified), with per-row
scoping and distinct counts that reject a count swap and the shell's name-only row
— closing the hardcoded-`today` residual ITEST-3 handed forward. AC-1/2/3/4/5/11
verified unaffected by PROJECT-3's `projects_region` / `project_controller` /
`project_summary` changes. **No augmentation is owed** (the only new finding — the
`'1 recipe'` substring is subsumed by `'1 recipes'` — is a cosmetic pluralisation
grain gap, not a G-rule failure, and the count value and swap-rejection still
hold). No test downgraded from its prior grade.

---

## Phase graded: PROJECT-4 (behavior — AC-7 + AC-8 un-pended)

Fresh, independent, adversarial re-grade (I did not write these tests) of every
currently un-pended bs-06 AC — **AC-7** and **AC-8** (just un-pended by
PROJECT-4, graded hardest), plus **AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-11**
for regression. AC-9/AC-10 remain pending (`bs06/pending.dart`) and were not
graded. Method: read the authoritative spec, the AC tests + harness, and the
PROJECT-4 production code (`ProjectController.openProject`,
`ProjectsRegion._OpenProjectView`/`_SourcePhoto`, the tappable rows, the keyed
`openProjectViewKey`), and the `FakeFileSink`; verified every Given/When/Then
against the real widget tree and confirmed the AC-7 augmentation discriminates
against pre-PROJECT-4 code. I ran nothing and edited nothing but this grid.
Prior sections above are unchanged.

| Test | Grade | Justification |
|---|---|---|
| **AC-7** `opening a project shows its note and source photo` | A (clears prior *B pending PROJECT-4*) | The TestAC07 augmentation closes the ITEST-3 bare-`find.byType(Image)` limit. **G1** Givens checked through the read endpoint before the When: `project.note==harborNote`, `project.sourcePhotoRef==harborPhotoRef`, the photo round-trips (`photos.read(harborPhotoRef)==harborPhotoBytes`), and the `openedProject==null` before/after control. **G2** the configured Given answers: `openProject` sets `_openedProject` to the live working-list project, and `_SourcePhoto` renders `Image.memory` from `store.read(sourcePhotoRef)` — the project's own stored bytes, not a literal. **G4 at grain/value:** the note is scoped to `openProjectViewKey` (`find.descendant(of: openProjectViewKey, find.textContaining(harborNote))`), and the photo is (a) scoped to `openProjectViewKey` → `findsOneWidget`, (b) `isA<MemoryImage>()` (rejects an `Image.asset`/decorative asset image), (c) `(image as MemoryImage).bytes == harborPhotoBytes` — verified the `FakeFileSink.read` returns a value-equal `Uint8List.fromList` copy and the `equals` matcher compares element-wise, so the bytes assertion holds by value. **G5 discriminates:** scoping + MemoryImage-type + exact-bytes reject a decorative image, a wrong-bytes image, and an asset image; and against pre-PROJECT-4 code (no open-project view, `openProjectViewKey` absent, `openProject` inert) the scoped `findsOneWidget` and the `openedProject?.name` Then both fail — the augmentation genuinely requires PROJECT-4. **G6** AC-7 only (note + photo of the opened project). No residual. |
| **AC-8** `a note kept with a project is retained when it is reopened` | A (unchanged) | Not regressed by PROJECT-4. Still G4-tight — `openedProject?.note==harborNote` at the model grain **and** the verbatim rendered `find.textContaining(harborNote)`, with the `harborNote.isNotEmpty` guard closing the vacuous-`""` hole. `whenOpenProject` now taps the real per-project row (PROJECT-4 wired the per-project open, honouring the ITEST-1 docstring follow-on), so the When is a genuine open rather than an inert forward-drive. **G6 holds — distinct from AC-7:** AC-8 asserts only the retained note value (never the photo); AC-7 asserts note+photo. **Caveat (documented, unchanged):** "retained across reopen" is carried by `givenPalette`'s persistent seed→load round-trip, not an app-driven edit/close/reopen cycle — it tests "the exact persisted note is shown on open", still a distinct discriminating assertion → A. |
| **AC-6** `the projects list shows each project size, counts and last edit` | A (unchanged) | Not regressed by PROJECT-4, which added the open-project view and made rows tappable in `projects_region.dart`. AC-6 never opens a project, so `openedProject==null` and no `_OpenProjectView` is rendered; the summary rows still render name/size/counts/last-edit under `projectRowKey` (the key now sits on the wrapping `GestureDetector`, and the scoped `find.descendant` Thens still resolve the row's `Text` children). Per-row scoping, the 6≠3 / 2≠1 count asymmetries and the Old-Study `not-today` control all hold. |
| **AC-1** `switch between the My paints and Projects views` | A (unchanged) | Not regressed. PROJECT-4 changed only what `ProjectsRegion` renders *inside* its subtree (tappable rows + open-project view); `ProjectsRegion.regionKey` and the E31 view toggle are untouched, so the mutually-exclusive `if/else` presence/absence and both-ways control still hold. |
| **AC-2** `each paint lists its identity and provenance badge` | A (unchanged) | Not regressed. `paint_list_region` / `paint_row` / `provenance_badge` and the keyed badge/medium widgets + differently-tiered control are entirely outside PROJECT-4's touched files. |
| **AC-3** `the provenance legend explains the four confidence tiers` | A (unchanged) | Not regressed. Static legend copy, independent of the projects-region changes. |
| **AC-4** `add a paint by choosing from the shipped dataset` | A (with caveat, unchanged) | Not regressed. `addPaintFromDataset` and the E32 picker are untouched by PROJECT-4. Same long-standing, non-blocking uniform-measured-dataset caveat (a data limit, not a G-rule violation). |
| **AC-5** `selecting a palette re-points recipe search at it` | A (unchanged) | Not regressed. The recipe-controller / selector / `onPaletteSelected` wiring is in different files; PROJECT-4's `openProject` is additive and does not touch the palette/recipe surface the TestAC05 augmentation exercises. |
| **AC-11** `the vision-profile card shows the estimate and opens the self-assessment` | A (unchanged) | Not regressed. `VisionProfileCard` + second-profile control are independent of the projects region / project controller changes. |

**Counts: 9×A, 0×B pending — PASS (no unsanctioned B).** AC-7 clears from *B
pending PROJECT-4* to a clean **A**: the TestAC07 augmentation ties the shown
photo to the keyed open-project view and the project's own stored bytes
(`harborPhotoRef → harborPhotoBytes`, value-equal) and scopes the note to that
view too, rejecting a decorative / wrong-bytes / asset image and discriminating
against pre-PROJECT-4 code (no open-project view existed). AC-8 is unregressed
and remains G6-distinct from AC-7 (note value only, no photo). AC-1/2/3/4/5/6/11
verified unaffected by PROJECT-4's `projects_region` / `project_controller`
changes. **No augmentation remains owed by PROJECT-4** (TestAC07 is now closed).
No test downgraded from its prior grade.

---

## PROJECT-5 grade (AC-9 un-pended; full re-grade of all 10 un-pended ACs)

Fresh, independent, adversarial re-grade (I did not write these tests), given the
full prior grid and the G1–G6 rubric. **AC-9** (just un-pended by PROJECT-5,
graded hardest with its new non-flag control) plus **AC-1, AC-2, AC-3, AC-4,
AC-5, AC-6, AC-7, AC-8, AC-11** for regression. AC-10 is still pending
(`bs06/pending.dart` → `PROJECT-6`; the scaffold guard pins `pendingACs` to
exactly `{AC-10}`) and was **not** graded as a behaviour test. PROJECT-5 is a
working-tree change (HEAD = PROJECT-4 @ 921fc9b) touching `bs06/pending.dart`,
`palette_test.dart` (AC-9 augmentation), `build_app.dart` (wires
`deps.confusionCheck` + `deps.cvdProfile` into `ProjectController`),
`projects_region.dart` (renders the warning), `project_controller.dart`
(`confusionPairs` via the new `flagConfusionPairs`), the new
`lib/projects/confusion_pairs.dart`, and unit tests. I verified every
Given/When/Then against the production code the test exercises, confirmed the
detector under test is the shipped `DichromatConfusionCheck` (via
`AppDependencies.confusionCheck` → `ProjectController._confusionCheck`), and
**independently re-ran** a from-scratch CIEDE2000 + Viénot-1999 deutan projection
over all 15 harbor pairs. I ran nothing in-repo and edited nothing but this grid.

| AC | Test | Grade | Justification |
|---|---|---|---|
| AC-9 | `a confusable pair of saved samples is flagged within a project` | A (clears prior *B pending PROJECT-5*) | **G1** every Given checked through the public surface before the When: `harness.projects.single.samples` containsAll `{Mid Raw Umber, Ultramarine Shadow}` (read endpoint), and the pair is confirmed on the deutan confusion line via the harness's **independent** `referenceConfusable` — never the detector under test. **G2 exemplary:** the flag comes from the shipped `DichromatConfusionCheck` + injected `deutanDichromat` (`build_app` → `ProjectController(confusionCheck: deps.confusionCheck, cvdProfile: deps.cvdProfile)` → `confusionPairs` → `flagConfusionPairs(opened, _confusionCheck, _cvdProfile)`), not a script/override; the Given is graded against independent code, the behaviour against the shipped detector. A wrong profile injection would make the pair not collapse and fail the Then, so the configured profile genuinely answers. **G3** the negative Then (`Mid Raw Umber`/`Hull Red` NOT flagged) is settled after `whenOpenProject`'s `pumpAndSettle` and paired with the positive flag + `hasLength(1)` control, proving the list can and does change. **G4 at grain/value:** the raw observable `confusionPairs` is asserted by exact pair names (`anyElement(unorderedEquals(...))`), `hasLength(1)` (exactly one pair), and the rendered `check`-warning Text (only rendered when `confusionPairs.isNotEmpty`). **G5 discriminates — verified by independent math:** my own CIEDE2000+Viénot deutan projection gives Mid Raw Umber/Ultramarine Shadow normal ΔE00 22.02 / projected 0.77 (flags), Mid Raw Umber/Hull Red normal 11.96 / projected 5.95 (does not), and exactly one of 15 pairs flags — so a no-op impl fails `anyElement`+`hasLength(1)`, an over-flagging impl fails the Hull-Red non-flag control **and** `hasLength(1)` (15≠1), and a wrong-pair impl fails `anyElement`. Against pre-PROJECT-5 code (`confusionPairs` returned `const []`) every positive assertion fails, so the augmentation genuinely requires this phase. **G6** AC-9 only. The `check` warning uses a case-insensitive `'check'` substring Text predicate (not scoped to the open-project view) — the only `check` Text on the Projects view is the warning, and the pair-identity + `hasLength(1)` + non-flag control carry the discrimination, so this is a minor, non-blocking looseness, not a sub-A. Clean A. |
| AC-1 | `switch between the My paints and Projects views` | A | Not regressed. PROJECT-5 touched only the confusion surface (project controller/region/wiring); the E31 view toggle, `ProjectsRegion.regionKey` and the mutually-exclusive `if/else` + both-ways control are untouched. |
| AC-2 | `each paint lists its identity and provenance badge` | A | Not regressed. `paint_list_region`/`paint_row`/`provenance_badge` + keyed badge/medium widgets and the differently-tiered control are outside PROJECT-5's touched files. |
| AC-3 | `the provenance legend explains the four confidence tiers` | A | Not regressed. Static legend copy, independent of the projects-confusion changes. |
| AC-4 | `add a paint by choosing from the shipped dataset` | A (with caveat) | Not regressed. `addPaintFromDataset`/E32 picker untouched. Same long-standing, non-blocking uniform-measured-dataset caveat (a data limit, not a G-rule violation). |
| AC-5 | `selecting a palette re-points recipe search at it` | A | Not regressed. The recipe-controller/selector/`onPaletteSelected` wiring is in different files; PROJECT-5's `confusionPairs` getter and the new `cvdProfile`/`confusionCheck` ctor params are additive and do not touch the palette/recipe surface. |
| AC-6 | `the projects list shows each project size, counts and last edit` | A | Not regressed. AC-6 never opens a project, so `openedProject == null`, no `_OpenProjectView` (and no confusion warning) is rendered; summary rows under `projectRowKey` still render name/size/counts/derived last-edit with the Old-Study not-today control intact. |
| AC-7 | `opening a project shows its note and source photo` | A | Not regressed. Opened under the default `deutanModerate`, where the harbor pair's projected ΔE00 ≈ 9.7 > 3.0 does **not** collapse, so `confusionPairs` is empty and no `check` warning text appears to interfere with the note/scoped-photo assertions (`Image.memory` bytes tied to `harborPhotoBytes`). |
| AC-8 | `a note kept with a project is retained when it is reopened` | A | Not regressed. Same default moderate profile → no confusion warning; `openedProject?.note == harborNote` at model grain + verbatim rendered note, with the `isNotEmpty` vacuity guard, all hold. G6-distinct from AC-7. |
| AC-11 | `the vision-profile card shows the estimate and opens the self-assessment` | A | Not regressed. `VisionProfileCard` + the second-profile (protan/mild) control are independent of the projects/confusion changes. |

**Verdict: 10×A, 0×B — PASS (all A, no unsanctioned B).** AC-9 clears from *B
pending PROJECT-5* to a clean **A**: the TestAC09 augmentation adds a real
non-flag control (`Mid Raw Umber`/`Hull Red`, independently confirmed
non-confusable) and `hasLength(1)`, both rejecting an over-flagging impl that the
prior `anyElement`-only check could not; the detector under test is the shipped
`DichromatConfusionCheck` while the Given is confirmed against the independent
reference (G2); and an independent from-scratch CIEDE2000+Viénot re-run confirms
exactly one of 15 harbor pairs flags under full deutan. AC-10 remains pending
(PROJECT-6). AC-1/2/3/4/5/6/7/8/11 verified unaffected by the `build_app` /
`projects_region` / `project_controller` / pending-gate changes. **No
augmentation remains owed by PROJECT-5.**

---

## PROJECT-6 grade (AC-10 un-pended; full re-grade of all 11 un-pended ACs)

Fresh, independent, adversarial re-grade (I did not write these tests), given the
full prior grid and the G1–G6 rubric, judging what the code does now. **AC-10**
(just un-pended by PROJECT-6, graded hardest with its new sample/recipe content
assertion) plus **AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8, AC-9, AC-11**
as regression checks that PROJECT-6 did not weaken them. All 11 bs-06 ACs are now
delivered — `integration_test/bs06/pending.dart` → `pendingACs` is empty and the
scaffold guard pins it to exactly `{}`. PROJECT-6 touched `bs06/pending.dart`
(drained AC-10), `palette_test.dart` (AC-10 content augmentation), the new
`lib/projects/project_export.dart`, `project_controller.dart`
(`exportOpenedProject` + `PdfShareSink`/`lastExport`), `projects_region.dart`
(E34 wired), `build_app.dart` and `main.dart` (share-sink threading). I verified
every Given/When/Then against the production code the test exercises, confirmed
the `pdf`-package `/Info` keywords carry the sample names and recipe paint-lists
as contiguous ASCII literals, and independently confirmed each `harborRecipes`
recipe has a component paint unique to it. I ran nothing in-repo and edited
nothing but this grid.

| AC | Test | Grade | Justification |
|---|---|---|---|
| AC-10 | `the painter exports a project as a PDF studio sheet` | A (clears prior *B pending PROJECT-6*) | **G1** every Given checked through the public surface before the When: `harness.projects.single` pinned `name=='Harbor at Dusk'`, `samples` `hasLength(6)`, `recipes` `hasLength(3)` (read endpoint); the `lastExport==null` before-control; and — the spec's "has opened the project" Given — `whenOpenProject('Harbor at Dusk')` (real per-project row tap, PROJECT-4) then `openedProject?.name=='Harbor at Dusk'` asserted *before* the export. **G2** the configured Given answers: `whenExportProject()` taps the real E34 `exportKey`, which `projects_region` wires `onPressed: opened==null ? null : controller.exportOpenedProject()` — enabled only because a project is open — driving `ProjectController.exportOpenedProject` → `buildProjectStudioSheet(openedProject)` → `_lastExport`; no script/override, the produced bytes are the raw observable (`lastExport`, D-6, no disk file). **G3** n/a (no negative/"never" Then). **G4 at grain/value:** asserts the raw observable `lastExport` — `isNotNull`, `%PDF-` magic bytes (a real PDF, rejects null/empty/placeholder), and then **"every/each" at item grain**: a loop over `project.samples` asserting `document.contains(sample.name)` for all 6, and a loop over `project.recipes` asserting `document.contains(paints)` where `paints = components.map((c)=>c.paint.name).join(' + ')` for all 3. Expectations are re-derived from the fixture independently of the production `recipePaintList`/`sampleStudioLabel` builders. **G5 discriminates — verified:** against pre-PROJECT-6 code (export inert, `lastExport==null`) `expect(pdf, isNotNull)` fails; against a sheet omitting any sample, that sample's `contains` fails; against one omitting any recipe, that recipe's joined paint-list fails — and I confirmed each recipe carries a unique paint (R1 `Yellow Ochre + Ivory Black`, R2 `Titanium White + Raw Umber`, R3 `Ultramarine Blue + Ivory Black`; the three joined strings are distinct and none is a substring of another), so an omitted recipe is genuinely caught and the shared `Ivory Black` does not mask it. Production writes exactly `[...sampleLabels, ...recipePaints].join(' | ')` to the `/Info` `keywords` with `compress: false`, all ASCII, so the substrings are present contiguously in `String.fromCharCodes(pdf)`. **G6** asserts AC-10 only (the opened-project check is the When's precondition/Given, not a second AC). **Documented caveat (non-blocking, stays A):** the content assertion matches the sample/recipe strings in the `/Info` metadata rather than parsing the visible content stream (which the `pdf` package lays out word-by-word, so the literals are not contiguous there); production *also* renders every sample and recipe visibly on the page via `pw.Bullet`, so the sheet genuinely carries the content, and the metadata match is a sound, deliberately-documented proxy for "references each sample and each recipe." It does not distinguish a hypothetical metadata-present-but-blank-page impl — a theoretical wrong impl only, not a G-rule violation — so per the rubric this is a recorded caveat, not a downgrade. Clean A. |
| AC-1 | `switch between the My paints and Projects views` | A | Not regressed. PROJECT-6 touched only the export surface; the E31 view toggle, `ProjectsRegion.regionKey` and the mutually-exclusive `if/else` + both-ways control are untouched. |
| AC-2 | `each paint lists its identity and provenance badge` | A | Not regressed. `paint_list_region`/`paint_row`/`provenance_badge` + keyed badge/medium widgets and the differently-tiered control are outside PROJECT-6's touched files. |
| AC-3 | `the provenance legend explains the four confidence tiers` | A | Not regressed. Static legend copy, independent of the export changes. |
| AC-4 | `add a paint by choosing from the shipped dataset` | A (with caveat) | Not regressed. `addPaintFromDataset`/E32 picker untouched. Same long-standing, non-blocking uniform-measured-dataset caveat (a data limit, not a G-rule violation). |
| AC-5 | `selecting a palette re-points recipe search at it` | A | Not regressed. The recipe-controller/selector/`onPaletteSelected` wiring is in different files; PROJECT-6's `exportOpenedProject`/`lastExport`/`PdfShareSink` additions do not touch the palette/recipe surface the TestAC05 augmentation exercises. |
| AC-6 | `the projects list shows each project size, counts and last edit` | A | Not regressed. The E34 button is enabled only when a project is open; AC-6 never opens a project, so the summary rows under `projectRowKey` still render name/size/counts/derived last-edit with the Old-Study not-today control intact. |
| AC-7 | `opening a project shows its note and source photo` | A | Not regressed. `openProject`/`_OpenProjectView`/`_SourcePhoto` are unchanged; the new export control sits in the same `Row` but is independent of the note + scoped-photo (`MemoryImage` bytes tied to `harborPhotoBytes`) assertions. |
| AC-8 | `a note kept with a project is retained when it is reopened` | A | Not regressed. `openedProject?.note==harborNote` at model grain + verbatim rendered note, with the `isNotEmpty` vacuity guard, all hold; G6-distinct from AC-7. |
| AC-9 | `a confusable pair of saved samples is flagged within a project` | A | Not regressed. `confusionPairs`/`flagConfusionPairs` and the shipped `DichromatConfusionCheck` + injected `deutanDichromat` are untouched by PROJECT-6; the TestAC09 non-flag control + `hasLength(1)` still discriminate. The export path does not read or alter the confusion surface. |
| AC-11 | `the vision-profile card shows the estimate and opens the self-assessment` | A | Not regressed. `VisionProfileCard` + the second-profile (protan/mild) control are independent of the export changes. |

**Verdict: 11×A, 0×B — PASS (all A, no unsanctioned B).** AC-10 clears from *B
pending PROJECT-6* to a clean **A**: the PROJECT-6 augmentation adds a
real-content assertion over the produced PDF bytes — every saved sample by name
and every saved recipe by its " + "-joined component paint-list — that
discriminates against pre-PROJECT-6 code (`lastExport==null`) and against a sheet
omitting any sample or any recipe (each recipe carries a paint unique to it,
independently confirmed), driving the real E34 export control enabled by the
opened project (G1/G2/G4/G5/G6 all met). The only noted limit — the content is
matched in the `/Info` metadata rather than the visible content stream — is a
deliberately documented, non-blocking caveat (production also renders the content
visibly), not a G-rule violation, so it stays A. AC-1/2/3/4/5/6/7/8/9/11 verified
unaffected by the `project_export` / `project_controller` / `projects_region` /
`build_app` / `main` / pending-gate changes. All 11 bs-06 ACs are delivered and
the pending map is empty. **No augmentation remains owed by PROJECT-6.**

---

## SIGNOFF-1 — fresh full-suite re-grade (independent, adversarial)

A new independent, adversarial grader (I did **not** write these tests) re-graded
the **whole** bs-06 acceptance suite as the SIGNOFF-1 gate: all 11 AC
`acTestWidgets`, the 2 never-pending smoke tests, the 7 fixture guards, the 3
pending-gate scaffold guards, and the 3 harness artifacts (the Given/When/Then
vocabulary, the fixtures + independent confusion reference, the `FakeFileSink`).
I read the code **statically** against G1–G6 and the guard bar; I did **not** run
the integration suite on the simulator (a verification run holds the device lock)
— I traced every Given/When/Then to the production widget tree and controllers it
exercises and confirmed each discriminator against the shipped code. All 11 ACs
are confirmed **un-pended** (`integration_test/bs06/pending.dart` → `pendingACs`
is `{}`) and **built** (each driven by real production code, verified below). I
independently re-derived nothing numerically this pass but confirmed the AC-9
coefficients and thresholds (`DichromatConfusionCheck`: normal ΔE00 ≥ 10 and
projected ΔE00 < 3.0) match the prior independent re-runs the grid records. I
edited nothing but this section.

| Test / Artifact | Grade | Justification |
|---|---|---|
| **AC-1** `switch between the My paints and Projects views` (un-pended, built — SCREEN-2) | A | **G1** `PaintListRegion.regionKey` `findsOneWidget` after `givenPalette(twoPalettes)` (resting on My paints, the real default `_view`). **G2** `whenSwitchToProjects` taps the real `'Projects'` `TextButton` in `viewSelectorKey`, wired `onPressed: ()=>_show(_PaletteView.projects)→setState`. **G3/G4** the negative `PaintListRegion findsNothing` is asserted after the switch's `pumpAndSettle` and paired with a both-ways control (`whenSwitchToMyPaints` restores it, hides Projects) — the `if(showMyPaints)…else…` renders exactly one subtree. **G5** rejects the shell's both-at-once layout, a one-way/stuck toggle and a non-toggling control. **G6** AC-1 only. |
| **AC-2** `each paint lists its identity and provenance badge` (un-pended, built — PALETTE-3) | A | **G1** both paints pinned by name-list, id, brand, line, medium and tier via `myPaints` before the When. **G2** the configured paints answer: `ProvenanceBadge` renders `Provenance(paint.provenance)` and the medium is a dedicated `Text` keyed `PaintRow.mediumKeyFor(id)` (verified a separate widget from the identity line `"Artists' Oil"` in `paint_row.dart`). **G4 non-subsumed:** `badgeOf('pw6').provenance.tier == measured` and `mediumOf('pw6').data == 'Oil'` read the keyed widgets, killing the old substring subsumption. **G5** the `ctrl-estimated`/`Phthalo Green`/acrylic/estimated control renders its own `Estimated`/`Acrylic` — rejects an impl hardcoding Measured/Oil per row. **G6** AC-2 only. |
| **AC-3** `the provenance legend explains the four confidence tiers` (un-pended, built — PALETTE-3) | A | **G1** legend region present. **G4** asserts all four tiers by exact spec strings scoped to `ProvenanceLegendRegion.regionKey`, incl. the long forms `'Estimated — not yet verified'` / `'Confirmed — you measured this'` — confirmed `ProvenanceLegend.legendText` renders these verbatim (distinct from the short `Provenance.label` the badge uses). Static explanatory copy, so fixed-text assertion is correct. **G5** rejects a legend missing/renaming any tier or using the short labels. **G6** AC-3 only. |
| **AC-4** `add a paint by choosing from the shipped dataset` (un-pended, built — PALETTE-2) | A (with caveat) | **G1** `myPaints` empty; `whenAddPaint` drives the real E32 `addPaintKey`→`_openDatasetPicker`→`showModalBottomSheet`; picker offers `'Ultramarine Blue'` asserted before the tap. **G2** the picker lists `controller.reviewedDataset == kReviewedPaints` (no fake), the tapped `ListTile` pops the exact `Paint`, `addPaintFromDataset` appends it verbatim (`[...?current?.paints, paint]`) and persists via `PersistentPaletteSource.savePalette`. **G4** full `Paint` value-equality + explicit `provenance` equality (`Paint.==` includes provenance). **G5** rejects free-hand/blanked/fabricated/wrong-masstone/dropped-pigment-index. **Caveat (confirmed, non-blocking):** I verified `kReviewedPaints` is uniformly `ProvenanceTier.measured` (all 8 entries) and `Paint.provenance` defaults to `measured`, so "provenance preserved" cannot be separated from a hardcoded-`measured` impl — no non-measured reviewed paint exists to build a control from; value-equality is the strongest assertion the data supports. A data limit, not a G-rule violation. **G6** AC-4 only. |
| **AC-5** `selecting a palette re-points recipe search at it` (un-pended, built — PALETTE-4) | A | **G1** palette order `['My paints','Travel set']`, `selectedPalette=='My paints'`, `recipeSelectedPalette=='My paints'` (D-5 first-listed), `recipes isNotEmpty`, and a pre-selection control loop (every recipe component ⊆ My-paints ids). **G2** `whenSelectPalette('Travel set')` taps the real `InkWell` (`onTap→controller.selectPalette`)→`onPaletteSelected→RecipeController.selectPalette`→`_solve(engine,target,Travel set)`; wiring confirmed in `build_app._PaletteHomeScreenState` (shared `RecipeController` under `RecipeReadEndpoint`, `onPaletteSelected: _recipeController.selectPalette`). **G4/G5** `recipeSelectedPalette` re-points to Travel set, every returned recipe's components ⊆ the disjoint Travel id-set (guarded disjoint by id), `recipes isNotEmpty` both sides — rejects a screen-pointer-only impl and, against pre-PALETTE-4 code, the `RecipeReadEndpoint` lookup throws. Note: `inverse()` builds components only from `palette.paints`, so ⊆ holds by construction — the load-bearing discriminators are the re-point + disjoint sets. **G6** AC-5 only. |
| **AC-6** `the projects list shows each project size, counts and last edit` (un-pended, built — PROJECT-3) | A | **G1** both projects (harbor: 24×30 in / 6 / 3 / `inDays==0`; control Old Study: 9×12 in / 2 / 1 / `inDays==3`) checked through the read endpoint. **G2** labels derived by `ProjectSummary._lastEditedLabel` (calendar-day: `Edited today`/`…days ago`) off each project's own `lastEdited`. **G3/G5** `inRow('old-study', saysToday) findsNothing` after the settle, paired with `inRow('harbor-at-dusk', saysToday) findsWidgets` — confirmed production renders `Edited 3 days ago` for the control, killing a hardcoded-`today`. Per-row scoping via `projectRowKey(id)`; 6≠3 and 2≠1 reject a count swap. **Residual (cosmetic, non-blocking):** the control's `find.textContaining('1 recipe')` is subsumed by `'1 recipes'`, but production `_plural` is correct and the count value + swap are still pinned — not a G-rule failure. **G6** AC-6 only. |
| **AC-7** `opening a project shows its note and source photo` (un-pended, built — PROJECT-4) | A | **G1** `project.note==harborNote`, `sourcePhotoRef==harborPhotoRef`, photo round-trips, `openedProject==null` before-control. **G2** `openProject` sets the live working-list project; `_SourcePhoto` renders `Image.memory` from `store.read(sourcePhotoRef)`. **G4** note scoped to `openProjectViewKey`; photo scoped to that view → `findsOneWidget`, `isA<MemoryImage>()`, `(image as MemoryImage).bytes == harborPhotoBytes`. **G5** scope + MemoryImage-type + exact-bytes reject a decorative/asset/wrong-bytes image, and discriminate against pre-PROJECT-4 code (no open view). **G6** AC-7 only (note+photo). |
| **AC-8** `a note kept with a project is retained when it is reopened` (un-pended, built — PROJECT-4) | A | **G4** `openedProject?.note==harborNote` at model grain **and** verbatim rendered note, with `harborNote.isNotEmpty` closing the vacuous-`""` hole. `whenOpenProject` taps the real per-project row (`openProject(summary.id)`). **G6 distinct from AC-7:** asserts only the note value, never the photo. **Caveat (documented, non-blocking):** "retention across reopen" is carried by the persistent seed→load round-trip, not an in-app edit/close/reopen cycle — it asserts "the exact persisted note is shown on open", still a distinct discriminating assertion. |
| **AC-9** `a confusable pair of saved samples is flagged within a project` (un-pended, built — PROJECT-5) | A | **G1** Given pair confirmed via the harness's **independent** `referenceConfusable` (bs-03 reference ΔE00 + projection), never the detector under test. **G2** the flag comes from the shipped `DichromatConfusionCheck` + injected `deutanDichromat` (`build_app`→`ProjectController(confusionCheck, cvdProfile)`→`confusionPairs`→`flagConfusionPairs`), confirmed in `confusion_pairs.dart` (pairwise over `project.samples`, keeps `check.confusable`). **G3/G5** the `Mid Raw Umber`/`Hull Red` non-flag control (`referenceConfusable isFalse`) plus `hasLength(1)` reject an over-flagging impl that `anyElement` alone could not; the exact-pair `anyElement(unorderedEquals(...))` rejects wrong/no-op impls. **G4** raw `confusionPairs` asserted by pair-names + `hasLength(1)` + the rendered `check` warning (only rendered when `confusionPairs.isNotEmpty`). **Minor (non-blocking):** the `'check'` Text predicate is unscoped, but it is the only `check` Text on the Projects view and identity+`hasLength(1)`+control carry the discrimination. **G6** AC-9 only. |
| **AC-10** `the painter exports a project as a PDF studio sheet` (un-pended, built — PROJECT-6) | A (with caveat) | **G1** name/6-samples/3-recipes + `lastExport==null` before-control + the spec's "has opened the project" Given (`whenOpenProject` then `openedProject?.name` asserted before export). **G2** `whenExportProject` taps the real E34 `exportKey` (`onPressed: opened==null?null:()=>controller.exportOpenedProject()`, enabled only because open)→`buildProjectStudioSheet`→`_lastExport`; no share-sink in tests, so the produced bytes are the raw observable (D-6). **G4** `lastExport isNotNull` + `%PDF-` magic + **item-grain loops**: every sample by name and every recipe by its `' + '`-joined component paint-list are `contains`-asserted on the produced bytes (expectations re-derived from the fixture, not the production label builder). **G5** rejects pre-PROJECT-6 code (`lastExport==null`) and a sheet omitting any sample/recipe (confirmed each recipe carries a unique paint, so the shared `Ivory Black` does not mask an omission). **Caveat (documented, non-blocking):** the content is matched in the `/Info` `keywords` metadata rather than the laid-out content stream; production *also* renders every sample/recipe visibly via `pw.Bullet`, so the metadata match is a sound, deliberately-documented proxy — a theoretical metadata-present-but-blank-page impl is not distinguished, which is not a G-rule violation. **G6** AC-10 only. |
| **AC-11** `the vision-profile card shows the estimate and opens the self-assessment` (un-pended, built — SCREEN-3) | A | **G1** card present, `selfAssessmentOpen` false, estimate asserted before the When. **G2** the estimate is rendered by `VisionProfileCard` from the injected `deutanModerate` (`'${profile.type.name}-type, ${_severityWord(profile.severity)}'`), not a fixed string. **G3** `selfAssessmentOpen` false→true across `whenRetakeAssessment`; and the second-profile control (protan/0.2→`'protan-type, mild'`, `'deutan-type, moderate' findsNothing`) after a fresh `givenPalette` settle proves the estimate tracks the injected profile. **G4** exact estimate strings scoped to `regionKey`; boolean nav grain. **G5** rejects a blank card, wrong estimate, no-op retake, and a card hardcoding the default estimate. **G6** AC-11 only. |
| **Smoke:** `the assembled app boots to the Palette screen showing every region` | A | Boots the real `buildApp` to the `Palette` AppBar, both read endpoints mount; the four My-paints resting regions resolve and `ProjectsRegion.regionKey findsNothing` initially, then `whenSwitchToProjects` resolves it (both views' shells wire through the real toggle, confirmed in `palette_screen.dart`). Pins the resting state through the endpoints (all empty/null/false, no speech, 0 haptics). Deterministic (`pumpAndSettle`). Non-vacuous — each assertion fails a mis-wired shell. |
| **Smoke:** `seeded sources are read back through the endpoints` | A | Seeds `twoPalettes`+`harborProject`+a photo through the production persistent sources and asserts round-trip: palette order, `selectedPalette=='My paints'`, `myPaints` containsAll, projects `['Harbor at Dusk']`, photo round-trips via the sink **and** `photos.writes==0` (seeding is not a recorded save). Deterministic; fails a dropped/reordered source or unwired endpoint. |
| **Fixture guard:** `reviewedDataset carries the AC-2 and AC-4 paints` | A | `firstWhere` throws if "Titanium White" absent, then pins brand/line/`PW6`/`PaintMedium.oil`/`provenance==measured` (type-correct against shipped `kReviewedPaints`, verified), and asserts "Ultramarine Blue" present for AC-4. Non-vacuous. |
| **Fixture guard:** `twoPalettes are named "My paints"/"Travel set" and disjoint` | A | Pins names/order, asserts each palette non-empty (so disjointness can't pass on empty sets), and id-set intersection empty (verified disjoint: `pw6/py42/pbr7/pbk9` vs `pb29/py35/pr108`). Vacuous-empty hole closed. |
| **Fixture guard:** `harborProject has the counts, note and photo AC-6..AC-10 assume` | A | Pins name, `24×30 in`, `samples.length==6`, `recipes.length==3`, note, `sourcePhotoRef`, `lastEdited != null`, and `samples.length==recipes.length` `isFalse` (catches a count swap). Matches AC-6/7/8/10 needs. |
| **Fixture guard:** `exactly one harbor sample pair is confusable for a deutan (AC-9)` | A | Loops all 15 pairs of the const 6-sample list (cannot be empty), cross-checks shipped `DichromatConfusionCheck` vs independent `referenceConfusable` on **every** pair, then pins the flagged set to exactly `{'Mid Raw Umber/Ultramarine Shadow'}` — count **and** identity. Non-vacuous; consistent with the independent ΔE00 re-runs the grid records (projected ≈ 0.77 flags, all others clear). |
| **Fixture guard:** `the confusion pair is a deutan collapse, not a plain near-match` | A | Independent normal ΔE00 `> 10`; flagged under `deutanDichromat` (`isTrue`) but not under `deutanModerate` (`isFalse` — the shipped fixed 3.0 projected threshold fires only near full dichromacy, justifying AC-9's full-dichromat injection); real non-flag control `Mid Raw Umber`/`Hull Red` `isFalse`. Genuine control. |
| **Fixture guard:** `the vision-profile fixtures are the deutan profiles their ACs name` | A | Pins `deutanModerate`=deutan/0.6 (AC-11 "moderate") and `deutanDichromat`=deutan/1.0 (AC-9). Matches the spec severity words and the detector's threshold behaviour. |
| **Fixture guard:** `FakeFileSink records saves and round-trips; seed does not count` | A | `writes==0` after construction and after `seed`, round-trips seeded bytes, then a real `save` bumps `writes` to 1, records the ref, round-trips. Distinguishes seed from save exactly as the smoke test relies on. Deterministic. |
| **Pending-gate guard:** `pending map is exactly the still-pending ACs (shrinks as they land)` | A | Pins `pendingACs.keys.toSet()` to exactly `{}` (all 11 delivered) — a missing-drain, re-added or typo'd AC fails. Asserts the exact set identity (non-vacuous even at empty), and I confirmed `bs06/pending.dart` seeds `pendingACs = {}`. |
| **Pending-gate guard:** `every pending AC is owned by a real behaviour phase` | A (documented note) | Loops `pendingACs.entries` asserting each owner ∈ the non-empty `behaviorPhases` (verified it lists the 9 real bs-06 phases, PROJECT-2 enabler correctly excluded). **Note (non-blocking):** with `pendingACs` now drained to `{}` this loop runs zero iterations, so *considered in isolation* it is a dormant/vacuous loop; it is **not** a hidden gap because the sibling guard above pins `pendingACs == {}` (the required size/identity assertion) and the third guard asserts all 11 run — so the pending-gate group as a whole satisfies the vacuous-pass bar, and emptiness is the correct terminal state, not a masked behaviour. Cheap hardening: add `expect(pendingACs, isEmpty)` (or fold the owner check into guard 1) so the test stands alone. Graded A on the group's collective coverage, with the note recorded so it is not rubber-stamped. |
| **Pending-gate guard:** `pendingSkipReason runs every un-pended AC in both modes` | A | Fixed-count loop `i=1..11` (non-vacuous) asserts every `AC-i` has `pendingSkipReason == null` in both default and `forceRunPending: true` modes (all delivered → none skipped), plus an absent `AC-999` always runs. `forceRunPending` keeps it deterministic without touching the environment; confirmed the `pendingSkipReason` branch logic in `bs06/pending.dart`. |
| **Artifact:** Given/When/Then vocabulary (`PaletteHarness`, `when…`, `givenPalette`) | A | Every `when…` drives a real control now wired by its phase (`viewSelectorKey`, `addPaintKey`, `InkWell` selector option, per-project row open, `exportKey`, `retakeKey`), confirmed against the production widgets. Read seams (`paletteController`/`projectController`/`recipeController` via the three endpoints; `palettes`/`selectedPalette`/`myPaints`/`projects`/`openedProject`/`confusionPairs`/`lastExport`/`recipeSelectedPalette`/`recipes`/`selfAssessmentOpen`) are all real getters. `whenOpenProject(name)` now taps the named per-project row (ITEST-1's `name`-ignored follow-on closed by PROJECT-4). `givenPalette` rebuilds a fresh app each call via the production `buildApp`+persistent sources and uses `pumpAndSettle` throughout — deterministic. |
| **Artifact:** Fixtures + independent confusion reference (`referenceConfusable`, reused bs-03 `referenceDeltaE00`/`referenceDeutanProjectedDeltaE00`) | A | Fixtures are stable constants named to the plan catalogue. `referenceConfusable` re-implements the D-5 predicate over the bs-03 reference ΔE00 (independent CIEDE2000), so the shipped detector's threshold/direction/metric are cross-checked against code it does not call. **Documented caveat (inherited, non-blocking):** the reference *projection* shares the shipped Viénot coefficients, so a transcription error in those matrices would not be caught by the cross-check — the ΔE00 metric and predicate logic remain independently checked, and this is the long-standing bs-03-inherited caveat the grid already records, not a new defect. |
| **Artifact:** `FakeFileSink` recording `SourcePhotoStore` | A | Faithful recording fake: copies bytes in/out, `seed` pre-stores without counting, `save` records refs in order, `writes`/`saved`/`read`/`exists`/`delete` are honest seams. AC-10 PDF export is not routed here (read off `ProjectController.lastExport`), and the doc-comment matches — no overstatement. |

**Verdict:** 26×A, 0 below A — PASS (all A). All 11 AC tests are un-pended and
built, each driven by real production code verified statically, each satisfying
G1–G6 and rejecting a named wrong implementation; the smoke tests, 7 fixture
guards, 3 pending-gate guards and 3 harness artifacts are non-vacuous,
comment-accurate and deterministic. Standing documented, non-blocking caveats
(not G-rule violations, no augmentation owed): AC-4's uniform-`measured` dataset
limit; the AC-9/harness reference projection sharing the shipped Viénot
coefficients; AC-10's `/Info`-metadata content proxy; AC-6's `'1 recipe'`
substring. One recorded guard note: `every pending AC is owned by a real
behaviour phase` is now a dormant/vacuous loop because `pendingACs` is drained to
`{}`, but its sibling guard pins the exact empty identity and the third guard
asserts all 11 run, so the pending-gate group collectively meets the vacuous-pass
bar (cheap hardening suggested: `expect(pendingACs, isEmpty)` inside that test).
Nothing is below A; the suite passes the SIGNOFF-1 full-suite re-grade.
