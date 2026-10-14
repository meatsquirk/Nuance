// bs-12 swap harness (GUARD-2 scaffold).
//
// test-support for the swappable-interface guards (AC-14 mixing engine, AC-15
// CVD model): builds the *real* assembled app via the production `buildApp`
// entry with an alternate [MixingEngine] and / or [ConfusionCheck] injected
// through `AppDependencies`, proving a caller reaches the engine / CVD model
// only through its interface.
//
// GUARD-2 lays the injection helper on the real path (defaults to the shipped
// implementations, no assertions). GUARD-5 adds the recording alternates
// (`altMixingEngine` / `altConfusionCheck`), passes them here, drives the recipe
// and CVD callers, and asserts the callers routed through the interface while
// the source guard shows no caller references the concrete impl.
//
// This is test-support only — no `lib/` product code (D-7).

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';

import '../../fakes/fake_haptics.dart';
import '../../fakes/fake_speech.dart';

/// Pumps the real app (production `buildApp`) with [mixingEngine] and
/// [confusionCheck] injected through `AppDependencies`, the only platform sinks
/// faked (speech / haptics) and the real `ColorScienceImpl` in place.
///
/// This is the injection path AC-14 / AC-15 assert over: the recipe and CVD
/// callers reach the engine / CVD model only through their interface, so an
/// alternate implementation passed here drives every caller unchanged. Both
/// parameters default to the shipped implementations
/// ([SubtractiveMixingEngine], [DichromatConfusionCheck]), so GUARD-2 and
/// ITEST-1's smoke test can pump the app through this helper without doubles;
/// GUARD-5 passes recording alternates and checks the callers routed through
/// them.
Future<void> pumpAppWithSwaps(
  WidgetTester tester, {
  MixingEngine mixingEngine = const SubtractiveMixingEngine(),
  ConfusionCheck confusionCheck = const DichromatConfusionCheck(),
}) async {
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        mixingEngine: mixingEngine,
        confusionCheck: confusionCheck,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
