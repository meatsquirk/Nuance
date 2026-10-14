import 'package:flutter/foundation.dart';

/// The record of the Phase-0.5 held-out validation that gates whether the seed
/// dataset is allowed to ship (bs-13 AC-5, AC-6).
///
/// A held-out set of recipes (count in [50, 100], AC-5) is mixed and measured,
/// and their ΔE00 against the predicted mix is recorded as
/// [deltaE00Distribution]. [hybridMeanDeltaE00] is the mean error of the shipped
/// hybrid (LLM candidates + physics solver), [llmAloneMeanDeltaE00] the mean of
/// the LLM's own guesses, and [usableThreshold] the ΔE00 the distribution must
/// clear. The [shippable] decision (AC-6) is **both** that the distribution
/// clears the threshold **and** that the hybrid beats the LLM alone.
///
/// This is the **shell shape only** (SEED-2): the fields and [shippable] exist
/// so the dataset surface and the acceptance read endpoint can observe a
/// manifest, but the ship logic is deferred to SEED-5 — [shippable] is a
/// behaviour-neutral placeholder (`false`) until then. Value-equal and
/// `const`-constructible so a dataset compares by content.
@immutable
class ValidationManifest {
  /// Creates a manifest over a recorded held-out validation run.
  const ValidationManifest({
    required this.heldOutCount,
    required this.deltaE00Distribution,
    required this.hybridMeanDeltaE00,
    required this.llmAloneMeanDeltaE00,
    required this.usableThreshold,
  });

  /// The empty placeholder manifest an unshipped (shell) dataset carries.
  ///
  /// No held-out run has been recorded yet, so every statistic is zero and the
  /// distribution is empty; [shippable] is `false`.
  const ValidationManifest.empty()
      : heldOutCount = 0,
        deltaE00Distribution = const [],
        hybridMeanDeltaE00 = 0,
        llmAloneMeanDeltaE00 = 0,
        usableThreshold = 0;

  /// How many held-out recipes were mixed and measured (AC-5 requires 50..100).
  final int heldOutCount;

  /// The recorded per-recipe ΔE00 of prediction against the measured mix (AC-5).
  final List<double> deltaE00Distribution;

  /// The mean ΔE00 of the shipped hybrid (LLM candidates + physics solver).
  final double hybridMeanDeltaE00;

  /// The mean ΔE00 of the LLM's guesses alone, the hybrid must beat (AC-6).
  final double llmAloneMeanDeltaE00;

  /// The ΔE00 the distribution must clear for the seed to be usable (AC-6).
  final double usableThreshold;

  /// Whether the seed may ship on this evidence (AC-6).
  ///
  /// Shell placeholder: the real decision (distribution clears [usableThreshold]
  /// **and** [hybridMeanDeltaE00] < [llmAloneMeanDeltaE00]) lands in SEED-5, so
  /// the shell manifest is never shippable.
  bool get shippable => false;

  @override
  bool operator ==(Object other) =>
      other is ValidationManifest &&
      other.heldOutCount == heldOutCount &&
      listEquals(other.deltaE00Distribution, deltaE00Distribution) &&
      other.hybridMeanDeltaE00 == hybridMeanDeltaE00 &&
      other.llmAloneMeanDeltaE00 == llmAloneMeanDeltaE00 &&
      other.usableThreshold == usableThreshold;

  @override
  int get hashCode => Object.hash(
        heldOutCount,
        Object.hashAll(deltaE00Distribution),
        hybridMeanDeltaE00,
        llmAloneMeanDeltaE00,
        usableThreshold,
      );

  @override
  String toString() => 'ValidationManifest(heldOut $heldOutCount, '
      'hybrid $hybridMeanDeltaE00, llm $llmAloneMeanDeltaE00, '
      'threshold $usableThreshold, shippable $shippable)';
}
