# Module SOURCE — CaptureSource extensions (torch, colour space, RAW, normalization)

**Status:** In progress — SOURCE-1 done; next SOURCE-2 (behavior, blocked by CAPTURE-2 + G-2)
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/source/capture_source.dart`, `lib/capture/source/frame.dart`,
`lib/capture/source/software_capture_source.dart`, `lib/capture/source/sampling.dart`,
`integration_test/fakes/fake_capture_source.dart` (extensions only — bs-02's existing members stay)
**Depends on:** bs-02 source (merged on `main`) · **Blocks:** CAPTURE-2 (shell consumes the new signatures), SOURCE-2/3/4

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| SOURCE-1 | shell | — | ✅ Done | 5,166,894 | 15m 59s |
| SOURCE-2 | behavior | AC-6, AC-8 | ⬜ Todo | | |
| SOURCE-3 | behavior | AC-7 | ⬜ Todo | | |
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
