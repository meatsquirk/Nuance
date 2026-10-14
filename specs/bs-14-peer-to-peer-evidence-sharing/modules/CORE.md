# Module CORE — sharing subsystem scaffold, wiring & invisible consent

**Status:** Not started
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/sharing/` package root; `lib/sharing/consent/sharing_consent.dart`, `consent_store.dart`; `lib/sharing/sharing_scope.dart`; `SharingConsentReadEndpoint`; wiring into `lib/app/build_app.dart`. Coverage-gate tooling + `integration_test/bs14/` runner (scaffold).
**Depends on:** bs-13 (G-3) · **Blocks:** RECORD, EXCHANGE, MERGE (all consume the package + wiring)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| 1 | scaffold | — | ⬜ Todo | | |
| 2 | shell | — | ⬜ Todo | | |
| 3 | behavior | AC-1 | ⬜ Todo | | |
| 4 | behavior | AC-2 | ⬜ Todo | | |

## Interface reconciliation

- Consumes bs-13's provenance/dataset surface (present on main after G-3). bs-14 adds no new user-visible screens beyond the single plain-language opt-in offer; the invisibility guarantee is enforced here (the sharing subsystem exposes no peers/devices/syncing/network surface).
- `SharingScope` injects the sharing dependencies (consent store, record builder, gossip exchange, evidence merge) into the app the same way sibling scopes do; it is wired into `build_app.dart` **additively** so merge with bs-13's root is a one-line integration.
- Reconciles with bs-12: the sharing subsystem's only off-device actor is `PeerTransport`; everything else stays on-device (D-4).

## Open gates

- **G-1** (approve the spec) ✅ resolved 2026-10-14 (Matt Quirk). **G-3** (bs-13 signed off & merged) still blocks **CORE-1**.
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
