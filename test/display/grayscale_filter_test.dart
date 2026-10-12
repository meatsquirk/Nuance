import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_scope.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/display/grayscale_filter.dart';

/// The saturation-0 Rec. 709 luma matrix the filter uses, rebuilt here so the
/// test grades the applied filter against an independent copy.
const ColorFilter _expectedDesaturate = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

void main() {
  group('GrayscaleFilter (AC-6: root value-only grayscale)', () {
    // Pumps the filter under a DisplayScope over [controller], mirroring how
    // buildApp places it (below the scope, wrapping the app).
    Future<void> pump(WidgetTester tester, DisplayController controller) {
      return tester.pumpWidget(
        DisplayScope(
          controller: controller,
          child: const GrayscaleFilter(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text('subject'),
            ),
          ),
        ),
      );
    }

    testWidgets('grayscale off: passes the child through with no filter',
        (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await pump(tester, controller);

      expect(find.text('subject'), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNothing,
          reason: 'no app-wide desaturation when grayscale is off');
    });

    testWidgets('grayscale on: wraps the child in a saturation-0 ColorFiltered',
        (tester) async {
      final controller = DisplayController(
        initialSettings: const DisplaySettings(grayscale: true),
      );
      addTearDown(controller.dispose);
      await pump(tester, controller);

      expect(find.text('subject'), findsOneWidget);
      final filtered = tester.widget<ColorFiltered>(find.byType(ColorFiltered));
      expect(filtered.colorFilter, _expectedDesaturate,
          reason: 'the whole app is greyed by one saturation-0 root filter');
    });

    testWidgets('reacts to the grayscale toggle (one root, both directions)',
        (tester) async {
      final controller = DisplayController();
      addTearDown(controller.dispose);
      await pump(tester, controller);
      expect(find.byType(ColorFiltered), findsNothing);

      controller.setGrayscale(true);
      await tester.pump();
      expect(find.byType(ColorFiltered), findsOneWidget,
          reason: 'turning grayscale on greys the app at the root');

      controller.setGrayscale(false);
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing,
          reason: 'turning grayscale off removes the app-wide filter');
    });

    testWidgets('toggling grayscale reparents (does not remount) the app',
        (tester) async {
      _InitCounter.inits = 0;
      final controller = DisplayController();
      addTearDown(controller.dispose);
      // A child that counts its own initState: a remount would run it again.
      await tester.pumpWidget(
        DisplayScope(
          controller: controller,
          child: const GrayscaleFilter(child: _InitCounter()),
        ),
      );
      tester.state<_InitCounterState>(find.byType(_InitCounter)).bumped = 1;
      expect(_InitCounter.inits, 1, reason: 'mounted once');

      controller.setGrayscale(true); // wrap under ColorFiltered
      await tester.pump();
      controller.setGrayscale(false); // unwrap again
      await tester.pump();

      expect(_InitCounter.inits, 1,
          reason: 'the app element is reparented, not remounted, on toggle');
      // Same State instance survived both toggles (its mutation is intact).
      expect(
        tester.state<_InitCounterState>(find.byType(_InitCounter)).bumped,
        1,
        reason: 'child state preserved across the grayscale toggle',
      );
    });
  });
}

/// A leaf whose [State] counts how many times it is mounted, so a test can prove
/// the grayscale toggle reparents rather than remounts the subtree below it.
class _InitCounter extends StatefulWidget {
  const _InitCounter();

  static int inits = 0;

  @override
  State<_InitCounter> createState() => _InitCounterState();
}

class _InitCounterState extends State<_InitCounter> {
  int bumped = 0;

  @override
  void initState() {
    super.initState();
    _InitCounter.inits++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
