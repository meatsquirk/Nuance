import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_scope.dart';

void main() {
  group('DisplayScope', () {
    testWidgets('of() returns the nearest controller', (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      late DisplayController seen;
      await tester.pumpWidget(
        DisplayScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              seen = DisplayScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(identical(seen, controller), isTrue);
    });

    testWidgets('of() asserts when there is no scope', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => DisplayScope.of(context), throwsAssertionError);
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('maybeOf() returns the controller when present', (
      tester,
    ) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      late DisplayController? seen;
      await tester.pumpWidget(
        DisplayScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              seen = DisplayScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(identical(seen, controller), isTrue);
    });

    testWidgets('maybeOf() returns null when there is no scope', (
      tester,
    ) async {
      late DisplayController? seen;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            seen = DisplayScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );
      expect(seen, isNull);
    });

    testWidgets('a dependent rebuilds when the controller notifies', (
      tester,
    ) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      var builds = 0;
      await tester.pumpWidget(
        DisplayScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              builds++;
              // Depend on the scope so a notify triggers a rebuild.
              DisplayScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(builds, 1);
      controller.setSimulationType(CvdType.deutan);
      await tester.pump();
      expect(builds, 2);
    });
  });
}
