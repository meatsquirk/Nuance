import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/projects/confusion_pairs.dart';
import 'package:paint_color_assistant/projects/project.dart';

/// A [ConfusionCheck] that flags exactly the unordered coordinate pairs listed,
/// so `flagConfusionPairs` is tested for its pair-enumeration glue rather than
/// bs-03's CVD math (acceptance-tested against the real detector).
class _StubConfusionCheck implements ConfusionCheck {
  const _StubConfusionCheck(this._flagged);

  final Set<Set<ColorCoordinates>> _flagged;

  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile) =>
      _flagged.any((pair) => pair.length == 2 && pair.containsAll([a, b]));
}

Sample _sample(String name, double lightness) => Sample(
      name: name,
      coordinates: ColorCoordinates(lightness: lightness, a: 0, b: 0),
      provenance: const Provenance(ProvenanceTier.measured),
    );

Project _project(List<Sample> samples) =>
    Project(id: 'p', name: 'P', samples: samples);

const _profile = CvdProfile(type: CvdType.deutan);

void main() {
  group('flagConfusionPairs (PROJECT-5)', () {
    test('returns the confusable pair among the project\'s samples', () {
      final a = _sample('A', 40);
      final b = _sample('B', 41);
      final c = _sample('C', 80);
      final check = _StubConfusionCheck({
        {a.coordinates, b.coordinates},
      });

      final pairs = flagConfusionPairs(_project([a, b, c]), check, _profile);

      expect(pairs, hasLength(1));
      expect({pairs.single.a.name, pairs.single.b.name}, {'A', 'B'});
    });

    test('flags every confusable pair, skipping the distinct ones', () {
      final a = _sample('A', 40);
      final b = _sample('B', 41);
      final c = _sample('C', 42);
      // A/B and A/C collapse; B/C stays distinct.
      final check = _StubConfusionCheck({
        {a.coordinates, b.coordinates},
        {a.coordinates, c.coordinates},
      });

      final pairs = flagConfusionPairs(_project([a, b, c]), check, _profile);

      expect(pairs.map((p) => {p.a.name, p.b.name}).toList(), [
        {'A', 'B'},
        {'A', 'C'},
      ]);
    });

    test('returns empty when no pair collapses', () {
      final a = _sample('A', 40);
      final b = _sample('B', 80);
      final pairs = flagConfusionPairs(
          _project([a, b]), const _StubConfusionCheck({}), _profile);
      expect(pairs, isEmpty);
    });

    test('returns empty for a project with fewer than two samples', () {
      final one = flagConfusionPairs(
          _project([_sample('A', 40)]), const _StubConfusionCheck({}), _profile);
      final none = flagConfusionPairs(
          _project(const []), const _StubConfusionCheck({}), _profile);
      expect(one, isEmpty);
      expect(none, isEmpty);
    });
  });
}
