import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_readings_list.dart';
import 'package:paint_color_assistant/capture/capture_state.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';

Widget _host(List<MultiPointReading> readings) => MaterialApp(
      home: Scaffold(body: CaptureReadingsList(readings: readings)),
    );

const _r0 = MultiPointReading(
  position: MarkedPoint(10, 20),
  coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
);
const _r1 = MultiPointReading(
  position: MarkedPoint(30, 40),
  coordinates: ColorCoordinates(lightness: 55, a: 12, b: -6),
);

void main() {
  testWidgets('renders the readings region even when empty (SCREEN-1 shell)',
      (tester) async {
    await tester.pumpWidget(_host(const []));

    expect(find.byKey(CaptureReadingsList.readingsListKey), findsOneWidget);
    // No reading rows before any point is sampled.
    expect(find.byType(ColorChip), findsNothing);
  });

  testWidgets('renders one labelled ColorChip row per reading (AC-4)',
      (tester) async {
    await tester.pumpWidget(_host(const [_r0, _r1]));

    // Each reading is a ColorChip — a reading is never a bare swatch.
    expect(find.byType(ColorChip), findsNWidgets(2));
    expect(find.byKey(CaptureReadingsList.readingKey(0)), findsOneWidget);
    expect(find.byKey(CaptureReadingsList.readingKey(1)), findsOneWidget);
  });

  testWidgets('each row keeps its own position and its own value (AC-4)',
      (tester) async {
    await tester.pumpWidget(_host(const [_r0, _r1]));

    final first =
        tester.widget<ColorChip>(find.byKey(CaptureReadingsList.readingKey(0)));
    final second =
        tester.widget<ColorChip>(find.byKey(CaptureReadingsList.readingKey(1)));

    // Distinct positions kept.
    expect(first.label, contains('(10, 20)'));
    expect(second.label, contains('(30, 40)'));
    // Distinct values kept (each row shows its own CIELAB value).
    expect(first.label, contains('L 40.0 a -8.0 b 24.0'));
    expect(second.label, contains('L 55.0 a 12.0 b -6.0'));
    expect(first.label, isNot(second.label));
  });

  test('exposes stable keys', () {
    expect(CaptureReadingsList.readingsListKey,
        const ValueKey('capture-readings-list'));
    expect(
        CaptureReadingsList.readingKey(2), const ValueKey('capture-reading-2'));
  });
}
