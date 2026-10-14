import 'package:flutter/foundation.dart';

import '../a11y/cvd/cvd_profile.dart';
import 'persistent_store.dart';

/// Persists the painter's one measured [CvdProfile] over a [PersistentStore]
/// (bs-07 PROFILE-1, D-2/D-3; G-4).
///
/// A single stored document: collection [collection], id [documentId], body
/// `{type: <CvdType.name>, severity: <0..1>}`. The profile is reused from bs-03
/// unchanged (`lib/a11y/cvd/cvd_profile.dart`) — bs-07 only *populates* it — so
/// the measured type/severity flows to bs-03's `ConfusionCheck` and the
/// `projectDichromat` seam bs-08/bs-10 reuse (D-3). The store is the write-side
/// of that one value; production assembly loads it at startup (`loadCvdProfile`)
/// and PROFILE-2 (AC-13) saves the assessed estimate through it.
///
/// Backed by the same [PersistentStore] seam as the bs-06 sources, so the unit
/// suite and the acceptance harness exercise it over an [InMemoryPersistentStore]
/// while production uses the file-backed `DriftPersistentStore`.
class CvdProfileStore {
  /// Creates a profile store over [store].
  const CvdProfileStore(this._store);

  final PersistentStore _store;

  /// Notifies when the backing store changes, so a live reader re-reads the
  /// saved profile on a save (bs-10 DALT-11, AC-6).
  ///
  /// Forwards the backing [PersistentStore.changes]: the app root listens here
  /// and re-reads [load] when it fires, so a saved profile change (e.g. a new
  /// self-assessment, or a direct store write) recomputes the daltonization
  /// remap live rather than only at app assembly. Like the backing signal it
  /// carries no payload — a listener re-reads [load] to see the new profile.
  Listenable get changes => _store.changes;

  /// The collection the single profile document lives in.
  static const String collection = 'cvd_profile';

  /// The id of the single profile document (there is only ever one profile).
  static const String documentId = 'current';

  /// Writes [profile] as the single stored profile, replacing any previous one.
  Future<void> save(CvdProfile profile) => _store.put(
        collection,
        documentId,
        {'type': profile.type.name, 'severity': profile.severity},
      );

  /// The stored profile, or null when none has been saved.
  Future<CvdProfile?> load() async {
    final data = await _store.get(collection, documentId);
    if (data == null) return null;
    return CvdProfile(
      type: CvdType.values.byName(data['type']! as String),
      severity: (data['severity']! as num).toDouble(),
    );
  }

  /// How many profiles are stored (0 or 1) — lets the acceptance suite assert
  /// exactly one profile is written without reaching into the store engine.
  Future<int> count() async => (await _store.list(collection)).length;

  /// Whether the painter has actually **saved** a profile (bs-10 AC-10, D-4).
  ///
  /// `true` only when a profile document exists — not when the pipeline is
  /// merely running on the const default [loadCvdProfile] falls back to. The
  /// daltonization control consults this (not the injected `cvdProfile`) so it
  /// can prompt for a self-assessment when nothing has been saved, rather than
  /// silently remapping against the default.
  Future<bool> hasSavedProfile() async => (await count()) > 0;
}
