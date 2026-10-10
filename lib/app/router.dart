import 'package:flutter/material.dart';

import '../domain/sample.dart';
import '../readout/readout_screen.dart';
import 'build_app.dart';

/// Which comparison slot a carried-over sample lands in.
enum ComparisonSlot { a, b }

/// Typed navigation for the app.
///
/// The comparison and recipes destinations are the real [ComparisonHomeScreen]
/// (bs-03) and [RecipesHomeScreen] (bs-04), each replacing bs-01's render-only
/// stub behind this same route — callers never change. Both render the
/// handed-off sample so the acceptance tests can observe the handoff (AC-9,
/// AC-10, AC-11). The router is injected via `buildApp` (CORE-3).
class AppRouter {
  const AppRouter();

  /// A route to the Comparison screen with [sample] placed into [slot].
  ///
  /// Carries the reading into the chosen slot (the other slot empty) via
  /// [ComparisonHomeScreen]'s initial slots, so the Readout → compare handoff
  /// (bs-01 AC-9/AC-10) lands on the real comparison with the sample in place.
  Route<void> toComparison(Sample sample, ComparisonSlot slot) {
    return MaterialPageRoute<void>(
      builder: (_) => ComparisonHomeScreen(
        initialA: slot == ComparisonSlot.a ? sample : null,
        initialB: slot == ComparisonSlot.b ? sample : null,
      ),
    );
  }

  /// A route to bs-01's full [ReadoutScreen] for [sample].
  ///
  /// Two callers share this one handoff: the Comparison → readout handoff, so the
  /// painter can open either compared sample in full (bs-03 AC-10/AC-11); and the
  /// capture commit, which opens the captured reading's readout (bs-02 D-5) where
  /// a sample marked [Sample.justCaptured] confirms with a haptic as the Readout
  /// lands (bs-01 AC-12). The screen reads its services from the [AppScope] the
  /// pushed route sits under (the production assembly wraps the navigator in that
  /// scope), symmetric to [toComparison].
  Route<void> toReadout(Sample sample) {
    return MaterialPageRoute<void>(
      builder: (_) => ReadoutScreen(sample: sample),
    );
  }

  /// A route to the [RecipesHomeScreen] with [target] as the mixing target.
  ///
  /// Carries the reading into the Recipes feature as its mixing target, so the
  /// Readout → recipes handoff (bs-01 AC-11) lands on the real Recipes screen
  /// with the target in place. The home is constructed with its default seams
  /// (empty catalogue / palettes, the stub engine) — the painter-supplied
  /// catalogue is injected only on the recipes *entry* assembly path.
  Route<void> toRecipes(Sample target) {
    return MaterialPageRoute<void>(
      builder: (_) => RecipesHomeScreen(target: target),
    );
  }
}
