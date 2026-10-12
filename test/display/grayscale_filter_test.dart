import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/display/grayscale_filter.dart';

void main() {
  group('GrayscaleFilter (shell: inert pass-through)', () {
    testWidgets('renders its child unchanged', (tester) async {
      await tester.pumpWidget(
        const GrayscaleFilter(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text('subject'),
          ),
        ),
      );
      expect(find.text('subject'), findsOneWidget);
      // Inert: no colour filter is applied yet (DISPLAY-7 adds it).
      expect(find.byType(ColorFiltered), findsNothing);
    });
  });
}
