# bs-14 Peer-to-peer evidence sharing — Sign-off packet, round 1

**Feature:** Crowd-refinement of the AI mappings (peer-to-peer evidence sharing)
**Spec:** [bs-14-peer-to-peer-evidence-sharing.feature](../bs-14-peer-to-peer-evidence-sharing.feature) — approved 2026-10-14 (G-1)
**At code:** `b47b667` (worktree `Nuance-bs14`, branch `feat/bs-14-peer-to-peer-evidence-sharing`)
**Phase:** SIGNOFF-1 · **Verified:** 2026-10-16
**Decision:** ⏸ Awaiting — record with `/feature-next-phase --signoff bs14 approved | changes "<items>"`

> **This is a FUTURE / post-v1 feature** (SI D8): an invisible, serverless peer-to-peer layer that refines only the *Estimated* AI mappings. All 12 ACs are coded, tested through production wiring, and graded A. **Read "The one open decision (D-3)" below before deciding** — the on-device data-origination wiring is deliberately deferred and affects what the on-device walkthrough can show today.

## Verdict at a glance

| Check | Result |
|---|---|
| ACs built & green | **12 / 12** (every scenario) |
| Grade grid (fresh independent re-grade) | **16 A / 0 B** ([signoff/round-1-grade-grid.md](round-1-grade-grid.md)) |
| Unit suite | **1597 / 0** |
| Unit coverage on touched files | **100% on 23 / 24**; 24th = `local_network_io.dart` — justified exclusion (D-3) |
| bs-14 acceptance suite (default) | **24 / 0 / 0** |
| bs-14 acceptance suite (run-pending) | **24 / 0 / 0** (identical — pending list empty) |
| Cross-feature regression — host (`flutter-tester`) | bs12 nfr **33** + bs13 dataset **19** = **52 / 0** |
| Cross-feature regression — sim (iPhone 17) | harness **222** + conformance **1597** = **1819 / 0** |
| Open gates | **none** (G-1, G-2, G-3, G-4 all resolved) |
| Non-A grades accepted | **none** |

## Per-AC result

Every AC test runs on the real app via `buildApp(AppDependencies(...))`; the only infrastructure fake is an
in-process loopback `PeerTransport`. Tests live in `integration_test/bs14/`. All graded **A**.

| AC | Scenario (Rule) | Test | Result |
|---|---|---|---|
| AC-1 | Opts in once in plain terms, never shown the mechanism *(invisible)* | `TestAC01_OptInOnceNeverShown` | ✅ A |
| AC-2 | No exchange ever asks the painter to do anything *(invisible)* | `TestAC02_NoPerExchangeAction` | ✅ A |
| AC-3 | A shared record carries only the mapping evidence *(record-only)* | `TestAC03_RecordCarriesOnlyEvidence` | ✅ A |
| AC-4 | No photo/project/sample/profile/identifier/location leaves *(record-only)* | `TestAC04_NothingPersonalLeaves` | ✅ A |
| AC-5 | A record without a declared palette is not shared *(record-only)* | `TestAC05_NoPaletteNotShared` | ✅ A |
| AC-6 | Two reachable installs exchange only what each is missing *(serverless exchange)* | `TestAC06_ExchangeOnlyMissing` | ✅ A |
| AC-7 | No peer ⇒ nothing happens, nothing waited on *(serverless exchange)* | `TestAC07_NoPeerNoWait` | ✅ A |
| AC-8 | Clustered crowd records improve an Estimated value *(refine, never Confirm)* | `TestAC08_ClusteredRefine` | ✅ A |
| AC-9 | Crowd evidence never promotes to Confirmed on the painter's screen *(refine, never Confirm)* | `TestAC09_NeverPromotes` | ✅ A |
| AC-10 | Records from many devices merge without overwriting *(append-only, source-tagged)* | `TestAC10_AppendOnlyMerge` | ✅ A |
| AC-11 | Statistical outliers discarded from the local estimate *(quality controls)* | `TestAC11_OutlierDiscarded` | ✅ A |
| AC-12 | The volume one source can contribute is bounded *(quality controls)* | `TestAC12_RateLimited` | ✅ A |

## Grade grid & augmentations

Fresh, independent re-grade of the whole suite at sign-off (a subagent that did not write the tests, given
the previous grid, grading against rules G1–G6): **16 A / 0 B**, no downgrades. The previous "B pending
MERGE-4" on AC-9 is now **A** — the grader confirmed `ingest` stamps `EvidenceKind.peerContributed` and
discards a record's declared tier, and `tierFor` has no `peerContributed` branch, so even an
instrument-tier *peer* record cannot promote. Grid: [signoff/round-1-grade-grid.md](round-1-grade-grid.md).

Augmentations made during the build (all closed):
- **AC-1 (CORE-3):** pre-opt-in scan of the populated `userFacingSharingSurfaces` inventory (live-binding, discriminates against the always-empty pre-CORE-3 code).
- **AC-9 (MERGE-4):** the 5-peer "refined by peer records" Given realized; a high-tier peer record still stays Estimated.

## Gates (all resolved)

| Gate | Decision | Resolved |
|---|---|---|
| G-1 | Spec approved | 2026-10-14 — Matt Quirk |
| G-2 | Acceptance tests approved (11 A + AC-9 B-pending-MERGE-4, since closed to A) | 2026-10-16 — Matt Quirk |
| G-3 | bs-13 signed off & merged to main (`c00422f`); PROV/SEED surface present | 2026-10-15 — bs-13 sign-off |
| G-4 | Single sanctioned off-device path approved: local-network-only `PeerTransport` (mDNS + socket; no server/account/addressing; record-only; consented). bs-12 guards amended to permit exactly this one path + a bs-14 boundary guard. | 2026-10-16 — Matt Quirk |

## The one open decision (D-3): on-device transport + data origination

The acceptance suite proves the gossip, merge, refine and quality **logic** over a fake loopback transport
with real records. Two things are, by plan design (D-3, mirroring bs-12's pure-manual AC-5), **not** covered
by an automated AC and are the substance of this decision:

1. **The real transport's discovery/socket path** — `lib/sharing/exchange/local_network_io.dart` (the single
   justified coverage exclusion; the serialization/framing half, `record_wire.dart`, is fully unit-tested and
   a **boundary guard** asserts only a `MixAccuracyRecord` serialization crosses). The real
   `LocalNetworkTransport` is the shipped app's default (`AppDependencies.peerTransport`). Its mDNS/Bonjour +
   socket behaviour is verified only by the **on-device walkthrough** below.

2. **Own-record origination is not yet wired into the live round.** The live background round currently
   offers `const <MixAccuracyRecord>[]` (`build_app.dart:1055`) — on-device the app would discover peers and
   *receive*, but **offer none of its own records** until the painter's shareable confirmed mixes
   (`RecordBuilder` share-set) are fed into the trigger. This is explicitly deferred in code and plan as "the
   last on-device wiring step." **Consequence:** as wired today, the on-device walkthrough step "a mix
   recorded on install A appears merged on install B" cannot be demonstrated from A's side — A offers nothing.

**This is product-code behaviour (a new source of records plumbed into `_SharingRoot`, with its own unit
coverage and an acceptance augmentation); it is out of scope for a sign-off phase, which makes no product
code changes.** The reviewer's call:
- **Approve as-is** — accept bs-14 as the complete, tested *logic* layer plus a receive-capable real
  transport, with own-record origination formally deferred (appropriate for a post-v1, invisible feature); or
- **Request changes** — a short enabler phase wires the share-set into the live trigger (+ unit coverage + an
  AC-6/AC-2 augmentation over a booted app) before a fresh SIGNOFF-2 and the full on-device walkthrough.

## Manual walkthrough — how a reviewer sees each Rule working

Logic Rules (1–6 below) are demonstrated by the acceptance tests; run them with
`cd Nuance-bs14 && flutter test integration_test/bs14/<file>.dart -d flutter-tester`:

- **Invisible to the painter** (AC-1, AC-2 — `consent_and_record_test.dart`): the opt-in offer reads
  *"help improve recipe accuracy by sharing anonymous mix results"*; after opt-in and a settled background
  round, no prompt/spoken/haptic surface fires and the only user-facing item is the mechanism-free
  *"recipes improve over time"* — no peers/devices/sync/network wording anywhere.
- **Only an anonymous record leaves** (AC-3, AC-4, AC-5 — `consent_and_record_test.dart`): a prepared record
  carries exactly {paint combination, declared palette, measured colour, tier} and nothing else; no
  photo/project/sample/profile/identifier/location; a candidate with no declared palette is excluded.
- **Serverless exchange** (AC-6, AC-7 — `exchange_and_merge_test.dart`): two loopback installs each offer
  only what the other lacks (keyed by content hash), dedup already-seen; with no peer, zero exchanges and
  `waitedOnExchange == false`.
- **Refine Estimated, never Confirm** (AC-8, AC-9 — `refine_test.dart`): 7 clustered peer records + 1 outlier
  move an Estimated value to the robust centroid (not the mean); provenance stays *"Estimated — not yet
  verified"* even against an instrument-tier peer record.
- **Append-only, source-tagged merge** (AC-10 — `exchange_and_merge_test.dart`): 3 records from 3 devices all
  append, each tagged `peerContributed`, none overwrites another.
- **Quality controls** (AC-11, AC-12 — `refine_test.dart`): a far outlier is discarded from the estimate; a
  100-record flood from one source is capped (honest sources unaffected).

**On-device walkthrough (D-3 — the manual gap):** build the app on two devices on one LAN, opt both in. The
real `LocalNetworkTransport` discovers the peer (mDNS/Bonjour) and opens a direct socket; confirm with a
packet capture / the boundary guard that *only* `MixAccuracyRecord` serializations cross and nothing
personal. **Note the origination gap above:** demonstrating a record *recorded on A appearing on B* requires
the own-record wiring (decision item 2); until then the walkthrough can show discovery, the socket link, the
record-only boundary, and receive-side merge from a seeded peer, but not A-originated send.

## Known gaps & deferred items

- **D-3 own-record origination** — see the open decision above. The live trigger offers an empty own set.
- **`local_network_io.dart` coverage exclusion** — the platform mDNS/socket orchestration (D-3); verified
  manually, not by unit coverage. The testable framing/serialization (`record_wire.dart`) is at 100%.

## Open flakes (carried; none block)

| Test | Symptom | Workaround |
|---|---|---|
| coverage_gate | const-folded ctor line intermittently read as uncovered | re-run once; green ⇒ ignore |
| integration suite (no `-d`) | `flutter test integration_test/…` with no device runs 0 tests, exits 0 (false green) | always pass `-d flutter-tester` / a sim id |
| host pair combined | bs12 nfr + bs13 dataset fail to **load** combined in one isolate | run each host file one per `flutter test` |

## Token usage & cost per AC

Full report: [signoff/cost-per-ac-round-1.md](cost-per-ac-round-1.md).

- **Feature total:** 187,581,598 tokens over 26 sessions — input 2,850 · cache write 4,981,974 · cache read 181,285,570 · output 1,311,204.
- **Cost (API list rates, 2026-09-25):** **$168.05** — cache write $44.61, cache read $90.64, output $32.78, input $0.01. All 26 sessions priced from their transcripts.
- **Time:** first start 2026-10-14 17:46 EDT → last end 2026-10-16 15:21 EDT; **Σ active 7h 35m** (Σ wall 7h 56m).
- **Per-stage subtotals:** scaffold $5.41 · shells $22.15 · acceptance-tests $27.55 · behavior (12 ACs) ~$82.65 · enabler (EXCHANGE-4) $13.55 · sign-off $10.41 · activities (plan/gates) $6.33.
- **Cost per AC (fully loaded, incl. an even 1/12 share of shared work):** AC-1 $21.95, AC-2 $19.32, AC-3 $12.38, AC-4 $12.38, AC-5 $12.18, AC-6 $15.32, AC-7 $12.50, AC-8 $10.41, AC-9 $14.05, AC-10 $12.74, AC-11 $10.41, AC-12 $14.40.

(Lines-of-code attribution is unavailable — `feature_loc.py` ships with the `behavior-test-check` tool, which is not installed here; token/cost attribution is unaffected.)

## Summary page

Scorecard: **https://claude.ai/artifact/WweicVCzsgmUGSYJEPZAMj**
