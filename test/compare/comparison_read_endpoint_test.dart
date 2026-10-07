import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/compare/comparison_controller.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';

ComparisonController _controller() => ComparisonController(
      sampleSource: const InMemorySampleSource(),
      confusionCheck: const NoopConfusionCheck(),
      profile: const CvdProfile(type: CvdType.deutan),
    );

void main() {
  testWidgets('of() returns the controller exposed above a descendant',
      (tester) async {
    final controller = _controller();
    late ComparisonController seen;
    await tester.pumpWidget(
      ComparisonReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            seen = ComparisonReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, controller), isTrue);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      ComparisonReadEndpoint(
        key: ComparisonReadEndpoint.endpointKey,
        controller: _controller(),
        child: const SizedBox(),
      ),
    );
    expect(find.byKey(ComparisonReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks whether the controller changed', () {
    final a = ComparisonReadEndpoint(
      controller: _controller(),
      child: const SizedBox(),
    );
    final b = ComparisonReadEndpoint(
      controller: _controller(),
      child: const SizedBox(),
    );
    final shared = _controller();
    final c = ComparisonReadEndpoint(controller: shared, child: const SizedBox());
    final d = ComparisonReadEndpoint(controller: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
