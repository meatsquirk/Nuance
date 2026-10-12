import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/palette/palette_read_endpoint.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

PaletteController _controller() =>
    PaletteController(source: const InMemoryPaletteSource());

void main() {
  testWidgets('of() returns the controller exposed above a descendant',
      (tester) async {
    final controller = _controller();
    late PaletteController seen;
    await tester.pumpWidget(
      PaletteReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            seen = PaletteReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, controller), isTrue);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      PaletteReadEndpoint(
        key: PaletteReadEndpoint.endpointKey,
        controller: _controller(),
        child: const SizedBox(),
      ),
    );
    expect(find.byKey(PaletteReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks whether the controller changed', () {
    final a =
        PaletteReadEndpoint(controller: _controller(), child: const SizedBox());
    final b =
        PaletteReadEndpoint(controller: _controller(), child: const SizedBox());
    final shared = _controller();
    final c = PaletteReadEndpoint(controller: shared, child: const SizedBox());
    final d = PaletteReadEndpoint(controller: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
