# Approved 2026-10-06 by owner Matt Quirk (G-1). Derived 2026-10-05 by /wireframe-behavior-specs.
Feature: Sample capture and sampling
  A painter captures a colour from the live camera or a photo, controlling how the
  colour is sampled and how trustworthy the reading is. Exposure, white balance and
  focus lock with a visible stability indicator; poor lighting downgrades the stated
  accuracy rather than failing silently; a reference card upgrades it. A committed
  reading settles over several frames and opens its readout.

  Boundary: the Capture screen only. Reading the captured colour is bs-01; comparing
  samples is bs-03. Accuracy tiers follow the solution-intent NFR table.
  Wireframe: Paint Color Assistant.dc.html, Capture screen (region S1.R1, elements
  E15-E21).

  Rule: The camera shows a live view with a centre-point eyedropper

    # UX: Paint Color Assistant.dc.html › S1.R1 Capture screen — live view [body]
    Scenario: The live camera view shows a centre-point eyedropper
      Given the painter has opened the Capture screen
      When the live camera view is shown
      Then a centre-point eyedropper marks where the colour will be sampled

  Rule: A colour is sampled at a point or as an area average of a chosen radius

    # UX: Paint Color Assistant.dc.html › S1.R1 Capture screen — sample point [body]
    Scenario: The painter samples the colour under the centre point
      Given the live camera view is shown with the sampling radius set to 5 px
      When the painter samples the colour at the centre point
      Then the sampled colour is the average over a 5 px radius under the point

    # UX: Paint Color Assistant.dc.html › S1.R1.E18 Sampling radius selector [button]
    Scenario Outline: The painter selects an area-average radius
      Given the live camera view is shown
      When the painter selects the <radius> sampling radius
      Then the reticle grows to <reticle>
      And the sampled colour is averaged over that radius

      Examples:
        | radius | reticle |
        | 1 px   | 8 px    |
        | 5 px   | 20 px   |
        | 21 px  | 44 px   |

  Rule: Exposure, white balance and focus lock with a visible stability indicator

    # UX: Paint Color Assistant.dc.html › S1.R1.E16 Exposure and focus lock [button]
    Scenario: Locking exposure, white balance and focus settles the reading
      Given the live camera view reads "SETTLING 6/12" with auto exposure
      When the painter locks exposure, white balance and focus
      Then the indicator reads "AE · AWB · AF LOCKED"
      And the stability indicator reads "STABLE 12/12"

    # UX: Paint Color Assistant.dc.html › S1.R1.E16 Exposure and focus lock [body]
    Scenario: Before locking, the stability indicator warns the reading is still settling
      Given the live camera view is in auto exposure
      When the reading has not yet been locked
      Then the stability indicator reads "SETTLING 6/12"
      And the lock control invites the painter to lock

  Rule: Poor lighting downgrades the stated accuracy rather than failing

    # UX: Paint Color Assistant.dc.html › S1.R1 Capture screen — low-light warning [body]
    Scenario: A low-light reading is marked approximate rather than refused
      Given the painter is capturing without a reference card in dim light
      When the reading is committed
      Then a low-light warning is shown
      And the stated accuracy is downgraded to approximate, within delta-E 8 of ground truth

    # UX: Paint Color Assistant.dc.html › S1.R1.E15 Dismiss low-light warning [button]
    Scenario: The painter dismisses the low-light warning and capture continues at the lower accuracy
      Given a low-light warning is shown on the Capture screen
      When the painter dismisses the warning
      Then the warning is cleared
      And the reading remains labelled approximate

  Rule: A reference card calibrates capture and upgrades the stated accuracy

    # UX: Paint Color Assistant.dc.html › S1.R1.E17 Calibrate with reference card [button]
    Scenario: Calibrating against a reference card upgrades the accuracy tier
      Given a reference card is present in the frame under controlled lighting
      When the painter calibrates against the reference card
      Then captures are normalised against the card
      And the stated accuracy is upgraded to within delta-E 3 of ground truth

  Rule: A colour can be sampled from an existing photo

    # UX: Paint Color Assistant.dc.html › S1.R1.E19 Import photo [button]
    Scenario: The painter samples a colour from a gallery photo
      Given the painter has a photograph in the device gallery
      When the painter imports the photograph and samples a point on it
      Then the sampled colour is read from that point of the photograph

  Rule: The camera can be previewed in value-only grayscale

    # UX: Paint Color Assistant.dc.html › S1.R1.E21 Value-only camera preview [button]
    Scenario: The painter previews the camera feed in value-only grayscale
      Given the live camera view is shown in colour
      When the painter turns on the value-only view
      Then the camera feed is shown in grayscale
      And the control reads "✓ Value"

  Rule: Committing a reading settles over several frames and opens the readout

    # UX: Paint Color Assistant.dc.html › S1.R1.E20 Capture sample [button]
    Scenario: Capturing commits a settled reading and opens its readout with a haptic
      Given the live camera view reads "STABLE 12/12"
      When the painter captures the sample
      Then the reading is averaged over several frames before it is committed
      And a haptic confirms the reading landed
      And the readout for the captured sample "Deep Olive Green" is shown
