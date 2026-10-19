import 'package:flutter/foundation.dart';

import '../../store/persistent_store.dart';
import 'sharing_consent.dart';

/// The write/read seam for the painter's crowd-refinement [SharingConsent]
/// (bs-14 CORE-2).
///
/// Mirrors the bs-07 `CvdProfileStore` shape: a single stored value behind a
/// small interface, so the opt-in action (CORE-3) and the acceptance suite talk
/// to the same contract while the suite and unit tests back it with an
/// in-memory double and production persists to disk. The stored default is
/// **not opted in** — [load] returns the not-consented [SharingConsent] default
/// until a consent is [save]d.
abstract interface class ConsentStore {
  /// Notifies when the stored consent changes, so a live reader re-reads it on
  /// an opt-in (consumed by the reactive wiring in CORE-3).
  Listenable get changes;

  /// The stored consent, or the not-opted-in [SharingConsent] default when none
  /// has been saved.
  Future<SharingConsent> load();

  /// Records [consent] as the single stored consent, replacing any previous one.
  Future<void> save(SharingConsent consent);
}

/// A [ConsentStore] over the shared [PersistentStore] document seam (bs-14
/// CORE-2).
///
/// Stores the one consent document as `{consented: <bool>, offerCopy: <String>}`
/// in its own [collection], keyed by [documentId]. Backed by the same
/// [PersistentStore] as the bs-06 sources and the bs-07 profile, so the unit
/// suite and acceptance harness exercise it over an [InMemoryPersistentStore]
/// while production uses the file-backed `DriftPersistentStore`. Absent document
/// ⇒ the not-consented default (nothing shared until the painter opts in).
class PersistentConsentStore implements ConsentStore {
  /// Creates a consent store over [store].
  const PersistentConsentStore(this._store);

  final PersistentStore _store;

  /// The collection the single consent document lives in.
  static const String collection = 'sharing_consent';

  /// The id of the single consent document (there is only ever one consent).
  static const String documentId = 'current';

  @override
  Listenable get changes => _store.changes;

  @override
  Future<SharingConsent> load() async {
    final data = await _store.get(collection, documentId);
    if (data == null) return const SharingConsent();
    return SharingConsent(
      consented: data['consented']! as bool,
      offerCopy: data['offerCopy']! as String,
    );
  }

  @override
  Future<void> save(SharingConsent consent) => _store.put(
        collection,
        documentId,
        {'consented': consent.consented, 'offerCopy': consent.offerCopy},
      );
}
