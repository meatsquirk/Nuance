/// The work-in-progress CVD estimate the self-assessment assembles (bs-07).
///
/// `CvdEstimate` is engine/flow-internal: it carries the [prior], the optional
/// per-tier results, and the assembled [type]/[severity]. It is **not** the
/// stored profile — saving (PROFILE-2) projects the final estimate onto the
/// bs-03 `CvdProfile`, which stays fixed (D-1). Produced by `assemble` on
/// `AssessmentEngine` (`assessment_engine.dart`).
library;

import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/onboarding/engine/tier_results.dart';

/// The assembled estimate: a [type] and [severity] with the tier evidence that
/// produced them.
///
/// [screening] and [threshold] are null until their tiers run; [prior] is
/// always present (at least [StartingPrior.none]); [arrangementPresent] records
/// whether a Tier 3 arrangement contributed. The scale of [severity] is 0..1 to
/// match `CvdProfile.severity`.
class CvdEstimate {
  const CvdEstimate({
    required this.type,
    required this.severity,
    required this.prior,
    this.screening,
    this.threshold,
    this.arrangementPresent = false,
  });

  /// The estimated dichromacy class.
  final CvdType type;

  /// The estimated severity, 0 (none) to 1 (full dichromat).
  final double severity;

  /// The prior formed at intake (Tier 1).
  final StartingPrior prior;

  /// The screening outcome (Tier 2), or null if not run.
  final ScreeningResult? screening;

  /// The threshold outcome (Tier 4), or null if not run.
  final ThresholdResult? threshold;

  /// Whether a Tier 3 arrangement contributed (false when skipped, AC-8).
  final bool arrangementPresent;

  @override
  bool operator ==(Object other) =>
      other is CvdEstimate &&
      other.type == type &&
      other.severity == severity &&
      other.prior == prior &&
      other.screening == screening &&
      other.threshold == threshold &&
      other.arrangementPresent == arrangementPresent;

  @override
  int get hashCode => Object.hash(
      type, severity, prior, screening, threshold, arrangementPresent);

  @override
  String toString() =>
      'CvdEstimate(${type.name}, severity: $severity, prior: $prior, '
      'screening: $screening, threshold: $threshold, '
      'arrangementPresent: $arrangementPresent)';
}
