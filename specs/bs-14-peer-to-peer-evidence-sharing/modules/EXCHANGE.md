# Module EXCHANGE — serverless gossip

**Status:** In progress — EXCHANGE-1 ✅, EXCHANGE-3 (AC-7) ✅ (graded A); **G-4 approved 2026-10-16 — EXCHANGE-2 (AC-6) now startable**, then EXCHANGE-4 (enabler)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/exchange/peer_transport.dart`, `gossip_exchange.dart`, `seen_set.dart`, `exchange_scheduler.dart`, `exchange_outcome_endpoint.dart`; the real transport impl `lib/sharing/exchange/local_network_transport.dart` (EXCHANGE-4).
**Depends on:** CORE, RECORD · **Blocks:** CORE-4 (background exchange), SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | shell | — | ✅ Done | 4,252,500 | 11m 52s |
| 2 | behavior | AC-6 | ⬜ Todo | | |
| 3 | behavior | AC-7 | ✅ Done | 5,300,757 | 14m 22s |
| 4 | behavior (*enabler*) | — | ⬜ Todo | | |

## Interface reconciliation

- `PeerTransport` is the single off-device actor and the one bs-12 exception (D-4, G-4). The interface: `Future<List<Peer>> discover()`, `Future<void> offer(Peer, List<MixAccuracyRecord>)`, `Stream/Future<List<MixAccuracyRecord>> receive(Peer)`. The acceptance suite supplies an in-process loopback fake; EXCHANGE-4 supplies the real mDNS/Bonjour + socket impl.
- `GossipExchange` is transport-agnostic: offered = `mine − theirs` keyed by `contentHash`; `SeenSet` drops already-seen; received records are handed to `EvidenceMerge` (MERGE). Dedup lives here; append lives in MERGE (D-7).
- The scheduler is **fire-and-forget**: core flows never await it; no-peer and transport failure are silent (D-5).
- **bs-12 guard reconciliation (G-4):** amend bs-12's network-block/no-off-device-path guards to allow only this consented, record-only path; add a bs-14 boundary guard asserting only a `MixAccuracyRecord` serialization crosses `PeerTransport`.

## Open gates

- **G-2** ✅ resolved 2026-10-16 (acceptance tests approved) — no longer blocks EXCHANGE behavior.
- **G-4** ✅ **resolved 2026-10-16 12:59 EDT (Matt Quirk): Approved.** The sanctioned off-device path is the local-network-only `PeerTransport` (mDNS/Bonjour + direct socket; no server/account/stored addressing; only `MixAccuracyRecord` serializations cross; consented, record-only). bs-12's network-block / no-off-device-path guards are to be amended to permit exactly this one path, with a bs-14 boundary guard asserting only a `MixAccuracyRecord` serialization crosses `PeerTransport` (implemented in EXCHANGE-2/EXCHANGE-4; on-device path verified by the sign-off walkthrough, D-3). EXCHANGE-2 and EXCHANGE-4 unblocked.

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

### Result — after EXCHANGE-1

Landed the EXCHANGE shell under `lib/sharing/exchange/` (5 files, no behaviour, nothing wired into the app assembly — same precedent as RECORD-1):

- `peer_transport.dart` — `Peer` (opaque per-session id, value-equal) + `PeerTransport` interface (`discover`/`offer`/`receive`); the single off-device actor and the one bs-12 exception (D-4, G-4). Only `MixAccuracyRecord` serializations cross it.
- `seen_set.dart` — `SeenSet` keyed by `MixAccuracyRecord.contentHash`; `register` returns false on an already-seen hash (the dedup drop, D-7), `contains`, `length`.
- `gossip_exchange.dart` — `GossipExchange{transport, seenSet}` + `ExchangeReport{offered, received, dedupDrops, exchangesConducted}` (`.empty`). Skeleton `exchangeOnce(mine)` **awaits `discover()` (the async seam EXCHANGE-2 builds on) but exchanges nothing** → always `ExchangeReport.empty`.
- `exchange_scheduler.dart` — `ExchangeScheduler` fire-and-forget: `trigger(mine)` launches `exchangeOnce` **unawaited**, folds the report into `outcome` on completion, swallows any failure silently (D-5); `settled` future for tests; returns synchronously so no core flow ever waits. `ExchangeOutcome{offered, received, dedupDrops, exchanges, waitedOnExchange}` with `fold`/`withWaited`/value `==`.
- `exchange_outcome_endpoint.dart` — `ExchangeOutcomeEndpoint` InheritedWidget (mirrors `RecordInspectEndpoint`): `endpointKey`, getters `offered`/`received`/`dedupDrops`/`exchanges`/`waitedOnExchange`, `of`/`maybeOf`. The AC-2/AC-6/AC-7 observation seam; zero/false in the shell.

Verification: `flutter analyze` clean; unit **1488/0** (+24 new exchange tests); coverage **100% on all 14 touched lib files** (`dart run tool/coverage_gate.dart c00422f`). Non-blocking proven by a gated-transport smoke test (`trigger` returns, `waitedOnExchange==false`, round still pending). No acceptance/grade gate (shell). Fix passes: 0/3. Tokens 4,252,500 · Time 11m 52s.

### Checkpoint / Handoff — after EXCHANGE-1

- **Frozen interfaces (consumed by EXCHANGE-2/3/4, ITEST, CORE-4):**
  - `PeerTransport` — `Future<List<Peer>> discover()`, `Future<void> offer(Peer, List<MixAccuracyRecord>)`, `Future<List<MixAccuracyRecord>> receive(Peer)`; `Peer(String id)` value type.
  - `SeenSet` — `bool register(MixAccuracyRecord)` (false ⇒ dedup drop), `bool contains(...)`, `int length`.
  - `GossipExchange({required PeerTransport transport, required SeenSet seenSet})` — `Future<ExchangeReport> exchangeOnce(Iterable<MixAccuracyRecord> mine)`.
  - `ExchangeReport({offered, received, dedupDrops, exchangesConducted})`, `.empty`.
  - `ExchangeScheduler(GossipExchange)` — `void trigger(Iterable<MixAccuracyRecord>)`, `ExchangeOutcome get outcome`, `Future<void>? get settled`.
  - `ExchangeOutcome({offered, received, dedupDrops, exchanges, waitedOnExchange})` — `fold(ExchangeReport)`, `withWaited(bool)`, value `==`; `.empty`.
  - `ExchangeOutcomeEndpoint` — `endpointKey`, `outcome`, getters, `of`/`maybeOf`.
- **Wiring note:** nothing in `lib/sharing/exchange/` is yet a `SharingDependencies` field or mounted in `build_app.dart` (behaviour-neutral shell). CORE-4 (AC-2, background exchange) adds the scheduler to `SharingDependencies` + mounts `ExchangeOutcomeEndpoint` when it wires the live exchange; the ITEST harness mounts the endpoint directly over a loopback-fake transport.
- **Verification commands:** flutter at `~/development/flutter/bin`. Unit: `flutter test`. Coverage: `flutter test --coverage` then `dart run tool/coverage_gate.dart c00422f` (full-suite run). Construct value classes non-const in a test or the const-ctor line reads 0.
- **Next:** EXCHANGE-2 (AC-6, `mine − theirs` diff + dedup) — blocked on **G-2 + G-4**. EXCHANGE-3 (AC-7, no-peer no-wait) — blocked on **G-2**. EXCHANGE-4 (enabler, real mDNS/socket) — blocked on **G-4**. All EXCHANGE behaviour waits on the ITEST test review (G-2); EXCHANGE-2/4 also wait on G-4.

### Result — after EXCHANGE-3

AC-7 ("with no peer reachable, nothing happens and nothing is waited on") coded
and un-pended. Touched one lib file, `gossip_exchange.dart`:

- `exchangeOnce` now discovers peers and branches: **no peer reachable ⇒
  `ExchangeReport.empty`** (no exchange conducted, nothing offered) — the AC-7
  no-op the scheduler folds, so a core flow that triggered the round is never
  blocked and the outcome stays at zero; **≥1 peer ⇒
  `ExchangeReport(exchangesConducted: peers.length)`** so a real exchange is
  conducted per reachable peer. The `mine − theirs` offer/receive diff + dedup
  content stays with EXCHANGE-2 (AC-6). `exchange_scheduler.dart` needed no
  change — EXCHANGE-1's fire-and-forget `trigger` already folds the empty report
  and keeps `waitedOnExchange==false`.
- Shell unit test rewritten to the EXCHANGE-3 behaviour: no-peer ⇒ empty report;
  a reachable peer (two peers) ⇒ `exchangesConducted==2`, offered/received still
  empty (AC-6's content). Discovery seam still asserted.

**Acceptance gate:** un-pended AC-7 in `pending.dart`; `TestAC07_NoPeerNoWait`
runs and **passes** in the default suite (both the no-peer Thens and the
reachable-peer control green). `exchange_and_merge_test.dart` default: AC-7 ✅,
AC-10 ✅, AC-6 skipped (pending EXCHANGE-2). The harness pending-set guard
(`harness_test.dart`) updated for AC-7's un-pend (+ EXCHANGE-3 in
`completedBehaviorPhases`) — 12/12 green; `refine_test.dart` 4/0, +1 skip;
`consent_and_record_test.dart` 4/0, +1 skip. Only AC-2 (CORE-4) and AC-6
(EXCHANGE-2) remain pending — both later phases.

**Grade gate:** fresh independent reviewer re-graded the full un-pended set
(10 ACs) against G1–G6 — **AC-7 A on first grade, 10 A / 0** (AC-1,3,4,5,7,8,9,
10,11,12); no downgrades, one non-A-denying residual noted (the
`waitedOnExchange` by-contract constant-false flag). Grid:
`behavior-test-completeness-bs-14.md` § EXCHANGE-3.

**Verification:** flutter at `~/development/flutter/bin`. `flutter analyze` clean;
unit **1545/0**; coverage **100% on all 20 touched lib files** (`dart run
tool/coverage_gate.dart c00422f`). Fix passes: **1/3** (the harness pending-set
guard needed updating after AC-7's un-pend; no implementation change). Tokens
5,300,757 · Time 14m 22s.

### Checkpoint / Handoff — after EXCHANGE-3

- **Frozen behaviour (consumed by CORE-4, EXCHANGE-2):** `GossipExchange.exchangeOnce`
  conducts an exchange with each reachable peer (`exchangesConducted ==
  peers.length`) and is a silent no-op when no peer is reachable. The count is
  the AC-7 invariant; EXCHANGE-2 will fill the `mine − theirs` offer/receive +
  dedup content inside the same method (it must keep the no-peer short-circuit
  and the per-peer conduct count).
- **CORE-4 (AC-2, next unblocked):** wires the scheduler into `SharingDependencies`
  and mounts `ExchangeOutcomeEndpoint` when it drives the live background
  exchange; AC-2 observes "no per-exchange action". Depends on EXCHANGE-3 (now
  done) — startable.
- **Verification commands:** unit `flutter test`; coverage `flutter test
  --coverage` then `dart run tool/coverage_gate.dart c00422f`. Acceptance:
  `flutter test integration_test/bs14/<file>.dart -d flutter-tester` — run the
  app-booting bs-14 files **one per invocation** (flutter-tester app-relaunch
  limitation). `--dart-define=BS14_RUN_PENDING=true` runs pending ACs.
- **Known gaps:** EXCHANGE-2 (AC-6) and EXCHANGE-4 (enabler) remain blocked on
  **G-4** (the sanctioned off-device path / bs-12 guard reconciliation).
