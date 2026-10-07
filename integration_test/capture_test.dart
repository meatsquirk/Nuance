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

import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';

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
      // readable through the endpoint the AC Thens use.
      expect(harness.state.lockState, LockState.auto);
      expect(harness.state.radiusPx, 5);
      expect(harness.state.currentSample, isNull);
      expect(harness.haptics.confirmations, 0);
    },
  );

  group('pending gate', () {
    // The owner of each AC is the phase whose acceptance gate un-pends it,
    // matching ITEST's red-baseline *Owning phase* column. Pinned exactly so a
    // typo'd id, a missing AC, a stray AC or a re-owned AC fails this test
    // rather than passing vacuously. AC-1 is absent: it was un-pended at ITEST-2
    // as green at baseline (its always-running test is below), so only the ten
    // still-pending ACs remain here.
    const expectedOwners = {
      'AC-2': 'SOURCE-2',
      'AC-3': 'SCREEN-2',
      'AC-4': 'CAPTURE-3',
      'AC-5': 'CAPTURE-3',
      'AC-6': 'CAPTURE-4',
      'AC-7': 'CAPTURE-4',
      'AC-8': 'CAPTURE-5',
      'AC-9': 'SOURCE-3',
      'AC-10': 'SCREEN-3',
      'AC-11': 'CAPTURE-6',
    };

    test('the still-pending ACs are each owned by a real behaviour phase', () {
      expect(pendingACs, expectedOwners);
      expect(pendingACs.length, 10);
      for (final owner in pendingACs.values) {
        expect(behaviorPhases, contains(owner),
            reason: '"$owner" is not a known bs-02 behaviour phase');
      }
    });

    test('a pending AC is skipped by default and runs only in run-pending mode',
        () {
      // A mapped (pending) AC: skipped in the default run, run in run-pending.
      expect(pendingSkipReason('AC-2', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-2', forceRunPending: true), isNull);
      // An un-mapped AC always runs, in either mode — the end state as each
      // behaviour phase deletes its row, and the state AC-1 is already in
      // (un-pended at ITEST-2 as green at baseline).
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNull);
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
