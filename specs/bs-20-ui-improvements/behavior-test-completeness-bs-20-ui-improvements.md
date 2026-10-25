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
