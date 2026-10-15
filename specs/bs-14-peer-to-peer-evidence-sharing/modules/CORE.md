# Module CORE — sharing subsystem scaffold, wiring & invisible consent

**Status:** In progress — CORE-1 ✅ done; next CORE-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/` package root; `lib/sharing/consent/sharing_consent.dart`, `consent_store.dart`; `lib/sharing/sharing_scope.dart`; `SharingConsentReadEndpoint`; wiring into `lib/app/build_app.dart`. Coverage-gate tooling + `integration_test/bs14/` runner (scaffold).
**Depends on:** bs-13 (G-3) · **Blocks:** RECORD, EXCHANGE, MERGE (all consume the package + wiring)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ✅ Done | 6,209,519 | 23m 46s |
| 2 | shell | — | ⬜ Next | | |
| 3 | behavior | AC-1 | ⬜ Todo | | |
| 4 | behavior | AC-2 | ⬜ Todo | | |

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

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->
