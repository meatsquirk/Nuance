# Draft: awaiting owner approval (derived 2026-10-05 by /wireframe-behavior-specs)
# Phase: FUTURE (post-v1) — invisible crowd-refinement of the AI mappings, not a v1 feature (SI D8).
Feature: Crowd-refinement of the AI mappings
  The intended future path for improving the quality of the LLM-seeded paint
  mappings, crowdsourced without a server and invisible to the painter. The only
  thing that ever leaves a device is a tiny, anonymous mix-accuracy record; it
  travels by a trivial serverless exchange between reachable installs; and it
  refines the "Estimated" mappings only — it never reaches "Confirmed", which
  still requires the painter's own measured mix. The painter is never shown peers,
  devices, syncing or a network.

  Boundary: NOT a v1 feature, and strictly limited to improving the AI mappings.
  It attaches to the append-only, source-tagged provenance and clustering model v1
  already builds (bs-13). Photos, projects, samples and the CVD profile never leave
  the device (bs-12).
  Builds on: bs-13.
  Source: SI "Quiet crowd-refinement of the AI mappings"; scope §6.4, §6.6; D8, D9.

  Rule: Crowd-refinement is invisible to the painter

    # Spec: SI — invisible by design; one-time plain-language opt-in
    Scenario: The painter opts in once in plain terms and is never shown the mechanism
      Given the painter is offered to "help improve recipe accuracy by sharing anonymous mix results"
      When the painter opts in
      Then they are never shown peers, devices, syncing or a network

    # Spec: SI — no per-exchange action
    Scenario: No exchange ever asks the painter to do anything
      Given the painter has opted in
      When mix-accuracy records are exchanged in the background
      Then the painter is not prompted and sees only that recipes improve over time

  Rule: Only an anonymous mix-accuracy record ever leaves the device

    # Spec: SI — the record and nothing else
    Scenario: A shared record carries only the mapping evidence
      Given a mix-accuracy record is prepared to share
      When its contents are inspected
      Then it carries the paint combination, the declared palette, the measured resulting colour and the measurement tier

    # Spec: SI; bs-12 privacy — nothing personal leaves
    Scenario: No photo, project, sample, profile or identifier leaves the device
      Given a mix-accuracy record is prepared to share
      When its contents are inspected
      Then it contains no photograph, project, saved sample, CVD profile, identifier or location

    # Spec: scope §6.6 — declared palette required
    Scenario: A record without a declared palette is not shared
      Given a candidate record has no declared palette
      When records to share are selected
      Then that record is not shared, because it is not interpretable

  Rule: Records travel by a trivial serverless exchange

    # Spec: SI — serverless gossip, content-hash keyed
    Scenario: Two reachable installs exchange only the records each is missing
      Given two installs are reachable on the same local network
      When they exchange mix-accuracy records
      Then each offers only the records the other is missing, keyed by content hash
      And duplicates and already-seen records are dropped

    # Spec: SI — nothing waited on when no peer is reachable
    Scenario: With no peer reachable, nothing happens and nothing is waited on
      Given no other install is reachable
      When the app runs
      Then no exchange occurs and no core function waits on one

  Rule: Crowd evidence refines Estimated mappings, never Confirms them

    # Spec: SI — refine the Estimated starting point
    Scenario: Clustered crowd records improve an Estimated mapping's value
      Given several peer-contributed records exist for one Estimated mapping
      When the local value is recomputed
      Then it is taken as a robust central estimate of the clustered records with outliers discarded

    # Spec: SI — crowd evidence never promotes to Confirmed
    Scenario: Crowd evidence never promotes a value to Confirmed on the painter's screen
      Given an Estimated mapping has been refined by peer-contributed records
      When its user-facing provenance is shown
      Then it remains "Estimated — not yet verified" until the painter confirms it with their own mix

  Rule: Evidence merges because it is append-only and source-tagged

    # Spec: D9 — append-only, source-tagged merge
    Scenario: Records from many devices merge without overwriting
      Given records for one mapping arrive from several devices
      When they are merged into the local copy
      Then each is appended and tagged as peer-contributed, and none overwrites another

  Rule: Quality controls keep the shared mappings honest

    # Spec: scope §6.6 — outlier rejection
    Scenario: Statistical outliers are discarded from the local estimate
      Given peer-contributed records for one mapping include a statistical outlier
      When the local estimate is computed
      Then the outlier is discarded rather than averaged in

    # Spec: scope §6.6 — rate limiting bounds any one source
    Scenario: The volume one source can contribute is bounded
      Given a stream of records arrives from a single source
      When the records are ingested
      Then the amount accepted from that source is rate-limited
