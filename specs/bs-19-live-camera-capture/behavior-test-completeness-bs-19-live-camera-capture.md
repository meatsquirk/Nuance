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
