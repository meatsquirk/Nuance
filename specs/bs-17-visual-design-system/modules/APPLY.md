# Module APPLY — wire the screens to the design system

**Status:** Done — APPLY-1 ✅ (AC-14), APPLY-2 ✅ (AC-15); module complete, SIGNOFF-1 next
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** screen-level edits across `lib/readout/**`, `lib/capture/**`, `lib/compare/**`, `lib/recipes/**`, `lib/palette/**`, `lib/projects/**`, `lib/display/**`, `lib/onboarding/**` — swapping ad-hoc buttons/cards/labels for the COMPONENTS wrappers, removing residual hardcoded palette colours, and adding the shared swatch caption. Plus a shared caption widget (`lib/widgets/swatch_caption.dart`, new) and the AC-14 source-scan rule.
**Depends on:** THEME, COMPONENTS · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| APPLY-1 | behavior | AC-14 | ✅ Done | 13,043,220 | 37m 15s (54m 20s) |
| APPLY-2 | behavior | AC-15 | ✅ Done | 18,031,030 | 30m 16s (30m 16s) |

## Interface reconciliation

- APPLY introduces no new public interface beyond `SwatchCaption` (a small wrapper around the existing `ColorChip`/swatch surfaces); it is wiring. It must not change any screen's behaviour, layout CHOICE, or semantics — only the surface styling and the colour source.
- **AC-14 scope (D-4):** the source-scan rule flags hardcoded palette `Color(0x…)` in `lib/**` **excluding** `lib/capture/**` camera-device literals (viewfinder stripes, reticle, shutter, feed placeholder), `lib/color_science/**`, `lib/correction/engine/**`, `lib/recipes/engine/**`, `lib/dataset/**`, `lib/domain/**` (these carry colour *data*, not chrome). The ~7 residual chrome literals identified in the gap analysis are the removal target.
- Runs after every component phase so screen swaps use finished wrappers. APPLY-1 is the merge-risky phase (touches many screen files) — run alone.

## Open gates

- None. **G-2** (test review) ✅ Resolved 2026-10-17 (Matt Quirk) — it previously blocked both APPLY phases.

## Phase APPLY-1 — behavior: one theme, no hardcoded palette (AC-14)

- **Kind:** behavior
- **Target AC:** AC-14
- **Depends on:** THEME-4, THEME-5, COMPONENTS-2, COMPONENTS-3, COMPONENTS-4, ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** the screen files above (swaps + colour routing); `integration_test/conformance/checks/` (or the design-system suite) for the source-scan rule.
- **Tasks:**
  1. Swap ad-hoc buttons/cards/labels on each primary screen for `PillButton`/`SpeakButton`/`SurfaceCard`/`MonoLabel` so each screen renders through the single theme.
  2. Route the ~7 residual hardcoded chrome palette colours through `Theme.of(context)` / `AppTheme` tokens (D-4 exclusions untouched).
  3. Add/extend the source-scan rule that fails the build on a hardcoded palette `Color(0x…)` outside the exclusion list, and assert no screen wraps a child in its own `Theme`/`MaterialApp`.
- **Acceptance gate:** un-pend AC-14; `TestAC14_OneThemeNoHardcode` green (now fully discriminating — **augments** the baseline that was partially green) with earlier ACs; every sibling feature suite stays green; unit + coverage gate.
- **Augments:** `TestAC14`: assert **zero** residual palette literals (was partially green at baseline because bs-11 already installs one theme).

### Result

**Scope (user decision 2026-10-18):** AC-14 gate only — route the residual hardcoded
palette literals through the theme + close the augmentation. The wholesale ad-hoc→wrapper
screen swap (plan task 1) was **deferred**: AC-14 (and no AC) gates wrapper usage, the one-theme
invariant already held structurally (one `MaterialApp`, no nested `Theme`), and a blind swap
across 8 screen areas carries untested regression risk to the signed-off bs-07..bs-11 suites.
The wrappers remain available (built + acceptance-tested in COMPONENTS); opting screens into
them is a future, test-backed change. Noted for SIGNOFF-1.

**Landed (lib — 3 files):**
- `lib/app/theme.dart` — added design-system token accessors (D-7): `provenanceTint(tier)`
  (4 const tints, byte-identical to the old `ProvenanceIcon` hexes) and `cvdDemoOriginal` /
  `cvdDemoNeutral` (the onboarding self-calibration illustration pair). Imports `domain/provenance.dart`.
  `ThemeData` **unchanged** — only new statics, so layout/contrast are byte-identical.
- `lib/widgets/provenance_icon.dart` — `tintFor` now delegates to `AppTheme.provenanceTint` (same values).
- `lib/onboarding/screens/result_step.dart` — `_pairOriginal` and `_simulatedColour` read
  `AppTheme.cvdDemoOriginal` / `cvdDemoNeutral` (same values).

**Source-scan refinement + augmentation (test — 3 files):**
- `design_system_source_scan.dart` — `fromARGB`/`fromRGBO` patterns now match only numeric-literal
  args, so the 6 runtime data-reconstructions (`Color.fromARGB(255, x.red, x.green, x.blue)` in
  readout/palette/display/capture/a11y) are no longer false-flagged as hardcoded palette colours
  (they render colour *data*, not chrome — AC-14 / D-4). Hex-literal forms still match.
- `design_system_test.dart` — **closed the pre-seeded TestAC14 augmentation**: AC-14's no-hardcode
  half now asserts residual `isEmpty` at full strength AND **pins the D-4 exclusion set**
  (`kCaptureDeviceLiteralFiles == {capture_live_view.dart}`; dropping it re-exposes only pinned
  capture-device literals, never a screen chrome literal). Un-pend edits to the pending-gate guards
  (un-pended set += AC-14; still-pending exemplar → AC-15). Added a source-scan helper test proving a
  data-reconstruction is not flagged (discriminates the refinement) + a hex-arg `fromARGB` case.
- `bs17/pending.dart` — deleted the `AC-14` row (`pendingACs` now `{AC-15}`).

**Verification** (Flutter 3.47.6 on `~/development/flutter/bin`; no `timeout` on macOS):
- `flutter analyze` on all 6 touched files — **clean**.
- Unit `flutter test` — **1450 / 1450** green (unchanged from COMPONENTS-5; no regression).
- Coverage gate vs BASE `058283c` (`dart run tool/coverage_gate.dart`) — **100% line on all 3 touched
  lib files** (`theme.dart`, `provenance_icon.dart`, `result_step.dart`). Existing provenance_icon /
  result_step / theme unit tests exercise every new accessor branch.
- Acceptance `flutter test -d flutter-tester integration_test/design_system_test.dart` — **GREEN,
  26 passed / 1 skipped**: AC-1..AC-14 run (AC-14 now full strength), only AC-15 pending (APPLY-2).
- Sibling regressions (per-file, the touched packages): **bs-11 accessibility 19/19** (app-wide
  contrast — the required theme/UI GOTCHA), **bs-10 daltonization 25/25** (provenance tint remap),
  **readout 12/12**. bs-07 self_assessment (23 pass) and bs-08 display each carry **one pre-existing
  `flutter-tester` viewport flake** (bs-07 AC-4 off-screen tap @(94.4,656); bs-08 AC-9 off-screen tap
  @(281.1,560)) — **both reproduce identically at BASE `058283c`** with my changes stashed, so they
  predate APPLY-1 and are device-lane artifacts (green on the booted sim those features were signed off
  on). Recorded in Known flakes. The whole `integration_test/` directory can't be launched at once
  (per-file only) — a known device-lane limitation, not a regression.
- **Grade gate: PASS** — independent fresh re-grade appended to `behavior-test-completeness-…md`:
  **AC-14 → straight A** (augmentation closed; the D-4 pin + full-strength `isEmpty` discriminate), all
  un-pended AC-1..AC-14 A, modified guard/helper tests A. 0 plain-B. (See grid for counts.)
- **Fix passes:** 0/3 (green on the first full run; the two sibling failures are pre-existing BASE flakes).
- **Tokens / Time:** 13,043,220 · 37m 15s active (54m 20s wall).

### Checkpoint / Handoff

- **Frozen for APPLY-2:** the single palette source is `AppTheme` (D-7) — screens/widgets read colours
  from the theme and from `AppTheme.provenanceTint` / `cvdDemoOriginal` / `cvdDemoNeutral`; no `lib/`
  file outside `lib/app/theme.dart` and the pinned D-4 set (`lib/capture/capture_live_view.dart`)
  holds a hardcoded palette `Color(0x…)`. The source-scan (`residualPaletteLiterals`) now treats only
  numeric-literal `fromARGB`/`fromRGBO` as hardcoded; data reconstructions are fine. AC-14 is full
  strength (adding a hardcoded palette literal to any screen breaks it).
- **Verification commands:** unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`; acceptance
  `flutter test -d flutter-tester integration_test/design_system_test.dart`
  (`--dart-define=BS17_RUN_PENDING=true` to run AC-15); sibling suites **per-file** on
  `-d flutter-tester` (never the whole dir). Booted sim needed to clear the bs-07/bs-08 viewport flakes.
- **Known gaps:** the wrapper screen-swap (plan task 1) is deferred (see Result) — SIGNOFF-1 should note
  the components are available but not yet opted into every screen. The two pre-existing sibling
  viewport flakes are bs-07/bs-08 device-lane artifacts, not bs-17 regressions.
- **Next:** **APPLY-2** (AC-15 — the shared swatch approximation caption; `lib/widgets/swatch_caption.dart`
  new + swatch call sites). It is **not** disjoint from APPLY-1's screen files but APPLY-1 touched no
  swatch call site, so no conflict; run after this. Then **SIGNOFF-1**.

## Phase APPLY-2 — behavior: swatch approximation caption (AC-15)

- **Kind:** behavior
- **Target AC:** AC-15
- **Depends on:** COMPONENTS-4, ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `lib/widgets/swatch_caption.dart` (new); the screen swatch call sites (readout, compare A/B swatches, recipes target/paint dots, palette paint rows).
- **Tasks:**
  1. Add `SwatchCaption` — a shared caption carrying the "approximate — trust the numbers" message, foldable into the swatch's semantics so it reads once.
  2. Attach it to every rendered colour swatch; reuse the existing readout "a hint, not the message" copy where one already exists rather than duplicating.
- **Acceptance gate:** un-pend AC-15; `TestAC15_SwatchCaption` green with earlier ACs; unit + coverage gate.

### Result

**Scope note:** the spec lists swatches on readout, compare A/B, recipes dots and palette rows,
but only three roster screens actually render a counted swatch (a `ColorChip` with a non-null
`color`): **readout** (always), **capture** (the live reading, when a sample exists under a
colour-science scope) and **palette** (the paint rows, when paints exist under a scope). Compare
and recipes render no `ColorChip`, so the AC-15 sweep skips them. The caption is attached **once
per swatch-bearing screen** (not per swatch) — the G-2-accepted screen-grain reading. No existing
"a hint, not the message" copy was present in `lib/` to reuse (the pre-seeded table assumed one),
so this phase introduces the single shared copy.

**Landed (lib — 4 files, +1 new):**
- `lib/widgets/swatch_caption.dart` (**new**) — `SwatchCaption`: an `APPROX.` `MonoLabel` eyebrow
  + the line "Swatches are screen approximations. Trust the numbers.", folded into one `Semantics`
  node (`captionKey`, `excludeSemantics`, `label == message`) so a screen reader announces it once.
  The line uses the muted `colorScheme.onSurfaceVariant` role from the one theme — no palette
  literal (AC-14 holds).
- `lib/readout/value_region.dart` — one `SwatchCaption` after the region's single `ColorChip`
  (unconditional; the region always renders a swatch).
- `lib/capture/capture_screen.dart` — one `SwatchCaption`, gated `currentSample != null &&
  AppScope.maybeOf(context)?.colorScience != null` (exactly when `CaptureCurrentReading` draws its
  live swatch).
- `lib/palette/paint_list_region.dart` — one `SwatchCaption` below the paint rows, gated
  `paints.isNotEmpty && science != null` (exactly when the rows render masstone swatches).

**Un-pend + tests (test — 5 files):**
- `integration_test/bs17/pending.dart` — deleted the `AC-15` row; `pendingACs` is now **empty**
  (AC-15 was the last pending AC).
- `integration_test/design_system_test.dart` — updated the two pending-gate guard tests for the
  terminal empty-map state: the coverage guard now pins `unpended == every AC-1..AC-15` and asserts
  `pendingACs` **isEmpty**; the mode guard asserts all 15 ACs run in both the default and
  run-pending modes. AC-15's own test runs by default now (was skipped).
- new `test/widgets/swatch_caption_test.dart` (5 cases); AC-15 assertions added to
  `test/readout/value_region_test.dart`, `test/capture/capture_screen_test.dart` (true + both
  false paths), `test/palette/paint_list_region_test.dart` (swatch/no-scope/no-paint cases).
- `test/readout/readout_screen_test.dart` — the AC-12 acknowledge test now `ensureVisible`s the
  Acknowledge control before tapping: the AC-15 caption makes the scrollable readout body taller so
  the last ListView item can sit below the 800px test viewport. **Assertion unchanged** (marker
  clears on Acknowledge) — a scroll-into-view adaptation to a real, intended layout addition, not a
  weakening.

**Verification** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS; BASE `5bdb14c`):
- `flutter analyze` on all 10 touched files — **clean**.
- Unit `flutter test` — **1459 / 1459** green (1450 + 9 new AC-15 cases).
- Coverage gate (`dart run tool/coverage_gate.dart 5bdb14c`) — **100% line on all 4 touched lib
  files** (`swatch_caption.dart`, `value_region.dart`, `capture_screen.dart`, `paint_list_region.dart`).
- Acceptance `flutter test -d flutter-tester integration_test/design_system_test.dart` — **GREEN,
  27 passed / 0 skipped**: AC-1..AC-15 all run (AC-15 un-pended; the previous 1 skip is gone).
- Sibling regressions (per-file on `-d flutter-tester`): **bs-11 accessibility 19/19** (the required
  app-wide-contrast regression — the caption's muted role clears AA), **bs-10 daltonization 25/25**,
  **readout 12/12**, **capture 19/19**. **palette** 19/21: AC-3 (provenance legend region) and AC-5
  (palette selector "Travel set") fail — **both reproduce identically at BASE `5bdb14c` with my
  changes stashed**, so they are pre-existing bs-06 `flutter-tester` viewport artifacts (green on a
  booted sim), NOT APPLY-2 regressions. Recorded in Known flakes.
- **Grade gate: PASS** — independent fresh re-grade appended to
  `behavior-test-completeness-…md`: **AC-15 → A**; AC-1..AC-14 carry forward A; both reworked
  pending-gate guards A (non-vacuous: assert the empty map's expected contents). 0 plain-B.
- **Fix passes:** 1/3 — first unit run surfaced 3 failures, all in test code: two brittle assertions
  in my new `swatch_caption_test` (fontSize) / `capture_screen_test` (the controller auto-samples),
  and the readout AC-12 tap needing `ensureVisible`. Also refined the capture gate to require a
  colour-science scope (so no caption renders without a swatch). Green on the next run.
- **Tokens / Time:** 18,031,030 · 30m 16s active (30m 16s wall).

### Checkpoint / Handoff

- **Frozen for SIGNOFF-1:** `SwatchCaption` (`lib/widgets/swatch_caption.dart`) is the single
  swatch-approximation caption; readout/capture/palette each render it once beside their swatch
  group (capture & palette gated to appear exactly when a swatch does). `pendingACs` is empty — all
  15 bs-17 ACs run by default. AC-15's sweep counts `ColorChip` with a non-null `color`; compare and
  recipes render none and are skipped.
- **Verification commands:** unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`; acceptance
  `flutter test -d flutter-tester integration_test/design_system_test.dart` (all 15 run by default);
  sibling suites **per-file** on `-d flutter-tester` (never the whole dir). A booted sim clears the
  bs-06/bs-07/bs-08 viewport flakes.
- **Known gaps:** the wrapper screen-swap remains deferred from APPLY-1 (components available but not
  opted into every screen) — SIGNOFF-1 to note. The pre-existing palette (AC-3/AC-5), bs-07 and
  bs-08 `flutter-tester` viewport flakes are device-lane artifacts, not bs-17 regressions.
- **Next:** **SIGNOFF-1** — the sign-off packet + summary page + the human decision. All behavior
  phases are now done; the AC coverage table is fully ✅.
