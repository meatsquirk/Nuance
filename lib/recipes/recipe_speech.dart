import 'dart:math' as math;

import '../domain/sample.dart';
import 'engine/mixing_engine.dart';

/// Builds the spoken utterances for the Recipes screen (bs-04 AC-11, AC-12).
///
/// Two pure builders the `RecipeController` speaks through its injected
/// [Speech] seam — the spoken counterparts of what the target region and the
/// recipe cards already show, so the heard recipe never drifts from the seen
/// one. Kept pure (a function of the [Sample] / [Recipe] alone) like bs-03's
/// `comparisonSpeech`, and deriving L, C and h straight from canonical CIELAB
/// the way `ColorScience.decompose` does, so the builders need no conversion
/// seam of their own.

/// The target spoken as one utterance: its name and its CIELCh L, C and hue
/// (AC-11, wireframe S1.R1.E23).
///
/// The hue angle and chroma are the polar form of the target's canonical
/// CIELAB a\*/b\* (C\* = √(a\*²+b\*²), h = atan2(b\*, a\*)), each rounded to a
/// whole number for speech — the same values the LCh readout shows. An unnamed
/// target is spoken as "(unnamed)", matching the target region's on-screen line.
String targetSpeech(Sample target) {
  final c = target.coordinates;
  final name = target.name ?? '(unnamed)';
  final lightness = c.lightness.round();
  final chroma = math.sqrt(c.a * c.a + c.b * c.b).round();
  final hue = _hueAngleDeg(c.a, c.b).round();
  return '$name. Lightness $lightness, chroma $chroma, hue $hue degrees.';
}

/// A recipe spoken as one utterance: each paint and its parts by volume
/// (AC-12, wireframe S1.R1.E25).
///
/// Every component is named; a measured component states its parts as a small
/// integer (the shares reduced against the smallest measured share, so a 2:1
/// mix speaks "2 parts … 1 part" rather than naive percentages — SI: recipes
/// are parts by volume), and a trace component (under ~2%, AC-7/D-12) is spoken
/// as "a touch of" that paint rather than a measured part, matching its card.
String recipeSpeech(Recipe recipe) {
  final measured =
      recipe.components.where((c) => !c.isTrace).map((c) => c.partsFraction);
  // A recipe's shares sum to 1 and a trace is under ~2%, so there is always at
  // least one measured component; `fold` seeds from the first share so an
  // all-trace mix (which the solver never returns) still divides safely.
  final smallest = measured.isEmpty
      ? 1.0
      : measured.reduce((a, b) => a < b ? a : b);
  final phrases = [
    for (final component in recipe.components)
      component.isTrace
          ? 'a touch of ${component.paint.name}'
          : _measuredPhrase(component, smallest),
  ];
  return 'Recipe: ${phrases.join(', ')}.';
}

/// `<paint> <n> part(s)` for a measured [component], its share reduced against
/// the recipe's [smallest] measured share (floored at one part).
String _measuredPhrase(RecipeComponent component, double smallest) {
  final parts = math.max(1, (component.partsFraction / smallest).round());
  return '${component.paint.name} $parts ${parts == 1 ? 'part' : 'parts'}';
}

/// The CIELAB hue angle of ([a], [b]) in degrees, normalised to [0, 360).
double _hueAngleDeg(double a, double b) {
  final deg = math.atan2(b, a) * 180.0 / math.pi;
  return deg < 0 ? deg + 360.0 : deg;
}
