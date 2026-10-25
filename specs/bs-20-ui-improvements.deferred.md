# bs-20 UI improvements — deferred / dropped wireframe elements

Elements present in the wireframe (`Paint Color Assistant.dc.html`) that the owner has decided
**not** to build in bs-20. Recorded here so they are not silently reintroduced by a later derivation
or "make it match the wireframe" pass. Decided 2026-10-24 by owner Matt Quirk.

| Wireframe element | Where in mock | Decision | Rationale |
|---|---|---|---|
| **Two switchable readout layouts** — "A · Value-first" vs "B · Spec sheet", chosen via the Tweaks `readoutLayout` enum | `.dc.html:701` (props), `.dc.html:229-281` (take A), `.dc.html:283-301` (take B) | **Dropped.** Ship a single merged readout layout (value-first hero + all-spaces list), not a switch. | The two "takes" were prototype variations for the owner to choose between, never both meant to ship. bs-20 merges the useful parts of each into one layout; a runtime layout switch is noise. |

## Not dropped — recorded to prevent confusion

These were raised during the walkthrough and **kept** (they are not deferred):

- **Provenance chips / confidence badge** (`.dc.html:224-227`) — kept; real confidence information.
- **Temperature line** (`.dc.html:257-260`) — kept.
- **Capture "just captured" banner incl. Acknowledge/OK** (`.dc.html:207-213`) — kept, always visible.
- **Swatch "APPROX." caption** (`.dc.html:276-279`, bs-17 AC-15) — kept, always visible (judged a
  universal honesty cue, not CVD-specific). *Owner to confirm; flip to accessibility-gated if desired.*
