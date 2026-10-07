import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';

Widget _host(CaptureState state) => MaterialApp(
      home: Scaffold(body: CaptureLiveView(state: state)),
    );

void main() {
  testWidgets('renders the feed surface and the centre eyedropper over it',
      (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    expect(find.byKey(CaptureLiveView.liveViewKey), findsOneWidget);
    expect(find.byKey(CaptureEyedropper.eyedropperKey), findsOneWidget);
  });

  testWidgets('shows the stability indicator text from the state',
      (tester) async {
    await tester.pumpWidget(_host(const CaptureState(stabilityCount: 6)));

    final text = tester.widget<Text>(find.byKey(CaptureLiveView.stabilityKey));
    expect(text.data, 'SETTLING 6/12');
  });

  testWidgets('shows the accuracy label as text', (tester) async {
    await tester.pumpWidget(
      _host(const CaptureState(accuracy: CaptureAccuracy.calibrated)),
    );

    final text = tester.widget<Text>(find.byKey(CaptureLiveView.accuracyKey));
    expect(text.data, 'Calibrated');
  });

  testWidgets('hides the low-light warning when there is none', (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    // The warning text is laid out but not shown (Visibility false).
    expect(find.byKey(CaptureLiveView.warningKey), findsNothing);
  });

  testWidgets('shows the low-light warning as text when set', (tester) async {
    await tester.pumpWidget(_host(const CaptureState(lowLightWarning: true)));

    expect(find.byKey(CaptureLiveView.warningKey), findsOneWidget);
    final text = tester.widget<Text>(find.byKey(CaptureLiveView.warningKey));
    expect(text.data, contains('Low light'));
  });

  test('exposes stable keys', () {
    expect(CaptureLiveView.liveViewKey, const ValueKey('capture-live-view'));
    expect(
      CaptureLiveView.stabilityKey,
      const ValueKey('capture-stability-indicator'),
    );
    expect(
      CaptureLiveView.accuracyKey,
      const ValueKey('capture-accuracy-label'),
    );
    expect(
      CaptureLiveView.warningKey,
      const ValueKey('capture-low-light-warning'),
    );
  });
}
