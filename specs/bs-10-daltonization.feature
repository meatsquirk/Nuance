# Approved 2026-10-13 by Matt Quirk (G-1; derived 2026-10-05 by /wireframe-behavior-specs)
# Scope beyond the wireframe: scope §5.4 daltonization, not drawn in the mock.
Feature: Daltonization and colour-distinction aids
  An optional display mode that remaps shown colours to maximise distinguishability
  for the painter's own CVD type and severity. Daltonization helps the painter tell
  colours apart; it is distinct from the simulation (bs-08), which shows how the
  painter sees. It is injected across every screen and never removes the label or
  number an element already carries.

  Boundary: a display-only remap of shown colour. It changes nothing stored. The
  type and severity it uses come from the stored CVD profile (bs-07). Proposed
  ahead of any mock.
  Builds on: bs-07.
  Source: scope §5.4, §5.1; SI Accessibility; D10.

  Rule: The UI can remap colours to maximise distinguishability for the painter's type

    # Spec: scope §5.4 — daltonization mode
    Scenario Outline: Daltonization remaps displayed colours for the painter's type
      Given the painter's stored profile is <type>
      When the painter turns on daltonization
      Then displayed colours are remapped to be more distinguishable for a <type> viewer

      Examples:
        | type   |
        | protan |
        | deutan |
        | tritan |

    # Spec: scope §5.4 — daltonization mode off
    Scenario: With daltonization off, colours are shown unremapped
      Given daltonization is off
      When colours are displayed
      Then they are shown with their original values

  Rule: Remapping never removes the meaning carried in text or number

    # Spec: scope §5.1 — meaning never in colour alone
    Scenario: A remapped element still shows its label and value
      Given daltonization is on
      When a colour-coded element is displayed
      Then it still shows its label and numeric value, not colour alone

    # Spec: scope §5.1, §6.5 — provenance stays legible under daltonization
    Scenario: A provenance badge stays distinguishable under daltonization
      Given daltonization is on
      When a value's provenance is shown
      Then the provenance remains readable from its label and icon, not its colour

  Rule: Daltonization follows the painter's stored profile

    # Spec: scope §5.4; D10 — remap driven by stored profile
    Scenario: The remap uses the type and severity from the stored profile
      Given the stored profile is deutan-type at moderate severity
      When daltonization is on
      Then the remap is computed for deutan at moderate severity

    # Spec: scope §5.4 — remap updates with the profile
    Scenario: Changing the profile updates the remap
      Given daltonization is on for a deutan profile
      When the painter's stored profile changes to protan
      Then the remap is recomputed for protan

  Rule: Daltonization is a display-only aid, distinct from simulation

    # Spec: SI Accessibility — daltonization versus simulation
    Scenario: Daltonization remaps to help the painter, where simulation shows how they see
      Given both daltonization and simulation are available
      When the painter turns daltonization on
      Then colours are remapped to aid distinction, not shown as the painter perceives them

    # Spec: scope §5.4; D9 — display-only, stored values unchanged
    Scenario: Daltonization changes only what is shown, not stored values
      Given a sample has stored colour values
      When daltonization remaps its displayed colour
      Then the stored colour values are unchanged

  Rule: Daltonization is injected across every screen

    # Spec: SI Accessibility — cross-cutting services injected into every screen
    Scenario: Daltonization applies on every screen while it is on
      Given daltonization is on
      When the painter moves between the capture, readout and palette screens
      Then the remap is applied on each screen

  Rule: Daltonization needs a profile to remap against

    # Spec: scope §4.5, §5.4 — remap depends on a known type and severity
    Scenario: Without a stored profile, daltonization offers no remap
      Given no CVD profile has been saved
      When the painter opens the daltonization control
      Then it reports that a self-assessment is needed before colours can be remapped
