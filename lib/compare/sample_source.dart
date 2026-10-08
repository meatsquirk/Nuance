import '../domain/sample.dart';

/// The saved samples the comparison picker lists (D-7).
///
/// A minimal read-only seam over the painter's saved colours: the picker (E3/E5
/// via E49) and every selection Given read the catalogue through this interface
/// rather than from a store, so bs-03 stays independent of persistence. bs-03
/// ships the in-memory [InMemorySampleSource]; **bs-06** (palette & projects)
/// later supplies a persistent catalogue behind this same interface without
/// touching the comparison code.
abstract interface class SampleSource {
  /// The saved samples available to compare, in listing order.
  List<Sample> savedSamples();
}

/// An in-memory [SampleSource] over a fixed list of samples.
///
/// The bs-03 default: an **empty** catalogue (`const InMemorySampleSource()`),
/// so the shell assembles with no saved samples. **COMPARE-3** constructs one
/// seeded with the named saved samples the picker offers; the list is exposed
/// read-only so callers cannot mutate the catalogue through [savedSamples].
class InMemorySampleSource implements SampleSource {
  /// Creates a catalogue over [samples] (empty by default).
  const InMemorySampleSource({this.samples = const []});

  /// The saved samples this catalogue holds.
  final List<Sample> samples;

  @override
  List<Sample> savedSamples() => List<Sample>.unmodifiable(samples);
}
