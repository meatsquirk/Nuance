# Module EXCHANGE — serverless gossip

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/exchange/peer_transport.dart`, `gossip_exchange.dart`, `seen_set.dart`, `exchange_scheduler.dart`, `exchange_outcome_endpoint.dart`; the real transport impl `lib/sharing/exchange/local_network_transport.dart` (EXCHANGE-4).
**Depends on:** CORE, RECORD · **Blocks:** CORE-4 (background exchange), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ⬜ Todo | | |
| 2 | behavior | AC-6 | ⬜ Todo | | |
| 3 | behavior | AC-7 | ⬜ Todo | | |
| 4 | behavior (*enabler*) | — | ⬜ Todo | | |

## Interface reconciliation

- `PeerTransport` is the single off-device actor and the one bs-12 exception (D-4, G-4). The interface: `Future<List<Peer>> discover()`, `Future<void> offer(Peer, List<MixAccuracyRecord>)`, `Stream/Future<List<MixAccuracyRecord>> receive(Peer)`. The acceptance suite supplies an in-process loopback fake; EXCHANGE-4 supplies the real mDNS/Bonjour + socket impl.
- `GossipExchange` is transport-agnostic: offered = `mine − theirs` keyed by `contentHash`; `SeenSet` drops already-seen; received records are handed to `EvidenceMerge` (MERGE). Dedup lives here; append lives in MERGE (D-7).
- The scheduler is **fire-and-forget**: core flows never await it; no-peer and transport failure are silent (D-5).
- **bs-12 guard reconciliation (G-4):** amend bs-12's network-block/no-off-device-path guards to allow only this consented, record-only path; add a bs-14 boundary guard asserting only a `MixAccuracyRecord` serialization crosses `PeerTransport`.

## Open gates

- **G-2** blocks all EXCHANGE behavior.
- **G-4** (sanctioned off-device path / bs-12 reconciliation) blocks **EXCHANGE-2** and **EXCHANGE-4**.

## Phase 1 — Shell: transport interface, gossip skeleton, scheduler, read endpoint

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-2, RECORD-1 · **Blocks:** EXCHANGE-2, EXCHANGE-3
- **Files:** `peer_transport.dart`, `gossip_exchange.dart` (skeleton), `seen_set.dart`, `exchange_scheduler.dart`, `exchange_outcome_endpoint.dart`.
- **Tasks:**
  1. `PeerTransport` interface; `GossipExchange` skeleton (no diff logic yet); `SeenSet` keyed by content hash; `ExchangeScheduler` wired fire-and-forget so no core flow awaits it.
  2. `ExchangeOutcomeEndpoint` exposing `offered`, `received`, `dedupDrops`, `exchanges` (count) and `waitedOnExchange` (bool).
  3. No behavior: skeleton exchanges nothing; existing suite green; no real network (fake only reachable through tests).
- **Exit criteria:** unit gate (100% touched); existing suite green; scheduler demonstrably non-blocking in a smoke test.

## Phase 2 — AC-6: exchange only the records each is missing

- **Kind:** behavior
- **Target AC:** AC-6 (full)
- **Depends on:** EXCHANGE-1, RECORD-3, G-2, **G-4** · **Blocks:** EXCHANGE-3
- **Files:** `gossip_exchange.dart`, `seen_set.dart`.
- **Tasks:**
  1. Compute offered = `mine − theirs` by content hash; drop duplicates and already-seen records (SeenSet); each side offers only what the other lacks.
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-6; `TestAC06_ExchangeOnlyMissing` passing (and all earlier ACs).

## Phase 3 — AC-7: no peer reachable ⇒ no exchange, no wait

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** EXCHANGE-1, G-2 · **Blocks:** CORE-4
- **Files:** `exchange_scheduler.dart`, `gossip_exchange.dart`.
- **Tasks:**
  1. When `discover()` returns no peer, no exchange occurs; the scheduler is a silent no-op; a core flow invoked concurrently completes without ever awaiting the exchange (`waitedOnExchange==false`, `exchanges==0`).
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-7; `TestAC07_NoPeerNoWait` passing (and all earlier ACs).

## Phase 4 — *Enabler*: real local-network transport (no AC)

- **Kind:** behavior (enabler — no AC of its own)
- **Target AC:** — (makes the feature actually work on-device; verified by the sign-off manual walkthrough, not an AC — mirrors bs-12 AC-5)
- **Depends on:** EXCHANGE-2, **G-4** · **Blocks:** SIGNOFF-1
- **Files:** `lib/sharing/exchange/local_network_transport.dart`.
- **Tasks:**
  1. Real `PeerTransport` over local-network discovery (mDNS/Bonjour) + a direct socket link; best-effort, no server/account/addressing.
  2. Honour the bs-12 boundary guard: only `MixAccuracyRecord` serializations cross; nothing else.
- **Exit criteria:** unit + coverage on the parts that are unit-testable (serialization/framing); the discovery/socket path verified by the sign-off on-device walkthrough and recorded as a named manual gap (D-3).
- **Acceptance gate:** none (no AC). Suite stays green; coverage gate on touched files; any untestable platform path listed as a justified exclusion with the manual walkthrough step.

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
