# Module VIEW — Live preview rendering

**Status:** ✅ Complete — VIEW-1/2/3/4/5 all done. VIEW-5 (native `CameraPreview` render, D-9) landed 2026-10-22 @ code; SIGNOFF-3 is the only remaining feature phase.
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_live_view.dart`, a frame-render widget (e.g. `lib/capture/live_frame_view.dart`), the native-preview seam, widget tests under `test/capture/`.
**Depends on:** CAM · **Blocks:** SIGNOFF-1 (done), SIGNOFF-3 (via VIEW-5)

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| VIEW-1 | shell | — | ✅ Done | | |
| VIEW-2 | behavior | AC-1 | ✅ Done | 7.74M | 14m 54s |
| VIEW-3 | behavior | AC-4 | ✅ Done | 3.88M | 11m 59s |
| VIEW-4 | behavior (fix) | — (keeps AC-1/AC-4; resolves bs-17 AC-14) | ✅ Done | 3.79M | 14m 40s |
| VIEW-5 | behavior (fix) | — (D-9 native `CameraPreview`; keeps AC-1/AC-4) | ✅ Done | 8.22M | 16m 10s |

## Interface reconciliation

- `capture_live_view.dart` currently renders `const Widget feedSurface = ColoredBox(key: liveViewKey, color: Color(0xFF3A3A3A))` and wraps it in a saturation-0 `ColorFiltered` for value-only mode; the marked-point/readings overlays are Stack siblings of the feed.
- VIEW introduces a frame-render widget that paints the active source's latest `Frame` and keeps `liveViewKey` as the stable anchor; when no frame is available it shows the existing placeholder (so the software-source / no-camera paths are unchanged). The grayscale filter and overlays stay exactly where they are (presentation invariant).

## Open gates

- G-2 (test review) ✅ Resolved 2026-10-21 12:36 EDT (Matt Quirk) — behavior stage unblocked; VIEW-2 done, VIEW-3 startable.

## Phase VIEW-1 — Frame-render widget seam

- **Kind:** shell
- **Target AC:** —
- **Depends on:** CAM-1 · **Blocks:** ITEST-1, VIEW-2
- **Files:** `lib/capture/live_frame_view.dart` (new), `capture_live_view.dart`
- **Tasks:**
  1. Add a `LiveFrameView(frame)` widget that paints a `Frame` (e.g. via `RawImage`/`CustomPaint` over the converted pixels), keyed `liveViewKey`.
  2. Route the live view through it with `frame == null` → the existing `ColoredBox` placeholder, so behaviour is unchanged until a source provides frames.
- **Exit criteria:** unit gate; existing capture widget/integration suites stay green; placeholder still shows (no source frames wired yet).
- **Acceptance gate:** —

### Result
Frame-render widget seam — **no behaviour change** (the feed still shows the flat placeholder; `frame` is null everywhere until VIEW-2 wires a live source, so the software-source / no-camera paths render exactly as before).
- **New lib file (100% covered):** `lib/capture/live_frame_view.dart` — `LiveFrameView({required Frame? frame})`, carries `CaptureLiveView.liveViewKey`. `frame == null` → `ColoredBox(color: placeholderColor = 0xFF3A3A3A)` (the original SCREEN-1 colour); `frame != null` → `CustomPaint(painter: _FramePainter(frame), child: SizedBox.expand())` painting the row-major RGB pixels scaled to fill (per-pixel `drawRect`; D-4 downsampling keeps it cheap). `_FramePainter.shouldRepaint` = `oldDelegate.frame != frame` (Frame keeps identity equality).
- **Routed through it:** `capture_live_view.dart` gains an optional `final Frame? frame` (default null) and renders the feed via `LiveFrameView(frame: frame, key: liveViewKey)` in place of the inline `ColoredBox`. The value-only `ColorFiltered` still wraps that surface (grayscale invariant) and the eyedropper/readings/overlays are untouched Stack siblings.
- **Tests:** +3 widget tests (`test/capture/live_frame_view_test.dart`): null→placeholder (ColoredBox, no CustomPaint under the view), non-null→CustomPaint (no placeholder), and a rebuild with a fresh frame (exercises `shouldRepaint`). Existing `capture_live_view_test.dart` (grayscale ancestor assertions over `liveViewKey`) and `capture_screen_test.dart` stay green unchanged.
- **Gates:** unit + coverage **PASS** — `flutter test --coverage test/` = **1666 passed** (1663 baseline + 3), exit 0; `dart run tool/coverage_gate.dart 11944b6` = **100% on all 11 touched lib files**. Existing integration suites green per-file: `integration_test/capture_test.dart` 19/19, `advanced_capture_test.dart` 21/21. No acceptance/grade gate (shell). **Fix passes: 1/3** (scoped one test's `CustomPaint` matcher under `LiveFrameView` — framework-internal CustomPaints tripped a global `findsNothing`; test-only, no product change).
- **Tokens/Time:** see dashboard (VIEW-1 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (VIEW-2 builds on):**
  - `LiveFrameView({required Frame? frame, Key? key})` — the single frame-render seam. VIEW-2 passes the active source's latest `Frame` (non-null) so the preview paints the live feed; `frame == null` must keep showing `placeholderColor` (the software / no-camera path).
  - `CaptureLiveView.frame` (optional, default null) — the Capture screen will feed the controller's latest frame here in VIEW-2; `liveViewKey` stays on `LiveFrameView` (anchor + grayscale-wrap target unchanged).
  - `_FramePainter` is private to `live_frame_view.dart`; its per-pixel paint is a preview-only seam — VIEW-2 may keep it or swap to a `ui.Image` path, but must preserve: `liveViewKey` resolves to one widget, and no `ColoredBox` placeholder under `liveViewKey` while a camera source streams (the VIEW-2 `TestAC01` assertion).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`
  - Coverage gate on touched files: `dart run tool/coverage_gate.dart 11944b6`
  - Existing capture integration suites (run **one file per invocation** — launching two at once fails to start the app): `flutter test -d flutter-tester integration_test/capture_test.dart` then `… integration_test/advanced_capture_test.dart`.
- **Known gaps:** none introduced. No frame source is wired — `frame` is null in assembly, so the feed is still the flat placeholder; VIEW-2 (behavior, gated by G-2 and dependent on CAM-3's real stream) wires it. The grayscale value-only toggle already wraps the new surface, so VIEW-3 only needs the real frame flowing.

## Phase VIEW-2 — Live preview renders real frames

- **Kind:** behavior
- **Target AC:** AC-1 (full)
- **Depends on:** VIEW-1, CAM-3 · **Blocks:** VIEW-3, SIGNOFF-1
- **Files:** `capture_live_view.dart`, `live_frame_view.dart`
- **Tasks:**
  1. Feed the active source's latest `Frame` into `LiveFrameView` so the preview paints the camera feed.
  2. Ensure the placeholder is gone once frames flow (and still present on the software/no-camera path).
- **Exit criteria:** unit/coverage gate; `TestAC01_LivePreview` green (render present, no `ColoredBox` placeholder under `liveViewKey` when a camera source streams).
- **Acceptance gate:** un-pend AC-1; `integration_test/live_camera/` green.
- **Augments:** none

### Result
Live preview now paints the active camera source's frame — **AC-1 delivered (grade A)**.
- **Lib (2 files, 100% covered):**
  - `capture_controller.dart` — new `Frame? get currentFrame`: the latest buffered frame (`_recentFrames.last`) **only** when `source.kind == CaptureSourceKind.camera` and a frame has arrived, else null. So the live camera paints its feed while the deterministic **software / no-camera fallback keeps the flat placeholder** (the VIEW-1 invariant) — its synthetic feed still drives the sampled reading, it is simply not painted as a preview.
  - `capture_screen.dart` — passes `frame: controller.currentFrame` into `CaptureLiveView` (was unset/null).
- **AC un-pended:** AC-1 (`TestAC01_LivePreview`) — deleted its row in `pending.dart`. Green in the default suite; `showsPlaceholder isFalse` + `liveView.frame isNotNull`.
- **Augmentations:** none of its own. **Smoke-guard follow-through** (`live_camera/smoke_test.dart`, required because VIEW-2 changed observable state): render-path assertion flipped `showsPlaceholder` true→`isFalse` (AC-1 delivered); pending exact-set `unpendedACs` now `{AC-1, AC-2}`; the pending-skip example moved AC-1→AC-3 (CAM-4). Guards stay non-vacuous (set-equality both directions).
- **Gates:** analyze clean; unit+coverage **PASS** — `flutter test --coverage test/` 1672 passed, exit 0; `coverage_gate.dart 4673ec7` **100% on both touched files**. Acceptance **PASS** — `live_camera/` default suite green (AC-1 runs green; AC-2 green; others skip pending); run-pending baseline unchanged (AC-3/AC-5/AC-6/AC-10 green-at-baseline, AC-7/AC-8/AC-9 still red → PERM-2/PERM-3/CAM-7). No regression: `capture_test.dart` 19/19, `advanced_capture_test.dart` 21/21. **Grade A** (fresh independent re-grade, live). **Fix passes: 0/3.**
- **Note:** AC-4 (VIEW-3) already passes in run-pending mode now (the grayscale `ColorFiltered` was wired in the SCREEN-1 shell around the feed surface, so once the real frame flows it greys correctly) — left pending; VIEW-3 un-pends + confirms it.
- **Tokens/Time:** see dashboard (VIEW-2 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase (VIEW-3 builds on):**
  - `CaptureController.currentFrame` — the live preview frame seam. Camera source → latest frame; software/fallback → null (placeholder). The Capture screen feeds it to `CaptureLiveView.frame`.
  - The feed surface renders through `LiveFrameView(frame: controller.currentFrame, key: liveViewKey)` inside the value-only `ColorFiltered` wrapper (unchanged from the shell). VIEW-3 only needs to **un-pend AC-4** and make its augmentation (assert the readings subtree sits OUTSIDE the grayscale filter); the behaviour already works — the `ColorFiltered` wraps `feedSurface` (which carries `liveViewKey`), and `accuracyKey` is a sibling outside it.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <BASE>`.
  - Acceptance (one file per invocation): `flutter test -d flutter-tester integration_test/live_camera/preview_test.dart` (default: AC-1/AC-2 green, AC-4 pending); add `--dart-define=BS19_RUN_PENDING=true` to run AC-4.
- **Known gaps:** none introduced. AC-4 remains pending (VIEW-3). The software path deliberately shows the placeholder (not its synthetic feed).

## Phase VIEW-3 — Value-only grayscale over the live frame

- **Kind:** behavior
- **Target AC:** AC-4 (full)
- **Depends on:** VIEW-2 · **Blocks:** SIGNOFF-1
- **Files:** `capture_live_view.dart`
- **Tasks:**
  1. Ensure the saturation-0 `ColorFiltered` wraps the real frame render (not the placeholder), leaving overlaid readings in colour.
- **Exit criteria:** unit/coverage gate; `TestAC04_ValueOnlyLive` green.
- **Acceptance gate:** un-pend AC-4; suite green.
- **Augments:** `TestAC04`: assert the readings subtree sits **outside** the grayscale filter (stays in colour).

### Result
Value-only grayscale now greys the **live frame**, not the readings — **AC-4 delivered (grade A)**. Un-pend + keep-green only.
- **No `lib/` change.** The behaviour already existed: the SCREEN-1 shell wraps the feed surface (`LiveFrameView`, carrying `liveViewKey`) in a saturation-0 `ColorFiltered` when `state.valueOnly`, and VIEW-2 made a real frame flow into it. The `accuracyKey` readings region is a Stack sibling outside that filter, so it stays in colour. AC-4's assertions and its readings-outside-filter augmentation were written in ITEST-2.
- **AC un-pended:** AC-4 (`TestAC04_ValueOnlyLive`) — deleted its row in `pending.dart`. Runs green in the default suite.
- **Augmentations:** none newly made (the readings-outside-filter augmentation was already in the ITEST-2 test); VIEW-3's residual was making the Given pass (real frame shown) + un-pend. No already-green AC test is further strengthenable by this phase (no new behaviour landed).
- **Smoke-guard follow-through** (`live_camera/smoke_test.dart`, required because the un-pended set changed): exact-set `unpendedACs` → `{AC-1, AC-2, AC-3, AC-4}`; the pending-skip example moved AC-4 → AC-5 (owner CAM-5), still a genuinely-pending AC. Guards stay non-vacuous (set-equality both directions + each un-pended AC's skip-reason null + every owner a real phase).
- **Gates:** analyze clean; unit+coverage **PASS** — `flutter test --coverage test/` 1672 passed, exit 0; `coverage_gate.dart ea5d98c` = **no touched lib/**.dart — nothing to gate, PASS**. Acceptance **PASS** — `preview_test.dart` default 3/3 (AC-1/2/4 green); run-pending 3/3; `smoke_test.dart` 11/11; reading/controls/permission/platform default-mode files green with only later-phase ACs (AC-5/6/7/8/9) still skipped-pending. No regression (no lib touched; the existing `capture_test`/`advanced_capture_test` suites don't import the changed test files). **Grade A** (fresh independent re-grade of all 4 un-pended ACs: 4 A / 0 below A). **Fix passes: 0/3.**
- **Tokens/Time:** see dashboard (VIEW-3 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase:** nothing new — VIEW-3 added no interfaces. AC-4 now runs in the default suite; the value-only grayscale invariant (`ColorFiltered` over `liveViewKey` only, `accuracyKey` outside) is locked by `TestAC04_ValueOnlyLive`.
- **VIEW module is now complete** (VIEW-1 shell, VIEW-2 AC-1, VIEW-3 AC-4 all done). No VIEW phase remains; VIEW no longer blocks SIGNOFF-1 (which still waits on the CAM-5/6/7 and PERM-2/3/4 behavior phases).
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no** `timeout`, run bare):
  - Unit + coverage: `flutter test --coverage test/`; gate `dart run tool/coverage_gate.dart <BASE>`.
  - Acceptance (one file per invocation): `flutter test -d flutter-tester integration_test/live_camera/preview_test.dart` (default: AC-1/AC-2/AC-4 green); `… smoke_test.dart` (11/11).
- **Known gaps:** none introduced.

## Phase VIEW-4 — Theme the live-view placeholder (resolve bs-17 AC-14 regression)

- **Kind:** behavior (fix / conformance) — no bs-19 AC of its own; keeps AC-1 and AC-4 green and restores bs-17's design-system conformance AC-14.
- **Why:** SIGNOFF-1's full cross-feature regression (2026-10-21) found that bs-19's VIEW-1 put the
  camera-preview placeholder grey in a **new** file — `lib/capture/live_frame_view.dart:24`
  `static const Color placeholderColor = Color(0xFF3A3A3A)`. bs-17's design-system conformance test
  **AC-14** ("no screen may hardcode a palette colour", `integration_test/design_system_test.dart:883`)
  scans `lib/` for residual `Color(0x…)` literals outside `kThemeAuthorityFile` + the pinned D-4
  capture-device exclusion set (`kCaptureDeviceLiteralFiles = {'lib/capture/capture_live_view.dart'}`,
  `integration_test/design_system_source_scan.dart:45`). The new file is not in the set, so the scan flags
  it. **Proven a real regression, not a flake:** AC-14 **passes at base `11944b6`** (file didn't exist) and
  **fails deterministically at HEAD `1d01c9d`** (+26 −1, every run). **Decision (Matt Quirk, 2026-10-21):
  theme the placeholder** — source the colour from `AppTheme` so there is no hardcoded literal and no
  exemption is needed (master D-8).
- **Target AC:** — (fix). **Depends on:** VIEW-3, CAM-3 · **Blocks:** SIGNOFF-1
- **Files:** `lib/capture/live_frame_view.dart` (product); `integration_test/live_camera/harness.dart`
  (the `showsPlaceholder` helper at `harness.dart:139` reads `w.color == LiveFrameView.placeholderColor` — it
  must follow whatever the themed placeholder resolves to); possibly `test/capture/live_frame_view_test.dart`.
  Do **not** add `live_frame_view.dart` to `kCaptureDeviceLiteralFiles` (the chosen fix removes the literal
  rather than exempting it).
- **Tasks:**
  1. Replace the `static const Color placeholderColor = Color(0xFF3A3A3A)` with a placeholder sourced from
     `AppTheme` at build time (e.g. the neutral surface token the design system already exposes), so
     `LiveFrameView`'s `frame == null` branch paints a themed `ColoredBox`/surface and `lib/` holds no
     residual `Color(0x…)` literal in this file. Keep it a neutral camera-surface grey consistent with the
     prior look; confirm against `AppTheme`'s available tokens.
  2. Update the harness `showsPlaceholder` detection so AC-1/AC-4 still distinguish the placeholder from a
     painted frame without depending on a removed `static const` (e.g. match the themed placeholder colour
     resolved from `AppTheme`, or detect the absence of the `CustomPaint`/frame render under `liveViewKey`).
  3. Unit-test the themed placeholder branch to 100% of the changed lines/branches.
- **Exit criteria:** unit + coverage gate on touched lib; **bs-19 acceptance suite stays green** both modes
  (AC-1 `TestAC01_LivePreview` + AC-4 `TestAC04_ValueOnlyLive` in particular); **bs-17 `design_system_test.dart`
  AC-14 green**; no new residual-literal offender; the three carried off-lane flakes (palette AC-3/AC-5,
  display AC-9, self_assessment AC-4) unchanged (off-lane, not VIEW-4's).
- **Acceptance gate:** no AC to un-pend (all delivered); keep AC-1/AC-4 green; grade gate — re-grade the bs-19
  suite A (confirm the placeholder-detection change didn't weaken `TestAC01`/`TestAC04`).
- **Augments:** none (fix only; must not weaken any AC test).

### Result
- **Landed:** themed the live-camera preview placeholder through the theme authority (D-8). Added
  `AppTheme.cameraPlaceholderSurface` (+ private `_cameraPlaceholder = Color(0xFF3A3A3A)`) to the exempt
  `lib/app/theme.dart`; `lib/capture/live_frame_view.dart` now reads it — `static Color get placeholderColor
  => AppTheme.cameraPlaceholderSurface` (was `static const Color = Color(0xFF3A3A3A)`), build paints a
  non-const `ColoredBox(color: placeholderColor)`. The hex is unchanged, so the un-wired preview looks
  byte-for-byte identical. No `Color(0x…)` literal remains in `live_frame_view.dart`.
- **Harness/unit test: unchanged** — both read `LiveFrameView.placeholderColor`, which still exists (now a
  forwarding getter) and resolves to the same value, so `harness.dart:139` `showsPlaceholder` and
  `test/capture/live_frame_view_test.dart` track the placeholder with no edit and no dependence on a literal.
- **D-4 exemption retired (decision: Matt Quirk 2026-10-21, realises D-8).** VIEW-1 had moved the lone
  camera-device literal out of `capture_live_view.dart` into `live_frame_view.dart`; theming it left the D-4
  capture carve-out silencing nothing, which broke bs-17 AC-14's *load-bearing* augmentation
  (`design_system_test.dart:903`). Per Matt's choice (retire the exemption), set
  `kCaptureDeviceLiteralFiles = {}` in `design_system_source_scan.dart` and rewrote the augmentation
  (`design_system_test.dart:888–912`) to pin the empty set and assert `AppTheme` is the **sole** file-level
  exemption (a sweep exempting only the theme authority is empty). Core AC-14 rule unchanged and still fully
  enforced; no AC test weakened.
- **Gates:** analyze clean (3 touched items). Unit+coverage **PASS** — `flutter test --coverage test/` =
  **1687 passed**, exit 0; `coverage_gate.dart fdf794a` = **100% on both touched lib files**
  (`lib/app/theme.dart`, `lib/capture/live_frame_view.dart`). **bs-19 acceptance green both modes** —
  `preview_test.dart` 3/3 default + run-pending (AC-1/AC-2/AC-4), `reading/controls/permission/platform` 2/2/2/1
  default, `smoke_test.dart` 11/11. **bs-17 regression resolved** — `design_system_test.dart` **27/27**
  (AC-14 green; the three scan-helper tests green). **Grade A** (no AC test weakened; `placeholderColor`
  preserved as a forwarding getter, so `TestAC01`/`TestAC04` are behaviourally identical). **Fix passes: 1/3**
  (first full run surfaced AC-14's load-bearing augmentation still red after theming; resolved by the
  exemption-retirement decision, green thereafter).
- **Tokens/Time:** see dashboard (VIEW-4 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase:** `AppTheme.cameraPlaceholderSurface` is the single source of the live-preview
  placeholder grey; `LiveFrameView.placeholderColor` forwards to it (the harness/test anchor). `AppTheme` is
  now the **sole** AC-14 file-level exemption — `kCaptureDeviceLiteralFiles` is empty; re-adding a capture
  literal must be a deliberate, reviewed decision (D-4/D-8).
- **Verification commands:** `flutter test --coverage test/`; `dart run tool/coverage_gate.dart <BASE>`;
  acceptance per-file `flutter test -d flutter-tester integration_test/live_camera/<file>_test.dart`
  (`--dart-define=BS19_RUN_PENDING=true` for pending mode); regression
  `flutter test -d flutter-tester integration_test/design_system_test.dart`.
- **Known gaps:** none introduced. All 10 bs-19 ACs delivered and green; VIEW module complete.
- **Next:** re-run **SIGNOFF-1** — regenerate the packet with a clean full cross-feature regression (AC-14 now
  green), refresh cost-per-AC, surface the production-dormant-camera decision (§9) and the on-device
  walkthrough (D-5). The three carried off-lane flakes (bs-06 palette AC-3/AC-5, bs-08 display AC-9, bs-07
  self_assessment AC-4) are pre-existing, not bs-19's.

## Phase VIEW-5 — Native `CameraPreview` render (D-9)

- **Kind:** behavior (fix / fidelity) — **no new bs-19 AC of its own**; keeps AC-1 (`TestAC01_LivePreview`)
  and AC-4 (`TestAC04_ValueOnlyLive`) green, improves the on-device preview fidelity.
- **Why:** SIGNOFF-2's human review (Matt Quirk, 2026-10-22) found the on-device live preview is
  **rotated 90° CCW, super-pixelated and laggy**. Root cause: VIEW-1 renders the preview by *painting* the
  downsampled 64px sampling `Frame` through `_FramePainter` (`lib/capture/live_frame_view.dart`) — thousands
  of per-pixel `drawRect`s per frame on a CPU-converted 64×64 buffer with no sensor-orientation applied. The
  64px frame is the right, cheap input for the **reticle colour sample** (AC-3) but the wrong thing to show as
  the preview. **Decision (master D-9):** render the preview from the `camera` plugin's native
  `CameraPreview(controller)` (full-res, GPU-composited, orientation-correct); keep the `Frame` stream for
  colour sampling only.
- **Target AC:** — (fix). **Depends on:** VIEW-2, CAM-3, PERM-5 · **Blocks:** SIGNOFF-3
- **Files:** `lib/capture/capture_live_view.dart`, `lib/capture/live_frame_view.dart` (product); the
  `CameraCaptureSource` / `PluginCameraDevice` seam in `lib/capture/source/` (surface the plugin
  `CameraController` / a `Widget buildPreview()` seam to the view); possibly `lib/capture/capture_screen.dart`
  (thread the preview widget); `integration_test/live_camera/harness.dart` + `test/capture/*` as needed.
- **Tasks:**
  1. Expose the active camera's native preview to the view layer **without leaking the plugin into testable
     code**: add a seam on `CameraCaptureSource` (e.g. `Widget? buildPreview()` / `CameraController? get
     previewController`) that only `PluginCameraDevice` (the device-only, coverage-ignored implementation, D-5)
     fulfils with a real `CameraController`; the `ScriptedCameraSource` and `SoftwareCaptureSource` return null.
  2. In the live view, render `CameraPreview(controller)` (orientation handled by the plugin) **when** the
     active source provides a preview; otherwise fall back to the existing `LiveFrameView` frame-paint
     (scripted source → painted frame; software / no-camera → themed placeholder). Keep `liveViewKey` as the
     single stable anchor and keep the value-only saturation-0 `ColorFiltered` wrapping whichever surface
     renders (AC-4 invariant), with the readings/overlays as untouched outside-the-filter siblings.
  3. **Keep the `Frame` stream wired to sampling only** — `CaptureController.currentFrame` / the reticle
     sampler are unchanged; AC-3 (`reading follows the live frame`) must stay green. The preview no longer
     *depends* on `_FramePainter` for the real camera, but the painter stays for the scripted/fallback path.
  4. Fit the native preview to the view box (cover/fill) so it is not letterboxed, and confirm the grayscale
     filter still applies over it.
  5. The native-preview construction (`CameraPreview`, controller access) is device-only → `// coverage:ignore`
     (D-5), placed ABOVE any `@override` (the VIEW/CAM coverage-ignore gotcha). Unit-test every testable branch
     (seam returns null → paint path; non-null → preview path, exercised via a host fake, not the real plugin).
- **Exit criteria:** analyze clean; unit + coverage gate on touched lib (100% of testable lines; the
  `PluginCameraDevice` preview construction coverage-ignored, D-5). **bs-19 acceptance suite green both modes** —
  AC-1 `TestAC01_LivePreview` (scripted source still renders the painted frame, **no** placeholder, under
  `liveViewKey`) and AC-4 `TestAC04_ValueOnlyLive` in particular; AC-3 `TestAC03_ReadingFollowsFrame` still
  green (sampling unchanged). No new residual-literal offender (bs-17 AC-14 stays green). The carried off-lane
  flakes unchanged.
- **Acceptance gate:** no AC to un-pend (all delivered); keep AC-1/AC-3/AC-4 green; grade gate — re-grade the
  bs-19 suite A (confirm the render-path change did **not** weaken `TestAC01`/`TestAC04`: the scripted path must
  still assert the painted frame, and any new native-preview assertion that can't run under `flutter-tester`
  belongs in the device walkthrough, not a weakened test).
- **Augments:** none required (fix only; must not weaken any AC test). Optional: assert the preview seam is
  null for the scripted/software sources so the painted-frame path is the one AC-1 exercises (documents the
  test/device split without weakening the Then).
- **Device walkthrough (for SIGNOFF-3):** on the Pixel, the live preview is **upright, full-resolution and
  smooth** (not the 64px block mosaic), the reticle reading still tracks the scene, value-only greys the live
  preview, and lock/torch still work — exercises the `PluginCameraDevice` preview seam (D-5).

### Result
Rendered the on-device live preview from the camera plugin's native `CameraPreview` (D-9); the painted 64px
sampling `Frame` is now the reticle colour-sampling input only — **no AC un-pended** (fix), AC-1/AC-3/AC-4 kept
green, **grade A**.
- **New preview seam (host-testable, 100% covered):** added `Widget? buildPreview()` to the `CameraDevice`
  interface (`camera_capture_source.dart`); `CameraCaptureSource.buildPreview()` delegates to the device seam,
  and `CaptureController.previewWidget` surfaces it to the view **only when `source is CameraCaptureSource`**
  (the real device camera) — null for the software fallback and for the scripted acceptance source (not a
  `CameraCaptureSource`), so the painted-frame / placeholder path is unchanged under `flutter-tester`.
- **View render (`capture_live_view.dart`):** `CaptureLiveView` gained an optional `Widget? preview`; the feed
  surface is now `preview != null ? KeyedSubtree(key: liveViewKey, child: preview) : LiveFrameView(frame, key:
  liveViewKey)`. Either surface carries `liveViewKey` and sits inside the value-only saturation-0
  `ColorFiltered`, so the grayscale filter greys the native preview too (AC-4) and the readings stay outside it.
  `capture_screen.dart` passes `preview: controller.previewWidget` alongside the existing `frame:`.
- **Device-only (D-5):** `PluginCameraDevice.buildPreview()` (returns `CameraPreview(_controller)` once the
  controller is live, else null) is the sole new `// coverage:ignore` block, placed ABOVE `@override` (the
  VIEW/CAM coverage-ignore gotcha). Verified at the SIGNOFF-3 walkthrough. The `Frame` stream, `currentFrame`
  and the reticle sampler are untouched — AC-3 stays green.
- **Augmentations:** AC-1 (`TestAC01_LivePreview`) gained a non-weakening assertion that
  `h.controller.previewWidget` is null for the scripted source — it documents that AC-1 exercises the
  painted-frame path (the native path is device-only), without weakening the Then. No other AC test changed.
- **Gates:** analyze clean; unit+coverage **PASS** — `flutter test --coverage test/` **1699 passed** (1694 +5
  new), exit 0; `coverage_gate.dart badb334` = **100% on all 4 touched lib files** (`capture_controller.dart`,
  `capture_live_view.dart`, `capture_screen.dart`, `source/camera_capture_source.dart`). Acceptance **PASS** —
  bs-19 suite green **both modes**: `preview_test` 3/3, `reading_test` 2/2, `controls_test` 2/2,
  `permission_test` 2/2, `platform_test` 1/1, `smoke_test` 11/11. Regression **PASS** — bs-17
  `design_system_test.dart` **27/27** (AC-14 green; no new residual `Color(0x…)` literal). **Grade A**
  (AC-1/AC-3/AC-4 unweakened). **Fix passes: 0/3** (green on the first full run).
- **Tokens/Time:** see dashboard (VIEW-5 row) and the master ledger.

### Checkpoint / Handoff
- **Frozen this phase:** `CameraDevice.buildPreview()` → `CameraCaptureSource.buildPreview()` →
  `CaptureController.previewWidget` is the native-preview seam; the view renders it through the optional
  `CaptureLiveView.preview`, falling back to `LiveFrameView` (painted frame / themed placeholder). `liveViewKey`
  remains the single feed anchor and stays inside the value-only `ColorFiltered`.
- **Verification commands** (prepend `export PATH="$HOME/development/flutter/bin:$PATH"`; macOS has **no**
  `timeout`, run bare): `flutter test --coverage test/`; `dart run tool/coverage_gate.dart <BASE>`; acceptance
  per-file `flutter test -d flutter-tester integration_test/live_camera/<file>.dart`
  (`--dart-define=BS19_RUN_PENDING=true` for pending mode); regression
  `flutter test -d flutter-tester integration_test/design_system_test.dart`.
- **Known gaps:** the native `CameraPreview` render is device-only (coverage-ignored, D-5) — proven under host
  tests only through the seam; its on-device fidelity (upright / full-res / smooth) is confirmed at the
  SIGNOFF-3 walkthrough, not under `flutter-tester`.
- **Next:** **SIGNOFF-3** — fresh packet + full cross-feature regression + the on-device walkthrough (now also
  checking preview fidelity), then the human decision. Expect only the 3 carried off-lane flakes (bs-06 palette
  AC-3/AC-5, bs-08 display AC-9, bs-07 self_assessment AC-4).
