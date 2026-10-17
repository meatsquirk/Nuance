# Module THEME — the warm-paper tokens, fonts and shape in one chokepoint

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/app/theme.dart` (`AppTheme`), `test/app/theme_test.dart`, `pubspec.yaml` (fonts section), `assets/fonts/` (bundled Atkinson `.ttf`). Scaffold tooling for the feature.
**Depends on:** — · **Blocks:** COMPONENTS, APPLY, ITEST

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| THEME-1 | scaffold | — | ⬜ Todo | | |
| THEME-2 | shell | — | ⬜ Todo | | |
| THEME-3 | behavior | AC-1 + AC-2 + AC-3 + AC-4 | ⬜ Todo | | |
| THEME-4 | behavior | AC-5 + AC-6 | ⬜ Todo | | |
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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

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

### Checkpoint / Handoff

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

### Checkpoint / Handoff

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

### Checkpoint / Handoff

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
