import 'package:flutter/foundation.dart';

import '../domain/color_coordinates.dart';
import '../domain/sample.dart';
import 'capture_accuracy.dart';
import 'source/capture_source.dart';
import 'source/sampling.dart';

/// Whether exposure / white balance / focus are running automatically or have
/// been locked together to settle the reading (AC-4, AC-5).
enum LockState {
  /// Auto-exposure / auto-white-balance / auto-focus are still adjusting; the
  /// reading is settling and the lock control invites the painter to lock.
  auto,

  /// AE, AWB and AF are locked together; the reading can reach "STABLE 12/12".
  locked,
}

/// A point the painter has marked on the live frame for multi-point sampling
/// (bs-09 AC-3).
///
/// Holds the frame-pixel position ([x], [y]) the painter tapped; the controller
/// samples the current frame at each marked point to produce a
/// [MultiPointReading]. Behaviour lands in CAPTURE-4; this shell fixes the shape.
class MarkedPoint {
  const MarkedPoint(this.x, this.y);

  /// The marked point's column (0-based) on the frame.
  final int x;

  /// The marked point's row (0-based) on the frame.
  final int y;

  @override
  bool operator ==(Object other) =>
      other is MarkedPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'MarkedPoint($x, $y)';
}

/// One reading taken at a [MarkedPoint] (bs-09 AC-3, AC-4): the point's frame
/// [position] kept alongside the colour [coordinates] sampled there.
///
/// Each reading keeps its own position so the Capture screen can show every
/// marked point with its own value (AC-4). Behaviour lands in CAPTURE-4; this
/// shell fixes the shape.
class MultiPointReading {
  const MultiPointReading({required this.position, required this.coordinates});

  /// The frame position this reading was sampled at.
  final MarkedPoint position;

  /// The colour sampled at [position], in canonical CIELAB.
  final ColorCoordinates coordinates;

  @override
  bool operator ==(Object other) =>
      other is MultiPointReading &&
      other.position == position &&
      other.coordinates == coordinates;

  @override
  int get hashCode => Object.hash(position, coordinates);

  @override
  String toString() => 'MultiPointReading($position → $coordinates)';
}

/// The observable state of a capture in progress, held by the
/// [CaptureController] and surfaced to the Capture screen and the acceptance
/// read endpoint.
///
/// A plain immutable snapshot: the controller replaces it (via [copyWith]) and
/// notifies on every change. The behaviour that moves these fields lands in the
/// CAPTURE behaviour phases; this shell fixes their shape and the two derived
/// readings the UI shows as text — [stabilityText] and [isStable].
class CaptureState {
  const CaptureState({
    this.lockState = LockState.auto,
    this.stabilityCount = 0,
    this.radiusPx = kDefaultSamplingRadiusPx,
    this.accuracy = CaptureAccuracy.approximate,
    this.valueOnly = false,
    this.lowLightWarning = false,
    this.currentSample,
    this.lastCommittedSample,
    this.framesAveraged = 0,
    this.torchOn = false,
    this.torchWarning,
    this.markedPoints = const [],
    this.markedReadings = const [],
  });

  /// Whether AE/AWB/AF are auto or locked (AC-4, AC-5).
  final LockState lockState;

  /// Frames settled so far toward a stable reading, out of
  /// [kStabilityFrameTarget] (the "n" in "SETTLING n/12").
  final int stabilityCount;

  /// The sampling radius in pixels (default [kDefaultSamplingRadiusPx], 5 px —
  /// D-7). The radius selector (SCREEN-2) moves it to 1 / 5 / 21 px.
  final int radiusPx;

  /// The stated accuracy tier of the capture (D-3); downgraded in low light,
  /// upgraded by reference-card calibration. Defaults to
  /// [CaptureAccuracy.approximate].
  final CaptureAccuracy accuracy;

  /// Whether the live feed is shown value-only (grayscale) — the "✓ Value"
  /// preview (AC-10).
  final bool valueOnly;

  /// Whether a low-light warning is currently shown (AC-6, AC-7).
  final bool lowLightWarning;

  /// The colour sampled under the reticle right now, or null before a sample is
  /// read. Canonical CIELAB, carried on a [Sample].
  final Sample? currentSample;

  /// The sample committed by the last capture, or null before the first commit
  /// (AC-11). Carries the [accuracy] it was committed at.
  final Sample? lastCommittedSample;

  /// How many frames the last commit averaged over (AC-11). Zero before the
  /// first commit.
  final int framesAveraged;

  /// Whether the camera torch is currently lit (bs-09 AC-1, AC-2). Default
  /// false; moved by [CaptureController.turnTorchOn]/[turnTorchOff] (CAPTURE-3).
  final bool torchOn;

  /// The colour-temperature warning shown while the torch biases the reading
  /// (bs-09 AC-1), or null when none is shown. Set when the torch is lit and
  /// cleared on acknowledgement (CAPTURE-3).
  final String? torchWarning;

  /// The points the painter has marked for multi-point sampling (bs-09 AC-3),
  /// empty until any is marked. Moved by [CaptureController.markPoint] /
  /// [clearMarkedPoints] (CAPTURE-4).
  final List<MarkedPoint> markedPoints;

  /// One reading per marked point, each keeping its own frame position and value
  /// (bs-09 AC-3, AC-4), empty until [CaptureController.sampleMarkedPoints] runs
  /// (CAPTURE-4).
  final List<MultiPointReading> markedReadings;

  /// True once [stabilityCount] has reached [kStabilityFrameTarget].
  bool get isStable => stabilityCount >= kStabilityFrameTarget;

  /// The stability indicator text: "STABLE 12/12" once settled (or locked),
  /// otherwise "SETTLING n/12" (AC-4, AC-5).
  String get stabilityText {
    final settled = isStable || lockState == LockState.locked;
    final label = settled ? 'STABLE' : 'SETTLING';
    final count = settled ? kStabilityFrameTarget : stabilityCount;
    return '$label $count/$kStabilityFrameTarget';
  }

  /// The exposure/white-balance/focus lock indicator (AC-4). Reads
  /// "AE · AWB · AF LOCKED" once the three are locked together, otherwise
  /// "AE · AWB · AF AUTO" while they run automatically.
  String get lockIndicatorText => lockState == LockState.locked
      ? 'AE · AWB · AF LOCKED'
      : 'AE · AWB · AF AUTO';

  /// Returns a copy with the given fields replaced.
  ///
  /// Follows the repo's `x ?? this.x` merge, so the nullable sample fields are
  /// set-forward only (a commit fills [lastCommittedSample]); clearing them back
  /// to null is not a transition the capture flow needs.
  ///
  /// [torchWarning] is the one nullable the flow *does* clear: the torch is
  /// turned off and the banner acknowledged (CAPTURE-3), so [clearTorchWarning]
  /// forces it back to null past the set-forward merge. Passing both
  /// [clearTorchWarning] and a non-null [torchWarning] is a contradiction the
  /// flow never makes — clearing wins.
  CaptureState copyWith({
    LockState? lockState,
    int? stabilityCount,
    int? radiusPx,
    CaptureAccuracy? accuracy,
    bool? valueOnly,
    bool? lowLightWarning,
    Sample? currentSample,
    Sample? lastCommittedSample,
    int? framesAveraged,
    bool? torchOn,
    String? torchWarning,
    bool clearTorchWarning = false,
    List<MarkedPoint>? markedPoints,
    List<MultiPointReading>? markedReadings,
  }) {
    return CaptureState(
      lockState: lockState ?? this.lockState,
      stabilityCount: stabilityCount ?? this.stabilityCount,
      radiusPx: radiusPx ?? this.radiusPx,
      accuracy: accuracy ?? this.accuracy,
      valueOnly: valueOnly ?? this.valueOnly,
      lowLightWarning: lowLightWarning ?? this.lowLightWarning,
      currentSample: currentSample ?? this.currentSample,
      lastCommittedSample: lastCommittedSample ?? this.lastCommittedSample,
      framesAveraged: framesAveraged ?? this.framesAveraged,
      torchOn: torchOn ?? this.torchOn,
      torchWarning:
          clearTorchWarning ? null : (torchWarning ?? this.torchWarning),
      markedPoints: markedPoints ?? this.markedPoints,
      markedReadings: markedReadings ?? this.markedReadings,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CaptureState &&
      other.lockState == lockState &&
      other.stabilityCount == stabilityCount &&
      other.radiusPx == radiusPx &&
      other.accuracy == accuracy &&
      other.valueOnly == valueOnly &&
      other.lowLightWarning == lowLightWarning &&
      other.currentSample == currentSample &&
      other.lastCommittedSample == lastCommittedSample &&
      other.framesAveraged == framesAveraged &&
      other.torchOn == torchOn &&
      other.torchWarning == torchWarning &&
      listEquals(other.markedPoints, markedPoints) &&
      listEquals(other.markedReadings, markedReadings);

  @override
  int get hashCode => Object.hash(
        lockState,
        stabilityCount,
        radiusPx,
        accuracy,
        valueOnly,
        lowLightWarning,
        currentSample,
        lastCommittedSample,
        framesAveraged,
        torchOn,
        torchWarning,
        Object.hashAll(markedPoints),
        Object.hashAll(markedReadings),
      );

  @override
  String toString() =>
      'CaptureState(${lockState.name}, $stabilityText, ${radiusPx}px, '
      '${accuracy.label}${valueOnly ? ', value-only' : ''}'
      '${lowLightWarning ? ', low-light' : ''})';
}
