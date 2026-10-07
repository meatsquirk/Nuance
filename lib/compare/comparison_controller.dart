import 'package:flutter/widgets.dart';

import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import '../app/router.dart';
import '../domain/sample.dart';
import 'comparison_state.dart';
import 'difference.dart';
import 'sample_source.dart';

/// Drives the comparison: holds the chosen slots, derives the relational
/// [ComparisonState] from them, and offers the actions the Comparison screen
/// takes on it.
///
/// The screen is a pure view over this controller (read through
/// `ComparisonReadEndpoint`). The derived reading wires the two seams this
/// feature adds — DIFF's [compare] (overall ΔE00 + the LCh decomposition) and
/// CVD's [ConfusionCheck.confusable] (the confusion flag) — so that whenever
/// both slots are set the state carries a real reading; while the shells still
/// return placeholders, that reading is the placeholder.
///
/// A [ChangeNotifier] so the screen and the acceptance read endpoint rebuild as
/// the state moves. COMPARE-2 establishes the derivation and the catalogue seam;
/// the painter *actions* ([selectA] / [selectB] / [swap] / [openReadout]) are
/// declared here and throw until their behaviour phases (COMPARE-3 / COMPARE-5 /
/// COMPARE-6) fill them, exactly as bs-02's capture controller deferred its
/// actions.
class ComparisonController extends ChangeNotifier {
  /// Creates a controller over [sampleSource]'s catalogue, deriving the initial
  /// state from [initialA] / [initialB] (both null for the picker-driven entry;
  /// one set for the Readout → compare handoff, which carries a sample into a
  /// slot — AC-9/AC-10 of bs-01).
  ComparisonController({
    required this.sampleSource,
    required this.confusionCheck,
    required this.profile,
    Sample? initialA,
    Sample? initialB,
  }) : _state = _derive(initialA, initialB, confusionCheck, profile);

  /// The saved-sample catalogue the picker lists (D-7).
  final SampleSource sampleSource;

  /// The detector deciding whether a pair is confusable for [profile] (AC-7/8).
  final ConfusionCheck confusionCheck;

  /// The painter's colour-vision profile the confusion flag is judged against.
  final CvdProfile profile;

  // Final in this shell — no action mutates it yet; COMPARE-3 makes it mutable
  // when it adds the selection/emit path.
  final ComparisonState _state;

  /// The current observable comparison state.
  ComparisonState get state => _state;

  /// The saved samples the picker offers (empty in the bs-03 shell catalogue;
  /// COMPARE-3 seeds it).
  List<Sample> get savedSamples => sampleSource.savedSamples();

  /// Derives the comparison state for slots [a] / [b].
  ///
  /// The single wiring seam for the two feature services: when both slots are
  /// set it reads the pair through DIFF's [compare] and CVD's
  /// [ConfusionCheck.confusable]; when either is empty there is no reading
  /// ([ComparisonState.comparison] null, [ComparisonState.confusable] false), so
  /// no relational statement is shown (AC-12).
  static ComparisonState _derive(
    Sample? a,
    Sample? b,
    ConfusionCheck confusionCheck,
    CvdProfile profile,
  ) {
    if (a == null || b == null) {
      return ComparisonState(slotA: a, slotB: b);
    }
    return ComparisonState(
      slotA: a,
      slotB: b,
      comparison: compare(a, b),
      confusable:
          confusionCheck.confusable(a.coordinates, b.coordinates, profile),
    );
  }

  /// Chooses [sample] into slot A and re-derives the reading (AC-1). Behaviour
  /// lands in COMPARE-3 (picker + slot render + catalogue).
  void selectA(Sample sample) =>
      throw UnimplementedError('selectA: behaviour lands in COMPARE-3');

  /// Chooses [sample] into slot B and re-derives the reading (AC-2). Behaviour
  /// lands in COMPARE-3.
  void selectB(Sample sample) =>
      throw UnimplementedError('selectB: behaviour lands in COMPARE-3');

  /// Exchanges slots A and B so the statement re-expresses new-A → new-B
  /// (AC-3). Behaviour lands in COMPARE-5.
  void swap() => throw UnimplementedError('swap: behaviour lands in COMPARE-5');

  /// A route to the full Readout for the sample in [slot] (AC-10, AC-11).
  /// Behaviour lands in COMPARE-6 (wires `AppRouter.toReadout`).
  Route<void> openReadout(ComparisonSlot slot) =>
      throw UnimplementedError('openReadout: behaviour lands in COMPARE-6');
}
