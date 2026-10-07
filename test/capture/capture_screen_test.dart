import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_screen.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

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

  testWidgets('binds the live view to the controller state', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

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
}
