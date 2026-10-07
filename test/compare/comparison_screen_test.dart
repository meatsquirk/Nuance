import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
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

ComparisonController _controller({Sample? initialA, Sample? initialB}) =>
    ComparisonController(
      sampleSource: const InMemorySampleSource(),
      confusionCheck: const NoopConfusionCheck(),
      profile: const CvdProfile(type: CvdType.deutan),
      initialA: initialA,
      initialB: initialB,
    );

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
    testWidgets('the choose and picker controls are present but inert',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SlotsRegion(controller: controller))),
      );

      for (final label in const [
        'Choose sample A',
        'Choose sample B',
        'Sample picker',
        'Swap A and B',
      ]) {
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, label),
        );
        expect(button.enabled, isFalse, reason: '$label must be inert in SCREEN-1');
      }
    });
  });

  group('placeholder regions', () {
    testWidgets('each states its heading and an inert placeholder',
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
      // Three regions, each with the same "nothing yet" placeholder.
      expect(find.text('—'), findsNWidgets(3));
    });
  });

  group('ComparisonActionsBar', () {
    testWidgets('every action is present but inert', (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ComparisonActionsBar(controller: controller)),
        ),
      );

      for (final label in const [
        'Speak whole comparison',
        'Open readout for A',
        'Open readout for B',
      ]) {
        final button = tester.widget<TextButton>(
          find.widgetWithText(TextButton, label),
        );
        expect(button.enabled, isFalse, reason: '$label must be inert in SCREEN-1');
      }
    });
  });
}
