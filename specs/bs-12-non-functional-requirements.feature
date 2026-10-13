# Approved 2026-10-13 by Matt Quirk (G-1; derived 2026-10-05 by /wireframe-behavior-specs)
# Non-functional: testable system-wide requirements, not a single UX element.
Feature: Core non-functional requirements
  The system-wide requirements the solution intent states as testable: everything
  works offline, responses stay within a performance budget, data stays private and
  on the device, a reading is never silently untrustworthy, accuracy meets explicit
  targets, the mixing engine and CVD model are swappable, and one codebase serves
  both platforms.

  Boundary: cross-cutting requirements verified across the app, not behaviour of one
  screen. Accessibility conformance is bs-11.
  Source: SI Non-functional requirements and accuracy targets; scope §8; D1–D5.

  Rule: Every core function works offline

    # Spec: SI NFR Offline
    Scenario: With networking disabled, every core function still works
      Given networking is disabled on the device
      When the painter captures, reads out, compares, searches recipes, saves a project and exports it
      Then every one of those functions works

    # Spec: SI NFR Offline — no connectivity dependency
    Scenario: No core function blocks on connectivity
      Given networking is disabled
      When the painter uses any core function
      Then the function never waits on or requires a network connection

  Rule: The app responds within the performance budget

    # Spec: SI NFR Performance — reading settle time
    Scenario: A committed reading settles within the budget with a visible indicator
      Given the painter commits a reading
      When the frames are averaged
      Then the reading settles within about one to two seconds
      And a stability indicator shows progress until it settles

    # Spec: SI NFR Performance — recipe search time
    Scenario: Recipe search returns within the budget
      Given the painter searches recipes for a target on target hardware
      When the search runs
      Then the top three to five candidates return within about one to two seconds

    # Spec: SI NFR Performance — live preview
    Scenario: Live capture holds a usable preview frame rate
      Given the live camera view is open
      When the preview runs
      Then it holds a usable frame rate

  Rule: Data stays private and on the device

    # Spec: SI NFR Privacy & security
    Scenario: Photos and samples never leave the device
      Given the painter has captured photos and samples
      When the app operates in v1
      Then the photos and samples never leave the device

    # Spec: SI NFR Privacy & security — no account or telemetry
    Scenario: There is no account and no telemetry in v1
      Given the painter uses the app in v1
      When the app runs
      Then it requires no account and sends no telemetry

    # Spec: SI NFR Privacy & security — future sync is opt-in
    Scenario: Any future sync is opt-in and explicit
      Given a future sync capability exists
      When data would be shared off the device
      Then it happens only after the painter opts in explicitly

  Rule: A reading is never silently untrustworthy

    # Spec: SI NFR Reliability
    Scenario: Poor conditions downgrade the stated accuracy rather than failing quietly
      Given poor lighting, unlocked exposure, or a missing reference card
      When a reading is produced
      Then its stated accuracy is downgraded rather than the reading being returned as if trustworthy

  Rule: Accuracy meets the stated targets

    # Spec: scope §8; SI accuracy table
    Scenario Outline: Each condition meets its accuracy target
      Given a <condition>
      When the result is validated against measured ground truth
      Then it meets the target "<target>"

      Examples:
        | condition                                          | target                                          |
        | capture with reference card in controlled lighting | delta-E00 ≤ 3 from spectrophotometer ground truth |
        | capture without reference card in daylight         | delta-E00 ≤ 8, labelled approximate               |
        | recipe prediction versus a physically mixed swatch | delta-E00 ≤ 5 for in-gamut targets                |
        | out-of-gamut target                                | identified as out of gamut, no false recipe       |

  Rule: The engine and models are swappable behind interfaces

    # Spec: SI NFR Maintainability; D3
    Scenario: The mixing engine can be replaced without touching its callers
      Given the mixing engine sits behind its interface
      When the engine implementation is swapped
      Then the callers are unchanged

    # Spec: SI NFR Maintainability; D10
    Scenario: The CVD model can be replaced without touching its callers
      Given the CVD model sits behind its interface
      When the model implementation is swapped
      Then the callers are unchanged

    # Spec: SI NFR Maintainability; D4
    Scenario: Colour-science conversions come from one tested library
      Given a colour-space conversion or a delta-E is needed
      When the conversion is performed
      Then it is computed by the one tested colour-science library

  Rule: One codebase serves both platforms

    # Spec: SI NFR Portability; D1, D2
    Scenario: Only the native capture implementation differs per platform
      Given the app is built for Android and for iOS
      When the two builds are compared
      Then only the native capture implementation differs between them
