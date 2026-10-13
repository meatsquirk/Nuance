import '../capture/capture_accuracy.dart';
import '../capture/source/capture_source.dart';
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
///
/// A capture also tags the reading with the gamut it was measured in
/// ([colorSpace]), whether it was lit by the camera torch ([litByTorch]) and
/// whether the device captured processed frames or RAW ([captureMode]) — bs-09.
/// These are all nullable/off by default so every bs-01..bs-06 caller is
/// unaffected; the CAPTURE commit threads the source's values in, and the
/// SOURCE/CAPTURE behaviour phases give them meaning.
class Sample {
  const Sample({
    required this.coordinates,
    required this.provenance,
    this.name,
    this.justCaptured = false,
    this.accuracy,
    this.evidence = const [],
    this.colorSpace,
    this.litByTorch = false,
    this.captureMode,
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

  /// The colour space the capture measured this reading in (bs-09 AC-6), or null
  /// for a sample that did not come from a bs-09 capture. The CAPTURE commit
  /// stamps the source's current [CaptureSource.colorSpace]; SOURCE-2 makes it
  /// reflect the device's gamut.
  final CaptureColorSpace? colorSpace;

  /// Whether the reading was taken with the camera torch lit (bs-09 AC-2).
  /// Default false; the CAPTURE commit stamps the controller's torch state
  /// (CAPTURE-3).
  final bool litByTorch;

  /// Whether the capture delivered processed frames or RAW (bs-09 AC-7), or null
  /// for a non-capture sample. The commit stamps [CaptureSource.captureMode];
  /// SOURCE-3 switches RAW-capable devices to [CaptureMode.raw].
  final CaptureMode? captureMode;

  /// Returns a copy of this sample with the given fields replaced.
  Sample copyWith({
    ColorCoordinates? coordinates,
    Provenance? provenance,
    String? name,
    bool? justCaptured,
    CaptureAccuracy? accuracy,
    List<EvidencePoint>? evidence,
    CaptureColorSpace? colorSpace,
    bool? litByTorch,
    CaptureMode? captureMode,
  }) {
    return Sample(
      coordinates: coordinates ?? this.coordinates,
      provenance: provenance ?? this.provenance,
      name: name ?? this.name,
      justCaptured: justCaptured ?? this.justCaptured,
      accuracy: accuracy ?? this.accuracy,
      evidence: evidence ?? this.evidence,
      colorSpace: colorSpace ?? this.colorSpace,
      litByTorch: litByTorch ?? this.litByTorch,
      captureMode: captureMode ?? this.captureMode,
    );
  }

  @override
  String toString() =>
      'Sample(${name ?? '(unnamed)'}, $coordinates, ${provenance.label}'
      '${justCaptured ? ', just-captured' : ''}'
      '${accuracy == null ? '' : ', ${accuracy!.label}'}'
      '${colorSpace == null ? '' : ', ${colorSpace!.name}'}'
      '${litByTorch ? ', torch-lit' : ''}'
      '${captureMode == null ? '' : ', ${captureMode!.name}'})';
}
