import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/repeatable_speech.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/display/spoken_output_panel.dart';

/// A [Speech] that records each utterance, to observe the panel's repeat.
class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
}

void main() {
  group('SpeechScope', () {
    testWidgets('of() returns the nearest scope speech', (tester) async {
      final speech = RepeatableSpeech(const NoopSpeech());
      addTearDown(speech.dispose);
      late RepeatableSpeech seen;
      await tester.pumpWidget(
        SpeechScope(
          speech: speech,
          child: Builder(
            builder: (context) {
              seen = SpeechScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(identical(seen, speech), isTrue);
    });

    testWidgets('maybeOf() returns the speech when present, null when absent',
        (tester) async {
      final speech = RepeatableSpeech(const NoopSpeech());
      addTearDown(speech.dispose);
      late RepeatableSpeech? present;
      late RepeatableSpeech? absent;
      await tester.pumpWidget(
        Column(
          children: [
            Builder(
              builder: (context) {
                absent = SpeechScope.maybeOf(context);
                return const SizedBox();
              },
            ),
            SpeechScope(
              speech: speech,
              child: Builder(
                builder: (context) {
                  present = SpeechScope.maybeOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );
      expect(identical(present, speech), isTrue);
      expect(absent, isNull);
    });
  });

  group('SpokenOutputPanel', () {
    Widget host(RepeatableSpeech speech) => MaterialApp(
          home: Scaffold(
            body: SpeechScope(
              speech: speech,
              child: const SpokenOutputPanel(),
            ),
          ),
        );

    testWidgets('is present but inert (no control, no text) until something is '
        'spoken', (tester) async {
      final speech = RepeatableSpeech(_RecordingSpeech());
      addTearDown(speech.dispose);
      await tester.pumpWidget(host(speech));

      expect(find.byKey(SpokenOutputPanel.panelKey), findsOneWidget);
      expect(find.byKey(SpokenOutputPanel.repeatKey), findsNothing);
      expect(find.byKey(SpokenOutputPanel.lastSpokenKey), findsNothing);
    });

    testWidgets('shows the last-spoken text and a repeat control once spoken',
        (tester) async {
      final inner = _RecordingSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);
      await tester.pumpWidget(host(speech));

      await speech.speak('lightness 58, warm');
      await tester.pump();

      expect(find.byKey(SpokenOutputPanel.panelKey), findsOneWidget);
      expect(find.byKey(SpokenOutputPanel.repeatKey), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(SpokenOutputPanel.lastSpokenKey)).data,
        'lightness 58, warm',
      );
    });

    testWidgets('the repeat control replays the exact utterance through the sink',
        (tester) async {
      final inner = _RecordingSpeech();
      final speech = RepeatableSpeech(inner);
      addTearDown(speech.dispose);
      await tester.pumpWidget(host(speech));

      await speech.speak('lightness 58, warm');
      await tester.pump();

      await tester.tap(find.byKey(SpokenOutputPanel.repeatKey));
      await tester.pump();

      expect(inner.utterances, ['lightness 58, warm', 'lightness 58, warm']);
    });
  });
}
