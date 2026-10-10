import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/correction/correction_controller.dart';
import 'package:paint_color_assistant/correction/correction_read_endpoint.dart';
import 'package:paint_color_assistant/correction/engine/correction_engine_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

const _olive = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 42, a: -5, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);
const _white = Paint(
  id: 'pw6',
  name: 'Titanium White',
  medium: PaintMedium.acrylic,
  masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
);
const _mix = Recipe(
  medium: PaintMedium.acrylic,
  components: [RecipeComponent(paint: _white, partsFraction: 1)],
  predictedColor: ColorCoordinates(lightness: 96, a: 0, b: 2),
  deltaE00: 1.2,
);

class _InertCaptureSource implements CaptureSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

CorrectionController _controller() => CorrectionController(
      captureSource: _InertCaptureSource(),
      target: _olive,
      currentMix: _mix,
      paletteSource: const InMemoryPaletteSource(),
      correctionEngine: const SubtractiveCorrectionEngine(),
    );

void main() {
  testWidgets('of() returns the controller exposed above a descendant',
      (tester) async {
    final controller = _controller();
    late CorrectionController seen;
    await tester.pumpWidget(
      CorrectionReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            seen = CorrectionReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, controller), isTrue);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      CorrectionReadEndpoint(
        key: CorrectionReadEndpoint.endpointKey,
        controller: _controller(),
        child: const SizedBox(),
      ),
    );
    expect(find.byKey(CorrectionReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks whether the controller changed', () {
    final a =
        CorrectionReadEndpoint(controller: _controller(), child: const SizedBox());
    final b =
        CorrectionReadEndpoint(controller: _controller(), child: const SizedBox());
    final shared = _controller();
    final c = CorrectionReadEndpoint(controller: shared, child: const SizedBox());
    final d = CorrectionReadEndpoint(controller: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
