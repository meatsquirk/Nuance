import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/projects/project.dart';

const _sample = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 40, a: 6, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

void main() {
  test('defaults everything a project accrues to absent/empty', () {
    const project = Project(id: 'p1', name: 'Harbor at Dusk');
    expect(project.id, 'p1');
    expect(project.name, 'Harbor at Dusk');
    expect(project.size, isNull);
    expect(project.samples, isEmpty);
    expect(project.recipes, isEmpty);
    expect(project.note, isNull);
    expect(project.sourcePhotoRef, isNull);
    expect(project.lastEdited, isNull);
  });

  test('copyWith replaces only the fields it is given', () {
    const base = Project(id: 'p1', name: 'Harbor at Dusk');
    final edited = base.copyWith(
      size: '24×30 in',
      samples: const [_sample],
      note: 'Keep the values 2 steps apart.',
      sourcePhotoRef: 'photos/harbor.jpg',
      lastEdited: DateTime.utc(2026, 10, 10),
    );
    expect(edited.id, 'p1'); // kept
    expect(edited.name, 'Harbor at Dusk'); // kept
    expect(edited.size, '24×30 in');
    expect(edited.samples, [_sample]);
    expect(edited.note, 'Keep the values 2 steps apart.');
    expect(edited.sourcePhotoRef, 'photos/harbor.jpg');
    expect(edited.lastEdited, DateTime.utc(2026, 10, 10));
  });

  test('copyWith with no arguments keeps every field', () {
    final base = Project(
      id: 'p1',
      name: 'Harbor at Dusk',
      size: '24×30 in',
      samples: const [_sample],
      note: 'a note',
      sourcePhotoRef: 'photos/harbor.jpg',
      lastEdited: DateTime.utc(2026, 10, 10),
    );
    final copy = base.copyWith();
    expect(copy.id, base.id);
    expect(copy.name, base.name);
    expect(copy.size, base.size);
    expect(copy.samples, base.samples);
    expect(copy.recipes, base.recipes);
    expect(copy.note, base.note);
    expect(copy.sourcePhotoRef, base.sourcePhotoRef);
    expect(copy.lastEdited, base.lastEdited);
  });

  test('toString names the project and its counts', () {
    const project = Project(id: 'p1', name: 'Harbor at Dusk', samples: [_sample]);
    expect(project.toString(), 'Project(p1 "Harbor at Dusk", 1 samples, 0 recipes)');
  });
}
