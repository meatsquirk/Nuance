# Module ITEST — acceptance integration suite

**Status:** In progress — ITEST-1 done (harness + fixtures + independent reference + smoke + guards); next ITEST-2 (AC-1..7 pending), which shares `display_test.dart` with ITEST-3 (run them sequentially)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/display_harness.dart`, `integration_test/display_test.dart`, `integration_test/bs08/pending.dart` (seeded in DISPLAY-1), reuse of `integration_test/fakes/fake_speech.dart` + `fake_haptics.dart`.
**Depends on:** all shell phases (DISPLAY-2, SETTINGS-1, SPEECH-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 8,480,396 | 16m 57s |
| ITEST-2 | acceptance-tests | AC-1..7 (pending) | ⬜ Todo | | |
| ITEST-3 | acceptance-tests | AC-8,9,10 (pending) | ⬜ Todo | | |
| ITEST-4 | test-review | — (G-2) | ⬜ Todo | | |

## Interface reconciliation

- **Boundary:** the whole app assembled through `buildApp(deps)` — real `DisplayController`, real `projectDichromat`, real `ColorChip`/root-grayscale rendering, real readout/comparison/recipes speech paths. Faked infrastructure only: `FakeSpeech`, `FakeHaptics`. The simulated colour (AC-3/AC-4) is graded against an **independent** in-harness `referenceProjectDichromat`, never the shipped projection.
- **Observation points:**
  - AC-1 → keyed finders for the settings entry (E2) and the panel's three controls (E46/E47/E48 + theme).
  - AC-2/AC-3/AC-4/AC-7 → the rendered swatch colours (original + simulated, read off `ColorChip`/`Container` decoration) + `DisplayReadEndpoint` (`simulationType`, `simulationSeverity`); AC-3/AC-4 graded vs `referenceProjectDichromat`.
  - AC-5 → `DisplayReadEndpoint` (`simulationType == null` after grayscale on) + the root grayscale filter active.
  - AC-6 → sampled rendered colours of the camera surface, a palette swatch and a reading are all achromatic (root saturation-0 filter).
  - AC-8/AC-9 → `FakeSpeech` log (utterance count + text equality; both reading and comparison recorded by the one sink).
  - AC-10 → the spoken-output panel (E50) still found after a long pump + settle.
- **Pending gate:** `bs08/pending.dart` exposes `acTestWidgets`, `pendingACs` and `pendingSkipReason`; a pending AC is skipped by default and runs under `--dart-define=BS08_RUN_PENDING=true`. Un-pend = delete that AC's row (its owning behavior phase does this).

## Phase ITEST-1 — harness + fixtures + pending gate + smoke

- **Kind:** acceptance-tests
- **Target AC:** — · **Depends on:** SPEECH-1 · **Blocks:** ITEST-2, ITEST-3
- **Files:** `integration_test/display_harness.dart`, `integration_test/display_test.dart`, `integration_test/bs08/pending.dart`
- **Tasks:** build the Given/When/Then vocabulary over the wired shells; the fixtures (incl. `referenceProjectDichromat`); re-export the pending gate + fakes; a never-pending smoke test proving the shells wire end to end (settings open, controller reachable, speech wrapped), plus guard tests over the pending gate + fixtures.
- **Exit criteria:** suite green with all 10 ACs pending (skipped) by default; smoke + guards pass; `-d <udid>` documented.

### Result — ITEST-1 (2026-10-12)

- **Landed (test-only — no `lib/` change):** `integration_test/display_harness.dart` — the bs-08 Given/When/Then vocabulary + fixtures + independent reference, re-exporting `bs08/pending.dart` + the fakes so an AC test imports only this file. `givenDisplay(tester, {sample, cvdProfile, initialSettings})` boots the **real** app through the one production `buildApp` on the Readout for the injected sample, injecting a recording `FakeSpeech`/`FakeHaptics`, the real `ColorScienceImpl`, the painter's `cvdProfile` and an app-wide `DisplayController` (so a scenario can start with a simulation set and the Thens read the live controller). `DisplayHarness` exposes `settings` (via `DisplayReadEndpoint`), `appSpeech` (the one `RepeatableSpeech`, `.inner == speech`), finders for the E2 entry / panel / E46·E47·E48 / theme / E50 panel·repeat·last-spoken / readout speak, and `when…` actions (`whenOpenSettings`/`whenCloseSettings`/`whenSelectSimulation`/`whenSetSeverity`/`whenSetGrayscale`/`whenSpeakReading`/`whenRepeatLastSpoken`) that drive the real shipped controls. Fixtures: `displaySample` (`DISPLAY_SAMPLE_LAB` = CIELAB (55, −25, 30), a muted yellow-green, sRGB ≈ (105,142,78) — non-grey and shifts under every type while staying in gamut), `cvdProfileFixture` (deutan). `referenceProjectDichromat(lab, type, {severity})` — an **independent** Viénot transcription (literal published matrices, not run-time-inverted like the shipped file) + `labDistance`.
- **`display_test.dart`:** kept the 3 scaffold guards; added 6 fixture guards (reference identity at sev 0; grey stays grey; idempotent at full sev; clearly shifts the display sample for every type; near-black sub-knee branch finite; `labDistance` zero/positive) and 2 never-pending smoke tests (default settings via the read endpoint + E2 opens the panel with all three controls; the one app-wide speech wraps the injected sink, the readout speaks through it and the E50 panel reflects it). All 10 ACs remain pending/skipped (ITEST-2/3 register them).
- **Verification:** `flutter analyze` clean (whole repo); `flutter test --coverage` = **914 unit pass**; coverage gate **PASS** — ITEST-1 touched no `lib/` file, so the gate's cumulative set (11 bs-08 shell files vs `main`) is unchanged at 100%. Integration suite on sim `5AB9D06D…` under the device lock: **11/11 pass** (3 scaffold + 6 guard + 2 smoke), 0 ACs un-pended. Scaffold-test discipline met (no vacuous passes — guards assert real model properties and loop over the fixed `CvdType.values`; honest comments; deterministic — `pumpAndSettle`, no sleeps). No AC tests written ⇒ no red baseline / grade grid this phase (ITEST-2/3). Fix passes: 0/3.
- **Tokens / Time:** see dashboard row (ledger `ITEST-1`).

### Checkpoint / Handoff — ITEST-1

- **Frozen for ITEST-2 / ITEST-3:** import `display_harness.dart` (it re-exports `bs08/pending.dart` + the fakes). Register each AC with `acTestWidgets('AC-n', '<slug>', (tester) async { … })`. Build the Given with `givenDisplay(tester, …)`; drive the When through `DisplayHarness.when…`; read the Then through `h.settings` (type/severity/grayscale), the rendered swatch colour (ITEST-2 reads the `ColorChip`/`Container` decoration once DISPLAY-3/4 render it) graded vs `referenceProjectDichromat(displaySample.coordinates, type, severity)` → convert to sRGB with the real `colorScience.toSRGB` (the colour-space conversion is shared; only the **projection** is independent), `h.speech.utterances` / `h.appSpeech`, and the E50 finders. `whenSetSeverity(percent)` taps the slider at the fractional position — assert the resulting `simulationSeverity` within a small tolerance, and refine the interaction if the shipped slider needs it. The two AC-test phases **share `display_test.dart` → run sequentially** (not in parallel).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · device lane under the shared lock: `FNP_COORD_REPO=/Users/matthew.quirk/Nuance ~/.claude/skills/feature-next-phase/scripts/coord.sh with-lock bs-08 <PHASE> --wait 900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs08 && flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'` (default; add `--dart-define=BS08_RUN_PENDING=true` for the run-pending / red baseline). Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH; booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase ITEST-2 — AC-1..7 (display) pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-1..AC-7 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/display_test.dart` (+ `bs08/pending.dart`)
- **Tasks:** one *pending* `acTestWidgets` per AC-1..7 per the catalogue; record each one's run-pending red baseline (where it fails) in **Red baseline** below; grade each against grade-A design.
- **Exit criteria:** suite green with the new tests pending; run-pending shows each failing on its Then / named Given precondition; grade gate passed. **Runs sequentially with ITEST-3** (shared test file).

## Phase ITEST-3 — AC-8,9,10 (speech) pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-8,9,10 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/display_test.dart` (+ `bs08/pending.dart`)
- **Tasks:** one *pending* `acTestWidgets` per AC-8..10; red baseline; grade. Shares the test file with ITEST-2 → sequence them.
- **Exit criteria:** as ITEST-2, for the speech ACs.

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue, red baseline, grades, fixtures, real-vs-faked) for a human. On **approved**, G-2 resolves and this phase is done; **changes requested** turns each item into an ITEST change phase before behavior, then a fresh review.
- **Exit criteria:** a human records the G-2 decision.

## Red baseline  <!-- filled by the AC-test phases (run-pending) -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | TestAC01_OpenDisplaySettings | FAIL (expected) | Then: three controls shown / Given: no settings surface (SETTINGS-2) | SETTINGS-2 | — |
| AC-2 | TestAC02_SimOffTrichromat | FAIL (expected) | Then: displayed == original identity path | DISPLAY-3 | — |
| AC-3 | TestAC03_SimulateTypeAlongsideOriginal | FAIL (expected) | Then: projected swatch + original alongside | DISPLAY-4 | — |
| AC-4 | TestAC04_SeveritySlider | FAIL (expected) | Then: render at severity 0.60 | DISPLAY-5 | — |
| AC-5 | TestAC05_GrayscaleClearsSimulation | FAIL (expected) | Then: grayscale on ⇒ sim off | DISPLAY-6 | — |
| AC-6 | TestAC06_GrayscaleWholeApp | FAIL (expected) | Then: camera + palettes + readings achromatic | DISPLAY-7 | — |
| AC-7 | TestAC07_ReadingKeepsValueAndLabel | FAIL (expected) | Then: value + label present under sim | DISPLAY-8 | — |
| AC-8 | TestAC08_RepeatSpokenOutput | FAIL (expected) | Then: identical utterance replayed | SPEECH-2 | — |
| AC-9 | TestAC09_OneConsistentPhrasing | FAIL (expected) | Then: both via the one sink | SPEECH-3 | — |
| AC-10 | TestAC10_PanelNeverAutoDismisses | FAIL (expected) | Then: panel present after long pump | SPEECH-4 | — |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| — | none pre-seeded: each AC test discriminates at baseline on its own Then or a Given precondition naming its single owning behavior phase | — | — | — |
