# Approved 2026-10-07 by Matt Quirk (owner) — G-1 (derived 2026-10-05 by /wireframe-behavior-specs)
Feature: Relative comparison
  The flagship reading for a colour-vision-deficient painter: two samples compared
  as an explicit, spoken relational statement — lighter or darker by, more or less
  saturated by, hue shifted by so many degrees toward a named direction — with an
  overall delta-E and a plain verdict, so the painter never has to trust their eyes.
  When the two samples collide on the painter's confusion line, the comparison says so.

  Boundary: the Comparison screen. Reading one sample in full is bs-01; the sample
  values come from captures (bs-02). The painter's CVD profile that drives the
  confusion check is configured in bs-07. The choice of comparison layout
  (Ledger / Sentence / Scales) is presentation and is not specified.
  Builds on: bs-01, bs-02.
  Wireframe: Paint Color Assistant.dc.html, Comparison screen (region S1.R1,
  elements E3-E8; sample picker E49).

  Rule: The painter chooses the two samples to compare

    # UX: Paint Color Assistant.dc.html › S1.R1.E3 Choose sample A [button]
    # UX: Paint Color Assistant.dc.html › S1.R1.E49 Sample picker [button]
    Scenario: The painter chooses sample A from the saved samples
      Given the Comparison screen is open
      When the painter chooses "Warm Terracotta" as sample A
      Then "Warm Terracotta" with L 58, C 34, h 42 degrees is shown in slot A

    # UX: Paint Color Assistant.dc.html › S1.R1.E5 Choose sample B [button]
    # UX: Paint Color Assistant.dc.html › S1.R1.E49 Sample picker [button]
    Scenario: The painter chooses sample B from the saved samples
      Given sample A is "Warm Terracotta"
      When the painter chooses "Raw Sienna Light" as sample B
      Then "Raw Sienna Light" with L 70, C 25, h 60 degrees is shown in slot B

  Rule: The comparison can be reversed

    # UX: Paint Color Assistant.dc.html › S1.R1.E4 Swap A and B [button]
    Scenario: Swapping exchanges the two samples and re-expresses the difference
      Given sample A is "Warm Terracotta" and sample B is "Raw Sienna Light"
      When the painter swaps A and B
      Then sample A is "Raw Sienna Light" and sample B is "Warm Terracotta"
      And the relational statement is re-expressed from the new A to the new B

  Rule: The comparison states an overall difference with a plain verdict

    # UX: Paint Color Assistant.dc.html › S1.R1 Comparison screen — overall difference [body]
    Scenario: The overall difference is stated as a delta-E with a plain verdict
      Given sample A is "Warm Terracotta" and sample B is "Raw Sienna Light"
      When the comparison is shown
      Then the overall difference reads "delta-E00 14.2"
      And it carries the plain verdict "clearly different"

  Rule: The comparison decomposes the difference into lightness, saturation and hue

    # UX: Paint Color Assistant.dc.html › S1.R1 Comparison screen — relational statement [body]
    Scenario: The difference is decomposed into lightness, saturation and hue
      Given sample A is "Warm Terracotta" and sample B is "Raw Sienna Light"
      When the comparison is shown
      Then it states "Lighter by 12" from L 58 to L 70
      And it states "Less saturated by 9" from C 34 to C 25
      And it states "Hue shifted 18 degrees toward yellow" from h 42 to h 60

    # UX: Paint Color Assistant.dc.html › S1.R1 Comparison screen — unchanged dimension [body]
    Scenario: A dimension that does not change is stated as unchanged
      Given sample A and sample B share the same hue angle of 42 degrees
      When the comparison is shown
      Then it states "Same hue" for the hue dimension

  Rule: A pair that collides on the painter's confusion line is flagged

    # UX: Paint Color Assistant.dc.html › S1.R1 Comparison screen — confusion warning [body]
    Scenario: A confusable pair is flagged for the painter's CVD type
      Given the painter's profile is deutan-type
      And sample A is "Mid Raw Umber" and sample B is "Ultramarine Shadow", which fall on the painter's confusion line
      When the comparison is shown
      Then a confusion warning states the two will look identical to the painter but are clearly different to others

    # UX: Paint Color Assistant.dc.html › S1.R1 Comparison screen — confusion warning [body]
    Scenario: A clearly distinct pair is not flagged as confusable
      Given the painter's profile is deutan-type
      And sample A is "Warm Terracotta" and sample B is "Raw Sienna Light", which do not fall on the painter's confusion line
      When the comparison is shown
      Then no confusion warning is shown

  Rule: The comparison can be spoken, including any confusion warning

    # UX: Paint Color Assistant.dc.html › S1.R1.E6 Speak whole comparison [button]
    Scenario: Speaking the comparison includes the confusion warning
      Given a confusion warning is shown for sample A and sample B
      When the painter asks to speak the whole comparison
      Then the spoken output states the relational statement and the confusion warning

  Rule: Either sample can be opened in full from the comparison

    # UX: Paint Color Assistant.dc.html › S1.R1.E7 Open readout for A [button]
    Scenario: The painter opens the full readout for sample A
      Given sample A is "Warm Terracotta"
      When the painter opens the readout for sample A
      Then the Readout screen is shown for "Warm Terracotta"

    # UX: Paint Color Assistant.dc.html › S1.R1.E8 Open readout for B [button]
    Scenario: The painter opens the full readout for sample B
      Given sample B is "Raw Sienna Light"
      When the painter opens the readout for sample B
      Then the Readout screen is shown for "Raw Sienna Light"

  Rule: A comparison needs two samples

    # UX: Paint Color Assistant.dc.html › S1.R1.E5 Choose sample B [button]
    Scenario: With no second sample chosen, the comparison invites one
      Given sample A is "Warm Terracotta" and no sample B has been chosen
      When the Comparison screen is shown
      Then no relational statement is shown
      And the screen invites the painter to choose sample B
