import 'package:flutter/foundation.dart';

/// One stored document: its [id] within a collection and its decoded [data].
///
/// Returned by [PersistentStore.list]. A plain record (structural equality, no
/// boilerplate) — the body is a JSON-shaped map the caller encoded on [put].
typedef StoredDocument = ({String id, Map<String, Object?> data});

/// The on-device persistence seam the bs-06 sources write through (DATA-2).
///
/// A minimal document store: collections of JSON-shaped maps keyed by a string
/// id, with create/replace ([put]), read ([get]), enumerate ([list]) and
/// [delete] primitives. It is the write-side the read-only `PaletteSource` /
/// `SampleSource` seams' doc-comments nominate bs-06 to add, plus the new
/// `ProjectSource`; those sources map their entities onto this contract so they
/// stay independent of the storage engine. The shipped implementation is
/// [DriftPersistentStore] (SQLite); [InMemoryPersistentStore] is the double the
/// acceptance harness and unit tests exercise against the same contract.
///
/// `data` maps must be JSON-encodable — the engine serialises them verbatim and
/// returns an equal structure. Ids are opaque to the store; the caller chooses
/// them and is responsible for their uniqueness within a collection.
abstract interface class PersistentStore {
  /// Notifies its listeners whenever a write ([put] or [delete]) changes the
  /// store's documents (bs-10 DALT-11, AC-6).
  ///
  /// The reactive seam bs-10 adds so a surface reading a stored value can
  /// re-read it when the store changes rather than once at build: the app root
  /// listens here (via [CvdProfileStore.changes]) and re-reads the painter's
  /// colour-vision profile on a save, so a saved deutan→protan change recomputes
  /// the daltonization remap live. A plain [Listenable] (no change payload) — a
  /// listener re-reads whatever document it cares about; the notification does
  /// not say which collection changed.
  Listenable get changes;

  /// Creates or replaces the document [id] in [collection] with [data].
  Future<void> put(String collection, String id, Map<String, Object?> data);

  /// The document [id] in [collection], or null if none is stored.
  Future<Map<String, Object?>?> get(String collection, String id);

  /// Every document in [collection], in ascending id order (empty if none).
  Future<List<StoredDocument>> list(String collection);

  /// Removes the document [id] from [collection]; a no-op if it is absent.
  Future<void> delete(String collection, String id);

  /// Releases the store's resources (closes the underlying database).
  Future<void> close();
}

/// An in-memory [PersistentStore] over nested maps (collection → id → data).
///
/// The persistence-free double: the acceptance harness and unit tests back the
/// same contract with it so they run without a real database, and a future
/// "no persistence" mode can ship it. Stored maps are copied in and out so a
/// caller cannot mutate the store's state through a reference it handed to
/// [put] or received from [get] / [list].
class InMemoryPersistentStore with ChangeNotifier implements PersistentStore {
  final Map<String, Map<String, Map<String, Object?>>> _collections = {};

  @override
  Listenable get changes => this;

  @override
  Future<void> put(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    (_collections[collection] ??= {})[id] = Map<String, Object?>.from(data);
    notifyListeners();
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async {
    final stored = _collections[collection]?[id];
    return stored == null ? null : Map<String, Object?>.from(stored);
  }

  @override
  Future<List<StoredDocument>> list(String collection) async {
    final docs = _collections[collection];
    if (docs == null) return const [];
    final ids = docs.keys.toList()..sort();
    return [
      for (final id in ids)
        (id: id, data: Map<String, Object?>.from(docs[id]!)),
    ];
  }

  @override
  Future<void> delete(String collection, String id) async {
    _collections[collection]?.remove(id);
    notifyListeners();
  }

  @override
  Future<void> close() async {}
}
