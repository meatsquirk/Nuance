# Approved 2026-10-13 by Matt Quirk (owner). Derived 2026-10-05 by /wireframe-behavior-specs.
# Non-functional: cross-cutting accessibility acceptance criteria, not a single UX element.
Feature: Accessibility conformance
  Accessibility is acceptance criteria, not a checklist, enforced structurally so a
  non-compliant screen is hard to build. These are the cross-cutting rules every
  feature is held to: no meaning in colour alone, a size-and-scaling floor, full
  screen-reader operation, nothing time-limited, two conformance gates on every
  feature, and device-measured iOS parity.

  Boundary: conformance rules applied to every screen, not behaviour of one screen.
  The interactive accessibility behaviours (spoken output, simulation, grayscale,
  daltonization) are bs-08 and bs-10.
  Source: scope §5; SI Accessibility as an architectural concern; Cross-platform
  parity acceptance.

  Rule: No element conveys meaning by colour alone

    # Spec: scope §5.1; SI label contract on every coloured element
    Scenario: Every colour-coded element carries a non-colour cue
      Given a screen shows a colour-coded element
      When the element is rendered
      Then it carries a label, an icon, a pattern or a numeric value alongside the colour

    # Spec: scope §5.1 — no bare status dots
    Scenario: A status is never rendered as a bare colour dot
      Given a status would otherwise be shown by colour
      When the status is rendered
      Then it is shown with text or an icon, not a bare colour dot

  Rule: Text and targets meet the size and scaling floor

    # Spec: scope §5.7 — font scaling to 200%
    Scenario: System font scaling to 200 percent does not break the layout
      Given the system font scale is set to 200 percent
      When any screen is shown
      Then its content stays readable and the layout does not break

    # Spec: scope §5.7 — minimum tap targets
    Scenario: Interactive targets meet the minimum size
      Given a screen shows interactive targets
      When the targets are measured
      Then each is at least 48 density-independent pixels

    # Spec: scope §5.7 — high contrast
    Scenario: Text meets the high-contrast floor
      Given text is shown on any screen
      When its contrast is measured against its background
      Then it meets the WCAG 2.2 AA contrast floor

  Rule: Every screen is fully operable under a screen reader

    # Spec: scope §5.8; SI meaningful labels
    Scenario: Every control exposes a meaningful screen-reader label
      Given a screen shows its controls
      When each control is read by the screen reader
      Then each announces a meaningful label describing what it does

    # Spec: scope §5.8 — eyes-free walkthrough
    Scenario: An eyes-free walkthrough completes under the screen reader
      Given the screen reader is active
      When a core task is performed without looking at the screen
      Then the task can be completed end to end by screen reader alone

  Rule: Nothing is time-limited or auto-dismissed

    # Spec: scope §5.10 — no time-limited interactions
    Scenario: No interaction imposes a time limit and nothing auto-dismisses
      Given the painter is partway through any interaction
      When the painter waits without acting
      Then nothing is dismissed or cancelled on a timer

  Rule: Accessibility is gated on every feature

    # Spec: scope §5; SI test gates — automated check
    Scenario: A feature that fails the automated accessibility check is not accepted
      Given a feature has failed part of the automated contrast, scaling, target-size and semantics check
      When the feature is reviewed for acceptance
      Then the feature is not accepted

    # Spec: SI test gates — manual walkthrough
    Scenario: A feature that fails the manual eyes-free walkthrough is not accepted
      Given a feature has failed the manual eyes-free screen-reader walkthrough
      When the feature is reviewed for acceptance
      Then the feature is not accepted

    # Spec: scope §5; SI WCAG 2.2 AA floor
    Scenario: WCAG 2.2 AA is the accepted floor
      Given a feature has passed its accessibility gates
      When its compliance level is recorded
      Then it meets at least WCAG 2.2 AA

  Rule: iOS parity is verified on device, not on compile

    # Spec: SI Cross-platform parity acceptance
    Scenario: The eyes-free walkthrough passes under VoiceOver as it does under TalkBack
      Given a feature passes the eyes-free walkthrough under TalkBack on Android
      When the same walkthrough is run under VoiceOver on iOS reference hardware
      Then it passes there as well before iOS parity is considered done
