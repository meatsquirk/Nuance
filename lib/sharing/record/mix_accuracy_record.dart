import 'package:flutter/foundation.dart';

import '../../domain/color_coordinates.dart';
import '../../domain/sample.dart';
import 'content_hash.dart';

/// The set of paints a mix was made from, as sorted canonical paint ids.
///
/// The record carries the *combination*, not the painter's palette: the ids are
/// deduplicated and sorted so that two painters who mixed the same paints in a
/// different order (or listed a paint twice) produce the same combination, and
/// therefore the same [MixAccuracyRecord.contentHash]. Empty ids are dropped so
/// a blank entry never perturbs the canonical form.
@immutable
class PaintCombination {
  /// Creates a combination from an already sorted, deduplicated [paintIds]
  /// list. Prefer [PaintCombination.of], which normalizes arbitrary input.
  const PaintCombination(this.paintIds);

  /// Builds a combination from arbitrary [ids], trimming blanks, deduplicating
  /// and sorting into the canonical order.
  factory PaintCombination.of(Iterable<String> ids) {
    final normalized = <String>{
      for (final id in ids)
        if (id.trim().isNotEmpty) id.trim(),
    }.toList()
      ..sort();
    return PaintCombination(List<String>.unmodifiable(normalized));
  }

  /// The sorted, deduplicated canonical paint ids.
  final List<String> paintIds;

  /// The canonical form contributed to the content hash.
  String get canonical => paintIds.join(',');

  @override
  bool operator ==(Object other) =>
      other is PaintCombination && listEquals(other.paintIds, paintIds);

  @override
  int get hashCode => Object.hashAll(paintIds);

  @override
  String toString() => 'PaintCombination(${canonical.isEmpty ? '∅' : canonical})';
}

/// The declared identity of the paints behind a mix — the only palette context
/// that crosses the boundary (brand / line / medium), never the painter's own
/// palette object or project.
///
/// A record without a declared palette is not interpretable by a recipient and
/// is excluded from sharing (AC-5); [isPresent] reports whether all three parts
/// are known.
@immutable
class DeclaredPalette {
  /// Creates a declared palette. Each part defaults to empty ("not declared").
  const DeclaredPalette({this.brand = '', this.line = '', this.medium = ''});

  /// The manufacturer (e.g. "Winsor & Newton").
  final String brand;

  /// The product line within the brand (e.g. "Professional"), or empty.
  final String line;

  /// The binder the paints are ground in (the [PaintMedium] name), or empty.
  final String medium;

  /// Whether every part of the palette is declared. A record whose palette is
  /// not present is not interpretable and must not be shared (AC-5).
  bool get isPresent =>
      brand.trim().isNotEmpty &&
      line.trim().isNotEmpty &&
      medium.trim().isNotEmpty;

  /// The canonical form contributed to the content hash.
  String get canonical => '$brand|$line|$medium';

  @override
  bool operator ==(Object other) =>
      other is DeclaredPalette &&
      other.brand == brand &&
      other.line == line &&
      other.medium == medium;

  @override
  int get hashCode => Object.hash(brand, line, medium);

  @override
  String toString() => 'DeclaredPalette($canonical)';
}

/// A colour in CIELCh (lightness, chroma, hue angle) — the cylindrical form of
/// CIELAB carried alongside the Cartesian coordinates in a [MeasuredColour].
///
/// CIELCh is a pure mathematical transform of CIELAB, so it is a value the
/// record can carry directly; the COLOR layer owns the conversion that produces
/// it from [ColorCoordinates].
@immutable
class CielchCoordinates {
  /// Creates CIELCh coordinates.
  const CielchCoordinates({
    required this.lightness,
    required this.chroma,
    required this.hue,
  });

  /// CIELCh L\* — perceptual lightness, shared with CIELAB.
  final double lightness;

  /// CIELCh C\* — chroma (distance from the neutral axis), ≥ 0.
  final double chroma;

  /// CIELCh h — hue angle in degrees, 0–360.
  final double hue;

  @override
  bool operator ==(Object other) =>
      other is CielchCoordinates &&
      other.lightness == lightness &&
      other.chroma == chroma &&
      other.hue == hue;

  @override
  int get hashCode => Object.hash(lightness, chroma, hue);

  @override
  String toString() => 'CielchCoordinates(L $lightness, C $chroma, h $hue)';
}

/// The measured colour of a mix, carried in both CIELAB ([lab]) and CIELCh
/// ([lch]). Both are rounded in the record's canonical form so that readings
/// within rounding tolerance collapse to the same content hash (D-7).
@immutable
class MeasuredColour {
  /// Creates a measured colour from its [lab] and [lch] forms.
  const MeasuredColour({required this.lab, required this.lch});

  /// The canonical CIELAB coordinates.
  final ColorCoordinates lab;

  /// The CIELCh form of the same colour.
  final CielchCoordinates lch;

  @override
  bool operator ==(Object other) =>
      other is MeasuredColour && other.lab == lab && other.lch == lch;

  @override
  int get hashCode => Object.hash(lab, lch);

  @override
  String toString() => 'MeasuredColour($lab, $lch)';
}

/// How well the mix's colour was measured — the record's own three-level tier,
/// mapped from bs-13's [EvidenceKind] (not a new scale):
///
/// * [instrument] — read from an instrument ([EvidenceKind.instrumentMeasured]);
/// * [referenceCard] — a reference-card-calibrated photograph
///   ([EvidenceKind.photographedSwatch]);
/// * [cardLess] — any lower-confidence origin (solver-calculated, seeded or
///   stated), the conservative floor.
enum MeasurementTier {
  /// Instrument-measured — the highest-confidence tier.
  instrument,

  /// Reference-card-calibrated — a measured photograph of the painter's swatch.
  referenceCard,

  /// Card-less — the conservative default for any lower-confidence origin.
  cardLess;

  /// Maps a bs-13 [EvidenceKind] to the record's measurement tier.
  static MeasurementTier fromEvidenceKind(EvidenceKind kind) {
    switch (kind) {
      case EvidenceKind.instrumentMeasured:
        return MeasurementTier.instrument;
      case EvidenceKind.photographedSwatch:
        return MeasurementTier.referenceCard;
      case EvidenceKind.solverCalculated:
      case EvidenceKind.llmSeed:
      case EvidenceKind.opinion:
        return MeasurementTier.cardLess;
    }
  }
}

/// The anonymous mix-accuracy record — the *only* thing bs-14 ever exchanges
/// between painters (D-4).
///
/// It carries exactly four things, all about the mix and none about the painter:
/// the [paintCombination] (sorted paint ids), the [declaredPalette]
/// (brand/line/medium), the [measuredColour] (CIELAB + CIELCh) and the
/// [tier] (how well it was measured). It is immutable and value-equal, and its
/// [contentHash] is a deterministic function of the rounded canonical form so
/// byte-identical records collapse at exchange (D-7).
@immutable
class MixAccuracyRecord {
  /// Creates a record from its four fields.
  const MixAccuracyRecord({
    required this.paintCombination,
    required this.declaredPalette,
    required this.measuredColour,
    required this.tier,
  });

  /// The sorted paint ids the mix was made from.
  final PaintCombination paintCombination;

  /// The declared brand / line / medium of those paints.
  final DeclaredPalette declaredPalette;

  /// The measured colour of the mix, in CIELAB and CIELCh.
  final MeasuredColour measuredColour;

  /// How well the colour was measured.
  final MeasurementTier tier;

  /// The canonical, rounded serialization the content hash is taken over.
  ///
  /// CIELAB/CIELCh values are rounded to two decimal places so readings within
  /// rounding tolerance collapse; the fields are joined in a fixed order with
  /// unambiguous separators so distinct records never alias.
  String get canonicalForm {
    final lab = measuredColour.lab;
    final lch = measuredColour.lch;
    return [
      paintCombination.canonical,
      declaredPalette.canonical,
      'lab:${_round(lab.lightness)},${_round(lab.a)},${_round(lab.b)}',
      'lch:${_round(lch.lightness)},${_round(lch.chroma)},${_round(lch.hue)}',
      'tier:${tier.name}',
    ].join(';');
  }

  /// The deterministic content hash over [canonicalForm] (D-7).
  String get contentHash => contentHashOf(canonicalForm);

  @override
  bool operator ==(Object other) =>
      other is MixAccuracyRecord &&
      other.paintCombination == paintCombination &&
      other.declaredPalette == declaredPalette &&
      other.measuredColour == measuredColour &&
      other.tier == tier;

  @override
  int get hashCode =>
      Object.hash(paintCombination, declaredPalette, measuredColour, tier);

  @override
  String toString() =>
      'MixAccuracyRecord(${paintCombination.canonical}, '
      '${declaredPalette.canonical}, ${tier.name})';
}

/// Rounds a coordinate to two decimal places for the canonical form, folding
/// negative zero to "0.00" so `-0.0` and `0.0` never hash differently.
String _round(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed == '-0.00' ? '0.00' : fixed;
}
