# Behaviour-test completeness grid — bs-01-color-readout

Graded 2026-10-06 by an independent grader (fresh context). Covers ITEST-2 display group AC-1..AC-7; ITEST-3 appends AC-8..AC-12.

Grades the assertions as written, i.e. the behaviour each pending test will exercise once its owning phase (COLOR-2/3, READOUT-2..5) lands — not whether it passes at the red baseline, where each correctly fails on a Then naming its phase.

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | TestAC01_LightnessProminent | A | G1,G2,G4,G5,G6 | Givens checked through the public surface (name "Warm Terracotta" shown) and on the input (`coordinates.lightness == 58`). Rejects not-largest (strict `greaterThan` of the Lightness font size over *every* other body paragraph, name-header + action labels excluded), missing grayscale (`grayscaleKey`), and missing Munsell value (`5.5` under the value region). Stays one-AC: the name's prominence is explicitly excluded (owned by AC-3). The generic "larger than every other body reading" makes the READOUT-4 pre-seed redundant — once the space values render they are auto-out-ranked. |
| AC-2 | TestAC02_ValueWord | A | G1,G2,G4,G5,G6 | Given L58 asserted on the controlled input. Main Then asserts a "middle" word in the value region; the dark (L15 → low/dark) and light (L90 → high) controls force the word to be *derived* from L (G2) and reject "always middle" (G5). Collision is handled: the light control asserts `high`, not `light`, so it cannot be satisfied by the "Lightness" label; the dark control uses `\b(low\|dark)\b` word-boundaries. Stays within the value region (G6). |
| AC-3 | TestAC03_ColourName | A | G1,G2,G4,G5,G6 | G2 is the point: the sample carries **no** name (`unnamed.name == null`, and the shell shows "Unnamed sample"), so a shell echoing `Sample.name` fails and the name must be derived. Prominence asserted at full grain: header-above-value (top) and name font size `>=` every other body paragraph (largest). Rejects name-absent, name-small, name-not-at-top. |
| AC-4 | TestAC04_Temperature | A | G1,G2,G4,G5,G6 | Given hue asserted on input (`_hueDegrees ≈ 42`) with the sample shown. Then asserts the **word** "warm" and `isNot(contains('42'))` — rejecting the hue angle (G4). The cool control (hue ≈ 250 → "cool", never "warm") proves derivation from hue and rejects "always warm" (G2/G5). Confined to the temperature line (G6). |
| AC-5 | TestAC05_ColourSpaceSelector | A (borderline) | G1,G3,G4,G5,G6 | Given sample shown. Exclusivity logic is **sound and collision-safe**: the four signatures (`°\|deg`, `10R`, `#` + 6 hex, `25.27`) are mutually non-substring, none is a substring of an sRGB hex (no `.`/`°`/`R` in hex), and none coincides with a value shared across spaces (e.g. `58`), so "space Y no longer shown" is unambiguous after each `whenSelectSpace` settles (G3). Present-checks hit full grain for CIELCh (58/34/42/°), Munsell (`10R`, `5.5/6`) and CIELAB (58/25.27/22.75). **Gap (minor, G4):** the spec's sRGB row is "a triplet **and** a hex value" but only the hex is asserted present — an impl that renders the hex yet omits the triplet would pass. Defensible as an A because the spec states no exact triplet value (so G4's exact-value clause does not bite) and the hex is the format-exact, collision-safe anchor; still worth tightening. |
| AC-6 | TestAC06_MeasuredBadge | A | G1,G2,G4,G5,G6 | Given asserted on input (`provenance.tier == measured`) and surface ("Measured Reading" shown). Then asserts the exact badge word "Measured" and, as the tier discriminator, `isNot` the Estimated strings ("not yet verified", "Seeded by a model") — so it does not badge every tier alike. Pairs with AC-7 as the measured/estimated control set; the in-test negatives already reject an impl that prints the estimated note on a measured reading. |
| AC-7 | TestAC07_EstimatedBadge | A | G1,G3,G4,G5,G6 | Given asserted on input + surface. Then asserts "Estimated", "not yet verified" and the **exact** note "Seeded by a model. Treat as a starting point." Carries its own in-test control: SAMPLE_MEASURED re-loaded (settled) shows no seeded note (G3), tying the note to the Estimated tier and rejecting "note on every reading". Rejects "Estimated without note" and "Measured". |
| AC-8 | TestAC08_SpeakReadout | A | G1,G2,G4,G5,G6 | *(ITEST-3; graded by an independent fresh grader 2026-10-06.)* Givens checked on surface (name shown; `speech.utterances` empty) and input (L58, `_hueDegrees`≈42, `_chroma`≈34). `hasLength(1)` rejects a fragment stream; name/58/34/42 are mutually non-colliding (the name has no digits; a\*/b\* don't spell them) so each independently rejects omitting its component; `\b(orange\|red)\b` rejects omitting the hue word (hue *family* is a defensible A — the spec fixes no exact word). **Was B (G5)**: the temperature check `lower.contains('warm')` was vacuously satisfied by the name "Warm Terracotta". **Fixed in ITEST-3** — temperature now asserted against the name-stripped utterance (`lower.replaceAll('warm terracotta','')`), so it rejects an impl that omits the separate temperature word. One AC. |
| AC-9 | TestAC09_CompareAsA | A | G1,G2,G4,G5,G6 | *(ITEST-3.)* Givens checked (name shown; `find.text('Comparison') findsNothing` = not already there). Asserts the filled **and** the empty slot at exact grain ("Slot A: Warm Terracotta" + "Slot B: (empty)", matching the stub's `'$label: ${name ?? '(empty)'}'`), rejecting "always slot B", "fills both slots" and "navigates without carrying". Control pair with AC-10. One AC. |
| AC-10 | TestAC10_CompareAsB | A | G1,G2,G4,G5,G6 | *(ITEST-3.)* Mirror of AC-9 (slot B filled, slot A empty). Together the pair rejects any "always slot X" impl — each fails exactly one. Exact stub-matched slot strings are the right grain. One AC. |
| AC-11 | TestAC11_FindRecipes | A | G1,G2,G4,G5,G6 | *(ITEST-3.)* Givens checked (name "Deep Olive Green" shown; `find.text('Recipes') findsNothing`). Then asserts the screen shown and the exact "Recipe target: Deep Olive Green" (stub renders `'Recipe target: ${name ?? '(unnamed)'}'`), rejecting "no target set" (would read "(unnamed)") and "wrong sample". Single handoff — no control pair needed. One AC. |
| AC-12 | TestAC12_JustCaptured | A | G1,G2,G3,G4,G5,G6 | *(ITEST-3.)* Given built via the configured input (`copyWith(justCaptured: true)`) and checked on surface (name shown). `haptics.confirmations == 1` is exact grain — rejects "no haptic" and "fires on every rebuild" (settle = readout rendered). The before(present)/after-acknowledge(absent)/non-fresh-control(absent, fresh `FakeHaptics` `confirmations==0`) triangle satisfies G3 and rejects marker-never-set, marker-never-clears and marker-always-on. One AC. |

## Summary — ITEST-3 (AC-8..AC-12)
- Grade counts: **5×A, 0×B** (after fix). Graded by an independent fresh grader 2026-10-06.
- Bs fixed in ITEST-3: **AC-8 (G5)** — vacuous temperature-word assertion satisfied by the name "Warm Terracotta"; now asserts "warm" against the name-stripped utterance. 1 fix pass.
- Judgement calls (grader verdicts): AC-8 hue *family* match is a defensible A (spec fixes no exact word; word boundaries block noise); AC-12 text-anchored marker is a sound public-surface observable (no lib key exists yet — A11Y-2 must render visible/semantic "just captured" text), and the before/after + non-fresh control satisfy G3/G5; AC-9/AC-10 are a proper control pair with exact stub-matched strings.

## Summary — ITEST-2 (AC-1..AC-7)
- Grade counts: 7×A, 0×B
- Bs to fix in ITEST-2: none
- Notes:
  - **AC-1 ↔ READOUT-4 pre-seed is redundant.** AC-1's "largest" assertion compares the Lightness font size against *every* other `RichText` paragraph in the ListView body (excluding only the name header and action-bar labels), using strict `greaterThan`. This already covers the colour-space readings the moment READOUT-4 renders them, so the plan's "pre-seeded augmentation (more readings to out-rank)" adds nothing — the generic assertion is strictly stronger.
  - **AC-5 is the one borderline A.** Exclusivity and three of four spaces are fully asserted; only the sRGB *triplet* is unasserted (hex only). Not a B — the spec states no exact sRGB values, so this is an optional tightening, not a rule failure. Suggested hardening (non-blocking): add a present-check for an sRGB triplet pattern (three 0–255 integers) in the `srgb` `_SpaceCase`.
  - **AC-6 relies on AC-7 as its positive contrast.** AC-6 feeds only a measured sample; the "always Measured" wrong impl is caught by AC-7's positive Estimated assertion, not by AC-6 alone. This is the catalogue's intended control pairing and is within G6 (AC-6's own negatives already reject the estimated note on a measured reading), so it holds — noted only so the pair is maintained together.
  - All negative Thens (AC-2 dark/light, AC-4 cool, AC-5 exclusivity, AC-6/AC-7 note) are asserted after a settle point and paired with a positive that shows the reading can change (G3 satisfied throughout).
  - Gate recommendation: ITEST-2 (AC-1..AC-7) passes the grade-A bar; behaviour coding (COLOR-2/3, READOUT-2..5) may begin. The AC-5 sRGB-triplet tightening can be folded into READOUT-4 without re-gating.

## Re-grade — READOUT-2 (AC-1, AC-2 un-pended)

Graded 2026-10-06 by an independent fresh grader against the **live behaviour** (real `buildApp` + `ColorScienceImpl`), per the behaviour-phase grade gate.

- **AC-1 — `TestAC01_LightnessProminent`: A** (G1,G2,G4,G5,G6). Given checked on surface + input; asserts the spec's exact values at the raw observable ("58" in the value region, Munsell "5.5" beside it, lightness font strictly larger than every other body reading). **Discriminates:** traced against the impl — `lightness`=58, `munsell.value`=5.5, number at `prominentFontSize` 48 vs ~14 others; a non-prominent / grayscale-less / Munsell-less impl fails.
- **AC-2 — `TestAC02_ValueWord`: A** (G1,G2,G4,G5,G6). G2 is load-bearing and satisfied by the L15/L90 controls (word must be *derived* from L). **Discriminates:** `valueWord(58)`="middle value", `valueWord(15)`="very low value", `valueWord(90)`="very high value"; a constant-"middle" impl fails both controls.
- **B-fixes needed:** none; no downgrade from the ITEST-2 grid. The AC-1 pre-seeded augmentation is confirmed redundant (the generic "larger than every other body reading" already out-ranks the colour-space readings READOUT-4 will add).
- **Counts:** 2×A, 0×B.

## Re-grade — READOUT-3 (AC-3, AC-4 un-pended)

Graded 2026-10-06 by an independent fresh grader against the **live behaviour** (real `buildApp` +
`ColorScienceImpl` — every member delegates to a real pure function, so AC-3/AC-4 run live and do not throw),
per the behaviour-phase grade gate. Grades **every** un-pended AC test (AC-1..AC-4), not only the two landed.

- **AC-3 — `TestAC03_ColourName`: A** (G1,G2,G4,G5,G6). The derived-name point holds: `unnamed.name == null`
  is checked on the public `Sample` surface before the When; `nameText` = `_sample.name ?? nearestName(...)`
  so a null name derives via `nearestColorName`. **Discriminates:** the Then requires the *derived* "Warm
  Terracotta" under the header, so (a) a shell echoing `Sample.name` shows null/placeholder → fails, (b) a
  not-derived/placeholder impl → fails. "Warm Terracotta" is the genuine nearest — `kNamedColors` holds an
  exact anchor `(58, 25.27, 22.75)` identical to the fixture coords (ΔE 0, global min). Prominence at full
  grain: header-above-value-region (top) and name font `>=` every other body paragraph (correctly `>=`, since
  the value number is also 48). **Test change this phase (non-weakening):** the earlier
  `expect(find.text('Unnamed sample'), findsOneWidget)` shell-placeholder Given was removed — the derived-name
  behaviour necessarily removes that placeholder, and the "no stored name" Given is still established by the
  retained `expect(unnamed.name, isNull)`. Grader confirmed the removal does **not** weaken discriminating
  power (both the echo-impl and the not-derived impl still fail the Then).
- **AC-4 — `TestAC04_Temperature`: A** (G1,G2,G4,G5,G6). Given: name shown + hue `closeTo(42, 0.5)` on input.
  Then on the temperature line ("Temperature: warm"): `contains('warm')` **and** `isNot(contains('42'))` —
  rejects the raw hue angle (G4). **Discriminates:** `temperatureWord(42)`="warm"; the SAMPLE_COOL control
  (hue `closeTo(250,1)` → `temperatureWord(250)`="cool", `isNot(contains('warm'))`) proves derivation from hue
  and rejects "always warm" (G2/G5). One AC (confined to the temperature line).
- **AC-1, AC-2:** no downgrade. The AC-1 name-header exclusion is confirmed **intact and load-bearing** —
  `NameHeader.nameStyle.fontSize == ValueRegion.prominentFontSize == 48` and the lightness number is also 48,
  so the exclusion set (name header + actions bar + lightness paragraphs) is what keeps AC-1's strict
  `greaterThan` valid; were the name header not excluded, 48 > 48 would fail. The now-prominent name does not
  affect AC-1's strict-largest-over-the-value-reading claim.
- **Counts:** 4×A, 0×B. No B to fix; no augmentations due this phase.

## Re-grade — READOUT-4 (AC-5 un-pended)

Graded 2026-10-06 by an independent fresh grader (fresh context) against the **live behaviour** (real `buildApp`
+ `ColorScienceImpl` — every member delegates to a real pure function, so AC-1..AC-5 run live, nothing throws),
per the behaviour-phase grade gate. Grades **every** un-pended test AC-1..AC-5 (AC-6..AC-12 remain pending).

- **AC-1 — `TestAC01_LightnessProminent`: A** (G1,G2,G4,G5,G6). Givens on surface ("Warm Terracotta" shown) +
  input (`coordinates.lightness == 58`). **Discriminates:** `lightness`=58 at `prominentFontSize` 48; the newly
  rendered space readings (`SpaceSelector.valuesKey` Text + the four `ChoiceChip` labels) all sit at body size
  ~14, and the strict `greaterThan` over *every* non-excluded body paragraph out-ranks them — so the READOUT-4
  readings do not threaten "largest" and the pre-seed augmentation stays redundant. Grayscale (`grayscaleKey`)
  and Munsell "5.5" (rendered "Munsell value 5.5") both asserted; a non-prominent/grayscale-less/Munsell-less
  impl fails.
- **AC-2 — `TestAC02_ValueWord`: A** (G1,G2,G4,G5,G6). **Discriminates:** `valueWord(58)`="middle value",
  `valueWord(15)`="very low value" (matches `\b(low|dark)\b`, not "middle"), `valueWord(90)`="very high value"
  (contains "high", not "middle"); the L15/L90 controls force derivation from L and reject a constant "middle".
- **AC-3 — `TestAC03_ColourName`: A** (G1,G2,G4,G5,G6). `unnamed.name == null` checked on the `Sample` surface;
  `nameText` = `name ?? nearestName(...)`. **Discriminates:** `kNamedColors` holds an exact anchor
  `(58, 25.27, 22.75)` = fixture coords (ΔE 0, global min), so the derived name is "Warm Terracotta"; an
  echo-`Sample.name` impl shows null/placeholder and fails, a not-derived impl fails. Name at 48 `>=` every
  other body paragraph (correctly `>=`, value number also 48) and header-above-value-region (top).
- **AC-4 — `TestAC04_Temperature`: A** (G1,G2,G4,G5,G6). **Discriminates:** `temperatureWord(42)`="warm"
  (arc to warm pole 60° = 18° ≤ 60°); `contains('warm')` **and** `isNot(contains('42'))` rejects the raw angle;
  SAMPLE_COOL (hue ≈250° → arc to cool pole 240° = 10° → "cool", `isNot('warm')`) rejects "always warm".
- **AC-5 — `TestAC05_ColourSpaceSelector`: A** (G1,G3,G4,G5,G6) — **prior borderline closed to a clean A.**
  Present-checks all match the live `readoutForSpace` at full grain: CIELCh "L 58, C 34, h 42°" (58/34/42/°),
  Munsell "10R 5.5/6" (`10R`, `5.5/6`), sRGB "192, 122, 101  #c07a65" (triplet **and** hex), CIELAB
  "L 58, a 25.27, b 22.75" (58/25.27/22.75). **Exclusivity stays collision-safe after the triplet:** the four
  cross-space signatures are unchanged (`°|deg`, `10R`, `#`+6 hex, `25.27`) — the triplet was added only to
  sRGB's `present` list, never as a signature — and each signature is absent from the other three live outputs
  (checked each: no `°`/`10R`/`#hex`/`25.27` bleeds across), so "space Y no longer shown" is unambiguous after
  each `whenSelectSpace` settle (G3), with the four-space loop as the control that the reading changes.
  **Discriminates** against the pre-READOUT-4 placeholder "<space> values —": that string contains none of the
  present patterns (no 58/34/42/°, no 10R, no triplet/hex, no 25.27), so every space's present-check fails it;
  it also rejects a show-all-at-once impl (exclusivity) and wrong values.
- **AC-5 sRGB-triplet verdict:** the prior A (borderline) carried one G4 gap — only the hex was asserted, so an
  impl rendering the hex but omitting the triplet would pass. READOUT-4 added
  `RegExp(r'\b\d{1,3},\s*\d{1,3},\s*\d{1,3}\b')` to sRGB's `present` list; it matches the live "192, 122, 101"
  and a hex-only impl now fails the present-check. The spec's "a triplet **and** a hex value" is now asserted at
  full grain. **Borderline closed — AC-5 is a clean A.**
- **Counts:** 5×A, 0×B. No B to fix; no augmentations outstanding.

## Re-grade — READOUT-5 (AC-6, AC-7 un-pended)

Graded 2026-10-06 by an independent fresh grader (fresh context) against the **live behaviour** (real `buildApp`
+ `ColorScienceImpl`; `ProvenanceRegion` reads `controller.sample.provenance` and derives label/note from the
`ProvenanceTier` with no colour math, so AC-1..AC-7 run live and nothing throws), per the behaviour-phase grade
gate. Grades **every** un-pended test AC-1..AC-7 (AC-8..AC-12 remain pending, owned by A11Y-2/READOUT-6).

- **AC-6 — `AC-6` measured badge: A** (G1,G2,G4,G5,G6). Given checked on surface ("Measured Reading" shown) and
  input (`SAMPLE_MEASURED.provenance.tier == ProvenanceTier.measured`). Then scoped to `ProvenanceRegion.regionKey`
  (not whole-screen — so the name "Measured Reading" cannot vacuously satisfy `contains('Measured')`): asserts
  `contains('Measured')` and, as the tier discriminators, `isNot('not yet verified')` + `isNot('Seeded by a
  model')`. **Discriminates:** live `labelFor(measured)` → `provenance.label` = "Measured", `noteFor(measured)`
  → null, so the region renders Text("Measured") only — a note-on-every-reading impl renders "Seeded by a
  model…" and fails the `isNot`; an empty region fails `contains('Measured')`. The one wrong impl AC-6 cannot
  catch alone — "badge every tier Measured" (feeds only a measured fixture) — is backstopped by AC-7's positive
  `contains('Estimated')`/`'not yet verified'`, the catalogue's intended control pairing; within G6 since AC-6's
  own negatives already reject the estimated note on a measured reading.
- **AC-7 — `AC-7` estimated badge: A** (G1,G3,G4,G5,G6). Given checked on surface ("Estimated Reading" shown)
  and input (`tier == ProvenanceTier.estimated`). Then (region-scoped): `contains('Estimated')` **and**
  `contains('not yet verified')` **and** the **exact** note `'Seeded by a model. Treat as a starting point.'`
  (full grain). Carries its own in-test measured control — `SAMPLE_MEASURED` re-loaded and settled shows
  `isNot('Seeded by a model')` (G3), tying the note to the Estimated tier. **Discriminates:** live
  `labelFor(estimated)` → "Estimated — not yet verified" (region owns the "— not yet verified" qualifier;
  `Provenance.label` is the bare "Estimated"), `noteFor(estimated)` → `estimatedNote` constant = the exact note,
  so the region renders both Texts. A badge-everything-"Measured" impl fails `contains('Estimated')`; a
  note-less impl fails the exact-note check; a note-on-every-reading impl fails the measured control.
- **AC-6/AC-7 control-pairing check:** confirmed against live values — measured fixture ⇒ {"Measured", no note};
  estimated fixture ⇒ {"Estimated — not yet verified", exact note}. The two wrong impls the gate names each die:
  "badge every tier Measured" ⇒ AC-7 positive fails; "print the note on every reading" ⇒ AC-6 `isNot('Seeded by
  a model')` fails (and AC-7's measured control fails). The pair must stay maintained together (noted, per G6).
- **AC-1..AC-5:** no downgrade, no regression. READOUT-5 touched only `lib/readout/provenance_region.dart`,
  `integration_test/harness.dart` (pending map) and `integration_test/harness_test.dart` (gate self-tests). The
  provenance region is rendered inside the Readout `ListView` (`readout_screen.dart:85`) with its two `Text`s at
  the inherited body size (~14, no explicit `fontSize`), well under the `prominentFontSize` = 48 of the lightness
  number and name — so AC-1's strict `greaterThan` (lightness > every other body paragraph) and AC-3's `>=`
  (name ≥ every other body paragraph) both still hold with the now-populated region text in the comparison set.
  Pending-gate self-tests stay consistent: `harness_test.dart` `unpended = {AC-1..AC-7}` is the exact complement
  of `pendingACs = {AC-8, AC-9, AC-10, AC-11, AC-12}` across all 12, each pending owner in `behaviorPhases`.
- **Counts:** 7×A, 0×B. No B to fix; no augmentations outstanding.

## Re-grade — READOUT-6 (AC-9/10/11 un-pended; full un-pended re-grade against live behaviour)

Graded 2026-10-06 by an independent fresh grader (fresh context, did not write the code) against the **live behaviour** of the working tree (real `buildApp` + `ColorScienceImpl`, whose members delegate to real pure `conv`/`naming`/`words` functions; `AppRouter` pushes real `ComparisonStubScreen`/`RecipesStubScreen`). READOUT-6 is the current uncommitted change: `pendingACs` is now `{AC-8: A11Y-2, AC-12: A11Y-2}` only, so AC-9/10/11 are un-pended; the navigation is wired in `lib/readout/actions_bar.dart` (`Navigator.push(controller.comparisonRoute(slot))` / `recipesRoute()`) → `readout_controller.dart` (`router.toComparison(_sample, slot)` / `router.toRecipes(_sample)`) → `lib/app/router.dart` → the stub screens. Grades **every** un-pended AC (AC-1..AC-7, AC-9, AC-10, AC-11); AC-8/AC-12 stay pending (A11Y-2) and are not graded live.

| AC | Test | Grade | Rules checked | Justification (live) |
|---|---|---|---|---|
| AC-1 | `AC-1` lightness prominent | A | G1,G2,G4,G5,G6 | Givens on surface ("Warm Terracotta" shown) + input (`coordinates.lightness==58`). Live `lightness`=58 at `prominentFontSize` 48; grayscale (`grayscaleKey`) + Munsell "5.5" asserted; strict `greaterThan` over every non-excluded body paragraph (name header + actions bar + lightness excluded) still out-ranks the space readings (~14). |
| AC-2 | `AC-2` value word | A | G1,G2,G4,G5,G6 | `valueWord(58)`="middle value"; L15→"very low value" (`\b(low\|dark)\b`, not middle), L90→"very high value" (contains high, not middle). Controls force derivation from L, scoped to value region. |
| AC-3 | `AC-3` colour name | A | G1,G2,G4,G5,G6 | `unnamed.name==null` checked on the `Sample` surface; `nameText = name ?? nearestName(coords)`. `kNamedColors` has exact anchor (58,25.27,22.75)=fixture ⇒ derived "Warm Terracotta"; echo-`Sample.name` impl fails. Name 48 `>=` every body paragraph; header above value region. |
| AC-4 | `AC-4` temperature | A | G1,G2,G4,G5,G6 | `temperatureWord(42)`="warm"; `contains('warm')` **and** `isNot(contains('42'))` rejects the raw angle (G4); SAMPLE_COOL (hue≈250→"cool", not warm) rejects "always warm". Confined to the temperature line. |
| AC-5 | `AC-5` colour-space selector | A | G1,G3,G4,G5,G6 | Present-checks match live `readoutForSpace` at full grain incl. sRGB triplet **and** hex ("192, 122, 101  #c07a65"); four cross-space signatures (`°\|deg`,`10R`,`#`+6hex,`25.27`) mutually non-substring and absent from the other three outputs, so one-at-a-time exclusivity is unambiguous after each settled `whenSelectSpace`. |
| AC-6 | `AC-6` measured badge | A | G1,G2,G4,G5,G6 | Given on surface + input (`tier==measured`). Region-scoped `contains('Measured')` + `isNot('not yet verified')` + `isNot('Seeded by a model')`; live `labelFor(measured)`="Measured", `noteFor(measured)`=null. "Badge every tier Measured" backstopped by AC-7's positive. |
| AC-7 | `AC-7` estimated badge | A | G1,G3,G4,G5,G6 | Region-scoped `contains('Estimated')` + `contains('not yet verified')` + exact note "Seeded by a model. Treat as a starting point."; in-test measured control (settled) shows no note (G3), tying note to the Estimated tier. |
| AC-9 | `AC-9` compare as A | A | G1,G2,G4,G5,G6 | Givens checked (name shown; `find.text('Comparison') findsNothing` before the When — Readout AppBar is 'Readout', button is 'Compare as A', so no leak). Live `comparisonRoute(a)`→`toComparison(sample, a)` sets `sampleA=sample, sampleB=null`. Asserts filled **and** empty slot at exact stub grain ("Slot A: Warm Terracotta" + "Slot B: (empty)", matching `'$label: ${sample?.name ?? '(empty)'}'`). Rejects "navigates without carrying" (both empty), "fills both slots", and "always slot B" (that impl renders Slot A empty → fails here); "always slot A" caught by its AC-10 pair. |
| AC-10 | `AC-10` compare as B | A | G1,G2,G4,G5,G6 | Mirror of AC-9: `comparisonRoute(b)`→`sampleA=null, sampleB=sample` ⇒ "Slot B: Warm Terracotta" + "Slot A: (empty)". Rejects "always slot A" (renders Slot B empty → fails). The AC-9/AC-10 pair kills any "always slot X" / ignores-the-slot-argument impl (each fails exactly one), and the name assertion rejects carrying the wrong sample. |
| AC-11 | `AC-11` find recipes | A | G1,G2,G4,G5,G6 | Givens checked (name "Deep Olive Green" shown; `find.text('Recipes') findsNothing` — button is 'Find mixing recipes' ≠ 'Recipes', no leak). Live `recipesRoute()`→`toRecipes(sample)` ⇒ `RecipesStubScreen(target: sample)` renders "Recipe target: Deep Olive Green" (`'Recipe target: ${target.name ?? '(unnamed)'}'`). Rejects "no target set" (→ "(unnamed)") and "wrong sample". Single handoff, no slot ambiguity → no control pair needed. |

- **Downgrades:** none. Every prior A holds against live behaviour; AC-9/10/11 (newly real) each reject their named wrong impls — navigate-without-carrying, fill-both-slots, always-one-slot (via the AC-9/10 pair), wrong-sample, and no-target. No rule (G1–G6) is failed by any un-pended test.
- **Adversarial note:** AC-9 and AC-10 individually each reject the *opposite* "always slot X" impl; an impl that ignores the `slot` argument entirely is caught only by the pair (one of the two fails), which is the rubric-sanctioned control-pairing (G5) the tests' own comments declare — so the pair must stay maintained together. AC-11's target carries the real sample (`toRecipes(_sample)`), so an impl that navigates with a wrong/empty target fails the exact-name Then.
- **Counts:** 10×A, 0×B (AC-1..AC-7, AC-9, AC-10, AC-11). AC-8, AC-12 remain pending (A11Y-2), not graded live.

## Re-grade — A11Y-2 (AC-8, AC-12 un-pended; full un-pended re-grade against live behaviour)

Graded 2026-10-06 by an independent fresh grader (fresh context, did not write the code) against the live behaviour of the working tree. (Flutter is not on that grader's PATH, so grades are by hand-trace of the live `buildApp` + real `ColorScienceImpl` and the arithmetic of `decompose` — the terracotta decomposition was recomputed independently: chroma 34.00→34, hue 41.996→42, value 58.) The suite itself was run green on the iOS simulator in run-pending mode (all 12 ACs + harness self-tests).

AC-8 runs live as `whenSpeak()` → tap `ActionsBar.speakKey` → `controller.speak()` → `speech.speak(colorScience.decompose(_sample))` → `decomposition.decompose`, producing exactly one `FakeSpeech` utterance: `"Warm Terracotta: a warm orange. Value 58, chroma 34, hue angle 42 degrees."`. AC-12 fires `haptics.confirm()` once from the `ReadoutController` constructor (via `_confirmIfJustCaptured`, built once in `didChangeDependencies`), renders `Text('Just captured')` while `controller.justCaptured`, and clears it on `acknowledge()`.

| AC | Test | Grade | Rules checked | Justification (live) |
|---|---|---|---|---|
| AC-1 | `AC-1` lightness prominent | A | G1,G2,G4,G5,G6 | No regression. Non-fresh `givenReadoutOf(SAMPLE_TERRACOTTA)` → no "Just captured" marker; the new marker lives in `ActionsBar` (excluded via `barKey`). Live `lightness`=58 prominent; grayscale + Munsell "5.5" asserted; strict `greaterThan` over every non-excluded body paragraph still out-ranks space readings. `harness.speech.utterances isEmpty` still holds — speak is wired but untapped. |
| AC-2 | `AC-2` value word | A | G1,G2,G4,G5,G6 | Unchanged path. `valueWord(58)`="middle value"; L15/L90 controls force derivation from L. |
| AC-3 | `AC-3` colour name | A | G1,G2,G4,G5,G6 | No regression. `unnamed.name==null` on surface; `nameText = name ?? nearestName`; exact catalogue anchor (58,25.27,22.75) ⇒ "Warm Terracotta"; name font `>=` every body paragraph. |
| AC-4 | `AC-4` temperature | A | G1,G2,G4,G5,G6 | Unchanged. `temperatureWord(42)`="warm"; `contains('warm')` + `isNot('42')`; SAMPLE_COOL (hue 250→"cool") rejects "always warm". |
| AC-5 | `AC-5` colour-space selector | A | G1,G3,G4,G5,G6 | Unchanged. Present-checks match live `readoutForSpace` at full grain incl. sRGB triplet + hex; four cross-space signatures mutually non-substring; one-at-a-time exclusivity settled after each `whenSelectSpace`. |
| AC-6 | `AC-6` measured badge | A | G1,G2,G4,G5,G6 | Unchanged. Region-scoped `contains('Measured')` + `isNot('not yet verified')` + `isNot('Seeded by a model')`; backstopped by AC-7's positive. |
| AC-7 | `AC-7` estimated badge | A | G1,G3,G4,G5,G6 | Unchanged. `contains('Estimated')`+`contains('not yet verified')`+exact note; in-test measured control (settled) shows no note (G3). |
| AC-8 | `AC-8` speak readout | A | G1,G2,G4,G5,G6 | Givens checked on surface (name shown; `utterances` empty = before-state) and input (L58, hue≈42, chroma≈34). `hasLength(1)` rejects a fragment stream. Traced decomposition contains every asserted substring: name "Warm Terracotta", "58", "warm" (survives the `replaceAll('warm terracotta','')` strip via "a **warm** orange"), `\b(orange\|red)\b` via "orange", "34", "42" — each uniquely tied, so each assertion independently rejects omitting its component. Sharpest kill: a name+coordinate-dump impl fails BOTH the name-stripped `contains('warm')` and the hue-family regex. Hue-FAMILY match is a defensible A (spec fixes no exact word; `\b` anchors block noise). One AC. |
| AC-9 | `AC-9` compare as A | A | G1,G2,G4,G5,G6 | No regression; nav path unchanged. Filled + empty slot at exact stub grain; pair with AC-10 kills "always slot X". |
| AC-10 | `AC-10` compare as B | A | G1,G2,G4,G5,G6 | Mirror of AC-9; the pair kills any slot-ignoring impl. |
| AC-11 | `AC-11` find recipes | A | G1,G2,G4,G5,G6 | Unchanged. `toRecipes(sample)` ⇒ exact "Recipe target: Deep Olive Green"; rejects no-target/wrong-sample. |
| AC-12 | `AC-12` just-captured confirm | A | G1,G2,G3,G4,G5,G6 | Given built from configured input (`copyWith(justCaptured:true)` via `givenJustCapturedReadoutOf`), checked on surface (name shown). Live: constructor fires `confirm()` once (built once under the `_controller == null` guard) ⇒ `confirmations==1`; marker `Text('Just captured')` matches `RegExp('just[ -]?captured', caseSensitive:false)`. The before(1 haptic, marker)/rebuild-while-fresh(still 1, marker persists)/after-acknowledge(marker gone, settled)/non-fresh-control(0, no marker) sequence is settled on every leg and shows the state CAN change — G3. Rejects no-haptic, always-haptic, **per-build confirm()** (the rebuild-while-fresh re-assert), marker-never-set, marker-never-clears, marker-always-on. One AC. |

- **Downgrades:** none. Every prior A holds against live behaviour; both newly-live tests (AC-8, AC-12) reject their named wrong impls and fail no G1–G6 rule.
- **AC-12 hardening applied this phase:** the grader flagged a non-blocking robustness gap — the AC-12 test as written did not reliably kill a `confirm()` relocated into `build()` (the boot `pumpAndSettle` builds once while fresh, so such an impl also yields `confirmations==1`, and the only later rebuild is post-acknowledge). Per the grader's recommendation, AC-12 was strengthened (not weakened) this phase: while still just-captured it forces an extra rebuild (`whenSelectSpace(munsell)`) and re-asserts `confirmations == 1` (and the marker persists), so a per-build `confirm()` now reaches 2 and fails. Suite re-run green on the simulator after the change.
- **Harness self-test:** non-vacuous. With `pendingACs` now empty, both gate self-tests still bite — "exact complement across all 12" fails if any AC is re-pended and asserts `length == 0`; "runs each in both modes" asserts `pendingACs isEmpty` and null skip-reason for all 12 in both modes, so re-pending (non-null in `forceRunPending:false`) or inverting the gate fails. The both-modes distinction is trivially satisfied only because nothing is pending (the correct fully-open end state); the meaningful mutations are caught.
- **Counts:** 12×A, 0×B (all 12).
