import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/speech.dart';

void main() {
  group('NoopSpeech', () {
    test('is a Speech', () {
      expect(const NoopSpeech(), isA<Speech>());
    });

    test('speak completes without doing anything', () async {
      await expectLater(const NoopSpeech().speak('Warm Terracotta'), completes);
    });
  });
}
