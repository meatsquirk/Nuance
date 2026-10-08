# Draft: awaiting owner approval (authored 2026-10-08 for /feature-next-phase planning)
# Depends on bs-04 (MixingEngine, Recipe, out-of-gamut) and bs-15 (ColorCombination,
# CombinationLibrary, save-to-project) being signed off and merged to main — see G-3, G-4.
Feature: Mixing a combination from the painter's paints
  Having found a colour combination they like (bs-15), the painter turns it into
  something they can actually mix: for each colour in the combination the app solves
  the nearest recipe from the selected palette, reusing the physics solver — parts by
  volume, predicted colour, delta-E00 and a plain verdict. A colour the palette cannot
  reach is marked out of gamut and the nearest mix is offered as the nearest, never as
  a match, so the painter learns which of a combination's colours their tubes can and
  cannot hit. The whole plan can be spoken and saved into a project, and it always
  reflects the palette currently selected.

  Boundary: solving a whole combination into per-colour recipes on the combination
  mixing-plan view. Suggesting and reading combinations is bs-15; the single-target
  recipe search, its ordering, trace, muddying, wet/dry and out-of-gamut rules are
  bs-04 and are reused, not re-specified; the palette and project stores are bs-06.
  Builds on: bs-15 (ColorCombination, CombinationLibrary, the save-to-project seam),
  bs-04 (MixingEngine inverse solve, Recipe, out-of-gamut, PaintPalette/PaletteSource).
  Source: SI "Mixing recipes" + "Phase 3 — Breadth"; SI fixed intent — never a false
  recipe, out-of-gamut stated not hidden; recipes solved only against the palette.

  Rule: Each colour in a combination is solved into the nearest recipe from the selected palette

    # Source: SI — inverse search minimises delta-E00 under the palette (reuses bs-04)
    Scenario: A combination is turned into one recipe per colour
      Given a selected palette that can mix a combination's colours
      And a combination of three colours
      When the painter mixes the combination from the palette
      Then each of the three colours has a recipe solved from the selected palette

    # Source: bs-04 — a recipe is parts by volume, predicted colour, delta-E00, verdict
    Scenario: Each colour's recipe states its parts, predicted colour, distance and verdict
      Given a combination colour that the palette can mix
      When its recipe is shown
      Then the recipe shows its paints as parts by volume and its predicted colour
      And it states its delta-E00 from that colour with a plain verdict

  Rule: Recipes are solved only against the selected palette

    # Source: SI — recipes solved only against the selected palette (reuses bs-04)
    Scenario: Every per-colour recipe uses only paints from the selected palette
      Given the selected palette is "My paints"
      When the combination is mixed from the palette
      Then every per-colour recipe uses only paints from "My paints"

    # Source: SI — changing the palette re-solves against it
    Scenario: Switching the active palette re-solves the combination
      Given a combination mixed against "My paints"
      When the painter selects "Travel set" as the active palette
      Then the combination is re-solved so every per-colour recipe uses only paints from "Travel set"

  Rule: A colour the palette cannot reach is marked out of gamut, never faked

    # Source: SI fixed intent — out-of-gamut stated, never a false recipe (reuses bs-04)
    Scenario: An unreachable combination colour is marked out of gamut
      Given a combination colour that the selected palette cannot mix
      When the combination is mixed from the palette
      Then that colour is marked "OUT OF GAMUT"
      And its nearest mix is offered as the nearest possible, not as a match

  Rule: The plan summarises how much of the combination the palette can mix

    # Source: SI — honest at-a-glance accuracy; the painter sees reachability up front
    Scenario: The plan states the in-gamut and out-of-gamut counts for the combination
      Given a four-colour combination of which three colours are in gamut and one is out of gamut
      When the combination is mixed from the palette
      Then the plan states that three of the four colours are in gamut and one is out of gamut

  Rule: The mixing plan can be spoken

    # Source: SI — hands-free spoken readout
    Scenario: The painter hears the mixing plan spoken
      Given a combination mixed into per-colour recipes
      When the painter asks to speak the plan
      Then the spoken output states, for each colour, its name and its recipe as paints and parts

  Rule: A combination mixing plan is saved into a project

    # Source: SI — projects collect recipes; the plan records the palette it solved against
    Scenario: A mixing plan is saved to a project with the palette it solved against
      Given the painter has opened a project "Harbour Dusk"
      And a combination mixed from "My paints" into per-colour recipes
      When the painter saves the mixing plan to "Harbour Dusk"
      Then the plan is retained in "Harbour Dusk" with its per-colour recipes and the palette "My paints" it solved against
