import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/correction/correction_controller.dart';
import 'package:paint_color_assistant/correction/correction_screen.dart';
import 'package:paint_color_assistant/correction/correction_state.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine.dart';
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
const _ochre = Paint(
  id: 'py43',
  name: 'Yellow Ochre',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
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

/// A controller whose [state] is fixed, so the correction region's render
/// branches (pre-check, no-correction, measured, trace) can be pumped without
/// driving a capture through the engine. The constructor seams are inert here.
class _FixedStateController extends CorrectionController {
  _FixedStateController(this._fixed)
      : super(
          captureSource: SoftwareCaptureSource(
            const SceneSpec(
              groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
            ),
          ),
          target: _olive,
          currentMix: _mix,
          paletteSource: const InMemoryPaletteSource(),
          correctionEngine: const SubtractiveCorrectionEngine(),
        );

  final CorrectionState _fixed;

  @override
  CorrectionState get state => _fixed;
}

/// A [CorrectionState] carrying [correction] (target and mix fixed).
CorrectionState _stateWith(Correction? correction) => CorrectionState(
      target: _olive,
      currentMix: _mix,
      correction: correction,
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

    testWidgets(
        'shows the ΔE00, verdict and value-leading decomposition once checked '
        '(CORRECT-2)', (tester) async {
      final controller = _controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: CorrectionScreen(controller: controller)),
      );

      // Check the mix (E26): photographs the swatch and reads the difference,
      // and the screen rebuilds on the controller's notification.
      await tester.tap(find.text('Check my mix'));
      await tester.pumpAndSettle();

      final difference = controller.state.difference;
      expect(difference, isNotNull);
      expect(difference!.verdict, 'noticeably off',
          reason: 'the scene sits beyond tolerance (G-4b)');

      // Rendered in the difference body: the verdict, then the value reading,
      // then the hue reading (value leads for a CVD painter, D-5).
      final region = find.byKey(DifferenceRegion.regionKey);
      expect(
        find.descendant(of: region, matching: find.textContaining('noticeably off')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: region, matching: find.textContaining('too dark')),
        findsOneWidget,
      );
      expect(
        find.descendant(
            of: region, matching: find.textContaining('shifted toward green')),
        findsOneWidget,
      );
      expect(
        find.text('Check the mix to see how it differs from the target.'),
        findsNothing,
      );
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
      final controller = _controller();
      addTearDown(controller.dispose);
      await _pumpRegion(tester, DifferenceRegion(controller: controller));

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
      final controller = _FixedStateController(_stateWith(null));
      addTearDown(controller.dispose);
      await _pumpRegion(tester, CorrectionRegion(controller: controller));

      expect(find.byKey(CorrectionRegion.regionKey), findsOneWidget);
      expect(
        find.text('Check the mix to see the paints to add.'),
        findsOneWidget,
      );
    });

    testWidgets('renders a measured addition as the paint and its amount (AC-4)',
        (tester) async {
      final controller = _FixedStateController(_stateWith(const Correction(
        additions: [CorrectionAddition(paint: _white, parts: 0.5)],
      )));
      addTearDown(controller.dispose);
      await _pumpRegion(tester, CorrectionRegion(controller: controller));

      expect(find.text('Add to your mix:'), findsOneWidget);
      expect(find.text('Add about 0.5 parts of Titanium White'), findsOneWidget,
          reason: 'a measured addition names the paint and its amount');
      expect(find.textContaining('a touch of'), findsNothing,
          reason: 'a measured amount is not a trace');
    });

    testWidgets(
        'renders a trace addition as "a touch of" + its technique note (AC-5)',
        (tester) async {
      final controller = _FixedStateController(_stateWith(const Correction(
        additions: [
          CorrectionAddition(
            paint: _ochre,
            parts: 0.01,
            isTrace: true,
            techniqueNote: 'Add a little at a time and mix fully.',
          ),
        ],
      )));
      addTearDown(controller.dispose);
      await _pumpRegion(tester, CorrectionRegion(controller: controller));

      expect(find.text('a touch of Yellow Ochre'), findsOneWidget,
          reason: 'a trace renders "a touch of", not a numeric part');
      expect(find.text('Add a little at a time and mix fully.'), findsOneWidget,
          reason: 'the trace carries its static technique note (D-7)');
    });

    testWidgets('renders the no-correction state for an empty correction',
        (tester) async {
      final controller = _FixedStateController(_stateWith(const Correction()));
      addTearDown(controller.dispose);
      await _pumpRegion(tester, CorrectionRegion(controller: controller));

      expect(find.text('No paints to add.'), findsOneWidget);
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
