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
      'the setters preserve the other fields (shell: no cross-field rules)',
      () {
        final controller = DisplayController()
          ..setSimulationType(CvdType.protan)
          ..setSimulationSeverity(0.6)
          ..setGrayscale(true);
        // DISPLAY-6 (AC-5) will make grayscale clear the simulation; the shell
        // does not, so all three fields stand together here.
        expect(controller.settings.simulationType, CvdType.protan);
        expect(controller.settings.simulationSeverity, 0.6);
        expect(controller.settings.grayscale, isTrue);
        controller.dispose();
      },
    );
  });
}
