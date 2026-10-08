import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/comparison_speech.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/compare/actions_bar.dart';
import 'package:paint_color_assistant/compare/comparison_controller.dart';
import 'package:paint_color_assistant/compare/comparison_screen.dart';
import 'package:paint_color_assistant/compare/confusion_region.dart';
import 'package:paint_color_assistant/compare/difference_region.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/compare/slots_region.dart';
import 'package:paint_color_assistant/compare/statement_region.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

const _sampleA = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);
const _sampleB = Sample(
  name: 'Raw Sienna Light',
  coordinates: ColorCoordinates(lightness: 70, a: 12.5, b: 21.65),
  provenance: Provenance(ProvenanceTier.measured),
);

ComparisonController _controller({
  SampleSource sampleSource = const InMemorySampleSource(),
  AppRouter router = const AppRouter(),
  Speech speech = const NoopSpeech(),
  Sample? initialA,
  Sample? initialB,
}) =>
    ComparisonController(
      sampleSource: sampleSource,
      confusionCheck: const NoopConfusionCheck(),
      profile: const CvdProfile(type: CvdType.deutan),
      speech: speech,
      router: router,
      initialA: initialA,
      initialB: initialB,
    );

/// A [Speech] that records each utterance, so the Speak control's (AC-9) wiring
/// can be observed at the widget level.
class _RecordingSpeech implements Speech {
  final List<String> utterances = [];

  @override
  Future<void> speak(String utterance) async => utterances.add(utterance);
}

/// Returns a trivial Readout route (no [AppScope] needed) and records which
/// sample it was asked to open, so a widget tap can prove the handoff.
class _StubRouter extends AppRouter {
  _StubRouter();

  final List<Sample> pushed = [];

  @override
  Route<void> toReadout(Sample sample) {
    pushed.add(sample);
    return MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('stub-readout')),
    );
  }
}

/// A [ConfusionCheck] pinned to a fixed verdict, so a widget test can drive the
/// confusion region without depending on the real projection's numbers.
class _FixedConfusionCheck implements ConfusionCheck {
  const _FixedConfusionCheck(this.verdict);
  final bool verdict;
  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile p) =>
      verdict;
}

Future<void> _pumpScreen(WidgetTester tester, ComparisonController c) =>
    tester.pumpWidget(MaterialApp(home: ComparisonScreen(controller: c)));

void main() {
  group('ComparisonScreen', () {
    testWidgets('renders one Comparison scaffold with all five regions',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller);

      expect(find.text('Comparison'), findsOneWidget);
      expect(find.byKey(SlotsRegion.regionKey), findsOneWidget);
      expect(find.byKey(DifferenceRegion.regionKey), findsOneWidget);
      expect(find.byKey(StatementRegion.regionKey), findsOneWidget);
      expect(find.byKey(ConfusionRegion.regionKey), findsOneWidget);
      expect(find.byKey(ComparisonActionsBar.regionKey), findsOneWidget);
    });

    testWidgets('shows both slots empty when no sample is placed',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller);

      expect(find.text('Slot A: (empty)'), findsOneWidget);
      expect(find.text('Slot B: (empty)'), findsOneWidget);
    });

    testWidgets('renders the pre-placed slot names (handoff)', (tester) async {
      final controller = _controller(initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller);

      expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
      expect(find.text('Slot B: Raw Sienna Light'), findsOneWidget);
    });
  });

  group('SlotsRegion', () {
    testWidgets('Choose A / Choose B and Swap are enabled; Sample picker inert '
        '(COMPARE-5 wires Swap)', (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SlotsRegion(controller: controller))),
      );

      for (final label in const [
        'Choose sample A',
        'Choose sample B',
        'Swap A and B',
      ]) {
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, label),
        );
        expect(button.enabled, isTrue, reason: '$label is wired');
      }
      final picker = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Sample picker'),
      );
      expect(picker.enabled, isFalse,
          reason: 'Sample picker is not wired in COMPARE-5');
    });

    testWidgets('tapping Swap exchanges the rendered slots (AC-3)',
        (tester) async {
      final controller = _controller(initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller);

      expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
      expect(find.text('Slot B: Raw Sienna Light'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Swap A and B'));
      await tester.pumpAndSettle();

      // The screen's ListenableBuilder re-renders the swapped slots.
      expect(find.text('Slot A: Raw Sienna Light'), findsOneWidget);
      expect(find.text('Slot B: Warm Terracotta'), findsOneWidget);
    });

    testWidgets('a placed slot shows its CIELCh reading, an empty one does not',
        (tester) async {
      final controller = _controller(initialA: _sampleA);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SlotsRegion(controller: controller))),
      );

      // Slot A (L 58 / C 34 / h 42°) renders its rounded LCh reading (AC-1).
      expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
      expect(find.text('L 58, C 34, h 42 degrees'), findsOneWidget);
      // Slot B is empty: name line only, no reading line.
      expect(find.text('Slot B: (empty)'), findsOneWidget);
    });

    testWidgets('Choose sample A opens the picker and fills slot A (AC-1)',
        (tester) async {
      final controller = _controller(
        sampleSource: const InMemorySampleSource(samples: [_sampleA, _sampleB]),
      );
      addTearDown(controller.dispose);
      // The full screen (with its ListenableBuilder) so the slot re-renders.
      await _pumpScreen(tester, controller);

      await tester.tap(find.widgetWithText(TextButton, 'Choose sample A'));
      await tester.pumpAndSettle();
      // The picker lists the catalogue.
      expect(find.text('Warm Terracotta'), findsOneWidget);
      expect(find.text('Raw Sienna Light'), findsOneWidget);

      await tester.tap(find.text('Warm Terracotta'));
      await tester.pumpAndSettle();

      expect(controller.state.slotA, same(_sampleA));
      expect(controller.state.slotB, isNull);
      expect(find.text('Slot A: Warm Terracotta'), findsOneWidget);
    });

    testWidgets('Choose sample B opens the picker and fills slot B (AC-2)',
        (tester) async {
      final controller = _controller(
        sampleSource: const InMemorySampleSource(samples: [_sampleA, _sampleB]),
      );
      addTearDown(controller.dispose);
      await _pumpScreen(tester, controller);

      await tester.tap(find.widgetWithText(TextButton, 'Choose sample B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Raw Sienna Light'));
      await tester.pumpAndSettle();

      expect(controller.state.slotB, same(_sampleB));
      expect(controller.state.slotA, isNull);
      expect(find.text('Slot B: Raw Sienna Light'), findsOneWidget);
    });

    testWidgets('dismissing the picker without choosing changes nothing',
        (tester) async {
      final controller = _controller(
        sampleSource: const InMemorySampleSource(samples: [_sampleA]),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SlotsRegion(controller: controller))),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Choose sample A'));
      await tester.pumpAndSettle();
      // Tap the barrier to dismiss without choosing a sample.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(controller.state.slotA, isNull);
    });
  });

  group('placeholder / invite regions', () {
    testWidgets('difference shows a placeholder and confusion shows no warning; '
        'the statement invites a second sample when there is no reading (AC-12)',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DifferenceRegion(controller: controller),
                StatementRegion(controller: controller),
                ConfusionRegion(controller: controller),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Overall difference'), findsOneWidget);
      expect(find.text('Relational statement'), findsOneWidget);
      // Difference shows the "nothing yet" placeholder (its DIFF reading needs
      // both slots); the confusion region carries no warning (AC-8: not
      // confusable — here there is no pair at all).
      expect(find.text('—'), findsOneWidget);
      expect(find.text(confusionWarningMessage), findsNothing);
      // The statement region invites a second sample instead (AC-12).
      expect(find.text('Choose a second sample to compare.'), findsOneWidget);
    });

    testWidgets('with both slots set the statement shows the three LCh lines '
        '(AC-5)', (tester) async {
      final controller = _controller(initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatementRegion(controller: controller)),
        ),
      );

      // Warm Terracotta → Raw Sienna Light decomposes A→B (DIFF-3).
      expect(find.text('Relational statement'), findsOneWidget);
      expect(find.text('Lighter by 12'), findsOneWidget);
      expect(find.text('Less saturated by 9'), findsOneWidget);
      expect(find.text('Hue shifted 18 degrees toward yellow'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      expect(find.text('Choose a second sample to compare.'), findsNothing);
    });
  });

  group('ConfusionRegion (CVD-2)', () {
    ComparisonController confused(bool verdict) => ComparisonController(
          sampleSource: const InMemorySampleSource(),
          confusionCheck: _FixedConfusionCheck(verdict),
          profile: const CvdProfile(type: CvdType.deutan),
          speech: const NoopSpeech(),
          initialA: _sampleA,
          initialB: _sampleB,
        );

    testWidgets('states the warning when the pair is confusable (AC-7)',
        (tester) async {
      final controller = confused(true);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ConfusionRegion(controller: controller))),
      );

      expect(controller.state.confusable, isTrue);
      expect(find.text(confusionWarningMessage), findsOneWidget);
    });

    testWidgets('shows no warning when the pair is not confusable (AC-8)',
        (tester) async {
      final controller = confused(false);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ConfusionRegion(controller: controller))),
      );

      expect(controller.state.confusable, isFalse);
      expect(find.byKey(ConfusionRegion.regionKey), findsOneWidget);
      expect(find.text(confusionWarningMessage), findsNothing);
    });
  });

  group('DifferenceRegion (DIFF-2)', () {
    testWidgets('with both slots set it shows ΔE00 and its verdict, not the '
        'placeholder (AC-4)', (tester) async {
      final controller = _controller(initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DifferenceRegion(controller: controller))),
      );

      // ΔE00 for Warm Terracotta → Raw Sienna Light ≈ 13.05, shown to one
      // decimal with its plain verdict band.
      expect(find.text('Overall difference'), findsOneWidget);
      expect(find.text('delta-E00 13.1'), findsOneWidget);
      expect(find.text('clearly different'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });
  });

  group('ComparisonActionsBar', () {
    bool enabled(WidgetTester tester, String label) => tester
        .widget<TextButton>(find.widgetWithText(TextButton, label))
        .enabled;

    testWidgets('Speak and both Open-readout controls are inert with no slots',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ComparisonActionsBar(controller: controller)),
        ),
      );

      // With no second sample there is no comparison to speak (AC-9) and nothing
      // to open — every action is disabled.
      expect(enabled(tester, 'Speak whole comparison'), isFalse,
          reason: 'no comparison yet ⇒ Speak whole comparison disabled');
      expect(enabled(tester, 'Open readout for A'), isFalse,
          reason: 'slot A empty ⇒ Open readout for A disabled');
      expect(enabled(tester, 'Open readout for B'), isFalse,
          reason: 'slot B empty ⇒ Open readout for B disabled');
    });

    testWidgets('with both slots set, tapping Speak speaks the whole comparison '
        'once (AC-9)', (tester) async {
      final speech = _RecordingSpeech();
      final controller =
          _controller(speech: speech, initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ComparisonActionsBar(controller: controller)),
        ),
      );

      expect(enabled(tester, 'Speak whole comparison'), isTrue,
          reason: 'both slots set ⇒ there is a comparison to speak');
      await tester.tap(find.widgetWithText(TextButton, 'Speak whole comparison'));
      await tester.pump();

      // Exactly one utterance, and it is the whole-comparison text the builder
      // produces for this state (reuses DIFF's lines) — rejects a tap that
      // speaks nothing or more than once.
      expect(speech.utterances, [comparisonSpeech(controller.state)]);
    });

    testWidgets('tapping Open-readout-A opens the Readout for slot A (AC-10)',
        (tester) async {
      final router = _StubRouter();
      final controller =
          _controller(router: router, initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ComparisonActionsBar(controller: controller)),
        ),
      );

      expect(enabled(tester, 'Open readout for A'), isTrue,
          reason: 'slot A set ⇒ Open readout for A enabled');
      await tester.tap(find.widgetWithText(TextButton, 'Open readout for A'));
      await tester.pumpAndSettle();

      // Pushes the Readout for slot A's sample — not slot B's.
      expect(router.pushed, [same(_sampleA)]);
      expect(find.text('stub-readout'), findsOneWidget);
    });

    testWidgets('tapping Open-readout-B opens the Readout for slot B (AC-11)',
        (tester) async {
      final router = _StubRouter();
      final controller =
          _controller(router: router, initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ComparisonActionsBar(controller: controller)),
        ),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Open readout for B'));
      await tester.pumpAndSettle();

      expect(router.pushed, [same(_sampleB)]);
      expect(find.text('stub-readout'), findsOneWidget);
    });
  });
}
