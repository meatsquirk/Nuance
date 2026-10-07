import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

void main() {
  group('NoopConfusionCheck', () {
    const check = NoopConfusionCheck();
    const profile = CvdProfile(type: CvdType.deutan);

    test('is a ConfusionCheck', () {
      expect(check, isA<ConfusionCheck>());
    });

    test('never flags a pair as confusable (inert until CVD-2)', () {
      const a = ColorCoordinates(lightness: 58, a: 24, b: 30);
      const b = ColorCoordinates(lightness: 70, a: 12, b: 24);
      expect(check.confusable(a, b, profile), isFalse);
      // Even identical coordinates are not flagged by the inert default.
      expect(check.confusable(a, a, profile), isFalse);
    });
  });
}
