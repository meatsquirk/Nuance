# Module ITEST — acceptance integration suite

**Status:** ⏸ Awaiting review — ITEST-4 packet assembled; **G-2** *awaiting decision* (a human approves the acceptance tests before any behavior phase)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `integration_test/display_harness.dart`, `integration_test/display_test.dart`, `integration_test/bs08/pending.dart` (seeded in DISPLAY-1), reuse of `integration_test/fakes/fake_speech.dart` + `fake_haptics.dart`.
**Depends on:** all shell phases (DISPLAY-2, SETTINGS-1, SPEECH-1) · **Blocks:** every behavior phase (via G-2)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| ITEST-1 | acceptance-tests | — (harness + smoke) | ✅ Done | 8,480,396 | 16m 57s |
| ITEST-2 | acceptance-tests | AC-1..7 (pending) | ✅ Done | 14,829,254 | 1h 06m (1h 10m) |
| ITEST-3 | acceptance-tests | AC-8,9,10 (pending) | ✅ Done | 6,704,225 | 18m 11s |
| ITEST-4 | test-review | — (G-2) | ⏸ Awaiting review | 1,393,384 | 3m 12s |

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

### Result — ITEST-2 (2026-10-12)

- **Landed (test-only — no `lib/` change):** 7 pending `acTestWidgets` (AC-1..AC-7) in a new `group('bs-08 display ACs (ITEST-2)')` in `integration_test/display_test.dart`, each driven through the public surface — the harness `when…` over the shipped E2 panel / selector / slider / grayscale toggle, `h.settings` over the live `DisplayReadEndpoint`, and the rendered swatches. Added three test-only helpers: `_displayColor` (CIELAB → sRGB via the **shared** `ColorScienceImpl.toSRGB`), `_displaySwatches` (the circular-`BoxDecoration` `ColorChip` swatch colours — the only circular swatches on the Readout, so the simulation chokepoint is read without a not-yet-defined key; empty until DISPLAY-3/4 render one), and `_colorNear` (sum-of-channel tolerance, 0..1). AC-3/AC-4 grade the simulated swatch against the **independent** `referenceProjectDichromat`, never the shipped projection. AC-6 asserts a root `ColorFiltered` ancestor of the `MaterialApp` (the single D-5 root filter that greys camera + palettes + readings together — the harness opens on the Readout; the other surfaces are covered by that one filter).
- **Also fixed (scaffold guard, 1 fix pass):** the `pendingSkipReason` guard asserted the ambient-mode skip (`pendingSkipReason('AC-1')` isNotNull), which is **false under `--dart-define=BS08_RUN_PENDING=true`** — so the first run-pending run failed it. Rewrote it to drive both directions with explicit `forceRunPending` over `pendingACs.keys.first` (deterministic in either mode, robust to which AC is still pending), matching ITEST-1's stated discipline. Also corrected two cosmetic comments the grader flagged (an inaccurate "un-pended here" group header — bs-08 un-pends from the behaviour phase, not here; a stale `AC-12` reference in the reused `FakeHaptics`).
- **Red baseline (run-pending):** `+13 -5` — AC-2/AC-3/AC-4/AC-5/AC-6 FAIL on their Then naming the owning phase (see the Red baseline table); **AC-1 and AC-7 PASS — green at baseline** (SETTINGS-1's panel already shows the three controls; bs-01's label contract already shows value + label). All 11 ITEST-1 tests green in both modes after the guard fix. Default run (pending skipped): `+11 ~7: All tests passed!`.
- **Grades (fresh adversarial subagent, grid `behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md`):** ITEST-1 artifacts **15 A / 0 below A**; ITEST-2 AC tests **6 A + 1 B-pending-DISPLAY-8** (AC-7, limited per G5 — no swatch to reject "colour alone" until DISPLAY-4; augmentation row added, owner DISPLAY-8). This is the allowed test-review exception (B pending <phase> + augmentation).
- **Verification:** `flutter analyze` clean; `flutter test --coverage` **914 unit pass**; coverage gate **PASS** (ITEST-2 touched no `lib/`, so the cumulative set — the 11 bs-08 shell files — is unchanged at 100%). Integration on sim `5AB9D06D…` under the shared lock: default **11 pass / 7 skipped**; run-pending **13 pass / 5 fail** (the red baseline). Fix passes: **1/3** (the scaffold guard).
- **Tokens / Time:** see dashboard row (ledger `ITEST-2`).

### Checkpoint / Handoff — ITEST-2

- **For ITEST-3 (AC-8,9,10 — speech):** it **shares `display_test.dart`** → re-read the file before editing and append a second `group('bs-08 speech ACs (ITEST-3)')`; do not touch the ITEST-2 group. Reuse the harness speech seams (`h.speech.utterances`, `h.appSpeech`, `h.spokenOutputPanel`/`repeatControl`/`lastSpokenText`, `h.whenSpeakReading`/`whenRepeatLastSpoken`). Note `RepeatableSpeech.repeat()` is already wired (SPEECH-1), so AC-8's **render/replay** Then is what should discriminate SPEECH-2 — confirm the real red baseline, as AC-8 may be green-at-baseline like AC-1/AC-7. Fill the AC-8/9/10 rows in the Red baseline table and add the ITEST-3 section to the grade grid (keep the ITEST-1/ITEST-2 sections).
- **Pattern to copy:** `acTestWidgets('AC-n', '<scenario>', (tester) async {…})`; build the Given through `when…`, check it via `h.settings`/`h.speech`, assert the Then on the live endpoint / `FakeSpeech` log / E50 finders. Green-at-baseline → leave pending, record *green at baseline*, the behaviour phase un-pends; limited → add an augmentation row.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · device lane under the shared lock: `FNP_COORD_REPO=/Users/matthew.quirk/Nuance ~/.claude/skills/feature-next-phase/scripts/coord.sh with-lock bs-08-display-simulation-and-spoken-output <PHASE> --wait 2400 -- bash -c 'export PATH=/Users/matthew.quirk/development/flutter/bin:$PATH; cd /Users/matthew.quirk/Nuance-bs08 && flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685 [--dart-define=BS08_RUN_PENDING=true]'`. Booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`.
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`). The shared device lane was contended this session (a hung sibling run had to be cleared); expect to queue behind other sessions' `with-lock`.

## Phase ITEST-3 — AC-8,9,10 (speech) pending + red baseline

- **Kind:** acceptance-tests
- **Target AC:** AC-8,9,10 (pending) · **Depends on:** ITEST-1 · **Blocks:** ITEST-4
- **Files:** `integration_test/display_test.dart` (+ `bs08/pending.dart`)
- **Tasks:** one *pending* `acTestWidgets` per AC-8..10; red baseline; grade. Shares the test file with ITEST-2 → sequence them.
- **Exit criteria:** as ITEST-2, for the speech ACs.

### Result — ITEST-3 (2026-10-12)

- **Landed (test-only — no `lib/` change):** 3 pending `acTestWidgets` (AC-8/AC-9/AC-10) in a new `group('bs-08 speech ACs (ITEST-3)')` appended to `integration_test/display_test.dart` (the ITEST-2 group untouched — re-read first per the handoff). Each drives the *public* speech surface through the harness and reads only the one injected `FakeSpeech` (`h.speech`) + the E50 finders. **AC-8:** speak the readout (`whenSpeakReading`) → repeat via the real E50 control (`whenRepeatLastSpoken`) → assert a 2nd identical utterance; control = repeat inert before any speak. **AC-9:** fill both comparison slots through the picker, speak the whole comparison (E6), then open the Readout for slot A and speak it — assert both land in the one injected sink (`hasLength(2)`; a 2nd sink/route would leave one), distinct non-empty phrasings, `identical(appSpeech.inner, speech)`. **AC-10:** speak → 60 s idle pump + settle → panel + last-spoken text still present and unchanged; control = content-free panel before speak.
- **Harness additions (`display_harness.dart`, ITEST owns it):** `givenComparison` (boots the Comparison screen through the one production `buildApp` entry — `comparisonEntry` + a seeded `InMemorySampleSource`), the `compareSampleB` fixture (a cool blue-violet, distinct from the olive `displaySample`), and `DisplayHarness.whenChooseSample`/`whenSpeakComparison`/`whenOpenReadoutForA`; re-exported `ComparisonSlot`. The existing ITEST-1/ITEST-2 API was only extended, never changed.
- **Red baseline (run-pending):** AC-8/AC-9/AC-10 **all PASS — green at baseline** (SPEECH-1 had already wired `RepeatableSpeech.repeat()`, the E50 repeat control, and the one shared speech seam every caller resolves — comparison via its injected `speech`, the pushed readout via `AppScope.speech`). They stay pending; SPEECH-2/3/4 un-pend them + keep them green (same discipline as AC-1/AC-7). Suite now `+16 -5` run-pending (the 5 fails are the unchanged ITEST-2 display ACs AC-2..6); default `+11 ~10: All tests passed!`.
- **Grades (fresh adversarial subagent, appended to grid `behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md`):** ITEST-3 **3 A / 0 below A** — all green-at-baseline but fully discriminating (G1 Givens asserted via Slot A/B text + utterance counts; G3 AC-10 settle point + content control; G4 exact counts/identity/distinctness; G5 each rejects a plausible wrong impl; G6 one AC per test). No augmentation rows required. One optional non-blocking note for SPEECH-2 (AC-8's single-utterance design can't separate "replays last" from "replays a fixed" utterance; a 2nd distinct reading would; G5 bar already met → stays A). ITEST-1/ITEST-2 grades unchanged.
- **Verification:** `flutter analyze integration_test/` clean; `flutter test --coverage` **914 unit pass**; coverage gate **PASS** (ITEST-3 touched no `lib/` → the cumulative set — the 11 bs-08 shell files — is unchanged at 100%). Integration on sim `5AB9D06D…` under the shared lock: default **11 pass / 10 skipped**; run-pending **16 pass / 5 fail** (the red baseline). Fix passes: **0/3**.
- **Tokens / Time:** see dashboard row (ledger `ITEST-3`).

### Checkpoint / Handoff — ITEST-3

- **The acceptance stage is test-complete.** AC-1..AC-10 each have one pending `acTestWidgets` in `display_test.dart`; the whole suite grades **all A** except AC-7 (*B pending DISPLAY-8*, its augmentation row open). **Next is ITEST-4 — the test review (G-2):** assemble the packet from this module (catalogue, red baseline table, grades, fixtures, real-vs-faked) and set G-2 *awaiting decision* for a human. No AC-test phase remains; ITEST-2 and ITEST-3 both ran (shared file, sequenced).
- **Red baseline summary for the packet:** display ACs AC-2/AC-3/AC-4/AC-5/AC-6 FAIL at baseline on their Then naming DISPLAY-3/4/5/6/7; AC-1 (SETTINGS-2) + AC-7 (DISPLAY-8, limited) + AC-8 (SPEECH-2) + AC-9 (SPEECH-3) + AC-10 (SPEECH-4) are green at baseline and stay pending until their owning behavior phase un-pends them.
- **Verification commands:** unchanged — `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · device lane under the shared lock (`FNP_COORD_REPO=/Users/matthew.quirk/Nuance ~/.claude/skills/feature-next-phase/scripts/coord.sh with-lock bs-08-display-simulation-and-spoken-output <PHASE> --wait 2400 -- bash -c '… flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685 [--dart-define=BS08_RUN_PENDING=true]'`).
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`). The device lane stays contended across sessions (a sibling bs-09 ITEST-2 run held the lock this session; queued cleanly behind it).

## Phase ITEST-4 — test review (G-2)

- **Kind:** test-review
- **Target AC:** — · **Depends on:** ITEST-2, ITEST-3 · **Blocks:** every behavior phase
- **Tasks:** assemble the review packet (catalogue, red baseline, grades, fixtures, real-vs-faked) for a human. On **approved**, G-2 resolves and this phase is done; **changes requested** turns each item into an ITEST change phase before behavior, then a fresh review.
- **Exit criteria:** a human records the G-2 decision.
- **Status:** ⏸ Awaiting review (packet below; **G-2** *awaiting decision*). No code ran in this phase.

### Review packet — ITEST-4 (2026-10-12)

**What this is.** Ten pending acceptance tests (one per AC) over the fully wired bs-08 shells, to be
approved before any behaviour is coded. The suite is test-complete and grades **all A** except AC-7
(*B pending DISPLAY-8*, with a scheduled augmentation — the single allowed exception). **Approving G-2
opens all ten behaviour phases.**

**Read first (the three judgment calls a reviewer should confirm):**
1. **Independent oracle for AC-3/AC-4.** The simulated swatch is graded against `referenceProjectDichromat`
   — a *separate* in-harness Viénot transcription with **literal** published matrices (the shipped file
   inverts its matrices at runtime), so the shipped projection is never graded against itself. Only the
   colour-space `toSRGB` is deliberately shared (documented). Confirm this independence is real, not
   cosmetic.
2. **AC-6 structural proxy.** The harness opens on the Readout; the camera feed and palettes live on other
   screens. AC-6 therefore asserts a **single root `ColorFiltered` ancestor of `MaterialApp`** (D-5's one
   global filter) rather than sampling three surfaces. Confirm that the one-root-filter assertion is an
   acceptable proxy for "greys the whole app".
3. **Five tests are green at baseline** (AC-1, AC-7, AC-8, AC-9, AC-10) because their shells already behave.
   They stay pending; their behaviour phase un-pends them and must keep them green. Confirm each still
   *discriminates* a wrong impl (the catalogue's *Rejects*/control column) rather than passing vacuously —
   this is where a green-at-baseline test most often hides a weak assertion.

**Per-AC catalogue** (Given checked via the public surface → When through a real shipped control → Then +
what it Rejects):

| AC | Test (`display_test.dart`) | Given (checked) | When (real control) | Then + Rejects | Baseline | Grade |
|---|---|---|---|---|---|---|
| AC-1 | `AC-1: opens display & simulation settings` | panel absent (finder) | tap E2 entry | panel + E47 selector + E46 grayscale + theme each `findsOneWidget`. **Rejects** a surface missing any of the three, or an unreachable entry | PASS (green) | A |
| AC-2 | `AC-2: sim off = original (trichromat)` | `simulationOn == false` (live endpoint) | reading renders | exactly **1** swatch, `_colorNear` `toSRGB(displaySample)`. **Rejects** a projected/desaturated sim-off view, and (via `hasLength(1)`) a spurious alongside-pair | FAIL → DISPLAY-3 | A |
| AC-3 | `AC-3: simulate type alongside original` | settings open, `simulationOn == false`; outline protan/deutan/tritan | `whenSelectSimulation(type)` (asserts `simulationType == type`) | ≥2 swatches, one ≈ original **and** one ≈ `referenceProjectDichromat(sample,type)`. **Rejects** a no-op selector, wrong/fixed type (tritan Δ≈71 separates), or a dropped original | FAIL → DISPLAY-4 | A |
| AC-4 | `AC-4: severity slider strength` | `simulationType == deutan` | `whenSetSeverity(60)` → `simulationSeverity closeTo(0.60, 0.03)` | swatch ≈ `referenceProjectDichromat(sample,deutan,0.60)`; **control** sev 0 ≈ original. **Rejects** a slider that never reaches the projection or renders at a fixed severity | FAIL → DISPLAY-5 | A |
| AC-5 | `AC-5: grayscale clears an active sim` | `simulationType == deutan` | `whenSetGrayscale(on:true)` (settle) | `grayscale == true` **and** `simulationType == null`; **control** grayscale off keeps it null. **Rejects** both views active, and restore-on-off | FAIL → DISPLAY-6 | A |
| AC-6 | `AC-6: value-only greys the whole app` | `grayscale == true` | — | a root `ColorFiltered` **ancestor** of `MaterialApp` `findsOneWidget`; **control** off → `findsNothing`. **Rejects** greys-readings-only (descendant filter fails the ancestor check) and an always-on filter | FAIL → DISPLAY-7 | A |
| AC-7 | `AC-7: reading keeps value + label under sim` | `simulationType == deutan` | reading renders | `ValueReading` with `number == round(L)` + non-empty `word` + `find.text("55")`. **Limited (G5):** cannot yet reject "swatch with no text" until a swatch renders (DISPLAY-4) → augmentation owned by DISPLAY-8 | PASS (green, limited) | **B pending DISPLAY-8** |
| AC-8 | `AC-8: repeats the last spoken output` | **control** repeat inert + log empty; then `whenSpeakReading` → `utterances hasLength(1)`, repeat control appears | `whenRepeatLastSpoken` (E50 repeat) | `utterances hasLength(2)` **and** `last == spoken` (count + identity). **Rejects** a different/empty/no replay | PASS (green) | A |
| AC-9 | `AC-9: one consistent phrasing` | both slots filled via picker (`find.text('Slot A/B: …')`), `identical(appSpeech.inner, speech)` | `whenSpeakComparison` (E6) then `whenOpenReadoutForA` + `whenSpeakReading` | `utterances hasLength(2)` in the **one** injected sink; **control** reading ≠ comparison (distinct, non-empty). **Rejects** a second sink or a second phrasing route (would leave only 1) | PASS (green) | A |
| AC-10 | `AC-10: panel stays until the painter leaves it` | **control** panel present but `lastSpokenText` absent; `whenSpeakReading` → panel + text present | `pump(60s)` then `pumpAndSettle` | panel + `lastSpokenText` still present, `Text.data == shown`. **Rejects** a timer auto-dismiss (60s+settle clears it) and (control) an always-on vacuous pass | PASS (green) | A |

**Red baseline summary** (run-pending `--dart-define=BS08_RUN_PENDING=true`, sim `5AB9D06D…`): default run
**11 pass / 10 skipped — all passed**; run-pending **16 pass / 5 fail**. The 5 fails are exactly AC-2, AC-3,
AC-4, AC-5, AC-6, each failing on its own Then naming its owning phase (DISPLAY-3/4/5/6/7). AC-1, AC-7, AC-8,
AC-9, AC-10 are **green at baseline** (their shells already behave) and stay pending until SETTINGS-2 /
DISPLAY-8 / SPEECH-2 / SPEECH-3 / SPEECH-4 un-pend them. No test failed on a compile error, panic or harness
error. Full per-test rows in the **Red baseline** table below.

**Augmentations scheduled** (full table in *Test augmentations* below):

| AC test | Limited because | Closed by | Add |
|---|---|---|---|
| `AC-7: reading keeps value + label under sim` | green-at-baseline + G5: no simulated swatch exists until DISPLAY-4, so it cannot yet reject a simulated reading that shows a swatch with **no** value/label | **DISPLAY-8** | assert the simulated swatch is shown **alongside** the value + label ("not colour alone"), then re-grade A |

One optional, **non-blocking** note (not a rule failure, stays A): AC-8's single-utterance design cannot
separate "replays the *last*" from "replays a fixed/first" utterance; SPEECH-2 *may* speak a second distinct
reading before repeating to close the gap. Not required for the grade.

**Fixtures & real-vs-faked.** The whole app is assembled through the one production `buildApp(deps)`: real
`DisplayController`, real `projectDichromat`, real `ColorChip`/root-grayscale rendering, real
readout/comparison/recipes speech paths. **Faked infrastructure only:** `FakeSpeech` (records utterances in
order), `FakeHaptics`. Fixtures: `displaySample` (CIELAB 55/−25/30, a non-grey olive, in-gamut and clearly
shifted under every type — guard-proven), `compareSampleB` (a cool blue-violet for AC-9's slot B),
`cvdProfileFixture` (deutan, matching the panel's pre-selected default), `referenceProjectDichromat` (the
independent oracle above).

**Grade grid:** [`behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md`](../behavior-test-completeness-bs-08-display-simulation-and-spoken-output.md)
— graded by a fresh adversarial subagent that did not write the tests. **Counts: 24 A (15 ITEST-1 artifacts +
6 ITEST-2 + 3 ITEST-3) + 1 B-pending-DISPLAY-8 (AC-7).** Two cosmetic grader notes, neither grade-affecting:
a premature "un-pended here" group-header comment (AC-1/AC-7 remain in `pendingACs`), and `FakeHaptics`'s
stale "AC-12" doc-comment (haptics unused by any bs-08 AC) — both can be swept in a touching behaviour phase.

**Decision.** A human approves or requests changes:
`/feature-next-phase --gate bs-08-display-simulation-and-spoken-output G-2 approved | "<changes>"`.
On **approved**, G-2 resolves, ITEST-4 is done, and the behaviour phases open (SETTINGS-2, DISPLAY-7 and the
SPEECH chain run concurrently with the simulation chain DISPLAY-3→4→{5,6,8}). On **changes requested**, each
item becomes an ITEST change phase before behaviour, followed by a fresh review.

## Red baseline  <!-- filled by the AC-test phases (run-pending) -->

| AC | Test | Baseline outcome (run-pending) | Fails at | Owning phase | Grade |
|---|---|---|---|---|---|
| AC-1 | `AC-1: opens display & simulation settings` | **PASS — green at baseline** | SETTINGS-1 already shows the panel + E47/E46/theme; SETTINGS-2 un-pends + keeps green | SETTINGS-2 | A |
| AC-2 | `AC-2: sim off = original (trichromat)` | FAIL (expected) | Then: exactly one displayed swatch == original — **0** circular `ColorChip` swatches rendered yet (`length 0`, expected 1) | DISPLAY-3 | A |
| AC-3 | `AC-3: simulate type alongside original` | FAIL (expected) | Then: ≥2 swatches (simulated + original alongside) — **0** rendered (protan iteration; `0 >= 2` false) | DISPLAY-4 | A |
| AC-4 | `AC-4: severity slider strength` | FAIL (expected) | Then: swatch matches `referenceProjectDichromat(deutan, 0.60)` — no swatch (the `simulationSeverity == 0.60` setter check **passed**; only the render failed) | DISPLAY-5 | A |
| AC-5 | `AC-5: grayscale clears an active sim` | FAIL (expected) | Then: `simulationType == null` after grayscale on — still `CvdType.deutan` (no mutual exclusion yet) | DISPLAY-6 | A |
| AC-6 | `AC-6: value-only greys the whole app` | FAIL (expected) | Then: a root `ColorFiltered` ancestor of `MaterialApp` — **0 found** (the root `GrayscaleFilter` is inert) | DISPLAY-7 | A |
| AC-7 | `AC-7: reading keeps value + label under sim` | **PASS — green at baseline (limited)** | value + label present under deutan sim; cannot yet reject "swatch, no text" (no swatch until DISPLAY-4) → augmented by DISPLAY-8 | DISPLAY-8 | B pending DISPLAY-8 |
| AC-8 | `AC-8: the painter repeats the last spoken output` | **PASS — green at baseline** | SPEECH-1 already wired `RepeatableSpeech.repeat()` + the E50 repeat control; replay records a 2nd identical utterance now. SPEECH-2 un-pends + keeps green | SPEECH-2 | A |
| AC-9 | `AC-9: readings and comparisons are spoken through one consistent phrasing` | **PASS — green at baseline** | both the comparison speak (E6) and the carried reading speak (E7→readout) already resolve the one injected `FakeSpeech` (comparison gets `speech: speech`; pushed readout reads `AppScope.speech`) → 2 utterances in the one sink. SPEECH-3 un-pends + keeps green | SPEECH-3 | A |
| AC-10 | `AC-10: the spoken-output panel stays until the painter leaves it` | **PASS — green at baseline** | the E50 panel (SPEECH-1) has no timer — it reflects the live `SpeechScope`, so it survives a 60s idle + settle. SPEECH-4 un-pends + keeps green | SPEECH-4 | A |

## Test augmentations  <!-- pre-seeded in plan mode; confirmed by AC-test phases; closed by behavior phases -->

| AC test | Limited because | Augmented by | Add | Status |
|---|---|---|---|---|
| `AC-7: reading keeps value + label under sim` | green at baseline + limited (G5): `ValueReading` renders the value + word regardless of simulation, and no simulated swatch exists until DISPLAY-4, so the test cannot yet reject AC-7's real wrong impl — a simulated reading showing a colour swatch with **no** accompanying value/label | DISPLAY-8 | assert a simulated display swatch is shown **alongside** the value + label ("not colour alone"), then re-grade A | ⬜ Open (owner DISPLAY-8) |
