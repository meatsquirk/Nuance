# Approved 2026-10-10 by Matt Quirk (derived 2026-10-05 by /wireframe-behavior-specs)
Feature: Palette and projects
  The painter declares the paints they physically own as one or more named
  palettes, each paint carrying its provenance, and organises saved colours into
  named projects with notes and a source photo. Recipes are solved only against
  the selected palette; a project flags confusion pairs among its samples; and a
  project can be exported as a printable studio sheet.

  Boundary: managing paints and projects on the Palette screen. Solving recipes is
  bs-04; the CVD self-assessment reached from here is bs-07. The painter cannot add
  free-hand paint values in v1 — paints come from the reviewed shipped dataset.
  Builds on: bs-01, bs-04.
  Wireframe: Paint Color Assistant.dc.html, Palette screen (region S1.R1, elements
  E30-E34).

  Rule: The painter keeps paints and projects in two views

    # UX: Paint Color Assistant.dc.html › S1.R1.E31 Paints or projects selector [button]
    Scenario: The painter switches between the My paints and Projects views
      Given the Palette screen is showing My paints
      When the painter switches to Projects
      Then the saved projects are shown instead of the paints

  Rule: Every paint shows its provenance, never colour alone

    # UX: Paint Color Assistant.dc.html › S1.R1 Palette screen — paint list [body]
    Scenario: Each paint is listed with its identity and provenance badge
      Given the My paints palette contains "Titanium White" by Winsor & Newton, Artists' Oil, pigment PW6, read with a spectrophotometer
      When the My paints list is shown
      Then "Titanium White" is listed with its brand, line, medium and pigment index
      And it carries the provenance "Measured", not colour alone

    # UX: Paint Color Assistant.dc.html › S1.R1 Palette screen — provenance legend [body]
    Scenario: The provenance legend explains the four confidence tiers
      Given the My paints list is shown
      When the provenance legend is shown
      Then it explains "Measured", "Calculated", "Estimated — not yet verified" and "Confirmed — you measured this"

  Rule: The painter builds a palette from the reviewed dataset

    # UX: Paint Color Assistant.dc.html › S1.R1.E32 Add paint [button]
    Scenario: The painter adds a paint by choosing from the shipped dataset
      Given the painter is adding a paint to the My paints palette
      When the painter chooses "Ultramarine Blue" from the reviewed dataset
      Then "Ultramarine Blue" is added to the palette with its dataset provenance preserved

  Rule: The painter keeps more than one named palette, and the selected one drives recipes

    # UX: Paint Color Assistant.dc.html › S1.R1 Palette screen — palette selection [body]
    Scenario: Selecting a palette makes recipes solve against it
      Given the painter has palettes "My paints" and "Travel set"
      When the painter selects "Travel set" as the active palette
      Then recipe search solves only against the paints in "Travel set"

  Rule: Projects collect saved samples, recipes, notes and a source photo

    # UX: Paint Color Assistant.dc.html › S1.R1 Palette screen — projects list [body]
    Scenario: The projects list shows each project's size, counts and last edit
      Given the painter has a project "Harbor at Dusk"
      When the Projects list is shown
      Then "Harbor at Dusk" shows its 24×30 in size, 6 samples, 3 recipes and that it was edited today

    # UX: Paint Color Assistant.dc.html › S1.R1.E33 Open project [button]
    Scenario: Opening a project shows its notes and source photo
      Given the project "Harbor at Dusk" has a note and a source photo
      When the painter opens "Harbor at Dusk"
      Then the project's note is shown
      And its source photo is shown

    # UX: Paint Color Assistant.dc.html › S1.R1 Palette screen — project note [body]
    Scenario: A note kept with a project is retained when it is reopened
      Given the painter has saved the note "Keep the hull and wall values 2 steps apart." on "Harbor at Dusk"
      When the painter reopens "Harbor at Dusk"
      Then the note "Keep the hull and wall values 2 steps apart." is shown

  Rule: A project flags confusion pairs among its saved samples

    # UX: Paint Color Assistant.dc.html › S1.R1 Palette screen — confusion note [body]
    Scenario: A confusable pair of saved samples is flagged within a project
      Given the project "Harbor at Dusk" holds samples "Mid Raw Umber" and "Ultramarine Shadow" that fall on the painter's confusion line
      When the painter opens "Harbor at Dusk"
      Then the pair is flagged as a confusion pair to check by value

  Rule: A project can be exported as a printable sheet

    # UX: Paint Color Assistant.dc.html › S1.R1.E34 Export to device [button]
    Scenario: The painter exports a project as a PDF studio sheet
      Given the painter has opened the project "Harbor at Dusk"
      When the painter exports the project to the device
      Then a PDF studio sheet of the project's samples and recipes is produced

  Rule: The painter reaches the CVD self-assessment from the palette

    # UX: Paint Color Assistant.dc.html › S1.R1.E30 Vision profile card [button]
    Scenario: The vision-profile card shows the current estimate and opens the self-assessment
      Given the painter's vision profile is estimated as deutan-type, moderate
      When the painter chooses to retake the self-assessment from the vision-profile card
      Then the current estimate is shown on the card
      And the CVD self-assessment is opened
