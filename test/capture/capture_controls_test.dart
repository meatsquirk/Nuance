import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

CaptureController _controller() => CaptureController(
      source: SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, CaptureController controller) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CaptureControls(controller: controller))),
    );

void main() {
  testWidgets('renders every E15–E21 control as a findable button',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    for (final key in [
      CaptureControls.dismissWarningKey,
      CaptureControls.lockKey,
      CaptureControls.calibrateKey,
      CaptureControls.radiusKey,
      CaptureControls.importKey,
      CaptureControls.captureKey,
      CaptureControls.valueOnlyKey,
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: '$key missing');
    }
  });

  testWidgets('leaves E18 (radius) a disabled placeholder', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final radius =
        tester.widget<TextButton>(find.byKey(CaptureControls.radiusKey));
    expect(radius.onPressed, isNull);
  });

  testWidgets('wires E19 (import) to the controller import action (SOURCE-3)',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final import =
        tester.widget<TextButton>(find.byKey(CaptureControls.importKey));
    expect(import.onPressed, isNotNull,
        reason: 'E19 is enabled and reaches controller.importPhoto');

    // Tapping with no photo staged is a no-op — the import action is real
    // (SOURCE-3), not a deferred throw, so it raises no exception.
    await tester.tap(find.byKey(CaptureControls.importKey));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('wires E21 to its (still-deferred) controller action',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    // E21 (value-only) is the one control whose behaviour is still deferred — a
    // tap surfaces its owning phase's (SCREEN-3) UnimplementedError. (E16 lock
    // is live as of CAPTURE-3, E15 dismiss + E20 capture as of CAPTURE-4, E17
    // calibrate as of CAPTURE-5 — all asserted separately below.)
    final button =
        tester.widget<TextButton>(find.byKey(CaptureControls.valueOnlyKey));
    expect(button.onPressed, isNotNull, reason: 'E21 should be wired');

    await tester.tap(find.byKey(CaptureControls.valueOnlyKey));
    await tester.pump();
    expect(
      tester.takeException(),
      isA<UnimplementedError>(),
      reason: 'E21 should reach the deferred controller action',
    );
  });

  testWidgets(
      'wires E15 (dismiss), E20 (capture) and E17 (calibrate) to live actions',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    // All three reach real behaviour now — a tap raises no deferred throw
    // (commit + dismiss landed in CAPTURE-4; E17 calibrate in CAPTURE-5, a no-op
    // here since this controls-only harness has no reference card in view).
    for (final key in [
      CaptureControls.captureKey,
      CaptureControls.dismissWarningKey,
      CaptureControls.calibrateKey,
    ]) {
      final button = tester.widget<TextButton>(find.byKey(key));
      expect(button.onPressed, isNotNull, reason: '$key should be wired');

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: '$key reaches live behaviour, not a deferred throw');
    }
  });

  testWidgets('wires E16 to the live lock action (CAPTURE-3)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final button =
        tester.widget<TextButton>(find.byKey(CaptureControls.lockKey));
    expect(button.onPressed, isNotNull, reason: 'E16 lock should be wired');

    await tester.tap(find.byKey(CaptureControls.lockKey));
    await tester.pump();

    // Lock is real behaviour now — no deferred throw, and the reading locks.
    expect(tester.takeException(), isNull);
    expect(controller.state.lockState, LockState.locked);
  });

  test('exposes a stable key per wireframe element', () {
    expect(CaptureControls.dismissWarningKey,
        const ValueKey('capture-e15-dismiss-warning'));
    expect(CaptureControls.lockKey, const ValueKey('capture-e16-lock'));
    expect(
        CaptureControls.calibrateKey, const ValueKey('capture-e17-calibrate'));
    expect(CaptureControls.radiusKey, const ValueKey('capture-e18-radius'));
    expect(CaptureControls.importKey, const ValueKey('capture-e19-import'));
    expect(CaptureControls.captureKey, const ValueKey('capture-e20-capture'));
    expect(CaptureControls.valueOnlyKey,
        const ValueKey('capture-e21-value-only'));
  });
}
