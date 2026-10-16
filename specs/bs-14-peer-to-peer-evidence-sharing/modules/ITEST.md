# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 ✅ (harness), ITEST-2 ✅ (AC-1..5, 5 A), ITEST-3 ✅ (AC-6/7/10, 3 A), ITEST-4 ✅ (AC-8/9/11/12, 3 A + AC-9 B-pending-MERGE-4); next ITEST-5 (test review → G-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs14/` — `harness.dart`, `fake_peer_transport.dart`, `pending.dart`, `harness_test.dart` (ITEST-1 scaffold/smoke tests), `consent_and_record_test.dart` (AC-1..5), `exchange_and_merge_test.dart` (AC-6,7,10), `refine_test.dart` (AC-8,9,11,12).
**Depends on:** all shell phases (CORE-2, RECORD-1, EXCHANGE-1, MERGE-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ✅ Done | 7,810,941 | 20m 38s |
| 2 | acceptance-tests | AC-1..5 | ✅ Done | 6,582,231 | 21m 58s |
| 3 | acceptance-tests | AC-6, AC-7, AC-10 | ✅ Done | 4,609,896 | 12m 39s |
| 4 | acceptance-tests | AC-8, AC-9, AC-11, AC-12 | ✅ Done | 6,488,618 | 19m 29s |
| 5 | test-review | — (G-2) | ⬜ Next | | |

## Interface reconciliation

- **Boundary:** the real app via `buildApp(AppDependencies(...))` — real `ColorScience`, the single shipped `deltaE00` (`lib/compare/difference.dart`, never a second copy), bs-13's provenance/derivation/clustering, and all bs-14 product code through production wiring. The **only** fake is `PeerTransport` (in-process loopback between two installs); there is no real network in the suite.
- **Observation points:** `SharingConsentReadEndpoint` (AC-1, AC-2), `RecordInspectEndpoint` (AC-3, AC-4, AC-5), `ExchangeOutcomeEndpoint` (AC-6, AC-7), `MappingEvidenceEndpoint` (AC-8..AC-12).
- **Pending gate:** `integration_test/bs14/pending.dart` keyed to `--dart-define=BS14_RUN_PENDING=true` (host env `BS14_RUN_PENDING=1`). Default run **skips** pending ACs (green with 0 pending visible); run-pending runs them (red baseline). Un-pend = delete the AC's pending entry in a behavior phase.

## Phase 1 — Harness

- **Kind:** acceptance-tests
- **Depends on:** all shells · **Blocks:** ITEST-2/3/4
- **Files:** `harness.dart`, `fake_peer_transport.dart`, `pending.dart`.
- **Tasks:** two-install fixture over a shared fake loopback transport; the fixtures table (`twoInstalls`, `seedMapping`, `confirmedEvidence`, `peerRecords`, `noPaletteRecord`); pending-gate mechanism; one smoke test that builds both installs and reads each endpoint.
- **Exit criteria:** smoke test green on `-d flutter-tester`; pending gate demonstrably skips a planted pending test by default and runs it under the flag.

### Result — ITEST-1 ✅ Done

Three new test-support files under `integration_test/bs14/` (no `lib/` touched):
- **`fake_peer_transport.dart`** — the only fake: a `FakeLocalNetwork` shared medium + per-install `FakePeerTransport` views implementing the real `PeerTransport` contract (`discover`/`offer`/`receive`), call-counted, with `peersReachable=false` driving the AC-7 no-peer case. Returns unmodifiable copies; deterministic.
- **`harness.dart`** — the Given/When/Then vocabulary and the fixture table verbatim: `twoInstalls` (two real `SharingInstall`s — real `SeenSet`/`GossipExchange`/`ExchangeScheduler`/`EvidenceMerge`/`CrowdRefine`/`SourceRateLimiter`/`EvidenceRecordBuilder` — over one fake network), `seedMapping`(+`seedMappingValue`/`seedCombination`/`seedPalette`), `confirmedEvidence`, `peerRecords(n, spread, outlier?)` (RNG-free monotonic cluster + far outlier), `noPaletteRecord`, the source taggers, `measuredColourOf` (real `ColorScienceImpl` CIELAB→CIELCh). `givenTheSharingApp` boots the real app via `buildApp` with an `InMemoryPersistentStore` so `SharingScope`+`SharingConsentReadEndpoint` mount; the record/exchange/merge surfaces are read through the sibling endpoints the harness builds over the **real** service output (the sanctioned "harness mounts the endpoint; behaviour phase populates it" pattern — only the mount is the suite's).
- **`harness_test.dart`** — the scaffold suite (added file; not in the original Owns list — a benign addition recorded here and in the module Owns line): 1 smoke test + 2 pending-gate tests + 5 fixture guards + 3 fake-transport contract tests = **12 tests**. The smoke asserts only **wiring invariants** that stay true as behaviour lands (frozen offer copy, consent default false on a fresh store, no speech/haptics on boot, fire-and-forget `waitedOnExchange==false`, `discoverCalls>=1`, append-only `merged orderedEquals existing`, bs-13 tier derivation incl. a differentiating `instrumentMeasured→Measured` linkage probe + the peer-contributed never-promote invariant, endpoint value round-trips) — no shell-stub value a behaviour phase will change.
- **Verification:** `flutter analyze integration_test/bs14/` clean; scaffold suite **12/12 green in both default and run-pending modes** on `-d flutter-tester`; full unit suite **1511/0** (unchanged — no `lib/` touched, so the coverage gate has no touched source and is trivially satisfied). No red baseline (ITEST-1 writes no AC tests). **Fix passes: 1/3** (fresh-reviewer grade: a rule-2 over-claiming comment on the refine block → added a differentiating `instrumentMeasured→Measured` case proving real derivation linkage + corrected the comment; a vacuous invisibility loop over an inventory that is legitimately empty at the shell → replaced with an accessor-wired check, since the invisibility guarantee is AC-1/AC-2's discriminating assertion and `isNotEmpty` would be false at the shell).
- **Grade:** scaffold tests reviewed by a fresh subagent against the three scaffold rules (no vacuous passes / comments claim only what's checked / deterministic) + the smoke-invariant check — PASS after the two fixes above. No AC grade grid yet (first AC grades at ITEST-2/3/4).
- Tokens 7,810,941 · Time 20m 38s.

### Checkpoint / Handoff — after ITEST-1

- **Frozen interfaces (consumed by ITEST-2/3/4):**
  - `givenTheSharingApp(tester, {PersistentStore? store}) → SharingAppHarness` with `.consented`/`.offerCopy`/`.userFacingSharingSurfaces`/`.speech`/`.haptics` — the consent surface (AC-1/AC-2).
  - `twoInstalls({aRecords, bRecords, peersReachable}) → TwoInstalls(network, a, b)`; `SharingInstall` exposes `id`/`transport`/`ownRecords`/`seenSet`/`recordBuilder`/`merge`/`refine`/`rateLimiter`/`gossip`/`scheduler` — all real but the transport.
  - `FakeLocalNetwork` (`peersReachable`, `inboxOf(id)`) + `FakePeerTransport` (`discover`/`offer`/`receive`, `discoverCalls`/`offerCalls`/`receiveCalls`).
  - Fixtures: `seedMapping`/`seedMappingValue`/`seedCombination`/`seedPalette`, `confirmedEvidence`, `peerRecords(n,{spread,outlier,palette,combination,tier})`, `noPaletteRecord`, `sourcedFromDistinctPeers`/`sourcedFromOnePeer`, `measuredColourOf`.
  - Endpoint builders: `recordEndpoint({prepared, shareSet})`, `exchangeEndpoint(outcome)` + `runExchange(install)`, `mappingEndpoint({value, evidence, tier, label})`.
  - Re-exports: `pending.dart`, `fake_peer_transport.dart`, the fakes, and the sharing/domain/colour types — an AC test imports only `harness.dart`.
- **Run commands:** flutter at `~/development/flutter/bin`. `flutter test integration_test/bs14/<file> -d flutter-tester` (a `-d` is mandatory — Known flakes); add `--dart-define=BS14_RUN_PENDING=true` for the run-pending (red-baseline) run. Unit: `flutter test`. Coverage: `flutter test --coverage` then `dart run tool/coverage_gate.dart <base>` (only when a phase touches `lib/`).
- **Known gap / note:** three of the four read endpoints (`RecordInspectEndpoint`/`ExchangeOutcomeEndpoint`/`MappingEvidenceEndpoint`) are **not yet mounted in `buildApp`** — the harness builds them over the real service output; the behaviour phases mount them for real and populate their values. `SharingDependencies` still holds only `consentStore`; the record/exchange/merge services are not yet threaded through it (the behaviour phases wire them). The smoke reads the consent endpoint from the booted tree and the other three from the services directly.
- **Next:** **ITEST-2 ∥ ITEST-3 ∥ ITEST-4** (disjoint files `consent_and_record_test.dart` / `exchange_and_merge_test.dart` / `refine_test.dart`) — one *pending* integration test per AC + the run-pending red baseline + grades; then **ITEST-5** (test review → G-2). No behaviour phase runs until G-2.

## Phase 2 — AC-1..5 (consent + record), pending + red baseline

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5
- **Files:** `consent_and_record_test.dart`.
- **Tasks:** author `TestAC01_OptInOnceNeverShown`, `TestAC02_NoPerExchangeAction`, `TestAC03_RecordCarriesOnlyEvidence`, `TestAC04_NothingPersonalLeaves`, `TestAC05_NoPaletteNotShared` per the master catalogue; mark all pending; record the run-pending red baseline + grades.
- **Exit criteria:** default run green (all pending), run-pending red at the catalogue's Then/Given; grade gate passed.

### Result — ITEST-2 ✅ Done

- **Landed** one file, `integration_test/bs14/consent_and_record_test.dart` (no `lib/` touched) — the five pending acceptance tests for AC-1..AC-5, all through the public surface:
  - **AC-1 / AC-2** are widget tests (`acTestWidgets`) over the booted real app, reading the wired `SharingConsentReadEndpoint` (`consented` / `offerCopy` / `userFacingSharingSurfaces`) + the `FakeSpeech`/`FakeHaptics` sinks. AC-1 drives the one-time opt-in offer through a public control keyed `sharingOptInKey` (the frozen contract below) and asserts consent recorded + the invisibility invariant (no surface names a mechanism) + the offer shown once; AC-2 pre-seeds opted-in consent via the public `PersistentConsentStore`, settles the silent background exchange, and asserts the only surfaced change is a mechanism-free recipe-improved signal, with no prompt (speech/haptics) and no network wording.
  - **AC-3 / AC-4 / AC-5** are pure-Dart (`acTest`) over the real `EvidenceRecordBuilder`, observed through `RecordInspectEndpoint` (`recordEndpoint(...)`). AC-3 asserts the prepared record's four fields at grain (declared palette ==, measured CIELAB ==/CIELCh closeTo, tier == referenceCard from the card-calibrated swatch, canonical paint ids); AC-4 asserts the crossing `canonicalForm` carries none of the source mix's personal tokens (name/evidence source) — redaction by construction; AC-5 asserts the share-set excludes `noPaletteRecord` and keeps the interpretable control.
- **Verification** (`-d flutter-tester`, flutter at `~/development/flutter/bin`): `flutter analyze` clean. **Default run green** — 5 pending ⇒ **5 skipped, 0 failed** (`+0 ~5 All tests skipped`). **Run-pending red baseline** — **5/5 fail**, each at exactly one point that names its owning phase, no harness crash (see the Red baseline table: AC-1 opt-in-offer Given precondition → CORE-3; AC-2 opted-in Given → CORE-3/CORE-4; AC-3/AC-4 record-prepared Given precondition → RECORD-2; AC-5 share-set Then → RECORD-3). The scaffold suite (`harness_test.dart`) stays **12/12** green on its own. (Running two app-booting files in one `flutter test` invocation trips the known flutter-tester app-relaunch limitation — run bs-14 files **one per invocation**; carried as a Known note.) No `lib/` touched ⇒ coverage gate has no touched source (trivially satisfied); unit suite unchanged at 1511/0.
- **Grades:** fresh independent reviewer against G1–G6 — AC-1/AC-3/AC-5 **A** on the first grid; AC-2 and AC-4 came back **B** on **G3** (vacuous negative Thens: AC-2's empty speech/haptics could pass against a dead sink; AC-4's `isNot(contains(...))` could pass against an empty serialization). Both fixed **in-phase** with the prescribed non-vacuity controls (AC-2: a live-sink probe proving speech/haptics record; AC-4: a positive control that the crossing serialization carries the declared brand) → **5 A / 0**. The controls are additive and run only once the behaviour lands, so the red baseline is unchanged. **Fix passes: 1/3.**
- **Interface reconciliations surfaced for the test review (ITEST-5) / behaviour phases:**
  1. **AC-3 paint combination (RECORD-2):** the frozen `RecordBuilder.prepare(Sample, {palette})` gives no paint ids, yet AC-3's record must carry a `paintCombination`. The test asserts the combination is present + canonical; **RECORD-2 must source the ids** (extend the prepared input — a combination arg or a recipe-bearing `Sample`). Flagged, not a blocker for the pending test.
  2. **AC-5 reason (RECORD-3):** the catalogue's "reason recorded — not interpretable" is not observable through the frozen `selectShareSet → List`; the test asserts the observable exclusion/inclusion. If RECORD-3 exposes a reason channel, a later augmentation can assert it.
  3. **AC-2 app exchange (CORE-4):** the booted app must run the background exchange over the **fake** transport in the suite and surface the recipe-improved signal; CORE-4 extends `givenTheSharingApp`/`buildApp` wiring to inject it (the sanctioned "behaviour phase wires the app surface" pattern).
- Tokens 6,582,231 · Time 21m 58s.

### Checkpoint / Handoff — after ITEST-2

- **New frozen contract for CORE-3/CORE-4 (honour these exact strings/keys):**
  - `sharingOptInKey = const Key('sharing-opt-in-offer')` — CORE-3 presents the one-time opt-in offer control under this key (reachable from the default route on a fresh, not-opted-in install), and removes/hides it once opted in.
  - The ongoing **recipe-improved signal** CORE-4 surfaces must be a `userFacingSharingSurfaces` item that lower-cased contains both `recipe` and `improve` (e.g. "recipes improve over time") and names **no** mechanism (none of: peer, device, sync, network, wi-fi/wifi, bluetooth, nearby, server, upload, download, cloud — the `_mentionsNetworkConcept` scan).
- **Run commands:** `flutter test integration_test/bs14/consent_and_record_test.dart -d flutter-tester` (default, green/skipped); add `--dart-define=BS14_RUN_PENDING=true` for the red baseline. One bs-14 app-booting file per `flutter test` invocation.
- **Next:** **ITEST-3 ∥ ITEST-4** (disjoint files `exchange_and_merge_test.dart` AC-6/7/10 · `refine_test.dart` AC-8/9/11/12; both build only on the ITEST-1 harness, so parallelizable), then **ITEST-5** (test review → G-2). No behaviour phase runs until G-2.

## Phase 3 — AC-6, AC-7, AC-10 (exchange + append merge), pending + red baseline

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5
- **Files:** `exchange_and_merge_test.dart`.
- **Tasks:** author `TestAC06_ExchangeOnlyMissing`, `TestAC07_NoPeerNoWait`, `TestAC10_AppendOnlyMerge`; mark pending; record red baseline + grades.
- **Exit criteria:** default green, run-pending red; grade gate passed.

### Result — ITEST-3 ✅ Done

- **Landed** one file, `integration_test/bs14/exchange_and_merge_test.dart` (no `lib/` touched) — the three pending acceptance tests for AC-6/AC-7/AC-10, all pure-Dart (`acTest`) through the public surface over the real gossip/scheduler/merge, the fake loopback transport the only fake (D-3):
  - **AC-6 (EXCHANGE-2)** — `twoInstalls` with A={r1,r2}, B={r2,r3}; r2 held as a value-equal but **distinct-object** pair (`r2a`/`r2b`) so an identity-keyed diff would re-offer it. After A and B each `runExchange`, reads the transport's **delivered inbox** (`network.inboxOf`): A offers B only `{r1.contentHash}`, B offers A only `{r3.contentHash}` (r2 common, dropped by content hash); the outcome endpoint shows `exchanges≥1`, `offered==1`; a second `runExchange(a)` leaves B's inbox at **length 1** (already-seen not re-offered). Rejects: full-set offer, identity-keyed diff, re-offering already-seen.
  - **AC-7 (EXCHANGE-3)** — `twoInstalls(peersReachable:false)`; the core flow triggers a fire-and-forget round. `waitedOnExchange` read **synchronously** after `trigger` returns (not blocked); the round `settled` `completes` without throwing (D-5); the outcome endpoint then shows `exchanges==0`, `offered==0`, `waitedOnExchange==false`. Because those no-peer Thens all pass against the no-op shell, a **G3-mandated control** — a reachable peer DOES conduct an exchange (`exchanges≥1`) while still never waiting — is the discriminator that reddens the baseline and goes green when EXCHANGE-2/3 land. The grader confirmed the control is **not** a G6 violation (it asserts only liveness + AC-7's own no-wait invariant, none of AC-6's offer-missing semantics).
  - **AC-10 (MERGE-2)** — one prior `llmSeed` evidence point + `sourcedFromDistinctPeers(peerRecords(3))` (3 distinct sources, 3 distinct measured colours, all checked as Givens) merged through the real `EvidenceMerge.ingest`, observed via `MappingEvidenceEndpoint`: evidence grows by exactly 3; the prior point is unchanged and still first (`sublist orderedEquals existing`); each appended point is `peerContributed`, carries its source id, and holds the record's measured CIELAB, in arrival order. Rejects: dedup of distinct measurements, overwrite/reorder, dropped source tag, wrong kind.
- **Verification** (`-d flutter-tester`, flutter at `~/development/flutter/bin`): `flutter analyze exchange_and_merge_test.dart` clean. **Default run green** — 3 pending ⇒ **3 skipped, 0 failed** (`All tests skipped`). **Run-pending red baseline** — **3/3 fail**, each on a Then naming its owner, no harness crash (AC-6 inbox `Set:[]` vs `{r1}` → EXCHANGE-2; AC-7 control `exchanges` 0 vs ≥1 → EXCHANGE-3; AC-10 evidence length 1 vs 4 → MERGE-2 — see Red baseline table). Scaffold `harness_test.dart` stays **12/12**. No `lib/` touched ⇒ coverage gate has no touched source (trivially satisfied); unit suite unchanged at 1511/0.
- **Grades:** fresh independent reviewer (fresh subagent; `/behavior-test-check` not installed → general grader against G1–G6) — **AC-6 A / AC-7 A / AC-10 A on the first grid, 0 below A**. No downgrades, no in-phase fixes. **Fix passes: 0/3.**
- **No new interface reconciliations.** The three tests consume only ITEST-1's frozen harness surface (`twoInstalls`/`runExchange`/`exchangeEndpoint`/`mappingEndpoint`/`sourcedFromDistinctPeers`/`peerRecords`). No augmentation rows (the sole pre-seeded one, TestAC09/MERGE-4, belongs to ITEST-4).
- Tokens 4,609,896 · Time 12m 39s.

### Checkpoint / Handoff — after ITEST-3

- **For the behaviour phases (honour these observable contracts):**
  - **EXCHANGE-2 (AC-6):** `GossipExchange.exchangeOnce(mine)` must offer each discovered peer `mine − theirs` keyed by `MixAccuracyRecord.contentHash` (not object identity), dedup already-offered/seen via `SeenSet`, and fold into `ExchangeOutcome` so `offered`/`exchanges` reflect the round. The suite reads what crossed via `FakeLocalNetwork.inboxOf(id)` and the counts via `ExchangeOutcomeEndpoint`.
  - **EXCHANGE-3 (AC-7):** with no reachable peer, `exchanges` stays 0 and nothing is offered; with a reachable peer holding a missing record, `exchanges≥1`. The scheduler stays fire-and-forget (`waitedOnExchange==false`) in both cases — AC-7's control depends on the reachable-peer path working (EXCHANGE-2 precedes EXCHANGE-3 in the graph).
  - **MERGE-2 (AC-10):** `EvidenceMerge.ingest(existing, incoming)` appends one `EvidencePoint` per `SourcedRecord` — `kind: EvidenceKind.peerContributed`, `source:` the arrival id, `coordinates:` the record's `measuredColour.lab` — through bs-13's append-only `appendEvidence`, preserving prior points and order.
- **Run commands:** `flutter test integration_test/bs14/exchange_and_merge_test.dart -d flutter-tester` (default, green/skipped); add `--dart-define=BS14_RUN_PENDING=true` for the red baseline. One bs-14 app-booting file per `flutter test` invocation (these three boot no app).
- **Next:** **ITEST-4** (`refine_test.dart`, AC-8/9/11/12; `TestAC09` carries the pre-seeded MERGE-4 augmentation), then **ITEST-5** (test review → G-2). No behaviour phase runs until G-2.

## Phase 4 — AC-8, AC-9, AC-11, AC-12 (refine/promote/quality), pending + red baseline

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5
- **Files:** `refine_test.dart`.
- **Tasks:** author `TestAC08_ClusteredRefine`, `TestAC09_NeverPromotes`, `TestAC11_OutlierDiscarded`, `TestAC12_RateLimited`; mark pending; record red baseline + grades. Note `TestAC09` carries a pre-seeded augmentation (MERGE-4).
- **Exit criteria:** default green, run-pending red; grade gate passed.

### Result — ITEST-4 ✅ Done

- **Landed** one file, `integration_test/bs14/refine_test.dart` (no `lib/` touched) — the four pending acceptance tests for AC-8/AC-9/AC-11/AC-12, all pure-Dart (`acTest`) through the public surface over the real `EvidenceMerge`/`CrowdRefine`/`SourceRateLimiter` (riding bs-13's real `ProvenanceDerivation`), observed through `MappingEvidenceEndpoint`:
  - **AC-8 (MERGE-3)** — `peerRecords(7, outlier: true)` (7-tight-cluster centred on `seedMappingValue` + 1 far outlier = 8) merged into an empty log, then `refine(_staleSeed, merged)`. `_staleSeed` (70,-6,16) is a deliberately-offset stored Estimated seed so an impl that **ignores the crowd** stays there. Then: the recomputed value is within ±1.5 of the cluster centroid (`seedMappingValue`, 62,2,6) **and** >1.5 from the plain mean of all 8 (57,7,0.5) — rejecting both plain-average (pulled by the outlier) and ignore-crowd. Given checks prove the fixture discriminates (centroid==seed; stale seed >5 away; plain-mean >3 away).
  - **AC-9 (MERGE-4)** — an Estimated mapping (`llmSeed` point) refined by `peerRecords(5)` via the real merge; `refine` → derived tier; label via the real `ProvenanceDerivation.qualifier`. Then: tier stays `estimated`, label stays "Estimated — not yet verified". **Control (G3/G5):** the SAME mapping promoted with the painter's own measured swatch via the real `promoteWithOwnSwatch` → Confirmed / "Confirmed — you measured this", proving the derivation CAN change.
  - **AC-11 (MERGE-3)** — same path as AC-8 (D-6), distinct fixture `peerRecords(6, outlier: true)` (6 tight + 1 far = 7). Then: the estimate is within ±1.5 of the 6-cluster centroid **and** >1.5 from the all-7 plain mean (56.3,7.7,-0.29) — the outlier is discarded, not averaged in.
  - **AC-12 (MERGE-5)** — `sourcedFromOnePeer(peerRecords(100), source:'flooder')` + `sourcedFromOnePeer(peerRecords(5), source:'honest-peer')` ingested. Then: the flooder's accepted peer-contributed points == `SourceRateLimiter.defaultMaxPerSource` (read symbolically so it tracks MERGE-5's scope-§6.6 value, <100) — excess rejected — and the honest peer's count == 5 (a flood never starves another source). Rejects "no cap → 100 accepted" and "global cap starves others".
- **Verification** (`-d flutter-tester`, flutter at `~/development/flutter/bin`): `flutter analyze refine_test.dart` clean. **Default run green** — 4 pending ⇒ **4 skipped, 0 failed** (`All tests skipped`). **Run-pending baseline** — **3 red + 1 green**: AC-8 red (value 70 vs centroid 62 ±1.5 → MERGE-3), AC-11 red (estimate 70 vs centroid 62 → MERGE-3), AC-12 red (flooder accepted 0 vs cap 50 → MERGE-5); **AC-9 green at baseline** — bs-13's `tierFor` already excludes `EvidenceKind.peerContributed` by fall-through, so the never-promote invariant holds trivially (a *limited* test — see the augmentation row). No harness crash. Scaffold `harness_test.dart` stays **12/12**. No `lib/` touched ⇒ coverage gate has no touched source (trivially satisfied); unit suite unchanged at 1511/0.
- **Grades:** fresh independent reviewer (fresh subagent; `/behavior-test-check` not installed → general grader against G1–G6) — **AC-8 A / AC-11 A / AC-12 A**; **AC-9 B pending MERGE-4** (G1: the "refined by peer records" Given isn't asserted through the surface because the shell merge is a no-op; G5: can't reject a promoting peer record until MERGE-4 formally excludes high-tier peers — both deferred to the MERGE-4 augmentation, the sanctioned limited-test exception). **3 A / 1 B-pending. Fix passes: 0/3** (no in-phase fix — the three reds are intended red baselines; AC-9's B is the deferred-augmentation exception).
- **Interface reconciliation surfaced for the test review (ITEST-5) / behaviour phases:**
  1. **AC-12 rate limiter wiring (MERGE-5):** the frozen `EvidenceMerge.ingest(existing, incoming)` takes no limiter, and `SourceRateLimiter.admit` is stateless in the shell. **MERGE-5 must wire a per-source `SourceRateLimiter` into `ingest`** (internal, defaulting to `SourceRateLimiter.defaultMaxPerSource`), capping each source's appended points at the cap while leaving other sources unaffected. The test reads the cap from `SourceRateLimiter.defaultMaxPerSource`, so changing that default stays in sync; MERGE-5 freezes exactly how the limiter is threaded (internal vs constructor-injected — must keep `const EvidenceMerge()` wiring in the harness working, e.g. a fresh per-call limiter).
  2. **AC-8/AC-11 depend on MERGE-2 first:** the robust-central-estimate value can only be computed once MERGE-2 has appended the peer points, so both go green at MERGE-3 *given* MERGE-2 is done (MERGE-2 precedes MERGE-3 in the graph).
- Tokens 6,488,618 · Time 19m 29s.

### Checkpoint / Handoff — after ITEST-4

- **For the behaviour phases (honour these observable contracts):**
  - **MERGE-3 (AC-8/AC-11):** `CrowdRefine.refine(current, evidence)` must recompute `.value` as the **robust central estimate** of the evidence coordinates with **outliers discarded** (reuse bs-13's clustering rule, D-6 — no new estimator), so a tight cluster + a far outlier resolves to the cluster centroid (±1.5), never the plain mean of everything and never the stored `current`. `.tier` stays whatever `tierFor` derives (Estimated for peer-contributed).
  - **MERGE-4 (AC-9):** a mapping refined by peer-contributed evidence must stay `ProvenanceTier.estimated` / "Estimated — not yet verified" (`ProvenanceDerivation.qualifier`) however much/high-tier the crowd evidence is — only the painter's own measured mix (`promoteWithOwnSwatch`) promotes. See the augmentation below for the two adds MERGE-4 owns.
  - **MERGE-5 (AC-12):** `EvidenceMerge.ingest` applies a per-source cap of `SourceRateLimiter.defaultMaxPerSource`; appended peer-contributed points per source ≤ cap; other sources unaffected (reconciliation 1 above).
- **Run commands:** `flutter test integration_test/bs14/refine_test.dart -d flutter-tester` (default, green/skipped); add `--dart-define=BS14_RUN_PENDING=true` for the baseline. One bs-14 app-booting file per `flutter test` invocation (these four boot no app).
- **Next:** **ITEST-5** — the test review; assemble the packet (all 12 AC tests), route **G-2** to a human → resolves G-2 and unblocks every behaviour phase. Preconditions met: every AC-test phase done; the whole-suite grid is all A **or** *B pending <phase>* with an augmentation row (AC-9). Also decide **G-4** before the EXCHANGE behaviour phases.

## Phase 5 — Test review (G-2)

- **Kind:** test-review
- **Depends on:** ITEST-2, ITEST-3, ITEST-4 · **Blocks:** every behavior phase
- **Tasks:** assemble the test-review packet (every AC test, its Given construction + assertions, its Rejects, its red baseline and grade); route **G-2** to a human. "Changes requested" → an ITEST change phase per item, then a fresh review.
- **Exit criteria:** a human records the G-2 decision.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_OptInOnceNeverShown | red | Given precondition: the one-time opt-in offer is presented (`find.byKey(sharingOptInKey)` findsNothing) | CORE-3 | A |
| AC-2 | TestAC02_NoPerExchangeAction | red | Given: the painter is opted in (live consent; `consented` false at the shell, which shows only the default) | CORE-4 (via CORE-3) | A |
| AC-3 | TestAC03_RecordCarriesOnlyEvidence | red | Given precondition: a record is prepared (`prepare` returns null at the shell) | RECORD-2 | A |
| AC-4 | TestAC04_NothingPersonalLeaves | red | Given precondition: a record is prepared (`prepare` returns null at the shell) | RECORD-2 | A |
| AC-5 | TestAC05_NoPaletteNotShared | red | Then: the interpretable control record is shared (`selectShareSet` returns `[]` at the shell) | RECORD-3 | A |
| AC-6 | TestAC06_ExchangeOnlyMissing | red | Then: A offers B only the missing r1 (`_hashesOf(inboxOf(b))` == `{}` at the shell, expected `{r1.contentHash}`) | EXCHANGE-2 | A |
| AC-7 | TestAC07_NoPeerNoWait | red | Then (control): a reachable peer gets an exchange (`exchanges` == 0 at the shell, expected ≥ 1). The no-peer Thens (exchanges==0/waited==false) pass at the shell, so the G3-mandated reachable-peer control is the discriminator that reddens the baseline. | EXCHANGE-3 | A |
| AC-8 | TestAC08_ClusteredRefine | red | Then: the recomputed value is the robust central estimate (value `70` = stale seed at the shell, expected within ±1.5 of centroid `62`) | MERGE-3 (needs MERGE-2 append) | A |
| AC-9 | TestAC09_NeverPromotes | **green at baseline** | *limited* — `tierFor` already excludes `peerContributed` (fall-through), so the never-promote invariant holds trivially; the own-swatch control shows the derivation CAN change; the Given ("refined by peer records") and the promoting-peer rejection are the MERGE-4 augmentation | MERGE-4 | B pending MERGE-4 |
| AC-10 | TestAC10_AppendOnlyMerge | red | Then: all three appended (evidence length `1` at the shell, expected `4`) | MERGE-2 | A |
| AC-11 | TestAC11_OutlierDiscarded | red | Then: the estimate equals the cluster centroid, outlier discarded (value `70` = stale seed at the shell, expected within ±1.5 of centroid `62`) | MERGE-3 (needs MERGE-2 append) | A |
| AC-12 | TestAC12_RateLimited | red | Then: per-source cap enforced (flooder accepted `0` at the shell, expected `50` = `defaultMaxPerSource`) | MERGE-5 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC09 | green at baseline — `tierFor` excludes `peerContributed` by fall-through, so the invariant holds trivially; and the shell merge appends nothing, so the "refined by peer records" Given is never realized. Confirmed by the ITEST-4 grader (G1 + G5). | MERGE-4 | **(1)** after the real `ingest`, assert the log holds exactly 5 `EvidenceKind.peerContributed` points — realizing the Given (this reddens it once added, since MERGE-2 must append first); **(2)** add a peer point whose record declares an instrument/high tier (would otherwise promote), and assert the tier *still* stays `estimated` / "Estimated — not yet verified" — proving `peerContributed` is actively *excluded*, not merely absent. Closes AC-9's B→A. | ⬜ Open |
