# Sign-off packet — Visual design system (bs-17) — Round 1

**Feature:** bs-17-visual-design-system · **Spec:** [bs-17-visual-design-system.feature](../../bs-17-visual-design-system.feature)
**Prepared:** 2026-10-18 (SIGNOFF-1) · **At code:** `feat/bs-17-visual-design-system` @ `2f779b1` (APPLY-2; the sign-off commit is stamped on the decision)
**Decision:** ⏸ **Awaiting** — a human records it via `/feature-next-phase --signoff bs-17-visual-design-system approved | changes "<items>"`.

bs-17 gives the app one deliberate skin, taken from the wireframe. It rewrites the single `AppTheme` chokepoint (`lib/app/theme.dart`) to the **warm-paper** `ColorScheme`, the **Atkinson Hyperlegible Next/Mono** families (bundled offline, no `google_fonts`), the stadium-pill / rounded-card shapes, the 1/2/3px border scale and the uppercase-tracked mono micro-label; adds a small **styled-component set** (`lib/widgets/`: `PillButton`, `SpeakButton`, `SurfaceCard`, `MonoLabel`, `SwatchCaption`) and the provenance-badge glyph-and-border signature; then **applies** the system across every primary screen — routing the last residual hardcoded palette literals through the theme and placing the shared swatch-approximation caption wherever a colour swatch renders. All 15 acceptance criteria are automated, coded, un-pended and green by default (== run-pending; the pending map is empty). A fresh independent whole-suite re-grade is **15 A / 0 below A**. This packet is the evidence for the decision.

The skin is **styling only**: it does not re-assert the measurable accessibility criteria bs-11 owns (contrast ratio, 200% scaling, 48dp targets, screen-reader semantics) — it is held to them, and the bs-11 contrast suite is run here as an app-wide-contrast regression (19/19). Only the **light** warm-paper theme is in-bound; the wireframe's dark theme is deferred (D-3).

---

## 1. Preconditions (checked mechanically, not from memory)

| Precondition | State |
|---|---|
| Every other phase done | ✅ 17/18 phases ✅ Done (THEME-1/2, COMPONENTS-1, ITEST-1…4, THEME-3/4/5, COMPONENTS-2/3/4/5, APPLY-1/2); SIGNOFF-1 is this phase |
| Every AC ✅ in the coverage table | ✅ AC-1…AC-15 all ✅ Done (all 15 automated) |
| Pending list empty | ✅ `integration_test/bs17/pending.dart` → `pendingACs` empty; all 15 ACs run in **both** default and run-pending modes (27/0 == 27/0) |
| No open row in ITEST *Test augmentations* | ✅ all four closed — TestAC10/AC12 closed at ITEST-3 authoring (tests already mount the real variants); TestAC07 closed COMPONENTS-2 (pill) + COMPONENTS-4 (card); TestAC14 closed APPLY-1 (zero residuals at full strength + pinned D-4 set) |
| Fresh whole-suite grade grid all A | ✅ **15 A / 0 below A** (fresh-context independent re-grade, this session; both previously A-core/B-pending rows — AC-7, AC-14 — now straight A). Appended to [behavior-test-completeness-bs-17-visual-design-system.md](../behavior-test-completeness-bs-17-visual-design-system.md) as "SIGNOFF-1 — whole-suite re-grade" |
| Decision/dependency gates | G-1 (spec + scope expansion) ✅, G-2 (test review) ✅. No G-3 for bs-17 |

---

## 2. Full verification (this session, 2026-10-18)

Toolchain: Flutter 3.47.6 (project-local, `~/development/flutter/bin`); Dart 3.13.5; no `timeout` on macOS. Machine-readable results (`flutter test --machine`) were produced on this run; the summary page (§7) is built from them.

**Lanes.** This repo's canonical acceptance lane is **`-d flutter-tester`** (the host VM, cwd = repo root): bs-17's own suite pumps `buildApp` there, and the bs-11/bs-12/bs-13 suites carry **source-scan** ACs that read `lib/` from the repo root and so are flutter-tester-native. Every bs-17 behaviour phase verified its sibling regressions on flutter-tester; SIGNOFF-1 does the same for the whole repo.

| Gate | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze lib integration_test/design_system_test.dart integration_test/bs17` | **No issues found!** (clean) |
| Unit + coverage | `flutter test --coverage` | **1459 passed, 0 failed, 0 skipped** |
| Coverage gate | `dart run tool/coverage_gate.dart <BASE>` | **PASS** — the sign-off BASE is HEAD (`2f779b1`), so no `lib/` is touched by this phase; the 12 touched `lib/` files each reached **100% line coverage of their added/changed lines** at the phase that landed them (THEME-3/4/5, COMPONENTS-2/4/5, APPLY-1/2), recorded in the module Results |
| Acceptance — bs-17 (default) | `flutter test -d flutter-tester integration_test/design_system_test.dart --machine` | **27 passed, 0 failed, 0 skipped** (15 AC tests + 11 scaffold + the AC-15 sub-cases) |
| Acceptance — bs-17 (run-pending) | same `+ --dart-define=BS17_RUN_PENDING=true` | **27 passed, 0 failed, 0 skipped** — identical to default (pending map empty) |
| Cross-feature regression (flutter-tester, 15 suites) | each `integration_test/*_test.dart` `-d flutter-tester --machine` | **316 passed, 4 failed, 0 skipped** — the 4 fails are pre-existing device-lane viewport flakes (below), **not** bs-17 regressions |
| Flake reproduction at BASE | the 3 affected suites at the merge-base `c00422f` (main, pre-bs-17), flutter-tester | **identical 4 failures** (palette 21/2, self_assessment 23/1, display 20/1) — proves bs-17 introduced **zero** regressions |
| Grade grid (fresh context) | whole-suite re-grade vs G1–G6 | **15 A / 0 below A — PASS** |

Per-suite (flutter-tester): harness 5 · capture 19 · advanced_capture 21 · readout 12 · comparison 26 · recipes 24 · correction 22 · palette **21 (+2 flake)** · self_assessment **23 (+1 flake)** · display **20 (+1 flake)** · daltonization 25 · bs11/accessibility **19** · bs12/nfr **33** · bs13/dataset **19** · design_system **27** = **316 pass / 4 pre-existing flakes**.

**The 4 failures, all pre-existing and all reproducing identically at the merge-base `c00422f`:**
- palette AC-3 (provenance legend region) — bs-06 device-lane viewport artifact; **green on the booted sim**.
- palette AC-5 (travel-set selection) — bs-06 device-lane artifact; reproduces at BASE on both flutter-tester **and** the sim.
- self_assessment AC-4 (intake diagnosis seeds the prior) — bs-07 off-screen-tap viewport artifact; **green on the booted sim**.
- display AC-9 (one consistent spoken phrasing) — bs-08 off-screen-tap viewport artifact; **green on the booted sim**.

**Sim corroboration.** A full booted-iPhone-17 run was also taken. It confirms 3 of the 4 flutter-tester flakes go green on the sim (palette AC-3, self_assessment AC-4, display AC-9), and leaves palette AC-5 red (device-independent bs-06 pre-existing failure). The sim run also fails the bs-11/bs-12/bs-13 **source-scan/contrast** ACs — expected, because those suites read `lib/` from the repo root and are flutter-tester-native; those failures are an artifact of running them off their home lane, not bs-17 regressions. Net: on the canonical flutter-tester lane, bs-17 is green but for 4 inherited flakes that predate it.

**What bs-17 changes in `lib/`** (12 files, +742 / −60 vs `c00422f`): `lib/app/theme.dart` rewritten to the warm-paper tokens + Atkinson families + shape/border/label styles (the one D-7 chokepoint); five new styled widgets `lib/widgets/{pill_button,speak_button,surface_card,mono_label,swatch_caption}.dart`; the provenance-badge signature on `lib/widgets/provenance_badge.dart` (+ `provenance_icon.dart`); and small theme-routing / caption edits on four screens (`lib/capture/capture_screen.dart`, `lib/onboarding/screens/result_step.dart`, `lib/palette/paint_list_region.dart`, `lib/readout/value_region.dart`). No colour science, mixing engine, capture pipeline or persistence is touched.

---

## 3. Per-AC result

Each AC's acceptance test is un-pended and green in both modes; each had a genuine red baseline at ITEST-2/3 and carries a discriminating control. The component ACs mount the real widget through the exact `AppTheme.light().themeData` `buildApp` installs (D-7).

| AC | Scenario (Rule) | Acceptance test (integration) | Behaviour phase(s) | Status |
|---|---|---|---|---|
| AC-1 | Surfaces use the warm-paper palette | `AC-1: Surfaces use the warm-paper palette` | THEME-3 | ✅ A |
| AC-2 | Ink, muted text and hairlines use the warm-paper neutrals | `AC-2: …neutrals` | THEME-3 | ✅ A |
| AC-3 | The primary action colour is the cobalt accent | `AC-3: …cobalt accent` | THEME-3 | ✅ A |
| AC-4 | The warm-paper palette still meets the AA contrast floor | `AC-4: …contrast floor` | THEME-3 | ✅ A |
| AC-5 | Prose and headings render in Atkinson Hyperlegible Next | `AC-5: …Atkinson Hyperlegible Next` | THEME-4 | ✅ A |
| AC-6 | Micro-labels and readouts render in Atkinson Hyperlegible Mono | `AC-6: …Atkinson Hyperlegible Mono` | THEME-4 | ✅ A |
| AC-7 | Buttons render as pills and cards as rounded panels | `AC-7: …pills and …rounded panels` (+ rendered-instance via AC-10/AC-12) | THEME-5 (+ COMPONENTS-2/4 augment) | ✅ A |
| AC-8 | Borders follow the weight scale | `AC-8: …weight scale` | THEME-5 | ✅ A |
| AC-9 | Monospace micro-labels render uppercase with wide tracking | `AC-9: …uppercase…` | THEME-5 | ✅ A |
| AC-10 | Primary ink-filled pills, secondary outline pills | `AC-10: …ink-filled…/outline pills` | COMPONENTS-2 | ✅ A |
| AC-11 | The speak action renders as a round accent FAB | `AC-11: …round accent floating button` | COMPONENTS-3 | ✅ A |
| AC-12 | Panels render as bordered surface cards (emphasis/inverted) | `AC-12: …surface cards…` | COMPONENTS-4 | ✅ A |
| AC-13 | Provenance badges render with the glyph-and-border signature | `AC-13: …glyph-and-border signature` | COMPONENTS-5 | ✅ A |
| AC-14 | Every screen inherits the one installed theme (no hardcoded palette) | `AC-14: …one installed theme` | APPLY-1 | ✅ A |
| AC-15 | A displayed colour swatch carries its approximation caption | `AC-15: …approximation caption` | APPLY-2 | ✅ A |

---

## 4. Design decisions behind the acceptance (for the reviewer)

- **D-1 Atkinson fonts bundled as app assets** (`assets/fonts/`, declared in `pubspec.yaml`), **not** `google_fonts` — the SI mandates fully-offline operation; a network font fetch would break first-run render.
- **D-2 `AppTheme.light()` rewritten to the warm-paper scheme**, and `test/app/theme_test.dart` changed from "`light()` equals stock M3" to "`light()` is the warm-paper scheme **and** clears the AA floor" — the equals-stock assertion is exactly what bs-17 changes; bs-11's real guarantee (AA floor) is preserved by re-proving it on the new tokens.
- **D-7 AC-7/8/9 made true at the `ThemeData` level** (button/card/divider themes + `labelSmall`) so component wrappers inherit them — one chokepoint, keeping the single-theme guarantee (AC-14).
- **D-4 Capture's fixed "device" colours excluded from the AC-14 sweep** (viewfinder stripes, reticle, shutter, feed placeholder) — they emulate a camera surface, not app chrome. The exclusion set is pinned to exactly `{lib/capture/capture_live_view.dart}` and is load-bearing: dropping it re-exposes literals, all inside the set, so a new screen literal would surface outside it and fail.
- **D-6 AC-13 augments the existing `ProvenanceBadge`/`ProvenanceIcon`** (glyph + text, bs-10/bs-11) with the wireframe border-style signature; it does not re-create them.

---

## 5. Known gaps and deferred items

- **APPLY-1 wholesale wrapper screen-swap deferred (owner decision).** AC-14 requires one installed theme and zero hardcoded palette literals, and that is met in full. The *further* step of swapping every ad-hoc `Container`/`FilledButton`/`Card` across all screens for the semantic `SurfaceCard`/`PillButton`/`SpeakButton` wrappers was scoped to the AC-14 gate only (remove residual literals) and the wholesale opt-in was deferred at APPLY-1 by owner decision. The components exist, are green, and are opted into where the ACs required; broader adoption is a cosmetic follow-up, not an AC.
- **D-3 dark theme deferred.** Only the light warm-paper theme is in-bound; `AppTheme.dark()` remains API but `buildApp` wires light only (status quo). The wireframe's dark theme (oklch accent) is deferred pending a separate decision, accepted at G-1.
- **D-5 accent stored as sRGB `#2F55C8`** (the wireframe's own fallback literal), the practical equivalent of its `oklch(0.48 0.16 262)`; oklch precision belongs with the deferred dark theme.
- **Carried sibling flakes (not bs-17's):** the 4 pre-existing device-lane viewport flakes in §2 (palette AC-3/AC-5, self_assessment AC-4, display AC-9), all reproducing identically at the merge-base `c00422f`. They belong to the merged bs-06/bs-07/bs-08 suites, not to bs-17 (which touches no intake layout, no speech phrasing, and only the palette paint-list caption).

---

## 6. Gates

| Gate | Kind | Status |
|---|---|---|
| G-1 | decision — approve the spec **and** the presentation scope expansion (visual design system in-bound; amend SI §Presentation; defer dark theme) | ✅ Resolved 2026-10-17 — Matt Quirk |
| G-2 | decision — approve the acceptance tests (ITEST-4 packet) | ✅ Resolved 2026-10-17 — Matt Quirk (all 15 AC tests accepted as-is) |

No open gates. No G-3 for bs-17.

---

## 7. Token usage and cost per AC

From the *Token usage* ledger (20 sessions, **117,211,944 tokens**) priced at API list rates (2026-09-25); all 20 sessions priced from their transcripts. **Feature total: $109.78** (input $0.01, cache write $33.08, cache read $56.31, output $20.38). Span: first start 2026-10-16 19:17 EDT → last end 2026-10-18 22:52 EDT; **Σ active 5h 28m (Σ wall 9h 07m)**.

Per-stage token subtotals: scaffold 2.91M (2.5%) · shells 6.17M (5.3%) · acceptance-tests 22.95M (19.6%) + test-review 1.48M (1.3%) · behaviour 70.33M (60.0%) · sign-off 6.98M (6.0%) · activities (plan, gate, test-review decision) 6.41M (5.5%). Fully-loaded cost per AC (direct + an even 1/15 share of all shared work) is **$7.32** each.

> Note: `ac_cost.py`'s **direct** per-AC attribution did not resolve this plan's module-dashboard *Target AC* cells, so the direct split reads $0 and everything falls into the shared buckets; the **fully-loaded** figure and the feature total above are correct (the behaviour stage is 60% of tokens, so the true direct-per-AC spread sits well below $7.32). Full breakdown: [cost-per-ac-round-1.md](cost-per-ac-round-1.md).

Summary scorecard: https://claude.ai/artifact/1xFCDcWNcvPHmCJJNbXc7W — headline checked against this run (15/15 ACs, 15 A/0, unit 1459/0, bs-17 27/0 both modes, cross-feature regression 316 pass with 4 pre-existing flakes reproducing identically at BASE `c00422f`).

---

## 8. Manual walkthrough — how a reviewer sees each Rule working

All commands run from the worktree `/Users/matthew.quirk/Nuance-bs17` with `~/development/flutter/bin` on `PATH`. The whole feature's own suite:

```
cd /Users/matthew.quirk/Nuance-bs17 && export PATH="$HOME/development/flutter/bin:$PATH"
flutter analyze lib integration_test/design_system_test.dart integration_test/bs17
flutter test --coverage && dart run tool/coverage_gate.dart 2f779b1
flutter test -d flutter-tester integration_test/design_system_test.dart
flutter test -d flutter-tester integration_test/design_system_test.dart --dart-define=BS17_RUN_PENDING=true
```

**Rule — the warm-paper palette is the single source of surface and ink colour (AC-1..AC-4).**
`flutter test -d flutter-tester integration_test/design_system_test.dart --plain-name "AC-1"` pumps `buildApp` and reads the one installed `ColorScheme`: `surface/surfaceContainerLowest/surfaceContainer` equal `--bg #F3F1EC / --sf #FFFFFF / --sf2 #E9E6DF`, with an `isNot(stock.surface)` control. AC-2 pins the neutrals (`onSurface==#16150F`, muted `#57544C`, `outline/outlineVariant==#CFCAC0`); AC-3 the accent pair (`primary==#2F55C8`, `onPrimary==#FFFFFF`). AC-4 measures seven text-on-surface pairings against bs-11's mirrored WCAG math — each clears the AA floor — after three preconditions pin that the installed scheme *is* the warm-paper scheme. To *see* it, run the app and compare to the wireframe's warm-paper surfaces.

**Rule — Atkinson Hyperlegible is the app's typeface (AC-5, AC-6).**
AC-5 asserts all eight prose/heading `TextTheme` roles resolve `fontFamily == 'Atkinson Hyperlegible Next'`; AC-6 reads the D-7 source `AppTheme.monoLabel.fontFamily == 'Atkinson Hyperlegible Mono'` (with `isNot(Next)` / `isNot(null)` controls). The families are bundled in `assets/fonts/` and declared in `pubspec.yaml` — no network fetch.

**Rule — shape and weight follow the wireframe scale (AC-7, AC-8, AC-9).**
AC-7 reads the installed `filledButtonTheme`/`outlinedButtonTheme` shapes (`StadiumBorder`) and `cardTheme` radius (∈[16,22]); the **rendered-instance** half (a mounted `PillButton`/`SurfaceCard` actually inherits it, not a local override) is proven by AC-10 (mounts both pill variants → `isA<StadiumBorder>`) and AC-12 (mounts `SurfaceCard` → inherited r18). AC-8 reads the 1/2/3px scale off `dividerTheme.thickness` (1.0) and the outlined side width (2.0). AC-9 mounts a real `MonoLabel('srgb')` and asserts the rendered `Text` is upper-cased, `fontWeight==w700`, `letterSpacing/fontSize ≈ 0.06`.

**Rule — the core components carry the wireframe treatment (AC-10..AC-13).**
AC-10 mounts `PillButton.primary` (ink fill, paper label, no border) and `.secondary` (transparent, 2px ink side, ink label) and asserts their fills diverge. AC-11 mounts `SpeakButton`: `CircleBorder`, `fillColor == WarmPaper.accent` *and* `== cs.primary` (inherited, not hardcoded), a `volume_up` glyph, a "Speak" semantics label. AC-12 mounts all three `SurfaceCard` variants (ordinary hairline, emphasis ink border, inverted ink fill + paper text) and asserts they diverge. AC-13 mounts each `ProvenanceTier`'s badge and asserts a non-colour signature (border / fill / dashed `CustomPaint`) plus a distinct glyph per kind — the kinds are told apart with colour removed.

**Rule — the design system is applied across every primary screen (AC-14, AC-15).**
AC-14 walks every roster screen (`capture`, `readout`, `compare`, `recipes`, `palette`): each reads the one `AppTheme.light()` chokepoint (one `MaterialApp`, no nested theme) and the source-scan `residualPaletteLiterals(roots:['lib'], exempt:{authority, capture})` returns **empty** — the 6 former residuals (provenance tints, a CVD-demo pair) were routed into `AppTheme` at APPLY-1. AC-15 walks the roster, counts colour `ColorChip`s, and requires a `SwatchCaption` ("APPROX." + "Swatches are screen approximations. Trust the numbers.") on each swatch-bearing screen (readout always; capture & palette gated to appear exactly when a swatch does); compare/recipes render no counted swatch and are skipped.
