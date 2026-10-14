# bs-11 Accessibility conformance — Sign-off packet, round 1

**Feature:** Accessibility conformance (`specs/bs-11-accessibility-conformance.feature`)
**Branch / worktree:** `feat/bs-11-accessibility-conformance` · `/Users/matthew.quirk/Nuance-bs11`
**At code:** `254d366` (GATE-4; SIGNOFF-1 adds no product code)
**Base:** `main` @ `0900d44` (bs-08 merged)
**Decision command:** `/feature-next-phase --signoff bs-11 approved | changes "<items>"`

## What this packet is
All **16** build phases are done; the behaviour stage delivered every one of the **10 automated ACs** (AC-1..9, AC-11). This is the sign-off packet: a fresh whole-suite verification, an independent fresh re-grade, the cost rollup, the per-AC walkthrough, and the two **pure-manual gates** (AC-10 eyes-free walkthrough → G-3; AC-12 on-device VoiceOver-vs-TalkBack parity → G-4) that a human performs and records here.

## Verification (fresh, this session, from the feat/bs-11 worktree)
- **Static:** `flutter analyze` — **No issues found**.
- **Unit + coverage:** `flutter test --coverage` — **1048/1048 pass**. Coverage gate `dart run tool/coverage_gate.dart main` — **100% line coverage on all 18 touched lib files** (PASS).
- **Full cross-feature regression:** `flutter test integration_test -d <iPhone 17 sim>` — **192/192 pass, exit 0** (every feature's acceptance suite, bs-01..bs-11; bs-11 contributes all 10 AC tests in default mode, no skips).
- **This feature's acceptance suite:** default mode **green, pending set empty (0 skips)**; run-pending mode (`--dart-define=BS11_RUN_PENDING=true`) **19/19 pass, exit 0** — identical now that nothing is pending.
- Runs taken on a booted iPhone 17 sim (`-d` mandatory — no device ⇒ false green) through the machine-wide verify lock (`coord.sh with-lock`).

## Grade (fresh adversarial whole-suite re-grade, SIGNOFF-1)
Independent subagent, G1–G6 rubric, given the GATE-4 grid, asked to justify any downgrade against a named rule. Grid: `behavior-test-completeness-bs-11-accessibility-conformance.md`.
**Counts: 10 A / 0 B.** Every automated AC test is grade A. Re-verified AC-1..9 were not weakened or masked by the later GATE-3/GATE-4 changes (`acceptanceDecision`/`recordedLevel`/`WcagThresholds`/`scaling.dart`): each rides on the complete `ConformanceResult.passed`, never a single rule; the `scaling.dart` literal→constant swap is numerically identical; the 8th aggregate rule is non-destructive. One non-blocking hardening carried (AC-9 could pin `control_partialFail.failing` to exactly `{tapTarget48}`) — not required, not a downgrade.

## Per-AC result
| AC | Scenario | Test (integration) | Status |
|---|---|---|---|
| AC-1 | Every colour-coded element carries a non-colour cue | `TestAC01_ColourCarriesNonColourCue` | ✅ automated, A |
| AC-2 | A status is never a bare colour dot | `TestAC02_StatusNotBareColourDot` | ✅ automated, A |
| AC-3 | 200% font scaling does not break the layout | `TestAC03_FontScale200NoBreak` | ✅ automated, A |
| AC-4 | Interactive targets ≥ 48dp | `TestAC04_TapTargetMin48` | ✅ automated, A |
| AC-5 | Text meets WCAG 2.2 AA contrast | `TestAC05_ContrastFloorAA` | ✅ automated, A |
| AC-6 | Every control exposes a meaningful label | `TestAC06_ControlHasMeaningfulLabel` | ✅ automated, A |
| AC-7 | Eyes-free walkthrough completes (automated, semantics-only, D-6) | `TestAC07_EyesFreeWalkthroughCompletes` | ✅ automated, A |
| AC-8 | Nothing auto-dismisses / no time limit | `TestAC08_NothingAutoDismisses` | ✅ automated, A |
| AC-9 | A feature failing the automated check is not accepted | `TestAC09_FailedAutomatedCheckNotAccepted` | ✅ automated, A |
| AC-10 | A feature failing the **manual** eyes-free walkthrough is not accepted | **manual gate G-3 — no automated test (D-2)** | ⏸ pending human gate |
| AC-11 | WCAG 2.2 AA is the recorded floor | `TestAC11_RecordedFloorIsWcag22AA` | ✅ automated, A |
| AC-12 | Eyes-free passes under VoiceOver as under TalkBack (on-device) | **manual gate G-4 — no automated test (D-2)** | ⏸ pending human gate |

## Manual walkthrough for the reviewer (how to see each rule working)
Launch the app on a booted device from the worktree: `flutter run -d <device>`. The acceptance suite is the living demonstration of the automated check: `flutter test integration_test/bs11/accessibility_test.dart -d <booted-udid>`.

- **No meaning in colour alone (AC-1/AC-2):** every colour-coded element (`ColorChip`, `StatusBadge`, provenance badges) shows a text label / icon / value beside the colour — never a bare dot. The `colourCue` + `noBareDot` rules flag any colour-bearing widget with no labelled sibling; the `control_bareDot` fixture proves they discriminate.
- **Size & scaling floor (AC-3/AC-4/AC-5):** set the OS font size to 200% — layouts reflow (Row→Wrap) and nothing overflows (`fontScale200` rule; `control_overflow200` fails deterministically, box-height-scaled). Every interactive target is ≥ 48dp (`AppTheme` `MaterialTapTargetSize`; `tapTarget48`; `control_smallTarget` fails). Text clears WCAG 2.2 AA contrast (`AppTheme` AA scheme, pinned by unit test; `textContrastGuideline`; `control_lowContrast` fails).
- **Screen-reader operation (AC-6/AC-7):** turn on the screen reader; every control announces a meaningful label (`meaningfulLabel` rule; `control_unlabelled` fails). A core task (Readout → speak) completes by semantic label + `SemanticsAction` only, no coordinates (`eyesFree` driver, D-6).
- **Nothing time-limited (AC-8):** an `AccessibleNotice` stays put while the painter waits; advance the clock past any default dismiss window and it is still present (`noTimeout` rule, real 10s fake-clock settle; `control_autoDismiss`'s SnackBar is gone — rule fails there).
- **Gated on every feature (AC-9/AC-11):** `acceptanceDecision` rejects any result with ≥1 failing rule (two disjoint single-failure controls prove it is not a single-rule check); `recordedLevel` records `aa22` only for a fully-passing result, with the thresholds pinned equal to the WCAG 2.2 AA numbers the rules enforce.

## The two pure-manual gates (D-2) — what the reviewer performs and records here
- **G-3 / AC-10 — manual eyes-free walkthrough.** With a live screen reader (TalkBack or VoiceOver), complete a core task end-to-end without looking at the screen. Pass ⇒ AC-10 accepted; fail ⇒ feature not accepted. **No automated test exists by design (D-2);** this is a human judgment.
- **G-4 / AC-12 — on-device VoiceOver-vs-TalkBack parity.** Run the same eyes-free walkthrough under VoiceOver on iOS reference hardware and confirm it passes as it does under TalkBack. The repo has no device/VoiceOver CI (D-8), so this is performed and recorded on hardware at sign-off.

## Known gaps / deferred (named, not hidden)
- **AC-10 & AC-12 are pure-manual gates (D-2)** — closed by user acceptance here with the gap named; never recorded as passing automated gates.
- **No device/VoiceOver CI (D-8)** — acceptance suites run locally on a booted device; wiring the automated check into CI as a blocking cross-feature gate is a repo-wide follow-on.
- **Sweep scope (D-1)** — bs-11 ships the reusable mechanism + swept every screen present on `main` at the branch point; features merged after the branch (bs-07, bs-10) self-gate per the SI, and must rebase onto the shared `lib/app/theme.dart` + `lib/widgets/` when bs-11 merges.
- **Non-blocking AC-9 hardening** (pin `control_partialFail.failing` to exactly `{tapTarget48}`) — optional, deferred; the test already discriminates via two disjoint single-failure controls.
- **Cost attribution** — `ac_cost.py`'s direct-vs-shared split is unavailable due to a plan-format/tool mismatch (full-id Phase cells, e.g. `A11Y-2`, vs the tool's bare-number expectation); the feature total, per-type split and fully-loaded per-AC share are correct. See the cost file's caveat.

## Open flakes
- `integration suite — no -d <udid>` (false green without a booted device): mitigated by always passing `-d`; carried, repo-wide.
- `coverage_gate — const-constructor line`: ✅ closed during the behaviour stage (A11Y-2 / A11Y-4) via runtime constructor invocations.

## Cost
See [`signoff/cost-per-ac-round-1.md`](cost-per-ac-round-1.md).

**Feature total: $143.15** (163,175,938 tokens over 21 sessions, API list rates as of 2026-09-25). By type: input $0.01 · cache write $37.88 · cache read $78.88 · output $26.37. **Span:** 2026-10-13 05:14 EDT → 2026-10-14 12:33 EDT — **Σ wall 9h 13m, Σ active 6h 30m**. Fully-loaded per-AC share ≈ $11.93 (even 1/12). Direct-vs-shared breakdown unavailable (tool/plan-format mismatch — see the cost file's caveat).

## Recommendation
On the automated axis the feature is clear: all 10 automated ACs delivered and graded A, full regression green, 100% coverage on touched code. The only items outstanding are the two **inherently human/device** gates (G-3 AC-10, G-4 AC-12). The reviewer performs those two walkthroughs and records the decision with `/feature-next-phase --signoff bs-11 approved` (or `changes "<items>"`).
