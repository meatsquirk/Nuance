import 'package:flutter/material.dart';

import '../compare/compare_stub.dart';
import '../domain/sample.dart';
import '../readout/readout_screen.dart';
import '../recipes/recipes_stub.dart';

/// Which comparison slot a carried-over sample lands in.
enum ComparisonSlot { a, b }

/// Typed navigation for the app.
///
/// For bs-01 the comparison and recipes destinations are thin **stub** screens
/// ([ComparisonStubScreen], [RecipesStubScreen]) that render the handed-off
/// sample so the acceptance tests can observe the handoff (AC-9, AC-10, AC-11).
/// bs-03 / bs-04 replace the stubs behind these same typed routes; callers never
/// change. The router is injected via `buildApp` (CORE-3).
class AppRouter {
  const AppRouter();

  /// A route to the comparison screen with [sample] placed into [slot].
  Route<void> toComparison(Sample sample, ComparisonSlot slot) {
    return MaterialPageRoute<void>(
      builder: (_) => ComparisonStubScreen(
        sampleA: slot == ComparisonSlot.a ? sample : null,
        sampleB: slot == ComparisonSlot.b ? sample : null,
      ),
    );
  }

  /// A route to the recipes screen with [target] as the mixing target.
  Route<void> toRecipes(Sample target) {
    return MaterialPageRoute<void>(
      builder: (_) => RecipesStubScreen(target: target),
    );
  }

  /// A route to the bs-01 Readout screen showing [sample].
  ///
  /// The capture commit pushes it to open the captured reading's readout (bs-02
  /// D-5): the handoff is symmetric to bs-01's own readout entry, and a sample
  /// marked [Sample.justCaptured] confirms with a haptic as the Readout lands
  /// (bs-01 AC-12).
  Route<void> toReadout(Sample sample) {
    return MaterialPageRoute<void>(
      builder: (_) => ReadoutScreen(sample: sample),
    );
  }
}
