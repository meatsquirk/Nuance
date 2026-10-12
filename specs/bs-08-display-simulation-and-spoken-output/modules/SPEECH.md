# Module SPEECH — repeatable spoken output

**Status:** In progress — SPEECH-1 done (shell); SPEECH-2..4 blocked by G-2
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/a11y/repeatable_speech.dart` (the `RepeatableSpeech` wrapper behind the existing `Speech` seam), `lib/display/spoken_output_panel.dart` (the E50 panel: repeat control + last-spoken display, persistent), wiring in `lib/app/build_app.dart` / `lib/main.dart` (inject `RepeatableSpeech` app-wide). Unit tests under `test/a11y/` and `test/display/`.
**Depends on:** DISPLAY-1 (scaffold) only — independent of the display state · **Blocks:** ITEST (observes speech), SIGNOFF

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SPEECH-1 | shell | — | ✅ Done | 7,712,760 | 18m 46s |
| SPEECH-2 | behavior | AC-8 | ⬜ Todo | | |
| SPEECH-3 | behavior | AC-9 | ⬜ Todo | | |
| SPEECH-4 | behavior | AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes:** `RepeatableSpeech implements Speech` — wraps an inner `Speech` (production: `NoopSpeech`; suite: `FakeSpeech`), records `lastUtterance` on each `speak`, and adds `Future<void> repeat()` (re-speaks `lastUtterance`; inert when none). Because it *implements `Speech`*, every existing caller (readout, comparison, recipes) keeps speaking through the same seam unchanged (D-8).
- **Consumes:** the existing phrasing builders — readout speech (bs-01), `comparisonSpeech` (bs-03), `recipeSpeech` (bs-04) — which already run through the one injected `Speech`. bs-08 adds **no** second phrasing path (D-9).
- **Panel (E50):** `spoken_output_panel.dart` is a persistent widget — a repeat control + the last-spoken text — with **no timer / no auto-dismiss** (D-10, AC-10). It stays until the painter navigates away.
- **Production TTS:** still no native text-to-speech (bs-01 D-1); `RepeatableSpeech` wraps `NoopSpeech`, so production is inert but repeatable. A platform-TTS impl remains a later swap behind the same `Speech` seam.

## Open gates

- **G-2** (acceptance tests approved) blocks SPEECH-2..4.

## Phase SPEECH-1 — shell: RepeatableSpeech + spoken-output panel

- **Kind:** shell
- **Target AC:** —
- **Depends on:** SETTINGS-1 *(ordering only — shared `build_app.dart`; logically independent of DISPLAY/SETTINGS)* · **Blocks:** ITEST-1, SPEECH-2
- **Files:** `lib/a11y/repeatable_speech.dart`, `lib/display/spoken_output_panel.dart`, `lib/app/build_app.dart`, `lib/main.dart`. Tests under `test/a11y/`, `test/display/`.
- **Tasks:**
  1. `RepeatableSpeech` wrapping an inner `Speech`; `speak` delegates + records `lastUtterance`; `repeat()` re-speaks (inert when none). Wire it as the app-wide `Speech` (production wraps `NoopSpeech`; the harness wraps `FakeSpeech`).
  2. The spoken-output panel scaffold (E50) with a repeat control (calls `repeat()`) and the last-spoken display — present, persistent, no timer (the no-auto-dismiss behaviour is asserted in SPEECH-4).
  3. Keyed finders for the panel + repeat control.
- **Exit criteria:** unit gate (100% on new files, incl. the inert-repeat branch); existing suites green; existing speak paths (readout/comparison/recipes) still speak through the (now wrapping) seam unchanged.

### Result — SPEECH-1 (2026-10-12)

- **Landed (behaviour unchanged):** `lib/a11y/repeatable_speech.dart` — `RepeatableSpeech extends ChangeNotifier implements Speech`: wraps an `inner` `Speech`, `speak` records `lastUtterance` + `notifyListeners()` + delegates to `inner.speak`; `repeat()` re-speaks `lastUtterance` through `inner` (inert early-return when none, `lastUtterance` unchanged); `canRepeat` getter. `lib/display/spoken_output_panel.dart` — `SpeechScope` (InheritedNotifier over the one `RepeatableSpeech`, `of`/`maybeOf`, mirrors `DisplayScope`) + `SpokenOutputPanel` (E50): keyed `panelKey`/`repeatKey`/`lastSpokenKey`; inert (nothing spoken) → `SizedBox.shrink(key: panelKey)` (present but zero-size, so no screen's layout changes); once spoken → repeat control (`speech.repeat`) + last-spoken `Text`.
- **Wiring (`lib/app/build_app.dart`):** `buildApp` now wraps the injected `deps.speech` in a `RepeatableSpeech` (reuses an already-repeatable injected one as-is), re-provides it through `AppScope` via `_depsWithSpeech` (so the readout's controller, which reads `AppScope.of(context).speech`, speaks through the repeatable seam), passes it to the comparison/recipes/correction home branches, and exposes it app-wide through a new `_SpeechRoot` (owns + disposes the wrapper it created; an injected one is left to its injector, mirroring `_DisplayRoot`). The persistent panel is surfaced over every screen by `_SpokenOutputChrome` nested inside the existing `DisplayChrome` (settings entry/panel stay above it). `main.dart` unchanged (buildApp wraps the shipped `NoopSpeech`).
- **Test change:** `test/app/build_app_test.dart` — the `injects the dependencies via AppScope` test previously asserted `identical(seen, deps)`; the app-wide speech is now a `RepeatableSpeech` wrapping the injected sink, so it asserts `seen.speech is RepeatableSpeech` with `.inner` == the injected speech and the other services still identical (honest design change, not a weakened assertion). No AC test touched (none exist yet).
- **Verification:** `flutter analyze` clean; `flutter test --coverage` = **914 unit pass** (899 baseline + 15 new); coverage gate **100% on all 11 touched lib files** (PASS); bs08 integration scaffold guard **3/3** on sim `5AB9D06D…`. Fix passes: 0/3.
- **Tokens / Time:** see dashboard row (ledger `SPEECH-1`).

### Checkpoint / Handoff — SPEECH-1

- **Frozen for ITEST-1 / SPEECH-2..4:** `RepeatableSpeech(inner)` with `speak`/`repeat`/`lastUtterance`/`canRepeat`; `SpeechScope.of`/`maybeOf`; `SpokenOutputPanel` with `panelKey = Key('spoken-output-e50-panel')` (always present), `repeatKey = Key('spoken-output-e50-repeat')` and `lastSpokenKey = Key('spoken-output-e50-last')` (both present only once something has been spoken). The one app-wide `RepeatableSpeech` is what every speak path now flows through, so the ITEST `FakeSpeech` (injected as the inner) records every utterance once, and a repeat records it again (AC-8). The panel is inert/zero-size until an utterance exists — AC-10's "panel still found after a long pump" holds via `panelKey`, which is present even when inert.
- **Merge-risk:** SPEECH-1 edited `lib/app/build_app.dart` (wrapped the app-wide speech + the chrome). This was the last shell touching that file; ITEST-1 adds the harness/smoke (no build_app change expected).
- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart run tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`. Toolchain: `/Users/matthew.quirk/development/flutter/bin` on PATH; booted sim `5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685`. The device lane is shared across parallel sessions — run device tests under `coord.sh with-lock` (wrap the command in `bash -c 'cd <worktree> && …'`, keeping `FNP_COORD_REPO` at the primary checkout so the lock is shared).
- **Known gap:** none beyond the two standing carried flakes (coverage const-folded line; integration needs `-d`).

## Phase SPEECH-2 — AC-8 repeat the last spoken output

- **Kind:** behavior
- **Target AC:** AC-8 (full)
- **Depends on:** ITEST-4 (G-2), SPEECH-1 · **Blocks:** SPEECH-3
- **Files:** `lib/a11y/repeatable_speech.dart`, `lib/display/spoken_output_panel.dart`
- **Tasks:** after a reading has been spoken, the repeat control (E50) re-speaks the exact same utterance; inert (disabled / no-op) when nothing has been spoken yet.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-8; `display_test.dart` green (`TestAC08_RepeatSpokenOutput`).

## Phase SPEECH-3 — AC-9 one consistent phrasing for readings and comparisons

- **Kind:** behavior
- **Target AC:** AC-9 (full)
- **Depends on:** SPEECH-2 · **Blocks:** SPEECH-4
- **Files:** `lib/a11y/repeatable_speech.dart` (if any); mostly a verification/guard that both paths use the one seam (D-9)
- **Tasks:** confirm a reading and a comparison are both spoken through the single shared `Speech` (the one injected `RepeatableSpeech`), using the shared phrasing builders — no second speech route is introduced.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-9; `display_test.dart` green (`TestAC09_OneConsistentPhrasing`).

## Phase SPEECH-4 — AC-10 the spoken-output panel never auto-dismisses

- **Kind:** behavior
- **Target AC:** AC-10 (full)
- **Depends on:** SPEECH-3 · **Blocks:** —
- **Files:** `lib/display/spoken_output_panel.dart`
- **Tasks:** the panel stays available with no timer and nothing dismissing it after inactivity (D-10); it is removed only when the painter leaves it.
- **Exit criteria:** unit gate; existing suites green.
- **Acceptance gate:** un-pend AC-10; `display_test.dart` green (`TestAC10_PanelNeverAutoDismisses`).

### Result  <!-- filled on completion -->

### Checkpoint / Handoff  <!-- filled on completion -->

- **Verification commands:** `flutter analyze` · `flutter test --coverage` + `dart tool/coverage_gate.dart` · `flutter test integration_test/display_test.dart -d <udid>`
