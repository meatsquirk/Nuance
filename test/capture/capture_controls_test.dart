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

/// Pumps the controls in a tree that listens to [controller], so a control that
/// changes state (the radius selector) re-renders exactly as the Capture screen
/// rebuilds it.
Future<void> _pumpListening(
  WidgetTester tester,
  CaptureController controller,
) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (_, _) => CaptureControls(controller: controller),
          ),
        ),
      ),
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

  testWidgets('renders the E18 radius selector with an enabled option per '
      'radius (1 / 5 / 21 px)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    expect(CaptureControls.radiusOptionsPx, [1, 5, 21]);
    for (final radiusPx in CaptureControls.radiusOptionsPx) {
      final option = tester.widget<TextButton>(
          find.byKey(CaptureControls.radiusOptionKey(radiusPx)));
      expect(option.onPressed, isNotNull,
          reason: 'the $radiusPx px option is selectable');
    }
    // The option anchors live inside the E18 region.
    expect(
      find.descendant(
        of: find.byKey(CaptureControls.radiusKey),
        matching: find.byKey(CaptureControls.radiusOptionKey(21)),
      ),
      findsOneWidget,
    );
  });

  testWidgets('E18 marks the selected radius and drives controller.setRadius',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pumpListening(tester, controller);

    // The 5 px default is marked; the others are not (both label branches).
    expect(controller.state.radiusPx, 5);
    expect(find.text('✓ 5 px'), findsOneWidget);
    expect(find.text('1 px'), findsOneWidget);
    expect(find.text('21 px'), findsOneWidget);

    // Selecting the 21 px option sets the radius and moves the mark to it.
    await tester.tap(find.byKey(CaptureControls.radiusOptionKey(21)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.state.radiusPx, 21);
    expect(find.text('✓ 21 px'), findsOneWidget);
    expect(find.text('5 px'), findsOneWidget);
  });

  test('exposes a stable per-option anchor under the E18 key', () {
    expect(CaptureControls.radiusOptionKey(5),
        const ValueKey('capture-e18-radius-5'));
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

  testWidgets('wires E21 to the live value-only toggle and flips its label '
      '(SCREEN-3, AC-10)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pumpListening(tester, controller);

    // E21 (value-only) is wired and live as of SCREEN-3 — a tap drives the
    // toggle and raises no deferred throw. (E16 lock is live as of CAPTURE-3,
    // E15 dismiss + E20 capture as of CAPTURE-4, E17 calibrate as of CAPTURE-5.)
    final button =
        tester.widget<TextButton>(find.byKey(CaptureControls.valueOnlyKey));
    expect(button.onPressed, isNotNull, reason: 'E21 should be wired');

    // Off: reads "Value".
    Text label() => tester.widget<Text>(find.descendant(
        of: find.byKey(CaptureControls.valueOnlyKey), matching: find.byType(Text)));
    expect(label().data, 'Value');

    // Tapping turns value-only on and flips the label to "✓ Value".
    await tester.tap(find.byKey(CaptureControls.valueOnlyKey));
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'E21 reaches live behaviour, not a deferred throw');
    expect(controller.state.valueOnly, isTrue);
    expect(label().data, '✓ Value');

    // Tapping again turns it off and restores "Value".
    await tester.tap(find.byKey(CaptureControls.valueOnlyKey));
    await tester.pump();
    expect(controller.state.valueOnly, isFalse);
    expect(label().data, 'Value');
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
