import '../capture/capture_accuracy.dart';
import 'color_coordinates.dart';
import 'provenance.dart';

/// A single source-tagged colour observation backing a [Sample].
///
/// A sample keeps an append-ready list of these (SI D9) so the future
/// peer-to-peer layer (bs-14) merges evidence as data rather than as a schema
/// change. Behaviour is deferred — this is shape only.
class EvidencePoint {
  const EvidencePoint({required this.coordinates, required this.source});

  /// The colour this evidence reports, in canonical CIELAB.
  final ColorCoordinates coordinates;

  /// Where the evidence came from (instrument id, peer id, model name, …).
  final String source;

  @override
  bool operator ==(Object other) =>
      other is EvidencePoint &&
      other.coordinates == coordinates &&
      other.source == source;

  @override
  int get hashCode => Object.hash(coordinates, source);

  @override
  String toString() => 'EvidencePoint($source: $coordinates)';
}

/// A colour sample the painter works with.
///
/// Holds the canonical [coordinates], a required non-null [provenance] (SI D9),
/// an optional [name] (null until the sample is named), whether it was
/// [justCaptured] (drives the AC-12 confirmation), the stated capture [accuracy]
/// (null until the sample comes from a capture — bs-02), and the append-ready
/// [evidence] list.
class Sample {
  const Sample({
    required this.coordinates,
    required this.provenance,
    this.name,
    this.justCaptured = false,
    this.accuracy,
    this.evidence = const [],
  });

  /// The canonical CIELAB coordinates of the sample.
  final ColorCoordinates coordinates;

  /// Provenance of the reading (required, non-null — SI D9).
  final Provenance provenance;

  /// The plain-language name, or null until the sample is named.
  final String? name;

  /// True from capture until acknowledged (drives AC-12).
  final bool justCaptured;

  /// The stated capture accuracy tier (bs-02 D-3), or null for a sample that did
  /// not come from a capture (e.g. a bs-01 reading). Distinct from [provenance]:
  /// provenance records the data source, accuracy the capture confidence.
  final CaptureAccuracy? accuracy;

  /// Source-tagged evidence backing this sample; append-ready for bs-14.
  final List<EvidencePoint> evidence;

  /// Returns a copy of this sample with the given fields replaced.
  Sample copyWith({
    ColorCoordinates? coordinates,
    Provenance? provenance,
    String? name,
    bool? justCaptured,
    CaptureAccuracy? accuracy,
    List<EvidencePoint>? evidence,
  }) {
    return Sample(
      coordinates: coordinates ?? this.coordinates,
      provenance: provenance ?? this.provenance,
      name: name ?? this.name,
      justCaptured: justCaptured ?? this.justCaptured,
      accuracy: accuracy ?? this.accuracy,
      evidence: evidence ?? this.evidence,
    );
  }

  @override
  String toString() =>
      'Sample(${name ?? '(unnamed)'}, $coordinates, ${provenance.label}'
      '${justCaptured ? ', just-captured' : ''}'
      '${accuracy == null ? '' : ', ${accuracy!.label}'})';
}
