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
    this.router = const AppRouter(),
    Sample? initialA,
    Sample? initialB,
  }) : _state = _derive(initialA, initialB, confusionCheck, profile);

  /// The saved-sample catalogue the picker lists (D-7).
  final SampleSource sampleSource;

  /// Typed navigation used by [openReadout] to push the full Readout for a slot
  /// (AC-10, AC-11). The production assembly injects `AppDependencies.router`.
  final AppRouter router;

  /// The detector deciding whether a pair is confusable for [profile] (AC-7/8).
  final ConfusionCheck confusionCheck;

  /// The painter's colour-vision profile the confusion flag is judged against.
  final CvdProfile profile;

  // Mutable from COMPARE-3: the selection actions move the slots and re-derive
  // the reading, emitting the new snapshot to the screen and read endpoint.
  ComparisonState _state;

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

  /// Chooses [sample] into slot A and re-derives the reading (AC-1), leaving
  /// slot B as it was. Re-deriving with one slot still empty yields no reading
  /// (so the AC-12 invite stays); with both set it reads the pair through DIFF
  /// and CVD. Notifies the screen and the read endpoint.
  void selectA(Sample sample) =>
      _emit(_derive(sample, _state.slotB, confusionCheck, profile));

  /// Chooses [sample] into slot B and re-derives the reading (AC-2), leaving
  /// slot A as it was. See [selectA].
  void selectB(Sample sample) =>
      _emit(_derive(_state.slotA, sample, confusionCheck, profile));

  /// Replaces the observable [state] with [next] and notifies listeners.
  void _emit(ComparisonState next) {
    _state = next;
    notifyListeners();
  }

  /// Exchanges slots A and B so the derived statement re-expresses new-A →
  /// new-B (AC-3): re-deriving over the swapped slots recomputes the pair
  /// through DIFF and CVD, so the direction flips (e.g. "Lighter by 12" →
  /// "Darker by 12"). Routes through the one [_emit] mutation path, notifying
  /// the screen and the read endpoint. With a slot empty there is still no
  /// reading, so the swap simply moves the lone sample to the other slot.
  void swap() =>
      _emit(_derive(_state.slotB, _state.slotA, confusionCheck, profile));

  /// The sample currently in [slot], or null when that slot is empty.
  Sample? sampleIn(ComparisonSlot slot) =>
      slot == ComparisonSlot.a ? _state.slotA : _state.slotB;

  /// Whether [slot] holds a sample, so the Open-readout control for it is
  /// enabled only when there is a sample to open (AC-10, AC-11).
  bool slotFilled(ComparisonSlot slot) => sampleIn(slot) != null;

  /// A route to the full Readout for the sample in [slot] (AC-10, AC-11), built
  /// through [router]. Called only when [slotFilled] for [slot] — the control is
  /// disabled otherwise.
  Route<void> openReadout(ComparisonSlot slot) =>
      router.toReadout(sampleIn(slot)!);
}
