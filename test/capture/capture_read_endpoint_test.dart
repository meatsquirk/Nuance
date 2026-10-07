import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_controller.dart';
import 'package:paint_color_assistant/capture/capture_read_endpoint.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

CaptureController _controller() => CaptureController(
      source: SoftwareCaptureSource(
        const SceneSpec(
          groundTruth: ColorCoordinates(lightness: 40, a: -8, b: 24),
        ),
      ),
    );

void main() {
  testWidgets('of() returns the controller from the nearest endpoint',
      (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    late CaptureController seen;

    await tester.pumpWidget(
      CaptureReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            seen = CaptureReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(identical(seen, controller), isTrue);
  });

  testWidgets('of() asserts when no endpoint is above the context',
      (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          expect(
            () => CaptureReadEndpoint.of(context),
            throwsA(isA<AssertionError>()),
          );
          return const SizedBox();
        },
      ),
    );
  });

  test('updateShouldNotify tracks the controller identity', () {
    final a = _controller();
    final b = _controller();
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    final withA =
        CaptureReadEndpoint(controller: a, child: const SizedBox());
    final alsoA =
        CaptureReadEndpoint(controller: a, child: const SizedBox());
    final withB =
        CaptureReadEndpoint(controller: b, child: const SizedBox());

    expect(withA.updateShouldNotify(withB), isTrue);
    expect(withA.updateShouldNotify(alsoA), isFalse);
  });

  test('exposes a stable key for the acceptance suite', () {
    expect(CaptureReadEndpoint.endpointKey, const Key('capture-read-endpoint'));
  });
}
