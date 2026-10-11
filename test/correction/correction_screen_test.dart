import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/correction/correction_controller.dart';
import 'package:paint_color_assistant/correction/correction_screen.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/correction/regions/check_region.dart';
import 'package:paint_color_assistant/correction/regions/correction_region.dart';
import 'package:paint_color_assistant/correction/regions/difference_region.dart';
import 'package:paint_color_assistant/correction/regions/rephotograph_region.dart';
import 'package:paint_color_assistant/correction/regions/save_region.dart';
import 'package:paint_color_assistant/correction/regions/speak_region.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _unnamed = Sample(
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _mix = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);

CorrectionController _controller({Sample target = _olive}) => CorrectionController(
      captureSource: SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
        ),
      ),
      target: target,
      currentMix: _mix,
      paletteSource: const InMemoryPaletteSource(),
      correctionEngine: const SubtractiveCorrectionEngine(),
    );

/// Pumps [child] under a Material scaffold so a region renders in isolation.
Future<void> _pumpRegion(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

bool _buttonEnabled(WidgetTester tester, String label) => tester
    .widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    )
    .enabled;

void main() {
  group('CorrectionScreen', () {
    testWidgets('renders one Correction scaffold with all six regions',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CorrectionScreen(controller: controller)),
      );

      expect(find.widgetWithText(AppBar, 'Correction'), findsOneWidget);
      expect(find.byKey(CheckRegion.regionKey), findsOneWidget);
      expect(find.byKey(DifferenceRegion.regionKey), findsOneWidget);
      expect(find.byKey(CorrectionRegion.regionKey), findsOneWidget);
      expect(find.byKey(SpeakRegion.regionKey), findsOneWidget);
      expect(find.byKey(RephotographRegion.regionKey), findsOneWidget);
      expect(find.byKey(SaveRegion.regionKey), findsOneWidget);
    });

    testWidgets('renders the named target and the pre-check placeholders',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CorrectionScreen(controller: controller)),
      );

      expect(find.text('Correction target: Deep Olive Green'), findsOneWidget);
      expect(
        find.text('Check the mix to see how it differs from the target.'),
        findsOneWidget,
      );
      expect(
        find.text('Check the mix to see the paints to add.'),
        findsOneWidget,
      );
      // The check (LOOP-3) and re-photograph (LOOP-5) controls are wired; the
      // rest await their phases.
      expect(_buttonEnabled(tester, 'Check my mix'), isTrue);
      expect(_buttonEnabled(tester, 'Re-photograph swatch'), isTrue);
      expect(_buttonEnabled(tester, 'Speak correction'), isFalse);
      expect(_buttonEnabled(tester, 'Save confirmed mix'), isFalse);
    });
  });

  group('CheckRegion', () {
    testWidgets('shows the named target and checks the mix on tap (E26)',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, CheckRegion(controller: controller));

      expect(find.text('Correction target: Deep Olive Green'), findsOneWidget);
      expect(_buttonEnabled(tester, 'Check my mix'), isTrue);

      // E26 Check my mix drives CorrectionController.checkMix (AC-1): it
      // photographs the swatch and reads the difference from the target.
      await tester.tap(find.text('Check my mix'));
      await tester.pumpAndSettle();
      expect(controller.state.hasChecked, isTrue);
      expect(controller.state.mixedSwatch, isNotNull);
      expect(controller.state.difference, isNotNull);
    });

    testWidgets('falls back to (unnamed) for a target with no name',
        (tester) async {
      final controller = _controller(target: _unnamed);
      addTearDown(controller.dispose);
      await _pumpRegion(tester, CheckRegion(controller: controller));

      expect(find.text('Correction target: (unnamed)'), findsOneWidget);
    });
  });

  group('DifferenceRegion', () {
    testWidgets('keeps its anchor and shows the pre-check placeholder',
        (tester) async {
      await _pumpRegion(tester, const DifferenceRegion());

      expect(find.byKey(DifferenceRegion.regionKey), findsOneWidget);
      expect(
        find.text('Check the mix to see how it differs from the target.'),
        findsOneWidget,
      );
    });
  });

  group('CorrectionRegion', () {
    testWidgets('keeps its anchor and shows the pre-check placeholder',
        (tester) async {
      await _pumpRegion(tester, const CorrectionRegion());

      expect(find.byKey(CorrectionRegion.regionKey), findsOneWidget);
      expect(
        find.text('Check the mix to see the paints to add.'),
        findsOneWidget,
      );
    });
  });

  group('SpeakRegion', () {
    testWidgets('keeps its anchor and the disabled speak control (E27)',
        (tester) async {
      await _pumpRegion(tester, const SpeakRegion());

      expect(find.byKey(SpeakRegion.regionKey), findsOneWidget);
      expect(_buttonEnabled(tester, 'Speak correction'), isFalse);
    });
  });

  group('RephotographRegion', () {
    testWidgets('keeps its anchor and re-photographs the swatch on tap (E28)',
        (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, RephotographRegion(controller: controller));

      expect(find.byKey(RephotographRegion.regionKey), findsOneWidget);
      expect(_buttonEnabled(tester, 'Re-photograph swatch'), isTrue);

      // E28 Re-photograph swatch drives CorrectionController.rephotograph
      // (AC-8): it re-measures the swatch and re-reads the difference.
      await tester.tap(find.text('Re-photograph swatch'));
      await tester.pumpAndSettle();
      expect(controller.state.hasChecked, isTrue);
      expect(controller.state.mixedSwatch, isNotNull);
      expect(controller.state.difference, isNotNull);
    });
  });

  group('SaveRegion', () {
    testWidgets('keeps its anchor and the disabled save control (E29)',
        (tester) async {
      await _pumpRegion(tester, const SaveRegion());

      expect(find.byKey(SaveRegion.regionKey), findsOneWidget);
      expect(_buttonEnabled(tester, 'Save confirmed mix'), isFalse);
    });
  });
}
