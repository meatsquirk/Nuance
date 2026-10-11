import '../../color_science/conversions.dart' show labToCielch;
import '../../compare/difference.dart' show deltaE00;
import '../../domain/sample.dart';
import '../../recipes/engine/mixing_engine.dart' show Recipe;
import '../../recipes/palette.dart';
import 'correction_engine.dart';
import 'correction_words.dart';

/// The v1 [CorrectionEngine].
///
/// [difference] reports the real perceptual distance — the shipped CIEDE2000
/// (bs-03's `deltaE00`) between the swatch and the target — with its plain
/// verdict and value-leading decomposition (CORRECT-2, AC-2/AC-3); the
/// within-tolerance flag stays off until CORRECT-4 wires the tolerance
/// short-circuit, and [correct] is still an empty [Correction]. The rest of the
/// behaviour layers on behind this same interface: the concrete
/// paint-and-amount search (through bs-04's `MixingEngine.forward`) in CORRECT-3
/// and the within-tolerance short-circuit in CORRECT-4. Wired in as the default
/// `AppDependencies.correctionEngine`, symmetric to the `SubtractiveMixingEngine`.
///
/// A stateless, `const` engine.
class SubtractiveCorrectionEngine implements CorrectionEngine {
  /// Creates the (stateless, `const`) engine.
  const SubtractiveCorrectionEngine();

  @override
  Difference difference(Sample mixedSwatch, Sample target) {
    final mixed = mixedSwatch.coordinates;
    final tgt = target.coordinates;
    // The distance is the shipped CIEDE2000 (bs-03) — read through this seam
    // rather than computed here (D-2). Hue angles come through the shared
    // `labToCielch` derivation (D-5). The within-tolerance short-circuit lands
    // in CORRECT-4.
    final distance = deltaE00(mixed, tgt);
    return Difference(
      deltaE00: distance,
      verdict: verdictFor(distance),
      valueReading: valueReadingFor(tgt.lightness, mixed.lightness),
      hueReading: hueReadingFor(labToCielch(mixed).hue, labToCielch(tgt).hue),
      withinTolerance: false,
    );
  }

  @override
  Correction correct(
    Sample mixedSwatch,
    Sample target,
    Recipe currentMix,
    PaintPalette palette,
  ) =>
      const Correction();
}
