# Module ITEST — acceptance integration suite

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/bs14/` — `harness.dart`, `fake_peer_transport.dart`, `pending.dart`, `consent_and_record_test.dart` (AC-1..5), `exchange_and_merge_test.dart` (AC-6,7,10), `refine_test.dart` (AC-8,9,11,12).
**Depends on:** all shell phases (CORE-2, RECORD-1, EXCHANGE-1, MERGE-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | acceptance-tests | — (harness) | ⬜ Todo | | |
| 2 | acceptance-tests | AC-1..5 | ⬜ Todo | | |
| 3 | acceptance-tests | AC-6, AC-7, AC-10 | ⬜ Todo | | |
| 4 | acceptance-tests | AC-8, AC-9, AC-11, AC-12 | ⬜ Todo | | |
| 5 | test-review | — (G-2) | ⬜ Todo | | |

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

## Phase 2 — AC-1..5 (consent + record), pending + red baseline

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5
- **Files:** `consent_and_record_test.dart`.
- **Tasks:** author `TestAC01_OptInOnceNeverShown`, `TestAC02_NoPerExchangeAction`, `TestAC03_RecordCarriesOnlyEvidence`, `TestAC04_NothingPersonalLeaves`, `TestAC05_NoPaletteNotShared` per the master catalogue; mark all pending; record the run-pending red baseline + grades.
- **Exit criteria:** default run green (all pending), run-pending red at the catalogue's Then/Given; grade gate passed.

## Phase 3 — AC-6, AC-7, AC-10 (exchange + append merge), pending + red baseline

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5
- **Files:** `exchange_and_merge_test.dart`.
- **Tasks:** author `TestAC06_ExchangeOnlyMissing`, `TestAC07_NoPeerNoWait`, `TestAC10_AppendOnlyMerge`; mark pending; record red baseline + grades.
- **Exit criteria:** default green, run-pending red; grade gate passed.

## Phase 4 — AC-8, AC-9, AC-11, AC-12 (refine/promote/quality), pending + red baseline

- **Kind:** acceptance-tests
- **Depends on:** ITEST-1 · **Blocks:** ITEST-5
- **Files:** `refine_test.dart`.
- **Tasks:** author `TestAC08_ClusteredRefine`, `TestAC09_NeverPromotes`, `TestAC11_OutlierDiscarded`, `TestAC12_RateLimited`; mark pending; record red baseline + grades. Note `TestAC09` carries a pre-seeded augmentation (MERGE-4).
- **Exit criteria:** default green, run-pending red; grade gate passed.

## Phase 5 — Test review (G-2)

- **Kind:** test-review
- **Depends on:** ITEST-2, ITEST-3, ITEST-4 · **Blocks:** every behavior phase
- **Tasks:** assemble the test-review packet (every AC test, its Given construction + assertions, its Rejects, its red baseline and grade); route **G-2** to a human. "Changes requested" → an ITEST change phase per item, then a fresh review.
- **Exit criteria:** a human records the G-2 decision.

## Red baseline  <!-- filled by the AC-test phases -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_OptInOnceNeverShown | pending | Then: surfaces empty of network concepts | CORE-3 | |
| AC-2 | TestAC02_NoPerExchangeAction | pending | Then: prompt sink empty after exchange | CORE-4 | |
| AC-3 | TestAC03_RecordCarriesOnlyEvidence | pending | Then: exactly the four fields | RECORD-2 | |
| AC-4 | TestAC04_NothingPersonalLeaves | pending | Then: no personal field present | RECORD-2 | |
| AC-5 | TestAC05_NoPaletteNotShared | pending | Then: no-palette record excluded | RECORD-3 | |
| AC-6 | TestAC06_ExchangeOnlyMissing | pending | Then: offers only missing, dedup | EXCHANGE-2 | |
| AC-7 | TestAC07_NoPeerNoWait | pending | Then: exchanges==0, waited==false | EXCHANGE-3 | |
| AC-8 | TestAC08_ClusteredRefine | pending | Then: robust central estimate | MERGE-3 | |
| AC-9 | TestAC09_NeverPromotes | pending | Then: stays Estimated | MERGE-4 | |
| AC-10 | TestAC10_AppendOnlyMerge | pending | Then: appended + tagged, none overwritten | MERGE-2 | |
| AC-11 | TestAC11_OutlierDiscarded | pending | Then: outlier excluded | MERGE-3 | |
| AC-12 | TestAC12_RateLimited | pending | Then: per-source cap enforced | MERGE-5 | |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| TestAC09 | before MERGE-4 the derivation doesn't formally exclude a high-tier peer record from promotion, so the "never Confirms" Then can't discriminate the strongest wrong impl | MERGE-4 | a case where a peer record declares an instrument tier; assert the mapping still derives `estimated` / "not yet verified" | ⬜ Open |
