import 'package:flutter/foundation.dart';

import '../../domain/provenance_derivation.dart';
import '../../domain/sample.dart';
import '../record/mix_accuracy_record.dart';
import 'source_rate_limiter.dart';

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
/// MERGE-2 implements the append-only merge: each incoming record is appended
/// as a source-tagged [EvidenceKind.peerContributed] point and nothing prior is
/// dropped, reordered or overwritten. MERGE-5 bounds the volume any one source
/// may contribute via [SourceRateLimiter].
class EvidenceMerge {
  /// Creates a merge over bs-13's append-only [derivation], capping each source
  /// at [maxPerSource] peer-contributed points (AC-12).
  const EvidenceMerge({
    this.derivation = const ProvenanceDerivation(),
    this.maxPerSource = SourceRateLimiter.defaultMaxPerSource,
  });

  /// The frozen bs-13 derivation whose append-only add every merge rides on.
  final ProvenanceDerivation derivation;

  /// The most peer-contributed points any single source may hold in a mapping's
  /// evidence log; records beyond it from that source are rejected (AC-12;
  /// scope §6.6).
  final int maxPerSource;

  /// Merges the [incoming] source-tagged records into [existing], returning the
  /// mapping's new evidence log.
  ///
  /// Each [SourcedRecord] becomes one [EvidencePoint] whose coordinates are the
  /// record's measured colour, whose [EvidencePoint.source] is the id it arrived
  /// from, and whose kind is [EvidenceKind.peerContributed]. Each is appended
  /// through bs-13's append-only [ProvenanceDerivation.appendEvidence], so the
  /// prior points stay unchanged and in order, the appended points follow in
  /// arrival order, and nothing is overwritten or deduped — distinct peer
  /// measurements each add a point (AC-10). The result is an unmodifiable view.
  ///
  /// The volume any one source contributes is bounded by a [SourceRateLimiter]
  /// capped at [maxPerSource]: once a source has that many peer-contributed
  /// points in the log it is rejected, while every other source is admitted
  /// independently, so a flood from one source cannot dominate the mapping nor
  /// starve the others (AC-12). The limiter is seeded with the peer points
  /// already in [existing], so the cap counts a source's whole contribution
  /// across repeated merges, not just this batch (the log only ever grows).
  List<EvidencePoint> ingest(
    List<EvidencePoint> existing,
    Iterable<SourcedRecord> incoming,
  ) {
    final SourceRateLimiter limiter =
        SourceRateLimiter(maxPerSource: maxPerSource);
    for (final EvidencePoint point in existing) {
      if (point.kind == EvidenceKind.peerContributed) {
        limiter.admit(point.source);
      }
    }
    var evidence = existing;
    for (final SourcedRecord sourced in incoming) {
      if (!limiter.admit(sourced.source)) {
        continue;
      }
      evidence = derivation.appendEvidence(
        evidence,
        EvidencePoint(
          coordinates: sourced.record.measuredColour.lab,
          source: sourced.source,
          kind: EvidenceKind.peerContributed,
        ),
      );
    }
    return List<EvidencePoint>.unmodifiable(evidence);
  }
}
