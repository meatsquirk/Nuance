# Module GUARD — invariant guards (offline, privacy, swappable, portability)

**Status:** In progress — GUARD-1 done; next GUARD-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/nfr/guards/` (source-scan, swap-harness, network-block/offline harness — reusable test-support), `integration_test/bs12/pending.dart` (created at GUARD-1). Shares `integration_test/bs12/nfr_harness.dart` + `nfr_test.dart` with ITEST/QUALITY. **No `lib/` product change** (D-7).
**Depends on:** — · **Blocks:** ITEST (via GUARD-2), QUALITY (shells)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| GUARD-1 | scaffold | — | ✅ Done | 7.84M | 32m 51s |
| GUARD-2 | shell | — | ⬜ Next | | |
| GUARD-3 | behavior | AC-1, AC-2 | ⬜ Todo | | |
| GUARD-4 | behavior | AC-6, AC-7, AC-8 | ⬜ Todo | | |
| GUARD-5 | behavior | AC-14, AC-15 | ⬜ Todo | | |
| GUARD-6 | behavior | AC-16, AC-17 | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the guards observe the **real** assembled app (`buildApp`) and the **real** `lib/` source tree; they add no production surface. Reused seams: `AppDependencies.mixingEngine` / `.confusionCheck` (swap injection, AC-14/15); `ColorScience` + `conversions.dart` + `deltaE00` (the colour authorities, AC-16); `lib/capture/source/` (the one platform seam, AC-17); the existing read endpoints for flow completion.
- **Source-scan guard:** a test-support utility that reads every file under `lib/` and reports, per rule, offending sites (a conversion/ΔE outside the authorities for AC-16; a `Platform.is*`/`MethodChannel`/`EventChannel`/conditional import outside `lib/capture/source/` for AC-17; a forbidden dependency for AC-7; an off-device sender for AC-8). It scans text, so it must exclude comments/strings deliberately (a doc comment naming `Platform.is` is not an offender).
- **Network-block:** `HttpOverrides.runWithHttpOverrides` (or `HttpOverrides.global`) with a client whose connect throws; the sink counts attempts. Installed around `realFlows`.
- **Spec vs architecture:** AC-1/AC-2 name "saves a project and exports it" — on `main` these exist (bs-06 projects + PDF export to the device share sheet), so all six core functions are exercisable; no deferral needed.

## Open gates

- **G-1** (spec approval) ✅ Resolved 2026-10-13 14:59 EDT: approved — Matt Quirk (spec first line amended to the approval line); GUARD-1 unblocked.
- **G-2** (approve acceptance tests) blocks **GUARD-3..GUARD-6** (all behavior phases).

## Phase GUARD-1 — scaffold

- **Kind:** scaffold
- **Target AC:** —
- **Depends on:** — (G-1 ✅) · **Blocks:** GUARD-2, QUALITY-1
- **Files:** `../Nuance-bs12` worktree; `integration_test/bs12/pending.dart`; (confirm, don't recreate) `tool/coverage_gate.dart`
- **Tasks:**
  1. From the primary checkout's committed state, create worktree `../Nuance-bs12` on branch `feat/bs-12-non-functional-requirements` off `main` @ `ecd3a9e`; `flutter pub get` in the worktree; copy/link untracked tool binaries if any.
  2. Record the baseline: `flutter analyze`, `flutter test` (unit), the current unit count, and that the existing acceptance suites pass on a booted `-d`.
  3. Confirm the coverage gate works: `tool/coverage_gate.dart` passes on the clean tree and **fails on a planted uncovered line** (revert the plant).
  4. Lay `integration_test/bs12/pending.dart`: a `const Map<String,String> pendingACs` (AC → owning phase) for the **16 automatable ACs** (AC-1,2,3,4,6,7,8,9,10,11,12,13,14,15,16,17) + a `Set<String> behaviorPhases` allow-list, keyed to `BS12_RUN_PENDING` (compile-time `--dart-define` OR host env `=1`), matching bs02/03/04. **AC-5 never enters the gate** (pure-manual, D-3).
- **Exit criteria:** worktree builds; baseline recorded; coverage gate proven both ways; `pending.dart` compiles and lists exactly the 16 ACs mapped to real phases.
- **Result (✅ Done 2026-10-13):**
  - **Gate decision folded in:** G-1 (spec approval) approved by Matt Quirk and committed to `main` @ `c17f46d` (spec banner amended; master + GUARD gate rows resolved) — this session then ran GUARD-1.
  - **Worktree:** `feat/bs-12-non-functional-requirements` created at `/Users/matthew.quirk/Nuance-bs12` off `main` @ `c17f46d` (the current tip, which carries bs-01..09 + bs-07 + bs-08 + the bs-12 PLAN + the G-1 commit — the plan's stale "@ ecd3a9e" predates those). `flutter pub get` clean; no untracked tool binaries to copy (flutter on PATH at `~/development/flutter/bin`).
  - **Baseline:** `flutter analyze` → No issues. Unit `flutter test` → **1220 passed**. Acceptance (`flutter test integration_test -d <iPhone 17 sim>` under `coord.sh with-lock`) → **188 passed, 0 assertion failures**; the run exited 1 only on a simulator `stopApp`/`terminate` teardown race (`found nothing to terminate`, NSPOSIXErrorDomain code=3) that marked `correction_test.dart`'s tests *did not complete* and hit `display_test.dart` non-fatally. Re-running `correction_test.dart` alone → **22/22 green**, confirming the race is teardown-only, not test logic. Flake recorded in the master plan's *Known flakes*.
  - **Coverage gate:** `tool/coverage_gate.dart` confirmed (not recreated) — clean tree exit 0 (`no touched lib/**.dart files vs "main"`); planted `lib/_coverage_gate_probe.dart` exit 1 (`NO COVERAGE DATA`); plant reverted, tree clean.
  - **Pending gate:** `integration_test/bs12/pending.dart` written (mirrors bs-09's) — `pendingACs` lists **exactly 16** ACs (AC-1,2,3,4,6,7,8,9,10,11,12,13,14,15,16,17) each mapped to its owning behaviour phase; `behaviorPhases` = {GUARD-3,GUARD-4,GUARD-5,GUARD-6,QUALITY-2,QUALITY-3,QUALITY-4,QUALITY-5}; every owner ∈ `behaviorPhases`; **AC-5 excluded** (pure-manual, D-3); keyed to `BS12_RUN_PENDING` (`--dart-define` or host env `=1`). `flutter analyze integration_test/bs12/` → No issues.
  - **No product code** (D-7 honoured): only `integration_test/bs12/pending.dart` added.
  - **Fix passes:** 0/3 (gates green first pass; the acceptance teardown flake is not a gate failure — isolated re-run green).
  - **Tokens / Time:** see Dashboard / master ledger (GUARD-1 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** `cd /Users/matthew.quirk/Nuance-bs12` with `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin` · `flutter analyze` · `flutter test` (unit) · `flutter test --coverage && dart run tool/coverage_gate.dart` (base ref defaults to `main`) · acceptance: `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-12-non-functional-requirements <PHASE> --wait N -- bash -c 'cd /Users/matthew.quirk/Nuance-bs12 && flutter test integration_test[/bs12/nfr_test.dart] -d <booted-udid>'` (device lane is shared — the lock is mandatory; a booted `-d` is mandatory).
  - **Frozen for GUARD-2:** `pending.dart`'s public surface (`pendingACs`, `behaviorPhases`, `runPending`, `pendingSkipReason`, `acTestWidgets`) — GUARD-2's harness builds on it; behaviour phases un-pend by deleting their `pendingACs` row.
  - **Known gaps / next:** GUARD-2 ∥ QUALITY-1 are both startable in separate sessions (disjoint files). The teardown flake will recur on full-suite runs — prefer per-file runs or isolated re-runs; real `-N` count stays the signal. Env gotchas: no `timeout` on macOS; full-suite run exceeds foreground limits → redirect to a file + background; shared device lane → always `coord.sh with-lock`.

## Phase GUARD-2 — shell: guard scaffolds

- **Kind:** shell
- **Target AC:** —
- **Depends on:** GUARD-1 · **Blocks:** ITEST-1 · **∥ QUALITY-1**
- **Files:** `integration_test/nfr/guards/source_guard.dart`, `integration_test/nfr/guards/swap_harness.dart`, `integration_test/nfr/guards/offline_guard.dart`
- **Tasks:**
  1. `source_guard.dart`: signatures + stub returning an empty offender list for each rule (`conversionOffenders()`, `deltaEOffenders()`, `platformOffenders()`, `forbiddenDependencies()`, `offDeviceSenders()`), with the authority/allow-list constants (the two colour files; `lib/capture/source/`; the forbidden-package list).
  2. `swap_harness.dart`: a helper that builds `AppDependencies` with an injected alternate `MixingEngine`/`ConfusionCheck` and runs the relevant callers — stubbed to the real injection path (no assertions yet).
  3. `offline_guard.dart`: the `networkBlock` `HttpOverrides` + attempt sink, and a `runUnderNetworkBlock(body)` helper — stub that installs the override but records nothing yet.
- **Exit criteria:** files compile; the existing suite stays green; no behaviour change; the stubs are wired so ITEST-1's smoke test can call them.

## Phase GUARD-3 — AC-1 + AC-2 offline

- **Kind:** behavior
- **Target AC:** AC-1 (full), AC-2 (full) — slice: the offline/network-block guard
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/offline_guard.dart`; `integration_test/bs12/nfr_test.dart` (un-pend AC-1, AC-2)
- **Tasks:** implement `runUnderNetworkBlock` + the attempt sink; drive every core flow (capture, readout, compare, recipe search, save project, export) through `buildApp` under the block; assert each reaches its terminal state via its read endpoint **and** zero attempts recorded; prove the `control_networkTouch` fixture throws under the block.
- **Exit criteria (gates):** unit + coverage (touched files 100%); acceptance — `BS12_RUN_PENDING` run shows `TestAC01_*` + `TestAC02_*` green and discriminating (controls fail); grade gate.
- **Acceptance gate:** un-pend AC-1, AC-2; `nfr_test.dart` green (`TestAC01_OfflineCoreFunctionsWork`, `TestAC02_NoFunctionBlocksOnConnectivity`, and all earlier ACs).

## Phase GUARD-4 — AC-6 + AC-7 + AC-8 privacy

- **Kind:** behavior
- **Target AC:** AC-6, AC-7, AC-8 (full)
- **Depends on:** ITEST-4 (G-2), GUARD-3 (shares the network-block guard) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/offline_guard.dart` (privacy assertions), `integration_test/nfr/guards/source_guard.dart` (forbidden-deps + off-device rules); `nfr_test.dart` (un-pend AC-6, AC-7, AC-8)
- **Tasks:** AC-6 — run capture+save+export under the block, assert zero network attempts + stored artefacts resolve to local paths + export bytes never leave the device. AC-7 — `forbiddenDependencies()` returns empty over the resolved pubspec/lock (control: a planted forbidden name trips it) + no account surface reachable. AC-8 — `offDeviceSenders()` returns empty (D-6; control: a planted unconsented sender trips it).
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-6, AC-7, AC-8; `TestAC06/07/08_*` + all earlier green.

## Phase GUARD-5 — AC-14 + AC-15 swappable interfaces

- **Kind:** behavior
- **Target AC:** AC-14, AC-15 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/swap_harness.dart`; `nfr_test.dart` (un-pend AC-14, AC-15); `altMixingEngine`/`altConfusionCheck` doubles (in the harness)
- **Tasks:** inject `altMixingEngine` via `AppDependencies.mixingEngine` and run recipe callers; inject `altConfusionCheck` via `AppDependencies.confusionCheck` and run CVD callers (onboarding/compare/display); assert callers produce correct results through the interface and the source guard shows **no caller references the concrete impl**; the `control_boundToConcrete` fixture fails.
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-14, AC-15; `TestAC14/15_*` + all earlier green.
- **Augments:** `TestAC14`, `TestAC15`: add the "no concrete reference" source-guard assertion once GUARD-6's scan rules exist (if GUARD-6 lands first, assert directly).

## Phase GUARD-6 — AC-16 + AC-17 one colour library + portability

- **Kind:** behavior
- **Target AC:** AC-16, AC-17 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/source_guard.dart` (real scan rules); `nfr_test.dart` (un-pend AC-16, AC-17)
- **Tasks:** implement `conversionOffenders()`/`deltaEOffenders()` (any `lib/` file computing a colour-space conversion or a ΔE outside `ColorScience`/`conversions.dart` / `deltaE00`) and `platformOffenders()` (`Platform.is*`/`MethodChannel`/`EventChannel`/conditional import outside `lib/capture/source/`), excluding comments/strings; assert zero offenders (D-4); prove `control_strayColourMath` and `control_platformDart` are listed.
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-16, AC-17; `TestAC16/17_*` + all earlier green.

### Result  <!-- filled on completion; ≤ ~20 lines -->

### Checkpoint / Handoff  <!-- filled on completion -->

- **Verification commands:** `flutter analyze` · `flutter test` · `dart tool/coverage_gate.dart` · `flutter test integration_test/bs12/nfr_test.dart -d <udid>` (default) / `--dart-define=BS12_RUN_PENDING=true` (run-pending)
