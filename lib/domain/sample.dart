import '../capture/capture_accuracy.dart';
import '../capture/source/capture_source.dart';
import 'color_coordinates.dart';
import 'provenance.dart';

/// How a piece of evidence was obtained — its origin.
///
/// bs-13 derives a value's shown provenance tier from the origins of the
/// evidence behind it (SI D9): see [ProvenanceDerivation]. The precedence,
/// implemented in PROV-2, is `photographedSwatch` → Confirmed ·
/// `instrumentMeasured` → Measured · `solverCalculated` → Calculated ·
/// `llmSeed` → Estimated; [opinion] never contributes to the tier (AC-10).
enum EvidenceKind {
  /// Read from an instrument (e.g. a spectrophotometer).
  instrumentMeasured,

  /// Derived by the mix solver from other measured values.
  solverCalculated,

  /// Seeded by a model and not yet verified.
  llmSeed,

  /// A swatch the painter photographed of their own measured mix — the
  /// self-confirmation that promotes an estimate to Confirmed (AC-9).
  photographedSwatch,

  /// A stated opinion; carried as evidence but never raises the tier (AC-10).
  opinion,

  /// Received from another painter's install through the bs-14 peer-to-peer
  /// exchange. Carried as source-tagged evidence that may *refine* an Estimated
  /// value's coordinates, but it never contributes to the derived tier — only
  /// the painter's own measured swatch promotes (bs-14 AC-9; SI D2). It is
  /// default-safe: [ProvenanceDerivation.tierFor] reads only the kinds in its
  /// promotion precedence, so a peer-contributed point leaves the tier at the
  /// value's stored fallback.
  peerContributed,
}

/// A single source-tagged colour observation backing a [Sample].
///
/// A sample keeps an append-ready list of these (SI D9) so the future
/// peer-to-peer layer (bs-14) merges evidence as data rather than as a schema
/// change. Each point records both where it came from ([source]) and how it was
/// obtained ([kind]); the kind is what [ProvenanceDerivation] reads.
class EvidencePoint {
  const EvidencePoint({
    required this.coordinates,
    required this.source,
    this.kind = EvidenceKind.opinion,
  });

  /// The colour this evidence reports, in canonical CIELAB.
  final ColorCoordinates coordinates;

  /// Where the evidence came from (instrument id, peer id, model name, …).
  final String source;

  /// How this evidence was obtained — the origin the tier derives from.
  ///
  /// Defaults to [EvidenceKind.opinion] — a safe, non-contributing default so
  /// existing call-sites keep compiling unchanged; every evidence point that
  /// drives a tier is constructed with an explicit kind (the own-swatch wiring
  /// in bs-05/capture passes [EvidenceKind.photographedSwatch]).
  final EvidenceKind kind;

  @override
  bool operator ==(Object other) =>
      other is EvidencePoint &&
      other.coordinates == coordinates &&
      other.source == source &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(coordinates, source, kind);

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
