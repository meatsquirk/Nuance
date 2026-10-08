import 'package:flutter/foundation.dart';

import '../domain/paint.dart';

/// A named set of owned paints the solver mixes from (bs-04 D-5).
///
/// The pinned shape `{name, List<Paint>}`: the solver is constrained to exactly
/// these paints (AC-3) and the screen names the selected palette. Introduced
/// here because the frozen [MixingEngine] interface
/// (`inverse(Sample, PaintPalette, MixOptions)`) references it, and ENGINE-1
/// precedes RECIPE-2; **RECIPE-2** adds the `PaletteSource`/`InMemoryPaletteSource`
/// seam over this type (and **bs-06** the persistent store) without changing it.
///
/// Value-equal and `const`-constructible so a selected palette compares by
/// content; [paints] is exposed read-only so callers cannot mutate it.
class PaintPalette {
  /// Creates a palette named [name] over [paints] (empty by default).
  const PaintPalette({required this.name, this.paints = const []});

  /// The painter-facing palette name (e.g. "My paints"), rendered by the screen.
  final String name;

  /// The owned paints this palette offers the solver, in listing order.
  final List<Paint> paints;

  @override
  bool operator ==(Object other) =>
      other is PaintPalette &&
      other.name == name &&
      listEquals(other.paints, paints);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(paints));

  @override
  String toString() => 'PaintPalette("$name", ${paints.length} paints)';
}
