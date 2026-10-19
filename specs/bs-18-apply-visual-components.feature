# Feature: bs-18 Apply the visual design system to every screen and the app chrome
#
# Presentation-application feature over bs-17 (visual-design-system). bs-17 shipped
# the global THEME (warm-paper palette, Atkinson Hyperlegible fonts, cobalt accent)
# and BUILT + acceptance-tested the component wrappers (PillButton, SpeakButton,
# SurfaceCard, MonoLabel, SwatchCaption, ProvenanceBadge), but deliberately DEFERRED
# the "wholesale screen swap" (bs-17 APPLY-1, user decision 2026-10-18) to avoid
# regression risk to the signed-off bs-07..bs-11 suites. This feature resumes that
# work: it wires every primary screen onto those finished components, builds the
# wireframe's bottom navigation + top bar (previously classified "presentation / not
# specified"), and fixes the Capture-screen warning-banner overlap — so the running
# app matches the wireframe look-and-feel.
#
# Scope decisions (Matt Quirk, 2026-10-19): FULL CHROME (controls + bottom nav +
# top bar); ALL 8 screen areas (readout, capture, compare, recipes, palette,
# projects, display, onboarding). This feature is presentation only: it changes the
# widget that renders a control or region, never a screen's behaviour, data, numbers
# or semantics. Every AC is a structural, widget-level fact verified by Flutter
# widget/integration tests that assert the design-system wrapper is present AND the
# superseded ad-hoc widget is absent for each named control/region.

Feature: Apply the visual design system across the app
  As a colour-vision-deficient painter
  I want every screen and the app chrome to render in the one warm-paper design system
  So that the app reads as the single, legible, consistent surface the wireframe shows

  Background:
    Given the app is built on the one installed warm-paper theme (bs-17 THEME)
    And the design-system component wrappers from bs-17 are available

  # ---- App chrome -------------------------------------------------------------

  # UX: E44 (S1.R1) — bottom navigation (Capture / Compare / Recipes / Palette)
  Scenario: The app shows the design-system bottom navigation
    Given the app is open on any primary destination
    When the app chrome renders
    Then a bottom navigation bar offers the four destinations Capture, Compare, Recipes and Palette
    And the current destination is indicated by more than colour alone
    And the bar renders in the one installed theme's surface, ink and accent tokens

  # UX: E1 (S1.R1) — top bar / app chrome
  Scenario: Each primary screen shows the design-system top bar
    Given the app is open on a primary destination
    When the screen renders
    Then the top bar shows the destination title in Atkinson Hyperlegible
    And it exposes the back or close affordance that destination needs
    And it exposes the theme toggle, rendered through the theme

  # ---- Capture (E15–E21) ------------------------------------------------------

  # UX: E16, E18, E20, E21 — capture shutter, torch, import, actions
  Scenario: The Capture screen's controls render as design-system components
    Given the Capture screen is open
    When its controls render
    Then the capture action renders as the round 88px shutter button
    And the primary actions render as ink-filled pills and the secondary actions as outline pills
    And the torch and import-photo controls render as design-system controls, not ad-hoc buttons

  # UX: E15, E17, E19 — stability / accuracy / warning readings
  Scenario: The Capture screen's warnings stack without overlapping
    Given the Capture screen is showing more than one live warning
    When the warnings render over the viewfinder
    Then each warning reads as its own banner in the design-system banner style
    And no warning's text overlaps another warning's text

  # ---- Readout (E9–E14) -------------------------------------------------------

  # UX: E9, E10, E11, E12, E13, E14 — value, colour name, spaces, provenance, speak
  Scenario: The Readout screen renders its regions as cards with mono eyebrows and a speak FAB
    Given the Readout screen is open on a reading
    When the reading renders
    Then the value, colour-name and colour-space regions each sit in a surface card
    And each region's field eyebrow renders as an uppercase mono micro-label
    And the speak action renders as the round accent floating speak button

  # ---- Compare ----------------------------------------------------------------

  # UX: E9–E14 (comparison screen: compare-as-A/B, find recipes, speak)
  Scenario: The Compare screen renders its controls and rows as design-system components
    Given the Compare screen is open on a comparison
    When the comparison renders
    Then "Compare as A" and "Compare as B" render as outline pills
    And "Find mixing recipes" renders as an ink-filled pill
    And the difference and statement regions sit in surface cards
    And the speak action renders as the accent floating speak button

  # ---- Recipes ----------------------------------------------------------------

  # UX: recipes screen (recipe list, ranked-by note, out-of-gamut banner)
  Scenario: The Recipes screen renders recipes as cards with mono notes and pill actions
    Given the Recipes screen is open with recipes for a target
    When the recipe list renders
    Then each recipe renders in a surface card
    And the "ranked by" note and the out-of-gamut note render in the design-system mono/body styles
    And the recipe actions render as pills

  # ---- Palette (E30–E34) ------------------------------------------------------

  # UX: E30, E31, E33 — vision card, paint rows/chips, add from dataset
  Scenario: The Palette screen renders paints, provenance and the add action as design-system components
    Given the Palette screen is open
    When the paint list renders
    Then each paint row renders through the design-system row and chip components
    And each paint's provenance badge carries the glyph-and-border provenance signature
    And the add-from-dataset action renders as a pill

  # ---- Projects (E32, E34) ----------------------------------------------------

  # UX: E32, E34 — projects list, open / create project
  Scenario: The Projects region renders projects as cards with pill actions
    Given the Projects region is shown
    When the projects list renders
    Then each project entry renders in a surface card
    And the open and create-project actions render as pills

  # ---- Display & Onboarding ---------------------------------------------------

  # UX: E45 (theme / display settings), E42 (onboarding back) — configuration screens
  Scenario: The Display and Onboarding screens render through the design system
    Given the Display settings screen or an Onboarding step is open
    When the screen renders
    Then its view-switch and option controls render as pills or design-system segmented controls
    And each onboarding step's content sits in surface cards with next and back pills

  # ---- Cross-cutting guards ---------------------------------------------------

  # UX: — (cross-cutting; extends bs-17 "one installed theme" guarantee)
  Scenario: Every screen inherits the one installed theme
    Given any primary screen or configuration screen is open
    When it renders
    Then it does not wrap any child in its own Theme or MaterialApp
    And every surface reads its colours and type from the single installed theme

  # UX: — (cross-cutting; extends bs-17 SwatchCaption to all swatch-bearing screens)
  Scenario: Every swatch-bearing screen carries its approximation caption
    Given a screen that displays one or more colour swatches
    When the screen renders
    Then it shows exactly one swatch approximation caption beside its swatch group

  # UX: — (regression guard over bs-11 accessibility conformance)
  Scenario: The restyle preserves accessibility
    Given any screen after its controls are swapped to design-system components
    When its interactive controls and text are measured
    Then every interactive control reserves at least a 48dp tap target
    And every text pairing still meets the WCAG 2.2 AA contrast floor

  # UX: — (extends bs-17 AC-14 source-scan to the swapped screens)
  Scenario: No new hardcoded palette colours are introduced
    Given the swapped screen source under lib/
    When the design-system source-scan runs
    Then it finds no hardcoded palette Color(0x..) literal outside the bs-17 AC-14 exclusion list
