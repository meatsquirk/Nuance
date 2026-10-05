import 'package:flutter/material.dart';

import 'a11y/haptics.dart';
import 'a11y/speech.dart';
import 'app/build_app.dart';
import 'color_science/color_science_impl.dart';

/// Entry point for the Paint Color Assistant application.
///
/// Assembles the production dependencies — the [ColorScienceImpl] stub and the
/// no-op [NoopSpeech] / [NoopHaptics] platform sinks (bs-01 ships pure-Dart
/// logic with no native integration, D-1) — and launches via [buildApp], the
/// single assembly entry the acceptance harness also uses.
void main() {
  runApp(buildApp(productionDependencies()));
}

/// The dependencies the shipped app runs with.
///
/// Exposed so `main()` stays a one-liner and the production wiring is testable
/// on its own. Later features replace the stub implementations behind the same
/// [AppDependencies] seam without touching this entry point.
AppDependencies productionDependencies() {
  return const AppDependencies(
    colorScience: ColorScienceImpl(),
    speech: NoopSpeech(),
    haptics: NoopHaptics(),
  );
}
