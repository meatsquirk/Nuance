import '../domain/provenance.dart';
import '../domain/sample.dart';
import '../recipes/engine/mixing_engine.dart' show Recipe;
import 'engine/correction_engine.dart';

/// The observable state of the Correction screen: the mixing [target], the
/// [currentMix] the painter mixed toward it, the photographed [mixedSwatch] and
/// the [difference] / [correction] read from it, and the [savedProvenance] once
/// a satisfactory mix is confirmed.
///
/// A plain immutable snapshot held by the `CorrectionController` and surfaced to
/// the Correction screen and the acceptance read endpoint, mirroring bs-04's
/// `RecipeState`. Everything past [target] / [currentMix] is empty until the
/// painter checks the mix: [mixedSwatch] / [difference] / [correction] fill when
/// a swatch is photographed and compared (LOOP-3, CORRECT-2/3/4), and
/// [savedProvenance] fills when the mix is saved as confirmed (LOOP-6). The shape
/// is fixed here (LOOP-2); the behaviour phases move it.
class CorrectionState {
  /// Creates a snapshot for [target] / [currentMix].
  ///
  /// The photographed swatch, its difference and correction, and the saved
  /// provenance all default to the unchecked, unsaved start.
  const CorrectionState({
    required this.target,
    required this.currentMix,
    this.mixedSwatch,
    this.difference,
    this.correction,
    this.savedProvenance,
  });

  /// The colour the painter is mixing toward (AC-1); the swatch is compared to
  /// it and the confirmed value is promoted against it.
  final Sample target;

  /// The recipe the painter mixed toward [target] — the starting point the
  /// correction adds to (AC-4/AC-5).
  final Recipe currentMix;

  /// The photographed swatch read back as a measured sample (AC-1), or null
  /// until the painter checks the mix.
  final Sample? mixedSwatch;

  /// How [mixedSwatch] differs from [target] — distance, verdict and the
  /// value-leading decomposition (AC-2/AC-3) — or null until a check runs.
  final Difference? difference;

  /// The paints to add to close the gap (AC-4/AC-5), or null until a check runs.
  /// An empty [Correction] is the within-tolerance case (AC-6); null is "not
  /// checked yet".
  final Correction? correction;

  /// The provenance the value was promoted to once the mix was saved as
  /// confirmed (AC-9), or null until the painter saves it.
  final Provenance? savedProvenance;

  /// True once the painter has photographed and checked a swatch (drives the
  /// screen's difference / correction rendering vs. its pre-check state).
  bool get hasChecked => mixedSwatch != null;

  @override
  bool operator ==(Object other) =>
      other is CorrectionState &&
      other.target == target &&
      other.currentMix == currentMix &&
      other.mixedSwatch == mixedSwatch &&
      other.difference == difference &&
      other.correction == correction &&
      other.savedProvenance == savedProvenance;

  @override
  int get hashCode => Object.hash(
        target,
        currentMix,
        mixedSwatch,
        difference,
        correction,
        savedProvenance,
      );

  @override
  String toString() => 'CorrectionState(target: ${target.name ?? '(unnamed)'}, '
      '${hasChecked ? 'checked' : 'unchecked'}'
      '${savedProvenance == null ? '' : ', saved ${savedProvenance!.label}'})';
}
