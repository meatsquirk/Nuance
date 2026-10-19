# Module CORE — sharing subsystem scaffold, wiring & invisible consent

**Status:** Done — CORE-1 ✅, CORE-2 ✅, CORE-3 ✅ (AC-1), CORE-4 ✅ (AC-2) un-pended, graded A. Module complete.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/` package root; `lib/sharing/consent/sharing_consent.dart`, `consent_store.dart`; `lib/sharing/sharing_scope.dart`; `SharingConsentReadEndpoint`; wiring into `lib/app/build_app.dart`. Coverage-gate tooling + `integration_test/bs14/` runner (scaffold).
**Depends on:** bs-13 (G-3) · **Blocks:** RECORD, EXCHANGE, MERGE (all consume the package + wiring)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 6,209,519 | 23m 46s |
| 2 | shell | — | ✅ Done | 10,823,845 | 30m 53s |
| 3 | behavior | AC-1 | ✅ Done | 18,326,126 | 47m 46s |
| 4 | behavior | AC-2 | ✅ Done | 14,820,009 | 37m 40s |

## Interface reconciliation

- Consumes bs-13's provenance/dataset surface (present on main after G-3). bs-14 adds no new user-visible screens beyond the single plain-language opt-in offer; the invisibility guarantee is enforced here (the sharing subsystem exposes no peers/devices/syncing/network surface).
- `SharingScope` injects the sharing dependencies (consent store, record builder, gossip exchange, evidence merge) into the app the same way sibling scopes do; it is wired into `build_app.dart` **additively** so merge with bs-13's root is a one-line integration.
- Reconciles with bs-12: the sharing subsystem's only off-device actor is `PeerTransport`; everything else stays on-device (D-4).

## Open gates

- **G-1** (approve the spec) ✅ resolved 2026-10-14 (Matt Quirk). **G-3** (bs-13 signed off & merged) ✅ resolved 2026-10-15 — bs-13 merged to main @ `c00422f`; CORE-1 rebased onto it and no longer blocked.
- **G-2** (approve the acceptance tests) still blocks CORE-3/CORE-4 (every behavior phase).
- **G-4** (sanctioned off-device path) does not block CORE, but CORE-4's background exchange depends on the EXCHANGE phases, which need G-4.

## Phase 1 — Scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** G-1, G-3 · **Blocks:** CORE-2
- **Files:** branch `feat/bs-14-peer-to-peer-evidence-sharing` (already created for the plan; re-base onto bs-13-merged main at scaffold time); coverage-gate self-check; `integration_test/bs14/` runner skeleton.
- **Tasks:**
  1. Confirm the branch is based on a main that contains bs-13 (G-3). If the plan-time branch predates the bs-13 merge, rebase it onto the merged main.
  2. Record the baseline: `flutter analyze` clean; `flutter test` unit count; `flutter test integration_test -d flutter-tester` regression count on the merged tree.
  3. Self-check the coverage gate (passes on a clean tree, fails on a planted uncovered line) with `COVERAGE_GATE_BASE=<bs-13-merge-commit>`.
  4. Create the `integration_test/bs14/` dir + pending-gate skeleton (no tests yet).
- **Exit criteria:** analyze clean; baseline unit + integration counts recorded; coverage gate self-check passes; no product code added.

### Result — CORE-1 (scaffold) ✅

- **Rebase (task 1):** `feat/bs-14-peer-to-peer-evidence-sharing` was based on main `167c5db` (bs-12 merge) with two plan-only commits on top. Rebased onto current main `c00422f` (the bs-13 sign-off merge) — **clean, no conflicts** (the two commits touch only `specs/bs-14-*`, absent from main). bs-13's real surface confirmed present: `ProvenanceDerivation` (`appendEvidence`/`promoteWithOwnSwatch`/`tierFor`) in `lib/domain/provenance_derivation.dart`; `EvidenceKind` enum in `lib/domain/sample.dart`; `CandidateMapping` + declared-palette in `lib/dataset/seed_dataset.dart`. **G-3 closed.**
- **Baseline (task 2):** `flutter analyze` → **No issues found** (full tree, incl. the new skeleton). **Unit: `flutter test` = 1413/0.** **Integration = 293/293:** iPhone 17 sim (whole device-suite set, 12 entry points, under `coord.sh with-lock`) **241/241**; host flutter-tester **52/52** (`integration_test/bs12/nfr_test.dart` 33 + `integration_test/bs13/dataset_test.dart` 19 — these read `lib/` via `dart:io` so they run host-side, not on the sim). == the bs-13 merged-tree baseline (`c00422f`), unchanged by construction (bs-14 adds no `lib/`/`test/` code this phase).
- **Coverage gate self-check (task 3):** reused `tool/coverage_gate.dart` with `COVERAGE_GATE_BASE=c00422f`. Planted a temp `lib/` file + test: fully covered ⇒ **PASS** (exit 0); one branch left uncovered ⇒ **FAIL** (exit 1, named the uncovered line). Temp fixtures + `coverage/` removed; no product code remains.
- **Runner skeleton (task 4):** created `integration_test/bs14/pending.dart` — the `BS14_RUN_PENDING` pending-gate mechanism (`pendingSkipReason`, `acTest`/`acTestWidgets`), `allACs` (AC-1..AC-12), `behaviorPhases` (the 10 bs-14 behavior phases), empty `completedBehaviorPhases`, and `pendingACs` seeded with all 12 ACs → their owning phase (AC-1→CORE-3, AC-2→CORE-4, AC-3/4→RECORD-2, AC-5→RECORD-3, AC-6→EXCHANGE-2, AC-7→EXCHANGE-3, AC-8/11→MERGE-3, AC-9→MERGE-4, AC-10→MERGE-2, AC-12→MERGE-5). **No harness/fixtures/tests yet** (ITEST-1 adds the two-install fake-transport harness, fixtures and smoke test). Analyzes clean.
- **Coverage obligation:** CORE-1 touched no `lib/` file (the skeleton lives in `integration_test/`, outside the gate scope) — justified exclusion, same as prior scaffolds. **No product code added** (exit criterion).
- **Fix passes:** 0/3 (green on the first full run). **Tokens** 6,209,519 · **Time** 23m 46s.

### Checkpoint / Handoff — after CORE-1

- **Branch base:** `feat/bs-14-peer-to-peer-evidence-sharing` now sits on `c00422f`; force-pushed with lease after the rebase (plan-only commits rewritten onto the merged main).
- **Verification commands (reuse):** flutter is at `~/development/flutter/bin` (prepend to PATH on non-interactive shells). Unit: `flutter test`. bs-14's own suite (from ITEST-1 on): `flutter test integration_test/bs14/<file> -d flutter-tester` (a `-d` is **mandatory** — no `-d` ⇒ 0 tests, false green); run-pending adds `--dart-define=BS14_RUN_PENDING=true`. Host-side regression siblings: `integration_test/bs12/nfr_test.dart`, `integration_test/bs13/dataset_test.dart` on `-d flutter-tester`. Device-suite cross-feature regression: the other 12 entry points on the iPhone 17 sim under `coord.sh with-lock` (signature `<feature> <phase> [--wait N] -- <cmd>`, `FNP_COORD_REPO=/Users/matthew.quirk/Nuance`, `cd` into the worktree inside `bash -c`). Coverage: `flutter test --coverage` then `dart run tool/coverage_gate.dart c00422f`. macOS has no `timeout`; never stage the untracked `ios/.../swiftpm/` dirs the sim build leaves.
- **Surface drift for MERGE-1 / the plan-upgrade pass:** D-2 and the dependency-graph "merge-risky pairs" note say `EvidenceKind.peerContributed` is added to `lib/domain/provenance.dart`, but the `EvidenceKind` enum actually lives in `lib/domain/sample.dart` (`provenance.dart` exists but does not hold the enum). MERGE-1 must target `sample.dart`.
- **Next (CORE-2, shell):** add the `lib/sharing/` package — `SharingConsent`/`ConsentStore` (default **not** opted in, persisted per sibling conventions), `SharingScope` wired additively into `lib/app/build_app.dart`, and `SharingConsentReadEndpoint` (exposing `consented`, `offerCopy`, and an empty-of-network-concepts `userFacingSharingSurfaces`). Unit gate 100% on touched files; existing suite stays green; read endpoint observable from a smoke test. No behavior change.

## Phase 2 — Shell: package, consent state & wiring

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CORE-1 · **Blocks:** RECORD-1, MERGE-1, EXCHANGE-1, all CORE behavior
- **Files:** `lib/sharing/sharing_scope.dart`, `lib/sharing/consent/sharing_consent.dart`, `lib/sharing/consent/consent_store.dart`, `lib/sharing/sharing_read_endpoint.dart`, edit `lib/app/build_app.dart`.
- **Tasks:**
  1. `SharingConsent { bool consented; String offerCopy }` (immutable value); `ConsentStore` interface + a persisted impl (default **not** opted in), following sibling persistence conventions.
  2. `SharingScope` — the DI seam that holds the sharing dependencies; wire additively into `build_app.dart`.
  3. `SharingConsentReadEndpoint` exposing `consented`, `offerCopy`, and `userFacingSharingSurfaces` (an inventory of any user-visible sharing surface — must stay empty of network concepts; the invisibility assertion reads this).
  4. No behavior change: nothing opts in, nothing exchanges; existing suite stays green.
- **Exit criteria:** unit gate (100% touched) passes; existing suite green; read endpoint observable from a smoke test.

### Result — CORE-2 (shell) ✅

- **Landed:** the `lib/sharing/` package + additive app wiring.
  - `consent/sharing_consent.dart` — `SharingConsent{consented, offerCopy}` immutable value: default **not opted in**, `copyWith`, value `==`/`hashCode`, and `defaultOfferCopy` frozen to the spec wording *"help improve recipe accuracy by sharing anonymous mix results"* (AC-1), deliberately naming no mechanism.
  - `consent/consent_store.dart` — `ConsentStore` interface (`changes`/`load`/`save`) + `PersistentConsentStore` over the shared `PersistentStore` seam (own collection `sharing_consent`, doc `current`, `{consented, offerCopy}` body; absent ⇒ the not-consented default; forwards the backing `changes`), mirroring `CvdProfileStore`.
  - `sharing_scope.dart` — `SharingDependencies{consentStore}` holder (grows: RECORD-1 recordBuilder, EXCHANGE-1 gossipExchange, MERGE-1 evidenceMerge) + `SharingScope` InheritedWidget (`of`/`maybeOf`), symmetric to `AppScope`.
  - `sharing_read_endpoint.dart` — `SharingConsentReadEndpoint` (keyed `sharing-consent-read-endpoint`; `consented`/`offerCopy` getters + `userFacingSharingSurfaces` — **empty of network concepts**, the invisibility seam AC-1 reads; `of`/`maybeOf`).
  - `lib/app/build_app.dart` — **additive, store-gated** (mirrors `_profileStore`/`CvdProfileReadEndpoint`): `_AppState` builds `PersistentConsentStore` in `initState` when a store is wired and mounts `SharingScope` + the keyed `SharingConsentReadEndpoint` above the `MaterialApp`; consent is the const not-opted-in default, surface inventory empty ⇒ **behaviour-neutral** (no new route/visible surface). Bare unit trees (no store) mount no scope.
- **Gates:** `flutter analyze` clean. **Unit 1432/0** (+19: sharing_consent 5, consent_store 5, sharing_scope 3, sharing_read_endpoint 4, build_app sharing-wiring 2). **Coverage 100% line on all 5 touched files** (`build_app.dart` + the 4 `lib/sharing` files) vs `c00422f` — PASS.
- **Existing suite green (regression):** host `flutter-tester` — bs12 nfr 33 + bs13 dataset 19 = **52/52**; device iPhone 17 sim (under `coord.sh with-lock`) — 11 harness acceptance entry points combined **222/222** + `integration_test/conformance` (bs-11 on-device unit+a11y re-run) **1432/1432**; zero failures, exit 0. The inherited sim baseline (222 harness + bs-11 conformance = CORE-1's 241 tally) is fully covered and green.
- **No AC:** shell. **Fix passes: 1/3** (first run surfaced a `listEquals` undefined-method — needed `package:flutter/foundation.dart` in the read endpoint — and one `unrelated_type_equality_checks` lint in a `==` test; both fixed, green on the second run). **Tokens** 10,823,845 · **Time** 30m 53s.

### Checkpoint / Handoff — after CORE-2

- **Frozen interfaces (consumed by RECORD/EXCHANGE/MERGE):**
  - `SharingConsent` (`consented`, `offerCopy`, `copyWith`, `==`; `SharingConsent.defaultOfferCopy`).
  - `ConsentStore {Listenable changes; Future<SharingConsent> load(); Future<void> save(SharingConsent)}`; `PersistentConsentStore(PersistentStore)` with `collection`/`documentId` statics.
  - `SharingDependencies{consentStore}` — **add new services as fields here** (do not re-thread wiring); `SharingScope.of(context)`/`maybeOf(context)`.
  - `SharingConsentReadEndpoint` — `endpointKey`, `consent`, `userFacingSharingSurfaces`, `consented`/`offerCopy` getters, `of`/`maybeOf`.
- **Wiring:** store-gated in `_AppState` (built in `initState`, mounted above the `MaterialApp`). A tree pumped with no `store` mounts no `SharingScope` — a surface that must read it standalone uses `maybeOf`.
- **Verification commands:** as the CORE-1 handoff. **Device regression gotcha:** `flutter test <file1> <file2> … integration_test/conformance -d <sim>` **silently drops the trailing `conformance` dir arg** when mixed with file args (it ran 0 conformance tests) — run `integration_test/conformance` in its own `flutter test` invocation. Combined 11-harness-file run = 222; conformance (on-device unit+a11y re-run) = 1432.
- **Next (RECORD-1, shell):** `MixAccuracyRecord` + content hash + `RecordBuilder` + `RecordInspectEndpoint` — startable now. **MERGE-1 can run in parallel** (disjoint files), but MERGE-1's `EvidenceKind.peerContributed` goes in **`lib/domain/sample.dart`** (not `provenance.dart` — the surface-drift note). G-2 blocks every behaviour phase; G-4 blocks EXCHANGE-2/EXCHANGE-4.

## Phase 3 — AC-1: opt in once, never shown the mechanism

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** CORE-2, G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/sharing/consent/` (opt-in action), `lib/sharing/sharing_scope.dart`.
- **Tasks:**
  1. The one-time plain-language opt-in: the offer copy is exactly "help improve recipe accuracy by sharing anonymous mix results"; opting in records consent once.
  2. Guarantee the sharing subsystem never exposes peers, devices, syncing or a network in `userFacingSharingSurfaces` (stays empty of those concepts after opt-in).
- **Exit criteria:** unit + coverage; acceptance gate below; grade gate.
- **Acceptance gate:** un-pend AC-1; `integration_test/bs14/` green with `TestAC01_OptInOnceNeverShown` passing (and all earlier ACs).

### Result — CORE-3 (behavior, AC-1) ✅

- **Landed:** the one-time plain-language opt-in and the invisibility guarantee.
  - `lib/sharing/consent/opt_in_offer.dart` — `SharingOptInOffer`: a keyed (`Key('sharing-opt-in-offer')`) `ElevatedButton` labelled with the frozen `SharingConsent.defaultOfferCopy` (names no mechanism). Reads consent from `SharingConsentReadEndpoint.maybeOf` + the store from `SharingScope.maybeOf`; on press writes `consent.copyWith(consented: true)` through the `ConsentStore`. Renders `SizedBox.shrink` outside a sharing tree (no scopes) and once opted in (the one-time guarantee).
  - `lib/app/build_app.dart` — replaced CORE-2's inline const mount with a stateful **`_SharingRoot`**: loads the stored consent at mount, listens to `store.changes` so an opt-in reconfigures the live consent, and mounts `SharingScope` + the keyed `SharingConsentReadEndpoint` with `userFacingSharingSurfaces = consented ? [] : [offerCopy]` (the one pre-opt-in surface, mechanism-free). The home (Readout) landing now overlays the offer via a `Stack` (bottom-centre `SafeArea`), so a pushed route — e.g. the self-assessment onboarding — covers it.
- **Gates:** `flutter analyze` clean. **Unit 1519/0.** **Coverage 100% line on all 20 touched `lib/` files** (incl. new `opt_in_offer.dart` + changed `build_app.dart`) vs `c00422f` — PASS. Project gate is line-only (documented); the four offer branches + `_SharingRoot`'s load/reload/unmount-guard/surface branches are each unit-tested.
- **Acceptance (AC-1):** un-pended AC-1 (`pending.dart`); `TestAC01_OptInOnceNeverShown` **green** on `-d flutter-tester`, AC-2..AC-12 still pending; harness guard tests updated (scaffold-snapshot assertions → completed-phase invariants) and green. **Augmentation:** closed the ITEST-5 reviewer's G3 live-binding note — AC-1 now scans the populated pre-opt-in inventory (demonstrates the live `userFacingSharingSurfaces` binding, discriminates against the always-empty pre-CORE-3 code). Row added to ITEST *Test augmentations*.
- **Grade:** fresh independent reviewer — AC-1 **A** on G1–G6 (grid `behavior-test-completeness-bs-14.md`); augmentation applied after and keeps A.
- **Regression:** host `-d flutter-tester` bs12 33 + bs13 19 = **52** (run separately — the combined-invocation load failure reproduces independently of this phase; both pass alone; carried combined-run fragility). Device iPhone 17 sim under `coord.sh with-lock` — 12 cross-feature entry points **241/241** (== CORE-1 baseline), so the shared `build_app` change broke nothing (self-assessment's Readout-then-onboarding boot and bs-11 conformance included).
- **Fix passes: 0/3** (green on the first full run). **Tokens** 18,326,126 · **Time** 47m 46s.

### Checkpoint / Handoff — after CORE-3

- **Frozen interfaces (consumed by CORE-4):**
  - `SharingOptInOffer` (`offerKey = Key('sharing-opt-in-offer')`) — the keyed one-time opt-in control, shown on the home landing while not opted in, gone after.
  - `_SharingRoot` (private to `build_app.dart`) holds the **live** consent: it loads from the store and re-reads on `store.changes`, so a saved opt-in reconfigures the endpoint reactively. **CORE-4 adds its "recipes improve over time" signal to `userFacingSharingSurfaces` here** (the consented branch, currently `[]`), and wires the silent background exchange — do not re-thread the mount.
  - `SharingConsentReadEndpoint.userFacingSharingSurfaces` now reflects consent state: `[offerCopy]` pre-opt-in, `[]` post-opt-in. The invisibility scan reads this; keep it mechanism-free.
- **Verification commands:** as the CORE-2 handoff. **Device regression:** the 12 entry points on the iPhone 17 sim (`5AB9D06D-…`) under `coord.sh with-lock` = **241**; host bs12+bs13 = 52 **run one file per `flutter test`** (combining the two loads-fails on this toolchain — not a regression, both pass alone). Un-pend = delete the AC row in `pending.dart` **and** add the phase to `completedBehaviorPhases` when it owns no more pending AC (the harness guard enforces it).
- **Next (CORE-4, AC-2):** needs EXCHANGE-3 (the background exchange must exist) + G-2 (done). It reads CORE-3's live consent and adds the mechanism-free outcome signal; AC-2's test already pins the no-prompt/no-haptic + recipe-improved-signal contract.

## Phase 4 — AC-2: no per-exchange action

- **Kind:** behavior
- **Target AC:** AC-2 (full)
- **Depends on:** CORE-3, EXCHANGE-3 (background exchange must exist), G-2 · **Blocks:** SIGNOFF-1
- **Files:** `lib/sharing/sharing_scope.dart` (wire the silent background exchange), `lib/sharing/` surface signalling.
- **Tasks:**
  1. Run the background exchange silently once the painter has opted in: no prompt, toast or notification per exchange.
  2. Surface only a "recipes improve over time" signal — no network/sync wording.
- **Exit criteria:** unit + coverage; acceptance gate; grade gate.
- **Acceptance gate:** un-pend AC-2; `TestAC02_NoPerExchangeAction` passing (and all earlier ACs).

### Result — CORE-4 (behavior, AC-2) ✅

- **Landed:** the silent background exchange + the mechanism-free outcome signal.
  - `lib/sharing/consent/sharing_consent.dart` — `SharingConsent.recipesImproveSignal = 'Your recipes improve over time.'`: the one ongoing opted-in surface, naming an outcome and no mechanism.
  - `lib/sharing/inactive_peer_transport.dart` (new) — `InactivePeerTransport implements PeerTransport`: `discover` reaches no peer, `offer`/`receive` inert. The production default the exchange runs over until EXCHANGE-4 wires the real local-network transport under G-4; nothing crosses the device boundary, so bs-12's no-off-device-path guard is honoured while G-4 is unresolved.
  - `lib/sharing/sharing_scope.dart` — `SharingDependencies` gained an optional `exchangeScheduler` (null in bare unit trees; supplied by `_SharingRoot`).
  - `lib/app/build_app.dart` — `_SharingRoot` builds one fire-and-forget `ExchangeScheduler`(`GossipExchange` over `InactivePeerTransport` + `SeenSet`) in `initState`; on adopting a consented state (opt-in transition **and** a boot that reads back an already-opted-in consent) it fires exactly one silent round (`_startBackgroundExchange`) — no prompt/speech/haptic, caller never awaits. Consented ⇒ `userFacingSharingSurfaces = [recipesImproveSignal]` (was `[]`); the scheduler is exposed through `SharingScope` and the tree is wrapped in the keyed `ExchangeOutcomeEndpoint` (snapshot of the scheduler outcome — zero/not-waited over the inert transport).
- **Gates:** `flutter analyze` clean. **Unit 1553/0** (+8: inactive transport 4, sharing_scope 1, sharing_consent 1, build_app sharing-wiring 2). **Coverage 100% line on all 21 touched `lib/` files** vs `c00422f` — PASS.
- **Acceptance (AC-2):** un-pended AC-2 (`pending.dart`) + added CORE-4 to `completedBehaviorPhases`; `TestAC02_NoPerExchangeAction` **green** on `-d flutter-tester` (`consent_and_record_test.dart` 5/5). Only AC-6 (EXCHANGE-2) remains pending. No augmentation owed or newly enabled by CORE-4 (the AC-2 test already asserts the full no-prompt/no-haptic + recipe-improved-signal contract; AC-1's post-opt-in scan now reads the populated `[recipesImproveSignal]` live surface — a strengthening the reviewer confirmed, not a new row).
- **Grade:** fresh independent reviewer — AC-2 **A** on G1–G6; AC-1 re-confirmed **A** under the surface change; full set **11 A / 0** (AC-1,2,3,4,5,7,8,9,10,11,12). Grid `behavior-test-completeness-bs-14.md` § CORE-4. One non-A-denying residual noted (the recipe-signal presence proves consent was adopted + the surface swapped, not literally the trigger call; silence Thens stay controlled by the live probe).
- **Regression (no behaviour change for non-sharing features):** host `-d flutter-tester` bs12 nfr **33** (incl. the no-off-device-path NFR — the inert transport did not trip it) + bs13 dataset **19** = 52. Device iPhone 17 sim under `coord.sh with-lock` — 11 cross-feature entry points **222/222** + `integration_test/conformance` **1553/1553**; the extra `ExchangeOutcomeEndpoint` tree layer broke nothing.
- **Fix passes: 1/3** — first full run's coverage gate flagged `peer_transport.dart:16` (the `const Peer` ctor read 0 — every unit construction was const; the EXCHANGE-1 "const-ctor reads 0" gotcha); added one runtime `Peer` construction in the new transport test. No implementation change. **Tokens** 14,820,009 · **Time** 37m 40s.

### Checkpoint / Handoff — after CORE-4 (module complete)

- **Frozen interfaces (consumed by EXCHANGE-4, SIGNOFF-1):**
  - `SharingConsent.recipesImproveSignal` — the sole opted-in user-facing surface; mechanism-free by `SharingConsentReadEndpoint` contract. Keep it the only surface added to the consented branch.
  - `SharingDependencies.exchangeScheduler` — the fire-and-forget background scheduler, wired by `_SharingRoot`. A core flow reaches the exchange through it and never waits.
  - `_SharingRoot` (private to `build_app.dart`) owns the exchange lifecycle: one silent round per consented adoption, over `InactivePeerTransport`. **EXCHANGE-4 swaps the transport** — inject the real `LocalNetworkTransport` (e.g. via an `AppDependencies` field read here), leaving the trigger/surface wiring untouched.
- **Known gaps (for EXCHANGE-4 / the sign-off walkthrough):**
  - The round offers **no own records yet** (`const <MixAccuracyRecord>[]`): wiring the painter's shareable confirmed mixes (RECORD builder share-set) into the trigger is part of making the exchange carry data on-device — D-3 manual, with EXCHANGE-4's real transport.
  - `ExchangeOutcomeEndpoint` is mounted as a **build-time snapshot** (correct zero/not-waited over the inert transport). When EXCHANGE-4 makes the exchange live, refresh it on round settle so a booted-app AC can observe a non-zero tally.
- **Verification commands:** unchanged — flutter at `~/development/flutter/bin`; unit `flutter test`; coverage `flutter test --coverage` then `dart run tool/coverage_gate.dart c00422f`; bs-14 app-booting files one per `flutter test … -d flutter-tester`; sim cross-feature regression under `coord.sh with-lock` (11 `_test.dart` files combined = 222; `integration_test/conformance` separately). Construct a value class non-const at least once or its const-ctor line reads 0.
- **Next:** CORE module done. Remaining: **EXCHANGE-2 (AC-6)** and **EXCHANGE-4 (enabler)** — both need **G-4**; then **SIGNOFF-1** (needs CORE-4 ✅, EXCHANGE-4).
