# Module GUARD — invariant guards (offline, privacy, swappable, portability)

**Status:** In progress — GUARD-1/2/3/4/5 done (AC-1/2/6/7/8/14/15 delivered); next GUARD-6 (AC-16/17 one-lib + portability)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/nfr/guards/` (source-scan, swap-harness, network-block/offline harness — reusable test-support), `integration_test/bs12/pending.dart` (created at GUARD-1). Shares `integration_test/bs12/nfr_harness.dart` + `nfr_test.dart` with ITEST/QUALITY. **No `lib/` product change** (D-7).
**Depends on:** — · **Blocks:** ITEST (via GUARD-2), QUALITY (shells)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| GUARD-1 | scaffold | — | ✅ Done | 7.84M | 32m 51s |
| GUARD-2 | shell | — | ✅ Done | 3.72M | 17m 40s |
| GUARD-3 | behavior | AC-1, AC-2 | ✅ Done | 7.42M | 9m 39s |
| GUARD-4 | behavior | AC-6, AC-7, AC-8 | ✅ Done | 11.5M | 27m 11s |
| GUARD-5 | behavior | AC-14, AC-15 | ✅ Done | 10.1M | 21m 16s |
| GUARD-6 | behavior | AC-16, AC-17 | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the guards observe the **real** assembled app (`buildApp`) and the **real** `lib/` source tree; they add no production surface. Reused seams: `AppDependencies.mixingEngine` / `.confusionCheck` (swap injection, AC-14/15); `ColorScience` + `conversions.dart` + `deltaE00` (the colour authorities, AC-16); `lib/capture/source/` (the one platform seam, AC-17); the existing read endpoints for flow completion.
- **Source-scan guard:** a test-support utility that reads every file under `lib/` and reports, per rule, offending sites (a conversion/ΔE outside the authorities for AC-16; a `Platform.is*`/`MethodChannel`/`EventChannel`/conditional import outside `lib/capture/source/` for AC-17; a forbidden dependency for AC-7; an off-device sender for AC-8; a caller bound to a concrete swap impl for AC-14/15). It scans text, so it must exclude comments/strings deliberately (a doc comment naming `Platform.is` is not an offender).
  - **ITEST-2 extended the scan signatures (stubbed) under the user's "B-pending via fixtures" decision** — GUARD-4/5/6 must implement them **honouring the planted-input args**: `conversionOffenders`/`deltaEOffenders`/`platformOffenders`/`offDeviceSenders({roots = kDefaultSourceRoots})`, `forbiddenDependencies({resolvedNames})`, and the new `concreteTypeReferences(typeName, {roots})` (+ `ruleConcreteTypeReference`). The real scan uses the default `lib/` root; the AC tests point a rule at `integration_test/nfr/fixtures/controls/` (the planted offenders `control_off_device_sender.dart`/`control_stray_colour_math.dart`/`control_platform_dart.dart`/`control_bound_to_concrete.dart`) to prove discrimination. **GUARD-4** → AC-7/8 (real pubspec-lock + off-device scans); **GUARD-6** → AC-16/17 (real conversion/ΔE/platform scans); **GUARD-5** → AC-14/15 (drive the swapped callers + the `concreteTypeReferences` no-concrete-coupling scan, using GUARD-6's scan infra — the AC-14/15 augmentation). AC-14's **dynamic** swap proof already passes (ITEST-2 drives the recipe caller through an injected alt); only the static no-concrete-reference control is owed.
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
- **Result (✅ Done 2026-10-13):**
  - Three test-support scaffolds under `integration_test/nfr/guards/`, no `lib/` change (D-7):
    - **`source_guard.dart`** — the `SourceOffender` record, four rule-id constants, the authority/allow-list constants (`conversionAuthorityFiles` = the three `lib/color_science/` files; `deltaEAuthorityFiles` = `lib/compare/difference.dart` — the shipped CIEDE2000; `nativeCaptureSeam` = `lib/capture/source/`; `forbiddenDependencyNames` = analytics/crash/account/remote-sync SDKs), and the five rule scans as empty-result stubs (`conversionOffenders`/`deltaEOffenders`/`platformOffenders` → `const []`, `forbiddenDependencies` → `const <String>[]`, `offDeviceSenders` → `const []`). Real scans: GUARD-6 (AC-16/17), GUARD-4 (AC-7/8).
    - **`offline_guard.dart`** — `NetworkAttemptSink` (inert `record()`/`reset()`/`attempts`), `NetworkBlockingOverrides extends HttpOverrides` (refuses via `NetworkBlockedException` from `createHttpClient`), and `runUnderNetworkBlock<T>(body, {sink})` installing it through `HttpOverrides.runWithHttpOverrides`. Stub installs the block but does **not** record yet — GUARD-3 wires `sink.record()` + drives every core flow.
    - **`swap_harness.dart`** — `pumpAppWithSwaps(tester, {mixingEngine, confusionCheck})` pumping the **real** `buildApp(AppDependencies(…))` with the two interfaces injected (defaults = shipped `SubtractiveMixingEngine` / `DichromatConfusionCheck`), platform sinks faked (`FakeSpeech`/`FakeHaptics`), real `ColorScienceImpl`. The real injection path AC-14/15 assert over; no assertions yet, no doubles (GUARD-5 adds the recording alternates).
  - **Verification:** `flutter analyze` → No issues (project-wide). Unit `flutter test` → **1220 passed** (baseline, no regression). Acceptance `flutter test integration_test -d <iPhone 17 sim>` under `coord.sh with-lock` → **197 passed, exit 0** (a clean full-suite run — the GUARD-1 teardown race did not recur; 197 is the un-flaked full count vs GUARD-1's flake-reduced 188). The scaffolds are **unreferenced** by any test/lib yet, so the acceptance build is unchanged by this phase; ITEST-1 wires them in.
  - **Coverage gate:** N/A — no `lib/**.dart` touched (shell adds only `integration_test/` support files).
  - **Fix passes:** 0/3 (analyze + both suites green first pass).
  - **Tokens / Time:** see Dashboard / master ledger (GUARD-2 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** unchanged from GUARD-1 — `cd /Users/matthew.quirk/Nuance-bs12` + `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test` (unit); acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-12-non-functional-requirements <PHASE> --wait N -- bash -c 'cd …/Nuance-bs12 && flutter test integration_test -d <booted-udid>'` (shared device lane → lock mandatory; booted `-d` mandatory).
  - **Frozen for ITEST-1 / the behaviour phases:** the three files' public surface —
    - `source_guard.dart`: `SourceOffender`; `conversionOffenders()`, `deltaEOffenders()`, `platformOffenders()`, `forbiddenDependencies()`, `offDeviceSenders()`; constants `conversionAuthorityFiles`, `deltaEAuthorityFiles`, `nativeCaptureSeam`, `forbiddenDependencyNames`; rule-ids `ruleStrayConversion`/`ruleStrayDeltaE`/`rulePlatformOutsideSeam`/`ruleOffDeviceSender`.
    - `offline_guard.dart`: `NetworkAttemptSink`, `NetworkBlockingOverrides`, `NetworkBlockedException`, `runUnderNetworkBlock`.
    - `swap_harness.dart`: `pumpAppWithSwaps`.
  - **Known gaps / next:** QUALITY-1 (the other stage-2 shell) is still ⬜ Next and startable now (disjoint: `integration_test/nfr/quality/` + the `lib/capture` AC-9 seam); **ITEST-1 needs BOTH GUARD-2 and QUALITY-1**. GUARD-3 (behaviour, AC-1/AC-2) wires the offline sink but is blocked on G-2 (ITEST-4). Teardown flake is intermittent — a full-suite re-run may exit 1 on it; re-run the affected file alone, the `-N` count is the signal.

## Phase GUARD-3 — AC-1 + AC-2 offline

- **Kind:** behavior
- **Target AC:** AC-1 (full), AC-2 (full) — slice: the offline/network-block guard
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/offline_guard.dart`; `integration_test/bs12/nfr_test.dart` (un-pend AC-1, AC-2)
- **Tasks:** implement `runUnderNetworkBlock` + the attempt sink; drive every core flow (capture, readout, compare, recipe search, save project, export) through `buildApp` under the block; assert each reaches its terminal state via its read endpoint **and** zero attempts recorded; prove the `control_networkTouch` fixture throws under the block.
- **Exit criteria (gates):** unit + coverage (touched files 100%); acceptance — `BS12_RUN_PENDING` run shows `TestAC01_*` + `TestAC02_*` green and discriminating (controls fail); grade gate.
- **Acceptance gate:** un-pend AC-1, AC-2; `nfr_test.dart` green (`TestAC01_OfflineCoreFunctionsWork`, `TestAC02_NoFunctionBlocksOnConnectivity`, and all earlier ACs).
- **Result (✅ Done 2026-10-14):**
  - **The one change is the sink increment** (D-7 honoured — no `lib/` product code): `NetworkBlockingOverrides.createHttpClient` (`integration_test/nfr/guards/offline_guard.dart`) now calls `sink.record()` *before* throwing `NetworkBlockedException`, so the block is still impassable but every refused attempt is observable. The GUARD-2 doc-comments were updated to state the increment landed. `runUnderNetworkBlock` + `NetworkAttemptSink` were already in place (GUARD-2); no new flow-driving code was needed — ITEST-2 already wrote AC-1/AC-2 to sweep every core flow under the block and assert the terminal state + zero attempts, with the deliberate-`HttpClient()` control.
  - **Un-pended** AC-1, AC-2 — deleted their rows from `integration_test/bs12/pending.dart` (gate now holds 14 ACs).
  - **Two dependent non-AC tests updated** (recorded here per the test-change rule — both were written against the GUARD-2 *inert-sink* contract that GUARD-3 deliberately ends): (a) the ITEST-1 wiring test `offline guard runs a body and refuses any network touch` flipped its final assertion from `sink.attempts == 0` to `== 1` (the refused touch is now recorded) — reason: GUARD-2's comment explicitly scheduled the increment for GUARD-3; (b) the `pending gate` test's `expectedPending` set dropped AC-1/AC-2 and its count `16 → 14`, with added `containsKey` negatives, and its ambient-path example switched from the now-un-pended `AC-1` to the still-pending `AC-3`. No AC test was weakened.
  - **Verification:** `flutter analyze` → No issues. Unit `flutter test` → **1228 passed** (no regression). Acceptance `flutter test integration_test/bs12/nfr_test.dart -d <iPhone 17 sim>` under `coord.sh with-lock`, **default mode** → **17 passed / 14 skipped / exit 0** (AC-1 + AC-2 now run and pass; AC-3..AC-17 skip as pending; the wiring test + the 14-AC pending-gate test pass). The teardown flake did not recur.
  - **Coverage gate:** N/A — no `lib/**.dart` touched (only `integration_test/` files: `offline_guard.dart`, `pending.dart`, `nfr_test.dart`).
  - **Grade gate:** a fresh independent grader re-graded the two newly un-pended tests (AC-1, AC-2) against G1–G6 with the ITEST-2 grid as prior → **2 A / 0 B pending / 0 ordinary B**. AC-1/AC-2 hold A for the *stronger* reason now: the `sink.attempts > 0` control is live within this phase (GUARD-3 is their own owner), so no augmentation is owed — the live block + the counting control discriminate today. Grid appended to `behavior-test-completeness-bs-12-non-functional-requirements.md` (GUARD-3 §).
  - **Fix passes:** 0/3 (analyze + unit + acceptance + grade all green first pass).
  - **Tokens / Time:** see Dashboard / master ledger (GUARD-3 row).
- **Checkpoint / Handoff:**
  - **Verification commands:** unchanged — `cd /Users/matthew.quirk/Nuance-bs12` + `export PATH=$PATH:/Users/matthew.quirk/development/flutter/bin`; `flutter analyze`; `flutter test` (unit); acceptance via `FNP_COORD_REPO=/Users/matthew.quirk/Nuance coord.sh with-lock bs-12-non-functional-requirements <PHASE> --wait N -- bash -c 'cd …/Nuance-bs12 && flutter test integration_test/bs12/nfr_test.dart -d <booted-udid>'` (shared device lane → lock mandatory; booted `-d` mandatory; full-suite runs may hit the teardown flake → run the affected file alone).
  - **Frozen for later phases:** `offline_guard.dart`'s public surface is final — `NetworkBlockingOverrides.createHttpClient` now records-then-refuses, so **GUARD-4 (AC-6) inherits a live counting sink** (its `sink.attempts > 0` control already greens; GUARD-4 only un-pends AC-6 + adds the AC-7/AC-8 source-scan privacy work). In run-pending mode AC-6 now passes early too (the sink increment was its remaining red assertion), but AC-6 stays pending until GUARD-4 un-pends it with AC-7/AC-8.
  - **Known gaps / next:** GUARD-4/5/6 + QUALITY-2/3/4/5 remain. GUARD-4/5/6 share `source_guard.dart` + `nfr_test.dart` → sequence them (one phase/session, `/clear` between). QUALITY-2 (`lib/capture` only) may run ∥ a GUARD phase in a `--parallel` worktree session. No `lib/` change in GUARD-3, so no cross-feature regression was owed.

## Phase GUARD-4 — AC-6 + AC-7 + AC-8 privacy

- **Kind:** behavior
- **Target AC:** AC-6, AC-7, AC-8 (full)
- **Depends on:** ITEST-4 (G-2), GUARD-3 (shares the network-block guard) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/offline_guard.dart` (privacy assertions), `integration_test/nfr/guards/source_guard.dart` (forbidden-deps + off-device rules); `nfr_test.dart` (un-pend AC-6, AC-7, AC-8)
- **Tasks:** AC-6 — run capture+save+export under the block, assert zero network attempts + stored artefacts resolve to local paths + export bytes never leave the device. AC-7 — `forbiddenDependencies()` returns empty over the resolved pubspec/lock (control: a planted forbidden name trips it) + no account surface reachable. AC-8 — `offDeviceSenders()` returns empty (D-6; control: a planted unconsented sender trips it).
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-6, AC-7, AC-8; `TestAC06/07/08_*` + all earlier green.

### Result

Landed the real GUARD-4 scans in `source_guard.dart` (+ `dart:io`): `forbiddenDependencies({resolvedNames})` reads `pubspec.lock` via `resolvedDependencyNames`/`parseLockPackageNames` (top-level `packages:` keys) when no names are passed, else intersects the passed set with `forbiddenDependencyNames`; `offDeviceSenders({roots})` → shared `_scanSource` walks `.dart` files under each root, runs `maskCommentsAndStrings` (blanks `//`+`/* */`+single/double/triple strings, honours `\` escapes + the `r` raw prefix, preserves newlines) and matches `_offDeviceSendPatterns` (HttpClient / sockets / websocket / datagram / `http.*`). Un-pended AC-6/AC-7/AC-8 in `pending.dart` (gate 14→11). **No `lib/` change** (D-7) ⇒ coverage gate N/A (nothing touched). Augmentations TestAC07 + TestAC08 closed (AC-7/AC-8 *B pending GUARD-4* → A). **Test changes (recorded):** 3 forward-looking control comments corrected to present/past tense + AC-6 sink attribution GUARD-4→GUARD-3; the ITEST-1 wiring test comment noting "GUARD-4/6 fill the real scans"; added one never-pending wiring test (`the GUARD-4 source scans exclude comments / strings and parse the lock`) exercising the masker + lock parser + missing-lockfile branch. No AC test weakened.
- **Verification (host `-d flutter-tester`, cwd = repo root — see Checkpoint):** `flutter analyze` clean; `flutter test test/` **1228 pass / 0 fail** (no regression); acceptance default `flutter test integration_test/bs12/nfr_test.dart -d flutter-tester` → **+21 / ~11 skip / exit 0** (AC-6/7/8 pass, controls discriminate); run-pending (`--dart-define=BS12_RUN_PENDING=true`) → **+24 / −8** (the 8 still-unbuilt ACs AC-9/10/11/12/14/15/16/17 = intact red baseline; AC-3/4/13 green-at-baseline).
- **Grade gate:** fresh independent grader (prior grid as context) → **3 A / 0 B pending / 0 ordinary B** (AC-6 A; AC-7/AC-8 close B-pending → A). Grid appended to `behavior-test-completeness-…md` (GUARD-4 §).
- **Fix passes:** 0/3 (first full run green; the one earlier red was an iOS-sim run of the file-reading controls — resolved by running on `-d flutter-tester`, not a code fix).
- **Tokens / Time:** see Dashboard / master ledger (GUARD-4 row).

### Checkpoint / Handoff

- **Frozen for later phases:** `source_guard.dart` now exposes shared scan machinery — `maskCommentsAndStrings(source)`, `_scanSource(roots, rule, patterns)`, `resolvedDependencyNames({lockPath})`, `parseLockPackageNames(text)` — which **GUARD-6 reuses** for `conversionOffenders`/`deltaEOffenders`/`platformOffenders` (still stubs) and **GUARD-5** for `concreteTypeReferences`. Add new rule patterns + call `_scanSource`; honour each scan's authority/allow-list constants (comments/strings already excluded).
- **Verification environment (IMPORTANT):** the bs-12 acceptance suite runs on **`-d flutter-tester`** (host VM), NOT an iOS sim — the source scans read the repo tree through `dart:io` (`cwd = repo root`), which the sim sandbox lacks. `flutter test integration_test/bs12/nfr_test.dart -d flutter-tester` runs all tests on the host with no Xcode build and **needs no device lane** (so no `coord.sh with-lock`). A bare run with no `-d` still gives zero tests / false green — always pass `-d flutter-tester`. Master plan line 81 updated.
- **Known gaps / next:** GUARD-5 (AC-14/15), GUARD-6 (AC-16/17), QUALITY-2/3/4/5 remain. GUARD-5/6 share `source_guard.dart`+`nfr_test.dart` → sequence (one phase/session, `/clear` between). G-3 (AC-5 device frame rate + AC-3/4 target timings) stays a SIGNOFF-1 manual gate.

## Phase GUARD-5 — AC-14 + AC-15 swappable interfaces

- **Kind:** behavior
- **Target AC:** AC-14, AC-15 (full)
- **Depends on:** ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `integration_test/nfr/guards/swap_harness.dart`; `nfr_test.dart` (un-pend AC-14, AC-15); `altMixingEngine`/`altConfusionCheck` doubles (in the harness)
- **Tasks:** inject `altMixingEngine` via `AppDependencies.mixingEngine` and run recipe callers; inject `altConfusionCheck` via `AppDependencies.confusionCheck` and run CVD callers (onboarding/compare/display); assert callers produce correct results through the interface and the source guard shows **no caller references the concrete impl**; the `control_boundToConcrete` fixture fails.
- **Exit criteria (gates):** unit + coverage; acceptance green + discriminating; grade gate.
- **Acceptance gate:** un-pend AC-14, AC-15; `TestAC14/15_*` + all earlier green.
- **Augments:** `TestAC14`, `TestAC15`: add the "no concrete reference" source-guard assertion once GUARD-6's scan rules exist (if GUARD-6 lands first, assert directly). **Both closed this phase** — GUARD-5 landed the scan itself (it did not need GUARD-6's rules).

### Result

Landed the real `concreteTypeReferences(typeName, {roots})` scan in `source_guard.dart`, reusing GUARD-4's shared `maskCommentsAndStrings` + file-walk machinery: it flags a word-boundary `\b<type>\b(?!\s*\()` match (a type-position *coupling*) while excluding the DI-default constructor call `const X()` (the `(?!\s*\()` lookahead), `import`/`export` directive lines, and the type's own definition file (`\b(?:class|mixin|enum|extension)\s+<type>\b`). **AC-14** was already dynamically proven at baseline (the recipes flow drives the injected `RecordingMixingEngine` through `MixingEngine.inverse`); GUARD-5 added the static half (empty `lib/` sweep + `control_bound_to_concrete` flagged). **AC-15** gained a real CVD-caller driver: new harness `nfrCvdCallerProject` (two samples), `givenPaletteWithCvdCallerProject`, and `whenOpenProject` (extracted from `whenOpenAndExportProject`) — opening the two-sample project renders the open-project view, which reads `ProjectController.confusionPairs` → `flagConfusionPairs` → `ConfusionCheck.confusable` on the injected `RecordingConfusionCheck` (`confusableCalls > 0`), plus the static sweep + new `control_bound_to_concrete_cvd.dart` control. Un-pended AC-14/AC-15 in `pending.dart` (gate 11→9); updated the pending-gate guard test's expected set (`length 9`, AC-14/15 asserted absent). **No `lib/` change** (D-7) ⇒ coverage gate N/A (nothing touched). Augmentations TestAC14 + TestAC15 closed. No AC test weakened.
- **Verification (host `-d flutter-tester`, cwd = repo root):** `flutter analyze integration_test/` clean; `flutter test test/` **1228 pass / 0 fail** (no regression); acceptance default `flutter test integration_test/bs12/nfr_test.dart -d flutter-tester` → **+23 / ~9 skip / exit 0** (AC-14/15 now run + pass, controls discriminate); run-pending (`--dart-define=BS12_RUN_PENDING=true`) → **+26 / −6** (the 6 still-unbuilt ACs AC-9/10/11/12/16/17 = intact red baseline; AC-3/4/13 green-at-baseline).
- **Grade gate:** fresh independent grader (prior grid as context) → **2 A / 0 B pending / 0 ordinary B** (AC-14/AC-15 close *B pending GUARD-5* → A). Grid appended to `behavior-test-completeness-…md` (GUARD-5 §).
- **Fix passes:** 0/3 (first full run green bar the pending-gate guard's expected-set, updated as part of the un-pend — not a behaviour fix).
- **Tokens / Time:** see Dashboard / master ledger (GUARD-5 row).

### Checkpoint / Handoff

- **Frozen for later phases:** `source_guard.dart` now exposes the real `concreteTypeReferences(typeName, {roots})` alongside GUARD-4's `forbiddenDependencies`/`offDeviceSenders`; only `conversionOffenders`/`deltaEOffenders`/`platformOffenders` remain GUARD-2 stubs for **GUARD-6** (AC-16/17), which reuses the same `maskCommentsAndStrings` + walk pattern (add rule patterns, honour the authority/allow-list constants). New harness vocabulary `nfrCvdCallerProject` / `givenPaletteWithCvdCallerProject` / `whenOpenProject` is available to later phases. New control fixture `control_bound_to_concrete_cvd.dart` sits beside `control_bound_to_concrete.dart` under `integration_test/nfr/fixtures/controls/`.
- **Verification environment:** unchanged from GUARD-4 — the whole bs-12 acceptance file runs on **`-d flutter-tester`** (host VM), never an iOS sim; the source scans read the repo tree through `dart:io` (cwd = repo root). A bare run with no `-d` gives zero tests / false green.
- **Known gaps / next:** GUARD-6 (AC-16/17), QUALITY-2/3/4/5 remain. GUARD-6 shares `source_guard.dart` + `nfr_test.dart` + `pending.dart` with the GUARD line → sequence (one phase/session, `/clear` between). QUALITY-2 (`lib/capture` only) may run ∥ GUARD-6 in a `--parallel` worktree session. G-3 (AC-5 device frame rate + AC-3/4 target timings) stays a SIGNOFF-1 manual gate.

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
