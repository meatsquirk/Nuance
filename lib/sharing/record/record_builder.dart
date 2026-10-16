import '../../domain/sample.dart';
import 'mix_accuracy_record.dart';

/// Builds the anonymous [MixAccuracyRecord]s bs-14 may share, from the painter's
/// own confirmed/measured mixes, and selects the subset that is actually
/// shareable.
///
/// The record is the only thing that crosses the boundary (D-4); the builder is
/// the single place that decides what a record contains and whether it is
/// shared, so the redaction guarantee (AC-4) and the no-palette exclusion (AC-5)
/// live behind this one seam. The shell wires the seam without behaviour: the
/// concrete [EvidenceRecordBuilder] returns nothing until the RECORD behaviour
/// phases fill it in.
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

/// The skeleton [RecordBuilder] wired by the CORE scope. It builds nothing and
/// shares nothing, so the existing suite stays green; the RECORD behaviour
/// phases replace these bodies.
class EvidenceRecordBuilder implements RecordBuilder {
  /// Creates the skeleton builder.
  const EvidenceRecordBuilder();

  @override
  MixAccuracyRecord? prepare(Sample sample, {DeclaredPalette? palette}) => null;

  @override
  List<MixAccuracyRecord> selectShareSet(
    Iterable<MixAccuracyRecord> candidates,
  ) =>
      const <MixAccuracyRecord>[];
}
