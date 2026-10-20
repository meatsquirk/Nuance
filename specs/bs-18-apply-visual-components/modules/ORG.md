# Module ORG — Palette + Projects screen swaps

**Status:** In progress — ORG-1 ✅ done (AC-8); next ORG-2 (AC-9)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/palette/**`, `lib/projects/**` (screen/region/row widgets only — not controllers, sources, read endpoints, `paint_dataset.dart` data or `project_export.dart`).
**Depends on:** ITEST (G-2) · **Blocks:** GUARD

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ORG-1 | behavior | AC-8 | ✅ Done | 10.83M | 26m 57s |
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

### Result — ORG-1 (✅ Done)

- **Landed (production, presentation-only, D-2):** `lib/palette/paint_list_region.dart` — the E32 add-from-dataset action (`addPaintKey`) is now a design-system `PillButton.secondary` (outlined within-list action, matching the capture/readout action pills); the ad-hoc `TextButton` it superseded is gone. `lib/palette/vision_profile_card.dart` — the vision-profile panel is now a `SurfaceCard` (Material `Card` gone, same 12dp inner padding, `regionKey` preserved) and the E30 retake control a `PillButton.secondary` (was `TextButton`, `retakeKey` preserved). Paint rows + per-row `ProvenanceBadge` were already design-system (`PaintRow` → `ProvenanceBadge`); the palette selector (E31 view toggle, palette options) and provenance legend stay stock (not named by AC-8, no design-system component supersedes them).
- **Un-pended:** AC-8 (`integration_test/visual_application/pending.dart` row removed).
- **Augmentation made (TestAC08 → ORG-1, pre-seeded ITEST-3):** closed. The AC-8 test gained the "old add button absent" sweep `expect(find.widgetWithText(TextButton, 'Add paint'), findsNothing)` after the `expectPill`; red-baselines against BASE 638df66 (add was exactly that `TextButton`), tight against the E31 selector's 'My paints'/'Projects' TextButtons (different labels). AC-8 re-graded **straight A**.
- **Tests (sibling maintenance for the swap, no behaviour weakened):** `test/palette/palette_screen_test.dart` — the add-paint and retake wiring reads changed from `tester.widget<TextButton>` to `tester.widget<PillButton>` (added the `pill_button.dart` import); the E31 view-selector `TextButton` reads and the ORG-2-owned Projects `openProjectKey`/`exportKey` reads are untouched. `integration_test/visual_application/smoke_test.dart` — the ITEST-1 pending-gate exemplar and the planted wiring-smoke `acTestWidgets` re-pointed AC-8 → AC-9 (next still-pending AC), AC-8 added to the un-pended sets.
- **Verification:** `flutter analyze` (6 touched files) clean. Unit `flutter test --coverage test/` → **1676 pass**. Coverage gate `dart run tool/coverage_gate.dart 638df66` → **100% line on both touched lib files** (`paint_list_region.dart`, `vision_profile_card.dart`). Acceptance (`-d flutter-tester`): `palette_test.dart` (AC-8) **1✅**; `smoke_test.dart` **13✅/1-skip** (the AC-9 pending exemplar). Siblings one at a time: bs-06 `palette_test` **21✅/2** (only AC-3 + AC-5 fail — both carried known off-lane flakes, owner bs-06; AC-4 add-paint flow green through the new pill); bs-07 `self_assessment_test` **23✅/1** (only AC-4, carried known off-lane flake, owner bs-07; the self-assessment entry nav the retake pill reaches is green).
- **Grade gate: PASS** (independent fresh-subagent grader; grid `../behavior-test-completeness-bs-18-apply-visual-components.md`): AC-8 **straight A** (the add-absent augmentation discriminates against BASE; closed). AC-1..AC-7 carry prior **A** forward (bodies untouched). **Straight A = 8 (AC-1..AC-8), A-core/B-pending = 0, plain-B = 0.**
- **Fix passes: 1/3** — one fix pass after the first full run: the `smoke_test.dart` pending-gate exemplars still asserted AC-8 pending (the AC I un-pended); re-pointed them to AC-9. Every other gate passed on the first run.

### Checkpoint / Handoff — after ORG-1

- **Frozen interfaces (this phase):** `PaintListRegion` renders the add-from-dataset action (`addPaintKey`) as a `PillButton.secondary`; `VisionProfileCard` renders its panel as a `SurfaceCard` (keyed `regionKey`) and its retake action (`retakeKey`) as a `PillButton.secondary`. A later phase restyling Palette must keep the add action and retake as `PillButton`s and the vision panel a `SurfaceCard`, or AC-8 / the sibling `palette_screen_test` wiring reddens. The palette selector + provenance legend stay stock (ORG-2 / GUARD do not own them either).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout` on macOS): unit+cov `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <BASE>`; AC-8 `flutter test -d flutter-tester integration_test/visual_application/palette_test.dart`; smoke `flutter test -d flutter-tester integration_test/visual_application/smoke_test.dart`; bs-06 `flutter test -d flutter-tester integration_test/palette_test.dart`; bs-07 `flutter test -d flutter-tester integration_test/self_assessment_test.dart` (run suites one at a time — loading two visual_application files in one invocation hits the documented "Unable to start the app" launch flake on the second).
- **Known gaps / next:** ORG-2 (AC-9, projects) is startable next — same `lib/palette`/`lib/projects` dir, so it runs *after* ORG-1 (not concurrently). CFG-1 (AC-10) remains independently startable. GUARD-1 now waits only on ORG-2 + CFG-1 (FLOW half already done). Carried off-lane flakes (bs-06 palette AC-3/AC-5, bs-07 self_assessment AC-4, bs-08 display AC-9) stay open in the Known flakes table — reproduce at merge-base, not regressions.

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
