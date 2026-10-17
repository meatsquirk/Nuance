# Module COMPONENTS — the styled widget set

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/widgets/pill_button.dart` (new), `lib/widgets/speak_button.dart` (new), `lib/widgets/surface_card.dart` (new), `lib/widgets/mono_label.dart` (new), and the border-style augmentation of `lib/widgets/provenance_badge.dart` / `lib/widgets/provenance_icon.dart` (AC-13 only).
**Depends on:** THEME · **Blocks:** APPLY

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| COMPONENTS-1 | shell | — | ⬜ Todo | | |
| COMPONENTS-2 | behavior | AC-10 | ⬜ Todo | | |
| COMPONENTS-3 | behavior | AC-11 | ⬜ Todo | | |
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

### Checkpoint / Handoff

## Phase COMPONENTS-2 — behavior: pill buttons (AC-10)

- **Kind:** behavior
- **Target AC:** AC-10 (also realises AC-7/AC-8 for buttons via the inherited theme)
- **Depends on:** THEME-3, ITEST-4 (G-2) · **Blocks:** APPLY-1
- **Files:** `lib/widgets/pill_button.dart`
- **Tasks:** finalise `PillButton.primary` (ink `FilledButton`, paper label, no border, weight 800) and `.secondary` (transparent `OutlinedButton`, 2px border, ink label), both fully-rounded from the theme.
- **Acceptance gate:** un-pend AC-10; `TestAC10_Pills` green with earlier ACs; unit + coverage gate.

### Result

### Checkpoint / Handoff

## Phase COMPONENTS-3 — behavior: speak FAB (AC-11)

- **Kind:** behavior
- **Target AC:** AC-11
- **Depends on:** THEME-3, ITEST-4 (G-2) · **Blocks:** APPLY-1
- **Files:** `lib/widgets/speak_button.dart`
- **Tasks:** finalise `SpeakButton` as a round, accent-filled button (paper-coloured icon), carrying the speaker-wave icon, in the three sizes; expose its `semanticLabel` (leaves bs-11's label contract intact).
- **Acceptance gate:** un-pend AC-11; `TestAC11_SpeakFab` green with earlier ACs; unit + coverage gate.

### Result

### Checkpoint / Handoff

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
