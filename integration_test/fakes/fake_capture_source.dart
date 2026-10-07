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

  /// The scene's known true colour, in canonical CIELAB — the ΔE anchor the
  /// accuracy Thens measure a committed sample against (D-4).
  ColorCoordinates get groundTruth => scene.groundTruth;

  /// A photo staged for the next import (AC-9), or null when none is staged.
  ///
  /// [whenImportPhoto] stages it here before tapping E19; the photo-import flow
  /// that consumes it is wired in SOURCE-3 (which owns how the controller reads a
  /// staged photo and enables E19). A test seam, not a production control.
  Photo? stagedPhoto;

  @override
  Stream<Frame> get frames =>
      super.frames.map((frame) {
        _framesRead++;
        return frame;
      });
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
