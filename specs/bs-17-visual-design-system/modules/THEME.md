# Module THEME — the warm-paper tokens, fonts and shape in one chokepoint

**Status:** In progress — THEME-4 done (Atkinson Next/Mono typeface, AC-5/6 ✅); THEME-5 next
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/app/theme.dart` (`AppTheme`), `test/app/theme_test.dart`, `pubspec.yaml` (fonts section), `assets/fonts/` (bundled Atkinson `.ttf`). Scaffold tooling for the feature.
**Depends on:** — · **Blocks:** COMPONENTS, APPLY, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| THEME-1 | scaffold | — | ✅ Done | 2,907,678 | 6m 03s |
| THEME-2 | shell | — | ✅ Done | 1,643,747 | 5m 52s |
| THEME-3 | behavior | AC-1 + AC-2 + AC-3 + AC-4 | ✅ Done | 7,460,317 | 17m 10s |
| THEME-4 | behavior | AC-5 + AC-6 | ✅ Done | 6,244,445 | 11m 59s |
| THEME-5 | behavior | AC-7 + AC-8 + AC-9 | ⬜ Todo | | |

## Interface reconciliation

- `AppTheme.light()` stays the single source of `ColorScheme` + `TextTheme` + `ThemeData` that `buildApp` installs (`build_app.dart` ~`theme: AppTheme.light().themeData`). bs-17 changes the **values** inside it, not the seam, so bs-11's "screens read `Theme.of(context)`" guarantee is preserved.
- The `ThemeData` getter gains component-theme slots (`filledButtonTheme`/`outlinedButtonTheme` → `StadiumBorder`; `cardTheme` → 16–22 radius + 2px side; `dividerTheme` → 1px; `textTheme.labelSmall` → the mono micro-label style). `MaterialTapTargetSize.padded` (bs-11 A11Y-3) stays untouched.
- Token names the components/tests read: expose `AppTheme` static getters for the design tokens that have no clean `ColorScheme` slot (e.g. `sunkenSurface`, the three border widths, the inverted pair) so COMPONENTS and the suite read one source (D-7).
- **Spec vs bs-11:** `test/app/theme_test.dart` currently asserts `light().colorScheme == stockM3`. D-2 replaces that with (a) `== warmPaperScheme` and (b) the AA-floor proof reusing the file's existing `_contrast` math — bs-11's actual guarantee (AA floor) survives; only the equals-stock line dies.

## Open gates

- **G-1** (feature-level) ✅ Resolved 2026-10-17: approved — spec + scope expansion (visual design system in-bound) accepted, SI amended (D12), dark theme deferred (D-3) — Matt Quirk. THEME-1 is now startable.

## Phase THEME-1 — scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1) · **Blocks:** THEME-2, COMPONENTS-1
- **Files:** `assets/fonts/*.ttf`, `pubspec.yaml`, (coverage-gate tooling as the repo already uses)
- **Tasks:**
  1. Confirm the Flutter toolchain (`~/development/flutter/bin` per repo convention); record a clean baseline test run of the existing suites.
  2. Stand up / reuse the unit-coverage gate for the files this feature will touch (prove it passes clean and fails on a planted gap).
  3. **Bundle the Atkinson Hyperlegible Next + Mono font files** under `assets/fonts/` and declare both families in `pubspec.yaml` `fonts:` (D-1 — no `google_fonts`, offline-first). No theme value changes yet; the families are only *declared*, not yet referenced by `AppTheme`.
- **Exit criteria:** `flutter pub get` resolves with the new fonts; the baseline suite stays green; the coverage gate demonstrably passes clean and fails on a planted gap. No product behaviour change.

### Result

Scaffold complete; no product code. **Fonts (D-1):** bundled 9 OFL-1.1 static TTFs under `assets/fonts/` — Atkinson Hyperlegible **Next** (Regular/Italic/Medium/SemiBold/Bold/BoldItalic → 400/400i/500/600/700/700i) and **Mono** (Regular/Medium/Bold → 400/500/700), plus `OFL.txt`; from `googlefonts/atkinson-hyperlegible-next` and `…-next-mono` (`main`). Both families **declared** in `pubspec.yaml` `fonts:` only — `AppTheme` does **not** yet reference them (that's THEME-4), so the rendered app is byte-for-byte unchanged. No `google_fonts` dependency (offline-first). **Baseline:** `flutter test` green = **1413/1413** at BASE `03961e0`; `flutter analyze` clean after the pubspec edit; `flutter pub get` resolves with the fonts. **Coverage gate:** reused the repo's `tool/coverage_gate.dart` (100% line on touched `lib/`) — demonstrated with a temporary 2-branch probe: full-coverage run → PASS (exit 0); partial-coverage run → FAIL (exit 1, named the uncovered line); probe removed. No touched `lib/**.dart` this phase, so the gate is a no-op PASS on the committed tree. **Fix passes:** 0/3 (passed first run). **Tokens/Time:** 2,907,678 · 6m 03s (active 6m 03s).

### Checkpoint / Handoff

- **Frozen:** `assets/fonts/` family names **"Atkinson Hyperlegible Next"** and **"Atkinson Hyperlegible Mono"** (exact strings the TextTheme and the AC-5/AC-6 tests must match); weight→asset map as declared in `pubspec.yaml`. THEME-4 references these families; it does not re-bundle.
- **Verification commands** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
  - unit: `flutter test`
  - coverage gate: `flutter test --coverage` then `dart run tool/coverage_gate.dart $BASE` (BASE = phase-start `HEAD`)
  - analyze: `flutter analyze`
  - pub: `flutter pub get`
  - (acceptance targets land with ITEST: `flutter test -d flutter-tester integration_test/design_system_test.dart`, red baseline `--dart-define=BS17_RUN_PENDING=true`)
- **Known gaps:** none. Dark theme stays deferred (D-3). The `23 packages have newer versions` notice from `pub get` is informational (constraint-pinned), not an error.
- **Next (THEME-2):** add the `AppTheme` token accessor surface returning current stock-derived values (behaviour unchanged); it owns `lib/app/theme.dart` and runs ∥ COMPONENTS-1 (`lib/widgets/`).

## Phase THEME-2 — shell: AppTheme accessor surface

- **Kind:** shell
- **Target AC:** —
- **Depends on:** THEME-1 · **Blocks:** ITEST-1, THEME-3
- **Files:** `lib/app/theme.dart`
- **Tasks:**
  1. Add the token accessor surface COMPONENTS and the suite will read (static getters for the sunken surface, the 1/2/3px border widths, the inverted ink/paper pair, the mono-label `TextStyle`), **returning the current stock-derived values** so behaviour is unchanged.
  2. Keep `AppTheme.light()`/`.dark()`/`themeData` signatures stable; the dark factory stays API-only (D-3).
- **Exit criteria:** unit gate passes; existing suite stays green; the app looks identical (values still stock). The accessors exist for THEME-3/4/5 and the suite to fill in.

### Result

Shell complete; the rendered app is byte-identical. Added the design-system token
accessor surface to `AppTheme` (`lib/app/theme.dart`) as the single source
COMPONENTS and the suite will read (D-7): `sunkenSurface` (→ stock
`surfaceContainer`), `inverted` (a `({Color paper, Color ink})` record → stock
`inverseSurface`/`onInverseSurface`), `monoLabel` (→ stock `labelSmall!`), and the
three border-weight constants `hairlineBorderWidth`/`standardBorderWidth`/
`emphasisBorderWidth` = 1.0/2.0/3.0. All colour/type accessors derive from a
cached private stock-light `ThemeData` (`_stockLight`), so the values track
today's look; THEME-3 replaces the colour bodies (and wires the warm-paper scheme
into `themeData`), THEME-4/5 the type and shape. **No accessor is wired into
`themeData` this phase** — `AppTheme.light()`/`.dark()`/`.themeData` seams and
`MaterialTapTargetSize.padded` are untouched, so `buildApp` installs the identical
stock scheme (pinned by the existing + a new test). **Verification:** `flutter
analyze` on the two changed files clean; `flutter test` **1418/1418** green (1413
baseline + 5 new accessor tests); coverage gate **100% line on
`lib/app/theme.dart`** (the one touched file) vs BASE `47c23a2`. **Fix passes:**
0/3 (passed first run). **Tokens/Time:** 1,643,747 · 5m 52s.

### Checkpoint / Handoff

- **Frozen surface (COMPONENTS / suite read these):**
  - `AppTheme.sunkenSurface` → `Color`
  - `AppTheme.inverted` → `({Color paper, Color ink})`
  - `AppTheme.monoLabel` → `TextStyle`
  - `AppTheme.hairlineBorderWidth` / `.standardBorderWidth` / `.emphasisBorderWidth` → `double` (1.0 / 2.0 / 3.0)
  Signatures are stable; the behaviour phases change the **values** (and wire the
  colours into the scheme/theme), never the names/types.
- **Verification commands** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
  unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>` (BASE = phase-start `HEAD`); `flutter analyze`.
- **Known gaps:** none. Border-weight accessors are exposed but not yet consumed
  by `themeData` (THEME-5 wires them); dark theme still deferred (D-3).
- **Next:** COMPONENTS-1 (`lib/widgets/` stock-styled PillButton/SpeakButton/
  SurfaceCard/MonoLabel API) — disjoint files, runs independently; both this phase
  and COMPONENTS-1 must land before ITEST-1. THEME-3 (behavior) is blocked by G-2.

## Phase THEME-3 — behavior: warm-paper ColorScheme (AC-1, AC-2, AC-3, AC-4)

- **Kind:** behavior
- **Target AC:** AC-1, AC-2, AC-3, AC-4 (one cohesive palette change)
- **Depends on:** THEME-2, ITEST-4 (G-2) · **Blocks:** COMPONENTS-2/3/4/5, APPLY-1
- **Files:** `lib/app/theme.dart`, `test/app/theme_test.dart`
- **Tasks:**
  1. Replace the stock-M3 adoption with the warm-paper `ColorScheme` (D-2/D-5): `surface`/`surfaceContainerLowest`/`surfaceContainer` → `#F3F1EC`/`#FFFFFF`/`#E9E6DF`; `onSurface`→`#16150F`; a muted role→`#57544C`; `outline`/`outlineVariant`→`#CFCAC0`; `primary`→`#2F55C8`, `onPrimary`→`#FFFFFF`; plus the inverted pair accessor.
  2. Update `test/app/theme_test.dart` per D-2: assert the warm-paper scheme **and** re-prove the AA floor (reuse `_contrast`), so AC-4 is pinned and a future token edit below AA fails the build.
- **Exit criteria / Acceptance gate:** un-pend AC-1..AC-4; `integration_test/design_system_test.dart` green for `TestAC01_Surfaces`/`TestAC02_Neutrals`/`TestAC03_Accent`/`TestAC04_ContrastFloor` and all earlier ACs; unit + coverage gate on touched files.

### Result

Warm-paper light scheme is live. **`lib/app/theme.dart`:** added the 8 warm-paper
token constants (`_bg`/`_sf`/`_sf2`/`_ink`/`_mut`/`_ln`/`_acc`/`_accInk`, hexes
mirroring the suite's `WarmPaper` fixture) and a new `static final ColorScheme
warmPaperScheme` = stock M3 light `copyWith(surface/surfaceContainerLowest/
surfaceContainer/onSurface/onSurfaceVariant/outline/outlineVariant/primary/
onPrimary)`. `AppTheme.light()` now builds from `warmPaperScheme` (stock M3
textTheme retained — THEME-4 sets Atkinson); `AppTheme.dark()` stays stock
(D-3). The colour accessors are superseded to warm-paper values:
`sunkenSurface → _sf2 (#E9E6DF)`, `inverted → (paper: _ink #16150F, ink: _bg
#F3F1EC)` (dark-paper/light-ink — COMPONENTS-4's `SurfaceCard.inverted` reads
this); `monoLabel` stays stock (THEME-4/5). **Tests:** rewrote
`test/app/theme_test.dart` per D-2 — `light()` now asserts the 9 warm-paper roles
+ an overlay check (a non-touched role keeps stock) + textTheme still stock, and
the AA proof is re-established over the 7 warm-paper pairings (AC-4's set), not by
equality to stock (bs-11's AA guarantee preserved by proof); the "shell—look
unchanged" test (now false) was removed. Un-pended AC-1..AC-4 (deleted their rows
in `bs17/pending.dart`) and updated the 2 `design_system_test.dart` pending-gate
guards to the `unpended`-set pattern (exact 11-row membership; hide/admit over
still-pending AC-5/15 + un-pended AC-1).
**Gates:** `flutter analyze` clean; unit **1434 green** (was 1435, −1 removed
shell test); coverage gate **100% line on `lib/app/theme.dart`** (only touched
`lib/`) vs BASE `b1e6ac5`; acceptance `design_system_test.dart` default run **green
— AC-1..4 run & pass, 11 later ACs skipped**. **Regression:** the warm-paper theme
renders app-wide, so ran the bs-11 accessibility suite (the on-screen WCAG
`textContrastGuideline` authority over every real screen) — **19/19 green**,
incl. AC-5 contrast and AC-4 48dp. **Grade gate:** fresh independent grader —
**AC-1..4 = 4 straight A, 0 B, PASS**; both modified guards A/non-vacuous
([grid](../behavior-test-completeness-bs-17-visual-design-system.md), THEME-3
section). No augmentation owed (per ITEST). **Fix passes:** 0/3 (all gates passed
first run). **Tokens/Time:** 7,460,317 · 17m 10s.

### Checkpoint / Handoff

- **Frozen (THEME-4/5, COMPONENTS, APPLY read these):**
  - `AppTheme.light().colorScheme` / `AppTheme.warmPaperScheme` — the warm-paper
    light scheme; roles pinned by hex in `test/app/theme_test.dart`. **THEME-4
    changes only the `textTheme`; THEME-5 only the shape/border/label component
    themes in `themeData` — neither touches these colour roles.**
  - `AppTheme.sunkenSurface` = `#E9E6DF`; `AppTheme.inverted` = `(paper: #16150F,
    ink: #F3F1EC)` (the values COMPONENTS-4 renders). `monoLabel` is still stock
    (THEME-4/5 set Mono family/weight/spacing).
- **Verification commands** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
  unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>`; acceptance `flutter test -d
  flutter-tester integration_test/design_system_test.dart` (red baseline:
  `--dart-define=BS17_RUN_PENDING=true`); regression `flutter test -d
  flutter-tester integration_test/bs11/accessibility_test.dart`.
- **Known gaps:** none. Dark scheme stays stock/deferred (D-3). The `23 packages
  have newer versions` pub notice is informational.
- **Merge-risk note:** THEME-4 and THEME-5 both own `lib/app/theme.dart` — run one
  at a time or coordinate (they are merge-risky with each other, disjoint from the
  COMPONENTS phases).
- **Next (THEME-4 ∥ THEME-5 ∥ COMPONENTS-2..5):** THEME-4 sets the Atkinson
  families on the `TextTheme`; THEME-5 the StadiumBorder/card-radius/border-weight/
  mono-label theme styles; the COMPONENTS phases style their own `lib/widgets/`
  widgets, reading the now-live warm-paper tokens through `AppTheme.light()`.

## Phase THEME-4 — behavior: Atkinson typeface (AC-5, AC-6)

- **Kind:** behavior
- **Target AC:** AC-5, AC-6
- **Depends on:** THEME-3 · **Blocks:** APPLY-1 · ∥ THEME-5
- **Files:** `lib/app/theme.dart`
- **Tasks:**
  1. Set the `TextTheme` default family to "Atkinson Hyperlegible Next" (the bundled asset family) across display/headline/title/body/label roles that carry prose.
  2. Set the mono roles (the readout/label styles, e.g. `labelSmall` and a numeric style) to "Atkinson Hyperlegible Mono".
- **Exit criteria / Acceptance gate:** un-pend AC-5, AC-6; `TestAC05_NextFont`/`TestAC06_MonoFont` green with earlier ACs; unit + coverage gate.

### Result

Atkinson Hyperlegible typeface is live. **`lib/app/theme.dart`:** added the two
family-name constants `nextFamily` = "Atkinson Hyperlegible Next" / `monoFamily`
= "Atkinson Hyperlegible Mono" (the exact bundled-asset strings frozen by
THEME-1) and a `static final TextTheme warmPaperTextTheme` = the stock M3 text
theme `.apply(fontFamily: nextFamily)` across every role, `.copyWith` the
`labelSmall` micro-label role to `monoFamily` (the single source `monoLabel`
reads, D-7). `AppTheme.light()` now installs `warmPaperTextTheme` (was
`_stockLight.textTheme`); `monoLabel` now returns `warmPaperTextTheme.labelSmall!`
(was stock `labelSmall`). THEME-5 sets the mono label's weight/letter-spacing;
THEME-4 sets only the families. `AppTheme.dark()` stays stock (D-3); the colour
roles THEME-3 set are untouched. **Tests:** `test/app/theme_test.dart` —
re-pointed the two THEME-3-stock assertions (`light()` textTheme now
`warmPaperTextTheme`, no longer stock; `monoLabel` now Mono-family, no longer
stock `labelSmall`) and added a "bs-17 Atkinson typeface (THEME-4)" group pinning
the family constants, every prose/heading role = Next (AC-5), the micro-label =
Mono distinct from Next (AC-6), and `light()` installing the theme. Un-pended
AC-5/AC-6 (deleted their rows in `bs17/pending.dart`) and updated the two
pending-gate guards (`unpended` set → `{AC-1..AC-6}`; the "hides a pending AC"
exemplar → still-pending AC-7, AC-5 moved to the un-pended list).
**Gates:** `flutter analyze` clean (4 files); unit **1438 green** (was 1434, +4
typeface tests); coverage gate **100% line on `lib/app/theme.dart`** (only touched
`lib/`) vs BASE `48e5257`; acceptance `design_system_test.dart` default run **green
— AC-1..6 run & pass, 9 later ACs skipped**. **Regression:** the Atkinson type
renders app-wide, so ran the bs-11 accessibility suite (the on-screen WCAG /
200%-scaling authority over every real screen) — **19/19 green**, incl. AC-3 200%
font scaling (the font-change-sensitive one). **Grade gate:** fresh independent
grader re-graded every un-pended AC test (AC-1..AC-6) + the two modified guards —
**4 straight A re-grade (AC-1..4) + AC-5/AC-6 2 straight A, 0 B; both modified guards A/non-vacuous**
([grid](../behavior-test-completeness-bs-17-visual-design-system.md), THEME-4
section). No augmentation owed (per ITEST; AC-5/AC-6 schedule none). **Fix passes:**
0/3 (all gates passed first run). **Tokens/Time:** 6,244,445 · 11m 59s.

### Checkpoint / Handoff

- **Frozen (THEME-5, COMPONENTS, APPLY read these):**
  - `AppTheme.warmPaperTextTheme` — the installed `TextTheme`: Next on every
    prose/heading role, Mono on `labelSmall`. `AppTheme.light().textTheme` is this.
    **THEME-5 changes the shape/border/label component themes in `themeData` and
    the mono label's weight/letter-spacing — it must keep the Mono family on the
    micro-label and the Next family on prose.**
  - `AppTheme.nextFamily` / `AppTheme.monoFamily` — the family-name constants
    (the bundled-asset strings; do not re-spell).
  - `AppTheme.monoLabel` = `warmPaperTextTheme.labelSmall!` — Mono family, stock
    weight/spacing until THEME-5 sets w700 + ~.06em tracking (AC-9).
- **Verification commands** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
  unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>`; acceptance `flutter test -d
  flutter-tester integration_test/design_system_test.dart` (red baseline:
  `--dart-define=BS17_RUN_PENDING=true`); regression `flutter test -d
  flutter-tester integration_test/bs11/accessibility_test.dart`.
- **Known gaps:** none. Dark theme stays stock/deferred (D-3). The `23 packages
  have newer versions` pub notice is informational.
- **Merge-risk note:** THEME-5 owns `lib/app/theme.dart`, which THEME-4 just
  landed on — branch a THEME-5 worktree from the THEME-4 commit. COMPONENTS-2..5
  own `lib/widgets/`, disjoint from THEME-5.
- **Next (THEME-5 ∥ COMPONENTS-2..5):** THEME-5 wires the StadiumBorder pills,
  16–22 card radius, 1/2/3px border weights and the w700/.06em uppercase mono
  label into `themeData`; the COMPONENTS phases style their own `lib/widgets/`
  widgets, reading the now-live warm-paper tokens, Atkinson type and `monoLabel`.

## Phase THEME-5 — behavior: shape, border and micro-label styles (AC-7, AC-8, AC-9)

- **Kind:** behavior
- **Target AC:** AC-7, AC-8, AC-9
- **Depends on:** THEME-3 · **Blocks:** APPLY-1 · ∥ THEME-4
- **Files:** `lib/app/theme.dart`
- **Tasks:**
  1. Shape (D-7): `filledButtonTheme`/`outlinedButtonTheme` → `StadiumBorder` (fully-rounded pills); `cardTheme` → `RoundedRectangleBorder` radius in 16–22.
  2. Border weights: `dividerTheme` → 1px hairline (`#CFCAC0`); the card/outline-button themes → 2px standard side; expose the 3px emphasis/warning width via the accessor.
  3. Micro-label style: `labelSmall` (or a named `AppTheme.monoLabel`) → Mono, `fontWeight: 700`, `letterSpacing` ≈ `.06em·fontSize`, consumed uppercase by `MonoLabel`.
- **Exit criteria / Acceptance gate:** un-pend AC-7, AC-8, AC-9; `TestAC07_Shape`/`TestAC08_BorderWeights`/`TestAC09_MonoLabel` green with earlier ACs; unit + coverage gate.

### Result

### Checkpoint / Handoff
