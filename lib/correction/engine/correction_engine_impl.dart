import '../../compare/difference.dart' show deltaE00;
import '../../domain/sample.dart';
import '../../recipes/engine/mixing_engine.dart' show Recipe;
import '../../recipes/palette.dart';
import 'correction_engine.dart';

/// The v1 [CorrectionEngine].
///
/// [difference] reports the real perceptual distance — the shipped CIEDE2000
/// (bs-03's `deltaE00`) between the swatch and the target (LOOP-3, AC-1) — with
/// its verdict and value-leading decomposition still empty and the
/// within-tolerance flag off; [correct] is still an empty [Correction]. The rest
/// of the behaviour layers on behind this same interface: the verdict + value /
/// hue readings in CORRECT-2, the concrete paint-and-amount search (through
/// bs-04's `MixingEngine.forward`) in CORRECT-3, and the within-tolerance
/// short-circuit in CORRECT-4. Wired in as the default
/// `AppDependencies.correctionEngine`, symmetric to the `SubtractiveMixingEngine`.
///
/// A stateless, `const` engine.
class SubtractiveCorrectionEngine implements CorrectionEngine {
  /// Creates the (stateless, `const`) engine.
  const SubtractiveCorrectionEngine();

  @override
  Difference difference(Sample mixedSwatch, Sample target) => Difference(
        // The shipped CIEDE2000 (bs-03) — the controller reads the distance
        // through this seam rather than computing it (D-2). The verdict, the
        // value-leading decomposition and the within-tolerance short-circuit
        // land in CORRECT-2 / CORRECT-4.
        deltaE00: deltaE00(mixedSwatch.coordinates, target.coordinates),
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
