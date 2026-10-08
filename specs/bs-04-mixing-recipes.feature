# Approved 2026-10-08 by Matt Quirk (G-1) — derived 2026-10-05 by /wireframe-behavior-specs
Feature: Mixing recipes
  Given a target colour and the palette of paints the painter physically owns, the
  app returns the top few candidate recipes as parts by volume, each with its
  predicted colour, its delta-E from the target and a plain verdict. It prefers
  fewer paints, expresses trace amounts as "a touch of", flags muddying mixes, and
  refuses to invent a recipe for an out-of-gamut target.

  Boundary: solving and presenting recipes on the Recipes screen. Capturing the
  target colour is bs-02; reading it is bs-01; the mix-correction loop is bs-05;
  defining and selecting a palette is bs-06.
  Builds on: bs-01.
  Wireframe: Paint Color Assistant.dc.html, Recipes screen (region S1.R1, elements
  E22-E25).

  Rule: A recipe target is a saved sample or a manually entered colour

    # UX: Paint Color Assistant.dc.html › S1.R1.E22 Target selector [button]
    Scenario: The painter chooses a saved sample as the target
      Given the painter has a saved sample "Deep Olive Green" with L 42, C 28, h 108
      When the painter chooses "Deep Olive Green" as the recipe target
      Then "Deep Olive Green" at L 42, C 28, h 108 is set as the target

    # UX: Paint Color Assistant.dc.html › S1.R1.E22 Target selector [button]
    Scenario: The painter enters a target colour manually and an impossible value is refused
      Given the painter is setting a recipe target by hand
      When the painter enters a lightness of 140
      Then the target is refused as out of range
      And the previously set target is kept

  Rule: Recipes are solved only against the selected palette

    # UX: Paint Color Assistant.dc.html › S1.R1 Recipes screen — recipe list [body]
    Scenario: Recipes use only paints from the currently selected palette
      Given the selected palette is "My paints" containing Titanium White, Yellow Ochre and Ivory Black
      And the target is "Deep Olive Green"
      When the recipes are solved
      Then every returned recipe uses only paints from "My paints"

  Rule: The search returns the top few candidate recipes

    # UX: Paint Color Assistant.dc.html › S1.R1 Recipes screen — recipe list [body]
    Scenario: The top three to five recipes are returned with parts and predicted colour
      Given the target is "Deep Olive Green" and the palette can mix it
      When the recipes are solved
      Then between three and five candidate recipes are listed
      And each recipe shows its paints as parts by volume and its predicted colour

  Rule: Each recipe states its distance from the target with a plain verdict

    # UX: Paint Color Assistant.dc.html › S1.R1 Recipes screen — recipe verdict [body]
    Scenario: A close recipe states a small delta-E with a plain verdict
      Given a recipe of Yellow Ochre 6 parts and Ivory Black 3 parts predicts L 42.6, C 27.1, h 106
      When the recipe is shown for the target "Deep Olive Green"
      Then the recipe states its delta-E00 from the target
      And it carries the plain verdict "very close"

  Rule: The search prefers fewer paints

    # UX: Paint Color Assistant.dc.html › S1.R1 Recipes screen — recipe ordering [body]
    Scenario: A cleaner two-paint mix ranks above a muddier four-paint mix at a similar delta-E
      Given a two-paint mix and a four-paint mix reach the target at a similar delta-E
      When the recipes are ordered
      Then the two-paint mix is ranked above the four-paint mix

  Rule: Trace components are expressed as a touch of

    # UX: Paint Color Assistant.dc.html › S1.R1 Recipes screen — trace component [body]
    Scenario: A component under about two percent is expressed as a touch of
      Given a recipe whose Titanium White component is under two percent by volume
      When the recipe is shown
      Then the Titanium White is expressed as "a touch of" with a technique note rather than a measured part

  Rule: Mixes that cross complementary hues are flagged as muddying

    # UX: Paint Color Assistant.dc.html › S1.R1 Recipes screen — muddying flag [body]
    Scenario: A complementary-crossing mix is flagged as muddying
      Given a candidate recipe crosses a complementary hue pair
      When the recipe is shown
      Then the recipe is flagged as liable to muddy

  Rule: An out-of-gamut target is identified without a false recipe

    # UX: Paint Color Assistant.dc.html › S1.R1.E22 Target selector [button]
    Scenario: An out-of-gamut target offers the nearest possible without claiming a match
      Given the target "Vivid Turquoise" cannot be mixed from the selected palette
      When the recipes are solved
      Then the target is marked "OUT OF GAMUT"
      And the nearest possible mix is offered as the nearest possible, not as a match

  Rule: The predicted colour can be shown wet or dry

    # UX: Paint Color Assistant.dc.html › S1.R1.E24 Wet or dry toggle [button]
    Scenario: The painter views the predicted dry colour
      Given a recipe predicts L 42.6, C 27.1, h 106 wet
      When the painter switches to the dry prediction for oil after 7 days
      Then the predicted colour shifts to L 41.2, C 26.4, h 107

  Rule: The target and a recipe can be spoken

    # UX: Paint Color Assistant.dc.html › S1.R1.E23 Speak target [button]
    Scenario: The painter hears the target spoken
      Given the target is "Deep Olive Green" at L 42, C 28, h 108
      When the painter asks to speak the target
      Then the spoken output states the target name and its L, C and hue

    # UX: Paint Color Assistant.dc.html › S1.R1.E25 Speak recipe [button]
    Scenario: The painter hears a recipe spoken
      Given a recipe of Yellow Ochre 6 parts and Ivory Black 3 parts for the target
      When the painter asks to speak the recipe
      Then the spoken output states each paint and its parts
