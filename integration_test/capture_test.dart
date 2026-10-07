// bs-02 Sample-capture acceptance suite.
//
// ITEST-1 lands the never-pending scaffold here — a smoke test proving the
// shells wire end to end, and guard tests over the pending gate, the fixtures
// and the fakes so the scaffold cannot pass vacuously. ITEST-2 / ITEST-3 append
// one *pending* `acTestWidgets` per AC (`TestAC01_…`) to this file.
//
// Default: `flutter test integration_test/capture_test.dart` (pending ACs
// skipped). Run-pending: `BS02_RUN_PENDING=1 flutter test
// integration_test/capture_test.dart` (the red-baseline / un-pend run).

import 'dart:math' as math;

import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/readout/name_header.dart';

import 'capture_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to a Capture screen showing every region',
    (tester) async {
      final harness = await givenCaptureOf(tester, SCENE_OLIVE);

      // Booted to the Capture route (a capture source was injected), not the
      // Readout. (The app-bar title "Capture" is scoped to the AppBar — the E20
      // button also reads "Capture".)
      expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget);
      expect(find.byKey(CaptureReadEndpoint.endpointKey), findsOneWidget);

      // The live view, the eyedropper + reticle, and every E15–E21 control
      // anchor the AC finders rely on are rendered.
      expect(find.byKey(CaptureLiveView.liveViewKey), findsOneWidget);
      expect(find.byKey(CaptureEyedropper.eyedropperKey), findsOneWidget);
      expect(find.byKey(CaptureEyedropper.reticleKey), findsOneWidget);
      for (final key in const [
        CaptureControls.dismissWarningKey, // E15
        CaptureControls.lockKey, // E16
        CaptureControls.calibrateKey, // E17
        CaptureControls.radiusKey, // E18
        CaptureControls.importKey, // E19
        CaptureControls.captureKey, // E20
        CaptureControls.valueOnlyKey, // E21
      ]) {
        expect(find.byKey(key), findsOneWidget);
      }

      // The default readings render as text (bs-01 label contract), the warning
      // is hidden, and opening the screen fires no haptic.
      expect(find.byKey(CaptureLiveView.stabilityKey), findsOneWidget);
      expect(find.text('SETTLING 0/12'), findsOneWidget);
      expect(find.text('Approximate'), findsOneWidget);
      expect(find.byKey(CaptureLiveView.warningKey), findsNothing);

      // The observable state is the default capture (auto, 5 px, approximate),
      // readable through the endpoint the AC Thens use. The live feed is sampled
      // passively on open (SOURCE-2), so a current sample is present; lock and
      // commit remain deferred, so no lock and no haptic yet.
      expect(harness.state.lockState, LockState.auto);
      expect(harness.state.radiusPx, 5);
      expect(harness.state.currentSample, isNotNull);
      expect(harness.haptics.confirmations, 0);
    },
  );

  group('pending gate', () {
    // The owner of each AC is the phase whose acceptance gate un-pends it,
    // matching ITEST's red-baseline *Owning phase* column. Pinned exactly so a
    // typo'd id, a missing AC, a stray AC or a re-owned AC fails this test
    // rather than passing vacuously. AC-1 is absent: it was un-pended at ITEST-2
    // as green at baseline (its always-running test is below). AC-2 is absent:
    // SOURCE-2 un-pended it. AC-9 is absent: SOURCE-3 un-pended it. AC-4 and AC-5
    // are absent: CAPTURE-3 un-pended them. AC-6 and AC-7 are absent: CAPTURE-4
    // un-pended them. So only the four still-pending ACs remain here.
    const expectedOwners = {
      'AC-3': 'SCREEN-2',
      'AC-8': 'CAPTURE-5',
      'AC-10': 'SCREEN-3',
      'AC-11': 'CAPTURE-6',
    };

    test('the still-pending ACs are each owned by a real behaviour phase', () {
      expect(pendingACs, expectedOwners);
      expect(pendingACs.length, 4);
      for (final owner in pendingACs.values) {
        expect(behaviorPhases, contains(owner),
            reason: '"$owner" is not a known bs-02 behaviour phase');
      }
    });

    test('a pending AC is skipped by default and runs only in run-pending mode',
        () {
      // A mapped (pending) AC: skipped in the default run, run in run-pending.
      expect(pendingSkipReason('AC-3', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-3', forceRunPending: true), isNull);
      // An un-mapped AC always runs, in either mode — the end state as each
      // behaviour phase deletes its row, and the state AC-1 (un-pended at
      // ITEST-2), AC-2 (un-pended by SOURCE-2) and AC-9 (un-pended by SOURCE-3)
      // are already in.
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-2', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-9', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
    });
  });

  group('fixtures and fakes are sound (no vacuous controls)', () {
    test('SCENE_CENTRE_VARIED has three distinct colours: centre, 5 px ring, '
        'outer — so a point / wrong-radius read is actually caught', () {
      final frame = SCENE_CENTRE_VARIED.spec.frames!.single;
      final cx = frame.width ~/ 2;
      final cy = frame.height ~/ 2;
      final centre = frame.pixelAt(cx, cy); // the point-read distractor
      final ring5 = frame.pixelAt(cx + 3, cy); // inside the 5 px disc, off-centre
      final outer = frame.pixelAt(cx + 15, cy); // in the 21 px outer band
      expect(centre, isNot(ring5),
          reason: 'centre pixel must differ from the 5 px average');
      expect(ring5, isNot(outer),
          reason: '5 px and 21 px averages must differ');
      expect(centre, isNot(outer));
    });

    test('PHOTO_SWATCH point P differs from the image centre (P ≠ centre)', () {
      final image = PHOTO_SWATCH.image;
      final atP = image.pixelAt(PHOTO_SWATCH.pointX, PHOTO_SWATCH.pointY);
      final atCentre = image.pixelAt(image.width ~/ 2, image.height ~/ 2);
      expect(atP, isNot(atCentre),
          reason: 'sampling P must be distinguishable from the image centre');
    });

    test('FakeCaptureSource exposes ground truth and counts each frame read',
        () async {
      final source = FakeCaptureSource(SCENE_CENTRE_VARIED.spec);
      expect(source.framesRead, 0);
      expect(source.groundTruth, SCENE_CENTRE_VARIED.groundTruth);

      final frames = await source.frames.toList();
      expect(frames, isNotEmpty);
      expect(source.framesRead, frames.length,
          reason: 'every pulled frame must be counted');
    });

    test('FakeHaptics counts confirmation pulses', () async {
      final haptics = FakeHaptics();
      expect(haptics.confirmations, 0);
      await haptics.confirm();
      expect(haptics.confirmations, 1);
    });

    test('SCENE_CARD and SCENE_DIM read clearly off their ground truth, so the '
        'accuracy / normalisation Thens (AC-6, AC-8) are not vacuous', () {
      // Both accuracy-tier scenes share the olive ground truth; their raw frames
      // sit a verified ΔE00 ≈ 4.6 / 5.1 off it (CIEDE2000). Guard the sRGB
      // separation so the fixtures can never silently regress to a ground-truth
      // reading — which would let a calibration/accuracy no-op pass the ΔE Thens.
      final groundTruthPx = _science.toSRGB(SCENE_OLIVE.groundTruth);
      for (final scene in [SCENE_CARD, SCENE_DIM]) {
        final frame = scene.spec.frames!.single;
        final rawPx = frame.pixelAt(frame.width ~/ 2, frame.height ~/ 2);
        expect(_distToPixel(groundTruthPx, rawPx), greaterThan(20),
            reason: '${scene.id}: the raw reading must sit clearly off ground '
                'truth so a no-op accuracy label cannot pass the ΔE Thens');
      }
    });
  });

  // ===========================================================================
  // ITEST-2 — sampling + screen ACs (AC-1, AC-2, AC-3, AC-9, AC-10)
  //
  // One pending test per AC, driving the real assembled app through the ITEST-1
  // harness. In the default run each body is skipped; under
  // `--dart-define=BS02_RUN_PENDING=true` it executes and must fail on a Then
  // (or an observable precondition naming its owning phase), never panic. The
  // sampled colour is observed through the read endpoint (`currentSample`) and
  // compared — rendered back to sRGB via the real `ColorScienceImpl` — against
  // the fixtures' own frame pixels, so the assertions reject a point read, a
  // wrong-radius average, the wrong source or a missing grayscale render.
  // ===========================================================================

  // AC-1 — The live camera view shows a centre-point eyedropper marking where
  // the colour will be sampled. Owned by SCREEN-2.
  acTestWidgets('AC-1', 'TestAC01_Eyedropper', (tester) async {
    // Given: the painter has opened the Capture screen on SCENE_OLIVE — the
    // Capture screen is shown with its live-view feed region present.
    await givenCaptureOf(tester, SCENE_OLIVE);
    expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget,
        reason: 'AC-1 Given: the Capture screen is shown');
    expect(find.byKey(CaptureLiveView.liveViewKey), findsOneWidget,
        reason: 'AC-1 Given: the live-view feed region is present');

    // When: the live camera view is shown (it is, on open).
    // Then: a centre-point eyedropper marker is present AND positioned at the
    // live-view centre — not merely present somewhere (rejects an off-centre or
    // absent marker). The reticle marks the sample point, so its centre must
    // coincide with the feed's centre.
    expect(find.byKey(CaptureEyedropper.eyedropperKey), findsOneWidget,
        reason: 'AC-1: a centre-point eyedropper marker is shown');
    expect(find.byKey(CaptureEyedropper.reticleKey), findsOneWidget,
        reason: 'AC-1: the eyedropper carries a reticle marking the sample point');
    final reticleCentre =
        tester.getCenter(find.byKey(CaptureEyedropper.reticleKey));
    final feedCentre =
        tester.getCenter(find.byKey(CaptureLiveView.liveViewKey));
    expect(reticleCentre.dx, moreOrLessEquals(feedCentre.dx, epsilon: 0.5),
        reason: 'AC-1: the eyedropper is horizontally centred on the feed, '
            'marking where the colour will be sampled (SCREEN-2)');
    expect(reticleCentre.dy, moreOrLessEquals(feedCentre.dy, epsilon: 0.5),
        reason: 'AC-1: the eyedropper is vertically centred on the feed, '
            'marking where the colour will be sampled (SCREEN-2)');
  });

  // AC-2 — Sampling under the centre point returns the 5 px-radius area average,
  // not the single centre pixel. Owned by SOURCE-2. SCENE_CENTRE_VARIED is the
  // control: its centre pixel, 5 px average and 21 px average are three distinct
  // colours, so a point read or a wrong-radius average is caught.
  acTestWidgets('AC-2', 'TestAC02_AreaAverage5px', (tester) async {
    // Given: the live camera view is shown with the sampling radius at the 5 px
    // default — asserted through the read endpoint.
    final harness = await givenCaptureOf(tester, SCENE_CENTRE_VARIED);
    expect(harness.state.radiusPx, 5,
        reason: 'AC-2 Given: the default sampling radius is 5 px (D-7)');

    // The three distinct region colours of the control scene, read from the
    // fixture's own frame (the same coordinates the fixture-soundness guard
    // uses): the centre distractor, a pixel inside the 5 px disc, and the outer
    // band that a wider average would pull toward.
    final frame = SCENE_CENTRE_VARIED.spec.frames!.single;
    final cx = frame.width ~/ 2;
    final cy = frame.height ~/ 2;
    final centrePx = frame.pixelAt(cx, cy); // point-read distractor
    final discPx = frame.pixelAt(cx + 3, cy); // the correct 5 px-average colour
    final outerPx = frame.pixelAt(cx + 15, cy); // the 21 px outer band

    // When: the painter samples the colour under the centre point (the live
    // feed samples under the reticle).
    await tester.pump();

    // Then: the sampled colour is the 5 px-radius average ≈ the inner-disc
    // colour, clearly nearer the disc than the centre distractor (rejects a
    // single-pixel read) and than the outer band (rejects a wrong, wider
    // radius).
    final sample = harness.state.currentSample;
    expect(sample, isNotNull,
        reason: 'AC-2: SOURCE-2 wires the centre sampler — no sample before it');
    final sampled = _science.toSRGB(sample!.coordinates);
    final toDisc = _distToPixel(sampled, discPx);
    final toCentre = _distToPixel(sampled, centrePx);
    final toOuter = _distToPixel(sampled, outerPx);
    expect(toDisc, lessThan(_sampleToleranceL1),
        reason: 'AC-2: the sample is the 5 px-radius average ≈ the inner disc');
    expect(toDisc, lessThan(toCentre),
        reason: 'AC-2: rejects a single-pixel (centre) read — the 5 px average '
            'differs from the centre distractor');
    expect(toDisc, lessThan(toOuter),
        reason: 'AC-2: rejects averaging over the wrong (wider) radius');
  });

  // AC-3 — Selecting a radius grows the reticle to the matching size (8/20/44 px
  // for 1/5/21 px) and the sampled colour is averaged over that radius. Owned by
  // SCREEN-2 (reticle sizing) over SOURCE-2 (radius-driven averaging). On
  // SCENE_CENTRE_VARIED each radius yields a distinct value.
  acTestWidgets('AC-3', 'TestAC03_RadiusSelector', (tester) async {
    // Given: the live camera view is shown.
    final harness = await givenCaptureOf(tester, SCENE_CENTRE_VARIED);
    expect(find.byKey(CaptureLiveView.liveViewKey), findsOneWidget,
        reason: 'AC-3 Given: the live camera view is shown');

    final frame = SCENE_CENTRE_VARIED.spec.frames!.single;
    final cx = frame.width ~/ 2;
    final cy = frame.height ~/ 2;
    final centrePx = frame.pixelAt(cx, cy);
    final outerPx = frame.pixelAt(cx + 15, cy);

    // The spec's radius → reticle mapping (ordered so the smallest radius, whose
    // reticle differs most from the 5 px default, is checked first).
    const radiusToReticlePx = <int, double>{1: 8, 5: 20, 21: 44};
    final sampledPerRadius = <int, SRGBColor>{};

    for (final entry in radiusToReticlePx.entries) {
      final radiusPx = entry.key;
      final reticlePx = entry.value;

      // When: the painter selects the <radius> sampling radius (E18).
      await harness.whenSelectRadius(radiusPx);

      // Then: the reticle grows to the matching size (rejects an unchanged
      // reticle — SCREEN-2).
      final size = tester.getSize(find.byKey(CaptureEyedropper.reticleKey));
      expect(size.width, moreOrLessEquals(reticlePx, epsilon: 0.5),
          reason: 'AC-3: radius $radiusPx px → reticle $reticlePx px (SCREEN-2)');
      expect(size.height, moreOrLessEquals(reticlePx, epsilon: 0.5),
          reason: 'AC-3: the reticle is square at $reticlePx px for radius '
              '$radiusPx px (SCREEN-2)');

      // And: the sampled colour is the average over that radius.
      await tester.pump();
      final sample = harness.state.currentSample;
      expect(sample, isNotNull,
          reason: 'AC-3: SOURCE-2 samples the area average at the selected '
              'radius — no sample before it');
      sampledPerRadius[radiusPx] = _science.toSRGB(sample!.coordinates);
    }

    // Then (averaging follows the selection — SOURCE-2): the three radii give
    // three distinct colours, the 1 px average is pulled toward the centre
    // distractor more than the 5 px one is, and the 21 px average is pulled
    // toward the outer band more than the 5 px one is. This rejects an average
    // that ignores the selected radius (all three would be equal).
    final s1 = sampledPerRadius[1]!;
    final s5 = sampledPerRadius[5]!;
    final s21 = sampledPerRadius[21]!;
    expect(_distToColor(s1, s5), greaterThan(0),
        reason: 'AC-3: the 1 px and 5 px averages differ');
    expect(_distToColor(s5, s21), greaterThan(0),
        reason: 'AC-3: the 5 px and 21 px averages differ');
    expect(_distToPixel(s1, centrePx), lessThan(_distToPixel(s5, centrePx)),
        reason: 'AC-3: the 1 px average sits nearer the centre distractor than '
            'the 5 px average — the radius narrows the average');
    expect(_distToPixel(s21, outerPx), lessThan(_distToPixel(s5, outerPx)),
        reason: 'AC-3: the 21 px average sits nearer the outer band than the '
            '5 px average — the radius widens the average');
  });

  // AC-9 — A colour is sampled from an imported gallery photo, read at the
  // photo's point P (not the live camera, not the image centre). Owned by
  // SOURCE-3. PHOTO_SWATCH's P is off the image centre, so a wrong-point read is
  // caught; the host scene is the olive live view, so a live-camera read is
  // caught.
  acTestWidgets('AC-9', 'TestAC09_SampleFromPhoto', (tester) async {
    // Given: the painter is on the Capture screen (olive live view) and has a
    // photograph with a known colour at P ≠ the image centre.
    final harness = await givenCaptureOf(tester, SCENE_OLIVE);
    final image = PHOTO_SWATCH.image;
    final atP = image.pixelAt(PHOTO_SWATCH.pointX, PHOTO_SWATCH.pointY);
    final atCentre = image.pixelAt(image.width ~/ 2, image.height ~/ 2);
    expect(atP, isNot(atCentre),
        reason: 'AC-9 Given: P is off the image centre (wrong-point control)');
    final liveCamera = _science.toSRGB(SCENE_OLIVE.groundTruth);

    // When: the painter imports the photograph and samples point P (E19).
    await harness.whenImportPhoto(PHOTO_SWATCH);
    await tester.pump();

    // Then: the sampled colour is read from point P of the photograph — nearer
    // P's colour than the image centre (rejects the wrong point) and than the
    // live camera colour (rejects sampling the camera instead of the photo).
    final sample = harness.state.currentSample;
    expect(sample, isNotNull,
        reason: 'AC-9: SOURCE-3 reads the sampled point from the imported '
            'photo — no sample before it');
    final sampled = _science.toSRGB(sample!.coordinates);
    final toP = _distToPixel(sampled, atP);
    expect(toP, lessThan(_sampleToleranceL1),
        reason: 'AC-9: the sample is the colour at point P of the photograph');
    expect(toP, lessThan(_distToPixel(sampled, atCentre)),
        reason: 'AC-9: rejects sampling the image centre — P ≠ centre');
    expect(toP, lessThan(_distToColor(sampled, liveCamera)),
        reason: 'AC-9: rejects sampling the live camera instead of the photo');
  });

  // AC-10 — The live feed can be previewed in value-only grayscale, and the
  // control reads "✓ Value". Owned by SCREEN-3.
  acTestWidgets('AC-10', 'TestAC10_ValueOnly', (tester) async {
    // Given: the live camera view is shown in colour — the value-only preview
    // is off and the control reads "Value" (not "✓ Value").
    final harness = await givenCaptureOf(tester, SCENE_OLIVE);
    expect(harness.state.valueOnly, isFalse,
        reason: 'AC-10 Given: the feed starts in colour, not value-only');
    expect(
        find.descendant(
          of: find.byKey(CaptureControls.valueOnlyKey),
          matching: find.text('Value'),
        ),
        findsOneWidget,
        reason: 'AC-10 Given: the value-only control reads "Value" while off');
    expect(
        find.ancestor(
          of: find.byKey(CaptureLiveView.liveViewKey),
          matching: find.byType(ColorFiltered),
        ),
        findsNothing,
        reason: 'AC-10 Given: no grayscale filter over the feed while in colour');

    // When: the painter turns on the value-only view (E21). The toggle
    // behaviour lands in SCREEN-3; until then E21 throws UnimplementedError on
    // tap, so consume that one deferred, expected throw — the baseline red is
    // then the Then below (the feed stays in colour), not the tap. Post-SCREEN-3
    // no exception is thrown and `takeException` is a harmless no-op; a surprise
    // exception of any other kind still fails the test here.
    await harness.whenToggleValueOnly();
    final deferred = tester.takeException();
    expect(deferred, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-10: only the pending-stage UnimplementedError may be '
            'deferred by the E21 tap');

    // Then: the value-only preview is on, the feed is rendered grayscale (a
    // colour filter over the feed itself — rejects leaving it in colour or
    // greyscaling an unrelated widget), and the control reads "✓ Value"
    // (rejects an unchanged label).
    expect(harness.state.valueOnly, isTrue,
        reason: 'AC-10: turning on value-only sets the preview on (SCREEN-3)');
    expect(
        find.ancestor(
          of: find.byKey(CaptureLiveView.liveViewKey),
          matching: find.byType(ColorFiltered),
        ),
        findsWidgets,
        reason: 'AC-10: the camera feed is rendered grayscale (SCREEN-3)');
    expect(
        find.descendant(
          of: find.byKey(CaptureControls.valueOnlyKey),
          matching: find.text('✓ Value'),
        ),
        findsOneWidget,
        reason: 'AC-10: the value-only control reads "✓ Value" (SCREEN-3)');
  });

  // ===========================================================================
  // ITEST-3 — lifecycle + accuracy + commit ACs (AC-4, AC-5, AC-6, AC-7, AC-8,
  // AC-11)
  //
  // The lock/settle lifecycle, the low-light and reference-card accuracy tiers,
  // and the multi-frame commit → Readout handoff. Same ITEST-1 harness and read
  // endpoint as ITEST-2; the accuracy Thens measure the committed colour against
  // the fake source's known ground truth in real CIEDE2000 ΔE00 (`_deltaE00`),
  // so "within ΔE00 N" is an actual numeric check, not label text (D-4). Each
  // control whose behaviour is still deferred throws `UnimplementedError` on tap,
  // so (as AC-10 does) each test consumes that one expected throw via
  // `tester.takeException()` — the baseline red then lands on a Then or on a
  // Given precondition naming the owning phase, never a panic. Settling is driven
  // by frames (CAPTURE-3), so AC-4 / AC-5 pump the feed to reach "SETTLING 6/12".
  // ===========================================================================

  // AC-4 — Locking AE/AWB/AF settles the reading: the indicator reads
  // "AE · AWB · AF LOCKED" and the stability reading jumps to "STABLE 12/12".
  // Owned by CAPTURE-3 (which also drives the pre-lock settling counter).
  acTestWidgets('AC-4', 'TestAC04_LockSettles', (tester) async {
    // Given: the Capture screen is open on SCENE_OLIVE in auto exposure, and the
    // live view reads "SETTLING 6/12" — a partially settled, not-yet-stable
    // reading. The counter is frame-driven (CAPTURE-3), so advance the feed until
    // it reads 6/12; at baseline it never leaves "SETTLING 0/12", so this Given
    // precondition reds cleanly naming CAPTURE-3 (no lock is tapped yet, so no
    // deferred throw here).
    final harness = await givenCaptureOf(tester, SCENE_OLIVE);
    expect(harness.state.lockState, LockState.auto,
        reason: 'AC-4 Given: the reading starts in auto exposure');
    await _pumpUntilText(tester, 'SETTLING 6/12');
    expect(find.text('SETTLING 6/12'), findsOneWidget,
        reason: 'AC-4 Given: the live view reads "SETTLING 6/12" before the '
            'lock — CAPTURE-3 drives the frame-settling counter');

    // When: the painter locks exposure, white balance and focus together (E16).
    await harness.whenLock();
    final deferred = tester.takeException();
    expect(deferred, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-4: only the pending-stage UnimplementedError may be '
            'deferred by the E16 tap');

    // Then: the indicator reads "AE · AWB · AF LOCKED" (exact string — rejects an
    // unchanged indicator and a partial AE/AWB/AF lock), the stability reading is
    // "STABLE 12/12" (rejects a reading that never settles), and the observable
    // lock state is fully locked.
    expect(find.text('AE · AWB · AF LOCKED'), findsOneWidget,
        reason: 'AC-4: locking shows the "AE · AWB · AF LOCKED" indicator '
            '(CAPTURE-3)');
    expect(find.text('STABLE 12/12'), findsOneWidget,
        reason: 'AC-4: the stability indicator reaches STABLE 12/12 on lock');
    expect(harness.state.lockState, LockState.locked,
        reason: 'AC-4: the capture is fully locked, not a partial lock');
    expect(harness.state.stabilityText, 'STABLE 12/12',
        reason: 'AC-4: the observable stability reading is STABLE 12/12');
  });

  // AC-5 — Before locking, the stability indicator warns the reading is still
  // settling ("SETTLING 6/12") and the lock control invites locking. Owned by
  // CAPTURE-3.
  acTestWidgets('AC-5', 'TestAC05_SettlingWarns', (tester) async {
    // Given: the Capture screen is open on SCENE_OLIVE in auto exposure.
    final harness = await givenCaptureOf(tester, SCENE_OLIVE);
    expect(harness.state.lockState, LockState.auto,
        reason: 'AC-5 Given: the reading is in auto exposure');

    // When: frames arrive and the painter does not lock — the reading is left to
    // settle (the counter advances one step per frame; CAPTURE-3). No lock tap,
    // so no deferred throw.
    await _pumpUntilText(tester, 'SETTLING 6/12');

    // Then: the indicator reads "SETTLING 6/12" (the counter advanced from 0 —
    // the reading is live, not frozen), it is NOT stable while unlocked (rejects
    // showing STABLE before a lock — the settle point is that we are still in
    // auto), and the lock control is present and enabled, inviting the painter
    // to lock.
    expect(find.text('SETTLING 6/12'), findsOneWidget,
        reason: 'AC-5: the indicator reads "SETTLING 6/12" while unlocked '
            '(CAPTURE-3 drives the settling counter)');
    expect(harness.state.lockState, LockState.auto,
        reason: 'AC-5 settle point: still unlocked when the reading is read');
    expect(harness.state.isStable, isFalse,
        reason: 'AC-5: the reading is not STABLE while it is still settling');
    expect(find.text('STABLE 12/12'), findsNothing,
        reason: 'AC-5: no STABLE reading is shown before locking');
    final lockButton =
        tester.widget<TextButton>(find.byKey(CaptureControls.lockKey));
    expect(lockButton.enabled, isTrue,
        reason: 'AC-5: the lock control invites locking (present + enabled)');
  });

  // AC-6 — A low-light reading is marked approximate rather than refused: a
  // low-light warning shows, a sample IS committed (never refused), and it is
  // approximate within ΔE00 8 of ground truth. Owned by CAPTURE-4. Graded
  // *B pending CAPTURE-5*: with only one accuracy tier until the reference-card
  // path lands, this test cannot yet prove low light *specifically* downgrades
  // vs a single always-on tier — CAPTURE-5 adds the calibrated-vs-approximate
  // control (see the Test augmentations table).
  acTestWidgets('AC-6', 'TestAC06_LowLightApproximate', (tester) async {
    // Given: capturing SCENE_DIM without a reference card — the source reports
    // low light and no card (asserted through the read endpoint's source).
    final harness = await givenCaptureOf(tester, SCENE_DIM);
    expect(harness.source.lighting, Lighting.low,
        reason: 'AC-6 Given: the scene is in low light');
    expect(harness.source.referenceCardPresent, isFalse,
        reason: 'AC-6 Given: no reference card is present');

    // When: the painter commits the reading (E20).
    await harness.whenCommit();
    final deferred = tester.takeException();
    expect(deferred, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-6: only the pending-stage UnimplementedError may be '
            'deferred by the E20 tap');

    // Then: a low-light warning is shown; a sample IS committed (rejects
    // refusing the capture in dim light); its stated accuracy is approximate
    // (rejects leaving it calibrated with no card); and its colour is within
    // ΔE00 8 of ground truth — the approximate tier's promise (D-4).
    expect(harness.state.lowLightWarning, isTrue,
        reason: 'AC-6: a low-light warning is raised on commit (CAPTURE-4)');
    expect(find.byKey(CaptureLiveView.warningKey), findsOneWidget,
        reason: 'AC-6: the low-light warning is shown on the live view');
    final committed = harness.state.lastCommittedSample;
    expect(committed, isNotNull,
        reason: 'AC-6: the reading is committed, not refused, in low light');
    expect(committed!.accuracy, CaptureAccuracy.approximate,
        reason: 'AC-6: the committed sample is marked approximate');
    expect(_deltaE00(committed.coordinates, harness.source.groundTruth),
        lessThanOrEqualTo(CaptureAccuracy.approximate.maxDeltaE),
        reason: 'AC-6: the committed colour is within ΔE00 8 of ground truth');
  });

  // AC-7 — Dismissing the low-light warning clears it and the reading stays
  // approximate (the dismiss does not change the accuracy). Owned by CAPTURE-4.
  acTestWidgets('AC-7', 'TestAC07_DismissWarning', (tester) async {
    // Given: a low-light warning is showing on the Capture screen — built
    // through the real commit flow on SCENE_DIM (CAPTURE-4 raises it on a
    // low-light commit). At baseline the commit is deferred and no warning is
    // raised, so this Given precondition reds cleanly naming CAPTURE-4.
    final harness = await givenCaptureOf(tester, SCENE_DIM);
    await harness.whenCommit();
    final committedThrow = tester.takeException();
    expect(committedThrow, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-7: only the pending-stage UnimplementedError may be '
            'deferred by the E20 tap');
    expect(find.byKey(CaptureLiveView.warningKey), findsOneWidget,
        reason: 'AC-7 Given: a low-light warning is shown on the Capture '
            'screen (CAPTURE-4 raises it on a low-light commit)');
    expect(harness.state.lowLightWarning, isTrue,
        reason: 'AC-7 Given: the low-light warning is active');
    expect(harness.state.lastCommittedSample?.accuracy,
        CaptureAccuracy.approximate,
        reason: 'AC-7 Given: the low-light reading is approximate before the '
            'dismiss');

    // When: the painter dismisses the warning (E15).
    await harness.whenDismissWarning();
    final dismissThrow = tester.takeException();
    expect(dismissThrow, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-7: only the pending-stage UnimplementedError may be '
            'deferred by the E15 tap');

    // Then (after the dismiss settles): the warning is cleared — not findable —
    // while the accuracy label stays approximate (rejects a dismiss that also
    // clears or upgrades the accuracy). The warning was present in the Given and
    // is absent now, so this negative Then is a settled observation of a reading
    // that demonstrably changed, not a vacuous one.
    expect(find.byKey(CaptureLiveView.warningKey), findsNothing,
        reason: 'AC-7: the low-light warning is cleared after the dismiss');
    expect(harness.state.lowLightWarning, isFalse,
        reason: 'AC-7: the warning flag is cleared');
    expect(harness.state.lastCommittedSample?.accuracy,
        CaptureAccuracy.approximate,
        reason: 'AC-7: the reading remains approximate — the dismiss does not '
            'change the accuracy label');
  });

  // AC-8 — Calibrating against a reference card normalises captures toward
  // ground truth and upgrades the accuracy to "calibrated" (within ΔE00 3).
  // Owned by CAPTURE-5.
  acTestWidgets('AC-8', 'TestAC08_CardCalibrates', (tester) async {
    // Given: the Capture screen is open on SCENE_CARD — a reference card is
    // present in the frame under controlled lighting (asserted through the read
    // endpoint's source); its ground truth is known.
    final harness = await givenCaptureOf(tester, SCENE_CARD);
    expect(harness.source.referenceCardPresent, isTrue,
        reason: 'AC-8 Given: a reference card is present in the frame');

    // When: the painter calibrates against the card (E17) …
    await harness.whenCalibrate();
    final calibrateThrow = tester.takeException();
    expect(calibrateThrow, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-8: only the pending-stage UnimplementedError may be '
            'deferred by the E17 tap');

    // … and the stated accuracy is upgraded to "Calibrated" on the live label
    // (rejects an accuracy that stays approximate after calibrate). Asserted on
    // the Capture screen before the commit navigates away.
    expect(
        find.descendant(
          of: find.byKey(CaptureLiveView.accuracyKey),
          matching: find.text('Calibrated'),
        ),
        findsOneWidget,
        reason: 'AC-8: calibrating upgrades the accuracy label to "Calibrated"');

    // … then captures (E20).
    await harness.whenCommit();
    final commitThrow = tester.takeException();
    expect(commitThrow, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-8: only the pending-stage UnimplementedError may be '
            'deferred by the E20 tap');

    // Then: the capture is normalised toward ground truth — the committed colour
    // is within ΔE00 3, the calibrated tier's promise (D-4; rejects a
    // calibration that no-ops and leaves the colour at the ΔE8 tier) — and the
    // committed sample carries the upgraded "calibrated" accuracy.
    final committed = harness.state.lastCommittedSample;
    expect(committed, isNotNull,
        reason: 'AC-8: a sample is committed after calibrating');
    expect(committed!.accuracy, CaptureAccuracy.calibrated,
        reason: 'AC-8: the committed sample is upgraded to calibrated');
    expect(_deltaE00(committed.coordinates, harness.source.groundTruth),
        lessThanOrEqualTo(CaptureAccuracy.calibrated.maxDeltaE),
        reason: 'AC-8: the normalised colour is within ΔE00 3 of ground truth');
  });

  // AC-11 — Capturing commits a settled reading averaged over several frames,
  // fires exactly one haptic, and opens the Readout for the captured sample
  // showing "Deep Olive Green". Owned by CAPTURE-6; its "STABLE 12/12" Given is
  // enabled by CAPTURE-3's lock/settle.
  acTestWidgets('AC-11', 'TestAC11_CommitOpensReadout', (tester) async {
    // Given: the Capture screen is open on SCENE_MULTIFRAME (several noisy frames
    // whose per-pixel mean is the ground truth), no haptic has fired, and the
    // reading has reached "STABLE 12/12" via locking. Reaching STABLE is
    // CAPTURE-3 behaviour, so at baseline the lock is deferred and the reading
    // stays "SETTLING 0/12" — this Given precondition reds cleanly naming
    // CAPTURE-3.
    final harness = await givenCaptureOf(tester, SCENE_MULTIFRAME);
    expect(harness.haptics.confirmations, 0,
        reason: 'AC-11 Given: no haptic has fired before the capture');
    await harness.whenLock();
    final lockThrow = tester.takeException();
    expect(lockThrow, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-11: only the pending-stage UnimplementedError may be '
            'deferred by the E16 tap');
    expect(find.text('STABLE 12/12'), findsOneWidget,
        reason: 'AC-11 Given: the reading has reached STABLE 12/12 (CAPTURE-3 '
            'lock/settle) before the capture');

    // When: the painter captures the sample (E20).
    await harness.whenCommit();
    final commitThrow = tester.takeException();
    expect(commitThrow, anyOf(isNull, isA<UnimplementedError>()),
        reason: 'AC-11: only the pending-stage UnimplementedError may be '
            'deferred by the E20 tap');

    // Then: the reading was averaged over several frames (`framesAveraged` > 1 —
    // rejects a single-frame commit by count) and the committed colour is the
    // multi-frame mean, i.e. a valid olive reading within ΔE00 8 of ground truth
    // (the symmetric per-frame noise averages out); exactly one haptic confirmed
    // the landing (rejects no haptic / a double pulse); and the current screen is
    // the Readout for the captured sample, showing "Deep Olive Green" (rejects
    // navigating without the sample or with the wrong name).
    final committed = harness.state.lastCommittedSample;
    expect(committed, isNotNull, reason: 'AC-11: the capture commits a sample');
    expect(harness.state.framesAveraged, greaterThan(1),
        reason: 'AC-11: the reading is averaged over several frames, not one');
    expect(_deltaE00(committed!.coordinates, harness.source.groundTruth),
        lessThanOrEqualTo(CaptureAccuracy.approximate.maxDeltaE),
        reason: 'AC-11: the committed colour is the multi-frame mean, ≈ ground '
            'truth (not a single noisy frame)');
    expect(harness.haptics.confirmations, 1,
        reason: 'AC-11: exactly one haptic confirms the reading landed');
    expect(find.widgetWithText(AppBar, 'Readout'), findsOneWidget,
        reason: 'AC-11: the captured sample opens its Readout');
    expect(
        find.descendant(
          of: find.byKey(NameHeader.headerKey),
          matching: find.text(oliveGroundTruthName),
        ),
        findsOneWidget,
        reason: 'AC-11: the Readout shows the captured sample name '
            '"Deep Olive Green"');
  });
}

// ---------------------------------------------------------------------------
// Test helpers: observe the sampled colour as sRGB and measure colour gaps.
//
// `currentSample` carries canonical CIELAB; rendering it back to sRGB through
// the real `ColorScienceImpl` (the same conversion the fixtures were built
// with) lets the AC Thens compare it to the fixtures' own frame pixels. The gap
// is a plain per-channel L1 distance over 0–255 sRGB — enough to tell the
// distinct region / source colours apart without a perceptual metric.
// ---------------------------------------------------------------------------

/// The real colour-science used to render a sampled CIELAB colour back to sRGB.
const ColorScience _science = ColorScienceImpl();

/// A sampled colour counts as "≈" an expected one when their L1 sRGB gap is
/// under this. Covers the 8-bit round-trip plus the small pull of the single
/// centre-distractor pixel inside the 5 px disc; far below the gaps between the
/// distinct region / source colours the Thens must reject.
const int _sampleToleranceL1 = 45;

/// Per-channel L1 distance between two sRGB triplets (0–255 each).
int _rgbL1(int r1, int g1, int b1, int r2, int g2, int b2) =>
    (r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs();

/// The L1 sRGB gap between a rendered sampled colour and a frame [pixel].
int _distToPixel(SRGBColor sampled, Pixel pixel) =>
    _rgbL1(sampled.red, sampled.green, sampled.blue, pixel.r, pixel.g, pixel.b);

/// The L1 sRGB gap between two rendered colours.
int _distToColor(SRGBColor a, SRGBColor b) =>
    _rgbL1(a.red, a.green, a.blue, b.red, b.green, b.blue);

// ---------------------------------------------------------------------------
// Settling + accuracy helpers for the lifecycle / accuracy / commit ACs.
// ---------------------------------------------------------------------------

/// Pumps the feed up to [maxPumps] frames, stopping as soon as [text] is
/// rendered, so a frame-driven reading (CAPTURE-3's settling counter) can be
/// advanced to a specific value — e.g. "SETTLING 6/12" — before the assertion.
///
/// At baseline the shell never advances the counter, so this exhausts its
/// budget and returns without the text present; the following `expect` then reds
/// cleanly on a Then / Given precondition rather than hanging.
Future<void> _pumpUntilText(
  WidgetTester tester,
  String text, {
  int maxPumps = 60,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (find.text(text).evaluate().isNotEmpty) return;
    await tester.pump();
  }
}

double _deg2rad(double degrees) => degrees * math.pi / 180.0;

/// CIEDE2000 colour difference (ΔE00) between two canonical-CIELAB colours.
///
/// The perceptual metric the accuracy tiers are defined in (D-3/D-4): the
/// accuracy Thens measure the committed sample against the fake source's known
/// ground truth, so "within ΔE00 8 / 3" is a real numeric check rather than
/// label text. Computed test-side (independent of the implementation's own
/// colour maths) so the test defines the bound it enforces. Follows Sharma,
/// Wu & Dalal (2005).
double _deltaE00(ColorCoordinates c1, ColorCoordinates c2) {
  final l1 = c1.lightness, a1 = c1.a, b1 = c1.b;
  final l2 = c2.lightness, a2 = c2.a, b2 = c2.b;

  final cStar1 = math.sqrt(a1 * a1 + b1 * b1);
  final cStar2 = math.sqrt(a2 * a2 + b2 * b2);
  final cBar = (cStar1 + cStar2) / 2.0;
  final cBar7 = math.pow(cBar, 7).toDouble();
  final pow25_7 = math.pow(25, 7).toDouble();
  final g = 0.5 * (1 - math.sqrt(cBar7 / (cBar7 + pow25_7)));

  final a1p = (1 + g) * a1;
  final a2p = (1 + g) * a2;
  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);

  double hPrime(double b, double ap) {
    if (b == 0 && ap == 0) return 0;
    var h = math.atan2(b, ap) * 180.0 / math.pi;
    if (h < 0) h += 360;
    return h;
  }

  final h1p = hPrime(b1, a1p);
  final h2p = hPrime(b2, a2p);

  final dLp = l2 - l1;
  final dCp = c2p - c1p;
  double dhp;
  if (c1p * c2p == 0) {
    dhp = 0;
  } else {
    var diff = h2p - h1p;
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }
    dhp = diff;
  }
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_deg2rad(dhp / 2));

  final lBarp = (l1 + l2) / 2.0;
  final cBarp = (c1p + c2p) / 2.0;
  double hBarp;
  if (c1p * c2p == 0) {
    hBarp = h1p + h2p;
  } else if ((h1p - h2p).abs() <= 180) {
    hBarp = (h1p + h2p) / 2.0;
  } else if (h1p + h2p < 360) {
    hBarp = (h1p + h2p + 360) / 2.0;
  } else {
    hBarp = (h1p + h2p - 360) / 2.0;
  }

  final t = 1 -
      0.17 * math.cos(_deg2rad(hBarp - 30)) +
      0.24 * math.cos(_deg2rad(2 * hBarp)) +
      0.32 * math.cos(_deg2rad(3 * hBarp + 6)) -
      0.20 * math.cos(_deg2rad(4 * hBarp - 63));
  final dTheta = 30 * math.exp(-math.pow((hBarp - 275) / 25, 2).toDouble());
  final cBarp7 = math.pow(cBarp, 7).toDouble();
  final rC = 2 * math.sqrt(cBarp7 / (cBarp7 + pow25_7));
  final sL = 1 +
      (0.015 * math.pow(lBarp - 50, 2).toDouble()) /
          math.sqrt(20 + math.pow(lBarp - 50, 2).toDouble());
  final sC = 1 + 0.045 * cBarp;
  final sH = 1 + 0.015 * cBarp * t;
  final rT = -math.sin(_deg2rad(2 * dTheta)) * rC;

  final termL = dLp / sL;
  final termC = dCp / sC;
  final termH = dHp / sH;
  return math.sqrt(
      termL * termL + termC * termC + termH * termH + rT * termC * termH);
}
