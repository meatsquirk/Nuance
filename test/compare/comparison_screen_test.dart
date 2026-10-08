import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
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
  Sample? initialA,
  Sample? initialB,
}) =>
    ComparisonController(
      sampleSource: sampleSource,
      confusionCheck: const NoopConfusionCheck(),
      profile: const CvdProfile(type: CvdType.deutan),
      router: router,
      initialA: initialA,
      initialB: initialB,
    );

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
    testWidgets('Choose A / Choose B are enabled; Sample picker and Swap inert '
        '(COMPARE-3)', (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SlotsRegion(controller: controller))),
      );

      for (final label in const ['Choose sample A', 'Choose sample B']) {
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, label),
        );
        expect(button.enabled, isTrue,
            reason: '$label opens the picker in COMPARE-3');
      }
      for (final label in const ['Sample picker', 'Swap A and B']) {
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, label),
        );
        expect(button.enabled, isFalse,
            reason: '$label is not wired in COMPARE-3');
      }
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
    testWidgets('difference and confusion show a placeholder; the statement '
        'invites a second sample when there is no reading (AC-12)',
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
      expect(find.text('Confusion warning'), findsOneWidget);
      // Difference and confusion still show the "nothing yet" placeholder.
      expect(find.text('—'), findsNWidgets(2));
      // The statement region invites a second sample instead (AC-12).
      expect(find.text('Choose a second sample to compare.'), findsOneWidget);
    });

    testWidgets('with both slots set the statement shows the DIFF-3 placeholder',
        (tester) async {
      final controller = _controller(initialA: _sampleA, initialB: _sampleB);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatementRegion(controller: controller)),
        ),
      );

      expect(find.text('Relational statement'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Choose a second sample to compare.'), findsNothing);
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

      // Speak stays deferred to CVD-3; the Open-readout controls are disabled
      // while their slots are empty (nothing to open).
      expect(enabled(tester, 'Speak whole comparison'), isFalse,
          reason: 'Speak whole comparison is inert until CVD-3');
      expect(enabled(tester, 'Open readout for A'), isFalse,
          reason: 'slot A empty ⇒ Open readout for A disabled');
      expect(enabled(tester, 'Open readout for B'), isFalse,
          reason: 'slot B empty ⇒ Open readout for B disabled');
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
