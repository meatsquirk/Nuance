# Behavior-test completeness — bs-20 UI improvements (ITEST-2, readout_test.dart)

Graded independently against the fixed rubric (grade A = every Given checked through
the public surface, the When through the real surface, every Then asserted tightly
enough that a wrong implementation fails, nothing extra). Six readout acceptance
tests reviewed: AC-1, AC-2, AC-3, AC-4, AC-5, AC-9. All are PENDING; each was
verified to fail at the red baseline on a Then (or on a Given precondition that
names its owning phase), never on a missing widget.

**Result: 6 A, 0 B.** Every test checks its Given(s) through the public readout
(`givenReadoutOf` + a real render assertion), drives the When through the real
assembled app (the single `buildApp` entry), and asserts each Then at the grain
the catalogue requires while rejecting both of the catalogue's "Rejects". The
swatch/size, font-size, signature, selected-Semantics and copy-spelling checks are
all raw observables scoped to the owning region or the readout Scaffold, so a
lingering shell/selector cannot satisfy them. The two heuristic Thens (AC-5's
example-marker regex, AC-2's `contains('2')`) were examined specifically and are
adequate within their bounded domains (see Notes).

| AC | Test | Grade | Rule(s) if B | Note |
|---|---|---|---|---|
| AC-1 | `AC-1` hero card as largest reading | A | — | Both Rejects covered: bordered-ancestor check rejects a plain row with no card; the strict `lightnessSize > fontSize(other)` loop over all scaffold paragraphs (header + action-bar excluded, with reason) rejects a card that is not the largest reading. `58` scoped to the value region, so an all-spaces `L* 58` lands in `others` and must be strictly smaller — correct. `_isBordered` treats any `Card` as bordered, which still rejects the catalogue's "plain row, no card". |
| AC-2 | `AC-2` 0–10 scale, value 2 marked | A | — | Given re-asserted through the public readout (`find.text('Munsell value 2')`), not assumed. All 11 steps 0..10 checked individually. Marked step = exactly one selected `Semantics` (`findsOneWidget` rejects "no marked step"); `contains('2')` uniquely identifies step 2 among the 0–10 labels (no other label in 0..10 carries the digit 2), so it rejects a wrong marked step. Double `givenReadoutOf` call is wasteful but harmless. |
| AC-3 | `AC-3` equal swatches | A | — | Grayscale keyed `Container` size vs the single `DecoratedBox` inside the displayed-colour `ColorChip`; both are the painted swatch box (border is painted inside, so it does not change size). `findsOneWidget` on the chip's `DecoratedBox` confirms the simulation-off single-swatch path. `equals(graySize)` rejects different size (16×16 vs 48×48 at baseline). Fair. |
| AC-4 | `AC-4` all spaces, no selector | A | — | All four spaces asserted *simultaneously* via mutually distinct signatures (°/deg, `10R`, hex, r,g,b triplet, CIELAB a* 25.27 / b* 22.75) inside the `allSpaces` region only — rejects "only one shown". `SpaceSelector` `findsNothing` rejects a selector left present. Values scoped to the all-spaces region, so a lingering selector's single-space `valuesKey` text cannot satisfy them. |
| AC-5 | `AC-5` open space name → definition + example | A | — | Scenario-Outline coverage: loops all four `ReadoutSpace.values` (matches the 4 Examples). Before/after pair (definition `findsNothing` after settle → `findsOneWidget` after tap) rejects "tapping shows nothing"; the openable-name Given check rejects "name not tappable". The example regex `e.g.|example|for instance` rejects "definition without an example" and is not coupled to specific copy. Mild heuristic risk only: prose that uses the word "example" without giving one would pass — contrived, and the catalogue's named Reject (a bare definition with no example marker) is rejected. |
| AC-9 | `AC-9` "Color" not "Colour" | A | — | Scoped to the readout `Scaffold` (ancestor of the value region). `isNot(contains('colou'))` catches any British "colour/colours/coloured" (rejects "any Colour left"); `\bcolor\b` positive control proves "Color" is actually present (so deleting all colour words would not pass), and the word boundary means it does not match "colour". Red baseline fails on the shell's "Displayed colour". |

## Notes on the two heuristic Thens (examined on request)

- **AC-5 example regex** — The Then "an example accompanies the definition" has no
  cleaner raw observable than copy content; a presence check for an example-marker
  phrase is the tightest reasonable proxy and rejects the catalogue's Reject (a
  definition with no example). It is not copy-coupled (accepts any of three
  markers). The only false-positive is prose that uses "example" without giving
  one — contrived enough not to cost the A.
- **AC-2 `contains('2')`** — Over a fixed 0–10 label domain, the digit 2 appears
  only in step 2's own label, so the marked-step assertion rejects a wrong marked
  step. It would be looser on a larger numeric range, but the scale is bounded to
  0..10, so it is sound here.

---

# ITEST-3 — settings / Speak (settings_test.dart)

Three settings/Speak acceptance tests graded against the same rubric by a fresh
independent grader: AC-6, AC-7, AC-8. All PENDING.

**Result: 3 A, 0 B** (cumulative suite: **9 A, 0 B**). All drive the real
assembled app via `givenReadoutOf` → `buildApp`, configure state through the live
`DisplayController` (the same `setAccessibilityFeatures` the shipped panel
drives — G2 clean), and anchor Thens on real keyed surfaces (the shipped
`SwitchListTile`, the real `ActionsBar` Speak control).

| AC | Test | Grade | Rule(s) if B | Note |
|---|---|---|---|---|
| AC-6 | `AC-6` accessibility off by default | A | — | **Green at baseline** (the A11Y-1 shell already ships `accessibilityFeatures = false`). Not downgraded: Given re-asserted through the controller (`settings.accessibilityFeatures isFalse`) before the When; Then is the exact raw observable (`SwitchListTile.value isFalse`, `findsOneWidget`); the in-test control drives the set on and asserts the toggle reads `isTrue`, rejecting a constant-off render. Rejects toggle-defaulting-on, toggle-absent, hardcoded-off. Kept pending (owner A11Y-2), flagged for the G-2 review. |
| AC-7 | `AC-7` Speak hidden while off | A | — | Off Given re-asserted; readout-shown When via real render. Negative Then (`speakControl findsNothing`) after `pumpAndSettle`, paired with a control that turns accessibility on and asserts Speak appears (G3) — so off→hidden is not vacuous. Primary rejects the always-shown `ActionsBar` (the baseline red); control rejects a never-rendered Speak. Keeps its own AC (on→shown is the control). |
| AC-8 | `AC-8` Speak shown when on | A | — | Off Given re-asserted; When verified to have taken (`settings.accessibilityFeatures isTrue`) and readout shown. Primary `speakControl findsOneWidget` after turning the named setting on via the real controller; in-test control `findsNothing` while off (the baseline red) rejects an always-shown Speak. Binding is to the named flag specifically (a Speak gated on a different flag would fail). Keeps its own AC (off→hidden is the control). |

## Notes — ITEST-3

- **AC-6 green at baseline.** The "off by default" behaviour is already satisfied
  by the A11Y-1 shell's `DisplaySettings.accessibilityFeatures = false`. The test
  is tight and discriminating (a constant-off render fails the control), so the
  grade stands at A, but it passes at the red baseline rather than failing. It is
  **not** un-pended here: doing so would leave its owner A11Y-2 with no pending AC
  against the smoke "no dead phase" guard (and no honest basis to mark A11Y-2
  complete). Whether A11Y-2 is still needed (keep-green + unit coverage) or the AC
  should be accepted as shell-satisfied is a decision for the ITEST-4 test review
  (G-2).
- **AC-7 / AC-8 pair.** Each asserts its own direction as the primary Then and
  carries the opposite as an in-test control, so neither is vacuous. The pairing
  is complete in this phase — the pre-seeded READOUT-7 augmentation ("pair both
  directions") is therefore satisfied in-phase and not carried forward.

---

# READOUT-4 re-grade — un-pended tests against built behaviour (2026-10-25)

Fresh independent re-grade of every **un-pended** AC test now that its behaviour
is built — AC-1, AC-3 (READOUT-4), AC-4 (READOUT-3), AC-6 (A11Y-2). Graded by
reading the built `lib/readout/value_region.dart` / `color_chip.dart` /
`surface_card.dart` and the tests.

**Result: 4 A, 0 B.** No downgrades against G1–G6; consistent with the pending
grid above.

- **AC-1** A — "58" is inside the keyed, bordered `SurfaceCard`
  (`Border.all(outlineVariant, 2px)` → `_isBordered`) at `prominentFontSize` 48,
  and strictly out-sizes every other readout paragraph (AppBar ~22pt, body ~14pt;
  header + actions-bar + lightness paras excluded). Rejects a plain row and a
  value not rendered largest (strict `greaterThan`).
- **AC-3** A — `ValueRegion.swatchSize = 48` feeds both the grayscale `Container`
  and `ColorChip(swatchSize: 48)`; the single simulation-off `DecoratedBox`
  measures 48×48 == the grayscale box. Rejects the baseline 48-vs-16 mismatch.
- **AC-4** A (still holds) — all four space signatures asserted simultaneously in
  the all-spaces region; `SpaceSelector findsNothing`.
- **AC-6** A (still holds) — keyed `SwitchListTile` defaults `false`, re-asserted
  through the live controller, with an on-control that rejects a constant-off
  render.

# READOUT-5 re-grade — un-pended tests against built behaviour (2026-10-25)

Fresh independent re-grade of every **un-pended** AC test now that AC-2's
behaviour is built — AC-1, AC-2 (READOUT-5), AC-3 (READOUT-4), AC-4 (READOUT-3),
AC-6 (A11Y-2). Graded by a fresh subagent reading the built
`lib/readout/value_scale.dart` / `readout_screen.dart` and the tests, given the
re-grades above as the baseline.

**Result: 5 A, 0 B.** No downgrades against G1–G6; consistent with the grids
above. AC-2 is the newly un-pended one and earns A on the same rubric.

- **AC-2** A — `value_scale.dart` renders all 11 steps 0..10 (each `find.text`
  checked individually) and marks exactly the sample's step via
  `markedStep = value.round().clamp(0,10)` wrapped in the single
  `Semantics(selected: true, label: 'Value N, this sample')`, driven by the real
  `controller.munsell.value` (G1/G2 clean — the derived value answers, not a
  script). Rejects all three named wrong impls: a bare "Munsell value 2" with no
  scale (the 11 labelled steps must exist under `valueScale`), no marked step
  (`findsOneWidget` on the selected Semantics), and a wrong marked step
  (`contains('2')` is unique over the bounded 0..10 label domain).
- **AC-1 / AC-3 / AC-4 / AC-6** A (unchanged) — see the READOUT-4 re-grade above;
  READOUT-5 touched only `value_scale.dart` + `readout_screen.dart` (and two
  sibling-feature harness viewports), so none of these tests' behaviour moved.

# READOUT-6 re-grade — un-pended tests against built behaviour (2026-10-25)

Fresh independent re-grade of every **un-pended** AC test now that AC-5's
behaviour is built — AC-1, AC-2, AC-3, AC-4, AC-5 (READOUT-6), AC-6. Graded by a
fresh subagent reading the built `lib/readout/space_definition.dart` /
`all_spaces_region.dart` and the tests, given the grids above as the baseline,
with adversarial scrutiny on AC-5.

**Result: 6 A, 0 B.** No downgrades against G1–G6; consistent with the grids
above. AC-5 is the newly un-pended one and earns A.

- **AC-5** A — `space_definition.dart` renders each space's name as a production
  `InkWell` keyed `nameKey` wrapping `Text(label)`, and reveals the
  `definitionFor(space)` copy under `definitionKey` only while `_open`. The test
  loops all four `ReadoutSpace.values` (matches the 4 Examples), checks the
  openable-name Given (`find.descendant(of: nameKey, matching: textContaining(label))`)
  and the definition-hidden precondition (`findsNothing`) before the tap, then
  asserts the definition is shown (`findsOneWidget`), non-empty, and carries an
  example marker after the tap. Rejects all three named wrong impls: name not
  tappable (no toggle → definition never built → `findsOneWidget` fails), tapping
  shows nothing (before/after pair), and a definition with no example (the
  `e.g.|example|for instance` regex). G2 clean — the definition comes from
  production `definitionFor`, not a script. The example-marker is a bounded
  heuristic proxy (the prior grid accepted it at A); all four built definitions
  carry a real example.
- **AC-1 / AC-2 / AC-3 / AC-4 / AC-6** A (unchanged) — see the re-grades above;
  READOUT-6 touched only `space_definition.dart` + `all_spaces_region.dart`
  (moved the plain-text label into the tappable name; values still rendered per
  space), so none of these tests' behaviour moved. AC-4's signatures still
  resolve under the all-spaces region and `SpaceSelector` is still absent.

# READOUT-8 re-grade — un-pended tests against built behaviour (2026-10-25)

Fresh independent re-grade of every **un-pended** AC test now that AC-9's
behaviour is built — AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-9 (READOUT-8).
AC-7/AC-8 stay pending (owner READOUT-7, gate-blocked by G-3). Graded by a fresh
subagent reading the built `lib/readout/value_region.dart` (`ColorChip(label:
'Displayed color')`) / `space_definition.dart` (now American "color" copy) /
`color_chip.dart` and the tests, given the grids above as the baseline, with
adversarial scrutiny on AC-9.

**Result: 7 A, 0 B.** No downgrades against G1–G6; consistent with the grids
above. AC-9 is the newly un-pended one and earns A.

- **AC-9** A — `TestAC09_ColorSpelling` scopes to the readout `Scaffold` (ancestor
  of `valueRegion`) and reads the aggregate rendered plain text — the right grain
  for a "user-facing copy" step (G4). `isNot(contains('colou'))` rejects any
  lingering British "colour/colours/coloured" (fails the pre-READOUT-8 shell's
  `'Displayed colour'` — the named Reject); `\bcolor\b` (word-boundary,
  case-insensitive) positively proves "Color" renders, so deleting every colour
  word would **not** pass (rejects the vacuous-pass impl) and doubles as the
  non-vacuity control (G3). Given ("reading a sample") checked via
  `find.text('Warm Terracotta')` (G1); When drives the real `buildApp`; the copy
  comes from the production `ColorChip(label: 'Displayed color')` →
  `Flexible(child: Text(label))` → RenderParagraph, not a script (G2); one AC per
  test (G6). The grader verified every remaining "colou" under `lib/readout/` sits
  in a `///`/`//` comment or an `assert()` message (`color_chip.dart:36`,
  `status_badge.dart:16`) — never added to the widget tree.
- **AC-1 / AC-2 / AC-3 / AC-4 / AC-5 / AC-6** A (unchanged) — READOUT-8 changed
  only user-facing copy spelling (`value_region.dart` chip label +
  `space_definition.dart` definition prose), no font size, no box size, no
  structure; AC-5's example-marker regex is still satisfied by the now-American
  definition copy and AC-5 never asserts spelling, so none of these tests'
  behaviour moved.

## READOUT-7 re-grade (2026-10-25) — full suite, AC-7/AC-8 now delivered

Fresh independent re-grade of the **full** bs-20 acceptance suite now that
READOUT-7 has delivered the Speak-gating behaviour for AC-7 and AC-8 (all 9 ACs
un-pended). Graded by reading the built `lib/readout/actions_bar.dart` (Speak
wrapped in `if (showSpeak)`, `showSpeak = DisplayScope.maybeOf(context)?.settings
.accessibilityFeatures ?? false`), `lib/display/display_scope.dart` /
`display_controller.dart` (the live `accessibilityFeatures` field + its setter),
and the two test files, with adversarial scrutiny on AC-7/AC-8 per the phase
deltas.

**Result: 9 A, 0 B.** No downgrades against G1–G6; consistent with every grid
above. AC-7 and AC-8 are the newly un-pended pair and each earns A on the same
rubric.

| AC | Test | Grade | Rule if B | Note |
|---|---|---|---|---|
| AC-1 | `AC-1` hero card as largest reading | A | — | Unchanged by READOUT-7 (`actions_bar.dart` only). Bordered-ancestor check + strict `greaterThan` size loop over all scaffold paras (header + bar excluded) reject both Rejects. |
| AC-2 | `AC-2` 0–10 scale, value 2 marked | A | — | Unchanged. 11 steps checked individually; exactly one selected `Semantics`; `contains('2')` unique over the bounded 0..10 label domain. |
| AC-3 | `AC-3` equal swatches | A | — | Unchanged. `equals(graySize)` on the grayscale box vs the single simulation-off `DecoratedBox` rejects the 48-vs-16 baseline mismatch. |
| AC-4 | `AC-4` all spaces, no selector | A | — | Unchanged. Four mutually-distinct signatures asserted together under the all-spaces region; `SpaceSelector findsNothing`. |
| AC-5 | `AC-5` open space name → definition + example | A | — | Unchanged. Loops all four spaces; before/after reveal pair; example-marker regex rejects a definition with no example. |
| AC-6 | `AC-6` accessibility off by default | A | — | Unchanged. Keyed `SwitchListTile` defaults `false` (re-asserted through the live controller); on-control rejects a constant-off render. |
| AC-9 | `AC-9` "Color" not "Colour" | A | — | Unchanged. `isNot(contains('colou'))` rejects any British spelling; `\bcolor\b` positive control proves "Color" renders and defeats a vacuous delete-all-colour-words pass. |
| AC-7 | `AC-7` Speak hidden while off | A | — | **Newly delivered.** Off Given re-asserted (`settings.accessibilityFeatures isFalse`, G1); When via the real `buildApp` readout render (`find.text('Any Sample')`). `_useTallReadoutView` (1200×3000) lays the whole lazy `ListView` out so the actions bar IS built — the negative Then `speakControl findsNothing` therefore means Speak is genuinely absent, not merely below the fold (G3). Paired in-test control turns accessibility on via the real controller and asserts `findsOneWidget`, so off→hidden is non-vacuous (G3/G5, rejects a never-rendered Speak). The control flips only `accessibilityFeatures`, so a Speak gated on any other flag would not appear — binding to the named flag is proved (G2/G4). Rejects the always-shown baseline bar. |
| AC-8 | `AC-8` Speak shown when on | A | — | **Newly delivered.** Off Given re-asserted (G1); in-test control asserts `speakControl findsNothing` while off (rejects an always-shown Speak); When drives the real `setAccessibilityFeatures(on:true)` and verifies it took (`settings.accessibilityFeatures isTrue`, G2) with the readout shown; primary Then `speakControl findsOneWidget` keyed on the real `ActionsBar.speakKey`. `_useTallReadoutView` guarantees the bar is laid out so the control's `findsNothing` is meaningful (G3). Binds to the specific `accessibilityFeatures` flag — flipping only that field reveals Speak, so a different-flag gate fails (G2/G4). Rejects Speak-absent-after-on. |

**Result: 9 A, 0 B.** No grade changed from the previous (pending / READOUT-8)
grids. AC-7 and AC-8 were graded A as pending tests and remain A now that their
behaviour is built: the adversarial checks the phase called out all hold — the
tall-viewport addition makes `findsNothing` a real "hidden" (not off-screen), each
direction is paired with a real opposite-direction control (neither passes
vacuously), and the gate binds to the named `accessibilityFeatures` flag through
the live controller + `DisplayScope`, not a script or fake. AC-1–AC-6/AC-9 are
untouched by READOUT-7 (it edits only `actions_bar.dart`), so their A grades carry
forward unchanged.

---

# Fresh grade — bs-20 UI-improvements acceptance suite (all ACs un-pended) — SIGNOFF-1

Graded independently and from scratch against rubric A (fresh subagent, 2026-10-25), reading `readout_test.dart`, `settings_test.dart`, `harness.dart`, `pending.dart` and the `.feature` spec. The pending map is empty (every AC delivered). Every test drives the real assembled app through the single `buildApp` entry via `givenReadoutOf`, checks its Given(s) through the public surface (rendered sample name, or the live injected DisplayController), and asserts each Then tightly enough that both of the catalogue's Rejects fail. The grader's judgment matches the prior (pending-era) grid — no downgrades.

**Result: 9 A, 0 B**

| AC | Test | Grade | Rule(s) if not A | Note |
|---|---|---|---|---|
| AC-1 | hero card as largest reading | A | — | Sample shown checked via `find.text('Warm Terracotta')`; 58 is a fixture property re-proven through the hero card at the Then. Bordered-ancestor check rejects a plain row; strict `greaterThan` font-size loop over all scaffold paragraphs (name header + actions-bar + lightness paras excluded, with reason) rejects a value that isn't the largest reading. Excluding the name header is correct — spec says largest *reading*, not title. |
| AC-2 | 0–10 scale, value 2 marked | A | — | Given re-asserted through public readout (`find.text('Munsell value 2')`). All 11 steps 0..10 checked individually; exactly one selected `Semantics` (findsOneWidget rejects no-mark); `contains('2')` uniquely identifies step 2 over the bounded 0..10 label domain, rejecting a wrong mark. Double `givenReadoutOf` is wasteful but harmless. |
| AC-3 | equal swatches | A | — | Grayscale keyed box vs the single simulation-off `DecoratedBox` in the displayed-colour ColorChip; `equals(graySize)` rejects the 48-vs-16 baseline mismatch. findsOneWidget on the chip's DecoratedBox confirms the single-swatch path. |
| AC-4 | all spaces, no selector | A | — | Four mutually-distinct signatures (°/deg, 10R, hex, integer r,g,b triplet, CIELAB a* 25.27 / b* 22.75) all asserted simultaneously scoped to the all-spaces region, rejecting "only one shown"; `SpaceSelector findsNothing` rejects a lingering selector. Triplet regex requires integers so it can't be satisfied by the decimal CIELAB values. |
| AC-5 | open space name → definition + example | A | heuristic (acceptable) | Loops all four `ReadoutSpace.values` (matches 4 Examples). Openable-name Given + definition-hidden precondition before the tap; after-tap findsOneWidget + non-empty + example-marker regex forms a before/after pair rejecting "tap shows nothing" and "no example". Example regex is a bounded proxy; false positive (prose saying "example" without one) is contrived — holds A. |
| AC-6 | accessibility off by default | A | — | Given re-asserted through the live controller; Then is the exact observable (`SwitchListTile.value isFalse`, present); in-test control drives it on and asserts isTrue, rejecting a constant-off render. Rejects default-on and absent-toggle. Note: green at the shell baseline, but tight and discriminating. |
| AC-7 | Speak hidden while off | A | — | Off Given re-asserted; tall viewport (1200×3000) lays the whole lazy ListView/actions bar out so `speakControl findsNothing` means genuinely absent, not off-screen. Paired control turns accessibility on and asserts Speak appears, so off→hidden is non-vacuous. Binds to the named flag via the real controller. |
| AC-8 | Speak shown when on | A | — | Off Given + in-test control `findsNothing` while off (rejects always-shown). When flips only `accessibilityFeatures` via the real controller and verifies it took; primary Then `findsOneWidget` on the real ActionsBar.speakKey. Tall viewport makes the findsNothing control meaningful. |
| AC-9 | "Color" not "Colour" | A | — | Scoped to the readout Scaffold. `isNot(contains('colou'))` rejects any British spelling (fails the pre-READOUT-8 "Displayed colour" shell); `\bcolor\b` positive control proves "Color" actually renders, defeating a vacuous delete-all-colour-words pass. |

## Heuristic Thens examined
- **AC-5 example regex** (`e.g.|example|for instance`): tightest reasonable proxy for "an example accompanies the definition"; not copy-coupled, rejects the named Reject (bare definition). Only contrived false positive. Holds A.
- **AC-2 `contains('2')`**: sound because the label domain is fixed at 0..10 where the digit 2 appears only in step 2; would be looser on a wider range. Holds A.

Difference from prior grid: none — independent read confirms 9 A, 0 B.
