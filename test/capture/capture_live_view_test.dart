import 'package:flutter/material.dart' hide LockState;
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/capture/capture_eyedropper.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/widgets/surface_card.dart';

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

    // The accuracy region wraps its label text (so the tier word is findable
    // within the keyed region — see CaptureLiveView.accuracyKey).
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(CaptureLiveView.accuracyKey),
        matching: find.byType(Text),
      ),
    );
    expect(text.data, 'Calibrated');
  });

  testWidgets('shows the lock indicator "… AUTO" while unlocked',
      (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    final text =
        tester.widget<Text>(find.byKey(CaptureLiveView.lockIndicatorKey));
    expect(text.data, 'AE · AWB · AF AUTO');
  });

  testWidgets('shows the lock indicator "… LOCKED" once locked', (tester) async {
    await tester.pumpWidget(
      _host(const CaptureState(lockState: LockState.locked)),
    );

    final text =
        tester.widget<Text>(find.byKey(CaptureLiveView.lockIndicatorKey));
    expect(text.data, 'AE · AWB · AF LOCKED');
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

  testWidgets('renders the feed in colour (no filter) while value-only is off '
      '(AC-10)', (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    // No saturation filter sits over the feed surface while in colour.
    expect(
      find.ancestor(
        of: find.byKey(CaptureLiveView.liveViewKey),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
    );
  });

  testWidgets('wraps the feed in a grayscale ColorFiltered while value-only is '
      'on (AC-10)', (tester) async {
    await tester.pumpWidget(_host(const CaptureState(valueOnly: true)));

    // The feed surface is wrapped in a ColorFiltered so it renders grayscale;
    // the overlaid readings (laid beside it in the Stack) are not.
    expect(
      find.ancestor(
        of: find.byKey(CaptureLiveView.liveViewKey),
        matching: find.byType(ColorFiltered),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byKey(CaptureLiveView.stabilityKey),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
      reason: 'the text readings stay in colour, only the feed is grayscaled',
    );
  });

  // ---- bs-09: torch colour-temperature warning + marked points (SCREEN-1) ----

  testWidgets('hides the torch warning when none is set', (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    expect(find.byKey(CaptureLiveView.torchWarningKey), findsNothing);
  });

  testWidgets('shows the torch colour-temperature warning text when set (AC-1)',
      (tester) async {
    await tester.pumpWidget(_host(
      const CaptureState(torchWarning: 'Torch (~5000 K) may bias the reading'),
    ));

    expect(find.byKey(CaptureLiveView.torchWarningKey), findsOneWidget);
    final text =
        tester.widget<Text>(find.byKey(CaptureLiveView.torchWarningKey));
    expect(text.data, 'Torch (~5000 K) may bias the reading');
  });

  testWidgets('draws no marked points by default', (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    expect(
      find.byKey(CaptureLiveView.markedPointKey(const MarkedPoint(0, 0))),
      findsNothing,
    );
  });

  testWidgets('draws one marker per marked point at its frame position (AC-3)',
      (tester) async {
    const a = MarkedPoint(10, 20);
    const b = MarkedPoint(30, 40);
    await tester.pumpWidget(
      _host(const CaptureState(markedPoints: [a, b])),
    );

    for (final point in [a, b]) {
      final key = CaptureLiveView.markedPointKey(point);
      expect(find.byKey(key), findsOneWidget, reason: '$point marker missing');
      final positioned = tester.widget<Positioned>(
        find.ancestor(of: find.byKey(key), matching: find.byType(Positioned)),
      );
      expect(positioned.left, point.x.toDouble());
      expect(positioned.top, point.y.toDouble());
    }
  });

  testWidgets('a marked point carries a non-colour cue (semantic label)',
      (tester) async {
    // bs-11 AC-1/AC-2: the white marker must not convey its meaning by colour
    // alone — a Semantics label states it in words for a screen reader.
    const point = MarkedPoint(10, 20);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const CaptureState(markedPoints: [point])));

    expect(
      tester
          .getSemantics(find.byKey(CaptureLiveView.markedPointKey(point)))
          .label,
      'Marked sample point',
    );
    handle.dispose();
  });

  testWidgets('shows no downgrade-reasons region when nothing is downgraded',
      (tester) async {
    await tester.pumpWidget(_host(const CaptureState()));

    expect(find.byKey(CaptureLiveView.downgradeReasonsKey), findsNothing,
        reason: 'a trustworthy reading surfaces no downgrade reason');
  });

  testWidgets('surfaces each active downgrade reason in words (bs-12 AC-9)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CaptureLiveView(
            state: CaptureState(),
            downgradeReasons: {
              AccuracyDowngradeReason.exposureUnlocked,
              AccuracyDowngradeReason.missingReferenceCard,
            },
          ),
        ),
      ),
    );

    expect(find.byKey(CaptureLiveView.downgradeReasonsKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(CaptureLiveView.downgradeReasonsKey),
        matching: find.text(AccuracyDowngradeReason.exposureUnlocked.label),
      ),
      findsOneWidget,
      reason: 'the unlocked-exposure reason is named in words',
    );
    expect(
      find.descendant(
        of: find.byKey(CaptureLiveView.downgradeReasonsKey),
        matching: find.text(AccuracyDowngradeReason.missingReferenceCard.label),
      ),
      findsOneWidget,
      reason: 'the missing-card reason is named in words',
    );
  });

  // ---- READ-2 (AC-4): readings laid in a single non-overlapping vertical run

  testWidgets(
      'lays the live readings in a single vertical run that never overlaps, '
      'even at 200% text scale (AC-4)', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // A state that surfaces every reading/warning at once — the densest run.
    await tester.pumpWidget(_host(const CaptureState(
      stabilityCount: 6,
      lowLightWarning: true,
      torchWarning: 'Torch (~5000 K) may bias the reading',
    )));

    const keys = <Key>[
      CaptureLiveView.stabilityKey,
      CaptureLiveView.lockIndicatorKey,
      CaptureLiveView.accuracyKey,
      CaptureLiveView.warningKey,
      CaptureLiveView.torchWarningKey,
    ];
    final rects = {
      for (final key in keys) key: tester.getRect(find.byKey(key)),
    };
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        expect(
          rects[keys[i]]!.overlaps(rects[keys[j]]!),
          isFalse,
          reason: '${keys[i]} must not overlap ${keys[j]}',
        );
      }
    }
  });

  testWidgets('renders each live reading in a design-system SurfaceCard banner '
      '(AC-4)', (tester) async {
    await tester.pumpWidget(_host(const CaptureState(lowLightWarning: true)));

    // Each present reading sits inside a SurfaceCard (the wireframe banner).
    for (final key in const [
      CaptureLiveView.stabilityKey,
      CaptureLiveView.lockIndicatorKey,
      CaptureLiveView.accuracyKey,
      CaptureLiveView.warningKey,
    ]) {
      expect(
        find.ancestor(of: find.byKey(key), matching: find.byType(SurfaceCard)),
        findsOneWidget,
        reason: '$key renders in a SurfaceCard banner',
      );
    }
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
      CaptureLiveView.lockIndicatorKey,
      const ValueKey('capture-lock-indicator'),
    );
    expect(
      CaptureLiveView.warningKey,
      const ValueKey('capture-low-light-warning'),
    );
    expect(
      CaptureLiveView.downgradeReasonsKey,
      const ValueKey('capture-downgrade-reasons'),
    );
    expect(
      CaptureLiveView.torchWarningKey,
      const ValueKey('capture-torch-warning'),
    );
    expect(
      CaptureLiveView.markedPointKey(const MarkedPoint(3, 7)),
      const ValueKey('capture-marked-point-3-7'),
    );
  });
}
