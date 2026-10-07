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
      other.framesAveraged == framesAveraged;

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
      );

  @override
  String toString() =>
      'CaptureState(${lockState.name}, $stabilityText, ${radiusPx}px, '
      '${accuracy.label}${valueOnly ? ', value-only' : ''}'
      '${lowLightWarning ? ', low-light' : ''})';
}
