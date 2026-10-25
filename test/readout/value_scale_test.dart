import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/readout/value_scale.dart';

void main() {
  testWidgets('exposes the findable scale anchor (READOUT-2 shell)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ValueScale())),
    );
    expect(find.byKey(ValueScale.scaleKey), findsOneWidget);
  });
}
