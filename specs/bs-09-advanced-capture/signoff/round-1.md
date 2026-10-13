# Sign-off packet — Advanced capture (bs-09) — Round 1

**Feature:** bs-09-advanced-capture · **Spec:** [bs-09-advanced-capture.feature](../../bs-09-advanced-capture.feature)
**Prepared:** 2026-10-12 (SIGNOFF-1) · **At code:** `feat/bs-09` @ `eb5c8aa` (SOURCE-4; sign-off commit stamped on decision)
**Decision:** ⏸ **Awaiting** — a human records Approved / Changes requested (the agent never approves).

All 10 acceptance criteria are coded, un-pended and green by default (nothing pending); the full
cross-feature regression (bs-01/02/03/04/05/06 + bs-09) is green; a fresh independent full-suite grade grid is
**24×A, 0 below A**. This packet is the evidence for the decision.

To record the decision:
`/feature-next-phase --signoff bs-09-advanced-capture approved | changes "<items>"`

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 16/16 build phases ✅ Done (CAPTURE/SOURCE/SCREEN/ITEST modules all done) |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-10 all ✅ |
| Pending list empty | ✅ `integration_test/bs09/pending.dart` `pendingACs = {}` (every row deleted; `unpended` set = {AC-1…AC-10}) |
| No open row in ITEST *Test augmentations* | ✅ none — the plan pre-seeded no augmentations; each AC test carries its own in-fixture control (AC-6↔AC-8 wide/narrow, AC-7 RAW/processed, AC-2 torch/ambient, AC-10 two differing platform raws) |
| Fresh whole-suite grade grid all A | ✅ 24×A / 0 below A (fresh-context grader, this session) |
| No open decision/dependency gates | ✅ G-1 (spec) + G-2 (test review) both ✅ Resolved; no dependency gate (bs-02/bs-03 already on `main`) |

---

## 2. Full verification (worktree `Nuance-bs09` on `feat/bs-09` @ `eb5c8aa`, this session)

Toolchain: Flutter (project-local, `~/development/flutter`); iOS sim iPhone 17 `5AB9D06D…51685`; the three
integration runs executed under the shared device lane via `coord.sh with-lock`. Machine-readable results
produced on the first run (`flutter test --machine`); the summary page (§8) is built from them.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | **No issues found!** (clean, 5.7s) |
| Unit + coverage | `flutter test --coverage` | **918 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart main` | **PASS** — 100% line coverage on all **13** touched bs-09 `lib/` files (first run; no flake) |
| Acceptance — all features (default) | `flutter test integration_test/ -d <udid> --machine` | **152 passed, 0 failed, 0 skipped** (bs-01…bs-06 + bs-09; `done.success=true`) |
| Acceptance — bs-09 (default) | `flutter test integration_test/advanced_capture_test.dart -d <udid> --machine` | **21 passed, 0 failed, 0 pending** |
| Acceptance — bs-09 (run-pending) | `… --dart-define=BS09_RUN_PENDING=true --machine` | **21 passed, 0 failed, 0 skipped** — identical to default (the pending map is empty) |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **24×A, 0 below A — PASS** (10 AC tests + 3 pending-gate/scaffold guards + 7 fixture guards + 1 smoke + 3 harness/fixture/gate artifacts) |

The 13 touched `lib/` files at 100%: `app/{build_app,router}.dart`,
`capture/{capture_controller,capture_controls,capture_live_view,capture_readings_list,capture_screen,
capture_state}.dart`, `capture/source/{capture_source,sampling,software_capture_source}.dart`,
`domain/sample.dart`, `widgets/color_chip.dart`.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green; each AC test carries a discriminating in-fixture control,
and AC-9/AC-10 have a genuine red baseline (CIE76 ~4.09 / 7.42 before SOURCE-4's normalization branch).

| AC | Scenario | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | Turning on the torch warns that its colour temperature biases the reading | `TestAC01_TorchWarnsColourTemp` | SCREEN-2 | ✅ green |
| AC-2 | A reading taken under the torch is labelled as lit by the torch | `TestAC02_ReadingLabelledTorchLit` | CAPTURE-3 | ✅ green |
| AC-3 | The painter samples several points together and gets all of them at once | `TestAC03_MultiPointSamplesAllAtOnce` | CAPTURE-4 | ✅ green |
| AC-4 | Each multi-point reading keeps its own position and value | `TestAC04_EachPointKeepsPositionValue` | SCREEN-3 | ✅ green |
| AC-5 | Any two sampled points can be sent to a comparison | `TestAC05_TwoPointsToComparison` | CAPTURE-5 | ✅ green |
| AC-6 | A capture is tagged with the colour space it was taken in | `TestAC06_TaggedWithColourSpace` | SOURCE-2 | ✅ green |
| AC-7 | RAW capture is used where the device supports it | `TestAC07_RawWhereSupported` | SOURCE-3 | ✅ green |
| AC-8 | A device without wide-gamut capture falls back and labels the narrower space | `TestAC08_FallbackLabelsNarrower` | SOURCE-2 | ✅ green |
| AC-9 | The capture interface returns a normalized, colour-space-tagged sample | `TestAC09_NormalizedTaggedSample` | SOURCE-4 | ✅ green |
| AC-10 | The rest of the app never sees the platform capture difference | `TestAC10_PlatformAgnosticSample` | SOURCE-4 | ✅ green |

**Grade grid:** `../behavior-test-completeness-bs-09-advanced-capture.md` — fresh SIGNOFF-1 full-suite
re-grade appended: **24×A, 0 below A — PASS**. The grader traced every Given/When/Then to the real
production widgets/controllers (`commit()` normalise branch, `turnTorchOn`/`torchWarning` banner,
`sampleMarkedPoints`, `sendPairToComparison`→`ComparisonController`, `colorSpace`/`captureMode` getters) and
confirmed each AC rejects a named wrong implementation, with nothing passing vacuously.

---

## 4. Augmentations made

**None.** The plan pre-seeded no augmentation rows: the ten ACs separate cleanly onto distinct phases, and
each AC test carries its discriminating control in-fixture —
- **AC-6 ↔ AC-8** — `SCENE_WIDE` (wide-gamut) vs `SCENE_NARROW` (sRGB fallback), each the other's control via an in-test reboot.
- **AC-7** — RAW-capable `SCENE_RAW` vs a non-RAW reboot asserting `captureMode == processed`.
- **AC-2** — a torch-off commit (`litByTorch == false`) precedes the torch-on commit, defeating a stamp-every-sample impl.
- **AC-9 / AC-10** — `SCENE_ANDROID` (+10) and `SCENE_IOS` (−8) carry *different* non-zero pre-normalization raw offsets, so "normalized to canonical" and "same across platforms" are real numeric checks, not label text.

---

## 5. Non-A grades accepted

**None.** No AC test or guard is below A (24×A); nothing was closed by user acceptance of a gap.

Two standing caveats the fresh grader recorded as **A-with-caveat** (correct grain, with a stronger
discriminator behind each — not sub-A grades, and no augmentation owed):
- **AC-9** — the margin between the raw platform offset (CIE76 ~4.09) and the normalized threshold (3.0) is
  thin (~1.1 ΔE) but real; the fake's `normaliseAgainstCard` returns the ground truth exactly, so the test
  gates SOURCE-4's commit-wiring decision (normalize whenever a reference card is present), which is the
  behaviour under test — the native per-platform colour transform is explicitly out of this Dart build.
- **AC-10** — the colour-space tag-equality check is weak in isolation (both platform scenes are non-wide, so
  both tag `srgb`), but it is at the correct grain (equality, not a specific value); the `<0.5` coordinate
  check is the strong discriminator and catches a platform leak.

---

## 6. Gates, flakes, known gaps and deferred items

**Gates:** G-1 (spec approval — spec approved ahead of a wireframe, scope §4.1 Should/Could capture features
accepted to build now) and G-2 (acceptance-test review) both ✅ Resolved 2026-10-12. No dependency gate
(bs-09 extends bs-02's capture surface and bs-03's comparison, both already merged to `main`). No open or
recorded-but-unresolved gates.

**Open known flakes:** none recorded for bs-09; none observed this session (coverage gate PASS first run; the
integration suite ran on a booted device and actually executed its tests).

**Known gaps / deferred by design (not defects):**

- **Platform raw offset is modelled, not measured (D-7).** AC-9/AC-10 model each platform's
  pre-normalization raw with `FakeCaptureSource`'s `SceneSpec.rawColorShift` (Android +10 / iOS −8). This is
  fixture infrastructure that stands in for a real device's raw pipeline; `normaliseAgainstCard` cancels it
  to canonical CIELAB. The real per-platform native colour transform (iOS/Android camera stacks) is out of
  this Dart build — the contract under test is "commit normalizes against a present reference card, tagging
  the space actually used", which the fixtures exercise end to end.
- **Wide-gamut / RAW capture is simulated in software (D-2, D-6).** `SoftwareCaptureSource` exposes
  `supportsWideGamut`/`supportsRaw` and tags `CaptureColorSpace`/`CaptureMode` honestly; the real platform
  capture APIs (Display P3 / DNG) are a later native-integration concern behind the same `CaptureSource`
  interface. Tests assert the tag and the honest colour conversion, not pixels from a real sensor.
- **Torch is a source control, not a real hardware torch.** `turnTorchOn/Off` + the colour-temperature
  warning model the honesty signal; wiring a physical torch is a device concern behind the same control.
- **"Normalized" = canonical CIELAB + a non-null tag (D-7).** Normalization is the reference-card cancel in
  `commit()`; the accuracy *tier* still upgrades only on an explicit `calibrate()` — AC-9/AC-10 deliberately
  commit without calibrating, exercising the card-present branch as the capture contract.
- **Comparison handoff reuses bs-03 (D-5).** AC-5's pair handoff opens bs-03's `ComparisonHomeScreen` with
  both slots filled; it depends on bs-03 already on `main` (it is).

---

## 7. Cost and tokens

From the *Token usage* ledger (21 sessions; full detail: [cost-per-ac-round-1.md](cost-per-ac-round-1.md)):

- **Feature total:** 139,015,857 tokens — input 2,444 · cache write 3,801,123 · cache read 134,278,917 · output 933,373.
- **Cost (API list rates, 2026-09-25):** **$124.59** (cache read $67.14 · cache write $34.10 · output $23.33 · input $0.01). All 21 sessions priced from their transcripts.
- **Span:** 2026-10-11 21:51 EDT → 2026-10-12 21:24 EDT — **Σ active 8h 06m** (Σ wall 14h 55m).
- **By stage:** scaffold $5.97 · shells $16.39 · acceptance tests $23.75 · test review $2.10 · behavior (direct $63.21) · sign-off $1.62 · activities (plan/reconcile/gate) $11.54.
- **Per-AC (fully loaded, sums to the feature total):** shared work $6.14/AC; fully loaded $10.92 (AC-4) … $17.32 (AC-5), mean ≈ $12.46; direct behavior $3.74 (AC-9/AC-10) … $11.19 (AC-5).

*(The cost report was generated from a normalized copy of the plan: `ac_cost.py` expects each module
dashboard's Phase cell to be a bare ordinal, but bs-09's dashboards spell the full phase name — see §9's note;
the token figures reconcile exactly with the ledger's Feature total.)*

---

## 8. Summary page

Acceptance-suite summary page (built from this session's machine-readable results):
**→ https://claude.ai/artifact/7QHEey7WZ29qfCQ1yqiz2m** — "Advanced Capture Sign-off" scorecard
(verification headline, 10 ACs with grades, controls, gates, cost). Private to the owner; share from the
page's Share menu for other reviewers. Its headline (unit 918 · coverage 13/13 · integration 152 + 21 bs-09 ·
24×A) matches this run.

---

## 9. Manual walkthrough — how a reviewer sees each Rule working

**Launch:** `flutter run -d <booted-udid>` from the `Nuance-bs09` worktree root; the app opens on the Capture
screen. The bs-09 controls on that screen are the **torch** toggle (`capture-torch`), **Sample points**
(`capture-sample-points`), **Send to comparison** (`capture-send-to-comparison`), and the per-point
**readings list** (`capture-readings-list` / `capture-reading-N`). To watch the whole contract run green end
to end: `flutter test integration_test/advanced_capture_test.dart -d <booted-udid>` (21 tests).

| Spec Rule | What the reviewer does | What they see |
|---|---|---|
| The torch can light the subject, with a warning about its colour temperature | On a dim scene, tap the **torch** control; then acknowledge the warning and tap **Capture**. | Turning the torch on raises a banner stating the torch's **colour temperature** will bias the reading (not merely "torch on"); acknowledging keeps the torch lit and dismisses the banner; the committed reading is **labelled lit-by-torch**. |
| Several points can be sampled at once | Mark three points on the frame, tap **Sample points**, then read the readings list; pick two and tap **Send to comparison**. | All three points are sampled in one action — the readings list shows **three** readings, **each labelled with its own position** and carrying **its own colour value** (three distinct positions, three distinct colours). Sending two opens the comparison with **both** slots filled — sample A and sample B — from the chosen pair. |
| Capture uses the widest colour space the device offers | Capture on a wide-gamut device, then on a RAW-capable device, then on a non-wide device. | A wide-gamut capture is **tagged `displayP3`**; a RAW-capable device captures in **RAW** at the widest space; a non-wide device **falls back and labels `srgb`** — the tag always reflects the space actually used, never null. |
| A normalized sample is returned regardless of platform | Capture the same scene through the Android config and the iOS config (their raw differs pre-normalization). | Each committed sample's coordinates are **canonical CIELAB** (normalized to within ΔE of ground truth) **and** carry a **non-null colour-space tag**; the two platforms' samples are **equal after normalization** (coordinates agree, tags identical) — the platform difference never leaks to the rest of the app. |

A reviewer who wants to see the tests fail honestly can revert a behaviour phase's un-pend (re-add its AC to
`bs09/pending.dart` and remove it from the `unpended` set) and re-run: that AC's test goes red on its own
Then. AC-9/AC-10 were genuinely red at baseline (the platform raw offset survived the commit); SOURCE-4's
reference-card normalization is what turns them green.

> **Note for the reviewer (plan-tooling, non-blocking):** bs-09's module dashboards spell the full phase name
> in the *Phase* column (`SOURCE-2`), whereas `ac_cost.py` expects a bare ordinal (`2`) as the sibling
> features use. This did not affect any gate or the token totals; the per-AC/per-stage cost split in §7 was
> produced from a normalized plan copy. A future tidy could renumber the dashboards to bare ordinals.

---

## 10. Decision

Reviewer: **________**  Date: **________**  Decision: ☐ **Approved**  ☐ Changes requested

Record via `/feature-next-phase --signoff bs-09-advanced-capture approved | changes "<items>"`.

- **Approved** → SIGNOFF-1 ✅; feature `Status: Done — signed off <date> by <reviewer> at <commit>`; merge `feat/bs-09` → `main` (as bs-05/bs-06).
- **Changes requested** → each item becomes a new phase before a fresh SIGNOFF-2; this round's file stays as history.
