# Proposed 2026-10-16 by /feature-next-phase from the Paint Color Assistant
# wireframe (docs/Color blindness artist tool.zip → "Paint Color Assistant.dc.html").
# Visual design system — PRESENTATION scope. The original derivation deliberately
# filed the look-and-feel as "excluded (presentation)" (specs/wireframe-spec-derivation.md
# §6) and "not specified" (§8: theme, layout). Building it is an owner-authorised
# scope expansion; owner approval is pending (G-1), which also amends the solution
# intent to bring a visual design system in-bound.
Feature: Visual design system
  The app wears one deliberate skin, taken from the wireframe: a warm-paper
  palette, the Atkinson Hyperlegible typeface, fully-rounded pill controls,
  bordered surface cards and uppercase monospace micro-labels. The skin lives in
  one theme chokepoint and a small set of styled components, so every screen
  inherits it and no screen reinvents it.

  Boundary: this is styling only — what the surface looks like, not what it says
  or how it is laid out. It deliberately does NOT re-assert the measurable
  accessibility criteria bs-11 owns (contrast ratio, 200% font scaling, 48dp tap
  targets, screen-reader semantics); those remain bs-11's, and this skin is held
  to them. Layout CHOICE stays unspecified (bs-03 comparison layout, bs-01/bs-08
  readout layout): these rules style whatever layout renders. Only the light
  warm-paper theme is in-bound; the wireframe's dark theme is deferred (bs-08
  leaves light/dark unspecified) pending a separate decision.
  Source: the wireframe's THEME tokens and component treatments; SI §Presentation
  (Flutter UI) to be amended at G-1 to name a visual design system.

  Rule: The warm-paper palette is the single source of surface and ink colour

    # UX: THEME tokens --bg #F3F1EC, --sf #FFFFFF, --sf2 #E9E6DF
    Scenario: Surfaces use the warm-paper palette
      Given any screen is shown
      When its surfaces are rendered
      Then the background is the warm paper tone, raised surfaces are the paper
        white and sunken surfaces are the muted paper tone, all from the theme

    # UX: THEME tokens --ink #16150F, --mut #57544C, --ln #CFCAC0
    Scenario: Ink, muted text and hairlines use the warm-paper neutrals
      Given a screen shows text and dividers
      When they are rendered
      Then primary text uses the near-black ink, secondary text the warm grey,
        and dividers the paper hairline, all read from the theme

    # UX: THEME token --acc (oklch 0.48 0.16 262 ≈ #2F55C8) / --accInk #FFFFFF
    Scenario: The primary action colour is the cobalt accent
      Given a screen shows its primary call-to-action surface
      When it is rendered
      Then it is filled with the cobalt accent and its label is white, from the theme

    # UX: the skin must stay within bs-11's floor — references, does not restate it
    Scenario: The warm-paper palette still meets the accessibility contrast floor
      Given the warm-paper theme is installed
      When every meaningful text-on-surface pairing is measured
      Then each still clears the accessibility contrast floor that bs-11 requires

  Rule: Atkinson Hyperlegible is the app's typeface

    # UX: font-family 'Atkinson Hyperlegible Next' on prose, headings, labels
    Scenario: Prose and headings render in Atkinson Hyperlegible Next
      Given a screen shows headings and body text
      When they are rendered
      Then they use the Atkinson Hyperlegible Next family from the theme

    # UX: font-family 'Atkinson Hyperlegible Mono' on micro-labels and readouts
    Scenario: Micro-labels and numeric readouts render in Atkinson Hyperlegible Mono
      Given a screen shows a micro-label or a numeric readout
      When it is rendered
      Then it uses the Atkinson Hyperlegible Mono family from the theme

  Rule: Shape and weight follow the wireframe scale

    # UX: pills fully rounded at half-height; cards radius 16–22; frame 44
    Scenario: Buttons render as fully-rounded pills and cards as rounded panels
      Given a screen shows buttons and cards
      When they are rendered
      Then each button is a fully-rounded pill and each card has the rounded-panel
        corner radius, from the theme's shape tokens

    # UX: border widths 1px hairline / 2px standard / 3px emphasis
    Scenario: Borders follow the weight scale
      Given a screen shows bordered elements
      When their borders are rendered
      Then hairline dividers are thin, standard cards and buttons use the medium
        weight, and emphasis or warning elements use the heavy weight

    # UX: mono micro-label — 700, letter-spacing .06em, uppercase
    Scenario: Monospace micro-labels render uppercase with wide letter-spacing
      Given a screen shows a monospace micro-label
      When it is rendered
      Then its text is uppercase, bold and widely letter-spaced

  Rule: The core components carry the wireframe treatment

    # UX: primary = ink-fill pill (weight 800); secondary = outline pill (ink/line)
    Scenario: Primary actions render as ink-filled pills and secondary as outline pills
      Given a screen shows a primary action and a secondary action
      When they are rendered
      Then the primary action is an ink-filled pill and the secondary action is a
        transparent pill with a border

    # UX: round accent FAB with speaker-wave glyph (sizes 64/52/44)
    Scenario: The speak action renders as a round accent floating button
      Given a screen offers spoken output
      When its speak control is rendered
      Then it is a round button filled with the accent colour, carrying a speaker icon

    # UX: cards var(--sf)+2px var(--ln); emphasis 2px var(--ink); inverted var(--ink) bg
    Scenario: Panels render as bordered surface cards with emphasis and inverted variants
      Given a screen shows a panel
      When it is rendered
      Then an ordinary panel is a surface card with a hairline-weight border, an
        emphasis panel has an ink border, and an inverted panel is ink-filled with
        paper-coloured text

    # UX: PROV badges — glyph ◉/∑/≈/✓ + solid/fill/dashed border, not hue alone
    Scenario: Provenance badges render with the glyph-and-border signature
      Given a provenance badge is shown
      When it is rendered
      Then its kind is carried by a glyph and a border style, not by colour alone

  Rule: The design system is applied across every primary screen

    # UX: THEMES applied once on the device root; all screens inherit
    Scenario: Every screen inherits the one installed theme
      Given the app is assembled
      When any primary screen is shown
      Then it reads its colours and type from the single installed theme, and no
        screen installs its own theme or hardcodes a palette colour

    # UX: "Swatches are screen approximations. Trust the numbers." / "APPROX."
    Scenario: A displayed colour swatch carries its approximation caption
      Given a screen renders a colour swatch
      When the swatch is shown
      Then it is accompanied by a caption that the swatch is an approximation and
        the numbers are authoritative
