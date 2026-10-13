import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/repeatable_speech.dart';
import 'package:paint_color_assistant/a11y/speech.dart';

/// A [Speech] that records each utterance in call order, so a test can observe
/// what the wrapper delegates to the inner sink.
class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
}

void main() {
  group('RepeatableSpeech', () {
    test('wraps the given inner sink', () {
      const inner = NoopSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);
      expect(identical(speech.inner, inner), isTrue);
      expect(speech, isA<Speech>());
    });

    test('has no last utterance and cannot repeat before anything is spoken',
        () {
      final speech = RepeatableSpeech(_RecordingSpeech());
      addTearDown(speech.dispose);
      expect(speech.lastUtterance, isNull);
      expect(speech.canRepeat, isFalse);
    });

    test('speak delegates to the inner sink, records the utterance and notifies',
        () async {
      final inner = _RecordingSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);
      var notifications = 0;
      speech.addListener(() => notifications++);

      await speech.speak('lightness 58');

      expect(inner.utterances, ['lightness 58']);
      expect(speech.lastUtterance, 'lightness 58');
      expect(speech.canRepeat, isTrue);
      expect(notifications, 1);
    });

    test('repeat re-speaks the last utterance through the inner sink unchanged',
        () async {
      final inner = _RecordingSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);

      await speech.speak('lightness 58');
      await speech.repeat();

      // The same utterance is replayed through the same sink; last unchanged.
      expect(inner.utterances, ['lightness 58', 'lightness 58']);
      expect(speech.lastUtterance, 'lightness 58');
    });

    test('repeat does nothing when nothing has been spoken yet', () async {
      final inner = _RecordingSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);

      await speech.repeat();

      expect(inner.utterances, isEmpty);
      expect(speech.lastUtterance, isNull);
    });

    test('a later utterance replaces the one repeat replays', () async {
      final inner = _RecordingSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);

      await speech.speak('first');
      await speech.speak('second');
      await speech.repeat();

      expect(inner.utterances, ['first', 'second', 'second']);
      expect(speech.lastUtterance, 'second');
    });
  });
}
