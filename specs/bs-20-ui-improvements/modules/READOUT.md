# Module READOUT — Readout re-composition

**Status:** 🔄 In progress — all bs-20 ACs un-pended, but SIGNOFF-1's full cross-feature regression found bs-20 regressed the signed-off **bs-11 accessibility suite** (AC-4 48dp tap target; AC-7 eyes-free Speak). READOUT-9 remediates, then SIGNOFF-1.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/readout/` (`readout_screen.dart`, `value_region.dart`, `space_selector.dart` → removed, new `all_spaces_region.dart`, `value_scale.dart`, `space_definition.dart`, `actions_bar.dart`), user-facing copy strings in `lib/readout/`. Holds the bs-20 scaffold (READOUT-1).
**Depends on:** A11Y (READOUT-7 reads `DisplaySettings.accessibilityFeatures`) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| READOUT-1 | scaffold | — | ✅ Done | 3,024,669 | 6m 06s |
| READOUT-2 | shell | — | ✅ Done | 5,244,417 | 11m 09s |
| READOUT-3 | behavior | AC-4 | ✅ Done | 19,357,101 | 43m 15s |
| READOUT-4 | behavior | AC-1, AC-3 | ✅ Done | 6,914,808 | 21m 02s |
| READOUT-5 | behavior | AC-2 | ✅ Done | 9,657,902 | 26m 19s |
| READOUT-6 | behavior | AC-5 | ✅ Done | 6,235,338 | 17m 37s |
| READOUT-7 | behavior | AC-7, AC-8 | ✅ Done | 15,442,290 | 25m 09s |
| READOUT-8 | behavior | AC-9 | ✅ Done | 6,017,977 | 15m 01s |
| READOUT-9 | behavior (regression fix) | — (restores bs-11 AC-4/AC-7) | ⬜ Next | | |

## Interface reconciliation

- **Supersedes bs-01 AC-5** (one-space-at-a-time selector). READOUT-3 removes the selector from the screen and **retired the bs-01 AC-5 integration test** (`integration_test/readout_test.dart`): the one-at-a-time behaviour no longer exists (superseded by bs-20 AC-4). **DONE 2026-10-25 — the removal cascaded wider than planned** (recorded in the READOUT-3 Result). The `SpaceSelector` *class* is **kept** (un-rendered) because the G-2-approved bs-20 AC-4 test asserts `find.byType(SpaceSelector) findsNothing` and AC-5 uses `SpaceSelector.labelFor` — both need the type importable, so deleting the file would weaken the approved tests. Reconciled consumers: bs-01 `harness_test` (selector-anchor smoke → all-spaces anchor), bs-01 AC-12 (its rebuild via the removed selector → new `whenForceRebuild` that re-pumps the app), bs-10 `daltonization_harness.storedValuesText` (read `SpaceSelector.valuesKey` → joined text under `AllSpacesRegion.regionKey`), and `test/readout/readout_screen_test.dart` (selector tests → all-spaces). The taller all-spaces readout pushed the actions bar below the 800×600 test surface, so bs-01's and bs-08's readout harnesses now size a tall viewport.
- **Re-gates bs-01 AC-8** (Speak). READOUT-7 hides Speak when accessibility is off (default). bs-01's AC-8 test must be reconciled to **enable accessibility in its setup** so Speak is present; record the edit in READOUT-7's Result.
- **bs-01 AC-1 / AC-12 unchanged in meaning**: the value is still the prominent reading (now in a card) and the capture banner / Acknowledge stay as-is.
- Reads `DisplaySettings.accessibilityFeatures` through the existing `DisplayScope` (A11Y-1).
- **Also re-gates bs-11 accessibility-conformance (found in SIGNOFF-1 verification, 2026-10-25; owner chose to remediate).** bs-20's `lib/` changes regressed two **already-signed-off** bs-11 ACs — green at the merge-base `0551d5c`, red at HEAD `a959dca`:
  - **bs-11 AC-4 (48dp tap targets)** — READOUT-6's tappable space-name `InkWell` (`space_definition.dart:81`, `EdgeInsets.symmetric(vertical: 2)` around a `labelLarge` Text + 18px icon) has a tap target < 48dp; bs-11's conformance sweep flags the Readout. **Genuine product defect** → READOUT-9 gives each space-name control a ≥48dp tap target (code fix), without disturbing AC-5's tap-to-reveal or AC-1/2/3/4 layout.
  - **bs-11 AC-7 (eyes-free screen-reader task)** — bs-11's eyes-free walkthrough uses `find.bySemanticsLabel('Speak this readout')` as the task entry control (`accessibility_test.dart:514`); bs-20 hides Speak by default, so it is absent. The G-3 resolution's stated reasoning ("bs-11 relies on the OS screen reader, not the in-app Speak button") is **contradicted** by this test. **Remediation = reconcile bs-11's AC-7 harness to enable `accessibilityFeatures`** (an eyes-free screen-reader user is the accessibility-on case) so Speak is present — **parallels the approved D-3 bs-01 AC-8 reconciliation**. Record the edit + reason in READOUT-9's Result; the assertion is preserved.

## Open gates

- ~~**G-3** blocks READOUT-7~~ — ✅ Resolved 2026-10-25: default-hidden Speak does **not** regress bs-11 accessibility-conformance. bs-11 explicitly scopes spoken output out to bs-08 (bs-11.feature lines 11-12); its screen-reader rule relies on the OS screen reader reading the always-present, labelled readout text, not on the in-app Speak button, which stays reachable whether or not accessibility features are on. — Matt Quirk
  - ⚠️ **Correction (2026-10-25, SIGNOFF-1 verification):** the G-3 reasoning is partly inaccurate — bs-11's **AC-7** test *does* drive the in-app "Speak this readout" control (not only the OS screen reader), so default-hidden Speak **did** red bs-11 AC-7. The owner chose (2026-10-25) to remediate via READOUT-9 (reconcile bs-11 AC-7 to run accessibility-on), not to reverse the Speak gating. bs-20's AC-7/AC-8 (Speak gated on the flag) stand.

## Phase READOUT-1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — · **Blocks:** A11Y-1, READOUT-2
- **Files:** none in `lib/`; `integration_test/ui_improvements/` skeleton
- **Tasks:**
  1. Branch `feat/bs-20-ui-improvements` off `main` (after bs-19 merges if possible — D-1); record `BASE`.
  2. Baseline unit run (`flutter test test/`) + confirm the coverage gate passes clean and fails on a planted gap; confirm the `flutter-tester` integration runner.
  3. Create the empty suite dir `integration_test/ui_improvements/` (no tests yet).
- **Exit criteria:** branch pushed; baseline recorded; gate tooling verified; no `lib/` change.

### Result — READOUT-1

Scaffold complete; no `lib/` change. Landed:
- Branched `feat/bs-20-ui-improvements` off `main` (`BASE = 0551d5c`, the PLAN commit). D-1 advisory (branch after bs-19 merges) **not** honoured — bs-19 is still awaiting SIGNOFF-3; proceeded because this phase writes no `lib/` and so cannot collide on `build_app.dart`. bs-19 and bs-20 both touch `build_app.dart` in later phases — carry D-1 forward.
- **Baseline unit run:** `flutter test test/ --coverage` → **1643 pass / 0 fail**; `coverage/lcov.info` produced.
- **Coverage gate verified:** `dart run tool/coverage_gate.dart 0551d5c` → clean tree **PASS** (exit 0, "nothing to gate"); planted an untracked `lib/_planted_gap_bs20.dart` → **FAIL** (exit 1, "NO COVERAGE DATA"); planted file removed.
- **flutter-tester integration runner confirmed:** `flutter test -d flutter-tester integration_test/harness_test.dart` → exit 0, all passed.
- Created the empty suite dir `integration_test/ui_improvements/` with a `README.md` placeholder (git won't track an empty dir) documenting the per-file run command and the `BS20_RUN_PENDING` gate key.

Coverage gate: N/A (no `lib/` touched). Fix passes: 0/3. Tokens / time: see dashboard row.

### Checkpoint / Handoff — READOUT-1

- **Toolchain (reuse these):** `flutter` at `/Users/matthew.quirk/development/flutter/bin` (not on PATH — prepend it). Flutter 3.47.6 / Dart 3.13.5.
  - Unit + coverage: `flutter test test/ --coverage`
  - Coverage gate: `dart run tool/coverage_gate.dart <BASE>` (line coverage on touched `lib/**`; `COVERAGE_GATE_BASE` env or arg; `main` default). **Per-branch exercise is a phase/review duty, not enforced by the tool.**
  - This feature's acceptance suite (once it exists): `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart` **per file** (whole dir won't launch at once — house gotcha); pending gate `--dart-define=BS20_RUN_PENDING=true`.
  - No `timeout` on macOS (house gotcha) — run pushes/commands bare.
- **BASE for the next phase:** branch HEAD after this commit (A11Y-1 / READOUT-2 set their own `BASE=$(git rev-parse HEAD)`).
- **Known gaps:** none introduced. Carry: D-1 build_app.dart overlap with bs-19 (unmerged); 3 carried off-lane sibling flakes (bs-06 palette AC-3/5, bs-08 display AC-9, bs-07 self_assessment AC-4) per Known flakes.
- **Next:** A11Y-1 (flag + controller setter + panel toggle) ∥ READOUT-2 (readout widget shells) — different dirs, may run concurrently in separate sessions.

## Phase READOUT-2 — Readout widget shells

- **Kind:** shell
- **Target AC:** —
- **Depends on:** READOUT-1 · **Blocks:** ITEST-1
- **Files:** `lib/readout/value_region.dart`, new `value_scale.dart`, `all_spaces_region.dart`, `space_definition.dart`, `readout_screen.dart`
- **Tasks:**
  1. Introduce keyed shell widgets: value-hero card, `ValueScale` (0–10), `AllSpacesRegion` (renders every space), per-space `SpaceDefinition` reveal. Render honest placeholders; behaviour unchanged (selector still present until READOUT-3).
  2. Wire them into `ReadoutScreen` behind the existing regions without removing current behaviour.
- **Exit criteria:** unit gate passes; existing suites stay green; anchors findable.

### Result — READOUT-2

Shell complete; behaviour unchanged (the one-at-a-time `SpaceSelector` and every bs-01 reading stay).
Landed, following the capture-shell idiom (findable keyed placeholders; real content named for its
behaviour phase):
- **New `value_scale.dart`** — `ValueScale` shell (`scaleKey`); renders `SizedBox.shrink`. READOUT-5
  renders the 11-step 0..10 strip + marks the sample's step.
- **New `all_spaces_region.dart`** — `AllSpacesRegion` shell (`regionKey`); hosts one `SpaceDefinition`
  per `ReadoutSpace`. No space *values* and no duplicate name text yet (so the still-present selector's
  `find.text('Munsell')`-style finders stay unique). READOUT-3 renders the values + drops the selector.
- **New `space_definition.dart`** — `SpaceDefinition` shell (`nameKey(space)` / `definitionKey(space)`);
  renders an empty per-space anchor. READOUT-6 makes the name tappable + reveals definition + example.
- **`value_region.dart`** — added `heroCardKey`; wrapped the value content in a `KeyedSubtree` anchor
  (no visible change). READOUT-4 turns it into a real bordered card.
- **`readout_screen.dart`** — wired `ValueScale` (after the value region) and `AllSpacesRegion` (after
  the selector) into the `ListView`; updated the screen doc.

Gates: `flutter analyze lib/readout test/readout` clean; unit **1654 pass / 0** (+6 new readout tests);
coverage gate **100% on all 5 touched `lib/` files**. Existing-suite check: bs-01 readout integration
suite (`integration_test/readout_test.dart`, flutter-tester, under the verify lock) **12/12 green** —
AC-5 selector and AC-8 Speak unchanged. No AC (shell). Fix passes: 0/3.

### Checkpoint / Handoff — READOUT-2

- **Frozen anchors (for ITEST finders):** `ValueRegion.heroCardKey` (AC-1), `ValueScale.scaleKey`
  (AC-2), `AllSpacesRegion.regionKey` (AC-4), `SpaceDefinition.nameKey(space)` /
  `definitionKey(space)` (AC-5). The displayed-colour swatch (AC-3) stays the single `ColorChip` in
  `value_region.dart`; the grayscale swatch is `ValueRegion.grayscaleKey`.
- **Verification commands (reuse):** `flutter test test/ --coverage`; `dart run tool/coverage_gate.dart <BASE>`;
  per-file `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend to PATH); no `timeout` on macOS.
- **Shells carry no real behaviour** — each new widget renders an empty/invisible keyed placeholder; the
  acceptance tests for them are *pending* until their behaviour phase un-pends them. `AllSpacesRegion` and
  `ValueScale` take no controller yet (READOUT-3 / READOUT-5 add the inputs they read).
- **Next:** the acceptance stage opens — ITEST-1 (harness + fixtures + `BS20_RUN_PENDING` gate), then
  ITEST-2 ∥ ITEST-3 (the pending AC tests + red baseline), then ITEST-4 (test review, G-2). Carry: D-1 —
  bs-19 still unmerged, both features edit `build_app.dart` (bites later behavior phases, not ITEST).

## Phase READOUT-3 — All colour spaces at once (AC-4)

- **Kind:** behavior · **Target AC:** AC-4 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `all_spaces_region.dart`, `readout_screen.dart`, remove `space_selector.dart`
- **Tasks:** render CIELCh + Munsell + sRGB + CIELAB together; remove `SpaceSelector`; keep per-space labels (host for READOUT-6 definitions).
- **Acceptance gate:** un-pend AC-4; `TestAC04_AllSpaces` green; **retire bs-01 AC-5 test** (D-3) and keep bs-01 suite green.
- **Augments:** none

### Result — READOUT-3

AC-4 delivered: every colour space shown together, the one-at-a-time selector gone. Landed:
- **`all_spaces_region.dart`** — `AllSpacesRegion` now takes the `ReadoutController` and renders, per
  `ReadoutSpace`, the space label (`SpaceSelector.labelFor`) + its `controller.readoutForSpace(space)`
  values; each space keeps a `SpaceDefinition` nameKey host (empty until READOUT-6).
- **`readout_screen.dart`** — removed the `SpaceSelector` from the screen; passes the controller to
  `AllSpacesRegion`; doc updated.
- **`space_selector.dart` kept (un-rendered).** The G-2-approved bs-20 AC-4 test asserts
  `find.byType(SpaceSelector) findsNothing` and AC-5 uses `SpaceSelector.labelFor`, so the type must stay
  importable — deleting it would weaken the approved tests. Its `build` is now dead in production
  (known gap below).
- **Pending gate:** AC-4 row removed; READOUT-3 added to `completedBehaviorPhases`.

Cross-feature reconciliation (the removal cascaded beyond the planned bs-01 AC-5 retirement — all forced by
AC-4, all assertion-preserving):
- bs-01 `integration_test/readout_test.dart` — **retired AC-5** (selector scenario; replaced by a
  retirement note citing bs-20 `TestAC04_AllSpaces`); AC-12's forced rebuild switched from the removed
  selector to the new `whenForceRebuild`; dropped the now-unused `_SpaceCase` + selector/controller imports.
- bs-01 `integration_test/harness.dart` — dropped `whenSelectSpace`; added `whenForceRebuild` (re-pumps
  `buildApp(deps)`, reusing the screen State → `build` re-runs over the same still-fresh sample, so a
  confirm-in-build would reach 2); stored `deps`; **tall viewport** in `givenReadoutOf` (the taller readout
  pushed the actions bar below 800×600).
- bs-01 `integration_test/harness_test.dart` — selector-anchor smoke → `AllSpacesRegion.regionKey`.
- bs-10 `integration_test/daltonization_harness.dart` — `storedValuesText` reads the joined text under
  `AllSpacesRegion.regionKey` (stored-derived values, unchanged by the display remap) instead of
  `SpaceSelector.valuesKey`; AC-8 meaning preserved.
- bs-08 `integration_test/display_harness.dart` — tall viewport in `givenDisplay` / `givenComparison` (the
  readout Speak control sat below the surface).
- `test/readout/readout_screen_test.dart` — selector layout/selection tests → "all spaces together, no
  selector"; controller-persistence test re-proved via acknowledge state; tall viewport helper.
  `all_spaces_region_test.dart` rewritten for the controller signature + values.

Gates: `flutter analyze` clean. Unit **1653/0** (net −1: merged two selector unit tests, dropped a
redundant all-spaces test). Coverage gate **100% on both touched lib files** (`all_spaces_region.dart`,
`readout_screen.dart`). Acceptance: bs-20 `TestAC04_AllSpaces` **green** (default run; AC-1/2/3/5/9 still
pending-skipped), smoke 7/7. Regression (every integration suite that reaches the Readout): bs-01 readout
11/11 + harness 5/5, bs-10 daltonization 25/25, bs-08 display 21/21, bs-05 comparison 26/26, bs-02 capture
19/19, design_system 27/27, correction 22/22, bs-11 accessibility 19/19, bs-12 nfr 33/33 — all green.
Grade gate (fresh independent grader): **AC-4 A, AC-6 A** — both discriminate (a one-space impl or a
lingering selector fails AC-4). Fix passes: 1/3 (the taller-readout viewport fix, applied across bs-01 +
bs-08 harnesses + the screen unit test). Tokens / time: see dashboard row.

**Known gap:** `SpaceSelector.build` is dead production code (no longer rendered), retained only as the
type/`labelFor` the approved AC-4/AC-5 tests reference. A later cleanup could move `labelFor` and delete the
widget if those tests are updated. Its lines are untouched this phase, so the coverage gate does not apply.

### Checkpoint / Handoff — READOUT-3

- **Frozen interfaces:** `AllSpacesRegion({required ReadoutController controller})` renders every space's
  label + values under `regionKey`, keeping one `SpaceDefinition` host per space. READOUT-6 (owns
  `space_definition.dart` + `all_spaces_region.dart`) makes each space name tappable inside its
  `SpaceDefinition.nameKey` and reveals the definition/example under `definitionKey` — it will move the
  plain-text label into the tappable name and reconcile AC-5's Given (`find.descendant(of: nameKey,
  matching: textContaining(label))`), which is still red/pending until then.
- **Verification commands (reuse):** `flutter test test/ --coverage`; `dart run tool/coverage_gate.dart
  <BASE>`; per-file `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH); no `timeout` on macOS; integration runs
  under `coord.sh with-lock`.
- **Shared-screen note for the remaining READOUT-* phases:** the readout body is now taller than the
  default 800×600 test surface. Any readout harness that taps the actions bar (Speak/compare/recipes/
  acknowledge) or asserts a bottom region must size a tall viewport (the bs-01 / bs-08 pattern:
  `tester.view.physicalSize = const Size(1200, 3000)` + `devicePixelRatio = 1.0` + `addTearDown(tester.view
  .reset)`). READOUT-7 (Speak gating) and the bs-20 harness will hit this.
- **Known gaps:** `SpaceSelector.build` dead (above). No open regressions — every readout-touching suite
  was run green (see Result).
- **Next:** READOUT-4 (hero card AC-1 + equal swatches AC-3) — shares `lib/readout/`, run serially.

## Phase READOUT-4 — Hero card + equal swatches (AC-1, AC-3)

- **Kind:** behavior · **Target AC:** AC-1 (full), AC-3 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `value_region.dart`
- **Tasks:** wrap the value in a bordered hero card with the value as the largest reading; size the displayed-colour swatch equal to the grayscale swatch.
- **Acceptance gate:** un-pend AC-1, AC-3; `TestAC01_HeroCard`, `TestAC03_EqualSwatches` green.

### Result — READOUT-4

AC-1 + AC-3 delivered. Landed in `lib/readout/value_region.dart`:
- **Bordered hero card (AC-1):** the value content is wrapped in a `SurfaceCard`
  (the app's ordinary bordered panel — `Border.all(outlineVariant, 2px)`, one-theme
  colours) keyed `heroCardKey`, replacing the READOUT-2 plain `KeyedSubtree`. The
  lightness stays at `prominentFontSize` (48), the largest reading on the screen.
- **Equal swatches (AC-3):** new `ValueRegion.swatchSize = 48` constant sizes both
  the grayscale preview `Container` and the displayed-colour swatch, so they render
  the same size.
- **One shared-widget change (beyond the plan's `value_region.dart` Files line):**
  `lib/widgets/color_chip.dart` gained a `double swatchSize = 16` parameter (the
  chip hard-coded 16). The displayed-colour swatch must be a `ColorChip` (the bs-08
  display chokepoint the harness finder requires), so matching the grayscale size
  needs the chip's swatch sizable. The **default is unchanged (16)**, so every other
  ColorChip call site is untouched; only the value region passes 48. No new branch
  (a plain field), so coverage stays 100%.
- **Pending gate:** AC-1 and AC-3 rows removed; READOUT-4 added to
  `completedBehaviorPhases`.

Gates: `flutter analyze` (3 touched files) clean. Unit **1654/0** (+1 net: strengthened
the hero-card unit test to assert the bordered `SurfaceCard`, added an equal-swatch-size
unit test). Coverage gate **100% on both touched lib files** (`value_region.dart`,
`color_chip.dart`). Acceptance: bs-20 `TestAC01_HeroCard` + `TestAC03_EqualSwatches`
**green** in the default run and the run-pending run; the only run-pending failures are
the still-pending AC-2/AC-5/AC-9 (+ AC-7/AC-8 in settings) at their red baselines —
exactly their owning phases. Smoke 7/7 both modes. Regression (readout-touching +
ColorChip-rendering suites): bs-01 readout 11/11 + harness 5/5, bs-08 display 21/21,
bs-10 daltonization 25/25, design_system 27/27, bs-02 capture 19/19, bs-05 comparison
26/26 — all green. Grade gate (fresh independent grader over every un-pended test):
**AC-1 A, AC-3 A, AC-4 A, AC-6 A** — 4 A / 0 B. Fix passes: 1/3 (the hero-card unit test
used a `find.descendant` for the SurfaceCard, which excludes the root the key sits on;
switched to `isA<SurfaceCard>()`). Tokens / time: see dashboard row.

**Known gap:** none introduced. Palette integration still shows the carried off-lane
flakes (bs-06 palette AC-3/AC-5) that reproduce at merge-base `c00422f` — not a
regression (neither test renders the readout or a 48px chip swatch).

### Checkpoint / Handoff — READOUT-4

- **Frozen interfaces:** `ValueRegion` renders the value inside a bordered
  `SurfaceCard` keyed `heroCardKey`; `ValueRegion.swatchSize = 48` is the shared size
  of the grayscale and displayed-colour swatches. `ColorChip({… double swatchSize =
  16})` — the swatch square side; leave the default for every call site except a
  deliberately enlarged one.
- **Verification commands (reuse):** `flutter test test/ --coverage`;
  `dart run tool/coverage_gate.dart <BASE>`; per-file
  `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH); no `timeout` on macOS;
  integration under `coord.sh with-lock`. The readout body is taller than 800×600 — a
  harness that taps the actions bar must size a tall viewport (bs-01/bs-08 pattern).
- **Known gaps:** none from this phase. `SpaceSelector.build` stays dead (READOUT-3
  gap). Carried flakes unchanged.
- **Next:** READOUT-5 (AC-2 0–10 value scale) — shares `lib/readout/`, run serially.

## Phase READOUT-5 — 0–10 value scale (AC-2)

- **Kind:** behavior · **Target AC:** AC-2 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `value_scale.dart`, `value_region.dart`
- **Tasks:** render an 11-step 0..10 scale with labels; mark the sample's Munsell value step.
- **Acceptance gate:** un-pend AC-2; `TestAC02_ValueScale` green.

### Result — READOUT-5

AC-2 delivered: the Munsell value reads on a labelled 0–10 scale with the sample's
step marked. Landed:
- **`value_scale.dart`** — the READOUT-2 `SizedBox.shrink` shell is now a real
  scale. `ValueScale({required double value})` renders the eleven whole steps
  0..10 (left=darkest, right=lightest) as a `Row` of equal `Expanded` cells, and
  marks the step nearest the sample's Munsell value
  (`markedStep = value.round().clamp(0, 10)`). The marked step is distinguished
  **without relying on colour** (CVD/SI-accessibility): a filled, bordered cell
  with a bold label and a caret `Icon`, plus a `Semantics(selected: true,
  label: 'Value N, this sample')`. `scaleKey` is preserved on the root.
- **`readout_screen.dart`** — `const ValueScale()` → `ValueScale(value:
  controller.munsell.value)`; rebuilds reactively under the existing
  `ListenableBuilder`.
- **Pending gate:** AC-2 row removed; READOUT-5 added to `completedBehaviorPhases`.

Cross-feature reconciliation (forced by the taller readout, assertion-preserving):
the readout `ListView` builds lazily (`SliverChildListDelegate`), so the new
scale's height pushed the bottom **provenance region** past the viewport cache on
the default 800×600 surface — two sibling suites that assert that bottom region
without a tall viewport went red. Fixed with the bs-01/bs-08 tall-viewport pattern
(`physicalSize = Size(1200, 3000)`, `devicePixelRatio = 1.0`, `addTearDown(reset)`):
`integration_test/daltonization_harness.dart` `_assembleDaltonization` (bs-10
AC-4) and `integration_test/correction_test.dart` `_showInLaterReadout` (bs-05/
correction AC-10). No assertion changed; the shell scale (0 height) had hidden the
limit in READOUT-3/4.

Gates: `flutter analyze` clean (lib/readout, test/readout, the two touched test
files). Unit **1658/0** (+4: new 0..10-steps / marked-step / clamp / value-0
`value_scale_test.dart` cases). Coverage gate **100% on both touched lib files**
(`value_scale.dart`, `readout_screen.dart`). Acceptance: bs-20 `TestAC02_ValueScale`
**green** in the default run; run-pending leaves only AC-5 (READOUT-6) and AC-9
(READOUT-8) red at their baselines. Regression (every readout-rendering suite):
bs-01 readout 11/11 + harness 5/5, bs-08 display 21/21, bs-10 daltonization 25/25,
bs-05 comparison 26/26, bs-02 capture 19/19, correction 22/22, advanced_capture
21/21, recipes 24/24, design_system 27/27, bs-20 smoke 7/7 + settings — all green.
Only the 3 documented carried off-lane flakes still fail (bs-06 palette AC-3/AC-5,
bs-07 self_assessment AC-4) — unrelated to the readout, reproduce at merge-base
`c00422f`. Grade gate (fresh independent subagent over every un-pended AC test):
**AC-1, AC-2, AC-3, AC-4, AC-6 — 5 A / 0 B**. Fix passes: 1/3 (the
lazy-ListView provenance-region regression → the two sibling tall-viewports).
Tokens / time: see dashboard row.

**Known gap:** none introduced.

### Checkpoint / Handoff — READOUT-5

- **Frozen interface:** `ValueScale({required double value})` renders the 0..10
  scale and marks `value.round().clamp(0, 10)` with a `Semantics(selected: true)`
  cell; `ValueScale.scaleKey` is the anchor, `minStep`/`maxStep` the bounds.
- **Verification commands (reuse):** `flutter test test/ --coverage`;
  `dart run tool/coverage_gate.dart <BASE>`; per-file
  `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH); no `timeout` on
  macOS; integration under `coord.sh with-lock`.
- **Shared-screen note (reinforced):** the readout body is now taller again. The
  readout `ListView` is **lazy** — a Then that asserts a bottom region (provenance,
  actions bar) must size a tall viewport, or the region is simply not built (0
  found / empty text), not merely off-screen. READOUT-7 (Speak, bottom actions bar)
  will hit this; its bs-01 AC-8 reconciliation already enables accessibility.
- **Known gaps:** none from this phase. `SpaceSelector.build` stays dead (READOUT-3
  gap). Carried flakes unchanged.
- **Next:** READOUT-6 (AC-5 per-space definitions) — shares `lib/readout/`, run
  serially.

## Phase READOUT-6 — Per-space definitions (AC-5)

- **Kind:** behavior · **Target AC:** AC-5 (full)
- **Depends on:** READOUT-3 (space labels exist), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `space_definition.dart`, `all_spaces_region.dart`
- **Tasks:** make each space name tappable → reveal the fuller definition + example (copy from the spec's B2 draft; owner may edit). No tap needed to see the values.
- **Acceptance gate:** un-pend AC-5; `TestAC05_Definitions` green.

### Result — READOUT-6

AC-5 delivered: each colour space's name is tappable and opening it reveals a
fuller plain-language definition with an example; the values stay always
visible (no tap needed). Landed:
- **`space_definition.dart`** — the READOUT-2 `SizedBox.shrink` shell is now a
  real control. `SpaceDefinition` is a `StatefulWidget` whose root is an
  `InkWell` keyed `nameKey(space)` wrapping the space's label (`Text(label)`,
  via `SpaceSelector.labelFor`) + an expand/collapse `Icon`; tapping toggles
  `_open`. While open it renders the definition under `definitionKey(space)`,
  so it is **hidden until the name is opened** (before/after). New static
  `SpaceDefinition.definitionFor(space)` holds the per-space plain-language copy,
  each with an example (D-4 presentation help text, owner may edit).
- **`all_spaces_region.dart`** — dropped the separate plain-text label `Text`
  (the label now lives inside the tappable name) and the now-unused
  `space_selector.dart` import; keeps `Text(controller.readoutForSpace(space))`
  so every space's **values stay always visible**. The label still appears
  exactly once per space (inside the name), so the AC-4 unit/integration
  assertions hold.
- **Pending gate:** AC-5 row removed; READOUT-6 added to
  `completedBehaviorPhases`.

Gates: `flutter analyze lib/readout test/readout integration_test/ui_improvements`
clean. Unit **1660/0** (+2: new open/close-reveal + all-spaces-definitions
`space_definition_test.dart` cases; the shell anchor test strengthened).
Coverage gate **100% on both touched lib files** (`space_definition.dart`,
`all_spaces_region.dart`). Acceptance: bs-20 `TestAC05_Definitions` **green** in
the default run; run-pending leaves only AC-7/AC-8 (READOUT-7) and AC-9
(READOUT-8) red at their baselines — exactly their owning phases. Smoke 7/7 both
modes; settings default green. Regression (every readout-touching suite): bs-01
readout 11/11 + harness 5/5, bs-08 display 21/21, bs-10 daltonization 25/25,
correction 22/22, design_system 27/27 — all green. (The 3 documented carried
off-lane flakes — bs-06 palette AC-3/5, bs-07 self_assessment AC-4 — are
unrelated to the readout and reproduce at merge-base `c00422f`.) Grade gate
(fresh independent subagent over every un-pended AC test, adversarial on AC-5):
**AC-1, AC-2, AC-3, AC-4, AC-5, AC-6 — 6 A / 0 B**. Fix passes: 0/3.
Tokens / time: see dashboard row.

**Known gap:** none introduced. `SpaceSelector.build` stays dead (READOUT-3 gap);
`SpaceSelector.labelFor` is still the live label source (now called from
`SpaceDefinition`). No tall viewport was needed — the bs-20 readout harness renders
every space name hittable on the default surface (the all-spaces region sits above
the lazy-ListView fold that bit READOUT-5's bottom provenance region).

### Checkpoint / Handoff — READOUT-6

- **Frozen interfaces:** `SpaceDefinition({required ReadoutSpace space})` renders
  the tappable name under `SpaceDefinition.nameKey(space)` (contains the label)
  and, while open, the definition under `SpaceDefinition.definitionKey(space)`;
  `SpaceDefinition.definitionFor(space)` is the per-space copy (owner-editable).
  `AllSpacesRegion` renders, per space, one `SpaceDefinition` then the space's
  always-visible values; it no longer renders a separate label `Text`.
- **Verification commands (reuse):** `flutter test test/ --coverage`;
  `dart run tool/coverage_gate.dart <BASE>`; per-file
  `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH); no `timeout` on
  macOS; integration under `coord.sh with-lock <feature> <PHASE> -- …`.
- **Shared-screen note (still applies):** the readout `ListView` is lazy — a Then
  on a **bottom** region (provenance, actions bar) must size a tall viewport
  (bs-01/bs-08 pattern). READOUT-7 adds the Speak control to the bottom actions
  bar and **will** hit this; its bs-01 AC-8 reconciliation already enables
  accessibility. (READOUT-6's names/definitions sit above the fold, so no viewport
  change was needed.)
- **Known gaps:** none from this phase. Carried flakes unchanged.
- **Next:** READOUT-7 (AC-7, AC-8 Speak gating) — **gate-blocked by G-3**; also
  needs the bs-01 AC-8 reconciliation (enable accessibility in its setup).
  READOUT-8 (AC-9 "Color" copy) is startable and independent, but shares
  `lib/readout/` → run serially.

## Phase READOUT-7 — Speak gating (AC-7, AC-8)

- **Kind:** behavior · **Target AC:** AC-7 (full), AC-8 (full)
- **Depends on:** A11Y-1, ITEST-4 (G-2), **G-3** · **Blocks:** SIGNOFF-1
- **Files:** `actions_bar.dart`
- **Tasks:** show the Speak control only when `accessibilityFeatures` is on (read via `DisplayScope`); hidden when off. Acknowledge/capture banner untouched.
- **Acceptance gate:** un-pend AC-7, AC-8; `TestAC07_SpeakHidden`, `TestAC08_SpeakShown` green; **reconcile bs-01 AC-8 test** (enable accessibility in setup) keeping bs-01 green.
- **Augments:** `TestAC07`: add the on→shown control so "hidden" isn't vacuous.

### Result — READOUT-7

AC-7 + AC-8 delivered — **behavior stage complete; every bs-20 AC un-pended**.
G-3 resolved first (approved by Matt Quirk: default-hidden Speak does not regress
bs-11, which scopes spoken output to bs-08 and relies on the OS screen reader over
the always-present readout text).

Landed (one touched `lib/` file):
- **`lib/readout/actions_bar.dart`** — the "Speak this readout" button is now
  `if (showSpeak)`, where `showSpeak = DisplayScope.maybeOf(context)?.settings
  .accessibilityFeatures ?? false`. On the readout screen (always under a
  `DisplayScope`) Speak is hidden while accessibility features are off (default)
  and revealed in place when turned on — the bar is a DisplayScope dependent, so
  the toggle rebuilds it. No `AppScope`/standalone render has a scope, so the
  `?? false` fallback keeps Speak hidden there (mirrors the shipped default). The
  other actions (compare/recipes/acknowledge) and the capture banner are untouched.

Acceptance gate — un-pended AC-7, AC-8 (the last two pending rows; gate now empty):
- bs-20 suite green both modes: `settings_test` AC-6/AC-7/AC-8 pass default **and**
  `--dart-define=BS20_RUN_PENDING=true`; `smoke_test` 7/7 (its mechanism guard
  rewritten to assert the gate is now empty — all delivered); `readout_test`
  AC-1/2/3/4/5/9 6/6.
- **Augmentation (viewport):** AC-7/AC-8 size a tall surface (`_useTallReadoutView`,
  1200×3000) before `givenReadoutOf`, so the bottom actions bar is laid out and
  `speakControl findsNothing` is a genuine "hidden", not an off-screen lazy-list
  skip (the bs-01/bs-08/READOUT-5 pattern). The pre-seeded `TestAC07` on→shown
  augmentation was already satisfied in ITEST-3 (the pair carries both directions).

bs-01 / bs-08 reconciliation (D-3; forced by gating the readout Speak control):
- **bs-01** `harness.dart` `givenReadoutOf` gained `{bool accessibilityFeatures =
  false}` (boots a `DisplayController` with it on when set); AC-8 (`readout_test`)
  and the `harness_test` smoke now pass `accessibilityFeatures: true`. bs-01
  `harness_test` 5/5, `readout_test` 11/11.
- **bs-08** `display_harness.dart` `givenDisplay`/`givenComparison` boot with
  accessibility on (preserving any seeded simulation), since the spoken-output ACs
  tap the readout Speak control. bs-08 `display_test` 21/21 (speech AC-8/9/10).
- Unit tests: `actions_bar_test.dart` pump helpers wrap a `DisplayScope` (new
  `accessibility` param; `null` = no scope for the fallback branch) + 3 new gating
  tests (hidden-off / shown-on / hidden-no-scope); `readout_screen_test.dart`
  wraps a `DisplayScope` (accessibility on) so its Speak anchors hold.

Gates: `flutter analyze lib/readout test/readout integration_test` clean; unit
**1663/0**; coverage gate **100%** on the one touched `lib/` file
(`actions_bar.dart`), both new branches (show/hide) + the null-scope fallback
covered. **Grade 9 A / 0 B** (fresh adversarial grader, full suite; no grade
changed from the prior grid). **Fix passes: 0/3.** Carried off-lane flakes
unchanged (not run this phase).

### Checkpoint / Handoff — READOUT-7

- **Frozen interface:** the readout actions bar renders the Speak control only
  when `DisplayScope`'s `accessibilityFeatures` is on; it is a DisplayScope
  dependent so toggling rebuilds it. Any test or screen that expects the readout
  Speak control present must boot/pump with accessibility on (bs-01 via
  `givenReadoutOf(..., accessibilityFeatures: true)`; bs-08 harness boots it on).
- **Verification commands (reuse):** `flutter test test/ --coverage`;
  `dart run tool/coverage_gate.dart <BASE>`; per-file
  `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH); no `timeout` on
  macOS; integration under `coord.sh with-lock <feature> <PHASE> -- …`. **Run
  integration files one at a time** (whole dir won't launch at once).
- **Known gaps:** none from this phase. The bs-20 pending gate is now empty (all 9
  ACs delivered); `pendingACs isEmpty`.
- **Next:** SIGNOFF-1 — the only remaining phase, now startable (G-3 resolved,
  every READOUT phase done). Carry D-1 (bs-19 still unmerged; it and these phases
  both edit `build_app.dart` — READOUT-7 did **not** touch it).

## Phase READOUT-8 — "Color" copy (AC-9)

- **Kind:** behavior · **Target AC:** AC-9 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** user-facing strings in `lib/readout/` (e.g. `ColorChip` label "Displayed colour" → "Displayed color", "grayscale"→"gray" where user-facing)
- **Tasks:** replace "Colour"/"colour" with "Color"/"color" in readout-screen copy; leave Dart `Color` type and code identifiers alone.
- **Acceptance gate:** un-pend AC-9; `TestAC09_ColorSpelling` green.

### Result — READOUT-8

AC-9 delivered: the readout's user-facing copy uses the American "Color" and no
"Colour"/"colour" appears. Landed (user-facing copy only — no logic, no `Color`
type or identifier touched):
- **`value_region.dart`** — the displayed-colour `ColorChip` label
  `'Displayed colour'` → `'Displayed color'`. This is the always-visible readout
  line; it renders as `Flexible(child: Text(label))`, so the American spelling is
  real visible text and gives the AC's positive `\bcolor\b` control.
- **`space_definition.dart`** — the four per-space definition strings
  (`definitionFor`) changed "colour" → "color" (5 occurrences). These are
  reveal-on-tap readout copy (D-4 help text); each keeps its example marker so
  AC-5 is unaffected.
- **Pending gate:** AC-9 row removed from `pendingACs`; READOUT-8 added to
  `completedBehaviorPhases`. Only AC-7/AC-8 remain pending (READOUT-7).

Cross-feature / test reconciliation (forced by the chip-label change,
assertion-preserving):
- `test/readout/value_region_test.dart` — the unit assertion `chip.label ==
  'Displayed colour'` → `'Displayed color'`.
- `integration_test/daltonization_test.dart` (bs-10 AC-3) — two
  `find.text('Displayed colour')` → `find.text('Displayed color')` (the swatch
  label that must stay while the swatch colour remaps); meaning preserved.
- The AC-9 test's now-stale "shell renders 'Displayed colour' today" comment
  updated to past tense (comment only; no assertion changed).

Gates: `flutter analyze lib/readout test/readout integration_test/ui_improvements
integration_test/daltonization_test.dart` clean. Unit **1660/0** (no count
change — copy edit). Coverage gate **100% on both touched lib files**
(`value_region.dart`, `space_definition.dart`). Acceptance: bs-20
`TestAC09_ColorSpelling` **green** in the default run **and** run-pending; readout
suite 6/6 both modes; smoke 7/7; settings green (AC-6 pass, AC-7/AC-8
pending-skipped). Regression (readout-rendering + the touched bs-10 suite):
bs-10 daltonization 25/25, bs-01 readout 11/11, bs-08 display 21/21, correction
22/22 — all green. (The 3 documented carried off-lane flakes — bs-06 palette
AC-3/5, bs-07 self_assessment AC-4 — are unrelated and reproduce at merge-base
`c00422f`.) Grade gate (fresh independent subagent over every un-pended AC test,
adversarial on AC-9): **AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-9 — 7 A / 0 B**.
Fix passes: 0/3.

**Known gap:** none introduced. `SpaceSelector.build` stays dead (READOUT-3 gap).
The code-comment British spellings under `lib/readout/` are developer comments,
never rendered — out of AC-9's user-facing scope, left unchanged.

### Checkpoint / Handoff — READOUT-8

- **Frozen interfaces:** the displayed-colour swatch label is `'Displayed color'`
  (`value_region.dart`); `SpaceDefinition.definitionFor(space)` copy is American
  ("color"). A sibling suite that asserts the swatch label must use `find.text(
  'Displayed color')` (bs-10 reconciled this phase).
- **Verification commands (reuse):** `flutter test test/ --coverage`;
  `dart run tool/coverage_gate.dart <BASE>`; per-file
  `flutter test -d flutter-tester integration_test/ui_improvements/<file>_test.dart`
  (`--dart-define=BS20_RUN_PENDING=true` to run pending). `flutter` at
  `/Users/matthew.quirk/development/flutter/bin` (prepend PATH); no `timeout` on
  macOS; integration under `coord.sh with-lock <feature> <PHASE> -- …`. **Run
  integration files one at a time** — passing two files to one `flutter test`
  reproduces the house "whole dir won't launch at once" load failure (hit this
  phase on `smoke+settings` together; each passed run alone).
- **Known gaps:** none from this phase. Carried flakes unchanged.
- **Next:** READOUT-7 (AC-7, AC-8 Speak gating) — **gate-blocked by G-3** (confirm
  default-hidden Speak doesn't regress bs-11 accessibility-conformance). It also
  needs the bs-01 AC-8 reconciliation (enable accessibility in its setup) and will
  hit the lazy-`ListView` bottom-region limit (tall viewport, bs-01/bs-08
  pattern), since Speak sits in the bottom actions bar. SIGNOFF-1 is also
  G-3-blocked. No startable behavior phase remains until G-3 resolves.

## Phase READOUT-9 — Restore bs-11 accessibility (48dp tap target + eyes-free Speak)

- **Kind:** behavior (regression fix — no new bs-20 AC; restores the signed-off bs-11 AC-4 and AC-7, which bs-20's `lib/` changes regressed, found in SIGNOFF-1 verification 2026-10-25)
- **Target AC:** — (guarded by the existing sibling tests `bs11/accessibility_test.dart` AC-4 + AC-7)
- **Depends on:** READOUT-6 (owns `space_definition.dart`), READOUT-7 (Speak gating) · **Blocks:** SIGNOFF-1
- **Files:** `lib/readout/space_definition.dart` (tap-target size); `integration_test/bs11/accessibility_harness.dart` and/or `integration_test/bs11/accessibility_test.dart` (AC-7 reconcile — enable `accessibilityFeatures` for the eyes-free Readout Given). Do **not** touch bs-11's `lib/` or other bs-11 ACs.
- **Tasks:**
  1. **AC-4 code fix.** Give each tappable space-name control a **≥48dp** tap target (e.g. `ConstrainedBox(minHeight: 48)` / `MergeSemantics` + sufficient padding / an `InkResponse`/`SizedBox` wrapper), preserving: AC-5 (tap still toggles the definition), AC-4 (all four space values still rendered in the all-spaces region; no `SpaceSelector`), AC-1/2/3 layout, and AC-9 copy. Keep `SpaceDefinition.nameKey` on the tappable control so bs-20 AC-5 still finds it.
  2. **AC-7 test reconcile (D-3-style).** Make bs-11's eyes-free AC-7 Given launch the Readout with `accessibilityFeatures` **on** (via the bs-11 harness's `givenScreen`/initial `DisplaySettings`, the same mechanism bs-01/bs-08 harnesses used in READOUT-7), so `find.bySemanticsLabel('Speak this readout')` is present and the eyes-free walkthrough runs. The assertion (task completes eyes-free via semantic labels; the no-label control stays unreachable) is **unchanged** — only the Given's settings change. Record the edit + reason in the Result (never weaken the AC).
- **Exit criteria / Acceptance gate:**
  - `bs11/accessibility_test.dart` **19/19 green** (AC-4 + AC-7 restored), run under the verify lock on `flutter-tester`.
  - bs-20 own suite still green **both modes** (smoke 7/7, readout 6/6, settings 3/3) — AC-5 tap-to-reveal unaffected.
  - Readout-touching cross-feature regression green (bs-01 readout, bs-08 display, bs-10 daltonization).
  - Unit + coverage: 100% line coverage on the touched `lib/` lines (the `space_definition.dart` change).
  - Grade gate: re-grade the touched bs-20 tests A (none should change); the bs-11 AC-7 reconcile is assertion-preserving (note it, not a re-grade of bs-11).
- **Augments:** none (no new bs-20 AC). **Known risk:** the 48dp wrapper must not reorder/resize the all-spaces region enough to break AC-4's region-scoped signatures or the tall-viewport assumptions; re-run bs-20 readout both modes to confirm.

### Result — READOUT-9

<!-- filled when the phase runs -->

### Checkpoint / Handoff — READOUT-9

<!-- filled when the phase runs; then SIGNOFF-1 re-runs the full cross-feature regression (must be green but
     for the carried bs-06 palette AC-3/AC-5 and bs-07 self_assessment AC-4 off-lane flakes). -->

