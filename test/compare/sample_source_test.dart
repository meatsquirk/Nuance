import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/capture/capture_accuracy.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

const _terracotta = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A fully-populated sample — a named, just-captured, calibrated reading with a
/// provenance note and an evidence point — so the round-trip exercises every
/// optional field.
const _full = Sample(
  name: 'Ultramarine Shadow',
  coordinates: ColorCoordinates(lightness: 32, a: 8, b: -40),
  provenance: Provenance(ProvenanceTier.confirmed, note: 'you measured this'),
  justCaptured: true,
  accuracy: CaptureAccuracy.calibrated,
  evidence: [
    EvidencePoint(
      coordinates: ColorCoordinates(lightness: 32.1, a: 7.8, b: -40.2),
      source: 'spectro-01',
    ),
  ],
);

/// A minimal sample — no name, not captured, no accuracy, no note, no evidence —
/// so the round-trip exercises the null/empty branches too.
const _minimal = Sample(
  coordinates: ColorCoordinates(lightness: 70, a: 12.5, b: 21.65),
  provenance: Provenance(ProvenanceTier.measured),
);

void _expectSameSample(Sample got, Sample want) {
  expect(got.coordinates, want.coordinates);
  expect(got.provenance, want.provenance);
  expect(got.name, want.name);
  expect(got.justCaptured, want.justCaptured);
  expect(got.accuracy, want.accuracy);
  expect(got.evidence, want.evidence);
}

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

  group('sampleToJson / sampleFromJson', () {
    test('round-trips a fully-populated sample, every field intact', () {
      _expectSameSample(sampleFromJson(sampleToJson(_full)), _full);
    });

    test('round-trips a minimal sample (null/empty optionals)', () {
      _expectSameSample(sampleFromJson(sampleToJson(_minimal)), _minimal);
    });
  });

  group('PersistentSampleSource', () {
    test('lists nothing before anything is saved', () async {
      final source = PersistentSampleSource(InMemoryPersistentStore());
      await source.load();
      expect(source.savedSamples(), isEmpty);
    });

    test('round-trips a saved sample through the store, every field intact',
        () async {
      final store = InMemoryPersistentStore();
      final source = PersistentSampleSource(store);
      await source.saveSample('s1', _full);

      // A fresh source over the same store proves it persisted (not cached).
      final reloaded = PersistentSampleSource(store);
      await reloaded.load();
      _expectSameSample(reloaded.savedSamples().single, _full);
    });

    test('lists samples in ascending id order and replaces by id', () async {
      final store = InMemoryPersistentStore();
      final source = PersistentSampleSource(store);
      await source.saveSample('s2', _minimal);
      await source.saveSample('s1', _full);
      final listed = source.savedSamples();
      expect(listed, hasLength(2));
      _expectSameSample(listed[0], _full); // "s1" sorts before "s2"
      _expectSameSample(listed[1], _minimal);

      // Re-saving the same id replaces rather than duplicates.
      await source.saveSample('s1', _minimal);
      expect(source.savedSamples(), hasLength(2));
      _expectSameSample(source.savedSamples()[0], _minimal);
    });

    test('exposes the cache read-only (callers cannot mutate it)', () async {
      final source = PersistentSampleSource(InMemoryPersistentStore());
      await source.saveSample('s1', _full);
      expect(
        () => source.savedSamples().add(_minimal),
        throwsUnsupportedError,
      );
    });

    test('exposes its store collection name', () {
      expect(PersistentSampleSource.collection, 'samples');
    });
  });
}
