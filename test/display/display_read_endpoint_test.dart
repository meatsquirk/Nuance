import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/cvd/daltonize.dart';
import 'package:paint_color_assistant/display/color_simulation.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_read_endpoint.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

void main() {
  group('DisplayReadEndpoint', () {
    testWidgets('of() exposes the controller and settings to a descendant', (
      tester,
    ) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      late DisplayController seen;
      late DisplayReadEndpoint endpoint;
      await tester.pumpWidget(
        DisplayReadEndpoint(
          key: DisplayReadEndpoint.endpointKey,
          controller: controller,
          child: Builder(
            builder: (context) {
              seen = DisplayReadEndpoint.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(identical(seen, controller), isTrue);
      endpoint = tester.widget<DisplayReadEndpoint>(
        find.byKey(DisplayReadEndpoint.endpointKey),
      );
      expect(endpoint.settings, const DisplaySettings());
    });

    testWidgets('of() asserts when there is no endpoint', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => DisplayReadEndpoint.of(context), throwsAssertionError);
            return const SizedBox();
          },
        ),
      );
    });

    test('updateShouldNotify is true for a different controller', () {
      final a = DisplayReadEndpoint(
        controller: DisplayController(),
        child: const SizedBox(),
      );
      final b = DisplayReadEndpoint(
        controller: DisplayController(),
        child: const SizedBox(),
      );
      expect(a.updateShouldNotify(b), isTrue);
      a.controller.dispose();
      b.controller.dispose();
    });

    test('updateShouldNotify is false for the same controller', () {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      final a = DisplayReadEndpoint(
        controller: controller,
        child: const SizedBox(),
      );
      final b = DisplayReadEndpoint(
        controller: controller,
        child: const SizedBox(),
      );
      expect(a.updateShouldNotify(b), isFalse);
    });

    // bs-10 DALT-2: the endpoint surfaces the daltonization flag and the
    // effective displayed colour for the acceptance suite to observe.
    test('daltonization reflects the controller settings', () {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      final endpoint =
          DisplayReadEndpoint(controller: controller, child: const SizedBox());
      expect(endpoint.daltonization, isFalse);
      controller.setDaltonization(true);
      expect(endpoint.daltonization, isTrue);
    });

    test('displayedColor routes through the shared chokepoint', () {
      const original = Color(0xFF3AA0BF);
      const profile = CvdProfile(type: CvdType.deutan);
      final controller = DisplayController();
      addTearDown(controller.dispose);
      final endpoint =
          DisplayReadEndpoint(controller: controller, child: const SizedBox());

      // Both views off: the simulation identity — the true colour.
      expect(endpoint.displayedColor(original, profile),
          simulateColor(original, controller.settings));

      // Daltonization on: the endpoint reports the remapped colour ColorChip
      // paints (identity in the shell).
      controller.setDaltonization(true);
      expect(endpoint.displayedColor(original, profile),
          daltonizeColor(original, profile));
    });
  });
}
