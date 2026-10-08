import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';

const _terracotta = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

void main() {
  group('InMemorySampleSource', () {
    test('defaults to an empty catalogue', () {
      expect(const InMemorySampleSource().savedSamples(), isEmpty);
    });

    test('lists the samples it was seeded with, in order', () {
      const other = Sample(
        name: 'Raw Sienna Light',
        coordinates: ColorCoordinates(lightness: 70, a: 12.5, b: 21.65),
        provenance: Provenance(ProvenanceTier.measured),
      );
      const source = InMemorySampleSource(samples: [_terracotta, other]);
      expect(source.savedSamples(), [_terracotta, other]);
    });

    test('exposes the catalogue read-only (callers cannot mutate it)', () {
      const source = InMemorySampleSource(samples: [_terracotta]);
      expect(
        () => source.savedSamples().add(_terracotta),
        throwsUnsupportedError,
      );
    });
  });
}
