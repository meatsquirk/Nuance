import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/app_destinations.dart';

void main() {
  group('AppDestination', () {
    test('lists the four wireframe destinations in bar order', () {
      expect(
        AppDestination.values,
        [
          AppDestination.capture,
          AppDestination.compare,
          AppDestination.recipes,
          AppDestination.palette,
        ],
      );
    });

    test('carries a label, an outline glyph and a distinct filled glyph', () {
      for (final d in AppDestination.values) {
        expect(d.label, isNotEmpty);
        expect(d.selectedIcon, isNot(equals(d.icon)),
            reason: 'the filled glyph must differ from the outline glyph so '
                'active state reads without colour (AC-13)');
      }
    });

    test('labels are the titles the wireframe names', () {
      expect(AppDestination.capture.label, 'Capture');
      expect(AppDestination.compare.label, 'Compare');
      expect(AppDestination.recipes.label, 'Recipes');
      expect(AppDestination.palette.label, 'Palette');
    });

    test('exposes a unique, stable nav-item key per destination', () {
      final keys = AppDestination.values.map((d) => d.navItemKey).toList();
      expect(keys.toSet().length, keys.length, reason: 'keys are unique');
      expect(AppDestination.capture.navItemKey,
          const Key('app-nav-dest-capture'));
      expect(AppDestination.palette.navItemKey,
          const Key('app-nav-dest-palette'));
    });
  });
}
