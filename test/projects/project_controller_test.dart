import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_controller.dart';
import 'package:paint_color_assistant/projects/project_source.dart';

const _harbor = Project(id: 'p-harbor', name: 'Harbor at Dusk');

void main() {
  test('lists the projects the source holds', () {
    final controller = ProjectController(
      source: const InMemoryProjectSource(catalogue: [_harbor]),
    );
    expect(controller.projects, [_harbor]);
  });

  test('a fresh install lists no projects', () {
    final controller =
        ProjectController(source: const InMemoryProjectSource());
    expect(controller.projects, isEmpty);
  });

  test('the shell has no opened project, no confusion pairs and no export', () {
    final controller =
        ProjectController(source: const InMemoryProjectSource());
    expect(controller.openedProject, isNull);
    expect(controller.confusionPairs, isEmpty);
    expect(controller.lastExport, isNull);
  });
}
