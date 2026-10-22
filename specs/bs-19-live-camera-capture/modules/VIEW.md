# Module VIEW — Live preview rendering

**Status:** 🔶 Reopened for VIEW-4 — VIEW-1/2/3 done; VIEW-4 (theme the placeholder, resolve bs-17 AC-14 regression) ⬜ Next
**Feature:** [MASTER_PLAN_FOR_FEATURE.md](../MASTER_PLAN_FOR_FEATURE.md)
**Owns (files/areas):** `lib/capture/capture_live_view.dart`, a frame-render widget (e.g. `lib/capture/live_frame_view.dart`), widget tests under `test/capture/`.
**Depends on:** CAM · **Blocks:** SIGNOFF-1

## Dashboard

| Phase | Kind | Target AC | Status | Tokens | Time |
|---|---|---|---|---|---|
| VIEW-1 | shell | — | ✅ Done | | |
| VIEW-2 | behavior | AC-1 | ✅ Done | 7.74M | 14m 54s |
| VIEW-3 | behavior | AC-4 | ✅ Done | 3.88M | 11m 59s |
| VIEW-4 | behavior (fix) | — (keeps AC-1/AC-4; resolves bs-17 AC-14) | ⬜ Next | | |

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
_pending — VIEW-4 not yet run._

### Checkpoint / Handoff
_pending._
