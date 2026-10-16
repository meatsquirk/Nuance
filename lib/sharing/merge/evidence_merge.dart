import 'package:flutter/foundation.dart';

import '../../domain/provenance_derivation.dart';
import '../../domain/sample.dart';
import '../record/mix_accuracy_record.dart';

/// A received [MixAccuracyRecord] paired with the id of the source it arrived
/// from (bs-14 MERGE-1).
///
/// The record itself is anonymous — its four fields carry nothing about a
/// painter (D-4) — so the source id is attached at ingest, from the peer the
/// exchange took it from. [EvidenceMerge] stamps it onto the appended
/// [EvidencePoint.source] (AC-10, source-tagged) and [SourceRateLimiter] keys
/// its per-source bound on it (AC-12).
@immutable
class SourcedRecord {
  /// Pairs [record] with the [source] it was received from.
  const SourcedRecord({required this.source, required this.record});

  /// The id of the source (peer/device) this record arrived from.
  final String source;

  /// The anonymous mix-accuracy record received.
  final MixAccuracyRecord record;

  @override
  bool operator ==(Object other) =>
      other is SourcedRecord &&
      other.source == source &&
      other.record == record;

  @override
  int get hashCode => Object.hash(source, record);

  @override
  String toString() => 'SourcedRecord($source, $record)';
}

/// Merges peer-contributed records into one mapping's evidence log —
/// append-only and source-tagged (bs-14 AC-10; SI D9).
///
/// Each received [SourcedRecord] becomes one [EvidencePoint] whose coordinates
/// are the record's measured colour, whose [EvidencePoint.source] is the id it
/// arrived from, and whose kind is [EvidenceKind.peerContributed]; the point is
/// appended through bs-13's append-only [ProvenanceDerivation.appendEvidence]
/// so prior points are never dropped, reordered or overwritten. bs-14 adds no
/// new evidence model — it reuses bs-13's (D-6).
///
/// This is the MERGE-1 shell: it wires the collaborator and freezes the
/// signature but performs no merge — [ingest] returns the existing evidence
/// unchanged. MERGE-2 appends each incoming record; MERGE-5 bounds the volume
/// any one source may contribute via [SourceRateLimiter].
class EvidenceMerge {
  /// Creates a merge over bs-13's append-only [derivation].
  const EvidenceMerge({this.derivation = const ProvenanceDerivation()});

  /// The frozen bs-13 derivation whose append-only add every merge rides on.
  final ProvenanceDerivation derivation;

  /// Merges the [incoming] source-tagged records into [existing], returning the
  /// mapping's new evidence log.
  ///
  /// Shell: appends nothing, so it returns [existing] unchanged (as an
  /// unmodifiable view). MERGE-2 appends each [SourcedRecord] as a
  /// [EvidenceKind.peerContributed] point tagged with its source, preserving
  /// order and overwriting nothing.
  List<EvidencePoint> ingest(
    List<EvidencePoint> existing,
    Iterable<SourcedRecord> incoming,
  ) {
    return List<EvidencePoint>.unmodifiable(existing);
  }
}
