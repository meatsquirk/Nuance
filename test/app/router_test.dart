import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';

Sample _sample(String name) => Sample(
      coordinates: const ColorCoordinates(lightness: 58, a: 24, b: 30),
      provenance: const Provenance(ProvenanceTier.measured),
      name: name,
    );

/// Pumps an app, then pushes [route] so its builder runs, and settles.
Future<void> _pushRoute(WidgetTester tester, Route<void> route) async {
  final key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const SizedBox()));
  unawaited(key.currentState!.push(route));
  await tester.pumpAndSettle();
}

void main() {
  // Constructed at runtime (non-const) so the const constructor line is covered.
  // ignore: prefer_const_constructors
  final router = AppRouter();

  testWidgets('toComparison slot A carries the sample into slot A only',
      (tester) async {
    await _pushRoute(
      tester,
      router.toComparison(_sample('Warm Terracotta'), ComparisonSlot.a),
    );
    expect(find.byType(ComparisonHomeScreen), findsOneWidget);
    expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot B: (empty)'), findsOneWidget);
  });

  testWidgets('toComparison slot B carries the sample into slot B only',
      (tester) async {
    await _pushRoute(
      tester,
      router.toComparison(_sample('Warm Terracotta'), ComparisonSlot.b),
    );
    expect(find.text('Slot B: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot A: (empty)'), findsOneWidget);
  });

  testWidgets('toRecipes carries the sample as the mixing target',
      (tester) async {
    await _pushRoute(tester, router.toRecipes(_sample('Deep Olive Green')));
    expect(find.byType(RecipesHomeScreen), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
  });

  testWidgets('toReadout opens the full Readout for the carried sample',
      (tester) async {
    // The Readout screen reads its services from the enclosing AppScope (the
    // production assembly wraps the navigator in one), so push under a scope.
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      AppScope(
        dependencies: const AppDependencies(
          colorScience: ColorScienceImpl(),
          speech: NoopSpeech(),
          haptics: NoopHaptics(),
        ),
        child: MaterialApp(navigatorKey: key, home: const SizedBox()),
      ),
    );
    unawaited(key.currentState!.push(router.toReadout(_sample('Warm Terracotta'))));
    await tester.pumpAndSettle();

    expect(find.byType(ReadoutScreen), findsOneWidget);
    expect(find.text('Warm Terracotta'), findsWidgets);
  });

  testWidgets('toCorrection carries the mix and reads the scope capture source',
      (tester) async {
    // The Correction loop needs a camera, which has no const default, so the
    // route reads the injected AppScope's capture source — push under a scope
    // that carries one, as the production assembly does.
    const mix = Recipe(
      medium: PaintMedium.acrylic,
      components: [
        RecipeComponent(
          paint: Paint(
            id: 'pw6',
            name: 'Titanium White',
            medium: PaintMedium.acrylic,
            masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
          ),
          partsFraction: 1,
        ),
      ],
      predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
      deltaE00: 1.2,
    );
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: const NoopSpeech(),
          haptics: const NoopHaptics(),
          captureSource: SoftwareCaptureSource(
            const SceneSpec(
              groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
            ),
          ),
        ),
        child: MaterialApp(navigatorKey: key, home: const SizedBox()),
      ),
    );
    unawaited(
      key.currentState!.push(router.toCorrection(_sample('Deep Olive Green'), mix)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CorrectionHomeScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Correction'), findsOneWidget);
    expect(find.text('Correction target: Deep Olive Green'), findsOneWidget);
  });
}
