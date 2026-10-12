# Module SOURCE — CaptureSource extensions (torch, colour space, RAW, normalization)

**Status:** In progress — SOURCE-1, SOURCE-2, SOURCE-3 done (AC-6 ✅, AC-8 ✅, AC-7 ✅); next SOURCE-4 (AC-9/10) — the last SOURCE phase before sign-off
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/capture_source.dart`, `lib/capture/source/frame.dart`,
`lib/capture/source/software_capture_source.dart`, `lib/capture/source/sampling.dart`,
`integration_test/fakes/fake_capture_source.dart` (extensions only — bs-02's existing members stay)
**Depends on:** bs-02 source (merged on `main`) · **Blocks:** CAPTURE-2 (shell consumes the new signatures), SOURCE-2/3/4

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SOURCE-1 | shell | — | ✅ Done | 5,166,894 | 15m 59s |
| SOURCE-2 | behavior | AC-6, AC-8 | ✅ Done | 14,008,491 | 2h 43m |
| SOURCE-3 | behavior | AC-7 | ✅ Done | 5,375,373 | 13m 59s |
| SOURCE-4 | behavior | AC-9, AC-10 | ⬜ Todo | | |

## Interface reconciliation

- **Exposes (added to `CaptureSource`):** `bool get torchOn`; `void turnTorchOn()` / `void turnTorchOff()`;
  `bool get supportsWideGamut`; `bool get supportsRaw`; `CaptureColorSpace get colorSpace` (the space the
  source captures in now); `CaptureMode get captureMode` (`processed` | `raw`). These are **source
  capability/state**; the controller reads them at commit (CAPTURE) to tag the `Sample`.
- **Colour-space type (D-2) — DECIDED in SOURCE-1:** *added* a separate
  `CaptureColorSpace{srgb, displayP3}` (in `capture_source.dart`) rather than renaming `FrameColorSpace`.
  Rationale: a `Frame` tag describes one decoded pixel buffer; `CaptureColorSpace` is capture *state* (the
  space the source captures in now, after fallback) and the type of the committed `Sample.colorSpace`, which
  must not depend on the frame-buffer enum. The two value sets coincide today but model different things.
  `CaptureColorSpace.ofFrame(FrameColorSpace)` maps a frame's buffer tag onto the capture tag (used from
  SOURCE-2, where `colorSpace` reflects the frames actually captured). `displayP3` is the widest space the
  enum offers and tags both wide-gamut and the widest RAW capture; processed-vs-RAW is carried orthogonally by
  `CaptureMode{processed, raw}`. `Frame`/`FrameColorSpace` are unchanged (`frame.dart` not touched).
- **Normalization contract (D-7):** `CaptureSource` yields frames and `normaliseAgainstCard` returns
  `ColorCoordinates`; the controller builds the `Sample`. "Normalized" means the sampled coordinates are
  canonical CIELAB regardless of the capture space — `sampling.dart` must convert **from the frame's actual
  colour space** (today it assumes sRGB). SOURCE-2/4 make that conversion space-aware.
- **Torch illuminant (D-3):** distinct from `Lighting{adequate,low}`; `turnTorchOn()` sets `torchOn`; the
  *warning string* and the `litByTorch` stamp are the controller's (CAPTURE-3), not the source's.
- **Platform modelling (D-7):** `SceneSpec`/`FakeCaptureSource` gain a platform knob so two configs
  (Android/iOS) can carry **different pre-normalization raw** yet the same ground truth.

## Open gates

None specific to SOURCE. G-2 (test review) blocks SOURCE-2/3/4 as behavior phases.

## Phase SOURCE-1 — shell: capability + torch + colour-space/RAW signatures

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAPTURE-1 · **Blocks:** CAPTURE-2, SOURCE-2/3/4
- **Files:** `capture_source.dart`, `frame.dart`, `software_capture_source.dart`,
  `integration_test/fakes/fake_capture_source.dart`
- **Tasks:**
  1. Add to `CaptureSource`: `torchOn`, `turnTorchOn()`, `turnTorchOff()`, `supportsWideGamut`,
     `supportsRaw`, `colorSpace`, `captureMode`. Introduce `CaptureColorSpace` + `CaptureMode` enums (D-2).
  2. Give `SoftwareCaptureSource` behaviour-preserving defaults: torch off, `supportsWideGamut`/`supportsRaw`
     from new `SceneSpec` fields (default false), `colorSpace == srgb`, `captureMode == processed`. No change
     to existing frame generation yet.
  3. Extend `SceneSpec` with knobs: `torchAvailable`, `torchColorShift` (how torch biases the reading),
     `supportsWideGamut`, `supportsRaw`, `platform`/`rawColorShift` (pre-normalization raw offset for AC-10).
  4. Extend `FakeCaptureSource` to surface those knobs; keep `framesRead`, `groundTruth`, `stagedPhoto`.
- **Exit criteria:** all four lib files + the fake 100% covered; `flutter analyze` clean; existing unit +
  integration suites stay green (no behaviour change); new getters return the defaults.

## Phase SOURCE-2 — behavior: colour-space tag + narrower fallback (AC-6, AC-8)

- **Kind:** behavior
- **Target AC:** AC-6 (full) + AC-8 (full)
- **Depends on:** CAPTURE-2 (Sample.colorSpace + commit threading), ITEST-4 (G-2) · **Blocks:** SOURCE-4
- **Files:** `software_capture_source.dart`, `sampling.dart`, `capture_source.dart` (behaviour of the new
  getters), `fake_capture_source.dart`
- **Tasks:**
  1. The source selects the widest space the device offers: `supportsWideGamut` → capture/tag `displayP3`,
     else fall back to `srgb`; `colorSpace` reflects the space actually used.
  2. Make `sampling.dart` convert from the frame's actual colour space to CIELAB (not always sRGB), so a
     wide-gamut frame converts honestly (committed colour within ~ΔE00 1 of ground truth).
  3. Confirm the committed `Sample.colorSpace` (threaded in CAPTURE-2) now reads `displayP3` on `SCENE_WIDE`
     and `srgb` on `SCENE_NARROW`.
- **Exit criteria:** unit + 100% coverage on touched files; `flutter analyze` clean.
- **Acceptance gate:** un-pend AC-6 and AC-8; `TestAC06_TaggedWithColourSpace` and
  `TestAC08_FallbackLabelsNarrower` green (and all earlier un-pended ACs).

## Phase SOURCE-3 — behavior: RAW capture where supported (AC-7)

- **Kind:** behavior
- **Target AC:** AC-7 (full)
- **Depends on:** SOURCE-2 (merge-risk: same source files), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `software_capture_source.dart`, `capture_source.dart`, `fake_capture_source.dart`
- **Tasks:**
  1. When `supportsRaw`, the source captures in RAW: `captureMode == raw` and `colorSpace` is the widest the
     device offers (the RAW/wide space, not the processed sRGB pipeline).
  2. Non-RAW devices keep `captureMode == processed` (the in-fixture control).
- **Exit criteria:** unit + 100% coverage on touched files; `flutter analyze` clean.
- **Acceptance gate:** un-pend AC-7; `TestAC07_RawWhereSupported` green (and all earlier un-pended ACs).

## Phase SOURCE-4 — behavior: normalized + tagged contract, platform-agnostic (AC-9, AC-10)

- **Kind:** behavior
- **Target AC:** AC-9 (full) + AC-10 (full)
- **Depends on:** SOURCE-2 (colour-space threading), ITEST-4 (G-2) · **Blocks:** SIGNOFF-1
- **Files:** `software_capture_source.dart`, `capture_source.dart`, `fake_capture_source.dart`,
  `sampling.dart` (if a platform-specific normalization seam is needed)
- **Tasks:**
  1. Guarantee the contract: every committed sample is normalized (canonical CIELAB) **and** carries a
     non-null `colorSpace`, independent of the source implementation.
  2. Model two platforms (`SCENE_ANDROID`, `SCENE_IOS`) whose pre-normalization raw differs (via
     `rawColorShift`) but which normalize to the identical CIELAB + identical tag.
  3. Ensure the normalization removes the platform raw offset so both land on the same ground truth.
- **Exit criteria:** unit + 100% coverage on touched files; `flutter analyze` clean.
- **Acceptance gate:** un-pend AC-9 and AC-10; `TestAC09_NormalizedTaggedSample` and
  `TestAC10_PlatformAgnosticSample` green (and all earlier un-pended ACs).

### Result — SOURCE-1  <!-- 2026-10-12 -->

- **Shell signatures only — behaviour unchanged.** Added to `CaptureSource` (abstract): `torchOn`,
  `turnTorchOn()`, `turnTorchOff()`, `supportsWideGamut`, `supportsRaw`, `colorSpace`, `captureMode`, with
  new enums `CaptureColorSpace{srgb, displayP3}` (+ `ofFrame` map) and `CaptureMode{processed, raw}`
  (`capture_source.dart`).
- **D-2 decided:** added `CaptureColorSpace` separate from `FrameColorSpace` (not a rename); `frame.dart`
  untouched. Rationale + mapping recorded in Interface reconciliation above.
- **`SoftwareCaptureSource` defaults (behaviour-preserving):** torch off; `turnTorchOn/Off` flip a private
  flag; `supportsWideGamut`/`supportsRaw` surface new `SceneSpec` fields (default false); `colorSpace`→`srgb`,
  `captureMode`→`processed` (constants — SOURCE-2/3 make them reflect capability).
- **`SceneSpec` knobs added (all default off):** `torchAvailable`, `torchColorShift`, `supportsWideGamut`,
  `supportsRaw`, `platform` (new `CapturePlatform{android, ios}`, default `android`), `rawColorShift` — so
  bs-02..bs-06 scenes are unaffected. Behaviour they drive lands in SOURCE-2/3/4 + CAPTURE-3.
- **`FakeCaptureSource` not edited:** inherits every new getter/control from `SoftwareCaptureSource`, so the
  knobs flow through the scene (`framesRead`/`groundTruth`/`stagedPhoto` untouched). Fixed `_ControllableSource`
  in `capture_controller_test.dart` (explicit `implements CaptureSource`) with inert shell defaults; the two
  `_InertCaptureSource` (`noSuchMethod`) and `_RephotographSource` (extends `SoftwareCaptureSource`) needed none.
- **Gates:** `flutter analyze` clean. Unit `flutter test --coverage` → **858 passed** (849 baseline + 9 new).
  Coverage gate `dart run tool/coverage_gate.dart main` → **100%** on the 2 touched lib files
  (`capture_source.dart`, `software_capture_source.dart`). Existing integration `flutter test integration_test/
  -d <iPhone 17>` under the verify lock → **131 passed** (no regression). Acceptance: n/a (no bs-09 AC tests
  until ITEST-1). Grades: n/a (shell).
- Fix passes: 0/3 (all gates green on first run).

### Checkpoint / Handoff — SOURCE-1

- **Frozen interface for CAPTURE-2 / SOURCE-2/3/4:** `CaptureSource` now exposes `torchOn` + `turnTorchOn/Off`,
  `supportsWideGamut`, `supportsRaw`, `colorSpace` (`CaptureColorSpace`), `captureMode` (`CaptureMode`).
  `CaptureColorSpace.ofFrame(FrameColorSpace)` is the frame→capture-tag map (currently unused — SOURCE-2 calls
  it when `colorSpace` starts reflecting the captured frames). `CapturePlatform{android, ios}` +
  `SceneSpec.{torchAvailable, torchColorShift, supportsWideGamut, supportsRaw, platform, rawColorShift}` are the
  fixture knobs the ITEST scenes drive.
- **Shell defaults any consumer can rely on now:** torch off; `colorSpace == srgb`; `captureMode == processed`;
  capabilities false unless the scene sets them. CAPTURE-2 threads `source.colorSpace`/`captureMode` and
  `state.torchOn` into the `Sample` on commit; until SOURCE-2/3 these are the sRGB/processed defaults.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host, no sim). Integration under the lock: `coord.sh with-lock bs-09-advanced-capture <PHASE> --wait
  900 -- bash -c 'cd /Users/matthew.quirk/Nuance-bs09 && export PATH=…/flutter/bin:$PATH && flutter test
  integration_test/ -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'`. (No `timeout` on this macOS — plain `git push`.)
- **Known gaps:** `colorSpace`/`captureMode`/capabilities are inert constants/pass-throughs (SOURCE-2/3/4 give
  them meaning); torch warning string + `litByTorch` stamp are the controller's (CAPTURE-3); `sampling.dart`
  still assumes sRGB (SOURCE-2 makes it space-aware). No `Sample` fields yet (CAPTURE-2).

### Result — SOURCE-2  <!-- 2026-10-12 -->

- **Colour-space selection + honest wide-gamut sampling (AC-6, AC-8).** The source now captures in the widest
  space it offers: `SoftwareCaptureSource._captureFrameSpace` → `displayP3` when `scene.supportsWideGamut`, else
  the `srgb` fallback; `colorSpace` reports it via `CaptureColorSpace.ofFrame(_captureFrameSpace)`, and the
  generated feed renders ground truth **in** that space (frames tagged accordingly). The CAPTURE-2 commit path
  already threads `source.colorSpace` onto `Sample.colorSpace`, so a committed reading is now tagged `displayP3`
  on `SCENE_WIDE` and `srgb` on `SCENE_NARROW`.
- **`sampling.dart` made space-aware (D-2/D-7):** `_pixelToLab(pixel, FrameColorSpace)` converts from the frame's
  actual space — sRGB unchanged; Display P3 rotates P3→sRGB primaries (one linear matrix, shared sRGB transfer
  curve + D65 white) before the existing `color_models` sRGB→CIELAB leg, so a wide-gamut capture converts
  honestly instead of being read as sRGB. New public `encodeFromSrgb(pixel, space)` renders the feed in the
  capture space (identity for sRGB). Olive round-trips at ΔE ≈ 0.2; reading a P3 buffer as sRGB passes the raw
  channels through unconverted (the SOURCE-1 assumption this replaces).
- **No new enums/signatures:** reused SOURCE-1's `CaptureColorSpace`/`ofFrame`; the abstract `CaptureSource`
  interface is unchanged, so every `implements CaptureSource` test double and `FakeCaptureSource` (which inherits
  and preserves `frame.colorSpace`) needs no edit. `captureMode` stays `processed` (SOURCE-3 owns RAW).
- **Gates:** `flutter analyze` clean. Unit `flutter test --coverage` → **905 passed** (+9 new over the 896
  baseline). Coverage gate `dart run tool/coverage_gate.dart main` → **100%** on both touched lib files
  (`sampling.dart`, `software_capture_source.dart`) and all 11 branch-vs-main files. Acceptance (default, under the
  device lock on iPhone 17 sim): **15 passed / 6 pending-skipped**, with `AC-6 TaggedWithColourSpace` and
  `AC-8 FallbackLabelsNarrower` now green (un-pended). Grades: fresh adversarial subagent re-graded every
  un-pended AC test + the modified scaffold guard — **AC-6 A, AC-8 A, AC-1 A (no drift), AC-2 A (no drift),
  scaffold guard A → 5 A / 0 below A**; whole suite still all A, no row needs fixing.
- **Augmentations:** none (the ITEST packet scheduled none; AC-6/AC-8 carry their own in-fixture/in-test controls,
  and AC-8's `SCENE_WIDE` control discriminates now that SOURCE-2 landed). SOURCE-2 strengthens no already-green
  AC test (AC-1/AC-2 are torch-only).
- Fix passes: 1/3 (first acceptance run failed to build for ios_sim — offline native-asset download; seeded the
  worktree's `.dart_tool/hooks_runner/shared` sqlite3 download cache from the primary checkout, then green. One
  unit assertion tuned: the mislabelled-read discrimination asserts the P3 channels pass through, not a ΔE
  threshold — olive's sRGB↔P3 gap is ~5/255).

### Checkpoint / Handoff — SOURCE-2

- **Frozen for SOURCE-3 / SOURCE-4 (same source files — base a worktree on this phase's branch or merge it in):**
  `SoftwareCaptureSource._captureFrameSpace` selects `displayP3`/`srgb` from `supportsWideGamut`; `colorSpace`
  = `ofFrame(_captureFrameSpace)`. `sampling.dart` is now space-aware: `encodeFromSrgb(Pixel, FrameColorSpace)`
  (encode, identity for sRGB) and the private `_pixelToLab(Pixel, FrameColorSpace)` (decode); `_p3ToSrgbLinear`
  / `_srgbToP3Linear` matrices + `_linearize`/`_encodeGamma`/`_toChannel8` are the P3 seam.
  - **SOURCE-3 (AC-7, RAW):** set `captureMode == raw` where `supportsRaw`, with `colorSpace == displayP3` (RAW
    uses the widest space — `SCENE_RAW` is also wide-gamut). The space selection + feed are already P3 for a
    wide device; SOURCE-3 only flips the mode (and must keep `SCENE_NARROW` → `processed`).
  - **SOURCE-4 (AC-9/10, platform-agnostic):** normalization must remove `SceneSpec.rawColorShift` so Android/iOS
    land on identical CIELAB + identical `colorSpace` tag. `sampling.dart` is the place for any platform seam.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host). Acceptance under the lock: `coord.sh with-lock bs-09-advanced-capture <PHASE> --wait 900 -- bash
  -c 'cd <worktree> && export PATH=/Users/matthew.quirk/development/flutter/bin:$PATH && flutter test
  integration_test/advanced_capture_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'` (add
  `--dart-define=BS09_RUN_PENDING=true` for run-pending). **A fresh worktree must seed
  `.dart_tool/hooks_runner/shared` from the primary checkout** (offline can't download the sqlite3 ios_sim
  dylib), else the ios build fails. macOS has no `timeout`; redirect long runs to a file.
- **Known gaps:** `captureMode` is still the `processed` constant (SOURCE-3); platform raw offset is not yet
  removed by normalization (SOURCE-4). Imported photos default to sRGB frames (unaffected).

### Result — SOURCE-3  <!-- 2026-10-12 -->

- **RAW capture where supported (AC-7).** `SoftwareCaptureSource.captureMode` now returns
  `scene.supportsRaw ? CaptureMode.raw : CaptureMode.processed` — a RAW-capable device captures unprocessed
  frames; every other device stays on the processed (sRGB/JPEG-style) pipeline. The one-line getter is the
  only product change: the commit path (`capture_controller.commit()`, CAPTURE-2) already stamps
  `source.captureMode` onto `Sample.captureMode`, and `colorSpace` already yields `displayP3` on the
  wide-gamut `SCENE_RAW` (SOURCE-2's `_captureFrameSpace`), so RAW's "widest space" tag needs no new code.
- **No new enums/signatures:** reused SOURCE-1's `CaptureMode`; the abstract `CaptureSource` interface is
  unchanged, so every `implements CaptureSource` double and `FakeCaptureSource` (inherits the getter) needs
  no edit. Refreshed two stale forward-reference comments (the `colorSpace`/`captureMode` getters).
- **Gates:** `flutter analyze` clean. Unit `flutter test --coverage` → **917 passed** (+1 new: a RAW-capable
  source asserts `captureMode == raw` + `colorSpace == displayP3`, covering the `raw` branch; the `processed`
  branch is covered by the existing wide/narrow cases). Coverage gate `dart run tool/coverage_gate.dart main`
  → **100%** on the touched lib file (`software_capture_source.dart`) and all 13 branch-vs-main files.
  Acceptance (default, under the device lock on iPhone 17 sim): **19 passed / 2 skipped** (AC-9, AC-10 pending
  SOURCE-4), with `AC-7 RawWhereSupported` now green (un-pended). Run-pending: AC-1..AC-8 pass, AC-9/AC-10
  fail their Thens — the designed red baseline for the unbuilt SOURCE-4 normalization, not a regression.
  Grades: fresh adversarial subagent re-graded every un-pended AC test (AC-1..AC-8) + the modified scaffold
  guard — **8 A / 0 below A**; whole-suite running total **24 A / 0 below A**, no row needs fixing.
- **Augmentations:** none (the ITEST packet scheduled none for AC-7; its RAW-vs-processed control is in-test
  and discriminates as soon as SOURCE-3 landed). SOURCE-3 strengthens no already-green AC test (`captureMode`
  is orthogonal to the torch / multi-point / colour-space paths; only AC-7 reads it).
- Fix passes: 0/3 (all gates green on first run).

### Checkpoint / Handoff — SOURCE-3

- **Frozen for SOURCE-4 (same source files — base a worktree on this phase's branch or merge it in):**
  `SoftwareCaptureSource.captureMode` = `scene.supportsRaw ? raw : processed`; `colorSpace` unchanged
  (`ofFrame(_captureFrameSpace)`, displayP3 iff wide-gamut). `Sample` carries `colorSpace` + `captureMode`
  (both threaded in CAPTURE-2's commit) and the coordinates the controller builds from
  `normaliseAgainstCard`. SOURCE-4 is the only remaining behaviour phase.
  - **SOURCE-4 (AC-9/10, platform-agnostic):** guarantee the capture *contract* — every committed sample is
    normalized (canonical CIELAB) and carries a non-null `colorSpace`, independent of platform. Normalization
    must remove `SceneSpec.rawColorShift` so `SCENE_ANDROID` (+10) and `SCENE_IOS` (−8) land on the identical
    CIELAB + identical tag. `sampling.dart`/`normaliseAgainstCard` is the place for the platform seam. AC-9/10
    are red at baseline today (the offset is not yet removed) — the expected pending state, not a limited test.
- **Verification commands:** `flutter analyze` · `flutter test --coverage` · `dart run tool/coverage_gate.dart
  main` (host). Acceptance under the lock: `coord.sh with-lock bs-09-advanced-capture <PHASE> --wait 900 -- bash
  -c 'cd /Users/matthew.quirk/Nuance-bs09 && export PATH=/Users/matthew.quirk/development/flutter/bin:$PATH &&
  flutter test integration_test/advanced_capture_test.dart -d 5AB9D06D-AE5D-43A2-A2E8-CBD46ED51685'` (add
  `--dart-define=BS09_RUN_PENDING=true` for run-pending). The worktree's `.dart_tool/hooks_runner/shared`
  sqlite3/objective_c cache is already seeded (SOURCE-2). macOS has no `timeout`; redirect long runs to a file.
- **Known gaps:** platform raw offset is not yet removed by normalization (SOURCE-4 owns AC-9/AC-10). After
  SOURCE-4 the behaviour stage is complete → SIGNOFF-1.
