# Sign-off packet — Apply the visual design system (bs-18) — Round 1

**Feature:** bs-18-apply-visual-components · **Spec:** [bs-18-apply-visual-components.feature](../../bs-18-apply-visual-components.feature)
**Prepared:** 2026-10-20 (SIGNOFF-1) · **At code:** `feat/bs-18-apply-visual-components` @ `9d0436d` (GUARD-3, the last behaviour commit; the sign-off commit is stamped on the decision)
**Decision:** ✅ **Approved** — 2026-10-20 by **Matt Quirk** at code `9d0436d` (SIGNOFF-DECISION). Feature `Status: Done`; ready to merge to `main`.

bs-18 resumes the "wholesale screen swap" that bs-17 shipped the components for but deliberately deferred (bs-17 APPLY-1, owner decision 2026-10-18). It **opts every primary screen and the app chrome into the finished bs-17 design-system wrappers** — `PillButton`, `SpeakButton`, `SurfaceCard`, `MonoLabel`, `SwatchCaption`, `ProvenanceBadge` — builds the wireframe's **bottom navigation + top bar** (previously classified "presentation / not specified"), and **fixes the Capture-screen warning-banner overlap**. It is presentation only (D-2): it changes the widget that renders a control or region, never a screen's behaviour, data, numbers, routing semantics or spoken output. All 14 acceptance criteria are automated, coded, un-pended and green by default (== run-pending; the pending map is empty). A fresh independent whole-suite re-grade (this session, fresh context) is **17 A / 0 below A** — 14 AC tests + 3 scaffold guards all straight A. This packet is the evidence for the decision.

The restyle is held to — but does not re-assert — the measurable accessibility criteria bs-11 owns; AC-13 runs the bs-11 target/contrast conformance check over every swapped screen as an app-wide regression. Only the **light** warm-paper theme is in-bound; the wireframe's dark theme remains deferred (bs-17 D-3).

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 20/21 phases ✅ Done (CHROME-1/2, ITEST-1…5, CHROME-3/4, READ-1/2/3, FLOW-1/2, ORG-1/2, CFG-1, GUARD-1/2/3); SIGNOFF-1 is this phase |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-14 all ✅ Done (all 14 automated) |
| Pending list empty | ✅ `integration_test/visual_application/pending.dart` → `pendingACs` is `{}`; all 14 ACs run in **both** default and run-pending modes (identical) |
| No open row in ITEST *Test augmentations* | ✅ all seven closed/satisfied — TestAC03→READ-1, TestAC05→READ-3, TestAC07→FLOW-2, TestAC08→ORG-1 closed by their behaviour phases; TestAC11/AC12/AC14 satisfied at ITEST-4 (dynamic sweeps + controls) |
| Fresh whole-suite grade grid all A | ✅ **17 A / 0 below A** (fresh-context independent re-grade this session: 14 AC tests + 3 scaffold guards). Appended to [behavior-test-completeness-bs-18-apply-visual-components.md](../behavior-test-completeness-bs-18-apply-visual-components.md) as "SIGNOFF-1 — whole-suite re-grade". One non-blocking transparency item (smoke_test owner-validity loop vacuous in isolation, covered non-vacuously by two companion guards) — recommended cheap hardening applied this phase |
| Decision/dependency gates | G-1 (spec) ✅ 2026-10-19, G-2 (test review) ✅ 2026-10-19. No G-3 for bs-18 |

---

## 2. Full verification (this session, 2026-10-20)

Toolchain: Flutter 3.47.6 (project-local, `~/development/flutter/bin`); Dart 3.13.5; no `timeout`/`gtimeout` on macOS. Machine-readable results (`flutter test --machine`) were produced for the bs-18 suite on this run; the summary page (§7) is built from them.

**Lanes.** This repo's canonical acceptance lane is **`-d flutter-tester`** (the host VM, cwd = repo root): bs-18's suite pumps the production `buildApp`/screens there, and the bs-11/bs-12/bs-13 siblings carry source-scan ACs that read `lib/` from the repo root and so are flutter-tester-native. The whole `integration_test/visual_application/` directory will not launch at once under sustained load (a device-saturation lane flake, not a test failure — see Known flakes); each `*_test.dart` is therefore run in its own invocation.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze lib integration_test/visual_application` | **No issues found!** (clean) |
| Unit + coverage | `flutter test --coverage test/` | **1676 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart 9d0436d` | **PASS** — "no touched `lib/**`.dart files vs 9d0436d — nothing to gate"; the sign-off BASE is HEAD, so this phase touches no `lib/`; the 28 touched `lib/` files each reached 100% of their added/changed lines at the phase that landed them (recorded in the module Results) |
| Acceptance — bs-18 (default) | each `integration_test/visual_application/<file>_test.dart` `-d flutter-tester --machine` | **29 passed, 0 failed, 0 skipped** across 10 files (`{"success":true}` each) |
| Acceptance — bs-18 (run-pending) | same `+ --dart-define=BS18_RUN_PENDING=true` | **29 passed, 0 failed, 0 skipped** — identical to default (pending map empty) |
| Cross-feature regression (flutter-tester, 19 suites) | each sibling `integration_test/*_test.dart` + bs11/bs12/bs13/bs14 | **341 passed, 3 failed, 0 skipped** — the 3 fails are the pre-existing off-lane flakes below, **not** bs-18 regressions |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **17 A / 0 below A — PASS** (14 AC tests + 3 scaffold guards) |

bs-18 own suite per file (both modes identical): smoke 14 · chrome 2 (AC-1/2) · capture 2 (AC-3/4) · readout 1 (AC-5) · compare 1 (AC-6) · recipes 2 (AC-7 main + out-of-gamut) · palette 1 (AC-8) · projects 1 (AC-9) · config 1 (AC-10) · guards 4 (AC-11..14) = **29 pass**.

Cross-feature regression per suite (flutter-tester): harness 5 · capture 19 · advanced_capture 21 · readout 12 · comparison 26 · recipes 24 · correction 22 · palette **21 (+2 flake)** · self_assessment 24 · display **20 (+1 flake)** · daltonization 25 · design_system 27 · bs11/accessibility 19 · bs12/nfr 33 · bs13/dataset 19 · bs14/consent 5 · bs14/exchange 3 · bs14/harness 12 · bs14/refine 4 = **341 pass / 3 pre-existing flakes**.

**The 3 failures, all pre-existing carried flakes in the Known flakes table, measured at the merge-base `c00422f`:**
- **palette AC-3** ("the provenance legend explains the four confidence tiers") — bs-06 device-lane viewport artifact (`Found 0 widgets with key palette-provenance-legend-region` — the off-screen-fold symptom); green on the booted sim.
- **palette AC-5** ("selecting a palette re-points recipe search") — bs-06 device-lane artifact (`Found 0 widgets with text "Travel set"`); reproduces at BASE.
- **display AC-9** ("one consistent spoken phrasing") — bs-08 off-screen-tap viewport artifact; green on the booted sim.

bs-18 touches no palette provenance-legend layout, no travel-set selection, and no speech phrasing (D-2), so it introduces **zero** regressions. bs-17's sign-off corroborated with a full booted-sim run that these same flakes go green on the sim (bar the device-independent bs-06 palette AC-5) and reproduce identically at the merge-base `c00422f`; every bs-18 behaviour phase re-verified its siblings and saw only these carried flakes.

**What bs-18 changes in `lib/`** (28 files, +1305 / −491 vs `d3a1c4f`): the new app chrome `lib/app/{app_destinations,app_shell,app_top_bar}.dart` + the `build_app.dart` 4-destination `IndexedStack` shell and `main.dart` wiring (CHROME); `lib/capture/{capture_controls,capture_live_view,capture_screen}.dart` (shutter/pills + the warning-overlap relaid as a vertical `SurfaceCard` run); `lib/readout/{actions_bar,readout_screen}.dart` (cards + mono eyebrows + speak FAB + compare/recipes pills); `lib/compare/{actions_bar,comparison_screen}.dart`; `lib/recipes/{recipe_list_region,gamut_banner,recipes_screen}.dart`; `lib/palette/{paint_list_region,palette_screen,projects_region,vision_profile_card}.dart`; `lib/display/settings_screen.dart`; the seven `lib/onboarding/screens/*.dart`; and a small `lib/app/theme.dart` chrome-token addition. No colour science, mixing engine, capture pipeline, routing or persistence is touched.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green in both modes; each had a genuine red baseline (or a green-at-baseline with a discriminating control, for AC-1/11/12/13/14) and asserts the design-system wrapper **present** AND the superseded ad-hoc widget **absent** (D-3).

| AC | Scenario (Rule) | Acceptance test (integration) | Behaviour phase | Status |
|---|---|---|---|---|
| AC-1 | The app shows the design-system bottom navigation | `AC-1: …bottom navigation` (chrome) | CHROME-3 | ✅ A |
| AC-2 | Each primary screen shows the design-system top bar | `AC-2: …top bar` (chrome) | CHROME-4 | ✅ A |
| AC-3 | The Capture screen's controls render as design-system components | `AC-3: …capture controls` (capture) | READ-1 | ✅ A |
| AC-4 | The Capture screen's warnings stack without overlapping | `AC-4: …warnings` (capture) | READ-2 | ✅ A |
| AC-5 | The Readout screen renders its regions as cards with mono eyebrows and a speak FAB | `AC-5: …readout` (readout) | READ-3 | ✅ A |
| AC-6 | The Compare screen renders its controls and rows as design-system components | `AC-6: …compare` (compare) | FLOW-1 | ✅ A |
| AC-7 | The Recipes screen renders recipes as cards with mono notes and pill actions | `AC-7: …recipes` (recipes) | FLOW-2 | ✅ A |
| AC-8 | The Palette screen renders paints, provenance and the add action as design-system components | `AC-8: …palette` (palette) | ORG-1 | ✅ A |
| AC-9 | The Projects region renders projects as cards with pill actions | `AC-9: …projects` (projects) | ORG-2 | ✅ A |
| AC-10 | The Display and Onboarding screens render through the design system | `AC-10: …display + onboarding` (config) | CFG-1 | ✅ A |
| AC-11 | Every screen inherits the one installed theme | `AC-11: …single theme` (guards) | GUARD-2 | ✅ A |
| AC-12 | Every swatch-bearing screen carries its approximation caption | `AC-12: …swatch caption` (guards) | GUARD-1 | ✅ A |
| AC-13 | The restyle preserves accessibility | `AC-13: …a11y preserved` (guards) | GUARD-3 | ✅ A |
| AC-14 | No new hardcoded palette colours are introduced | `AC-14: …no hardcoded palette` (guards) | GUARD-2 | ✅ A |

---

## 4. Design decisions behind the acceptance (for the reviewer)

- **D-1 The default app becomes a 4-destination `IndexedStack`** (Capture / Compare / Recipes / Palette) under one `Scaffold` with the new bottom nav + top bar, replacing the entry-precedence single `_home()` for the default route. Deep-link entries still open their own screen. The wireframe's nav/top bar were "presentation / not specified"; the owner expanded scope on 2026-10-19 to match the mock.
- **D-2 Presentation only.** A phase changes only the widget rendering a control/region — never a screen's behaviour, data, numbers, routing semantics or spoken output. This keeps the signed-off bs-01..bs-14 / bs-17 suites green and is why the acceptance tests are structural (present-wrapper + absent-ad-hoc).
- **D-3 The acceptance tests assert the wrapper present AND the ad-hoc widget absent** for each named control/region, because several screens were already partly swapped by bs-17 — a present-only assertion would pre-pass and not discriminate a no-op. A presentation-only `ThemeToggleButton` was added for AC-2's theme toggle.
- **D-4 The bs-17 AC-14 source-scan rule is reused unchanged** (same exclusion list: camera-device literals in `lib/capture/**`, colour-data modules) over the newly-swapped screens — one source-scan chokepoint, no second palette definition.
- **D-6 The AC-4 warning fix lays the capture banners in a single vertical run** of `SurfaceCard` banners (Column/stacked offsets) instead of the same-origin `Positioned` banners that caused the observed overlap — the root cause in `capture_live_view.dart`.
- **D-7 CHROME phases own `build_app.dart`**; no other phase edits it, so the screen-group modules stayed disjoint and parallelisable (it avoided the `build_app.dart` merge conflicts seen across bs-07/bs-11/bs-17).

---

## 5. Known gaps and deferred items

- **Presentation-only scope (D-2).** No screen's behaviour, data, numbers, routing or spoken output changed; every AC is a structural widget-level fact. No AC was closed by a user-accepted gap — every AC passed its gate.
- **The bs-17 APPLY-1 Capture warning-overlap was addressed here** by READ-2 (AC-4): the banners now lay out in a single non-overlapping vertical run, verified rect-disjoint at 200% text scale.
- **D-3 dark theme still deferred** (bs-17): only the light warm-paper theme is in-bound; `buildApp` wires light only. The presentation-only theme toggle added for AC-2 switches within the installed theme's modes, not to a new dark palette.
- **In-step onboarding answer buttons left as `TextButton`.** Onboarding navigation (continue/back/see-result) renders as pills and each step sits in a `SurfaceCard` (AC-10); the in-step *answer-selection* buttons were kept as `TextButton` per the FLOW-1 rule (they are content choices inside a step, not step navigation). AC-10's test asserts the navigation controls and step cards, which is the scenario's grain.
- **Carried sibling flakes (not bs-18's):** the pre-existing off-lane device-lane flakes — **bs-06 palette AC-3/AC-5** and **bs-08 display AC-9** (flutter-tester-native fails off the exclusive iOS-sim lane) — reproduce at the merge-base `c00422f` and belong to the merged bs-06/bs-08 suites, not to bs-18. The whole-`visual_application/`-dir launch saturation under sustained load is an environment/lane artifact (each file passes run alone), not a test failure.

---

## 6. Gates

| Gate | Kind | Status |
|---|---|---|
| G-1 | decision — approve the spec (recorded on the spec's first line) | ✅ Resolved 2026-10-19 07:33 EDT — Matt Quirk |
| G-2 | decision — approve the acceptance tests (ITEST-5's packet) | ✅ Resolved 2026-10-19 19:48 EDT — Matt Quirk (14 pending acceptance tests approved as-is; 6 non-blocking reviewer items carried to their owning behaviour phases — notably AC-6 cross-screen ownership, resolved by FLOW-1) |

No open gates. No G-3 for bs-18.

---

## 7. Token usage and cost per AC

From the *Token usage* ledger (24 sessions, **211,394,457 tokens**) priced at API list rates (2026-09-25); all 24 sessions priced from their transcripts. **Feature total: $181.81** (input $0.01, cache write $46.89, cache read $102.41, output $32.50). Span: first start 2026-10-19 06:13 EDT → last end 2026-10-20 18:05 EDT; **Σ active 8h 38m (Σ wall 16h 28m)**.

Per-stage token subtotals (computed from the ledger; they sum to the feature total): activities (plan, gate, test-review decision) 8.07M (3.8%) · scaffold 5.04M (2.4%) · shells 19.06M (9.0%) · acceptance-tests 32.42M (15.3%) + test-review 1.08M (0.5%) · **behaviour 138.94M (65.7%)** · sign-off 6.78M (3.2%). Fully-loaded cost per AC (direct + an even 1/14 share of all shared work) is **$12.99** each.

> Note: `ac_cost.py`'s **direct** per-AC attribution did not resolve this plan's module-dashboard *Target AC* cells (same limitation as bs-17), so its direct split reads $0 and its coarse buckets lump the behaviour stage into "activities"; the per-stage subtotals above are computed directly from the ledger rows and are authoritative, and the **fully-loaded** per-AC figure and feature total reconcile with the ledger's Feature total. Full file: [cost-per-ac-round-1.md](cost-per-ac-round-1.md).

Summary scorecard: https://claude.ai/artifact/REu96j2K9r8YzhNkM9zL9T — headline checked against this run (14/14 ACs, 17 A/0, unit 1676/0, bs-18 29/29 both modes, cross-feature 341 pass with 3 pre-existing flakes reproducing at BASE `c00422f`).

---

## 8. Manual walkthrough — how a reviewer sees each Rule working

All commands run from `/Users/matthew.quirk/Nuance` with `~/development/flutter/bin` on `PATH`, each `*_test.dart` in its own invocation (the lane saturates relaunching across entrypoints):

```
cd /Users/matthew.quirk/Nuance && export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze lib integration_test/visual_application
flutter test --coverage test/ && dart run tool/coverage_gate.dart 9d0436d
for f in smoke chrome capture readout compare recipes palette projects config guards; do
  flutter test -d flutter-tester integration_test/visual_application/${f}_test.dart
done
# run-pending mode (identical — pending map empty): add --dart-define=BS18_RUN_PENDING=true
```

To *see* it, launch the app (`flutter run`): the home screen is now the 4-destination shell with the bottom nav + top bar; every screen reads in the warm-paper system.

**Rule — the app chrome is the wireframe's nav + top bar (AC-1, AC-2).**
`chrome_test.dart` pumps the default route and reads `AppShell.bottomNavKey`: the bar exposes 4 destination keys (Capture/Compare/Recipes/Palette), the active destination carries a non-colour active marker (filled-vs-outline icon, not colour only), and its `DecoratedBox` colours equal the installed theme tokens — rejecting a nav drawn with colour-only active state or a missing destination. AC-2 pumps each destination and reads `AppTopBar`: the title `Text` uses the Atkinson family, and the theme-toggle control is present on every primary surface.

**Rule — Capture controls are design-system components (AC-3).**
`capture_test.dart` asserts the shutter at `CaptureControls.captureKey` renders as the ~88px round button, the primary actions are `PillButton`s, and — via the READ-1 augmentation — a full sweep finds **no** ad-hoc `TextButton`/`ElevatedButton` left among every capture control (dismiss/lock/calibrate/import/value-only/capture/torch/sample/send + the three radius options). The BASE had 10 ad-hoc buttons, so the sweep genuinely discriminates a partial swap.

**Rule — Capture warnings stack without overlapping (AC-4).**
`capture_test.dart` pumps ≥2 active warnings at `textScaleFactor=2.0` and asserts their render rects do not intersect (`!rectA.overlaps(rectB)`) — the D-6 single-vertical-run fix. The current-bug control (same-origin `Positioned` banners) is what the test rejects; keys, text, visibility and semantics are unchanged.

**Rule — Readout regions are cards with mono eyebrows and a speak FAB (AC-5).**
`readout_test.dart` asserts value/name/space regions each have a `SurfaceCard` ancestor, each eyebrow is a `MonoLabel`, and the widget at `ActionsBar.speakKey` `isA<SpeakButton>()` (the READ-3 augmentation discriminates the pre-swap tree, where speak was an `OutlinedButton` there) — the old `Card`/plain speak `IconButton` are absent.

**Rule — Compare controls and rows are design-system components (AC-6).**
`compare_test.dart`: "Compare as A/B" are outline pills, "Find mixing recipes" is an ink-filled pill, the difference and statement regions sit in `SurfaceCard`s, and the compare speak action is a `SpeakButton` FAB. FLOW-1 resolved the G-2 cross-screen ownership (those actions physically live in `lib/readout/actions_bar.dart`).

**Rule — Recipes render as cards with mono notes and pill actions (AC-7).**
`recipes_test.dart`: each recipe row sits in a `SurfaceCard`, the ranked-by note and the out-of-gamut note (pumped via an out-of-gamut target) render as `MonoLabel`s, and the recipe actions are pills — the old Material `Card` rows absent.

**Rule — Palette rows, provenance and add are design-system components (AC-8).**
`palette_test.dart`: each paint row renders through the design-system row/chip with a per-row `ProvenanceBadge` (glyph-and-border), and the add-from-dataset action is a `PillButton` — the old ad-hoc add button absent.

**Rule — Projects render as cards with pill actions (AC-9).**
`projects_test.dart` switches to the Projects view and asserts each project entry sits in a `SurfaceCard`, with open (`PillButton.primary`) and export (`PillButton.secondary`) pills — both ad-hoc `TextButton`s gone.

**Rule — Display and Onboarding render through the design system (AC-10).**
`config_test.dart` opens Display settings via the real chrome entry (`pumpDisplaySettings`) and asserts the simulation/theme options are pills; `pumpOnboarding` asserts each step's content sits in a `SurfaceCard` with continue/see-result pills.

**Rule — cross-cutting guards hold app-wide (AC-11, AC-12, AC-13, AC-14).**
`guards_test.dart` sweeps the 7-screen roster: AC-11 — exactly one `MaterialApp` and no scheme-overriding `Theme` per screen (control: a nested app+scheme flags both); AC-12 — exactly one `SwatchCaption` on each `ColorChip`-bearing screen (controls: an uncaptioned chip `findsNothing`, two captions `findsNWidgets(2)`); AC-13 — the bs-11 `runConformanceCheck` `tapTarget48 && contrastAA` on each screen (controls: a 24dp target + ~1.6:1 text each flagged); AC-14 — `residualPaletteLiterals(['lib'], exempt {…})` empty (control: a planted `Color(0x..)` temp file flagged, comment/string masked).
