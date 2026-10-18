# Module COMPONENTS — the styled widget set

**Status:** In progress
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/widgets/pill_button.dart` (new), `lib/widgets/speak_button.dart` (new), `lib/widgets/surface_card.dart` (new), `lib/widgets/mono_label.dart` (new), and the border-style augmentation of `lib/widgets/provenance_badge.dart` / `lib/widgets/provenance_icon.dart` (AC-13 only).
**Depends on:** THEME · **Blocks:** APPLY

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| COMPONENTS-1 | shell | — | ✅ Done | 4,522,630 | 10m 25s |
| COMPONENTS-2 | behavior | AC-10 | ✅ Done | 6,332,367 | 13m 15s |
| COMPONENTS-3 | behavior | AC-11 | ✅ Done | 4,156,872 | 9m 34s |
| COMPONENTS-4 | behavior | AC-12 | ⬜ Todo | | |
| COMPONENTS-5 | behavior | AC-13 | ⬜ Todo | | |

## Interface reconciliation

- Every component is a thin wrapper over a Material widget whose look comes from `AppTheme` (D-7), so the "single theme" guarantee (AC-14) holds and the components need no colour arguments:
  - `PillButton.primary({onPressed, child})` → `FilledButton` (ink fill, paper label); `PillButton.secondary(...)` → `OutlinedButton` (transparent, bordered). Shape inherited (StadiumBorder).
  - `SpeakButton({onPressed, semanticLabel})` → round accent button carrying the speaker icon; sizes `standard/compact/mini` map to the wireframe 64/52/44.
  - `SurfaceCard({child})` / `SurfaceCard.emphasis(...)` / `SurfaceCard.inverted(...)` → surface fill + hairline border / ink border / ink fill + paper text, radius from `cardTheme`.
  - `MonoLabel(String text)` → `Text` in the `AppTheme` mono-label style, upper-cased in the widget.
- These wrappers **replace** ad-hoc buttons/cards/labels during APPLY; they don't themselves touch screens. The existing `ColorChip`, `ValueReading`, `PaintRow`, `AccessibleNotice`, `StatusBadge` are untouched except where APPLY swaps a raw button/card for a wrapper.
- **AC-13 reuse (D-6):** `ProvenanceBadge`/`ProvenanceIcon` already carry glyph+text (bs-10/bs-11). COMPONENTS-5 adds only the wireframe border signature (measured=solid, calculated=sf2 fill, estimated=dashed, confirmed=ink fill) via the theme tokens; the semantics label and glyph are unchanged, so bs-11/bs-10 ACs are untouched.

## Open gates

- **G-2** (feature-level) blocks COMPONENTS-2..5: acceptance tests approved first.

## Phase COMPONENTS-1 — shell: component API

- **Kind:** shell
- **Target AC:** —
- **Depends on:** THEME-1 · **Blocks:** ITEST-1, COMPONENTS-2..5 · ∥ THEME-2
- **Files:** `lib/widgets/pill_button.dart`, `lib/widgets/speak_button.dart`, `lib/widgets/surface_card.dart`, `lib/widgets/mono_label.dart`
- **Tasks:**
  1. Create the four widget classes with their final public API (above), each rendering through the **current** theme (so they look ~stock for now) — the shells the suite targets. No screen is rewired yet.
- **Exit criteria:** unit gate passes; existing suite stays green; the widgets instantiate and render in a widget test. Behaviour of the app unchanged (nothing uses them yet).

### Result

Shell complete; the four styled widgets exist with their **final public API**,
rendering through the current theme so they look ~stock (no screen is rewired;
nothing renders them yet). New files:
- `lib/widgets/pill_button.dart` — `PillButton.primary` → `FilledButton`,
  `.secondary` → `OutlinedButton`; `onPressed`/`child`, no colour args.
- `lib/widgets/speak_button.dart` — round `RawMaterialButton` (CircleBorder,
  `shrinkWrap` + tight constraints so the 44px `mini` is exact), accent fill
  `colorScheme.primary` + `onPrimary` glyph (`Icons.volume_up`); `SpeakButtonSize`
  enum {standard 64, compact 52, mini 44}; `semanticLabel` on a `MergeSemantics`
  so a screen reader announces one labelled button.
- `lib/widgets/surface_card.dart` — `SurfaceCard` (surface fill + hairline
  `outlineVariant` border), `.emphasis` (2px `onSurface` ink border), `.inverted`
  (`AppTheme.inverted.paper` fill + `.ink` default text); radius from `cardTheme`
  (default 16 when unset). Reads the frozen `AppTheme` tokens (D-7).
- `lib/widgets/mono_label.dart` — upper-cases its text, drawn in `AppTheme.monoLabel`.
**Verification:** `flutter analyze` on the 8 new files clean; `flutter test`
**1435/1435** green (1418 baseline + 17 new widget tests); coverage gate **100%
line on all 4 touched `lib/widgets/*.dart`** vs BASE `969dafb`. App byte-identical
(no accessor/screen wired). **Fix passes:** 3/3 — all confined to the `SpeakButton`
test mechanics (ambiguous `SizedBox` finder → assert `RawMaterialButton` size;
label/tap node merge → `MergeSemantics` + `button: true` + `isSemantics` matcher;
deprecated `hasFlag`/`containsSemantics`); the other three widgets passed first run.
**Tokens/Time:** 4,522,630 · 10m 25s.

### Checkpoint / Handoff

- **Frozen public API (COMPONENTS-2..5 finalise the *look*, not these signatures):**
  - `PillButton.primary({required VoidCallback? onPressed, required Widget child})` / `.secondary(...)`
  - `SpeakButton({required VoidCallback? onPressed, required String semanticLabel, SpeakButtonSize size = standard})`; `enum SpeakButtonSize { standard(64), compact(52), mini(44) }` with a `.diameter` getter
  - `SurfaceCard({required Widget child})` / `.emphasis({...})` / `.inverted({...})`
  - `MonoLabel(String text)`
- **Verification commands** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
  unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`.
- **Known gaps:** none. The widgets read stock-derived theme values until the
  THEME behavior phases fill the warm-paper tokens; COMPONENTS-2..5 (behavior,
  blocked by G-2) finalise the exact weights/borders and un-pend AC-10..13.
  AC-13's provenance-badge signature lands in COMPONENTS-5 on the existing
  `ProvenanceBadge`/`ProvenanceIcon` (not touched here).
- **Next:** ITEST-1 (the acceptance harness) — both THEME-2 and this phase (the
  two shells) are now done, so ITEST-1 is unblocked. THEME-3.. / COMPONENTS-2.. /
  APPLY-.. remain blocked by G-2.

## Phase COMPONENTS-2 — behavior: pill buttons (AC-10)

- **Kind:** behavior
- **Target AC:** AC-10 (also realises AC-7/AC-8 for buttons via the inherited theme)
- **Depends on:** THEME-3, ITEST-4 (G-2) · **Blocks:** APPLY-1
- **Files:** `lib/widgets/pill_button.dart`
- **Tasks:** finalise `PillButton.primary` (ink `FilledButton`, paper label, no border, weight 800) and `.secondary` (transparent `OutlinedButton`, 2px border, ink label), both fully-rounded from the theme.
- **Acceptance gate:** un-pend AC-10; `TestAC10_Pills` green with earlier ACs; unit + coverage gate.

### Result

AC-10 built and un-pended. `PillButton.primary` now wraps a `FilledButton` styled
ink-filled — `backgroundColor: onSurface`, `foregroundColor: surface` (paper label),
label weight 800 (`labelLarge.copyWith(fontWeight: w800)`), **no** shape/side set →
the fully-rounded `StadiumBorder` + no-border are inherited from the frozen theme.
`PillButton.secondary` wraps an `OutlinedButton` styled `backgroundColor: transparent`,
`foregroundColor: onSurface` (ink label), **no** shape/side set → the `StadiumBorder`
+ 2px ink (`onSurface`) side come from `outlinedButtonTheme`. The theme is frozen; all
treatment is at the widget level in `lib/widgets/pill_button.dart` only.

**Un-pend:** deleted the `AC-10` row in `integration_test/bs17/pending.dart`
(`pendingACs` now `{AC-11..AC-15}`); updated the two pending-gate guard tests
(`unpended` += AC-10; pending exemplars → AC-11/AC-15).
**AC-7 augmentation (pill half) CLOSED:** added `expect(primaryShape/secondaryShape,
isA<StadiumBorder>())` on the mounted `PillButton` instances in the AC-10 test — proves
a rendered pill inherits the theme stadium (the pill sets no shape). AC-7 → "A-core / B
pending COMPONENTS-4" (card half only, owed by AC-12).

**Verification** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
`flutter analyze` on the 4 touched files clean; unit `flutter test` **1444/1444** green
(1442 baseline + 2 new pill colour/weight tests); coverage gate **100% line on
`lib/widgets/pill_button.dart`** vs BASE `71e34a6`; acceptance
`flutter test -d flutter-tester integration_test/design_system_test.dart` **GREEN —
21 passed / 5 skipped** (AC-1..AC-10 run, AC-11..AC-15 pending). **Grade gate PASS**
(independent re-grade): 9 straight A (incl. AC-10), 1 A-core/B-pending (AC-7 →
COMPONENTS-4), 0 plain-B; both guard tests A. **Fix passes:** 0/3 (green first run).
**Tokens/Time:** 6,332,367 · 13m 15s.

### Checkpoint / Handoff

- **Frozen for APPLY:** `PillButton.primary`/`.secondary` render their final look
  (ink-fill/paper-label/w800 primary; transparent/ink-label/2px-ink-border secondary),
  both fully-rounded via the inherited `StadiumBorder`. Public API unchanged
  (`primary({onPressed, child})` / `secondary(...)`). APPLY swaps ad-hoc buttons for these.
- **Verification commands:** unit `flutter test`; coverage `flutter test --coverage`
  then `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`; acceptance
  `flutter test -d flutter-tester integration_test/design_system_test.dart`.
- **Known gaps:** none for the pill. AC-7's card-half rendered-instance augmentation
  is still owed by COMPONENTS-4 (a mounted `SurfaceCard` must inherit `cardTheme` r18).
- **Next:** COMPONENTS-3 (AC-11 SpeakButton), COMPONENTS-4 (AC-12 SurfaceCard — closes
  AC-7's card half), COMPONENTS-5 (AC-13 provenance badge) — all three still startable
  **concurrently** (each owns its own `lib/widgets/*.dart`, disjoint). Then APPLY-1
  (alone) / APPLY-2, then SIGNOFF-1.

## Phase COMPONENTS-3 — behavior: speak FAB (AC-11)

- **Kind:** behavior
- **Target AC:** AC-11
- **Depends on:** THEME-3, ITEST-4 (G-2) · **Blocks:** APPLY-1
- **Files:** `lib/widgets/speak_button.dart`
- **Tasks:** finalise `SpeakButton` as a round, accent-filled button (paper-coloured icon), carrying the speaker-wave icon, in the three sizes; expose its `semanticLabel` (leaves bs-11's label contract intact).
- **Acceptance gate:** un-pend AC-11; `TestAC11_SpeakFab` green with earlier ACs; unit + coverage gate.

### Result

AC-11 built and un-pended. **No `SpeakButton` code change was needed:** the FAB's
wireframe treatment *is* the theme accent fill, and the COMPONENTS-1 shell already
renders `fillColor: scheme.primary` / `scheme.onPrimary` glyph on a `CircleBorder`
with the three diameters and the `semanticLabel`. Once THEME-3 made `colorScheme.primary`
the cobalt accent (`WarmPaper.accent` = `#2F55C8`), the shell *became* the final look —
unlike the `PillButton` (COMPONENTS-2), which had to override the stock accent fill with
an ink fill. So the FAB AC was realised by the shell + THEME; this phase finalises it by
un-pending and confirming, plus a doc-comment refresh in `lib/widgets/speak_button.dart`
recording that the accent fill is the frozen final treatment.

**Un-pend:** deleted the `AC-11` row in `integration_test/bs17/pending.dart`
(`pendingACs` now `{AC-12..AC-15}`); updated the two pending-gate guard tests in
`integration_test/design_system_test.dart` (`unpended` += AC-11; pending exemplars
`AC-11/AC-15` → `AC-12/AC-15`; ambient-path exemplar `AC-11` → `AC-12`).
**Augmentations:** none owed by this phase; none newly enabled (no new behaviour was
built that lets an already-green AC test assert more). The AC-7 **card half** remains
owed by COMPONENTS-4.

**Verification** (Flutter on `~/development/flutter/bin`; no `timeout` on macOS):
`flutter analyze` on the 4 touched files clean; unit `flutter test` **1444/1444** green
(unchanged — the widget's behaviour is unchanged); coverage gate **100% line on
`lib/widgets/speak_button.dart`** (the one touched lib file, comment-only) vs BASE
`5306d28`; acceptance `flutter test -d flutter-tester integration_test/design_system_test.dart`
**GREEN — 22 passed / 4 skipped** (AC-1..AC-11 run, AC-12..AC-15 pending); run-pending
pre-un-pend confirmed `AC-11` green. **Grade gate PASS** (independent fresh re-grade of
AC-1..AC-11): **10 straight A** (incl. AC-11) + **1 A-core / B-pending COMPONENTS-4**
(AC-7 card half, carried unchanged — not regressed, not closed this phase), 0 plain-B;
both pending-gate guard tests A (non-vacuous). **Fix passes:** 0/3 (green first run).
**Tokens/Time:** 4,156,872 · 9m 34s.

### Checkpoint / Handoff

- **Frozen for APPLY:** `SpeakButton` renders its final look — a round (`CircleBorder`)
  accent-filled (`colorScheme.primary`) FAB with a paper glyph (`onPrimary`, `Icons.volume_up`)
  in the three `SpeakButtonSize` diameters (64/52/44), carrying `semanticLabel`. Public API
  unchanged. APPLY swaps ad-hoc speak controls for this.
- **Verification commands:** unit `flutter test`; coverage `flutter test --coverage` then
  `dart run tool/coverage_gate.dart <BASE>`; `flutter analyze`; acceptance
  `flutter test -d flutter-tester integration_test/design_system_test.dart`.
- **Known gaps:** none for the speak FAB. AC-7's card-half rendered-instance augmentation
  is still owed by COMPONENTS-4 (a mounted `SurfaceCard` must inherit `cardTheme` r18).
- **Next:** COMPONENTS-4 (AC-12 SurfaceCard — closes AC-7's card half), COMPONENTS-5
  (AC-13 provenance badge) — both still startable **concurrently** (disjoint `lib/widgets/`).
  Then APPLY-1 (alone) / APPLY-2, then SIGNOFF-1.

## Phase COMPONENTS-4 — behavior: surface cards and panels (AC-12)

- **Kind:** behavior
- **Target AC:** AC-12 (also realises AC-7/AC-8 for cards)
- **Depends on:** THEME-3, ITEST-4 (G-2) · **Blocks:** APPLY-1, APPLY-2
- **Files:** `lib/widgets/surface_card.dart`
- **Tasks:** finalise `SurfaceCard` (surface fill, 2px hairline-colour border, theme radius), `.emphasis` (2px ink border), `.inverted` (ink fill, paper-coloured text + child default text colour).
- **Acceptance gate:** un-pend AC-12; `TestAC12_Cards` green with earlier ACs; unit + coverage gate.

### Result

### Checkpoint / Handoff

## Phase COMPONENTS-5 — behavior: provenance badge signature (AC-13)

- **Kind:** behavior
- **Target AC:** AC-13
- **Depends on:** THEME-3, ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `lib/widgets/provenance_badge.dart`, `lib/widgets/provenance_icon.dart`
- **Tasks:** add the border-style signature per provenance kind (measured ◉ solid ink; calculated ∑ sunken fill; estimated ≈ dashed; confirmed ✓ ink fill), reading theme tokens; keep the existing glyph + semantics label (D-6). Verify bs-10/bs-11 provenance tests stay green.
- **Acceptance gate:** un-pend AC-13; `TestAC13_ProvenanceSignature` green with earlier ACs; bs-10/bs-11 suites stay green; unit + coverage gate.

### Result

### Checkpoint / Handoff
