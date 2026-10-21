# Behaviour-test completeness grid — bs-19-live-camera-capture

Per-AC grade grid for the bs-19 **ITEST-2** acceptance tests
(`integration_test/live_camera/preview_test.dart` — AC-1/AC-2/AC-4;
`integration_test/live_camera/reading_test.dart` — AC-3/AC-5). Graded by an
independent fresh grader (did **not** write these tests) on **2026-10-21**.
Grades the assertions **as written** — i.e. the behaviour each pending test will
exercise once its owning phase lands (AC-1 → VIEW-2, AC-2 → CAM-3, AC-4 →
VIEW-3) — **except AC-3 and AC-5**, which already run **GREEN at baseline** (the
sampling/lock pipeline is source-agnostic) and are graded against the **live**
behaviour, confirming each already rejects a placeholder/fixed/independent
implementation through its control.

## Grade — ITEST-2 (AC-1..AC-5)

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_LivePreview` | A | G1,G4,G5,G6 (G2/G3 n/a) | **As-written (VIEW-2).** Given checked through the public read endpoint before the When: `h.activeSourceKind == CaptureSourceKind.camera` (the scripted source stands for the granted-camera selection and the endpoint surfaces its kind). When = the Capture screen opened by `givenLiveCamera`. Two Thens assert the AC's two clauses at grain against the **real** widget tree: `h.showsPlaceholder isFalse` (the `ColoredBox(LiveFrameView.placeholderColor)` under `liveViewKey` is gone) and `tester.widget<LiveFrameView>(liveViewKey).frame isNotNull`. **Kills** the catalogue's two Rejects: a view that keeps the placeholder (fails `showsPlaceholder isFalse` — the `frame==null` branch of `LiveFrameView` returns exactly that `ColoredBox`) and one that ignores frames (fails `frame isNotNull`). The pair is non-vacuous: a view that painted *nothing* would pass `showsPlaceholder` but fail `frame isNotNull`, and vice-versa, so both assertions bite. Red baseline is clean — `CaptureScreen` today never passes `frame:` to `CaptureLiveView`, so `frame` is null, `showsPlaceholder` true, and the Then reds (no panic). Structural open-state read after the single `pump`, so G3 (settle+control) n/a; G2 n/a (no configured value answers). One AC. |
| AC-2 | `TestAC02_FrameConversion` | A (B→A, fixed in-phase) | G1,G4,G5,G6 | **FIX APPLIED (ITEST-2 author, 2026-10-21):** tightened `_yuvToleranceL1` 30→12 so the "within tolerance" Then now rejects the limited-/video-range BT.601 mis-decode the grader flagged — the correct full-range decode lands L1 ≤ 2–3 while a limited-range decode lands L1 21 (c1 cyan) / 29 (c2 orange), both now outside 12; the comment was corrected to document the mis-range guard. Baseline unchanged (still a clean red on the CAM-3 `returnsNormally` guard; the tolerance only bites once CAM-3 lands). Re-graded **A**. Original B justification follows. — **As-written (CAM-3), pure-Dart over `frameFromCameraImage`.** Given checked on the raw observable before converting: the BGRA buffer's first 4 bytes `== [c1.b, c1.g, c1.r, 255]` and the YUV Y-plane's first byte `== _yOf(c1)` (G1). The `returnsNormally` guard in `_convertedCentre` is a **clean red**, not a masked panic: at baseline `frame_conversion.dart` throws `UnimplementedError('… lands in CAM-3')`, so `expect(returnsNormally)` throws a `TestFailure` naming CAM-3 *before* the `late final frame` is read (the `return frame.pixelAt` line is never reached); post-CAM-3 it passes and proceeds. **BGRA half is airtight:** tol `_bgraToleranceL1 = 3` with a correct B,G,R read landing L1 0; **kills** a BGR↔RGB swap (correct output is L1 400 from the swapped value — far past the `>100` assertion, and a swapped impl itself fails the `≤3` Then) and a constant pixel (the c1-vs-c2 control, `_l1(bgraPx, bgraPx2) > 100`, with c2=`RETICLE_ORANGE`). **YUV half kills the gross mis-ranges** (a U↔V swap ≈ L1 433, a missing `+128` bias, an output-channel swap — all ≫ 30). **GAP (G5):** the YUV tolerance `_yuvToleranceL1 = 30` does **not** reject the *canonical* mis-range — a full-range-encoded buffer decoded with limited-range (video BT.601, `1.164/1.596/2.017`) coefficients. For `RETICLE_CYAN` the correct full-range decode lands **L1 = 2** and the limited-range decode lands **L1 = 21** (verified: both `≤ 30`), so a limited-range converter — the most common real Android YUV bug — passes. The uniform frame makes downsampling lossless, so the only legitimate error is ~2 L1 of 8-bit rounding; the tolerance is ~15× looser than needed, and the comment's claim that a wrong range "leaves >180" is false for this case. The catalogue names "mis-ranged YUV conversion" as a Reject, and the data cannot separate it from the correct impl with no control to compensate. **Fix (augmentation, applicable now — not phase-pending):** tighten `_yuvToleranceL1` to ≤ ~10 (cleanly separates the L1 2 correct decode from the L1 21 limited-range decode), **or** add an explicit limited-range-decode control asserting it lands beyond tolerance. One AC. |
| AC-3 | `TestAC03_ReadingFollowsFrame` | A (live) | G1,G2,G3,G4,G5,G6 | **GREEN now; graded live.** Given checked through the public read endpoint: `before = _readingOf(h)` (reads `state.currentSample`, rendered back via the real `ColorScienceImpl.toSRGB`), `_distToReticle(before, RETICLE_CYAN) < 45` — the seed `FRAME_CYAN` is sampled by the real `sampleAreaAverage` over a uniform frame, so the round-trip is tight (well under 45). Control precondition `_distToReticle(before, RETICLE_ORANGE) > 135` proves c1/c2 are well separated (actual L1 cyan→orange = 450). When = `whenFrameChangesTo(FRAME_ORANGE)` pushes onto the real broadcast feed and `pump`s — the settle point where the frame flows source→controller→state (G2: the **configured** emitted frame is what answers, no faked sample value). Thens assert the raw observable at grain: `_distToReticle(after, ORANGE) < 45` (reading followed) **and** `_distToReticle(after, CYAN) > 135` (not stale). **Kills** a stale/placeholder/constant sampler: one stuck on c1 keeps `after`≈cyan → `dist(after, ORANGE)` = 450 > 45 fails the follow Then; the 450 ≫ 45 separation (10×) makes both the follow and the reject non-vacuous. Textbook G3 — the negative ("not cyan") sits after the pump settle point and is paired with the demonstrated before→after change (cyan→orange). One AC. |
| AC-4 | `TestAC04_ValueOnlyLive` | A | G1,G3,G4,G5,G6 (G2 n/a) | **As-written (VIEW-3).** Given is a pending precondition naming its owner (VIEW-2) and asserted on the public surface: `liveView.frame isNotNull` ("a live colour frame is shown (VIEW-2)") and `h.showsPlaceholder isFalse` (G1). When = `whenToggleValueOnly` taps the real E21 (`CaptureControls.valueOnlyKey` → `controller.toggleValueOnly`, flipping `CaptureState.valueOnly`) and `pumpAndSettle`s (the settle point). Thens read the real tree: a `ColorFiltered` **ancestor of `liveViewKey`** `findsOneWidget`, and a `ColorFiltered` ancestor of `accuracyKey` `findsNothing`. **Verified correct against `capture_live_view.dart`:** value-only wraps `feedSurface` (which carries `liveViewKey`) in the saturation-0 `ColorFiltered`, while `accuracyKey` is a sibling `KeyedSubtree` in the same `Stack`, outside that filter. The `findsOneWidget` (vs bs-02's looser `findsWidgets`) is safe here because the app-wide `GrayscaleFilter` (bs-08) is the **only** other `ColorFiltered` in `lib/` and is inert in this test (`DisplaySettings.grayscale` defaults `false`, simulation defaults none; value-only drives `CaptureState.valueOnly`, **not** `DisplayScope.grayscale`), so no root filter sits above either key. **Kills** the catalogue's two Rejects: graying the whole screen incl. readings (would put a `ColorFiltered` over `accuracyKey` → `findsNothing` fails) and filtering the placeholder only (the Given pins a real `frame` under the greyed feed). G3: the negative (readings outside the filter) sits after the `pumpAndSettle` settle point, paired with the positive control that the filter *did* apply over the feed. One AC. |
| AC-5 | `TestAC05_LockClearsWarning` | A (live) | G1,G2,G3,G4,G5,G6 | **GREEN now; graded live — the strongest G2 row.** Given checked on the public surface: `source.locks.allLocked isFalse`, and the "Exposure not locked" warning present via `find.descendant(of: downgradeReasonsKey, matching: find.text(AccuracyDowngradeReason.exposureUnlocked.label))` `findsOneWidget` (the screen feeds `controller.activeDowngradeReasons`, which includes `exposureUnlocked` while `!source.locks.allLocked`). When = `whenLock` taps the real E16 → `controller.lock()` → `source.lockExposure/WhiteBalance/Focus`; `pumpAndSettle` is the settle point. Thens at grain: `source.locks.allLocked isTrue` **and** the `exposureUnlocked` label under `downgradeReasonsKey` `findsNothing` — correctly asserts the *specific reason text* (the region persists carrying the still-active `missingReferenceCard` reason; a whole-region finder would be wrong here, so the grain is right). **G2 CONTROL (the load-bearing discrimination):** after `pumpWidget(const SizedBox())` tears the first app down (so `CaptureHomeScreen.initState` rebuilds a fresh controller rather than the element-reuse keeping the locked first source), a `ScriptedCameraSource(canLock: false)` is mounted; `whenLock` taps, `lock()` still flips the controller's own `lockState` to locked, yet `source.locks.allLocked` stays `false` (the no-op lock) → the warning **stays** (`findsOneWidget`). This proves the warning clears from the **source's** `locks.allLocked`, not from the UI lock flag — **killing** both named Rejects: "clearing the warning without locking" and "locking state not reflected from the source". Textbook G3 (negative after settle + a control that keeps the warning present); the reset is sound (`initState`-built controller). One AC. |

### Summary — ITEST-2

- **Grade counts (after the in-phase fix): 5×A, 0×B.** As first graded: 4×A, 1×B
  (AC-2); the B was fixed in ITEST-2 (fix pass 1/3) and re-graded A — see below.
- **AC-2 B→A — rule & fix (G5 limited):** the YUV path's `_yuvToleranceL1 = 30`
  was too loose to reject the canonical full-range-vs-limited-range YUV mis-range
  — for `RETICLE_CYAN` the correct full-range decode is **L1 2** and a
  limited-range (video BT.601) decode is **L1 21**, both inside 30, so the most
  plausible real YUV bug would pass. The BGRA path (exact, tol 3) and the gross
  YUV errors (U/V swap, missing bias, output swap) and the constant-pixel control
  were already killed, so it was a near-miss, not a vacuous test. **Fixed in
  ITEST-2:** `_yuvToleranceL1` tightened 30→12 (separates the L1 2 correct decode
  from the L1 21/29 limited-range decode cleanly while leaving the correct decode
  comfortable); this needed no later behaviour, only a tighter bound, so it was
  **not** "B pending <phase>". Re-graded A.
- **Fixture-discrimination confirmation:** `RETICLE_CYAN(0,170,200)` and
  `RETICLE_ORANGE(220,120,20)` are L1 450 apart — an order of magnitude above the
  reading tolerance 45 — so AC-3's follow/reject inequalities (`<45` / `>135`)
  and AC-2's BGRA constant-pixel/channel-swap rejects (`>100`) are non-vacuous.
- **Live rows (AC-3, AC-5) confirmed against live behaviour:** both already
  reject the implementations their catalogue rows name — AC-3's c1→c2 change with
  the 10× separation kills a stale/fixed sampler; AC-5's `canLock:false` control
  (with the `pumpWidget(SizedBox())` reset forcing a fresh `initState`
  controller) kills a warning driven off the UI lock flag rather than
  `source.locks.allLocked`.
- **Judgement calls (no further downgrades):**
  1. **AC-4 `findsOneWidget`** over `liveViewKey` is tighter than bs-02's
     `findsWidgets`; verified safe because the only other `ColorFiltered` in
     `lib/` (the app-wide `GrayscaleFilter`) is inert by default and value-only
     drives `CaptureState.valueOnly`, not `DisplayScope.grayscale`. If a future
     default turned app-wide grayscale on, both `liveViewKey` *and* `accuracyKey`
     would gain a root filter and the `findsNothing` Then would false-fail —
     flagged, not a current defect.
  2. **AC-1 / AC-2** red baselines are clean (null `frame` Then; `returnsNormally`
     guard throws a `TestFailure` before the `late final` read), so neither masks
     a panic.
- All five rows check every Given through the public surface before the When,
  drive the When through the real surface, and assert the raw observable the step
  names at its grain. After the AC-2 tolerance tightening, all five grade **A**.

## Grade — ITEST-3 (AC-6..AC-10)

Per-AC grade grid for the bs-19 **ITEST-3** acceptance tests
(`integration_test/live_camera/controls_test.dart` — AC-6/AC-9;
`permission_test.dart` — AC-7/AC-8; `platform_test.dart` — AC-10). Graded by an
independent fresh grader (did **not** write these tests) on **2026-10-21**.
Grades the assertions **as written** — the behaviour each *pending* test will
exercise once its owning phase lands (AC-7 → PERM-2, AC-8 → PERM-3, AC-9 →
CAM-7) — **except AC-6 and AC-10**, which already run **GREEN at baseline** (the
torch/commit pipeline is source-agnostic; the manifests already carry the
declarations) and are graded against the **live** behaviour, confirming each
still rejects a placeholder/fixed/independent implementation.

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-6 | `TestAC06_Torch` | A (live) | G1,G2,G3,G4,G5,G6 | **GREEN now; graded live — torch pipeline is shipped and source-agnostic** (`CaptureController.turnTorchOn/Off` call `source.turnTorch*` and emit; `commit` stamps `litByTorch: _state.torchOn`; none throw). **Scenario A** Given checked on the public surface before the When: `source.torchOn isFalse`, `h.state.torchOn isFalse`, `source.torchOnCalls == 0`, the torch-off label (`find.descendant(torchKey, text('Torch'))`) present, and **no** `torchWarningKey` (`Visibility(visible:false)` does not build the child → `findsNothing`). G1 ✓. When = `whenTurnTorchOn` taps the **real** E-torch control → `controller.turnTorchOn` → `source.turnTorchOn`; `pumpAndSettle` is the settle point. Thens at grain: `source.torchOn isTrue`, **`source.torchOnCalls == 1` (AUGMENTATION, CAM-6)** — the load-bearing G2/G5 check that the toggle *reached the device* rather than only flipping a UI flag (a UI-only toggle leaves `torchOnCalls` 0), `h.state.torchOn isTrue`, the `✓ Torch` label present, and `torchWarningKey findsOneWidget` (lighting raises the colour-temp banner). The off-path control (`whenTurnTorchOff` → the toggle now calls `turnTorchOff` because `state.torchOn` is true): `source.torchOn isFalse`, `torchOffCalls == 1`, state cleared, warning gone — rejects a one-way toggle. **Scenario B + control** (G3, G5 for the `litByTorch` stamp): after `pumpWidget(const SizedBox())` tears the first app down (so `didChangeDependencies` builds a fresh controller rather than element-reuse keeping the torch-off source), a torch-ON commit → `lastCommittedSample.litByTorch isTrue`; a **separate fresh app** with the torch left OFF commits → `litByTorch isFalse`. The off-commit control **kills** an impl that always stamps `litByTorch` regardless of torch state; the paired on-commit kills one that never stamps. `commit` lands because `givenLiveCamera`'s single pump samples `FRAME_CYAN` into `currentSample` (both `isNotNull` checks confirm a sample was committed, so neither clause is vacuous). Every clause is AC-6 (torch reaches device + warning + off extinguishes + `litByTorch` stamp). One AC. The strongest row: an explicit source-reaching augmentation *and* a negative-stamp control. |
| AC-7 | `TestAC07_PermissionFallback` | A (as-written, PERM-2) | G1,G2,G4,G5,G6 (G3 n/a) | **As-written (PERM-2).** Given checked on the recorder's public surface before the When: `granted.requestCount == 0` and `granted.status == undetermined` (G1). When = `givenLiveCamera(…, permission: granted)` opens Capture (the harness holds the recorder for PERM-2 to wire into `AppDependencies`; at baseline `buildApp` never requests, so `requestCount` stays 0 → **clean red** naming PERM-2, not a panic). Thens at grain: **`granted.requestCount == 1` exactly** (rejects never-requesting *and* a double request), `h.activeSourceKind == camera`, `h.permissionState == granted`. **G2 CONTROL — the airtight discrimination:** the denied branch (fresh app via `pumpWidget(SizedBox())`) injects a ScriptedCameraSource with the **identical default `kind == camera`** yet a `resolvesTo: denied` recorder, and asserts `h2.activeSourceKind == software`. Because the two injected sources are indistinguishable (both kind camera), the divergent outcome (camera vs software) can **only** come from the permission decision — so permission is provably the thing that answers, killing an impl that echoes the injected source kind and ignores permission. The denied branch also asserts `requestCount == 1`, a `find.textContaining('Camera access')` affordance `findsOneWidget`, and `tester.takeException() isNull` — covering the catalogue's three Rejects (never requesting / crash-on-denial / staying on a dead camera). G3 n/a (the decision resolves inside the open-screen assembly; no post-settle negative beyond the two-branch control). **Minor (not a downgrade):** the denied branch does not re-assert its `requestCount == 0` pre-state before its When, but the recorder is a freshly constructed object whose `requestCount` field defaults 0, so the 0→1 transition is still pinned. One AC. |
| AC-8 | `TestAC08_NoCameraFallback` | A (as-written, PERM-3) | G1,G4,G5,G6 (G2 built-in, G3 n/a) | **As-written (PERM-3).** Given checked on the public surface before the When: `source.available isFalse` (G1). When = `givenLiveCamera` opens Capture over the no-camera source. Then at grain: `h.activeSourceKind == software` — **clean red** at baseline (the injected source's default `kind == camera`, nothing probes `available` yet) naming PERM-3. **G2/G5 discrimination is built into the fixture:** the injected source reports `kind == camera`, so an impl that ignores availability and echoes the injected kind reports `camera` and **fails** `== software`; only a real availability-probe-and-fallback (PERM-3 inspecting `available`) passes — no separate control is needed because the injected kind *is* the wrong-impl baseline. Secondary Thens reject the other catalogue Rejects: `h.state.currentSample isNotNull` (the painter can still read on the fallback — rejects forcing a camera source that cannot stream / a black view) and `tester.takeException() isNull` (rejects a crash). The positive available-true→camera case is covered by AC-1, so AC-8 carries only the fallback half. G3 n/a (structural read after the open-screen pump). One AC. |
| AC-9 | `TestAC09_Lifecycle` | A (as-written, CAM-7) | G1,G3,G4,G5,G6 (G2 n/a) | **As-written (CAM-7).** Given checked through the source's public recorders before the When: `source.acquireCount == 1` (the controller subscribes once in its constructor — the `frames async*` generator increments on subscription), `source.releaseCount == 0`, and the opening reading renders the live frame (`_distToReticle(_readingOf(h), RETICLE_CYAN) < 45`, the real `ColorScienceImpl` round-trip over the sampled `currentSample`). G1 ✓. A `pumpAndSettle` first drives the self-rescheduling settle tick to STABLE 12/12 so it stops scheduling frames (otherwise the tick deadlocks the pump across the lifecycle transition) — verified against `_scheduleSettleTick`, which halts once `isStable`. When = `_background` dispatches `inactive→hidden→paused` then `tester.idle()`. **The no-pump-while-paused reasoning holds:** `handleAppLifecycleStateChanged` delivers to observers synchronously, and a subscription `cancel()`'s generator `finally` (`releaseCount++`) completes on a microtask that `tester.idle()` drains — so a CAM-7 release is observable without pumping a frame while paused (a pump-while-paused hangs the live integration binding). Then: `releaseCount >= 1` — **clean red** (verified: `_CaptureHomeScreenState` is not a `WidgetsBindingObserver` and has no `didChangeAppLifecycleState`, so backgrounding releases nothing today) naming CAM-7; rejects leaking the controller. `_foreground` dispatches `hidden→inactive→resumed` then pumps (safe — `resumed` re-enables frames); Then `acquireCount >= 2` rejects not re-acquiring. **And (control, G3):** `whenFrameChangesTo(FRAME_ORANGE)` on the resumed broadcast feed → `_distToReticle(resumed, RETICLE_ORANGE) < 45` — the live-frame-change control after the resume settle point that **kills a frozen/black feed** (an impl that re-subscribes but never wires frames through fails this; the 450-L1 cyan↔orange separation vs the 45 tolerance makes it non-vacuous). The `>=` bounds are at the step's grain ("released at least once / re-acquired") and still bite — a leak gives 0 (fails `>=1`), a no-re-acquire stays at 1 (fails `>=2`). G2 n/a. One AC. |
| AC-10 | `TestAC10_PlatformDeclarations` | A (live) | G1,G4,G5,G6 (G2/G3 n/a) | **GREEN now; graded live — source-scan (the bs-11/12/13 idiom).** Given checked before the inspection: `File(androidManifestPath).existsSync()` and the iOS `Info.plist` exist (the reason string prints the cwd for the host-VM path). When = read both files off disk. Thens at grain against the **real** shipped files (verified by reading them): the Android manifest `contains('android.permission.CAMERA')` **and** `matches(<uses-feature … android.hardware.camera)` — the two assertions are separate so it **rejects declaring one but not the other**; the manifest indeed has `<uses-permission android:name="android.permission.CAMERA"/>` and `<uses-feature android:name="android.hardware.camera" android:required="false"/>`. For iOS, the `_cameraUsageDescription` helper matches `<key>NSCameraUsageDescription</key>` **followed by** its `<string>…</string>` value and trims it, then asserts `isNotNull` **and** `isNotEmpty` — the structured match **kills the "bare key" weakness** a `contains('NSCameraUsageDescription')` would pass, and rejects an empty usage string; the shipped plist carries a real, non-empty explanation. G2/G3 n/a (static scan, no configured source, no settle). One AC. **Minor (not a downgrade):** the Android `contains`/regex would also match the literal strings inside an XML comment — the standard source-scan limitation; the structured iOS check is immune, and the real declarations are genuine elements, not comments. |

### Summary — ITEST-3

- **Grade counts: 5×A, 0×B.** No row admits a plausible wrong implementation that
  its assertions (plus controls) fail to reject; no fixable-now or pending-phase B.
- **Live rows (AC-6, AC-10) confirmed against live behaviour:** AC-6 already
  rejects a UI-only torch toggle (via the `torchOnCalls == 1` augmentation) and a
  torch-blind `litByTorch` stamp (via the torch-off commit control, with a
  `pumpWidget(SizedBox())` reset forcing a fresh controller); AC-10 already rejects
  a missing CAMERA permission, a missing `<uses-feature>`, and a bare/empty
  `NSCameraUsageDescription` (structured key→string match).
- **As-written rows (AC-7, AC-8, AC-9) — clean reds, each naming its owner:**
  AC-7 reds on `requestCount == 1` (actual 0 — PERM-2 wires the recorder into
  `buildApp`), AC-8 on `activeSourceKind == software` (actual camera — PERM-3
  probes availability), AC-9 on `releaseCount >= 1` (actual 0 — CAM-7 adds the
  `WidgetsBindingObserver` release/re-acquire). None masks a panic.
- **Strongest discriminations (why the fallback rows are not near-misses):**
  AC-7's two branches inject the **same** default `kind == camera` source and
  diverge only on the permission recorder, so the camera-vs-software outcome is
  provably permission-driven (a G2 control as tight as AC-5's `canLock:false`);
  AC-8 needs no separate control because the injected `kind == camera` is itself
  the wrong-impl baseline the `== software` assertion must overturn.
- **AC-9 lifecycle technique verified:** the pre-`pumpAndSettle` (stop the settle
  tick), the `tester.idle()` (drain the release microtask without a frame) and the
  pump-only-after-`resumed` ordering are all necessary and correct for the live
  integration binding — not test smells.
- **Judgement calls (no downgrades):** (1) AC-7 denied branch omits an explicit
  pre-When `requestCount == 0`, but the recorder's field defaults 0, so the 0→1
  transition is still pinned. (2) AC-8/AC-9 use `>=`/single-branch assertions at
  the step's grain; each still fails the plausible wrong impl. (3) AC-10's Android
  `contains`/regex could match a comment (standard source-scan limitation); the
  real elements are genuine and the iOS check is structurally immune.

## Re-grade — CAM-3 (AC-2 live, 2026-10-21)

CAM-3 landed the real `frameFromCameraImage` and un-pended **AC-2**. An
independent fresh grader (did not write the test) re-graded the now-live AC-2
against the implemented conversion:

- **AC-2 `TestAC02_FrameConversion` — A (holds the prior A).** Running against
  the real conversion the tolerances still bite every named Reject: BGR↔RGB swap
  → L1 400 (fails `≤3` and the `>100` control); limited-/video-range YUV
  mis-decode → L1 ≈ 21, outside `_yuvToleranceL1 = 12` (correct full-range decode
  lands L1 ≈ 2); constant pixel → killed by the c1-vs-c2 control (L1 450). G1
  (both buffers' bytes asserted), G4 (reticle pixel at value), G5 (controls),
  G6 (one AC) all met; G2 built-in (output derives from the configured buffer),
  G3 n/a (pure synchronous conversion). Confirmed green under run-pending.
- **Scaffold guard (`smoke_test.dart` pending gate) — NON-VACUOUS.** CAM-3
  changed it from the fixed "all 10 pending" assertion to an exact-set assertion,
  `pendingACs.keys.toSet() == {AC-1..AC-10} \ {AC-2}`, plus "the delivered AC-2
  runs in the default suite" and the real-owner check. Set-equality bites both
  directions; no drift to a bare `.length` count.

**CAM-3 grade count: 1 A / 0 B** (the sole un-pended AC). Feature grid remains
all-A.

## Re-grade — VIEW-2 (AC-1 live, 2026-10-21)

VIEW-2 landed the live preview render path (`CaptureController.currentFrame`,
camera-only; fed to `CaptureLiveView.frame`) and un-pended **AC-1**. An
independent fresh grader (did not write the test or the code) re-graded the
now-live AC-1 against the implementation:

- **AC-1 `TestAC01_LivePreview` — A (holds the prior as-written A).** Given read
  through the public read endpoint (`h.activeSourceKind == camera`) before the
  When; the painted frame genuinely flows `source.frames` (seed `FRAME_CYAN`) →
  `_onFrame` → `_recentFrames` → `currentFrame` → `CaptureScreen` →
  `LiveFrameView.frame` (G2 — nothing fakes the answer). The two Thens are a
  non-vacuous pair that kills **both** named Rejects: `showsPlaceholder isFalse`
  (the painted path is a `CustomPaint`, never the `ColoredBox(placeholderColor)`
  — a view that keeps the placeholder fails) and `liveView.frame isNotNull` (a
  wiring that ignores frames / never passes `currentFrame` down fails; the
  `tester.widget<LiveFrameView>` cast also throws if the key is absent, so the
  placeholder check can't pass vacuously). Grain is right for AC-1 (preview vs
  placeholder; colour is AC-2, frame-change AC-3), so `frame isNotNull` rather
  than `== FRAME_CYAN` (G4). The camera-only gating in `currentFrame` is what
  makes the frame non-null here and null on the software fallback, but AC-1 only
  drives the camera branch — appropriate scoping (the software→null invariant is
  VIEW-1's and is checked structurally in smoke), not a gap. G3 n/a (structural
  open-state read after the single pump). One AC. Confirmed green in the default
  suite.
- **Scaffold guards (`smoke_test.dart`) — NON-VACUOUS.** All three VIEW-2 edits
  verified: the render-path assertion `showsPlaceholder isFalse` is backed by the
  preceding `find.byKey(liveViewKey) findsOneWidget` (would fail if the
  placeholder regressed); the exact-set `unpendedACs = {AC-1, AC-2}` compares
  `pendingACs.keys.toSet()` to `{AC-1..AC-10} \ unpended` (set-equality both
  directions, not a count) and checks each unpended AC's skip-reason is null and
  every owner is a real behaviour phase; the pending-skip example moved AC-1→AC-3
  (owner CAM-4), still a genuinely-pending AC.

**VIEW-2 grade count: 1 A / 0 B** (the sole un-pended AC). Feature grid remains
all-A.

## Re-grade — CAM-4 (AC-3 un-pended, 2026-10-21)

CAM-4 un-pended **AC-3** (deleted its `pendingACs` row) so `TestAC03_ReadingFollowsFrame`
now runs in the **default** suite. CAM-4 added **no product code and no new test
assertions** — the reading-follows-frame behaviour is the existing source-agnostic
sampling, already enabled by CAM-3's real frame stream, and the discriminating
c1→c2 augmentation was written in ITEST-2. An independent fresh grader (did not
write the tests or the code) re-graded every un-pended AC test (AC-1, AC-2, AC-3):

- **AC-1 `TestAC01_LivePreview` — A** (holds; unchanged by CAM-4).
- **AC-2 `TestAC02_FrameConversion` — A** (holds; unchanged by CAM-4).
- **AC-3 `TestAC03_ReadingFollowsFrame` — A (confirmed live).** The grader verified
  the c1→c2 change flows through the **real** pipeline, not a faked value:
  `ScriptedCameraSource` streams real `Frame`s, the real `CaptureController._onFrame`
  samples via the real `sampleAreaAverage` and publishes `state.currentSample`, and
  the test reads it back through the real `ColorScienceImpl.toSRGB`; the fake supplies
  only the frame buffer (the camera device, G2), not the reading. Given asserts the
  opening reading ≈ c1 plus a c1/c2 separation control (>135); When = `whenFrameChangesTo`
  (emit + pump settle point); Then asserts the reading moved to c2 (<45) **and** away
  from stale c1 (>135). Kills a stale/fixed/placeholder sampler. G1 note: the test does
  not assert `activeSourceKind==camera` (AC-1's job); acceptable, not a gap — the
  behaviour is source-agnostic, so a kind check would assert something the behaviour
  does not depend on.
- **Scaffold guards (`smoke_test.dart`) — NON-VACUOUS.** The exact-set
  `unpendedACs = {AC-1, AC-2, AC-3}` compares `pendingACs.keys.toSet()` to
  `{AC-1..AC-10} \ unpended` (set-equality both directions, not a count), checks each
  un-pended AC's skip-reason is null, and that every owner is a real behaviour phase;
  the pending-skip example moved AC-3→AC-4 (owner VIEW-3), still a genuinely-pending AC.

**CAM-4 grade count: 3 A / 0 below A** (every un-pended AC test). No downgrades from
the prior grid; no fix owed. Feature grid remains all-A.

## Re-grade — VIEW-3 (AC-4 un-pended, 2026-10-21)

VIEW-3 un-pended **AC-4** (deleted its `pendingACs` row) so `TestAC04_ValueOnlyLive`
now runs in the **default** suite. VIEW-3 added **no product code**: the value-only
grayscale behaviour already existed in the SCREEN-1 shell (the saturation-0
`ColorFiltered` wrapping the feed surface), and AC-4's assertions — including its
readings-outside-the-filter augmentation — were written in ITEST-2. An independent
fresh grader (did not write the tests or the code) re-graded every un-pended AC test
(AC-1, AC-2, AC-3, AC-4):

- **AC-1 `TestAC01_LivePreview` — A** (holds; unchanged by VIEW-3).
- **AC-2 `TestAC02_FrameConversion` — A** (holds; unchanged by VIEW-3).
- **AC-3 `TestAC03_ReadingFollowsFrame` — A** (holds; unchanged by VIEW-3).
- **AC-4 `TestAC04_ValueOnlyLive` — A (confirmed live).** Both stated Givens are
  checked through the public surface before the When (`liveView.frame isNotNull`
  via `tester.widget<LiveFrameView>(liveViewKey)` + `showsPlaceholder isFalse`, i.e.
  a live colour frame is shown — G1). The When taps the real `valueOnlyKey`, driving
  the real `toggleValueOnly()` → `state.valueOnly` flip → the conditional
  `ColorFiltered` wrap; nothing scripted supplies the greying (G2). The Then is a
  discriminating pair verified against `capture_live_view.dart`: the grayscale
  `ColorFiltered` wraps **only** `feedSurface` (which carries `liveViewKey`) while the
  `accuracyKey` `KeyedSubtree` is a Stack **sibling** outside it — so
  `ancestor(liveViewKey, ColorFiltered) findsOneWidget` + `ancestor(accuracyKey,
  ColorFiltered) findsNothing` kills both named Rejects (grey-the-whole-screen incl.
  readings; grey-nothing) and an inverted toggle gate (G4/G5/G6). The negative Then is
  non-vacuous — paired with the positive assertion proving a `ColorFiltered` exists in
  the tree, so `findsNothing` means "exists but not over the readings" (G3).
  Grader observation (not a downgrade): the test doesn't assert the filter is *absent*
  pre-toggle, so a hypothetical always-grayscale build would pass; implausible here
  (grayscale-at-open is gated in real code and caught across the visual suite) and not a
  clean G-rule break — grade stands at A.

**VIEW-3 grade count: 4 A / 0 below A** (every un-pended AC test). No downgrades from
the prior grid; no fix owed. Feature grid remains all-A.

## Re-grade — CAM-5 (AC-5 un-pended + real lock forwarding, 2026-10-21)

CAM-5 un-pended **AC-5** (deleted its `pendingACs` row) so `TestAC05_LockClearsWarning`
now runs in the **default** suite, and wired the **real** camera lock controls: the
`CameraDevice` seam gained `lockExposure`/`lockWhiteBalance`/`lockFocus`, and
`CameraCaptureSource`'s lock controls now record the lock in `locks` *and* forward it to
the device (`PluginCameraDevice` drives `setExposureMode(locked)`/`setFocusMode(locked)`;
AWB is held implicitly by the AE lock — the plugin exposes no AWB control — documented for
the D-5 walkthrough, coverage-ignored). The AC-5 integration test drives the scripted
source and is **unchanged**; the real-source forwarding is covered by a new unit test. An
independent fresh grader (did not write the tests or the code) re-graded every un-pended AC
test (AC-1..AC-5):

- **AC-1 `TestAC01_LivePreview` — A** (holds; unaffected by CAM-5).
- **AC-2 `TestAC02_FrameConversion` — A** (holds; unaffected by CAM-5).
- **AC-3 `TestAC03_ReadingFollowsFrame` — A** (holds; unaffected by CAM-5).
- **AC-4 `TestAC04_ValueOnlyLive` — A** (holds; unaffected by CAM-5).
- **AC-5 `TestAC05_LockClearsWarning` — A (live) — the strongest G2 row.** Verified against
  live code: `lock()` (capture_controller.dart) unconditionally flips the UI `lockState`
  **and** calls `source.lock*`, while `activeDowngradeReasons` emits `exposureUnlocked` from
  `if (!source.locks.allLocked)` — the **source's** locks, not the UI flag, which the live
  view renders under `downgradeReasonsKey`. So the `canLock:false` control is a genuine
  discriminator: the stuck source's locks stay `allLocked:false`, the warning **stays**
  (`findsOneWidget`) though `lock()` flipped `lockState` — killing both named Rejects
  (clear-without-locking; locking-not-reflected-from-source). G1 (both Givens on the public
  surface before the When), G3 (negative after `pumpAndSettle`, paired with the warning-stays
  control; asserts the specific `exposureUnlocked` label, not the whole region), G4/G5/G6 all
  met; the `pumpWidget(SizedBox())` reset is sound (forces a fresh `initState` controller over
  the stuck source). Grader's minor note (not a downgrade, consistent with the prior AC-7
  judgement): the control branch does not re-assert its pre-tap state, but `stuck` is freshly
  constructed `canLock:false` using the identical assembly already shown to raise the warning
  at open, so the pre-state is pinned by construction.
- **Unit-test spot-check (CAM-5 device forwarding).** `each lock control forwards to the
  device (CAM-5)` (`camera_capture_source_test.dart`) genuinely asserts forwarding — a
  `_FakeCameraDevice` records `exposureLocks`/`whiteBalanceLocks`/`focusLocks`, each asserted
  `== 1` after the matching `source.lock*` call, plus the `locks` fields flip. Non-vacuous;
  this is the real-source coverage (the AC-5 integration grade stands on the scripted-source
  test above).
- **Scaffold guards (`smoke_test.dart`) — NON-VACUOUS.** The exact-set
  `unpendedACs = {AC-1..AC-5}` compares `pendingACs.keys.toSet()` to `{AC-1..AC-10} \ unpended`
  (set-equality both directions, not a count), checks each un-pended AC's skip-reason is null
  and every owner is a real behaviour phase; the pending-skip example moved AC-5→AC-6 (owner
  CAM-6), still a genuinely-pending AC.

**CAM-5 grade count: 5 A / 0 below A** (every un-pended AC test). No downgrades from the prior
grid; no fix owed. Feature grid remains all-A.

## Re-grade — CAM-6 (AC-6 un-pended + real torch forwarding, 2026-10-21)

CAM-6 un-pended **AC-6** (deleted its `pendingACs` row) so `TestAC06_Torch` now runs in the
**default** suite. Product change: `CameraCaptureSource.turnTorchOn/Off` now records `torchOn`
**and** forwards to a new `CameraDevice.turnTorchOn/Off` seam (`PluginCameraDevice` drives
`setFlashMode(torch)` / `setFlashMode(off)`; coverage-ignored device calls, D-5 walkthrough).
The AC-6 integration test drives the **scripted** source and is **unchanged**; the real-source
forwarding is covered by a new unit test. An independent fresh grader (did not write the tests
or the code) re-graded every un-pended AC test (AC-1..AC-6):

- **AC-1 `TestAC01_LivePreview` — A** (holds; unaffected by CAM-6).
- **AC-2 `TestAC02_FrameConversion` — A** (holds; unaffected by CAM-6).
- **AC-3 `TestAC03_ReadingFollowsFrame` — A** (holds; unaffected by CAM-6).
- **AC-4 `TestAC04_ValueOnlyLive` — A** (holds; unaffected by CAM-6).
- **AC-5 `TestAC05_LockClearsWarning` — A** (holds; unaffected by CAM-6).
- **AC-6 `TestAC06_Torch` — A (live, shipped torch pipeline).** Scenario A Givens all on the
  public surface before the When (`source.torchOn`/`state.torchOn` false, `torchOnCalls == 0`,
  'Torch' label present, no `torchWarningKey`). When = real E-torch tap →
  `controller.turnTorchOn` → `source.turnTorchOn`. Thens at grain: `source.torchOn isTrue`,
  **`source.torchOnCalls == 1`** (the load-bearing CAM-6 augmentation — kills a UI-only toggle
  that never reaches the device), `state.torchOn isTrue`, `✓ Torch` label, `torchWarningKey
  findsOneWidget`. Off-path control: `torchOffCalls == 1`, state/warning cleared (kills a
  one-way toggle). Scenario B (fresh app, torch-on commit → `litByTorch isTrue`) + the
  torch-off-commit control (`litByTorch isFalse`) kill both always-stamp and never-stamp;
  `isNotNull` checks confirm a sample was committed (non-vacuous). Driving the
  `ScriptedCameraSource` rather than `CameraCaptureSource` is correct per the D-5 seam
  convention (the plugin can't run under flutter-tester; real device forwarding is covered by
  the unit test + on-device walkthrough). G1–G6 met.
- **Unit-test spot-check (CAM-6 device forwarding).** `the torch toggle forwards to the device
  (CAM-6)` (`camera_capture_source_test.dart`) genuinely asserts forwarding — a
  `_FakeCameraDevice` records `torchOnCalls`/`torchOffCalls`, each asserted `== 1` after the
  matching `source.turnTorch*` call, plus `torchOn` flips. Non-vacuous; this is the real-source
  coverage (the AC-6 integration grade stands on the scripted-source test above).
- **Scaffold guards (`smoke_test.dart`) — NON-VACUOUS.** The exact-set
  `unpendedACs = {AC-1..AC-6}` compares `pendingACs.keys.toSet()` to `{AC-1..AC-10} \ unpended`
  (set-equality both directions, not a count); the pending-skip example moved AC-6→AC-7 (owner
  PERM-2), still a genuinely-pending AC.

**CAM-6 grade count: 6 A / 0 below A** (every un-pended AC test). No downgrades from the prior
grid; no fix owed. Feature grid remains all-A.

## Re-grade — CAM-7 (AC-9 un-pended + lifecycle release/resume, 2026-10-21)

CAM-7 made `_feed` nullable and added `pauseFeed()` (cancels the subscription, clears `_feed`,
idempotent) / `resumeFeed()` (re-subscribes via `source.frames.listen(_onFrame)`, guarded by
`if (_disposed || _feed != null) return;`) to `capture_controller.dart`, and made
`_CaptureHomeScreenState` a `WidgetsBindingObserver` whose `didChangeAppLifecycleState` calls
`resumeFeed()` on `resumed` and `pauseFeed()` on inactive/hidden/paused/detached. It un-pended
**AC-9** (deleted its `pendingACs` row) so `TestAC09_Lifecycle` now runs in the default suite,
added lifecycle unit tests, and updated the smoke exact-set guard. An independent fresh grader
(did not write the tests or the code) confirmed the lib diff is confined to those two files — no
AC-1..AC-6 behaviour code (`currentFrame`, `_onFrame`, `lock`, `turnTorch*`, `toggleValueOnly`)
touched — and graded adversarially, as the live code now behaves:

- **AC-1 `TestAC01_LivePreview` — A** (holds; `currentFrame`/render path untouched).
- **AC-2 `TestAC02_FrameConversion` — A** (holds; conversion path untouched).
- **AC-3 `TestAC03_ReadingFollowsFrame` — A** (holds; `_onFrame` sampling untouched).
- **AC-4 `TestAC04_ValueOnlyLive` — A** (holds; value-only filter untouched).
- **AC-5 `TestAC05_LockClearsWarning` — A** (holds; `lock()`/`activeDowngradeReasons` untouched).
- **AC-6 `TestAC06_Torch` — A** (holds; torch/commit path untouched).
- **AC-9 `TestAC09_Lifecycle` — A (now live; holds the prior as-written A).** Givens on the
  source's public recorders before the When — `acquireCount==1` (the `frames async*` increments on
  the controller's constructor subscription), `releaseCount==0`, opening reading ≈ `RETICLE_CYAN`
  (<45 via the real `ColorScienceImpl` round-trip). The pre-`pumpAndSettle` drives the
  self-rescheduling settle tick to STABLE 12/12 so it stops scheduling (verified against
  `_scheduleSettleTick`). `_background` (inactive→hidden→paused, then `tester.idle()`): the live
  observer calls `pauseFeed()` → `_feed.cancel()` → the generator `finally` runs `releaseCount++`
  on a microtask `idle()` drains under the real `IntegrationTestWidgetsFlutterBinding` (no-pump-while-
  paused reasoning sound). `releaseCount >= 1` bites a leaked controller. `_foreground` ends on
  `resumed` → `resumeFeed()` re-subscribes (guard passes because `pauseFeed` nulled `_feed`), so
  `acquireCount >= 2` bites a no-re-acquire; the intervening hidden/inactive no-op correctly. The
  G3 control — `whenFrameChangesTo(FRAME_ORANGE)` → resumed reading ≈ `RETICLE_ORANGE` (<45) over
  the 450-L1 cyan↔orange separation — kills a frozen/black feed that re-subscribes but never wires
  frames through. G1/G3/G4/G5/G6 met, G2 n/a. Non-vacuous in both directions.
- **New CAM-7 unit tests — NON-VACUOUS (both legitimate given their async-zone constraints).**
  `capture_controller_test.dart` 'lifecycle feed release/resume' drives the **real** controller over
  `_RecordingFeedSource` under real async (`pumpEventQueue`): exact counts for release+re-acquire
  (acquire 1→2, release 0→1), idempotent pause (release==1 after two pauses), resume-while-live
  no-op (`_feed != null` guard → acquire stays 1), resume-after-dispose no-op (`_disposed` guard →
  acquire unchanged), and a resumed feed delivering a fresh frame (seed→opening <12, emit→next <12).
  Each bites its guard. The `build_app_test.dart` host test is sound despite the FakeAsync zone not
  flushing the async `onCancel`: it counts acquisitions via `onListen` and asserts acquire stays 1
  while paused/detached and reaches 2 on resume — reachable only if the host actually called
  `pauseFeed` first (`resumeFeed`'s `_feed != null` guard), so it bites both "host never pauses" and
  "host doesn't re-acquire on resume". The precise release count is pinned in the controller unit
  test and the AC-9 acceptance test.
- **Smoke exact-set guard — NON-VACUOUS.** `unpendedACs` now includes AC-9; `expectedPending =
  {AC-1..10} \ unpendedACs = {AC-7, AC-8, AC-10}` compared by set-equality to
  `pendingACs.keys.toSet()` (pending.dart holds exactly AC-7→PERM-2, AC-8→PERM-3, AC-10→PERM-4).
  Both directions bite; the pending-skip example still uses a genuinely-pending AC (AC-7/PERM-2).

**CAM-7 grade count: 7 A / 0 below A** (every un-pended AC test: AC-1..AC-6, AC-9). No downgrades
from the prior grid; no fix owed. Feature grid remains all-A.

## Re-grade — PERM-2 (AC-7 un-pended, 2026-10-21)

PERM-2 wired the camera-permission seam into the assembly: `givenLiveCamera` now forwards the
injected `permission` into `buildApp` at `AppDependencies.cameraPermission` (a **shared** harness
change affecting every live_camera test), and `_CaptureHomeScreenState.didChangeDependencies`
requests access on first live-capture entry when the source is a live camera — granted keeps the
already-subscribed camera controller (only records the grant), denied swaps to
`cameraFallbackSource()` (a `SoftwareCaptureSource`) and overlays the `_CameraAccessAffordance`.
It un-pended **AC-7** (deleted its `pendingACs` row) so `TestAC07_PermissionFallback` now runs in
the default suite. An independent fresh grader (did not write the tests or the code) re-graded
every un-pended AC test (AC-1..AC-7, AC-9) adversarially, as the live code now behaves:

- **AC-1 `TestAC01_LivePreview` — A** (holds). Verified safe under the shared change: the default
  `givenLiveCamera` wires a `RecordingCameraPermission()` (resolves **granted**) over the default
  camera-kind source, so `_applyInitialPermission` takes the granted arm, which **keeps** the
  original controller — `activeSourceKind` stays `camera`, the render path is untouched.
- **AC-2 `TestAC02_FrameConversion` — A** (holds; pure buffer→Frame conversion, no app assembly,
  untouched by the permission wiring).
- **AC-3 `TestAC03_ReadingFollowsFrame` — A** (holds; granted-keeps-controller preserves the
  source subscription, so `_onFrame` sampling is unchanged).
- **AC-4 `TestAC04_ValueOnlyLive` — A** (holds; value-only filter untouched).
- **AC-5 `TestAC05_LockClearsWarning` — A** (holds). Its `canLock:false` control source is still
  kind `camera`, so the now-firing permission request resolves granted and keeps that controller —
  the stuck-lock discrimination is unaffected.
- **AC-6 `TestAC06_Torch` — A** (holds; all three apps use camera-kind sources → granted → kept
  controller; torch/commit path untouched).
- **AC-7 `TestAC07_PermissionFallback` — A (now live; holds the prior as-written A).** Granted
  branch: both Givens checked on the recorder's public surface before the When
  (`granted.requestCount == 0`, `granted.status == undetermined`) — G1. `request()` increments
  `requestCount` synchronously at the call site inside `_applyInitialPermission`, dispatched during
  the first `didChangeDependencies` build, so `requestCount == 1` is pinned by the time the test
  reads it: the granted branch **does** assert the request happened exactly once before concluding
  (rejects never-requesting *and* a double request), then `activeSourceKind == camera` and
  `permissionState == granted` (the grant is surfaced only after the awaited resolution + `setState`
  that the harness's single `pump` drains). Denied branch (fresh app via `pumpWidget(SizedBox())`):
  asserts `requestCount == 1`, `activeSourceKind == software` (the real `cameraFallbackSource()`
  swap, verified — kind `software`), `permissionState == denied`, `find.textContaining('Camera
  access') findsOneWidget` (the affordance's "Camera access needed — enable it in Settings…" copy),
  and `tester.takeException() isNull` — fallback **and** affordance **and** no crash, each at grain
  (G4). **G2/G5 — the airtight discrimination:** both branches inject a source with the *identical*
  default `kind == camera`; only the permission recorder's `resolvesTo` differs, so the
  camera-vs-software divergence can **only** come from the permission decision. This provably kills
  a **dead-camera-kept** impl (would report `camera` on denial → fails `== software`), a
  **never-requested** impl (`requestCount == 1` on both branches), a crash-on-denial impl, and an
  impl that echoes the injected source kind. The two-app `pumpWidget(SizedBox())` reset is sound
  (forces the first `CaptureHomeScreen` to unmount so the denied branch gets a fresh
  `didChangeDependencies` controller + request, not the granted first one — the established
  bs-19 idiom). G3 n/a (the decision resolves inside the open-screen assembly; the two-branch
  contrast is the control). G6: one AC. **Minor (not a downgrade, consistent with the AC-4/AC-5
  precedent):** (1) the denied branch does not re-assert its pre-When `requestCount == 0`, but
  `denied` is a freshly constructed recorder whose field defaults 0, so the 0→1 transition is pinned
  by construction; (2) the granted branch does not assert the affordance is *absent* on grant, so a
  spurious always-show-affordance impl is not rejected — implausible here (the affordance is built
  only when `_resolvedPermission == denied`, which the granted arm never sets while keeping the
  camera), the same symmetric "always-on" observation the grid logged for AC-4, so the grade stands
  at A.
- **AC-9 `TestAC09_Lifecycle` — A** (holds). Verified the granted arm **keeps** the already-
  subscribed controller rather than replacing it (code comment + `_applyInitialPermission` granted
  branch), so `acquireCount` stays 1 on entry — AC-9's `acquireCount == 1` Given still holds. Had
  granted rebuilt the controller it would read 2 and break; the keep-on-grant design is exactly
  what protects AC-9.

**Shared `givenLiveCamera` change — SAFE.** Forwarding the permission into `buildApp` now fires a
request on open for every camera-kind source (all neighbours), but the default recorder resolves
**granted**, and the granted arm only records the grant + a no-op `setState` while **keeping** the
original controller and feed — no teardown, no re-subscription, no lost frames, no sampling change.
The async request carries no timers and resolves on a microtask the harness `pump`/`pumpAndSettle`
drains, so no neighbour is left with pending work. Only AC-7's denied branch (the lone
`resolvesTo: denied`) exercises the fallback path. No neighbour was weakened or broken.

**Smoke exact-set guard — NON-VACUOUS.** `unpendedACs` now includes `AC-7`; `expectedPending =
{AC-1..10} \ unpendedACs = {AC-8, AC-10}` compared by set-equality to `pendingACs.keys.toSet()`
(pending.dart holds exactly AC-8→PERM-3, AC-10→PERM-4). Both directions bite; each un-pended AC's
skip-reason is asserted null; every owner is checked against `behaviorPhases`; the pending-skip
example uses a genuinely-pending AC (AC-8/PERM-3).

**PERM-2 grade count: 8 A / 0 below A** (every un-pended AC test: AC-1..AC-7, AC-9). No downgrades
from the prior grid; no fix owed. Feature grid remains all-A.

## Grade — PERM-3 re-grade (AC-1..AC-9)

Independent fresh grader (did **not** write these tests), **2026-10-21**, after
PERM-3 un-pended **AC-8** (no-camera fallback) and added `bool get available` to
the `CaptureSource` interface. Re-grades **every** un-pended AC test (AC-1..AC-9;
AC-10 still pending → PERM-4).

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_LivePreview` | A | G1,G4,G5,G6 (G2/G3 n/a) | Default fixture `available=true`+`kind=camera` → PERM-3 branch skipped, granted arm keeps the camera controller. `showsPlaceholder isFalse` + `frame isNotNull` kill "keeps placeholder" / "ignores frames". |
| AC-2 | `TestAC02_FrameConversion` | A | G1,G4,G5,G6 | Pure `frameFromCameraImage` below the source/host — PERM-3 can't touch it. BGRA tol 3 + BGR↔RGB `>100`; YUV tol 12 rejects limited-range mis-decode; c1/c2 control kills a constant pixel. |
| AC-3 | `TestAC03_ReadingFollowsFrame` | A (live) | G1,G2,G3,G4,G5,G6 | c1→c2 over 450-L1 vs 45 tol; granted-keeps-controller arm preserves the subscription (branch not reached). Kills stale/fixed/placeholder sampler. |
| AC-4 | `TestAC04_ValueOnlyLive` | A | G1,G3,G4,G5,G6 (G2 n/a) | `ColorFiltered` over `liveViewKey` findsOne + over `accuracyKey` findsNothing; value-only path untouched. |
| AC-5 | `TestAC05_LockClearsWarning` | A (live) | G1,G2,G3,G4,G5,G6 | `canLock:false` control proves clear comes from `source.locks.allLocked`; both sources `available=true` → branch skipped, lock path unchanged. |
| AC-6 | `TestAC06_Torch` | A (live) | G1,G2,G3,G4,G5,G6 | `torchOnCalls==1` kills a UI-only toggle; torch-off-commit control kills a torch-blind stamp; all apps `available=true`. |
| AC-7 | `TestAC07_PermissionFallback` | A (live) | G1,G2,G4,G5,G6 (G3 n/a) | Both branches inject identical `kind=camera, available=true` source, diverge only on the permission recorder → camera-vs-software provably permission-driven; `available=true` means PERM-3's branch never fires, so AC-7 exercises exactly the untouched PERM-2 code. |
| AC-8 | `TestAC08_NoCameraFallback` | A (live, PERM-3) | G1,G4,G5,G6 (G2 built-in, G3 n/a) | **New.** Given "no usable camera" asserted on the public surface (`source.available isFalse`) before the When; When drives real `buildApp`/`didChangeDependencies` (`kind==camera && !available` → `cameraFallbackSource()`). `activeSourceKind==software` overturns the injected `kind=camera` wrong-impl baseline (dead-camera echo), `currentSample isNotNull` pins "can still read", `takeException isNull` pins no-crash. Clean red at baseline. Corroborated by the build_app unit test (`requestCount==0`, `permissionState==undetermined`, `acquireCount==0`, no affordance → branch runs before any prompt; availability≠permission). Minor (not a downgrade, matches prior AC-7/AC-5 notes): "import/use-rest-of-app" clauses not asserted (fallback is bs-02's shipped source; no distinct wrong-impl escapes); `kind==camera` pinned by fixture default rather than re-asserted. |
| AC-9 | `TestAC09_Lifecycle` | A (live) | G1,G3,G4,G5,G6 (G2 n/a) | `acquireCount==1`/`releaseCount==0` Givens; `release>=1` on background, `acquire>=2` on resume + frozen-feed control; `available=true` → branch skipped, keep-on-grant preserves `acquireCount==1`. |

### Summary — PERM-3

- **Grade counts: 9×A, 0 below A.** No downgrades from the prior grid; every prior-A row holds; no fix owed.
- **AC-8 grades A:** Given on the public surface, When through the real assembled host, three Thens reject the three catalogue wrong-impls (dead-camera kind echo, black/unreadable view, crash); the discrimination is built into the fixture (injected `kind=camera` is the wrong-impl baseline the `==software` assertion overturns), so no separate control is needed.
- **The `available` interface change did NOT weaken any neighbour.** It resolves to `true` on every shipped and fake source; the host branch is gated on `kind==camera && !available`, never taken for AC-1..AC-7/AC-9 (all `available=true`), so the PERM-2 permission flow, CAM lifecycle, torch, lock and render paths are untouched. Only AC-8 sets `available=false`.

## Grade — PERM-4 re-grade (AC-1..AC-10 — all delivered)

Independent fresh grader (did **not** write these tests), **2026-10-21**, after
PERM-4 un-pended the **last** AC, **AC-10** (platform declarations), and rewrote
the two smoke guards to the terminal all-delivered state. PERM-4 touched exactly
two files (`pending.dart`, `smoke_test.dart`) — **no lib/ and no AC test body**,
so AC-1..AC-9 bodies are byte-identical to their prior-A states and AC-10's body
(written in ITEST-3) is unchanged, only un-pended. Grader verified AC-10's three
assertions against the real on-disk files (`AndroidManifest.xml:5-6`,
`Info.plist:7-8`).

| AC | Test | Grade | Rules checked | Justification / gap |
|---|---|---|---|---|
| AC-1 | `TestAC01_LivePreview` | A | G1,G4,G5,G6 (G2/G3 n/a) | Given on read endpoint before When; `showsPlaceholder isFalse` + `frame isNotNull` kill both Rejects. Unchanged; holds. |
| AC-2 | `TestAC02_FrameConversion` | A | G1,G4,G5,G6 | Pure converter below host; BGRA tol 3 + BGR↔RGB control; YUV tol 12 rejects limited-range mis-decode; c1/c2 control. Holds. |
| AC-3 | `TestAC03_ReadingFollowsFrame` | A (live) | G1..G6 | c1→c2 real sampling, `<45` follow / `>135` stale; settle via pump. Holds. |
| AC-4 | `TestAC04_ValueOnlyLive` | A | G1,G3,G4,G5,G6 (G2 n/a) | `ColorFiltered` over `liveViewKey` findsOne + over `accuracyKey` findsNothing. Holds. |
| AC-5 | `TestAC05_LockClearsWarning` | A (live) | G1..G6 | `canLock:false` control proves clear comes from `source.locks.allLocked`. Holds. |
| AC-6 | `TestAC06_Torch` | A (live) | G1..G6 | `torchOnCalls==1` kills UI-only toggle; torch-off-commit control kills torch-blind stamp. Holds. |
| AC-7 | `TestAC07_PermissionFallback` | A (live) | G1,G2,G4,G5,G6 (G3 n/a) | Both branches identical `kind=camera, available=true`, diverge only on recorder → camera-vs-software provably permission-driven. Holds. |
| AC-8 | `TestAC08_NoCameraFallback` | A (live) | G1,G4,G5,G6 (G2 built-in, G3 n/a) | Given `available isFalse` on public surface; `activeSourceKind==software` overturns injected `kind=camera`; `currentSample isNotNull`, no crash. Holds. |
| AC-9 | `TestAC09_Lifecycle` | A (live) | G1,G3,G4,G5,G6 (G2 n/a) | `acquireCount==1`/`releaseCount==0` Givens; `release>=1` bg, `acquire>=2` resume + frozen-feed control. Holds. |
| **AC-10** | `TestAC10_PlatformDeclarations` | **A (live — now runs by default)** | G1,G4,G5,G6 (G2/G3 n/a) | Given: both files' `existsSync()` asserted before inspection; reads the **real** files off disk, nothing faked. Three distinct Thens each failing a distinct wrong impl (G5): (1) Android `CAMERA` permission; (2) a **separate** `<uses-feature android.hardware.camera>` regex (rejects one-but-not-the-other); (3) the **augmentation** — captures the `NSCameraUsageDescription` *value* and asserts `isNotNull` **and** `isNotEmpty` (a bare key or empty string fails where a `contains` check would pass). Verified against the shipped declarations. Minor (standard source-scan limit, not a downgrade): the Android `contains` could match a literal inside an XML comment; the real entries are genuine elements and the structured iOS check is immune. |

### Summary — PERM-4

- **Grade counts: 10 A / 0 below A** — the complete delivered suite. No downgrade from any prior grid; every prior-A row holds by inspection (no lib / no AC body changed); no fix owed.
- **AC-10 grades A** as a source-scan AC: Given (files exist) on the public surface, When (inspect the real on-disk manifests), three Thens rejecting three distinct wrong impls, the non-empty-usage augmentation in place.
- **Both rewritten smoke guards are NON-VACUOUS.** Guard 1: exact set-equality `pendingACs.keys.toSet() == {}` + `isEmpty` pins the map's contents (a re-pended AC fails it), each delivered AC's null skip-reason asserted. Guard 2: a **fixed** `for n=1..10` loop (not over the empty map) asserts every AC runs in **both** modes — a silently re-pended AC or an inverted gate fails. No drift to a bare count; no fixed sleeps; comments match code.
