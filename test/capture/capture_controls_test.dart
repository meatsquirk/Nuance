import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/widgets/pill_button.dart';

CaptureController _controller() => CaptureController(
      source: SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
        ),
      ),
    );

/// The text shown inside the torch toggle (its state-driven label).
String? _torchLabel(WidgetTester tester) => tester
    .widget<Text>(find.descendant(
      of: find.byKey(CaptureControls.torchKey),
      matching: find.byType(Text),
    ))
    .data;

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
      // Each option is a design-system pill (AC-3), not an ad-hoc TextButton.
      final option = tester.widget<PillButton>(
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
        tester.widget<PillButton>(find.byKey(CaptureControls.importKey));
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
        tester.widget<PillButton>(find.byKey(CaptureControls.valueOnlyKey));
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
    // E20 capture is the round shutter (a FilledButton, AC-3); dismiss and
    // calibrate are design-system pills.
    final shutter =
        tester.widget<FilledButton>(find.byKey(CaptureControls.captureKey));
    expect(shutter.onPressed, isNotNull, reason: 'E20 capture should be wired');
    for (final key in [
      CaptureControls.dismissWarningKey,
      CaptureControls.calibrateKey,
    ]) {
      final button = tester.widget<PillButton>(find.byKey(key));
      expect(button.onPressed, isNotNull, reason: '$key should be wired');
    }
    for (final key in [
      CaptureControls.captureKey,
      CaptureControls.dismissWarningKey,
      CaptureControls.calibrateKey,
    ]) {
      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: '$key reaches live behaviour, not a deferred throw');
    }
  });

  testWidgets('renders E20 capture as the ~88px round shutter button (AC-3)',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    // The shutter is a round ~88px button (rejects leaving it a small ad-hoc
    // text button), carrying the "Capture" screen-reader label its icon gives.
    final shutter = find.byKey(CaptureControls.captureKey);
    final size = tester.getSize(shutter);
    expect(size.width, closeTo(88, 4));
    expect(size.height, closeTo(88, 4));
    expect(tester.widget(shutter), isA<FilledButton>());
    expect(
      find.descendant(of: shutter, matching: find.byType(TextButton)),
      findsNothing,
    );
  });

  testWidgets('renders every capture control as a design-system component, '
      'not an ad-hoc TextButton (AC-3)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    // The action controls are pills; the shutter is the round FilledButton.
    // None is a bare TextButton any more (the full AC-3 swap).
    for (final key in [
      CaptureControls.dismissWarningKey,
      CaptureControls.lockKey,
      CaptureControls.calibrateKey,
      CaptureControls.importKey,
      CaptureControls.valueOnlyKey,
      CaptureControls.torchKey,
      CaptureControls.samplePointsKey,
      CaptureControls.sendToComparisonKey,
      for (final r in CaptureControls.radiusOptionsPx)
        CaptureControls.radiusOptionKey(r),
    ]) {
      final keyed = find.byKey(key);
      expect(keyed, findsOneWidget, reason: '$key renders');
      expect(tester.widget(keyed), isA<PillButton>(),
          reason: '$key renders as a design-system pill');
    }
    for (final key in [
      CaptureControls.captureKey,
      CaptureControls.dismissWarningKey,
      CaptureControls.torchKey,
      CaptureControls.radiusOptionKey(5),
    ]) {
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(TextButton)),
        findsNothing,
        reason: '$key is not an ad-hoc TextButton',
      );
    }
  });

  testWidgets('wires E16 to the live lock action (CAPTURE-3)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final button =
        tester.widget<PillButton>(find.byKey(CaptureControls.lockKey));
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

  // ---- bs-09 controls (SCREEN-1 shell: findable, wired to deferred stubs) ----

  testWidgets('renders the bs-09 torch, sample-points and send-to-comparison '
      'controls as findable buttons', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    for (final key in [
      CaptureControls.torchKey,
      CaptureControls.samplePointsKey,
      CaptureControls.sendToComparisonKey,
    ]) {
      expect(find.byKey(key), findsOneWidget, reason: '$key missing');
    }
  });

  testWidgets('the torch toggle reads "Torch" while off and lights it on a tap '
      '(CAPTURE-3)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pumpListening(tester, controller);

    // Off by default: the toggle reads "Torch".
    expect(controller.state.torchOn, isFalse);
    final button =
        tester.widget<PillButton>(find.byKey(CaptureControls.torchKey));
    expect(button.onPressed, isNotNull, reason: 'the torch toggle is wired');
    expect(_torchLabel(tester), 'Torch');

    // Tapping lights the torch (CAPTURE-3): the state flips, the warning is
    // raised, and the label re-renders to the lit branch.
    await tester.tap(find.byKey(CaptureControls.torchKey));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.state.torchOn, isTrue);
    expect(controller.state.torchWarning, isNotNull,
        reason: 'lighting the torch raises the colour-temperature warning');
    expect(_torchLabel(tester), '✓ Torch');
  });

  testWidgets('the torch toggle reads "✓ Torch" while lit and extinguishes it '
      'on a tap (CAPTURE-3)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pumpListening(tester, controller);
    // Light the torch so the lit branch renders (both label and onPressed flip).
    controller.turnTorchOn();
    await tester.pump();
    expect(_torchLabel(tester), '✓ Torch');

    // Tapping turns it off (CAPTURE-3): torch off, warning cleared, label back.
    await tester.tap(find.byKey(CaptureControls.torchKey));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.state.torchOn, isFalse);
    expect(controller.state.torchWarning, isNull,
        reason: 'extinguishing clears the colour-temperature warning');
    expect(_torchLabel(tester), 'Torch');
  });

  testWidgets('"Sample points" drives the live sampleMarkedPoints '
      '(AC-3, CAPTURE-4)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    final button =
        tester.widget<PillButton>(find.byKey(CaptureControls.samplePointsKey));
    expect(button.onPressed, isNotNull);

    // Multi-point sampling is live as of CAPTURE-4: a tap reaches real
    // behaviour and raises no deferred throw.
    await tester.tap(find.byKey(CaptureControls.samplePointsKey));
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'multi-point sampling is live — not a deferred throw');
  });

  testWidgets('"Send to comparison" drives the live sendPairToComparison '
      '(AC-5, CAPTURE-5)', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await _pump(tester, controller);
    await tester.pumpAndSettle(); // the live feed buffers a frame to sample

    // Two marked, sampled readings exist for the placeholder (0, 1) index pair
    // the SCREEN-1 button carries.
    controller
      ..markPoint(2, 2)
      ..markPoint(6, 6)
      ..sampleMarkedPoints();

    final button = tester
        .widget<PillButton>(find.byKey(CaptureControls.sendToComparisonKey));
    expect(button.onPressed, isNotNull);

    // The send is live as of CAPTURE-5: a tap reaches real behaviour (no
    // deferred throw) and publishes the pair for the screen to open.
    await tester.tap(find.byKey(CaptureControls.sendToComparisonKey));
    await tester.pump();
    expect(tester.takeException(), isNull,
        reason: 'send-to-comparison is live — not a deferred throw');
    expect(controller.state.pairToCompare, isNotNull,
        reason: 'the tap publishes the pair for the comparison handoff');
  });

  test('exposes stable keys for the bs-09 controls', () {
    expect(CaptureControls.torchKey, const ValueKey('capture-torch'));
    expect(CaptureControls.samplePointsKey,
        const ValueKey('capture-sample-points'));
    expect(CaptureControls.sendToComparisonKey,
        const ValueKey('capture-send-to-comparison'));
  });
}
