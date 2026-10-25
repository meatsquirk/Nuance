# Approved 2026-10-24 by owner Matt Quirk (G-1). Authored 2026-10-23, decisions 2026-10-24, from the
# owner's change list + the wireframe (Paint Color Assistant.dc.html). Presentation/composition
# refinements to the Readout screen and the settings panel. This feature MODIFIES behaviour owned
# by already-signed-off features (bs-01 Color readout, bs-08 Display & simulation settings); each
# affected AC is named in the scenario comment so the test-review gate is explicit about what
# merged behaviour is changing.
#
# OWNER DECISIONS (2026-10-24):
#   * Hero value card, 0-10 value scale, all-spaces spec sheet: RESTORE (bring the readout back to
#     the wireframe composition — the skin matched but the layout had been simplified to flat regions).
#   * Four spaces shown together, no selector button: CIELCh, Munsell, sRGB, CIELAB.
#   * Space definitions: opened by tapping the space NAME; a fuller definition with an example.
#   * Two switchable readout layouts (value-first vs spec sheet): DROPPED — see bs-20-ui-improvements.deferred.md.
#   * Provenance chips, temperature, capture banner (incl. Acknowledge): KEEP as-is.
#   * Accessibility is OFF by default; while off it HIDES the Speak control (only).
#
# INTERPRETATIONS confirmed by owner 2026-10-24:
#   * Gating applies to SPEAK ONLY; the capture banner / Acknowledge stays always visible.
#   * The swatch "APPROX." caption is kept ALWAYS visible (judged universal, not CVD-specific).
#
# STILL OPEN:
#   * P3: this feature is intentionally left OPEN for further small enhancements (added later via a
#     plan upgrade), so it accretes batches rather than closing at one sign-off.
#   * B2: fuller definition COPY drafted (longer, with an example each) — pending owner edit; used at build time.
Feature: User interface improvements
  Presentation and composition refinements a colour-vision-deficient painter benefits from:
  the Readout shows every colour space at once instead of behind a selector, each space's name
  opens a fuller plain-language definition, the value reads in a prominent card with a 0-10 Munsell
  scale, the true-colour and grayscale swatches are shown at equal size, user-facing copy uses
  "Color", and the spoken-output affordance is revealed only when accessibility features are on.

  Boundary: the Readout screen and the Display & simulation settings panel only. This feature
  changes how existing readings and controls are PRESENTED; it adds no new colour science.
  Wireframe: Paint Color Assistant.dc.html — Readout screen (take A "value-first" and take B
  "spec sheet", merged into one layout) and the settings sheet.

  Rule: The value reads in a prominent bordered card
  # Restores the wireframe "value-first" hero card; refines bs-01 AC-1 presentation.

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout value hero card [.dc.html:232-256]
    Scenario: The lightness value is shown in a prominent bordered card
      Given the painter is reading the sample "Warm Terracotta" with Lightness 58
      When the readout for the sample is shown
      Then Lightness 58 is shown in a bordered card as the largest reading on the screen

  Rule: The Munsell value is presented on a labelled 0-10 scale
  # Restores the wireframe 11-step value strip; refines bs-01 AC-1.

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout value scale [.dc.html:244-255]
    Scenario: The Munsell value reads on a 0-10 scale with the sample marked
      Given the painter is reading a sample with Munsell value 2
      When the readout for the sample is shown
      Then a scale running from 0 to 10 is shown
      And the sample's position at value 2 is marked on the scale

  Rule: The displayed colour and the grayscale value swatch are shown at equal size
  # P2 — refines bs-01 AC-1 presentation.

    # UX: Paint Color Assistant.dc.html › S1.R1 gray chip [.dc.html:240] vs swatch [.dc.html:277]
    Scenario: The true-colour swatch is as large as the grayscale swatch
      Given the painter is reading a sample
      When the readout for the sample is shown
      Then the displayed-colour swatch and the grayscale value swatch are the same size

  Rule: All four colour spaces are shown at once, with no space selector
  # Supersedes bs-01 AC-5 ("several colour spaces, one at a time", element E11 selector).

    # UX: Paint Color Assistant.dc.html › S1.R1 Readout "spec sheet", all-at-once [.dc.html:284-301]
    Scenario: Every colour space is shown together on the readout
      Given the painter is reading the sample "Warm Terracotta"
      When the readout for the sample is shown
      Then the CIELCh values are shown
      And the Munsell notation is shown
      And the sRGB triplet and hex are shown
      And the CIELAB coordinates are shown
      And no colour-space selector control is present

  Rule: A colour space's name can be opened for a fuller definition
  # NEW (beyond the wireframe). The values are always shown (see the all-at-once rule); the painter
  # taps the space's NAME to reveal a fuller plain-language definition with an example.

    # UX: beyond wireframe (owner request)
    Scenario Outline: The painter opens a colour space's name to learn what it means
      Given the painter is reading a sample with all colour spaces shown
      When the painter opens the <space> name
      Then a plain-language definition of <space> is shown
      And an example accompanies the definition

      Examples:
        | space   |
        | CIELCh  |
        | Munsell |
        | sRGB    |
        | CIELAB  |

  Rule: Spoken output is revealed only when accessibility features are on
  # Gates bs-01 AC-8 (Speak, E10) only. Default OFF; hidden when off. (Acknowledge stays always on.)

    # UX: Paint Color Assistant.dc.html › settings sheet — accessibility features [new control]
    Scenario: Accessibility features are off by default
      Given the painter has not changed any settings
      When the settings panel is shown
      Then the accessibility-features control is off

    # UX: Paint Color Assistant.dc.html › S1.R1.E10 Speak this readout [button]
    Scenario: With accessibility features off, Speak is hidden
      Given accessibility features are off
      When the painter is reading a sample
      Then no "Speak this readout" control is shown

    # UX: Paint Color Assistant.dc.html › S1.R1.E10 Speak this readout [button]
    Scenario: Turning accessibility features on reveals Speak
      Given accessibility features are off
      When the painter turns accessibility features on
      And the painter is reading a sample
      Then a "Speak this readout" control is shown

  Rule: User-facing copy uses the spelling "Color"
  # P1 — the app currently uses "Colour"/"grayscale"; the wireframe uses American spelling.

    # UX: app-wide copy
    Scenario: The readout uses "Color" rather than "Colour"
      Given the painter is reading a sample
      When the readout for the sample is shown
      Then the user-facing copy spells it "Color"
      And the word "Colour" does not appear in the user-facing copy
