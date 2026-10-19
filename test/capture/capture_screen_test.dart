import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_readings_list.dart';
import 'package:paint_color_assistant/capture/capture_screen.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/widgets/swatch_caption.dart';

/// A controller that can push a state through the protected [emit] seam, so the
/// screen's rebuild-on-change can be driven without the deferred actions.
class _DrivableController extends CaptureController {
  _DrivableController(CaptureSource source) : super(source: source);

  void push(CaptureState next) => emit(next);
}

_DrivableController _controller() => _DrivableController(
      SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, CaptureController controller) =>
    tester.pumpWidget(MaterialApp(home: CaptureScreen(controller: controller)));

/// Pumps the screen inside an [AppScope] so the live-reading swatch renders
/// (it needs a colour-science scope); used by the AC-15 caption cases.
Future<void> _pumpScoped(WidgetTester tester, CaptureController controller) =>
    tester.pumpWidget(
      MaterialApp(
        home: AppScope(
          dependencies: const AppDependencies(
            colorScience: ColorScienceImpl(),
            speech: NoopSpeech(),
            haptics: NoopHaptics(),
          ),
          child: CaptureScreen(controller: controller),
        ),
      ),
    );

const Sample _sample = Sample(
  coordinates: ColorCoordinates(lightness: 55, a: -25, b: 30),
  provenance: Provenance(ProvenanceTier.measured),
);

void main() {
  testWidgets('renders the Capture app bar', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget);
  });

  testWidgets('composes the live view over the controls', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(find.byType(CaptureLiveView), findsOneWidget);
    expect(find.byType(CaptureControls), findsOneWidget);
  });

  testWidgets('places the bs-09 readings region bound to the state (SCREEN-1)',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final list = tester
        .widget<CaptureReadingsList>(find.byType(CaptureReadingsList));
    // Bound to the controller's marked readings (empty in this shell).
    expect(identical(list.readings, controller.state.markedReadings), isTrue);
    expect(list.readings, isEmpty);
  });

  testWidgets('binds the live view to the controller state', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    // Lock first so the per-frame settling tick (CAPTURE-3) stops mutating the
    // state; the rendered live view then holds exactly the controller's state.
    controller.lock();
    await tester.pump();

    final view = tester.widget<CaptureLiveView>(find.byType(CaptureLiveView));
    expect(identical(view.state, controller.state), isTrue);
  });

  testWidgets('rebuilds when the controller state changes', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(
      tester.widget<Text>(find.byKey(CaptureLiveView.stabilityKey)).data,
      'SETTLING 0/12',
    );

    controller.push(const CaptureState(stabilityCount: 6));
    await tester.pump();

    expect(
      tester.widget<Text>(find.byKey(CaptureLiveView.stabilityKey)).data,
      'SETTLING 6/12',
    );
  });

  testWidgets('shows the swatch approximation caption once a reading is sampled '
      '(AC-15)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pumpScoped(tester, controller);
    // Lock to stop the settling tick so the pushed state is the one rendered.
    controller.lock();
    await tester.pump();

    // No sample → the live swatch and its caption are both absent.
    controller.push(const CaptureState());
    await tester.pump();
    expect(find.byType(SwatchCaption), findsNothing);

    // A sampled reading renders a swatch, so the caption accompanies it — once.
    controller.push(const CaptureState(currentSample: _sample));
    await tester.pump();
    expect(find.byType(SwatchCaption), findsOneWidget);
  });

  testWidgets('shows no caption without a colour-science scope, even with a '
      'reading (no swatch to caption) (AC-15)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    // No AppScope → CaptureCurrentReading draws no swatch, so no caption either.
    await _pump(tester, controller);
    controller.lock();
    controller.push(const CaptureState(currentSample: _sample));
    await tester.pump();
    expect(find.byType(SwatchCaption), findsNothing);
  });
}
