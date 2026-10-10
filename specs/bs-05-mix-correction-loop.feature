# Approved 2026-10-10 by Matt Quirk (G-1) — derived 2026-10-05 by /wireframe-behavior-specs
Feature: Mix-correction loop
  After mixing a recipe, the painter photographs the actual swatch and the app
  compares it to the target, states how far off it is, and suggests a concrete
  correction ("add a little more white, a touch of blue"). The painter can
  re-photograph to re-check, and save a satisfactory mix, which promotes the
  value to the single-user "Confirmed · you" provenance tier. This iterative
  correction is the single-user replacement for community refinement in v1.

  Boundary: the Correction screen. Solving the recipe is bs-04; photographing the
  swatch reuses capture (bs-02). The community "Confirmed by N painters" tier is
  a Phase-2 capability and is not specified here (see the gap report).
  Builds on: bs-04, bs-02.
  Wireframe: Paint Color Assistant.dc.html, Correction screen (region S1.R1,
  elements E26-E29).

  Rule: The painter checks a physical mix against the target

    # UX: Paint Color Assistant.dc.html › S1.R1.E26 Check my mix [button]
    Scenario: Checking the mix photographs the swatch and compares it to the target
      Given the painter has mixed a recipe for the target "Deep Olive Green"
      When the painter chooses to check the mixed swatch
      Then the mixed swatch is photographed
      And its colour is compared to the target "Deep Olive Green"

  Rule: The check states how far the mix is from the target

    # UX: Paint Color Assistant.dc.html › S1.R1 Correction screen — difference [body]
    Scenario: The difference from the target is stated as a delta-E with a plain verdict
      Given the mixed swatch reads L 36, C 30, h 114 against the target "Deep Olive Green" at L 42
      When the comparison is shown
      Then the difference is stated as a delta-E00 with the plain verdict "noticeably off"

    # UX: Paint Color Assistant.dc.html › S1.R1 Correction screen — difference [body]
    Scenario: The difference is decomposed and leads with value for a CVD painter
      Given the mixed swatch reads L 36 against the target at L 42
      When the comparison is shown
      Then it states the mix is "too dark by 6" as the leading reading
      And it states the hue is shifted toward green

  Rule: The check suggests a concrete correction

    # UX: Paint Color Assistant.dc.html › S1.R1 Correction screen — correction [body]
    Scenario: A concrete correction names the paint and the amount to add
      Given the mixed swatch is too dark and shifted toward green against the target
      When the correction is shown
      Then it suggests adding about one part more Titanium White

    # UX: Paint Color Assistant.dc.html › S1.R1 Correction screen — correction [body]
    Scenario: A small correction is expressed as a touch of
      Given the correction also needs a small amount of Yellow Ochre
      When the correction is shown
      Then the Yellow Ochre adjustment is expressed as "a touch of"

    # UX: Paint Color Assistant.dc.html › S1.R1 Correction screen — correction [body]
    Scenario: A mix already within tolerance needs no correction
      Given the mixed swatch is within delta-E 2 of the target
      When the comparison is shown
      Then the verdict is "very close"
      And no correction is suggested

  Rule: The correction can be spoken

    # UX: Paint Color Assistant.dc.html › S1.R1.E27 Speak correction [button]
    Scenario: The painter hears the correction spoken
      Given a correction has been computed for the mixed swatch
      When the painter asks to speak the correction
      Then the spoken output states the difference and the paints to add

  Rule: The painter can re-photograph to re-check the mix

    # UX: Paint Color Assistant.dc.html › S1.R1.E28 Re-photograph swatch [button]
    Scenario: Re-photographing the swatch re-checks it against the target
      Given a correction has been applied to the physical mix
      When the painter re-photographs the swatch
      Then the swatch is compared to the target again
      And the stated difference and verdict are updated

  Rule: A confirmed mix is saved and promotes the value's provenance

    # UX: Paint Color Assistant.dc.html › S1.R1.E29 Save confirmed mix [button]
    Scenario: Saving a satisfactory mix promotes it to Confirmed by the painter
      Given the painter is satisfied with the mixed swatch for "Deep Olive Green"
      When the painter saves the mix as confirmed
      Then the value is promoted to the provenance "Confirmed — you measured this"
      And the note records it was confirmed after the painter photographed their own swatch

    # UX: Paint Color Assistant.dc.html › S1.R1.E29 Save confirmed mix [body]
    Scenario: A value confirmed by the painter shows its Confirmed provenance in later readouts
      Given the painter has saved a confirmed mix for "Deep Olive Green"
      When the value is shown in a later readout
      Then it carries the provenance "Confirmed — you measured this"
