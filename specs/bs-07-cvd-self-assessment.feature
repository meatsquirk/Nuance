# Draft: awaiting owner approval (derived 2026-10-05 by /wireframe-behavior-specs)
Feature: CVD self-assessment (onboarding)
  Rather than require a clinical diagnosis, the app estimates the painter's
  colour-vision-deficiency type and severity through a tiered battery, fastest
  first, and lets the painter refine it over time. The result writes one stored
  CVD profile that configures the simulation, daltonization and confusion
  warnings used across the app. It estimates; it does not diagnose.

  Boundary: the onboarding self-assessment flow. The profile it writes is consumed
  by bs-03 (confusion warnings) and bs-08 (simulation). Tiers 2 and 4
  (pseudoisochromatic screening and adaptive threshold probing) are in scope but
  are not drawn in the wireframe; their scenarios here are proposed ahead of the
  mock at the owner's instruction (see the derivation report).
  Wireframe: Paint Color Assistant.dc.html, Onboarding flow (region S1.R1, elements
  E36-E41, E43).

  Rule: The self-assessment estimates; it does not diagnose

    # UX: Paint Color Assistant.dc.html › S1.R1 Onboarding flow — result caveat [body]
    Scenario: The estimate is labelled approximate and a clinical test is recommended
      Given the painter has completed the self-assessment
      When the result is shown
      Then the result is labelled an approximate estimate
      And a clinical anomaloscope test is recommended for ground truth

  Rule: Tier 0 — display and lighting setup precedes testing

    # UX: Paint Color Assistant.dc.html › S1.R1.E36 Display and lighting checks [button]
    # UX: Paint Color Assistant.dc.html › S1.R1.E43 Continue to next step [button]
    Scenario: The lighting setup must be confirmed before testing begins
      Given the painter is on the display and lighting setup step
      And the checks for screen brightness, night-light off and daylight are not all confirmed
      When the painter tries to continue
      Then testing does not begin until the lighting checks are confirmed

  Rule: Tier 1 — intake questions form a starting prior

    # UX: Paint Color Assistant.dc.html › S1.R1.E37 Intake question answers [button]
    Scenario: An intake answer contributes to the starting prior
      Given the painter is asked "Do reds, browns and greens get mixed up?"
      When the painter answers "Often"
      Then the answer is recorded toward the starting prior

    # UX: Paint Color Assistant.dc.html › S1.R1.E37 Intake question answers [body]
    Scenario: A prior clinical diagnosis entered at intake seeds the prior
      Given the painter reports a prior diagnosis of deutan deficiency at intake
      When the intake is recorded
      Then the starting prior is seeded as deutan

  Rule: Tier 2 — pseudoisochromatic screening detects presence and direction

    # UX: Paint Color Assistant.dc.html › S1.R1 Onboarding flow — screening tier [body]
    Scenario: Screening yields presence and the red-green versus blue-yellow direction
      Given the painter completes the openly-licensed plate screening
      When the screening is scored
      Then it reports whether a deficiency is present
      And it reports the red-green versus blue-yellow direction

  Rule: Tier 3 — the arrangement test orders colour caps by hue

    # UX: Paint Color Assistant.dc.html › S1.R1.E38 Arrange colour caps [button]
    Scenario: The painter places colour caps in hue order
      Given the arrangement test shows a pool of unplaced colour caps
      When the painter places a cap from the pool into the arrangement
      Then that cap takes the next position in the arranged order
      And it is removed from the pool

    # UX: Paint Color Assistant.dc.html › S1.R1.E39 Start the arrangement over [button]
    Scenario: Starting over clears the arrangement
      Given the painter has placed several caps in the arrangement
      When the painter starts the arrangement over
      Then all caps return to the pool and none are placed

    # UX: Paint Color Assistant.dc.html › S1.R1.E43 Skip the arrangement [button]
    Scenario: The painter skips the arrangement for now
      Given the painter has not placed all the caps
      When the painter chooses to skip the arrangement for now
      Then the self-assessment continues without the arrangement result

  Rule: Tier 4 — adaptive threshold probing yields a severity

    # UX: Paint Color Assistant.dc.html › S1.R1 Onboarding flow — threshold tier [body]
    Scenario: Threshold probing yields a severity along the confusion line
      Given the painter completes the adaptive threshold probing
      When the probing is scored
      Then it yields a severity value along the painter's confusion line

  Rule: The result states type and severity, adjustable by the painter

    # UX: Paint Color Assistant.dc.html › S1.R1.E40 Adjust CVD type [button]
    Scenario: The painter adjusts the estimated type by hand
      Given the result estimates the painter as deutan-type
      When the painter sets the type to protan
      Then the profile type is protan

    # UX: Paint Color Assistant.dc.html › S1.R1.E41 Severity slider [input]
    Scenario Outline: The severity value sets a plain-language band
      Given the painter is setting the severity on the result step
      When the painter sets the severity to <value>
      Then the result reads "<band>"

      Examples:
        | value | band     |
        | 30    | mild     |
        | 60    | moderate |
        | 90    | strong   |

    # UX: Paint Color Assistant.dc.html › S1.R1.E41 Severity slider [input]
    Scenario: The severity slider doubles as subjective self-calibration
      Given a simulated-versus-original colour pair is shown with the severity slider
      When the painter sets the severity until the pair stops looking different to them
      Then the chosen severity is kept as the subjective self-calibration

  Rule: Saving writes one profile that configures the CVD pipeline

    # UX: Paint Color Assistant.dc.html › S1.R1.E43 Save profile [button]
    Scenario: Saving the profile configures simulation, daltonization and confusion warnings
      Given the painter has a result of deutan-type, moderate
      When the painter saves the profile
      Then one stored CVD profile is written
      And it configures the simulation, the daltonization and the confusion-warning thresholds

  Rule: Progress across the steps is shown

    # UX: Paint Color Assistant.dc.html › S1.R1 Onboarding flow — step progress [body]
    Scenario: The current step is shown against the total
      Given the self-assessment has four steps
      When the painter is on the second step
      Then the progress indicator shows the second of four steps as current
