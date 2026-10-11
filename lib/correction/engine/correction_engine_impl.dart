import '../../color_science/conversions.dart' show labToCielch;
import '../../compare/difference.dart' show deltaE00;
import '../../domain/color_coordinates.dart';
import '../../domain/paint.dart';
import '../../domain/sample.dart';
import '../../recipes/engine/mixing_engine.dart' show MixingEngine, Recipe;
import '../../recipes/engine/subtractive_engine.dart' show SubtractiveMixingEngine;
import '../../recipes/palette.dart';
import 'correction_engine.dart';
import 'correction_words.dart';

/// The v1 [CorrectionEngine].
///
/// [difference] reports the real perceptual distance — the shipped CIEDE2000
/// (bs-03's `deltaE00`) between the swatch and the target — with its plain
/// verdict and value-leading decomposition (CORRECT-2, AC-2/AC-3); the
/// within-tolerance flag stays off until CORRECT-4 wires the tolerance
/// short-circuit. [correct] searches the owned palette for the one paint to add
/// that most closes the gap, leading with value (CORRECT-3, AC-4/AC-5): it rides
/// bs-04's [MixingEngine.forward] model to score candidate additions, so the
/// suggestion is a real physical ratio, never an invented number (D-3). Wired in
/// as the default `AppDependencies.correctionEngine`, symmetric to the
/// `SubtractiveMixingEngine`.
///
/// A stateless, `const` engine over an injected [mixingEngine] (the bs-04 forward
/// model, swappable for the measured engine later).
class SubtractiveCorrectionEngine implements CorrectionEngine {
  /// Creates the (stateless, `const`) engine over [mixingEngine] — the bs-04
  /// forward model the correction search scores candidate additions through
  /// (defaults to the shipped `const SubtractiveMixingEngine`).
  const SubtractiveCorrectionEngine({
    this.mixingEngine = const SubtractiveMixingEngine(),
  });

  /// The forward model candidate additions are scored through (D-3); the engine
  /// never invents a colour, it predicts one.
  final MixingEngine mixingEngine;

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
  ) {
    if (palette.paints.isEmpty) return const Correction();

    final mixed = mixedSwatch.coordinates;
    final tgt = target.coordinates;
    final distance = deltaE00(mixed, tgt);

    // The current mix as parts by volume — the starting point the search
    // perturbs (D-3). The forward model is scale-invariant, so these shares
    // (summing to 1) stand in for any absolute volume.
    final baseParts = <Paint, double>{
      for (final c in currentMix.components) c.paint: c.partsFraction,
    };

    // Value-leading selection (D-5): a CVD painter reads value first, so the
    // single correction addresses the value gap first — lighten a too-dark mix,
    // darken a too-light one — and only turns to hue/chroma once value is
    // matched. The value gap is the rounded L* difference, matching the
    // value-leading reading the difference body shows.
    final valueGap = (tgt.lightness - mixed.lightness).round();
    final Paint? chosen;
    if (valueGap > 0) {
      chosen = _lightest(palette.paints); // too dark → lift the value
    } else if (valueGap < 0) {
      chosen = _darkest(palette.paints); // too light → lower the value
    } else {
      chosen = _bestChromaReducer(baseParts, mixed, tgt, palette.paints);
    }
    if (chosen == null) return const Correction();

    // The amount of the chosen paint that most reduces the predicted distance:
    // add it to the mix, predict the new colour through the forward model, apply
    // that predicted change to the *measured* swatch (so the model's error on
    // this mix cancels), and keep the amount with the smallest distance.
    final step = _closingStep(baseParts, chosen, mixed, tgt, distance);
    if (step <= 0) return const Correction();

    // How far beyond tolerance the mix sits scales the correction from a gentle
    // touch (just over tolerance — add a little and re-photograph, the loop) to
    // a full measured part (far off). A mix at or within tolerance needs no
    // correction (ramp 0; CORRECT-4 makes that an explicit "very close").
    final ramp = ((distance - _toleranceDeltaE00) /
            (_fullCorrectionDeltaE00 - _toleranceDeltaE00))
        .clamp(0.0, 1.0);
    final amount = step * ramp;
    if (amount <= 0) return const Correction();

    // An amount below the trace threshold (G-4(c): 2% by volume, reusing bs-04's
    // single "a touch of" idiom, D-7) is a trace: "a touch of" plus a static
    // technique note, not an unmeasurable measured part.
    final isTrace = amount < _traceThreshold;
    return Correction(additions: [
      CorrectionAddition(
        paint: chosen,
        parts: amount,
        isTrace: isTrace,
        techniqueNote: isTrace ? _traceTechniqueNote : null,
      ),
    ]);
  }

  /// The palette's lightest paint by masstone L* — the one that lifts a too-dark
  /// mix's value most (AC-4).
  Paint _lightest(List<Paint> paints) => paints
      .reduce((a, b) => b.masstone.lightness > a.masstone.lightness ? b : a);

  /// The palette's darkest paint by masstone L* — the one that lowers a too-light
  /// mix's value most.
  Paint _darkest(List<Paint> paints) => paints
      .reduce((a, b) => b.masstone.lightness < a.masstone.lightness ? b : a);

  /// Once value is matched, the paint whose best addition most reduces the
  /// distance (a hue/chroma correction) — or null if none improves on the mix.
  Paint? _bestChromaReducer(
    Map<Paint, double> baseParts,
    ColorCoordinates mixed,
    ColorCoordinates tgt,
    List<Paint> paints,
  ) {
    Paint? best;
    var bestDistance = deltaE00(mixed, tgt);
    for (final paint in paints) {
      final step = _closingStep(baseParts, paint, mixed, tgt, bestDistance);
      if (step <= 0) continue;
      final distance = _distanceAfter(baseParts, paint, step, mixed, tgt);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = paint;
      }
    }
    return best;
  }

  /// The amount of [paint] to add to [baseParts] that most reduces the predicted
  /// distance to [tgt], or 0 if no positive amount improves on [baseline].
  ///
  /// A coarse scan over the plausible range; the forward model's response to a
  /// single added paint is smooth, so a fine grid is unnecessary and the
  /// illustrative amount (G-4(a)) only needs to land in the right band.
  double _closingStep(
    Map<Paint, double> baseParts,
    Paint paint,
    ColorCoordinates mixed,
    ColorCoordinates tgt,
    double baseline,
  ) {
    var bestAmount = 0.0;
    var bestDistance = baseline;
    for (var amount = _searchStep;
        amount <= _searchMax + _searchStep / 2;
        amount += _searchStep) {
      final distance = _distanceAfter(baseParts, paint, amount, mixed, tgt);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestAmount = amount;
      }
    }
    return bestAmount;
  }

  /// The predicted distance to [tgt] after adding [amount] of [paint] to
  /// [baseParts]: the forward model's predicted colour change for the addition,
  /// applied to the *measured* [mixed] swatch so the model's error on this mix
  /// cancels (the physical effect of the addition, not the model's absolute
  /// prediction).
  double _distanceAfter(
    Map<Paint, double> baseParts,
    Paint paint,
    double amount,
    ColorCoordinates mixed,
    ColorCoordinates tgt,
  ) {
    final basePrediction = mixingEngine.forward(baseParts);
    final adjusted = Map<Paint, double>.from(baseParts);
    adjusted[paint] = (adjusted[paint] ?? 0) + amount;
    final adjustedPrediction = mixingEngine.forward(adjusted);
    final corrected = ColorCoordinates(
      lightness: mixed.lightness +
          adjustedPrediction.lightness -
          basePrediction.lightness,
      a: mixed.a + adjustedPrediction.a - basePrediction.a,
      b: mixed.b + adjustedPrediction.b - basePrediction.b,
    );
    return deltaE00(corrected, tgt);
  }

  /// Volume fraction below which a correction addition is a trace — "a touch of"
  /// (G-4(c): 2% by volume; D-7, the same idiom bs-04's recipes use).
  static const double _traceThreshold = 0.02;

  /// The distance at or below which no correction is offered (D-6 / G-4(b); the
  /// ramp anchor). CORRECT-4 wires the matching "very close" verdict and the
  /// within-tolerance flag on this same value.
  static const double _toleranceDeltaE00 = 2.0;

  /// The distance at or beyond which the correction is at full strength (a
  /// measured part). Between tolerance and here it ramps from a touch to a part:
  /// a mix only just beyond tolerance is corrected gently and re-photographed
  /// (the loop), not over-corrected in one step.
  static const double _fullCorrectionDeltaE00 = 10.0;

  /// The search grid for the closing amount (parts by volume). Coarse by design
  /// — the amount is illustrative (G-4(a)); the direction and the trace/measured
  /// band are what the ACs assert.
  static const double _searchStep = 0.005;

  /// The largest single addition the search considers (parts by volume): adding
  /// more than this much of one paint is no longer a correction to the mix.
  static const double _searchMax = 1.5;

  /// The static technique note shown with a trace addition (D-7) — the same
  /// guidance bs-04's recipes give for an unmeasurably small share.
  static const String _traceTechniqueNote =
      'Measuring so little by volume is not practical — add a little at a time '
      'and mix fully before judging the colour.';
}
