import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/projects/project_controller.dart';
import 'package:paint_color_assistant/projects/project_read_endpoint.dart';
import 'package:paint_color_assistant/projects/project_source.dart';

ProjectController _controller() =>
    ProjectController(source: const InMemoryProjectSource());

void main() {
  testWidgets('of() returns the controller exposed above a descendant',
      (tester) async {
    final controller = _controller();
    late ProjectController seen;
    await tester.pumpWidget(
      ProjectReadEndpoint(
        controller: controller,
        child: Builder(
          builder: (context) {
            seen = ProjectReadEndpoint.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(identical(seen, controller), isTrue);
  });

  testWidgets('is findable by its stable endpoint key', (tester) async {
    await tester.pumpWidget(
      ProjectReadEndpoint(
        key: ProjectReadEndpoint.endpointKey,
        controller: _controller(),
        child: const SizedBox(),
      ),
    );
    expect(find.byKey(ProjectReadEndpoint.endpointKey), findsOneWidget);
  });

  test('updateShouldNotify tracks whether the controller changed', () {
    final a =
        ProjectReadEndpoint(controller: _controller(), child: const SizedBox());
    final b =
        ProjectReadEndpoint(controller: _controller(), child: const SizedBox());
    final shared = _controller();
    final c = ProjectReadEndpoint(controller: shared, child: const SizedBox());
    final d = ProjectReadEndpoint(controller: shared, child: const SizedBox());
    expect(a.updateShouldNotify(b), isTrue);
    expect(c.updateShouldNotify(d), isFalse);
  });
}
