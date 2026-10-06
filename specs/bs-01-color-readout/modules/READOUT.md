# Module READOUT — Readout screen UI + controller

**Status:** In progress — READOUT-5 done (provenance badges: AC-6, AC-7 green); next READOUT-6 (navigation handoffs)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/readout/` — `readout_screen.dart` and per-region widgets
(`value_region.dart`, `name_header.dart`, `temperature_line.dart`, `space_selector.dart`,
`provenance_region.dart`, `actions_bar.dart`), `readout_controller.dart`.
**Depends on:** CORE, COLOR, A11Y · **Blocks:** SIGNOFF-1

> The Readout screen is the single surface under test. READOUT-2..6 and A11Y-2 all edit it — **merge-risky**;
> run serially. The shell (Phase 1) splits the screen into per-region files so later phases touch disjoint
> files where possible.

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 7,613,743 | 14m 38s (14m 38s) |
| 2 | behavior | AC-1, AC-2 | ✅ Done | 10,406,545 | 58m 47s (58m 48s) |
| 3 | behavior | AC-3, AC-4 | ✅ Done | 8,419,171 | 15m 59s (15m 59s) |
| 4 | behavior | AC-5 | ✅ Done | 7,596,426 | 12m 20s (12m 20s) |
| 5 | behavior | AC-6, AC-7 | ✅ Done | 6,292,987 | 16m 03s (16m 03s) |
| 6 | behavior | AC-9, AC-10, AC-11 | ⬜ Todo | | |

## Interface reconciliation

- `ReadoutController` holds the current `Sample` and exposes the derived readings (via `ColorScience`), the
  selected colour space, the speak action (→ A11Y-2), and the just-captured state (→ A11Y-2). The screen is a
  thin view over it. Region widgets come from A11Y's label-contract set where applicable (`ValueReading`,
  `ProvenanceBadge`).
- Navigation uses CORE's typed routes (`toComparison`, `toRecipes`) into the stub screens.

## Open gates

- **G-2 (approve acceptance tests)** blocks Phases 2–6 (all behavior).

## Phase 1 — Shell: Readout screen scaffold

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-2, COLOR-1, A11Y-1 · **Blocks:** ITEST-1, READOUT-2..6, A11Y-2
- **Files:** `lib/readout/readout_screen.dart` + the per-region widget files + `readout_controller.dart`.
- **Tasks:**
  1. Lay out all regions with placeholder content wired to the controller: value region, grayscale slot, name
     header, temperature line, colour-space selector, provenance region, actions bar (speak, compare-as-A/B,
     find-recipes, acknowledge).
  2. Controller holds a `Sample` and exposes selectors; no real derivations/behaviour (calls the COLOR/A11Y
     stubs). Make the screen the default route for a loaded sample.
- **Exit criteria:** unit/widget + coverage gate; `flutter test` green; the screen renders every region (so
  ITEST finders have anchors); behaviour unchanged.
- **Acceptance gate:** *(n/a — shell)*

### Result

- Landed: `lib/readout/` — `ReadoutController` (ChangeNotifier holding the `Sample` + injected
  `ColorScience`/`Speech`/`Haptics`/`AppRouter`, the `selectedSpace` (`ReadoutSpace` enum, default CIELCh)
  and a just-captured seam: `selectSpace`, `acknowledge`, `nameText`); `ReadoutScreen` (StatefulWidget that
  builds the controller once from `AppScope.of(context)` and disposes it) laying out six region widgets —
  `NameHeader`, `ValueRegion` (value + grayscale slot + Munsell placeholder), `TemperatureLine`,
  `SpaceSelector` (four-space `ChoiceChip` set, selection wired; per-space values placeholder), `ProvenanceRegion`,
  `ActionsBar` (five findable controls: speak / compare-A / compare-B / find-recipes / acknowledge). Every
  region/control carries a stable `ValueKey` anchor (e.g. `readout-value-region`, `readout-action-speak`).
- **No AC behaviour implemented** (lifecycle: behaviour follows the test review / G-2). Colour derivations are
  placeholders (the `ColorScience` stub throws until COLOR-2/3); the action controls are **disabled**
  placeholders until their behaviour phase wires them (speak + acknowledge → A11Y-2; compare-A/B + recipes →
  READOUT-6). The space selector toggles view state only — real per-space values + exclusivity are READOUT-4.
- `build_app.dart`: `buildApp` now opens on `ReadoutScreen(sample: deps.initialSample)` (replacing
  `_ReadoutPlaceholder`); added `AppDependencies.initialSample` (optional, defaults to new `demoSample` const)
  as the seam the acceptance harness injects a fixture through — `buildApp(deps)` signature unchanged (D-7).
- Fix passes: 2/3 — (1) a `prefer_initializing_formals` lint on the private `_sample` field (resolved with a
  scoped `// ignore`); (2) the coverage gate failed with "NO COVERAGE DATA" on a const-only `demo_sample.dart`
  (Dart emits no lcov record for a compile-time-const-only library) — folded `demoSample` into `build_app.dart`.
  Implementation moved toward green each pass.
- Suites run: unit/widget (this feature) only; no acceptance suite yet (stage 3). `flutter analyze` clean.
- Tests: 92 passing (+20) · Coverage (touched files): 100% line on all 23 touched `lib` files, incl. the 7
  new readout files + changed `build_app.dart` (Dart emits line coverage only; every branch exercised by a
  test per the review requirement — `selectSpace`/`acknowledge` both branches, `nameText` named/unnamed, all
  four `SpaceSelector.labelFor` cases, the controller-reuse guard in `didChangeDependencies`). Acceptance: n/a.
- Test grades: n/a (shell) · Augmentations made: none · Justified exclusions: none.
- Closed by: gate pass.
- Tokens: 7,613,743 (claude-opus-4-8) · Time: 14m 38s active (14m 38s wall). **Phase total: 7,613,743 tokens, 14m 38s.**

### Checkpoint / Handoff

- **Frozen for the behaviour phases:**
  - `ReadoutController{sample, colorScience, speech, haptics, router, selectedSpace, justCaptured, nameText,
    selectSpace(space), acknowledge()}` — a `ChangeNotifier`; the screen is a `ListenableBuilder` over it.
  - `ReadoutSpace { cielch, munsell, srgb, cielab }` (+ `SpaceSelector.labelFor`).
  - Region widgets each take `{required ReadoutController controller}`: `NameHeader` (`headerKey`),
    `ValueRegion` (`regionKey`, `grayscaleKey`), `TemperatureLine` (`lineKey`), `SpaceSelector`
    (`selectorKey`, `valuesKey`), `ProvenanceRegion` (`regionKey`), `ActionsBar` (`barKey`, `speakKey`,
    `compareAKey`, `compareBKey`, `recipesKey`, `acknowledgeKey`). **These key constants are the acceptance
    finders' anchors** — ITEST reads them; behaviour phases fill each region's real content behind them.
  - `AppDependencies.initialSample` (defaults to `demoSample`) — ITEST-1 injects a fixture here; `buildApp`
    passes it to `ReadoutScreen(sample:)`.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart main`.
- **Known gaps (all intended for later phases):** colour derivations throw (COLOR-2/3); value/Munsell/
  temperature/space/provenance regions show placeholder text; action controls are disabled; the selector
  shows a placeholder, not real per-space values. No AC is satisfied yet.
- **Next phase should:** the ITEST stage is now unblocked — run **ITEST-1** (harness over the wired shell:
  fixtures, `buildApp` with faked `Speech`/`Haptics`, the pending gate, smoke). G-2 (approve acceptance tests)
  stays open and blocks the behaviour stage (READOUT-2..6, A11Y-2, COLOR-2/3). Behaviour phases edit the
  Readout screen/controller — **merge-risky, run serially**.

## Phase 2 — Behavior: value region (AC-1, AC-2)

- **Kind:** behavior
- **Target AC:** AC-1 (full), AC-2 (full)
- **Depends on:** COLOR-2 (conversions), COLOR-3 (value word), READOUT-1, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/readout/value_region.dart`, `readout_controller.dart`.
- **Tasks:** render Lightness as the largest reading; grayscale preview; Munsell value beside it (AC-1); the
  value word next to the number (AC-2). Unit-test size-prominence logic and the word mapping.
- **Exit criteria:** unit + coverage on touched files; grade gate.
- **Acceptance gate:** un-pend AC-1, AC-2; `TestAC01_*`, `TestAC02_*` green in run-pending (+ earlier ACs).
- **Augments:** `TestAC01_LightnessProminent`: once READOUT-4 lands, strengthen the "largest reading" check
  to out-rank the colour-space readings too (add a row).

### Result

- **Landed:** `value_region.dart` renders the value region — Lightness as the prominent reading
  (`ValueRegion.prominentFontSize` = 48, bold) paired with its value word via the `ValueReading` widget; a
  grayscale preview swatch coloured from the sample's neutral (`controller.grayscale`); and the Munsell value
  beside the number ("Munsell value 5.5"). `readout_controller.dart` exposes the derived readings `lightness`,
  `valueWord`, `munsell` (`MunsellColor`) and `grayscale` (`SRGBColor`), each delegating to the injected
  `ColorScience`. Lightness displays rounded (spec "Lightness 58"); Munsell value drops a redundant ".0".
- **Scope extension (recorded):** added `ReadoutController.load(Sample)` (identity-guarded, notifies) and
  `ReadoutScreen.didUpdateWidget` so a sample injected into the live screen updates the reading in place —
  touches `readout_screen.dart` (module-owned) beyond the two listed files. **Why:** the acceptance harness
  re-pumps each scenario sample into the *same* screen position; the shell built its controller once and
  ignored a changed `widget.sample`, so AC-2's L15/L90 controls read the first sample (L58). Aligns with
  D-1/bs-02 ("capture replaces the running app's initial sample").
- **Test-infra change (recorded):** AC-1, AC-2 un-pended in `harness.dart`; `harness_test.dart` pending-gate
  tests rewritten to assert the pending map is the exact complement of the un-pended set across all 12 ACs
  (kept non-vacuous). **Why:** the "all 12 pending" invariant changes as behaviour un-pends ACs.
- **Gates:** unit 159 pass (+12); coverage gate **100% line** on the 3 touched lib files (PASS); `flutter
  analyze` clean. Acceptance (iOS sim `5AB9D06D…`, default mode): **AC-1, AC-2 green**; AC-3..12
  skipped/pending; harness smoke + pending-gate + fake tests green.
- **Test grades:** AC-1 **A**, AC-2 **A** (independent fresh grader; both discriminate against the live code —
  not green-vacuous). No B to fix.
- **Augmentations made:** none. AC-1's pre-seeded "largest reading" augmentation is **redundant** — the test's
  generic "larger than every other body reading" already out-ranks the colour-space readings READOUT-4 will
  render (confirmed by the grader and the ITEST-2 grid). Carried: AC-5 sRGB-triplet tightening still owned by
  READOUT-4. Justified exclusions: none.
- **Fix passes: 1/3** — first acceptance run: AC-2's L15 control failed (stale sample on re-pump); fixed with
  `load()`/`didUpdateWidget`; re-run green. The implementation moved to green on that pass.
- **Closed by:** gate pass.
- **Tokens:** 10,406,545 · **Time:** 58m 47s (58m 48s).

### Checkpoint / Handoff

- **Frozen additions (for the later behaviour phases):**
  - `ReadoutController` now also exposes `lightness` (double), `valueWord` (String), `munsell`
    (`MunsellColor`), `grayscale` (`SRGBColor`), and `load(Sample)` — identity-guarded, notifies, keeps the
    selected space. The screen reloads the controller on a changed `widget.sample` (`didUpdateWidget`).
  - `ValueRegion.prominentFontSize` = 48 is the value-region prominence constant. The region renders:
    grayscale swatch (`grayscaleKey`) + `ValueReading(number: rounded L, word: valueWord)` + a "Munsell
    value <v>" line.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart <base>`. Acceptance:
  boot the sim once (`xcrun simctl boot 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), then default
  `flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; run-pending adds
  `--dart-define=BS01_RUN_PENDING=true`.
- **Known gaps (later phases):** the name header still shows the stored/placeholder name (AC-3 → READOUT-3);
  temperature line, colour-space selector and provenance region are still placeholders (READOUT-3/4/5); the
  action controls stay disabled (A11Y-2 / READOUT-6).
- **Next phase should:** run **READOUT-3** (AC-3 name + AC-4 temperature) — edits `name_header.dart` and
  `temperature_line.dart`. All READOUT behaviour phases edit the Readout screen/controller — **merge-risky,
  run serially**. When READOUT-4 lands, the AC-1 pre-seed can be dropped with a note (confirmed redundant).

## Phase 3 — Behavior: name header + temperature (AC-3, AC-4)

- **Kind:** behavior
- **Target AC:** AC-3 (full), AC-4 (full)
- **Depends on:** COLOR-3 (name, temperature word), READOUT-1, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/readout/name_header.dart`, `temperature_line.dart`.
- **Tasks:** show the ISCC-NBS name large at the top (AC-3); state temperature as a word (AC-4). Unit-test the
  warm/cool/neutral word selection incl. the `SAMPLE_COOL` control path.
- **Exit criteria:** unit + coverage; grade gate.
- **Acceptance gate:** un-pend AC-3, AC-4; `TestAC03_*`, `TestAC04_*` green in run-pending (+ earlier ACs).
- **Augments:** none.

### Result

- **Landed:** `name_header.dart` renders the colour name at `ValueRegion.prominentFontSize` (48, bold) inside
  a keyed `Semantics(header: true)` wrapper, so the name is the largest text at the top and marked a heading
  for assistive tech (SI Accessibility, AC-3). `temperature_line.dart` renders `"Temperature: <word>"` from
  the controller (AC-4). `readout_controller.dart` now derives both: `nameText` = `_sample.name ??
  colorScience.nearestName(coordinates)` (an un-named sample shows the nearest ISCC-NBS name, not a
  placeholder); `temperatureWord` = `colorScience.temperatureWord(toCIELCh(coordinates).hue)`.
- **Structural fix (recorded):** the shell kept `NameHeader.headerKey` on the name `Text` itself; the AC-3
  finder is `find.descendant(of: byKey(headerKey), matching: find.text('Warm Terracotta'))`, which excludes
  the matched root — so the name must be a *descendant* of the keyed widget. Moved the key onto the wrapping
  `Semantics` with the `Text` as its child. No behaviour change; the readout_screen widget test's
  descendant check now resolves too.
- **AC test change (recorded, non-weakening):** removed the AC-3 Given
  `expect(find.text('Unnamed sample'), findsOneWidget)` from `readout_test.dart`. **Why:** it asserted the
  shell placeholder, which the derived-name behaviour (AC-3) necessarily replaces — the two could never both
  hold. The "no stored name" Given is still established by the retained `expect(unnamed.name, isNull)` on the
  public `Sample` surface; the Then still rejects both an echo-of-`Sample.name` impl and a not-derived impl.
  Independent grader confirmed no loss of discriminating power.
- **Test-infra change (recorded):** AC-3, AC-4 un-pended in `harness.dart`; `harness_test.dart` pending-gate
  example switched from AC-3 (now landed) to AC-5 (still pending), and the un-pended set extended to
  `{AC-1, AC-2, AC-3, AC-4}` — keeps the complement invariant non-vacuous.
- **Gates:** unit 162 pass (+3: controller temperatureWord warm/cool/neutral; screen unnamed→derived; grid);
  coverage gate **100% line** on the 3 touched lib files (PASS); `flutter analyze` clean. Acceptance
  (iOS sim `5AB9D06D…`, default mode): **AC-3, AC-4 green**; AC-1, AC-2 stay green; AC-5..12 skipped/pending;
  harness smoke + pending-gate + fake tests green.
- **Test grades:** independent fresh grader re-graded **all** un-pended tests live: AC-1 **A**, AC-2 **A**,
  AC-3 **A**, AC-4 **A** (4×A, 0×B). No downgrade; AC-1's name-header exclusion confirmed intact (name 48 ==
  value 48, so the exclusion is load-bearing). Grid: `behavior-test-completeness-bs-01-color-readout.md`.
- **Augmentations made:** none (none due this phase). Carried: AC-5 sRGB-triplet tightening (READOUT-4);
  AC-1's pre-seed remains confirmed redundant. Justified exclusions: none.
- **Fix passes: 1/3** — first unit run: the readout_screen unnamed-sample test failed on the
  `find.descendant` root-exclusion (key on the `Text`); fixed by keying the `Semantics` wrapper. Re-run green.
  Implementation moved to green on that pass.
- **Closed by:** gate pass.
- **Tokens:** 8,419,171 (claude-opus-4-8) · **Time:** 15m 59s active (15m 59s wall). **Phase total: 8,419,171 tokens, 15m 59s.**

### Checkpoint / Handoff

- **Frozen additions (for the later behaviour phases):**
  - `ReadoutController` now also exposes `nameText` (derived: stored name, else nearest ISCC-NBS name) and
    `temperatureWord` (String: "warm"/"cool"/"neutral", from the CIELCh hue).
  - `NameHeader.nameStyle` is `TextStyle(fontSize: ValueRegion.prominentFontSize /* 48 */, bold)`; the key
    `NameHeader.headerKey` is on a wrapping `Semantics(header: true)`, with the name `Text` as its child —
    finders that look *inside* the header (descendant / paragraphsUnder) rely on this.
  - `TemperatureLine` renders `"Temperature: <word>"` keyed `TemperatureLine.lineKey`.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart <base>`. Acceptance:
  boot the sim once (`xcrun simctl boot 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), then default
  `flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; run-pending adds
  `--dart-define=BS01_RUN_PENDING=true`.
- **Known gaps (later phases):** colour-space selector shows placeholder per-space values (AC-5 → READOUT-4);
  provenance region is still a placeholder (AC-6/7 → READOUT-5); action controls stay disabled (speak +
  just-captured → A11Y-2; compare/recipes → READOUT-6).
- **Next phase should:** run **READOUT-4** (AC-5 colour-space selector) — edits `space_selector.dart` +
  `readout_controller.dart`, and makes AC-1's (redundant) pre-seed augmentation decision: the generic
  largest-reading check already out-ranks the now-rendered space readings, so drop the pre-seed row with a
  note. All READOUT behaviour phases edit the Readout screen/controller — **merge-risky, run serially**.

## Phase 4 — Behavior: colour-space selector (AC-5)

- **Kind:** behavior
- **Target AC:** AC-5 (full — the outline's four spaces)
- **Depends on:** COLOR-2 (conversions), READOUT-1, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/readout/space_selector.dart`, `readout_controller.dart`.
- **Tasks:** selecting a space shows that space's values and hides the others (exclusivity). Unit-test the
  selection state and each space's formatting.
- **Exit criteria:** unit + coverage; grade gate.
- **Acceptance gate:** un-pend AC-5; `TestAC05_ColourSpaceSelector` green in run-pending (+ earlier ACs).
- **Augments:** make AC-1's pre-seeded augmentation (value out-ranks the now-rendered space readings).

### Result

- **Landed:** `readout_controller.dart` gained `spaceReadout` (the selected space's formatted values) and
  `readoutForSpace(space)` (formats any space; exposed for unit testing each space's formatting). Each space
  reads through `ColorScience`: CIELCh → `L 58, C 34, h 42°` (rounded); Munsell → `10R 5.5/6` (the familiar
  notation, a `_trimZero` helper dropping a redundant `.0` chroma); sRGB → `192, 122, 101  #c07a65` (8-bit
  triplet **and** hex); CIELAB → `L 58, a 25.27, b 22.75`. `space_selector.dart` now renders
  `controller.spaceReadout` under `valuesKey` — only the selected space, so selecting another replaces it and
  the others are no longer shown (the one-at-a-time rule, AC-5). Stale READOUT-4-pending doc comments on the
  `ReadoutSpace` enum and the selector updated to describe the landed behaviour.
- **AC-5 augmentation made (own AC, G6):** added `RegExp(r'\b\d{1,3},\s*\d{1,3},\s*\d{1,3}\b')` to the sRGB
  `present` list in `readout_test.dart`, so the test now asserts the spec's "a triplet **and** a hex value"
  (was hex only — the ITEST-2 borderline). Discriminates: the pre-READOUT-4 placeholder (`sRGB values —`) has
  no triplet, so it would have failed before. Closes the one open augmentation; ITEST.md updated.
- **AC-1 pre-seed decision:** confirmed **dropped** (already ❌ in ITEST-2). AC-1's "largest reading" is a
  font-*size* check — the now-rendered space readings render at body ~14 vs the prominent 48, so the generic
  "larger than every other body reading" already out-ranks them; a size augmentation adds no new assertion.
- **Test-infra change (recorded):** AC-5 un-pended in `harness.dart`; `harness_test.dart` `unpended` set →
  `{AC-1..AC-5}` and the pending-gate example switched from AC-5 (now landed) to AC-6 (still pending), keeping
  the complement invariant non-vacuous. `readout_screen_test.dart`: the three widget tests that asserted the
  old placeholder (`'CIELCh values —'` / `'Munsell values —'`) now assert the real readout via a `_spaceValues`
  helper (CIELCh shows `°`; Munsell shows `10R` and no `°`).
- **Gates:** `flutter analyze` clean; unit **168 pass** (+6: four per-space formats, `spaceReadout` tracks
  selection, tracks a reloaded sample); coverage gate **100% line** on both touched lib files (PASS). Branch
  coverage proven by design — all four `switch` cases and both `_trimZero` branches (5.5 non-integer, 6.0
  integer) exercised. Acceptance (iOS sim `5AB9D06D…`, default mode): **AC-5 green**; AC-1..AC-4 stay green;
  AC-6..12 skipped/pending; harness smoke + pending-gate + fakes green.
- **Test grades:** independent fresh grader re-graded **all** un-pended tests live (AC-1..AC-5): **5×A, 0×B**.
  AC-5 borderline closed to a clean A by the triplet augmentation; no downgrades. Grid:
  `behavior-test-completeness-bs-01-color-readout.md` (§ Re-grade — READOUT-4).
- **Augmentations made:** AC-5 sRGB triplet (above). **Carried:** none — the last open augmentation is now
  closed. Justified exclusions: none.
- **Fix passes: 0/3** — analyze, unit+coverage and acceptance all green on the first full run (the screen/
  harness test updates were made alongside the behaviour, before the gate run).
- **Closed by:** gate pass.
- **Tokens:** 7,596,426 (claude-opus-4-8) · **Time:** 12m 20s active (12m 20s wall). **Phase total: 7,596,426 tokens, 12m 20s.**

### Checkpoint / Handoff

- **Frozen additions (for the later behaviour phases):**
  - `ReadoutController.spaceReadout` (String — the selected space's values) and
    `readoutForSpace(ReadoutSpace)` (formats any space). The selector renders `spaceReadout` under
    `SpaceSelector.valuesKey`, exclusively (one space at a time).
  - Formats are frozen: CIELCh `L <l>, C <c>, h <h>°` (rounded); Munsell `<hue> <value>/<chroma>` (`.0`
    trimmed); sRGB `<r>, <g>, <b>  <#hex>`; CIELAB `L <l>, a <a.aa>, b <b.bb>`.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart <base>`. Acceptance:
  boot the sim once (`xcrun simctl boot 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), then default
  `flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; run-pending adds
  `--dart-define=BS01_RUN_PENDING=true`.
- **Known gaps (later phases):** provenance region is still a placeholder (AC-6/7 → READOUT-5); action
  controls stay disabled (compare/recipes → READOUT-6; speak + just-captured → A11Y-2).
- **Next phase should:** run **READOUT-5** (AC-6 Measured badge + AC-7 Estimated badge & note) — edits
  `provenance_region.dart`. All READOUT behaviour phases edit the Readout screen/controller — **merge-risky,
  run serially**. No open augmentations remain.

## Phase 5 — Behavior: provenance badges (AC-6, AC-7)

- **Kind:** behavior
- **Target AC:** AC-6 (full), AC-7 (full)
- **Depends on:** CORE-2 (provenance model), READOUT-1, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/readout/provenance_region.dart`.
- **Tasks:** render the provenance badge from the sample's tier — "Measured" (AC-6); "Estimated — not yet
  verified" + the "Seeded by a model. Treat as a starting point." note (AC-7). Unit-test each tier incl. the
  note presence/absence.
- **Exit criteria:** unit + coverage; grade gate.
- **Acceptance gate:** un-pend AC-6, AC-7; `TestAC06_*`, `TestAC07_*` green in run-pending (+ earlier ACs).
- **Augments:** none.

### Result

**READOUT-5 done (2026-10-06).** The provenance region now renders the sample's trust tier as a
plain-language badge (never colour alone): a **measured** reading reads "Measured" with no caveat (AC-6); an
**estimated** reading reads "Estimated — not yet verified" with the note "Seeded by a model. Treat as a
starting point." beneath it (AC-7). Label + note are folded into one semantics announcement.

- **What landed:** `lib/readout/provenance_region.dart` — `labelFor(provenance)` (estimated → the "— not yet
  verified" qualifier; every other tier → the bare `Provenance.label`) and `noteFor(provenance)` (estimated →
  the seeded-value caveat; else null), rendered under `regionKey` via `Semantics(excludeSemantics) + Column`.
- **Design note:** the "— not yet verified" qualifier and the caveat are **presentation** concerns owned by
  the region — the domain `Provenance.label` carries only the bare tier word (shared by every surface). The
  shell's `ProvenanceBadge` widget renders `Provenance.label` as-is, so it can't carry the display qualifier;
  the region renders directly (mirroring the badge's text-only, folded-semantics a11y contract). `ProvenanceBadge`
  keeps its own passing unit test and stays available as a general component.
- **Unit:** `test/readout/provenance_region_test.dart` — all 4 tiers (label + note presence/absence), the two
  widget renders, and both semantics-announcement branches. `flutter analyze`: clean. Coverage gate on the one
  touched lib file: **100%** line (both ternary branches covered).
- **Acceptance:** AC-6/AC-7 un-pended (removed from `harness.dart` `pendingACs`); default
  `flutter test integration_test/ -d <udid>` → **+12 ~5** green (AC-1..7 pass; AC-8..12 still pending/skipped).
  `TestAC06`/`TestAC07` green.
- **Test change (non-weakening, no AC test touched):** `integration_test/harness_test.dart` — the two
  pending-gate **self-tests** encode the un-pended set; un-pending AC-6/AC-7 required adding them to `unpended`
  and swapping the "still pending" example (AC-6 → AC-8, still owned by A11Y-2). These are harness guard tests,
  not AC tests.
- **Grade gate:** independent fresh re-grade of every un-pended AC test (AC-1..7) against live behaviour →
  **7×A, 0×B**, no regressions (AC-1/AC-3 prominence still holds — the new region text renders at ~14px, far
  below the 48px lightness/name). Grid: `../behavior-test-completeness-bs-01-color-readout.md`.
- **Augmentations:** none assigned; none newly enabled. **Fix passes:** 1/3 (harness self-tests updated after
  the first run; AC-6/AC-7 passed on the first run).
- **Tokens:** 6,292,987 (claude-opus-4-8) · **Time:** 16m 03s active (16m 03s wall). **Phase total: 6,292,987 tokens, 16m 03s.**

### Checkpoint / Handoff

- **Frozen additions:** `ProvenanceRegion.labelFor(Provenance)` / `noteFor(Provenance)` /
  `estimatedNote` (`@visibleForTesting` statics) — the tier→display mapping. The region renders under
  `ProvenanceRegion.regionKey` and reads live from `controller.sample.provenance`.
- **Verification commands** (PATH export first — `export PATH="$HOME/development/flutter/bin:$PATH"`):
  `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart <base>`. Acceptance: boot
  the sim once (`xcrun simctl boot 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`), then default
  `flutter test integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`; run-pending adds
  `--dart-define=BS01_RUN_PENDING=true`. Un-pend an AC by deleting its `pendingACs` row in `harness.dart`
  **and** updating the two `harness_test.dart` pending-gate self-tests (`unpended` set + the "still pending"
  example). Plain `flutter test integration_test/` (no `-d`) is a false green.
- **Known gaps (later phases):** action controls stay disabled — compare/recipes → READOUT-6 (AC-9/10/11);
  speak + just-captured → A11Y-2 (AC-8/12).
- **Next phase should:** run **READOUT-6** (AC-9/10/11 navigation handoffs) — edits the actions bar /
  controller navigation. All READOUT behaviour phases edit the Readout screen/controller — **merge-risky, run
  serially**. No open augmentations remain. A11Y-2 (AC-8/12) is the other startable serial phase.

## Phase 6 — Behavior: navigation handoffs (AC-9, AC-10, AC-11)

- **Kind:** behavior
- **Target AC:** AC-9 (full), AC-10 (full), AC-11 (full)
- **Depends on:** CORE-2 (routes + stub screens), READOUT-1, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/readout/actions_bar.dart`, `readout_controller.dart`.
- **Tasks:** compare-as-A → Comparison with sample in slot A (AC-9); compare-as-B → slot B (AC-10);
  find-recipes → Recipes with sample as target (AC-11). Unit-test each route call carries the right argument.
- **Exit criteria:** unit + coverage; grade gate.
- **Acceptance gate:** un-pend AC-9, AC-10, AC-11; `TestAC09/10/11_*` green in run-pending (+ earlier ACs).
- **Augments:** none.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
