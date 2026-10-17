# Module APPLY — wire the screens to the design system

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** screen-level edits across `lib/readout/**`, `lib/capture/**`, `lib/compare/**`, `lib/recipes/**`, `lib/palette/**`, `lib/projects/**`, `lib/display/**`, `lib/onboarding/**` — swapping ad-hoc buttons/cards/labels for the COMPONENTS wrappers, removing residual hardcoded palette colours, and adding the shared swatch caption. Plus a shared caption widget (`lib/widgets/swatch_caption.dart`, new) and the AC-14 source-scan rule.
**Depends on:** THEME, COMPONENTS · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| APPLY-1 | behavior | AC-14 | ⬜ Todo | | |
| APPLY-2 | behavior | AC-15 | ⬜ Todo | | |

## Interface reconciliation

- APPLY introduces no new public interface beyond `SwatchCaption` (a small wrapper around the existing `ColorChip`/swatch surfaces); it is wiring. It must not change any screen's behaviour, layout CHOICE, or semantics — only the surface styling and the colour source.
- **AC-14 scope (D-4):** the source-scan rule flags hardcoded palette `Color(0x…)` in `lib/**` **excluding** `lib/capture/**` camera-device literals (viewfinder stripes, reticle, shutter, feed placeholder), `lib/color_science/**`, `lib/correction/engine/**`, `lib/recipes/engine/**`, `lib/dataset/**`, `lib/domain/**` (these carry colour *data*, not chrome). The ~7 residual chrome literals identified in the gap analysis are the removal target.
- Runs after every component phase so screen swaps use finished wrappers. APPLY-1 is the merge-risky phase (touches many screen files) — run alone.

## Open gates

- **G-2** (feature-level) blocks both APPLY phases.

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

### Checkpoint / Handoff

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

### Checkpoint / Handoff
