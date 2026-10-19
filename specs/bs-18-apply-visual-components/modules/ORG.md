# Module ORG — Palette + Projects screen swaps

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/palette/**`, `lib/projects/**` (screen/region/row widgets only — not controllers, sources, read endpoints, `paint_dataset.dart` data or `project_export.dart`).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ORG-1 | behavior | AC-8 | ⬜ Todo | | |
| ORG-2 | behavior | AC-9 | ⬜ Todo | | |

## Interface reconciliation

Consumes the bs-17 wrappers plus the existing `ProvenanceBadge`/`ProvenanceIcon`/`PaintRow`/`ColorChip`
widgets. Changes only the Palette/Projects presentation; palette and project controllers, sources, the paint
dataset, provenance *data* and PDF export are frozen (D-2). Provenance meaning stays carried by glyph + text,
never colour alone (bs-11).

## Open gates

G-2 blocks both phases. ORG-1 and ORG-2 touch disjoint dirs and may run in either order or in parallel once
G-2 is open.

## Phase ORG-1 — behavior: Palette (AC-8)

- **Kind:** behavior
- **Target AC:** AC-8 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/palette/palette_screen.dart`, `paint_list_region.dart`, `palette_selector_region.dart`, `provenance_legend_region.dart`, `vision_profile_card.dart`.
- **Tasks:**
  1. Render each paint row through the design-system `PaintRow`/`ColorChip`; ensure each row shows its `ProvenanceBadge` (glyph-and-border signature); render add-from-dataset as `PillButton`.
  2. Wrap the vision-profile card in `SurfaceCard`; remove the superseded ad-hoc buttons.
- **Exit criteria:** `lib/palette` suite + bs-06 palette-and-projects + bs-07 self-assessment suites green (expect the carried palette AC-3/AC-5 and self_assessment AC-4 flakes off the exclusive lane — not regressions).
- **Acceptance gate:** un-pend AC-8; `TestAC08_Palette` green with earlier ACs; sibling suites green (carried flakes excepted).
- **Augments:** `TestAC08`: add "old add button absent" + per-row `ProvenanceBadge` present for rows `paint_list_region.dart` already partly swapped.

## Phase ORG-2 — behavior: Projects (AC-9)

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** ITEST-5 (G-2) · **Blocks:** GUARD-1
- **Files:** `lib/palette/projects_region.dart` (+ `lib/projects/project_summary.dart` presentation if it renders UI).
- **Tasks:**
  1. Render each project entry in a `SurfaceCard`; open + create-project actions as `PillButton`.
  2. Remove the superseded `ListTile`/buttons.
- **Exit criteria:** `lib/projects`/`lib/palette` project suite + bs-06 projects suite green.
- **Acceptance gate:** un-pend AC-9; `TestAC09_Projects` green with earlier ACs; sibling suites green.
