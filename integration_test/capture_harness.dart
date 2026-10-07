// Acceptance-suite harness for bs-02 Sample capture (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and buildApp driver the AC tests
// (ITEST-2, ITEST-3) are written against. The suite drives the *real* assembled
// app through bs-01's single production `buildApp` entry (D-6/D-7) with a
// capture source injected, so it opens on the Capture screen; `WidgetTester`
// drives the UI and the `CaptureReadEndpoint` observes the capture state.
//
// Faked (infrastructure only): the camera source (`FakeCaptureSource` — software
// frames + known ground truth, records frame reads) and bs-01's `FakeHaptics` /
// `FakeSpeech` sinks. Sampling, lock/settle, accuracy/calibration, the screen,
// routing and commit are the real code — which is why every AC stays pending
// until its behaviour phase lands (see `bs02/pending.dart`).
//
// Fixture identifiers mirror the plan's `SCENE_*` / `PHOTO_*` names, and the AC
// catalogue references them verbatim, so this file opts out of the camelCase
// lints for them.
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

import 'fakes/fake_capture_source.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export so an AC test only needs to import this harness: the pending gate
// (`acTestWidgets`, `pendingACs`, …), the fakes and the `Photo` fixture type.
export 'bs02/pending.dart';
export 'fakes/fake_capture_source.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// A scene's `groundTruth` is the canonical-CIELAB colour it really is — the ΔE
// anchor the accuracy Thens measure against. Non-uniform control scenes
// (`SCENE_CENTRE_VARIED`) and photos (`PHOTO_SWATCH`) carry explicit frames
// whose pixels are rendered from chosen CIELAB region colours via bs-01's real
// `ColorScienceImpl.toSRGB`, so sampling them back (SOURCE-2) returns ≈ those
// colours. The uniform scenes leave `frames` null: SOURCE-2 generates a feed
// from `groundTruth` (+ `noise` for `SCENE_MULTIFRAME`).
// ---------------------------------------------------------------------------

const ColorScience _science = ColorScienceImpl();

/// The known true colour of the olive scene (bs-01's "Deep Olive Green"); the
/// name AC-11's Readout must show.
const ColorCoordinates _olive = ColorCoordinates(lightness: 40, a: -8, b: 24);

/// The plain-language name bs-01's colour-science derives from [_olive] — what
/// AC-11 asserts the opened Readout shows after a commit.
const String oliveGroundTruthName = 'Deep Olive Green';

/// A scene paired with its known ground truth and (for the olive scenes) the
/// derived plain-language name, built into a [FakeCaptureSource] by
/// [givenCaptureOf].
class CaptureScene {
  const CaptureScene(this.id, this.spec, {this.groundTruthName});

  /// A human-readable fixture id, for failure messages.
  final String id;

  /// How the software source renders this scene.
  final SceneSpec spec;

  /// The plain-language name the committed reading should carry (AC-11), or null
  /// where the scene is not asserted by name.
  final String? groundTruthName;

  /// The scene's true colour, in canonical CIELAB.
  ColorCoordinates get groundTruth => spec.groundTruth;
}

/// Deep Olive Green under adequate light, no card. Drives AC-1, AC-2, AC-3,
/// AC-11; the import host for AC-9.
const CaptureScene SCENE_OLIVE = CaptureScene(
  'SCENE_OLIVE',
  SceneSpec(groundTruth: _olive),
  groundTruthName: oliveGroundTruthName,
);

/// SCENE_DIM's raw (uncalibrated) reading, ΔE00 ≈ 5.1 off ground truth
/// (CIEDE2000, verified against Sharma et al.): a genuinely approximate dim
/// reading — within the approximate tier's ΔE00 8 but well outside the
/// calibrated tier's ΔE00 3. This makes AC-6's "within ΔE00 8" bite and gives the
/// CAPTURE-5 augmentation a real approximate-vs-calibrated contrast; a dim
/// reading sitting at ΔE00 0 would defeat both.
const ColorCoordinates _dimRaw = ColorCoordinates(lightness: 34, a: -8, b: 24);

/// SCENE_CARD's raw (uncalibrated) reading, ΔE00 ≈ 4.6 off ground truth
/// (CIEDE2000, verified): outside the calibrated tier's ΔE00 3, so AC-8's
/// "normalised within ΔE00 3" rejects a calibration that only relabels the
/// accuracy without correcting the colour (the catalogue's "calibration no-ops"
/// Reject). Only a calibration that actually normalises toward ground truth
/// lands the committed colour within ΔE00 3.
const ColorCoordinates _cardRaw = ColorCoordinates(lightness: 45, a: -8, b: 24);

/// The olive scene under dim light with no card: the source flags low light and
/// the raw reading sits within ΔE00 8 of ground truth ([_dimRaw]). Drives AC-6,
/// AC-7.
final CaptureScene SCENE_DIM = CaptureScene(
  'SCENE_DIM',
  SceneSpec(
    groundTruth: _olive,
    lighting: Lighting.low,
    frames: [_uniformFrame(_dimRaw)],
  ),
  groundTruthName: oliveGroundTruthName,
);

/// The olive scene with a reference card in view under controlled light: the raw
/// reading sits ΔE00 ≈ 4.6 off ground truth ([_cardRaw]) until calibration
/// normalises it toward ground truth (within ΔE00 3). Drives AC-8, and the AC-6
/// accuracy-tier control (CAPTURE-5 augmentation).
final CaptureScene SCENE_CARD = CaptureScene(
  'SCENE_CARD',
  SceneSpec(
    groundTruth: _olive,
    referenceCardPresent: true,
    frames: [_uniformFrame(_cardRaw)],
  ),
  groundTruthName: oliveGroundTruthName,
);

/// Per-frame noise amplitude for [SCENE_MULTIFRAME]: SOURCE-2 generates several
/// distinct frames whose per-pixel mean is the ground truth.
const double _multiframeNoise = 6;

/// The olive scene as several noisy frames whose mean is the ground truth.
/// Drives AC-11's "averaged over several frames".
const CaptureScene SCENE_MULTIFRAME = CaptureScene(
  'SCENE_MULTIFRAME',
  SceneSpec(groundTruth: _olive, noise: _multiframeNoise),
  groundTruthName: oliveGroundTruthName,
);

// --- Non-uniform control scene: centre pixel ≠ 5 px average ≠ 21 px average ---

// Three well-separated CIELAB region colours. The single centre pixel is a
// distractor a point read returns; the inner disc (r ≤ 8 px) is what a correct
// 5 px sample reads; the outer band (r > 8 px) pulls the 21 px average off the
// 5 px one. The frame is 64×64 so a 21 px-radius disc fits around the centre.
const ColorCoordinates _variedCentre =
    ColorCoordinates(lightness: 55, a: 62, b: 45); // vivid red speck
const ColorCoordinates _variedDisc =
    ColorCoordinates(lightness: 50, a: -22, b: -6); // teal — the 5 px read
const ColorCoordinates _variedOuter =
    ColorCoordinates(lightness: 72, a: 2, b: 66); // yellow — widens the 21 px avg

/// A scene whose centre pixel, 5 px-radius average and 21 px-radius average are
/// three distinct colours. **Control** for AC-2 (rejects a point read) and AC-3
/// (rejects averaging over the wrong radius). Its [groundTruth] is the inner-disc
/// colour — the value a correct 5 px sample returns.
final CaptureScene SCENE_CENTRE_VARIED = CaptureScene(
  'SCENE_CENTRE_VARIED',
  SceneSpec(
    groundTruth: _variedDisc,
    frames: [
      _concentricFrame(
        centre: _variedCentre,
        inner: _variedDisc,
        outer: _variedOuter,
        innerRadiusPx: 8,
      ),
    ],
  ),
);

// --- Gallery photo: a known colour at an off-centre point P -------------------

const ColorCoordinates _photoBackground =
    ColorCoordinates(lightness: 50, a: 0, b: 0); // neutral grey field
const ColorCoordinates _photoSwatch =
    ColorCoordinates(lightness: 55, a: 50, b: -10); // magenta swatch at P

/// A gallery image with a known colour at point P = (12, 12), off the image
/// centre (24, 24). Drives AC-9: a correct import samples P, not the live camera
/// and not the image centre.
final Photo PHOTO_SWATCH = Photo(
  id: 'PHOTO_SWATCH',
  image: _swatchPhotoFrame(
    background: _photoBackground,
    swatch: _photoSwatch,
    pointX: 12,
    pointY: 12,
    swatchRadiusPx: 6,
  ),
  pointX: 12,
  pointY: 12,
  colorAtPoint: _photoSwatch,
);

// --- Frame builders -----------------------------------------------------------

Pixel _pixelFor(ColorCoordinates lab) {
  final srgb = _science.toSRGB(lab);
  return Pixel(srgb.red, srgb.green, srgb.blue);
}

/// A flat [width]×[height] frame of a single [color] — a uniform scene whose
/// sampled colour at any point or radius is exactly [color]. Used for the
/// accuracy-tier scenes (SCENE_DIM / SCENE_CARD), whose raw reading sits a known
/// ΔE00 off ground truth so the accuracy / normalisation Thens are not vacuous.
Frame _uniformFrame(ColorCoordinates color, {int width = 48, int height = 48}) {
  final px = _pixelFor(color);
  return Frame(
    width: width,
    height: height,
    pixels: List<Pixel>.filled(width * height, px),
  );
}

/// A [width]×[height] frame of a single centre-pixel [centre], an [inner] disc
/// out to [innerRadiusPx], and [outer] beyond it.
Frame _concentricFrame({
  required ColorCoordinates centre,
  required ColorCoordinates inner,
  required ColorCoordinates outer,
  required int innerRadiusPx,
  int width = 64,
  int height = 64,
}) {
  final centrePx = _pixelFor(centre);
  final innerPx = _pixelFor(inner);
  final outerPx = _pixelFor(outer);
  final cx = width ~/ 2;
  final cy = height ~/ 2;
  final pixels = <Pixel>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx == 0 && dy == 0) {
        pixels.add(centrePx);
      } else if (dx * dx + dy * dy <= innerRadiusPx * innerRadiusPx) {
        pixels.add(innerPx);
      } else {
        pixels.add(outerPx);
      }
    }
  }
  return Frame(width: width, height: height, pixels: pixels);
}

/// A [width]×[height] image: a [background] field with a [swatch] disc of
/// [swatchRadiusPx] centred on ([pointX], [pointY]).
Frame _swatchPhotoFrame({
  required ColorCoordinates background,
  required ColorCoordinates swatch,
  required int pointX,
  required int pointY,
  required int swatchRadiusPx,
  int width = 48,
  int height = 48,
}) {
  final backgroundPx = _pixelFor(background);
  final swatchPx = _pixelFor(swatch);
  final pixels = <Pixel>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final dx = x - pointX;
      final dy = y - pointY;
      if (dx * dx + dy * dy <= swatchRadiusPx * swatchRadiusPx) {
        pixels.add(swatchPx);
      } else {
        pixels.add(backgroundPx);
      }
    }
  }
  return Frame(width: width, height: height, pixels: pixels);
}

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one capture scenario.
///
/// Holds the injected [source] (its known ground truth and recorded frame reads)
/// and the recording [haptics] sink the Thens read, and exposes the `when…`
/// actions a painter takes on the Capture screen. Observes capture state through
/// the [CaptureReadEndpoint] the screen provides.
class CaptureHarness {
  CaptureHarness(this.tester, {required this.source, required this.haptics});

  /// The widget tester driving the real Capture UI.
  final WidgetTester tester;

  /// The fake capture source the scene was built into (ground truth, frame-read
  /// count, staged photo).
  final FakeCaptureSource source;

  /// The recording haptics sink injected into the app (AC-11).
  final FakeHaptics haptics;

  /// The live controller the Capture screen owns, via the read endpoint.
  CaptureController get controller => tester
      .widget<CaptureReadEndpoint>(
        find.byKey(CaptureReadEndpoint.endpointKey),
      )
      .controller;

  /// The current observable capture state.
  CaptureState get state => controller.state;

  Future<void> _tap(Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  /// Locks exposure / white balance / focus together (E16 — AC-4).
  Future<void> whenLock() => _tap(CaptureControls.lockKey);

  /// Captures (commits) the settled reading (E20 — AC-11).
  Future<void> whenCommit() => _tap(CaptureControls.captureKey);

  /// Dismisses the low-light warning (E15 — AC-7).
  Future<void> whenDismissWarning() => _tap(CaptureControls.dismissWarningKey);

  /// Calibrates against the reference card (E17 — AC-8).
  Future<void> whenCalibrate() => _tap(CaptureControls.calibrateKey);

  /// Toggles the value-only grayscale preview (E21 — AC-10).
  Future<void> whenToggleValueOnly() => _tap(CaptureControls.valueOnlyKey);

  /// Selects the sampling-radius option [radiusPx] (1 / 5 / 21 px — E18, AC-3).
  ///
  /// Taps the E18 radius region. SCREEN-2 builds the real 1/5/21 selector; when
  /// it lands it gives each option its own anchor and this helper targets the
  /// one for [radiusPx]. Until then it taps the region placeholder so AC-3 stays
  /// pending on its Then, not on a missing control.
  Future<void> whenSelectRadius(int radiusPx) => _tap(CaptureControls.radiusKey);

  /// Imports [photo] from the gallery and samples its point P (E19 — AC-9).
  ///
  /// Stages [photo] on the fake source, then taps E19. SOURCE-3 wires how the
  /// controller reads the staged photo and enables E19; until then the staged
  /// photo is held and the tap is a no-op, so AC-9 stays pending on its Then.
  Future<void> whenImportPhoto(Photo photo) async {
    source.stagedPhoto = photo;
    await _tap(CaptureControls.importKey);
  }
}

/// Opens the Capture screen on [scene] in the fully assembled app.
///
/// Builds the real app via bs-01's production `buildApp` entry with a
/// [FakeCaptureSource] over [scene] injected and the platform sinks faked;
/// colour-science is the real `ColorScienceImpl`. Because a capture source is
/// present, `buildApp` opens on the Capture screen (D-7). Returns a
/// [CaptureHarness] over the booted app.
Future<CaptureHarness> givenCaptureOf(
  WidgetTester tester,
  CaptureScene scene,
) async {
  final source = FakeCaptureSource(scene.spec);
  final haptics = FakeHaptics();
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: _science,
        speech: FakeSpeech(),
        haptics: haptics,
        captureSource: source,
      ),
    ),
  );
  // Mount with a single frame rather than `pumpAndSettle`: the stability reading
  // settles one step per rendered frame (CAPTURE-3), so `pumpAndSettle` would run
  // it straight to "STABLE 12/12". Opening leaves it at "SETTLING 0/12" (the
  // first build renders before the first settle tick draws) with the live feed
  // already sampled into `currentSample`; the lock/settle ACs then pump frames to
  // watch it climb (see `_pumpUntilText`). `when…` actions pumpAndSettle locally.
  return CaptureHarness(tester, source: source, haptics: haptics);
}
