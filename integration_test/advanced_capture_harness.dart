// Acceptance-suite harness for bs-09 Advanced capture (ITEST-1).
//
// The Given/When/Then vocabulary and fixtures the AC tests (ITEST-2, ITEST-3)
// are written against. bs-09 extends bs-02's capture surface and bs-03's
// comparison, both already merged, so this harness builds *on top of* bs-02's
// `capture_harness.dart`: it re-exports that harness (its `CaptureHarness`,
// `givenCaptureOf`, the bs-02 scenes, the `Photo` fixture and the fakes),
// adding only the bs-09 affordances —
//   * `when`-actions for the new controls: the torch toggle (AC-1/AC-2), the
//     "sample points" action (AC-3) and the "send to comparison" pair handoff
//     (AC-5), plus the two deferred controller actions the catalogue drives
//     through the controller (`markPoint`, `acknowledgeTorchWarning`);
//   * observation of bs-03's `ComparisonReadEndpoint` (`slotA`/`slotB`) after
//     the AC-5 handoff (D-9);
//   * the bs-09 fixtures (`SCENE_DIM_TORCH`, `SCENE_THREE_POINTS`, `SCENE_WIDE`,
//     `SCENE_NARROW`, `SCENE_RAW`, `SCENE_ANDROID`, `SCENE_IOS`).
//
// The suite drives the *real* assembled app (bs-01's production `buildApp` on
// the Capture route) through the UI; only infrastructure is faked (the extended
// `FakeCaptureSource` and bs-01's platform sinks). No colour or sampling maths
// is faked — the fixture guard in `advanced_capture_test.dart` samples
// `SCENE_THREE_POINTS` through bs-02's real `sampleAreaAverage`, so the fixture
// the AC-3/AC-4/AC-5 tests lean on is itself checked.
//
// The pending gate (all 10 ACs → owning phase) lives in `bs09/pending.dart`
// (seeded in CAPTURE-1); this harness re-exports it. Because bs-02's harness
// re-exports bs-02's own pending gate, that one is hidden here so the bs-09 gate
// (`BS09_RUN_PENDING`) is the one in scope.
//
// Fixture identifiers mirror the plan's `SCENE_*` names and the AC catalogue
// references them verbatim, so this file opts out of the camelCase lints.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/sampling.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/comparison_controller.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

import 'capture_harness.dart';

// Re-export so an AC test imports only this harness. bs-02's harness carries the
// CaptureHarness / givenCaptureOf vocabulary, the bs-02 scenes, the Photo
// fixture and the fakes; bs-02's own pending gate is hidden so bs-09's gate
// (below) is the `acTestWidgets` / `pendingACs` in scope.
export 'capture_harness.dart'
    hide acTestWidgets, pendingACs, runPending, pendingSkipReason, behaviorPhases;
export 'bs09/pending.dart';
export 'package:paint_color_assistant/capture/capture_state.dart'
    show CaptureState, LockState, MarkedPoint, MultiPointReading;
export 'package:paint_color_assistant/capture/source/capture_source.dart';
export 'package:paint_color_assistant/capture/source/software_capture_source.dart';
export 'package:paint_color_assistant/capture/source/sampling.dart';
export 'package:paint_color_assistant/capture/source/frame.dart';
export 'package:paint_color_assistant/domain/color_coordinates.dart';
export 'package:paint_color_assistant/compare/comparison_controller.dart';
export 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
export 'package:paint_color_assistant/compare/comparison_state.dart';

const ColorScience _science = ColorScienceImpl();

/// The olive scene's known true colour (bs-01's "Deep Olive Green"), reused as
/// the ground truth of the single-colour bs-09 scenes.
const ColorCoordinates _olive = ColorCoordinates(lightness: 40, a: -8, b: 24);

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A dim scene (`Lighting.low`) with a torch available at a fixed warm colour
/// temperature: lighting the torch biases the reading measurably from the
/// ambient ground truth ([SceneSpec.torchColorShift] > 0). Drives AC-1 (the
/// colour-temperature warning) and AC-2 (`litByTorch` on the committed sample).
const CaptureScene SCENE_DIM_TORCH = CaptureScene(
  'SCENE_DIM_TORCH',
  SceneSpec(
    groundTruth: _olive,
    lighting: Lighting.low,
    torchAvailable: true,
    torchColorShift: 8,
  ),
);

/// A device that **supports** wide-gamut (Display P3) capture, at a known
/// ground truth: the capture tags `displayP3` (AC-6) and the committed colour
/// stays within ΔE00 1 of ground truth. **Control** for AC-8 (a non-wide
/// device tags `srgb`).
const CaptureScene SCENE_WIDE = CaptureScene(
  'SCENE_WIDE',
  SceneSpec(groundTruth: _olive, supportsWideGamut: true),
);

/// A device **without** wide-gamut capture: it falls back to the standard sRGB
/// space and labels the narrower space (AC-8). **Control** for AC-6.
const CaptureScene SCENE_NARROW = CaptureScene(
  'SCENE_NARROW',
  SceneSpec(groundTruth: _olive),
);

/// A device that **supports** RAW capture (and the widest gamut it offers):
/// the capture mode is `raw` in the widest space (AC-7). **Control**: a non-RAW
/// device commits `processed` ([SCENE_WIDE] / [SCENE_NARROW]).
const CaptureScene SCENE_RAW = CaptureScene(
  'SCENE_RAW',
  SceneSpec(groundTruth: _olive, supportsRaw: true, supportsWideGamut: true),
);

/// The Android (CameraX) platform config: the same ground truth as
/// [SCENE_IOS], a reference card in view, but a **different** pre-normalization
/// raw offset ([SceneSpec.rawColorShift]). Normalisation against the card must
/// remove the offset so both platforms land on the identical CIELAB (AC-9 for
/// either; AC-10 for both identical).
const CaptureScene SCENE_ANDROID = CaptureScene(
  'SCENE_ANDROID',
  SceneSpec(
    groundTruth: _olive,
    referenceCardPresent: true,
    platform: CapturePlatform.android,
    rawColorShift: 10,
  ),
);

/// The iOS (AVFoundation) platform config: the same ground truth as
/// [SCENE_ANDROID] with a reference card, but a **different** raw offset, so
/// AC-10 proves the committed sample is platform-agnostic after normalisation.
const CaptureScene SCENE_IOS = CaptureScene(
  'SCENE_IOS',
  SceneSpec(
    groundTruth: _olive,
    referenceCardPresent: true,
    platform: CapturePlatform.ios,
    rawColorShift: -8,
  ),
);

// --- Multi-point scene: three well-separated, mutually distinct points --------

/// Three mutually distinct CIELAB region colours, each the true area-average at
/// its marked point. Well apart in CIELAB so a per-point reading cannot be
/// confused with another, and distinct from the neutral field so a point read
/// is not the background.
const ColorCoordinates _pointTeal =
    ColorCoordinates(lightness: 50, a: -22, b: -6);
const ColorCoordinates _pointRed =
    ColorCoordinates(lightness: 55, a: 62, b: 45);
const ColorCoordinates _pointYellow =
    ColorCoordinates(lightness: 72, a: 2, b: 66);

/// The neutral field the three coloured discs sit on — distinct from all three,
/// so a reading that fell back to the background would be caught.
const ColorCoordinates _pointBackground =
    ColorCoordinates(lightness: 50, a: 0, b: 0);

/// A scene paired with the marked points it is sampled at and the colour each
/// point's area-average should return — the bs-09 analogue of [Photo] for
/// multi-point sampling (AC-3, AC-4, AC-5).
class MultiPointScene {
  const MultiPointScene(this.scene, this.points, this.colorsAtPoints);

  /// The capture scene to open (passed to [givenCaptureOf]).
  final CaptureScene scene;

  /// The frame positions the painter marks, in order (P1, P2, P3).
  final List<MarkedPoint> points;

  /// The true area-average colour at each point in [points], same order — what
  /// a correct per-point reading returns (checked by the fixture guard through
  /// bs-02's real `sampleAreaAverage`).
  final List<ColorCoordinates> colorsAtPoints;
}

/// Three well-separated sample points on a 64×64 frame whose default-radius
/// area-averages are mutually distinct (and distinct from the field). Each disc
/// (radius 8 px) fully contains the 5 px sampling disc, so the sampled colour at
/// each point is that disc's colour. Drives AC-3, AC-4, AC-5.
final MultiPointScene SCENE_THREE_POINTS = MultiPointScene(
  CaptureScene(
    'SCENE_THREE_POINTS',
    SceneSpec(
      // Ground truth is the first point's colour; the per-point values the AC
      // tests assert are [colorsAtPoints], not this single anchor.
      groundTruth: _pointTeal,
      frames: [
        _threePointsFrame(
          background: _pointBackground,
          discs: const [
            (MarkedPoint(14, 14), _pointTeal),
            (MarkedPoint(50, 14), _pointRed),
            (MarkedPoint(32, 50), _pointYellow),
          ],
          discRadiusPx: 8,
        ),
      ],
    ),
  ),
  const [MarkedPoint(14, 14), MarkedPoint(50, 14), MarkedPoint(32, 50)],
  const [_pointTeal, _pointRed, _pointYellow],
);

// --- Frame builders -----------------------------------------------------------

Pixel _pixelFor(ColorCoordinates lab) {
  final srgb = _science.toSRGB(lab);
  return Pixel(srgb.red, srgb.green, srgb.blue);
}

/// A [width]×[height] frame of a [background] field with one disc of
/// [discRadiusPx] per entry in [discs], each centred on its [MarkedPoint] and
/// filled with its colour.
Frame _threePointsFrame({
  required ColorCoordinates background,
  required List<(MarkedPoint, ColorCoordinates)> discs,
  required int discRadiusPx,
  int width = 64,
  int height = 64,
}) {
  final backgroundPx = _pixelFor(background);
  final discPixels = [
    for (final (point, color) in discs) (point, _pixelFor(color)),
  ];
  final pixels = <Pixel>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      Pixel px = backgroundPx;
      for (final (point, discPx) in discPixels) {
        final dx = x - point.x;
        final dy = y - point.y;
        if (dx * dx + dy * dy <= discRadiusPx * discRadiusPx) {
          px = discPx;
          break;
        }
      }
      pixels.add(px);
    }
  }
  return Frame(width: width, height: height, pixels: pixels);
}

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// The bs-09 `when`-actions and observation points layered over bs-02's
/// [CaptureHarness].
///
/// The torch toggle, "sample points" and "send to comparison" controls are
/// driven through the real Capture UI (SCREEN-1's anchors); the deferred
/// controller actions the catalogue builds Givens with (`markPoint`,
/// `acknowledgeTorchWarning`) and the specific pair handoff (`sendPairToComparison`
/// — SCREEN-1's button carries a placeholder pair) are driven through the
/// controller the read endpoint exposes. All of these are `UnimplementedError`
/// stubs until their behaviour phase lands, which is why every AC that uses them
/// stays pending until then.
extension AdvancedCaptureActions on CaptureHarness {
  Future<void> _tapKey(Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  /// Turns the camera torch on (AC-1, AC-2) by tapping the torch control.
  Future<void> whenTurnTorchOn() => _tapKey(CaptureControls.torchKey);

  /// Turns the torch off by tapping the torch control.
  Future<void> whenTurnTorchOff() => _tapKey(CaptureControls.torchKey);

  /// Acknowledges the torch colour-temperature warning while leaving the torch
  /// lit (AC-2). Driven through the controller — SCREEN-1 has no dedicated
  /// acknowledge control; CAPTURE-3/SCREEN-2 give this behaviour.
  Future<void> whenAcknowledgeTorchWarning() async {
    controller.acknowledgeTorchWarning();
    await tester.pumpAndSettle();
  }

  /// Marks the point ([x], [y]) on the live frame for multi-point sampling
  /// (AC-3). Driven through the controller — the mark gesture is wired in
  /// CAPTURE-4.
  Future<void> whenMarkPoint(int x, int y) async {
    controller.markPoint(x, y);
    await tester.pumpAndSettle();
  }

  /// Marks every point in [points] in order (AC-3 Given).
  Future<void> whenMarkPoints(Iterable<MarkedPoint> points) async {
    for (final point in points) {
      await whenMarkPoint(point.x, point.y);
    }
  }

  /// Samples the marked points (AC-3) by tapping the "Sample points" control.
  Future<void> whenSamplePoints() => _tapKey(CaptureControls.samplePointsKey);

  /// Taps the "Send to comparison" control (AC-5). SCREEN-1's button carries a
  /// placeholder index pair; the chosen-pair handoff is [whenSendPairToComparison].
  Future<void> whenSendToComparison() =>
      _tapKey(CaptureControls.sendToComparisonKey);

  /// Sends the readings at marked indices [i] and [j] to the comparison (AC-5).
  /// Driven through the controller — the pair-selection UI lands in CAPTURE-5.
  Future<void> whenSendPairToComparison(int i, int j) async {
    controller.sendPairToComparison(i, j);
    await tester.pumpAndSettle();
  }

  /// The live [ComparisonController] bs-03 exposes, observed after the AC-5
  /// pair handoff navigates to the Comparison screen (D-9).
  ///
  /// `skipOffstage: false` so it is found whether the Comparison screen is the
  /// top route or sits under a later push.
  ComparisonController get comparisonController => tester
      .widget<ComparisonReadEndpoint>(
        find.byKey(ComparisonReadEndpoint.endpointKey, skipOffstage: false),
      )
      .controller;
}

/// The area-average colour at ([point]) of the first frame of [scene], sampled
/// at the default radius through bs-02's real sampling maths.
///
/// The fixture guard uses this to prove `SCENE_THREE_POINTS`' three points are
/// mutually distinct before the AC tests rely on it, so the fixture is checked
/// with the same code the app samples with — never faked.
ColorCoordinates sampleSceneAt(CaptureScene scene, MarkedPoint point) {
  final frame = scene.spec.frames!.first;
  return sampleAreaAverage(frame, point.x, point.y);
}

/// Straight-line CIELAB (CIE76) distance between [a] and [b] — enough to assert
/// the multi-point fixtures are "well apart" without pulling in a full ΔE00.
double labDistance(ColorCoordinates a, ColorCoordinates b) {
  final dl = a.lightness - b.lightness;
  final da = a.a - b.a;
  final db = a.b - b.b;
  return math.sqrt(dl * dl + da * da + db * db);
}
