import 'package:paint_color_assistant/onboarding/engine/cvd_estimate.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';

/// The observable state of the self-assessment onboarding flow.
///
/// A plain immutable snapshot held by the `OnboardingController` and surfaced to
/// the onboarding screens and the acceptance read endpoint. It carries the
/// cross-tier progress ([stepIndex]), the Tier 0 lighting confirmations and the
/// [testingStarted] gate, the Tier 1 [prior], the Tier 2 [screening] result, the
/// Tier 3 arrangement ([arrangementPool] / [arrangedCaps] / [arrangementSkipped]),
/// the Tier 4 [threshold] result, the assembled [estimate], the subjective
/// [calibratedSeverity], whether the result [caveatShown] is displayed, and
/// whether the profile is [saved].
///
/// FLOW-1 (shell) fixes this shape with its empty defaults; the behaviour phases
/// move the fields — step advance (FLOW-2), the lighting gate (FLOW-3), the
/// arrangement (FLOW-4), the engine-scored tiers (ENGINE-3..6), estimate
/// assembly (FLOW-5), the result adjustments (FLOW-6/7/8) and the save
/// (PROFILE-2). Severity is 0..1 throughout to match `CvdProfile.severity`.
class OnboardingState {
  /// Creates a snapshot; every field defaults to the pre-assessment empty state.
  const OnboardingState({
    this.stepIndex = 0,
    this.brightnessConfirmed = false,
    this.nightLightConfirmed = false,
    this.daylightConfirmed = false,
    this.testingStarted = false,
    this.prior = StartingPrior.none,
    this.screening,
    this.arrangementPool = const [],
    this.arrangedCaps = const [],
    this.arrangementSkipped = false,
    this.threshold,
    this.estimate,
    this.calibratedSeverity,
    this.caveatShown = false,
    this.saved = false,
  });

  /// The current top-level step (index into the controller's steps) — AC-14.
  final int stepIndex;

  /// Whether the Tier 0 screen-brightness check is confirmed (AC-2).
  final bool brightnessConfirmed;

  /// Whether the Tier 0 night-light-off check is confirmed (AC-2).
  final bool nightLightConfirmed;

  /// Whether the Tier 0 daylight check is confirmed (AC-2).
  final bool daylightConfirmed;

  /// Whether testing has begun — false until the lighting checks gate opens
  /// (AC-2). The measurement tiers run only once this is true.
  final bool testingStarted;

  /// The Tier 1 starting prior formed at intake (AC-3/AC-4).
  final StartingPrior prior;

  /// The Tier 2 screening result (presence + direction), or null until scored
  /// (AC-5).
  final ScreeningResult? screening;

  /// The Tier 3 caps not yet placed (AC-6/AC-7). Cap ids; FLOW-4 gives them hue.
  final List<int> arrangementPool;

  /// The Tier 3 caps placed in order so far (AC-6/AC-7).
  final List<int> arrangedCaps;

  /// Whether the painter skipped the arrangement, so it contributes no result
  /// (AC-8).
  final bool arrangementSkipped;

  /// The Tier 4 threshold result (severity on the confusion line), or null until
  /// scored (AC-9).
  final ThresholdResult? threshold;

  /// The assembled estimate shown on the result step, or null until FLOW-5
  /// assembles it (AC-1/10/11/12).
  final CvdEstimate? estimate;

  /// The severity the painter kept via the self-calibration slider, or null
  /// until confirmed (AC-12, FLOW-7).
  final double? calibratedSeverity;

  /// Whether the result step shows the approximate-estimate caveat (AC-1,
  /// FLOW-8).
  final bool caveatShown;

  /// Whether the profile has been written to the store (AC-13, PROFILE-2).
  final bool saved;

  /// Whether all three Tier 0 lighting checks are confirmed — the condition the
  /// FLOW-3 continue gate opens on (AC-2).
  bool get lightingConfirmed =>
      brightnessConfirmed && nightLightConfirmed && daylightConfirmed;

  @override
  bool operator ==(Object other) =>
      other is OnboardingState &&
      other.stepIndex == stepIndex &&
      other.brightnessConfirmed == brightnessConfirmed &&
      other.nightLightConfirmed == nightLightConfirmed &&
      other.daylightConfirmed == daylightConfirmed &&
      other.testingStarted == testingStarted &&
      other.prior == prior &&
      other.screening == screening &&
      _listEquals(other.arrangementPool, arrangementPool) &&
      _listEquals(other.arrangedCaps, arrangedCaps) &&
      other.arrangementSkipped == arrangementSkipped &&
      other.threshold == threshold &&
      other.estimate == estimate &&
      other.calibratedSeverity == calibratedSeverity &&
      other.caveatShown == caveatShown &&
      other.saved == saved;

  @override
  int get hashCode => Object.hash(
        stepIndex,
        brightnessConfirmed,
        nightLightConfirmed,
        daylightConfirmed,
        testingStarted,
        prior,
        screening,
        Object.hashAll(arrangementPool),
        Object.hashAll(arrangedCaps),
        arrangementSkipped,
        threshold,
        estimate,
        calibratedSeverity,
        caveatShown,
        saved,
      );

  @override
  String toString() =>
      'OnboardingState(step: $stepIndex, lighting: $brightnessConfirmed/'
      '$nightLightConfirmed/$daylightConfirmed, testingStarted: '
      '$testingStarted, prior: $prior, screening: $screening, pool: '
      '${arrangementPool.length}, arranged: ${arrangedCaps.length}, '
      'skipped: $arrangementSkipped, threshold: $threshold, estimate: '
      '$estimate, calibratedSeverity: $calibratedSeverity, caveatShown: '
      '$caveatShown, saved: $saved)';
}

/// Ordered element-wise equality for the arrangement cap lists.
bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
