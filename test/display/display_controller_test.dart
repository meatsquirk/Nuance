import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_settings.dart';

void main() {
  group('DisplayController', () {
    test('defaults to deutan pre-selection and the shipped view', () {
      final controller = DisplayController();
      expect(controller.defaultSimulationType, CvdType.deutan);
      expect(controller.settings, const DisplaySettings());
      controller.dispose();
    });

    test('keeps an injected default type and initial settings', () {
      final controller = DisplayController(
        defaultSimulationType: CvdType.tritan,
        initialSettings: const DisplaySettings(grayscale: true),
      );
      expect(controller.defaultSimulationType, CvdType.tritan);
      expect(controller.settings.grayscale, isTrue);
      controller.dispose();
    });

    test('setSimulationType changes the type and notifies', () {
      final controller = DisplayController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setSimulationType(CvdType.protan);
      expect(controller.settings.simulationType, CvdType.protan);
      expect(controller.settings.simulationOn, isTrue);
      expect(notifications, 1);

      // Turning it back off (null) is the trichromat view again.
      controller.setSimulationType(null);
      expect(controller.settings.simulationType, isNull);
      expect(notifications, 2);
      controller.dispose();
    });

    test('setSimulationType is a no-op when the type is unchanged', () {
      final controller = DisplayController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setSimulationType(null); // already null
      expect(notifications, 0);
      controller.dispose();
    });

    test('setSimulationSeverity changes the severity and notifies', () {
      final controller = DisplayController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setSimulationSeverity(0.3);
      expect(controller.settings.simulationSeverity, 0.3);
      expect(notifications, 1);
      controller.dispose();
    });

    test('setSimulationSeverity is a no-op when unchanged', () {
      final controller = DisplayController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setSimulationSeverity(1.0); // already the default
      expect(notifications, 0);
      controller.dispose();
    });

    test('setGrayscale toggles grayscale and notifies', () {
      final controller = DisplayController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setGrayscale(true);
      expect(controller.settings.grayscale, isTrue);
      expect(notifications, 1);
      controller.dispose();
    });

    test('setGrayscale is a no-op when unchanged', () {
      final controller = DisplayController();
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setGrayscale(false); // already false
      expect(notifications, 0);
      controller.dispose();
    });

    test(
      'the simulation setters preserve each other (type and severity coexist)',
      () {
        final controller = DisplayController()
          ..setSimulationType(CvdType.protan)
          ..setSimulationSeverity(0.6);
        // Type and severity stand together — only grayscale is exclusive with
        // the simulation (see the D-3 tests below).
        expect(controller.settings.simulationType, CvdType.protan);
        expect(controller.settings.simulationSeverity, 0.6);
        expect(controller.settings.grayscale, isFalse);
        controller.dispose();
      },
    );

    // DISPLAY-6 (AC-5, D-3): grayscale and simulation are mutually exclusive.
    test('setGrayscale(true) clears an active simulation and notifies', () {
      final controller = DisplayController()
        ..setSimulationType(CvdType.deutan)
        ..setSimulationSeverity(0.6);
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setGrayscale(true);

      expect(controller.settings.grayscale, isTrue, reason: 'grayscale is on');
      expect(controller.settings.simulationType, isNull,
          reason: 'turning grayscale on clears the active simulation');
      expect(controller.settings.simulationOn, isFalse);
      // The severity is left intact — only the active type is cleared.
      expect(controller.settings.simulationSeverity, 0.6);
      expect(notifications, 1, reason: 'one notification for the toggle');
      controller.dispose();
    });

    test('turning grayscale off does not re-enable the simulation', () {
      final controller = DisplayController()
        ..setSimulationType(CvdType.tritan)
        ..setGrayscale(true); // clears the tritan simulation
      expect(controller.settings.simulationType, isNull);

      controller.setGrayscale(false);

      expect(controller.settings.grayscale, isFalse);
      expect(controller.settings.simulationType, isNull,
          reason: 'grayscale off leaves the simulation off (never re-enabled)');
      controller.dispose();
    });
  });
}
