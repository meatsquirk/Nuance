import 'package:flutter/material.dart';

import '../compare/compare_stub.dart';
import '../domain/sample.dart';
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
}
