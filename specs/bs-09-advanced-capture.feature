# Draft: awaiting owner approval (derived 2026-10-05 by /wireframe-behavior-specs)
# Scope beyond the wireframe: scope §4.1 Should/Could capture features, not drawn in the mock.
Feature: Advanced capture
  The capture features the scope marks Should/Could but the wireframe does not
  draw: torch lighting with a colour-temperature warning, multi-point sampling,
  and wide-gamut / RAW capture. All sit behind the same CaptureSource interface
  that returns a normalized, colour-space-tagged sample.

  Boundary: extends the capture surface of bs-02. These are proposed ahead of any
  mock; a future wireframe revision should add their UX and re-link them.
  Builds on: bs-02.
  Source: scope §4.1; SI Cross-platform strategy (CaptureSource).

  Rule: The torch can light the subject, with a warning about its colour temperature

    # Spec: scope §4.1 — flash / torch control (Should)
    Scenario: Turning on the torch warns that its colour temperature biases the reading
      Given the painter is on the Capture screen in dim light
      When the painter turns on the torch
      Then a warning states the torch colour temperature will bias the reading

    # Spec: scope §4.1 — flash / torch control (Should)
    Scenario: A reading taken under the torch is labelled as lit by the torch
      Given the torch is on and its warning acknowledged
      When the painter commits a reading
      Then the reading records that it was taken under torch light

  Rule: Several points can be sampled at once

    # Spec: scope §4.1 — multi-point sampling (Should)
    Scenario: The painter samples several points together and gets all of them at once
      Given the painter has marked three points in the frame
      When the painter samples the marked points
      Then a reading is returned for each of the three points

    # Spec: scope §4.1 — multi-point sampling (Should)
    Scenario: Each multi-point reading keeps its own position and value
      Given three points have been sampled together
      When the readings are shown
      Then each reading keeps the position it was sampled from and its own colour value

    # Spec: scope §4.1 — multi-point sampling (Should)
    Scenario: Any two sampled points can be sent to a comparison
      Given three points have been sampled together
      When the painter sends two of the points to a comparison
      Then the two chosen points open as sample A and sample B

  Rule: Capture uses the widest colour space the device offers

    # Spec: scope §4.1 — RAW/DNG capture (Could); SI wide colour space
    Scenario: A capture is tagged with the colour space it was taken in
      Given the device supports a wide-gamut capture
      When the painter commits a reading
      Then the reading is tagged with the colour space it was captured in

    # Spec: scope §4.1 — RAW/DNG capture (Could)
    Scenario: RAW capture is used where the device supports it
      Given the device supports RAW capture
      When the painter commits a reading
      Then the reading is taken in RAW for the widest available colour data

    # Spec: SI Cross-platform strategy — widest colour space / RAW fallback
    Scenario: A device without wide-gamut capture falls back and labels the narrower space
      Given the device does not support a wide-gamut capture
      When the painter commits a reading
      Then the reading is captured in the device's standard colour space
      And the reading is tagged with that narrower colour space

  Rule: A normalized sample is returned regardless of platform

    # Spec: SI Cross-platform strategy — CaptureSource returns a normalized, tagged sample
    Scenario: The capture interface returns a normalized, colour-space-tagged sample
      Given a reading has been committed on either platform
      When the sample is handed to the rest of the app
      Then the sample is normalized and tagged with its colour space

    # Spec: SI D2 — native capture hidden behind CaptureSource
    Scenario: The rest of the app never sees the platform capture difference
      Given a reading is committed on Android and the same on iOS
      When each sample is handed to the colour-science layer
      Then both arrive in the same normalized, tagged form
