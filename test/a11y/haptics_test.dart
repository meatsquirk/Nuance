import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';

void main() {
  group('NoopHaptics', () {
    test('is a Haptics', () {
      expect(const NoopHaptics(), isA<Haptics>());
    });

    test('confirm completes without doing anything', () async {
      await expectLater(const NoopHaptics().confirm(), completes);
    });
  });
}
