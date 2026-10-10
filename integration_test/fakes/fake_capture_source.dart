import 'dart:async';

import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

/// A recording [CaptureSource] for the bs-02 acceptance suite (D-2).
///
/// It is the deterministic [SoftwareCaptureSource] with two test affordances the
/// acceptance Thens read: it **counts frame reads** (so a multi-frame commit can
/// be told apart from a single-frame one — AC-11) and exposes the scene's known
/// [groundTruth] colour (so "within ΔE00 N of ground truth" is a numeric check —
/// AC-6/AC-8, D-4). No colour or sampling maths is faked; only this frame
/// infrastructure and (elsewhere) bs-01's platform sinks are.
class FakeCaptureSource extends SoftwareCaptureSource {
  /// Builds a fake over [scene] (its ground truth, lighting, lock capability,
  /// reference-card presence, per-frame noise and any explicit frames).
  FakeCaptureSource(super.scene);

  int _framesRead = 0;

  /// How many frames have been pulled from [frames] so far.
  ///
  /// A capture that averages several frames (AC-11) drives this past 1; a
  /// single-frame read leaves it at 1. Zero before the feed is read.
  int get framesRead => _framesRead;

  /// A scene swapped in for a *subsequent* capture, or null to read the scene the
  /// source was built over.
  ///
  /// The re-photograph loop (bs-05 AC-8) models the painter adjusting the
  /// physical mix and photographing again: after [rephotographAs] the next
  /// capture reads the new swatch, so the re-check sees a different measured
  /// colour than the first check. Left null, the fake behaves exactly as before —
  /// every read (the frame feed, the ground truth, the card-normalised result)
  /// follows the constructor scene, so the existing bs-02..bs-04 suites are
  /// unaffected.
  SceneSpec? _rephotographed;

  /// Swaps the live scene so the *next* capture reads [scene] (AC-8): the painter
  /// corrected the mix, so the camera now sees a closer swatch.
  void rephotographAs(SceneSpec scene) => _rephotographed = scene;

  /// The scene the next capture reads — the swapped-in scene once a re-photograph
  /// has been staged, otherwise the constructor [scene].
  SceneSpec get _liveScene => _rephotographed ?? scene;

  /// The live scene's known true colour, in canonical CIELAB — the ΔE anchor the
  /// accuracy Thens measure a committed sample against (D-4).
  ColorCoordinates get groundTruth => _liveScene.groundTruth;

  /// The deterministic card-normalised reading: the live scene's ground truth
  /// (base behaviour), tracking a staged re-photograph (AC-8) so the re-measured
  /// swatch is the new scene's colour, not the first's.
  @override
  ColorCoordinates normaliseAgainstCard(ColorCoordinates raw) =>
      _liveScene.groundTruth;

  /// A photo staged for the next import (AC-9), or null when none is staged.
  ///
  /// [whenImportPhoto] stages it here before tapping E19; the import flow
  /// consumes it through the production [importedPhoto] surface, which this fake
  /// derives from the staged fixture below. A test seam, not a production
  /// control.
  Photo? stagedPhoto;

  /// Surfaces the [stagedPhoto] fixture through the production import surface
  /// the controller reads (SOURCE-3), so staging a fixture is equivalent to the
  /// painter picking that image from the gallery.
  @override
  ImportedPhoto? get importedPhoto => stagedPhoto == null
      ? null
      : ImportedPhoto(
          image: stagedPhoto!.image,
          pointX: stagedPhoto!.pointX,
          pointY: stagedPhoto!.pointY,
        );

  @override
  Stream<Frame> get frames {
    // The constructor scene's feed by default; the swapped-in scene's feed once a
    // re-photograph is staged (AC-8), so the re-check pulls frames of the new
    // swatch. Either way every frame read is counted (AC-11).
    final feed = _rephotographed == null
        ? super.frames
        : SoftwareCaptureSource(_rephotographed!).frames;
    return feed.map((frame) {
      _framesRead++;
      return frame;
    });
  }
}

/// A gallery photo the painter can import and sample a point from (AC-9).
///
/// Carries the decoded [image], the sample point ([pointX], [pointY]) — chosen
/// off-centre so a wrong-point read is caught — and the known [colorAtPoint] in
/// canonical CIELAB that a correct sample of that point should return.
class Photo {
  const Photo({
    required this.id,
    required this.image,
    required this.pointX,
    required this.pointY,
    required this.colorAtPoint,
  });

  /// A human-readable fixture id, for failure messages.
  final String id;

  /// The decoded image the photo imports as.
  final Frame image;

  /// The sample point's column (0-based), off the image centre.
  final int pointX;

  /// The sample point's row (0-based), off the image centre.
  final int pointY;

  /// The true colour at ([pointX], [pointY]), in canonical CIELAB.
  final ColorCoordinates colorAtPoint;
}
