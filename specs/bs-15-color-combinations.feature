# Approved 2026-10-08 by Matt Quirk (G-1) — authored 2026-10-08 for /feature-next-phase planning
# Source dataset: docs/ColorCombinations/sanzo-wada-swatch-catalog.html — Sanzo Wada,
# "A Dictionary of Color Combinations" (Haishoku Sokan, 1933-34): 159 named colours
# and 348 historical combinations of 2, 3 or 4 colours. Data MIT-licensed
# (Matt DesLauriers / Dain M. Blodorn Kim). Commercial-safe, consistent with SI D3.
Feature: Colour-combination suggestions
  Against a colour the painter already has — a saved sample or a paint they own —
  the app suggests historically-grounded colour combinations drawn only from Sanzo
  Wada's dictionary, ranked by how closely a combination contains that colour. Each
  suggested combination is read out the way the rest of the app reads colour: every
  colour named with its lightness, chroma and hue and a warm or cool word, never a
  swatch alone; it can be spoken; and any pair within it that the painter's own
  colour vision would confuse is flagged. The dictionary can also be browsed and
  searched directly. A combination is labelled an aesthetic reference, never dressed
  up as measured paint data, and can be saved into a project.

  Boundary: suggesting, reading, browsing and saving combinations from the shipped
  Wada reference set on the Combinations screen. Turning a combination into mixable
  recipes against the painter's palette is bs-16. Capturing a colour is bs-02;
  reading a single colour is bs-01; comparing two colours is bs-03; the palette and
  projects stores are bs-06.
  Builds on: bs-01 (ColorScience L/C/h + ISCC-NBS naming + warm/cool words, Speech,
  Sample, deltaE00, ConfusionCheck, SampleSource). The owned-paint anchor also uses
  bs-04's Paint/PaintPalette (see G-3).
  Source: SI "Phase 3 — Breadth: harmony and value-study tools"; SI accessibility
  (meaning in numbers, words and sound, never colour alone); SI D9 (provenance).

  Rule: The painter anchors suggestions on a colour they already have

    # Source: SI — "how does this colour relate to that one"; anchor = a saved Sample
    Scenario: Anchoring on a saved sample suggests combinations that contain it
      Given the painter has a saved sample "Studio Blue" at L 35, C 38, h 246
      When the painter asks for combinations relative to "Studio Blue"
      Then the suggestions are Wada combinations that each contain a colour within a small delta-E00 of "Studio Blue"

    # Source: SI — recipes/anchors relative to the paints the painter owns (see G-3)
    Scenario: Anchoring on an owned paint suggests combinations that contain it
      Given the selected palette contains the paint "Ultramarine Blue" with masstone L 30, C 44, h 290
      When the painter asks for combinations relative to "Ultramarine Blue"
      Then the suggestions are Wada combinations that each contain a colour within a small delta-E00 of that paint's masstone

  Rule: Suggestions are drawn only from the shipped Wada dictionary, never invented

    # Source: dataset — 159 colours, 348 combinations; nothing is generated at runtime
    Scenario: Every suggested combination is one of the 348 dictionary combinations
      Given the shipped dictionary holds 348 combinations over 159 named colours
      When combinations are suggested for any anchor
      Then every suggested combination is one of the 348 shipped combinations
      And no combination is generated or altered at runtime

  Rule: Suggestions are ranked by how closely a combination contains the anchor

    # Source: SI — relate by delta-E00; the closest-matching combination leads
    Scenario: A combination whose nearest colour is closer to the anchor ranks higher
      Given a combination A contains a colour 3 delta-E00 from the anchor
      And a combination B whose nearest colour is 11 delta-E00 from the anchor
      When the suggestions are ordered
      Then combination A is ranked above combination B

  Rule: Each colour in a combination is named with its values, never colour alone

    # Source: SI accessibility — meaning travels through numbers and words, not swatches
    Scenario: Each colour shows its dictionary name, its L, C and hue, and a warm or cool word
      Given a suggested combination containing "Raw Sienna"
      When the combination is shown
      Then "Raw Sienna" is shown with its lightness, chroma and hue
      And it is described as warm or cool in words
      And it is not presented as a swatch alone

  Rule: A combination can be spoken

    # Source: SI — one-tap spoken readout; hands-free studio use
    Scenario: The painter hears a combination spoken
      Given a suggested combination of "Raw Sienna", "Sulpher Yellow" and "Helvetia Blue"
      When the painter asks to speak the combination
      Then the spoken output names the combination and states each colour's name with its L, C and hue

  Rule: A pair the painter's own vision would confuse is flagged within a combination

    # Source: SI — confusion warnings: "these look identical to you but differ to others"
    Scenario: A combination holding a confusable pair is flagged for the painter
      Given the painter's vision profile is deutan-type, moderate
      And a suggested combination holds two colours that fall on the painter's confusion line
      When the combination is shown
      Then the pair is flagged as looking identical to the painter though clearly different to normal vision

    # Source: SI — the flag discriminates; a safe combination is not warned
    Scenario: A combination with no confusable pair is not flagged
      Given the painter's vision profile is deutan-type, moderate
      And a suggested combination holds no two colours on the painter's confusion line
      When the combination is shown
      Then no confusion pair is flagged on it

  Rule: The dictionary can be browsed and searched directly

    # Source: dataset — 120 two-colour, 120 three-colour, 108 four-colour combinations
    Scenario: The painter browses combinations by the number of colours
      Given the painter is browsing the dictionary
      When the painter filters to combinations of three colours
      Then only combinations of exactly three colours are listed

    # Source: dataset — each colour records the combinations it appears in
    Scenario: The painter searches a colour and sees the combinations that use it
      Given the painter is browsing the dictionary
      When the painter searches for "Sea Green"
      Then "Sea Green" is found and the combinations that use it are listed

  Rule: A combination is labelled an aesthetic reference, not measured paint data

    # Source: SI D9 — honest provenance; the dictionary is an aesthetic source, not a tube
    Scenario: A combination carries its Wada reference provenance
      Given a suggested combination from the dictionary
      When its provenance is shown
      Then it is labelled a reference from Sanzo Wada's "A Dictionary of Color Combinations"
      And it is not labelled "Measured", "Calculated", "Estimated" or "Confirmed"

  Rule: The painter saves a combination into a project

    # Source: SI — palette & projects; a project collects saved colours (bs-06 store)
    Scenario: A suggested combination is saved to a project and kept
      Given the painter has opened a project "Harbour Dusk"
      And a suggested combination of "Raw Sienna", "Sulpher Yellow" and "Helvetia Blue"
      When the painter saves the combination to "Harbour Dusk"
      Then the combination is retained in "Harbour Dusk" with its colours and its Wada reference provenance
