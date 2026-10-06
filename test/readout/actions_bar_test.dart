import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';

const _sample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A [Speech] that records each utterance, so the speak button (AC-8) wiring can
/// be observed.
class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
}

ReadoutController _controller({Sample? sample, Speech? speech}) =>
    ReadoutController(
      sample: sample ?? _sample,
      colorScience: const ColorScienceImpl(),
      speech: speech ?? const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: const AppRouter(),
    );

// The bar needs a Navigator ancestor to push its handoff routes.
Future<void> _pumpBar(WidgetTester tester, ReadoutController controller) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ActionsBar(controller: controller))),
    );

// As [_pumpBar], but rebuilds the bar when the controller notifies — the real
// screen wraps the bar in a ListenableBuilder, so acknowledging (which notifies)
// must re-render the bar and drop the marker.
Future<void> _pumpLiveBar(WidgetTester tester, ReadoutController controller) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => ActionsBar(controller: controller),
          ),
        ),
      ),
    );

void main() {
  testWidgets('"Compare as A" pushes the Comparison screen with the reading '
      'in slot A (AC-9)', (tester) async {
    await _pumpBar(tester, _controller());

    await tester.tap(find.byKey(ActionsBar.compareAKey));
    await tester.pumpAndSettle();

    expect(find.text('Comparison'), findsOneWidget);
    expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot B: (empty)'), findsOneWidget);
  });

  testWidgets('"Compare as B" pushes the Comparison screen with the reading '
      'in slot B (AC-10)', (tester) async {
    await _pumpBar(tester, _controller());

    await tester.tap(find.byKey(ActionsBar.compareBKey));
    await tester.pumpAndSettle();

    expect(find.text('Comparison'), findsOneWidget);
    expect(find.text('Slot B: Warm Terracotta'), findsOneWidget);
    expect(find.text('Slot A: (empty)'), findsOneWidget);
  });

  testWidgets('"Find mixing recipes" pushes the Recipes screen with the '
      'reading as the target (AC-11)', (tester) async {
    await _pumpBar(tester, _controller());

    await tester.tap(find.byKey(ActionsBar.recipesKey));
    await tester.pumpAndSettle();

    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Recipe target: Warm Terracotta'), findsOneWidget);
  });

  testWidgets('"Speak this readout" drives the controller\'s speak action (AC-8)',
      (tester) async {
    final speech = _RecordingSpeech();
    await _pumpBar(tester, _controller(speech: speech));

    await tester.tap(find.byKey(ActionsBar.speakKey));
    await tester.pump();

    expect(speech.utterances,
        [const ColorScienceImpl().decompose(_sample)]);
  });

  testWidgets('a non-fresh reading shows no marker and disables Acknowledge '
      '(AC-12 control)', (tester) async {
    await _pumpBar(tester, _controller()); // _sample is not just-captured

    expect(find.byKey(ActionsBar.justCapturedKey), findsNothing);
    final ack = tester.widget<OutlinedButton>(
        find.byKey(ActionsBar.acknowledgeKey));
    expect(ack.onPressed, isNull, reason: 'Acknowledge is disabled when nothing '
        'was just captured');
  });

  testWidgets('a just-captured reading shows the marker and acknowledging '
      'clears it (AC-12)', (tester) async {
    const fresh = Sample(
      name: 'Deep Olive Green',
      coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
      provenance: Provenance(ProvenanceTier.measured),
      justCaptured: true,
    );
    final controller = _controller(sample: fresh);
    await _pumpLiveBar(tester, controller);

    // The marker shows and Acknowledge is enabled.
    expect(find.byKey(ActionsBar.justCapturedKey), findsOneWidget);
    final ack = tester.widget<OutlinedButton>(
        find.byKey(ActionsBar.acknowledgeKey));
    expect(ack.onPressed, isNotNull);

    // Acknowledging clears the marker (the controller notifies → the bar
    // rebuilds without it).
    await tester.tap(find.byKey(ActionsBar.acknowledgeKey));
    await tester.pump();

    expect(controller.justCaptured, isFalse);
    expect(find.byKey(ActionsBar.justCapturedKey), findsNothing);
  });
}
