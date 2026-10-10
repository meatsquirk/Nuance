import '../../domain/sample.dart';
import '../../recipes/engine/mixing_engine.dart' show Recipe;
import '../../recipes/palette.dart';
import 'correction_engine.dart';

/// The v1 [CorrectionEngine] — a **stub** for the shell stage (CORRECT-1).
///
/// Returns an inert [Difference] (zero distance, empty readings, not within
/// tolerance) and an empty [Correction]: no real math yet. The real behaviour
/// layers on behind this same interface — the ΔE00 + verdict + value-leading
/// decomposition in CORRECT-2, the concrete paint-and-amount search (through
/// bs-04's `MixingEngine.forward`) in CORRECT-3, and the within-tolerance
/// short-circuit in CORRECT-4. Wired in as the default
/// `AppDependencies.correctionEngine`, symmetric to the `SubtractiveMixingEngine`.
///
/// A stateless, `const` engine.
class SubtractiveCorrectionEngine implements CorrectionEngine {
  /// Creates the (stateless, `const`) stub engine.
  const SubtractiveCorrectionEngine();

  @override
  Difference difference(Sample mixedSwatch, Sample target) => const Difference(
        deltaE00: 0,
        verdict: '',
        valueReading: '',
        hueReading: '',
        withinTolerance: false,
      );

  @override
  Correction correct(
    Sample mixedSwatch,
    Sample target,
    Recipe currentMix,
    PaintPalette palette,
  ) =>
      const Correction();
}
