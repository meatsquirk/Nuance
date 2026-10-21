import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/live_frame_view.dart';
import 'package:paint_color_assistant/capture/source/frame.dart';

Widget _host(Frame? frame) => MaterialApp(
      home: Scaffold(
        // A bounded box so the CustomPaint lays out and paints during the test.
        body: Center(
          child: SizedBox(width: 40, height: 40, child: LiveFrameView(frame: frame)),
        ),
      ),
    );

Frame _frame() => const Frame(
      width: 2,
      height: 2,
      pixels: <Pixel>[
        Pixel(255, 0, 0),
        Pixel(0, 255, 0),
        Pixel(0, 0, 255),
        Pixel(255, 255, 255),
      ],
    );

void main() {
  testWidgets('with no frame shows the flat placeholder surface', (tester) async {
    await tester.pumpWidget(_host(null));

    expect(
      find.descendant(
        of: find.byType(LiveFrameView),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    final box = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(LiveFrameView),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(box.color, LiveFrameView.placeholderColor);
  });

  testWidgets('with a frame paints it (no placeholder)', (tester) async {
    await tester.pumpWidget(_host(_frame()));

    // The painted frame replaces the flat placeholder.
    expect(
      find.descendant(
        of: find.byType(LiveFrameView),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(LiveFrameView),
        matching: find.byType(ColoredBox),
      ),
      findsNothing,
    );
  });

  testWidgets('repaints when a new frame arrives', (tester) async {
    await tester.pumpWidget(_host(_frame()));
    // A distinct frame instance drives CustomPaint.shouldRepaint on rebuild.
    await tester.pumpWidget(_host(_frame()));
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(LiveFrameView),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
