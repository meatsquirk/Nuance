# Module GUARD — app-wide guards (swatch caption, single theme, a11y, source-scan)

**Status:** ✅ Done — GUARD-1/2/3 all landed (AC-11..14 un-pended); module complete → SIGNOFF-1
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/visual_application/` guard checks and the extended source-scan rule (`integration_test/conformance/checks/` or the design-system suite); small corrective edits across any `lib/**` screen a guard flags.
**Depends on:** CHROME-3/4, READ-3, FLOW-2, ORG-2, CFG-1 (every screen swapped) · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| GUARD-1 | behavior | AC-12 | ✅ Done | 2.29M | 4m 30s |
| GUARD-2 | behavior | AC-11, AC-14 | ✅ Done | 2.15M | 4m 53s |
| GUARD-3 | behavior | AC-13 | ✅ Done | 3.94M | 12m 34s |

## Interface reconciliation

These are cross-cutting sweeps that run after every screen is swapped, so their Givens ("a screen that
displays swatches", "swapped `lib/**`") are only fully real once CHROME/READ/FLOW/ORG/CFG are done — hence
they sit last (D-5). GUARD reuses bs-11's `checks/target.dart` and the theme contrast test (AC-13) and the
bs-17 AC-14 source-scan rule (AC-11/AC-14). Any screen a guard flags gets a minimal corrective edit here.

## Open gates

G-2 blocks all three phases; each also depends on every screen behavior phase.

## Phase GUARD-1 — behavior: swatch caption everywhere (AC-12)

- **Kind:** behavior
- **Target AC:** AC-12 (full)
- **Depends on:** all screen behavior phases · **Blocks:** GUARD-2
- **Files:** any swatch-bearing screen missing its caption; the AC-12 sweep test.
- **Tasks:**
  1. Ensure every screen that displays colour swatches renders exactly one `SwatchCaption` beside its swatch group (extend from the 3 screens that already have it to all).
- **Exit criteria:** sweep finds one caption per swatch-bearing screen, none on non-swatch screens; sibling suites green.
- **Acceptance gate:** un-pend AC-12; `TestAC12_SwatchCaption` green with earlier ACs.
- **Augments:** `TestAC12`: enumerate all swatch-bearing screens so the sweep covers every one, not only the 3 pre-wired.

### Result — GUARD-1 (✅ Done)

- **What landed:** AC-12 un-pended. No `lib/**` change was needed — the swap phases (notably CFG-1's result-step
  `SwatchCaption`) already kept the invariant, so at the current tree every swatch-bearing screen renders exactly
  one caption. GUARD-1 verified the sweep over the fully-swapped roster, removed `AC-12` from `pendingACs`
  (`pending.dart`), and added `AC-12` to the smoke gate's two un-pended lists (`smoke_test.dart`).
- **Acceptance:** `TestAC12_SwatchCaption` green — run-pending probe passed first (every roster swatch screen
  already captioned), then default-mode run: AC-12 runs green while AC-11/AC-13/AC-14 still skip as expected.
  `smoke_test` green (the seed-drain self-check now expects AC-12 un-pended).
- **Augmentation:** `TestAC12` enumerate-all-swatch-screens was satisfied at ITEST-4 (the sweep is dynamic over
  every `ColorChip`-bearing roster screen + missing/duplicate controls); GUARD-1 un-pends and keeps it green.
  No change to the test's assertions.
- **Unit + coverage:** no touched `lib/**` — coverage gate PASS (nothing to gate). No unit test changed.
- **Grade:** AC-12 **A** carried from ITEST-4 (test unchanged; un-pend only). **Fix passes: 0/3.**
- **Siblings:** no `lib/**` change ⇒ no regression surface; carried off-lane flakes (bs-06 palette AC-3/AC-5,
  bs-08 display AC-9) unchanged, not re-run.
- **Tokens / time:** 2.29M / 4m 30s (4m 30s).

### Checkpoint / Handoff — after GUARD-1

- **Frozen interfaces (this phase):** `pendingACs` now holds only AC-11 (GUARD-2), AC-13 (GUARD-3), AC-14
  (GUARD-2). AC-12 is green and always runs. `TestAC12` is the standing swatch-caption regression guard over the
  full roster; any later screen edit that drops/duplicates a caption reddens it.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout` on macOS):
  AC-12 `flutter test -d flutter-tester integration_test/visual_application/guards_test.dart` (default = AC-12
  runs, AC-11/13/14 skip; `--dart-define=BS18_RUN_PENDING=true` runs all four); gate self-check
  `flutter test -d flutter-tester integration_test/visual_application/smoke_test.dart`; coverage gate
  `dart run tool/coverage_gate.dart <BASE>`.
- **Known gaps / next:** **GUARD-2** (AC-11 single theme + AC-14 source-scan) is now unblocked — un-pend AC-11
  and AC-14, assert no swapped screen wraps a child in its own `Theme`/`MaterialApp`, and extend the bs-17
  source-scan over the swapped screens (reuse the exact camera-device + colour-data exclusion list). Both guards
  are green at baseline (ITEST-4 ground truth); GUARD-2 un-pends + keeps green, fixing any flagged screen. Then
  GUARD-3 (AC-13 a11y) → SIGNOFF-1, sequentially.

## Phase GUARD-2 — behavior: single theme + source-scan (AC-11, AC-14)

- **Kind:** behavior
- **Target AC:** AC-11 (full) + AC-14 (full)
- **Depends on:** GUARD-1 · **Blocks:** GUARD-3
- **Files:** the AC-11 nested-theme sweep test; the extended AC-14 source-scan rule; any screen flagged.
- **Tasks:**
  1. Assert no swapped screen wraps a child subtree in its own `Theme`/`MaterialApp`; fix any that does.
  2. Extend the bs-17 AC-14 source-scan to the swapped screens, reusing the exact exclusion list (camera-device + colour-data modules); route any residual literal through the theme.
- **Exit criteria:** nested-theme count == 0 under each screen; source-scan clean; sibling suites green.
- **Acceptance gate:** un-pend AC-11 and AC-14; `TestAC11_SingleTheme` + `TestAC14_NoHardcodedPalette` green with earlier ACs.

### Result — GUARD-2 (✅ Done)

- **What landed:** AC-11 and AC-14 un-pended. No `lib/**` change was needed — the ITEST-4 ground-truth probe
  already held at the fully-swapped tree: every harness-reachable screen installs exactly one `MaterialApp`
  with no scheme-overriding `Theme`, and `lib/` carries zero residual palette `Color(0x..)` literals outside the
  bs-17 exclusions (`kThemeAuthorityFile` + `kCaptureDeviceLiteralFiles`). The task's "extend the source-scan
  over the swapped screens" is already met: `TestAC14` scans `roots: ['lib']`, which covers every swapped
  screen, with the exact bs-17 exclusion list. GUARD-2 removed `AC-11` and `AC-14` from `pendingACs`
  (`pending.dart`) and updated the smoke gate's bookkeeping (the skip-by-default proof moved AC-11 → the last
  pending AC-13; AC-11 + AC-14 added to the never-skip and seed-drain lists; the wiring-smoke planted AC moved
  AC-11 → AC-13).
- **Acceptance:** run-pending probe first — all four guards (AC-11/12/13/14) green with their discriminating
  controls. Default-mode run after un-pend: AC-11 ✅, AC-12 ✅, AC-14 ✅ run green while AC-13 skips (owner
  GUARD-3). `smoke_test` green (13 pass / 1 skip = the planted AC-13 wiring).
- **Unit + coverage:** no touched `lib/**` — coverage gate PASS (nothing to gate). No unit test changed.
- **Grade:** AC-11 **A** and AC-14 **A** carried from ITEST-4 (tests unchanged; un-pend only, like GUARD-1's
  AC-12). **Fix passes: 0/3.**
- **Siblings:** no `lib/**` change ⇒ no regression surface; carried off-lane flakes (bs-06 palette AC-3/AC-5,
  bs-08 display AC-9) unchanged, not re-run.
- **Tokens / time:** 2.15M / 4m 53s (4m 53s).

### Checkpoint / Handoff — after GUARD-2

- **Frozen interfaces (this phase):** `pendingACs` now holds only AC-13 (GUARD-3). AC-11/AC-12/AC-14 are green
  and always run. `TestAC11_SingleTheme` (one `MaterialApp`, no scheme override) and
  `TestAC14_NoHardcodedPalette` (bs-17 source-scan over `lib/`) are now standing regression guards; any later
  edit that nests a theme/app or hardcodes a palette literal reddens them.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout` on macOS):
  guards `flutter test -d flutter-tester integration_test/visual_application/guards_test.dart` (default = AC-11/
  12/14 run, AC-13 skips; `--dart-define=BS18_RUN_PENDING=true` runs all four); gate self-check
  `flutter test -d flutter-tester integration_test/visual_application/smoke_test.dart`; coverage gate
  `dart run tool/coverage_gate.dart <BASE>`.
- **Known gaps / next:** **GUARD-3** (AC-13 a11y regression) is now unblocked — un-pend AC-13, run the bs-11
  tap-target (≥48dp) + AA-contrast sweep over every swapped screen (the test already does this with
  discriminating 24dp + low-contrast controls and was green run-pending here), fixing any control that
  regressed. That un-pends the last pending AC, taking the suite to 0 pending — the gate into **SIGNOFF-1**.

## Phase GUARD-3 — behavior: a11y regression (AC-13)

- **Kind:** behavior
- **Target AC:** AC-13 (full)
- **Depends on:** GUARD-2 · **Blocks:** SIGNOFF-1
- **Files:** the AC-13 app-wide target/contrast sweep (reusing bs-11 checks); any control the sweep flags.
- **Tasks:**
  1. Run the bs-11 tap-target (≥48dp) and WCAG AA contrast checks over every swapped screen; fix any pill/FAB/nav item/label that regressed.
- **Exit criteria:** every interactive control ≥48dp; every text pairing ≥ AA across screens; bs-11 conformance suite green.
- **Acceptance gate:** un-pend AC-13; `TestAC13_A11yPreserved` green with all earlier ACs; the full suite green (0 pending) — the gate into SIGNOFF-1.

### Result — GUARD-3 (✅ Done)

- **What landed:** AC-13 un-pended — **all 14 bs-18 ACs now delivered; `pendingACs` is exactly `{}`.** No
  `lib/**` change was needed: the a11y sweep already held at the fully-swapped tree. Run-pending over the full
  roster (Readout shell, Capture, Compare, Recipes, Palette, Display settings, Onboarding), the reused bs-11
  conformance check reported every interactive control ≥48dp (`tapTarget48` pass) and every text pairing ≥ AA
  (`contrastAA` pass) on every screen; the test's discriminating controls (a 24dp target, a ~1.6:1 pairing)
  still fail the rules, so the sweep is non-vacuous. GUARD-3 emptied `pendingACs` (`pending.dart`) and moved the
  smoke gate to its terminal (drained-map) form, mirroring bs-17's completed suite: the directional proof became
  "with every AC delivered the gate runs them all in either mode" (asserts `pendingACs.isEmpty` + every
  AC-1..AC-14 runs in both modes), the seed-drain test now lists AC-13 among the un-pended (so `pendingACs`
  equals the empty expected map), and the planted AC-13 wiring smoke became a delivered-AC smoke.
- **Acceptance:** run-pending probe first — all four guards green with their controls. Default-mode run after
  un-pend: `guards_test` +4 (AC-11/12/13/14 all run, 0 skip); `smoke_test` +14 (0 skip; the AC-13 wiring smoke
  now runs). Full `visual_application/` sweep per-file (whole dir won't launch at once): all 10 files green,
  **0 pending** — the gate into SIGNOFF-1.
- **Unit + coverage:** no touched `lib/**` — coverage gate N/A (nothing to gate). No unit test changed.
- **Siblings:** no `lib/**` change ⇒ no regression surface; carried off-lane flakes (bs-06 palette AC-3/AC-5,
  bs-08 display AC-9) unchanged, not re-run (GUARD-1/GUARD-2 reasoning).
- **Grade:** AC-13 **A** carried from ITEST-4 (the AC test is unchanged; GUARD-3 un-pends it and edits only the
  scaffold bookkeeping, which keeps its non-vacuous invariants in the bs-17-A-graded drained form). SIGNOFF-1
  produces the authoritative fresh full-suite grid. **Fix passes: 0/3.**
- **Tokens / time:** 3.94M / 12m 34s (12m 34s).

### Checkpoint / Handoff — after GUARD-3

- **Frozen interfaces (this phase):** `pendingACs` is now empty — the behaviour stage is complete; every
  AC-1..AC-14 runs by default. `TestAC13_A11yPreserved` is a standing app-wide a11y regression guard (48dp +
  AA over the full roster); any later edit that drops a control below the floor or a pairing below AA reddens
  it. The smoke gate asserts `pendingACs` is exactly `{}`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; no `timeout` on
  macOS): guards `flutter test -d flutter-tester integration_test/visual_application/guards_test.dart`
  (default now runs all four); gate self-check
  `flutter test -d flutter-tester integration_test/visual_application/smoke_test.dart`; full suite = each
  `integration_test/visual_application/*_test.dart` run one file at a time (the whole dir won't launch at once).
- **Known gaps / next:** none owed. **SIGNOFF-1** is now unblocked (GUARD-3 was its only dependency) — assemble
  the sign-off packet + summary page, produce the authoritative fresh full-suite grade grid, set the round
  awaiting the human decision, and stop for `--signoff`.
