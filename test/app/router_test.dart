import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/compare/compare_stub.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/recipes_stub.dart';

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
    expect(find.byType(ComparisonStubScreen), findsOneWidget);
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
    expect(find.byType(RecipesStubScreen), findsOneWidget);
    expect(find.text('Recipe target: Deep Olive Green'), findsOneWidget);
  });
}
