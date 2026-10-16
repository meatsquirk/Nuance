import '../../color_science/color_science.dart';
import '../../color_science/color_science_impl.dart';
import '../../domain/sample.dart';
import 'mix_accuracy_record.dart';

/// Builds the anonymous [MixAccuracyRecord]s bs-14 may share, from the painter's
/// own confirmed/measured mixes, and selects the subset that is actually
/// shareable.
///
/// The record is the only thing that crosses the boundary (D-4); the builder is
/// the single place that decides what a record contains and whether it is
/// shared, so the redaction guarantee (AC-4) and the no-palette exclusion (AC-5)
/// live behind this one seam.
abstract class RecordBuilder {
  /// Prepares a shareable record from a confirmed/measured [sample] and its
  /// declared [palette], or null when nothing shareable can be built. RECORD-2
  /// implements the construction (AC-3) and the redaction-by-construction
  /// guarantee (AC-4).
  MixAccuracyRecord? prepare(Sample sample, {DeclaredPalette? palette});

  /// Selects, from already-prepared [candidates], the records that are actually
  /// shared — dropping any whose declared palette is absent (AC-5). RECORD-3
  /// implements the exclusion.
  List<MixAccuracyRecord> selectShareSet(Iterable<MixAccuracyRecord> candidates);
}

/// The concrete [RecordBuilder] the CORE scope wires.
///
/// [prepare] (RECORD-2) builds a record from exactly four things — the mix's
/// paint combination, the declared palette, the measured colour and the
/// measurement tier — and *nothing* about the painter. The input [Sample] may
/// carry a personal name, a project or evidence source ids; the builder reads
/// only [Sample.paintIds], [Sample.coordinates] and [Sample.evidence] (for the
/// tier), so the record structurally cannot hold anything personal (AC-4,
/// redaction by construction). [selectShareSet] stays a no-op until RECORD-3
/// adds the no-palette exclusion (AC-5).
class EvidenceRecordBuilder implements RecordBuilder {
  /// Creates the builder. [colorScience] derives the CIELCh form of a record's
  /// measured colour from its canonical CIELAB — the real engine by default, so
  /// a record's two colour forms are consistent the way production builds them.
  // A named parameter cannot be private, so the public `colorScience:` label is
  // assigned to the private field in the initializer rather than via an
  // initializing formal (which the lint would otherwise prefer).
  const EvidenceRecordBuilder({
    ColorScience colorScience = const ColorScienceImpl(),
    // ignore: prefer_initializing_formals
  }) : _colorScience = colorScience;

  final ColorScience _colorScience;

  @override
  MixAccuracyRecord? prepare(Sample sample, {DeclaredPalette? palette}) {
    // The paint combination is what a mix *is*; a sample with no declared paints
    // describes no mix, so there is nothing shareable to build (null).
    final combination = PaintCombination.of(sample.paintIds);
    if (combination.paintIds.isEmpty) return null;

    // The measured colour — the sample's canonical CIELAB verbatim, with its
    // CIELCh form derived by the real colour engine (never a hand-faked
    // conversion), so the two forms stay consistent.
    final lab = sample.coordinates;
    final lch = _colorScience.toCIELCh(lab);
    final measuredColour = MeasuredColour(
      lab: lab,
      lch: CielchCoordinates(
        lightness: lch.lightness,
        chroma: lch.chroma,
        hue: lch.hue,
      ),
    );

    return MixAccuracyRecord(
      paintCombination: combination,
      // Only the declared brand/line/medium crosses the boundary; an absent
      // palette is carried as-is and excluded at share-set selection (AC-5).
      declaredPalette: palette ?? const DeclaredPalette(),
      measuredColour: measuredColour,
      tier: _tierOf(sample.evidence),
    );
  }

  /// The record's measurement tier: the strongest tier among [evidence] (an
  /// instrument reading outranks a card-calibrated photograph, which outranks a
  /// card-less origin). A sample with no evidence falls to the conservative
  /// card-less floor.
  MeasurementTier _tierOf(List<EvidencePoint> evidence) {
    var best = MeasurementTier.cardLess;
    for (final point in evidence) {
      final tier = MeasurementTier.fromEvidenceKind(point.kind);
      if (tier.index < best.index) best = tier;
    }
    return best;
  }

  /// The reason a candidate is dropped from the share-set: without a declared
  /// palette a record is not interpretable by a recipient, so it is never
  /// shared (AC-5, D-8, scope §6.6).
  static const String noPaletteExclusionReason =
      'not interpretable — no declared palette';

  @override
  List<MixAccuracyRecord> selectShareSet(
    Iterable<MixAccuracyRecord> candidates,
  ) {
    // Keep only the records a recipient can interpret: a candidate whose
    // declared palette is absent is excluded for [noPaletteExclusionReason]
    // (AC-5). Every other record is carried through unchanged — the only thing
    // that ever crosses the boundary is an anonymous record (D-4).
    return <MixAccuracyRecord>[
      for (final candidate in candidates)
        if (candidate.declaredPalette.isPresent) candidate,
    ];
  }
}
