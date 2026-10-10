import 'package:flutter/foundation.dart';

import '../../domain/paint.dart';
import '../../domain/sample.dart';
import '../../recipes/engine/mixing_engine.dart' show Recipe;
import '../../recipes/palette.dart';

/// How a checked mix differs from the target the painter is mixing toward
/// (bs-05 AC-2/AC-3).
///
/// [deltaE00] is the perceptual distance (bs-03's shipped `deltaE00`); [verdict]
/// is bs-05's own plain-language band for it (D-4, owned in
/// `correction_words.dart` — not bs-03's or bs-04's bands). The decomposition
/// leads with value: [valueReading] ("too dark by 6") is the **leading** reading
/// (D-5), [hueReading] ("shifted toward green") follows. [withinTolerance] is
/// true once the mix is close enough that no correction is offered (AC-6; the
/// tolerance is G-4(b)).
///
/// Value-equal and `const`-constructible. The real readings land in CORRECT-2;
/// the stub engine returns an inert instance.
class Difference {
  /// Creates a difference reading. All fields are required so a reading is never
  /// silently partial; the stub passes explicit inert values.
  const Difference({
    required this.deltaE00,
    required this.verdict,
    required this.valueReading,
    required this.hueReading,
    required this.withinTolerance,
  });

  /// The perceptual distance between the mixed swatch and the target (D-2).
  final double deltaE00;

  /// The plain-language band for [deltaE00] (D-4), e.g. "noticeably off".
  final String verdict;

  /// The leading value reading (D-5), e.g. "too dark by 6".
  final String valueReading;

  /// The hue reading (D-5), e.g. "shifted toward green".
  final String hueReading;

  /// True when the mix is within tolerance, so no correction is offered (AC-6).
  final bool withinTolerance;

  @override
  bool operator ==(Object other) =>
      other is Difference &&
      other.deltaE00 == deltaE00 &&
      other.verdict == verdict &&
      other.valueReading == valueReading &&
      other.hueReading == hueReading &&
      other.withinTolerance == withinTolerance;

  @override
  int get hashCode =>
      Object.hash(deltaE00, verdict, valueReading, hueReading, withinTolerance);

  @override
  String toString() => 'Difference(ΔE00 $deltaE00, $verdict, '
      '$valueReading / $hueReading'
      '${withinTolerance ? ', within tolerance' : ''})';
}

/// One paint the correction tells the painter to add, and how much (bs-05
/// AC-4/AC-5).
///
/// [parts] is the amount to add, in the same parts-by-volume units a [Recipe]
/// uses. A share below the trace threshold (G-4(c)) is flagged [isTrace] and
/// renders as "a touch of" plus a [techniqueNote], reusing bs-04's trace idiom
/// (D-7) rather than reporting an unmeasurable fraction.
///
/// Value-equal and `const`-constructible.
class CorrectionAddition {
  /// Creates an addition: [parts] of [paint], optionally flagged a trace.
  const CorrectionAddition({
    required this.paint,
    required this.parts,
    this.isTrace = false,
    this.techniqueNote,
  });

  /// The paint to add.
  final Paint paint;

  /// How much to add, in parts by volume.
  final double parts;

  /// True when the amount is a trace — rendered as "a touch of" (AC-5). Defaults
  /// to false; CORRECT-3 sets it.
  final bool isTrace;

  /// A static technique note shown with a trace addition (D-7), or null.
  final String? techniqueNote;

  @override
  bool operator ==(Object other) =>
      other is CorrectionAddition &&
      other.paint == paint &&
      other.parts == parts &&
      other.isTrace == isTrace &&
      other.techniqueNote == techniqueNote;

  @override
  int get hashCode => Object.hash(paint, parts, isTrace, techniqueNote);

  @override
  String toString() =>
      'CorrectionAddition(${paint.name} $parts${isTrace ? ', trace' : ''})';
}

/// The concrete correction for a checked mix: the paint(s) to add to move it
/// toward the target (bs-05 AC-4/AC-5).
///
/// [isEmpty] when there is nothing to add — the within-tolerance case (AC-6),
/// where the screen shows no correction.
///
/// Value-equal and `const`-constructible. The real search lands in CORRECT-3/4;
/// the stub engine returns an empty instance.
class Correction {
  /// Creates a correction from its [additions] (empty by default — the
  /// within-tolerance / no-correction state).
  const Correction({this.additions = const []});

  /// The paints to add and their amounts, in suggested order.
  final List<CorrectionAddition> additions;

  /// True when there is nothing to add (AC-6).
  bool get isEmpty => additions.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is Correction && listEquals(other.additions, additions);

  @override
  int get hashCode => Object.hashAll(additions);

  @override
  String toString() => 'Correction(${additions.length} additions)';
}

/// The engine that reads a checked mix against its target and tells the painter
/// how to close the gap (SI; bs-05 D-2/D-3, swappable).
///
/// Two seams so the [difference] (AC-2/AC-3) is computable before the [correct]
/// (AC-4/AC-5), and the within-tolerance case (AC-6) can short-circuit
/// [correct]. The v1 engine (CORRECT-2/3/4) delegates its ΔE00 to bs-03's
/// `deltaE00` and scores candidate additions through bs-04's
/// `MixingEngine.forward`, so swapping either never touches the controller or
/// the screen. The stub [SubtractiveCorrectionEngine] implements it inertly for
/// the shell stage.
abstract interface class CorrectionEngine {
  /// How [mixedSwatch] differs from [target]: distance, verdict, and the
  /// value-leading decomposition (AC-2/AC-3).
  Difference difference(Sample mixedSwatch, Sample target);

  /// The paint(s) to add to [currentMix] (drawn from [palette]) to move
  /// [mixedSwatch] toward [target] (AC-4/AC-5).
  ///
  /// Returns an empty [Correction] when the mix is already within tolerance
  /// (AC-6).
  Correction correct(
    Sample mixedSwatch,
    Sample target,
    Recipe currentMix,
    PaintPalette palette,
  );
}
