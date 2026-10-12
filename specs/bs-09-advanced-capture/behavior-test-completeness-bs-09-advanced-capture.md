# bs-09 Advanced capture — behaviour-test completeness

Independent adversarial grade of the bs-09 advanced-capture acceptance suite. I did **not** write these tests; I modified no test or source file. Pending tests are graded on their design (what the code asserts), not on whether they currently skip. Surfaces read to verify every Then is tight and aimed at the right surface: `integration_test/advanced_capture_test.dart`, `integration_test/advanced_capture_harness.dart`, `integration_test/capture_harness.dart` (bs-02 base), `integration_test/bs09/pending.dart`, `integration_test/fakes/fake_capture_source.dart`, `lib/capture/capture_controller.dart`, `lib/capture/capture_controls.dart`, `lib/capture/capture_live_view.dart`, `lib/capture/capture_readings_list.dart`, `lib/capture/capture_state.dart`, `lib/capture/source/capture_source.dart`, `lib/capture/source/software_capture_source.dart`, `lib/domain/sample.dart`, `lib/compare/comparison_state.dart`, `lib/compare/comparison_read_endpoint.dart`, `lib/widgets/color_chip.dart`.

Each behaviour-phase action the Whens drive (`turnTorchOn`, `acknowledgeTorchWarning`, `markPoint`, `sampleMarkedPoints`, `sendPairToComparison`) throws `UnimplementedError('<phase>')` until its phase lands, so these AC tests have a genuine red baseline rather than being green-at-baseline.

## Phase graded: ITEST-1 (harness + scaffold guards)

| Test / Artifact | Grade | Justification |
| --- | --- | --- |
| scaffold guard: `pending map covers exactly AC-1..AC-10` | A | Asserts `pendingACs.keys.toSet()` equals exactly `{AC-1..AC-10}`; rejects a gate missing an AC or carrying a stray one. Tight equality, nothing extra. |
| scaffold guard: `every pending AC is owned by a real behaviour phase` | A | Iterates `pendingACs` and requires each owner ∈ `behaviorPhases`; rejects a typo'd/stale owner that would silently never un-pend. |
| scaffold guard: `pendingSkipReason skips by default, runs when forced` | A | Checks the gate in both modes deterministically via `forceRunPending` (pending→reason, forced→null) and that an absent AC always runs — proves the skip can't pass vacuously and can't wedge a real AC off. |
| fixture guard: `SCENE_THREE_POINTS declares three points and three colours` | A | Length-3 on both `points` and `colorsAtPoints`; the shape AC-3/4/5 lean on. |
| fixture guard: `each point samples to its declared colour` | A | Samples each point through bs-02's **real** `sampleAreaAverage` and requires CIE76 `labDistance < 3.0` to its declared colour — the fixture's per-point truth is checked with the same maths the app samples with, never faked. |
| fixture guard: `points mutually distinct and off the field` | A | Each sampled point `> 20` from the neutral field and pairwise `> 20` apart (real sampling). This is the discriminator that lets AC-4 reject "all one colour"/"value is the centre"; verified, not assumed. |
| fixture guard: `SCENE_WIDE supports wide gamut; SCENE_NARROW does not` | A | Reads the real `SoftwareCaptureSource.supportsWideGamut` getter on each spec; guards the AC-6↔AC-8 control pair at source. |
| fixture guard: `SCENE_RAW supports RAW; non-RAW does not` | A | Real `supportsRaw` getter on each spec; guards the AC-7 control. |
| fixture guard: `SCENE_DIM_TORCH is dim with a biasing torch` | A | Asserts `lighting==low` (via real source), `torchAvailable`, and `torchColorShift > 0` — makes AC-1/AC-2 non-vacuous (a zero-shift torch would void the warning's premise). |
| fixture guard: `ANDROID/IOS share ground truth, differ in raw` | A | Equal `groundTruth`, both `referenceCardPresent`, distinct platforms, and both `rawColorShift` non-zero **and** unequal — so AC-10 cannot pass merely because the two fixtures' raw happened to coincide. |
| smoke: `assembled app opens on Capture with the new controls, empty readings, no torch warning` | A | Boots the real `buildApp` via `givenCaptureOf`; asserts dim scene + `torchOn==false` + `torchWarning==null` + empty `markedPoints`/`markedReadings`, the three SCREEN-1 control anchors present, torch label reads "Torch" while off, readings region present but `readingKey(0)` absent, no marked-point marker, and `torchWarningKey` absent (AC-1 precondition). Never-pending; proves the shells wire end to end. |
| harness vocabulary (`AdvancedCaptureActions`, `sampleSceneAt`, `labDistance`, `comparisonController`) | A | `when`-actions drive the **real** controls (torch/sample-points via UI taps) or the real controller (mark/acknowledge/sendPair), each a deferred stub that throws until its phase; `comparisonController` reads the live controller off the real `ComparisonReadEndpoint` with `skipOffstage:false`. No colour/sampling maths faked. |
| fixtures (`SCENE_DIM_TORCH`, `SCENE_THREE_POINTS`, `SCENE_WIDE/NARROW/RAW`, `SCENE_ANDROID/IOS`) | A | Built on real `SceneSpec` knobs that exist in source; `SCENE_THREE_POINTS` frames are rendered from CIELAB via real `toSRGB` and every bias/offset/capability the ACs lean on is pinned by a fixture guard above. |
| pending gate (`bs09/pending.dart`) | A | All 10 ACs seeded → owning phase; `acTestWidgets` wires `skip` to `pendingSkipReason`; `BS09_RUN_PENDING` define/env path isolates it from other features' gates. Guarded by the three scaffold tests above. |

## Verdict

ITEST-1: 14 A (11 tests + 3 harness/fixture/gate artifact rows, all A).

## Phase graded: ITEST-2 (AC tests — AC-1..AC-5)

| AC | Test | Grade | Justification |
| --- | --- | --- | --- |
| AC-1 | `TorchWarnsColourTemp` | A | Givens checked through the public surface before the When: `CaptureScreen` shown, `lighting==low` (source), `torchOn==false` (state), and `torchWarningKey` absent — the latter rejecting "warning present before torch on". When taps the real `torchKey`. Then asserts `torchOn==true` **and** the banner is present **and** its real text (read off `torchWarningKey`'s `Text`) contains `temperature` **and** one of bias/skew/shift. Catches: silent toggle (no banner), a banner that omits the colour-temperature bias. Red baseline (stub throws), so not green-at-baseline. Discriminates. |
| AC-2 | `ReadingLabelledTorchLit` | A | Carries its own **control** in-test (satisfies G5): a torch-off `whenCommit()` first asserts `lastCommittedSample.litByTorch==false`, so the positive Then cannot pass by stamping every sample. Then turns torch on, acknowledges (asserting torch **stays** lit and banner dismissed — both AC-2's own catalogue, not another AC), commits, and asserts `litByTorch==true`. All through the real capture UI/commit, which reads `_state.torchOn`. Asserts at the exact bool grain; rejects "stamp-all-samples" and "never-stamp". |
| AC-3 | `MultiPointSamplesAllAtOnce` | A | Given marks three points and checks `markedPoints` length 3 through state before the When; When taps the real `samplePointsKey`. Then asserts `markedReadings` length **exactly 3** and the set of reading positions equals the three marked points — rejecting both "only the centre sampled" and "one averaged reading over all" (either collapses the count). Raw observable at the step's grain, no leftover-tolerant derivation. |
| AC-4 | `EachPointKeepsPositionValue` | A | Given three readings exist. Then builds a `position→coordinates` map from the raw readings, requires its keys to equal the three points (a shared position collapses the map and fails), requires each point's value within CIE76 `< 3.0` of **that point's own** declared colour (the three are mutually `>20` apart and `>20` off the field per the ITEST-1 guard, so "all one colour" and "value is the frame centre" both fail), and requires each row labelled `Point (x, y)` as a descendant of the real `CaptureReadingsList` — matching the live label format. Asserts each item per the step's "each" grain; aimed at the raw per-point value, not a tolerant aggregate. |
| AC-5 | `TwoPointsToComparison` | A | Given three readings; resolves the P1 and P3 readings by position. When sends the chosen pair through the real `sendPairToComparison`; Then observes the live `ComparisonController` via the real `ComparisonReadEndpoint` and asserts **both** slots filled, `slotA` within Δ<3 of the P1 reading, `slotB` within Δ<3 of the P3 reading, and `slotA`↔`slotB` `>3` apart. Rejects "one slot filled / other awaiting the picker", a swap or duplicate, and the wrong two carried. Through the real comparison surface end to end. |

## Verdict

ITEST-2: 5 A / 0 below A (AC-1..AC-5 all A).

### Cross-cutting observations (no grade impact)

- AC-5 implicitly assumes `sendPairToComparison(0, 2)` maps marked-reading indices 0 and 2 to the P1 and P3 readings, while AC-3 only pins the *set* of reading positions, not their order. The Then still correctly rejects a swap (it matches `slotA` against the P1 reading looked up by position, not by index), so it does not over-accept; the coupling is a reasonable ordering expectation of the forthcoming CAPTURE-4/CAPTURE-5 contract rather than a correctness gap.
- The whole suite is a false-green risk only if run without `-d <udid>` (zero tests, exit 0) — documented in the file header; that is an invocation hazard, not a test-design defect.
