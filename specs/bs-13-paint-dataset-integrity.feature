# Approved 2026-10-14 by Matt Quirk (G-1) — derived 2026-10-05 by /wireframe-behavior-specs
# Mixed build-time and runtime integrity rules; some are pipeline acceptance criteria, not app UX.
Feature: Paint dataset integrity and provenance
  The rules that keep the shipped paint data honest: the dataset stores per-paint
  optical data rather than RGB-to-recipe answers; the LLM proposes which paints and
  the solver produces the ratios, so no shipped number is a hallucination; the seed
  is validated before it ships; provenance is enforced in the schema and stored
  append-only; and an LLM-seeded value is promoted only by physical evidence, never
  by opinion. The seed stays deliberately narrow.

  Boundary: data-integrity rules spanning the build-time seeding pipeline and the
  runtime provenance model. The user-facing provenance display is bs-01/bs-06; the
  self-confirmation path is bs-05.
  Source: scope §6.1–6.3, §6.5, §6.7; SI Paint database and data pipeline; D6, D7, D9.

  Rule: The dataset stores per-paint optical data, not RGB-to-recipe answers

    # Spec: SI Paint database — stores optical data; engine solves
    Scenario: Recipes are solved from stored optical data, not looked up as answers
      Given the dataset stores per-paint optical data
      When a recipe is produced for a target
      Then the recipe is solved from the optical data, not retrieved as a stored answer

  Rule: The LLM proposes paint combinations; the solver produces ratios

    # Spec: scope §6.1; D7 — candidate generation from the LLM
    Scenario: Candidate paint combinations come from the LLM
      Given a target colour and a palette
      When candidate combinations are generated
      Then the candidate sets of paints come from the LLM's qualitative knowledge

    # Spec: scope §6.1; D7 — ratios from the solver only
    Scenario: Every shipped ratio comes from the solver, never from the LLM
      Given a candidate combination of paints
      When the parts for the mix are produced
      Then the ratios come from the physics solver and never from the LLM

    # Spec: scope §6.1 — trust the LLM for metadata, not for measured values
    Scenario: LLM metadata is accepted while LLM-claimed measured values are rejected
      Given the LLM supplies pigment index, opacity and lightfastness for a paint
      And the LLM also supplies claimed spectral curves and ratios
      When the data is ingested
      Then the metadata is accepted
      And the claimed spectral curves and ratios are rejected in favour of measured data and the solver

  Rule: The seed is validated before it ships

    # Spec: scope §6.3; SI Phase 0.5 gate — validation harness
    Scenario: A held-out recipe set is mixed and measured before shipping
      Given a generated seed dataset
      When between 50 and 100 held-out recipes are mixed and measured
      Then their delta-E00 distribution against prediction is recorded

    # Spec: SI Phase 0.5 gate — ship only on evidence
    Scenario: The seed ships only if it clears the threshold and beats the LLM alone
      Given the validation harness has recorded the delta-E00 distribution
      When the ship decision is made
      Then the seed ships only if it clears the usable threshold and the hybrid beats the LLM alone

  Rule: Provenance is enforced in the schema, not left to policy

    # Spec: scope §6.5; D9 — provenance a first-class field
    Scenario Outline: Every value carries an enforced provenance tier
      Given a value enters the dataset from <origin>
      When the value is stored
      Then it carries the provenance "<tier>"

      Examples:
        | origin                                      | tier                        |
        | a spectrophotometer measurement             | Measured                    |
        | the physics solver over measured pigment data | Calculated                |
        | an unconfirmed LLM seed                     | Estimated — not yet verified |
        | the user's own measured mix                 | Confirmed — you measured this |

    # Spec: D9 — evidence stored append-only
    Scenario: Evidence behind a value is stored append-only
      Given a value already carries evidence of its origin
      When new evidence for that value is recorded
      Then the new evidence is appended and the earlier evidence is retained

  Rule: An LLM-seeded value never graduates except on physical evidence

    # Spec: scope §6.5; SI refinement rule
    Scenario: An Estimated value is promoted only by a photographed or measured swatch
      Given a value is "Estimated — not yet verified"
      When the painter records a photographed or instrument-measured swatch for it
      Then the value may be promoted to "Confirmed — you measured this"

    # Spec: scope §6.5; SI — never on opinion
    Scenario: Opinions never promote a value
      Given a value is "Estimated — not yet verified"
      When only votes or opinions are offered for it
      Then the value is not promoted

  Rule: The shipped seed stays narrow

    # Spec: scope §6.7; SI start narrow
    Scenario: The shipped seed covers one brand, one medium and about fifteen paints
      Given the seed is being prepared for v1
      When its scope is set
      Then it covers one brand, one medium and about fifteen paints
