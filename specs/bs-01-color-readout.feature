# Approved 2026-10-05 by owner Matt Quirk (G-1). Derived 2026-10-05 by /wireframe-behavior-specs.
Feature: Color readout
  A colour-vision-deficient painter can read a sampled colour through numbers,
  words and structure rather than a swatch alone: a prominent value, a plain
  name, a temperature word, the same colour in several colour spaces, and the
  origin of every value. Each reading can be spoken, carried into a comparison,
  or used to start a recipe search.

  Boundary: the Readout screen only (the reading of a single sample). Capturing a
  sample is specified in bs-02; comparing two samples in bs-03; recipes in bs-04.
  Wireframe: Paint Color Assistant.dc.html, Readout screen (flattened inventory
  region S1.R1, elements E9-E14).

  Rule: Lightness is shown as the prominent value reading with a grayscale preview

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout screen — value reading [body]
    Scenario: Lightness is displayed as the prominent value with a grayscale preview
      Given the painter is reading the sample "Warm Terracotta" with Lightness 58
      When the readout for the sample is shown
      Then Lightness 58 is displayed as the largest reading on the screen
      And a grayscale preview of the sample accompanies it
      And the Munsell value 5.5 is shown beside the Lightness

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout screen — value word [body]
    Scenario: The numeric lightness is paired with a plain-language value word
      Given the painter is reading a sample with Lightness 58
      When the value reading is shown
      Then a plain-language value word such as "middle value" accompanies the number

  Rule: The sample is named in plain language

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout screen — colour name [body]
    Scenario: A plain-language colour name is shown large
      Given the painter is reading a sample whose nearest named colour is "Warm Terracotta"
      When the readout is shown
      Then the name "Warm Terracotta" is shown large at the top of the readout

  Rule: Temperature is stated in words relative to a neutral

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout screen — temperature [body]
    Scenario: A warm sample is described as warm in words
      Given the painter is reading a sample at hue 42 degrees
      When the readout is shown
      Then the temperature is stated in words as "warm"

  Rule: The numeric readout is available in several colour spaces, one at a time

    # UX: Paint Color Assistant.dc.html › S1.R1.E11 Readout colour-space selector [button]
    Scenario Outline: The painter selects a colour space and sees the sample in that space
      Given the painter is reading the sample "Warm Terracotta"
      When the painter selects the <space> readout
      Then the sample is expressed as <shown>
      And the other colour spaces are no longer shown

      Examples:
        | space   | shown                                |
        | CIELCh  | L 58, C 34, h 42 degrees             |
        | Munsell | 10R 5.5/6                            |
        | sRGB    | an sRGB triplet and a hex value      |
        | CIELAB  | L, a and b coordinates               |

  Rule: Every displayed value carries its provenance and confidence

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout screen — provenance badge [body]
    Scenario: A measured value is badged Measured
      Given the painter is reading a sample read with a spectrophotometer
      When the readout is shown
      Then the value carries the provenance "Measured"

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout screen — provenance badge [body]
    Scenario: An unverified seeded value is badged Estimated and labelled not yet verified
      Given the painter is reading a value seeded by a model and not yet verified
      When the readout is shown
      Then the value carries the provenance "Estimated — not yet verified"
      And the note "Seeded by a model. Treat as a starting point." is shown

  Rule: Any reading can be spoken on request

    # UX: Paint Color Assistant.dc.html › S1.R1.E10 Speak this readout [button]
    Scenario: The painter hears the whole readout spoken
      Given the painter is reading the sample "Warm Terracotta"
      When the painter asks to speak this readout
      Then the spoken output states the name, the value, the temperature, the hue in words, the chroma and the hue angle

  Rule: A reading can be carried into a comparison

    # UX: Paint Color Assistant.dc.html › S1.R1.E12 Compare as A [button]
    Scenario: The painter uses the reading as comparison sample A
      Given the painter is reading the sample "Warm Terracotta"
      When the painter uses the reading as comparison sample A
      Then the Comparison screen is shown with "Warm Terracotta" in slot A

    # UX: Paint Color Assistant.dc.html › S1.R1.E13 Compare as B [button]
    Scenario: The painter uses the reading as comparison sample B
      Given the painter is reading the sample "Warm Terracotta"
      When the painter uses the reading as comparison sample B
      Then the Comparison screen is shown with "Warm Terracotta" in slot B

  Rule: A reading can start a recipe search

    # UX: Paint Color Assistant.dc.html › S1.R1.E14 Find mixing recipes [button]
    Scenario: The painter starts a recipe search from the reading
      Given the painter is reading the sample "Deep Olive Green"
      When the painter asks to find mixing recipes for the reading
      Then the Recipes screen is shown with "Deep Olive Green" as the target

  Rule: A freshly captured reading is confirmed to the painter

    # UX: Paint Color Assistant.dc.html › S1.R1.E9 Acknowledge captured reading [button]
    Scenario: A just-captured reading is confirmed with a haptic and acknowledged
      Given the painter has just captured the sample "Deep Olive Green"
      When the readout for the captured sample is shown
      Then a haptic confirmation is given that the reading landed
      And the reading is marked as just captured until the painter acknowledges it
