# Approved 2026-10-11 by Matt Quirk (G-1) — derived 2026-10-05 by /wireframe-behavior-specs
Feature: Display, simulation and spoken output
  Cross-cutting accessibility controls reached from any screen: a CVD simulation of
  displayed colour for the painter's own type and severity, a value-only grayscale
  view of the whole app, and spoken output with consistent phrasing that can be
  repeated. These make a reading legible without relying on colour discrimination.

  Boundary: the display and simulation settings and the spoken-output behaviour.
  The painter's CVD type and severity come from bs-07; the per-reading "speak this"
  triggers live with their own screens (bs-01, bs-03, bs-04). Theme (light/dark) is
  presentation and is not specified. Daltonization (scope §5.4) is in scope but is
  not drawn in the wireframe and is left to a later feature (see the gap report).
  Builds on: bs-07.
  Wireframe: Paint Color Assistant.dc.html, display and simulation settings and the
  spoken-output sheet (region S1.R1, elements E2, E46-E48, E50).

  Rule: Display and simulation settings are reached from any screen

    # UX: Paint Color Assistant.dc.html › S1.R1.E2 Open display and simulation settings [button]
    Scenario: The painter opens the display and simulation settings
      Given the painter is on any screen
      When the painter opens the display and simulation settings
      Then the simulation, grayscale and theme controls are shown

  Rule: The app can simulate the painter's CVD type over displayed colour

    # UX: Paint Color Assistant.dc.html › S1.R1.E47 CVD simulation selector [button]
    Scenario: With simulation off, displayed colour is shown as a trichromat sees it
      Given the CVD simulation is off
      When a colour is displayed
      Then the colour is shown as a trichromat sees it

    # UX: Paint Color Assistant.dc.html › S1.R1.E47 CVD simulation selector [button]
    Scenario Outline: The painter simulates a chosen deficiency type alongside the original
      Given the display and simulation settings are open
      When the painter sets the simulation to <type>
      Then the displayed colour is shown simulated for <type>
      And the original colour is shown alongside the simulation

      Examples:
        | type   |
        | protan |
        | deutan |
        | tritan |

  Rule: The simulation strength follows a severity slider

    # UX: Paint Color Assistant.dc.html › S1.R1.E48 Simulation severity slider [input]
    Scenario: The painter sets the simulation strength with the severity slider
      Given the simulation is set to deutan
      When the painter sets the simulation severity to 60
      Then the simulation is rendered at that severity

  Rule: Simulation and value-only grayscale are mutually exclusive views

    # UX: Paint Color Assistant.dc.html › S1.R1.E46 Value-only grayscale of the whole app [button]
    Scenario: Turning on grayscale clears an active simulation
      Given the simulation is set to deutan
      When the painter turns on the value-only grayscale view of the whole app
      Then the whole app is shown in grayscale
      And the simulation is turned off

  Rule: The whole app can be shown in value-only grayscale

    # UX: Paint Color Assistant.dc.html › S1.R1.E46 Value-only grayscale of the whole app [button]
    Scenario: The value-only view greys the camera and the palettes as well as the readings
      Given the painter turns on the value-only grayscale view
      When the camera and the palettes are shown
      Then the camera feed and the palettes are rendered in grayscale

  Rule: Colour meaning never stands alone under any view

    # UX: Paint Color Assistant.dc.html › S1.R1.E47 CVD simulation selector [body]
    Scenario: A reading under simulation keeps its numeric value and label
      Given the simulation is set to deutan
      When a reading is displayed
      Then the reading still shows its numeric value and plain-language label, not colour alone

  Rule: Spoken output uses consistent phrasing and can be repeated

    # UX: Paint Color Assistant.dc.html › S1.R1.E50 Repeat spoken output [button]
    Scenario: The painter repeats the last spoken output
      Given the painter has just heard a reading spoken
      When the painter asks to repeat it
      Then the same spoken output is played again

    # UX: Paint Color Assistant.dc.html › S1.R1.E50 Repeat spoken output [body]
    Scenario: Readings and comparisons are spoken through one consistent phrasing
      Given spoken output is produced for a reading and for a comparison
      When each is spoken
      Then both use the one consistent phrasing of the shared speech service

  Rule: Spoken output never dismisses itself

    # UX: Paint Color Assistant.dc.html › S1.R1.E50 Repeat spoken output [body]
    Scenario: The spoken-output panel stays until the painter leaves it
      Given the painter has opened spoken output for a reading
      When the painter does not act for a while
      Then the spoken output stays available and nothing dismisses it on a timer
