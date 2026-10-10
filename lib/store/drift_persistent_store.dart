import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'app_database.dart';
import 'persistent_store.dart';

/// The shipped SQLite-backed [PersistentStore] (bs-06 DATA-2, plan D-1 / G-4).
///
/// Wraps an [AppDatabase] over the generic `Documents` table, encoding each
/// document's `data` map as JSON text on [put] and decoding it on [get] /
/// [list]. Constructed over an injected [QueryExecutor] so the same store code
/// runs against an in-memory sqlite ([DriftPersistentStore.memory]), a
/// temporary file and — once a persistent source consumes it — the on-device
/// application-data file; that file/native binding is the platform-wiring step
/// the first consumer (PALETTE-1/PROJECT-1) adds, kept out of this pure-Dart
/// component as bs-02 kept native capture out of `SoftwareCaptureSource`.
class DriftPersistentStore implements PersistentStore {
  /// Opens the store over [executor] (e.g. a `NativeDatabase` over a file).
  DriftPersistentStore(QueryExecutor executor) : _db = AppDatabase(executor);

  /// Opens the store over a fresh in-memory sqlite database (tests, and any
  /// future ephemeral mode). Nothing is persisted across instances.
  DriftPersistentStore.memory() : _db = AppDatabase(NativeDatabase.memory());

  final AppDatabase _db;

  @override
  Future<void> put(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    await _db.into(_db.documents).insertOnConflictUpdate(
          DocumentsCompanion.insert(
            collection: collection,
            id: id,
            body: jsonEncode(data),
          ),
        );
  }

  @override
  Future<Map<String, Object?>?> get(String collection, String id) async {
    final row = await (_db.select(_db.documents)
          ..where((t) => t.collection.equals(collection) & t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _decode(row.body);
  }

  @override
  Future<List<StoredDocument>> list(String collection) async {
    final rows = await (_db.select(_db.documents)
          ..where((t) => t.collection.equals(collection))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
    return [
      for (final row in rows) (id: row.id, data: _decode(row.body)),
    ];
  }

  @override
  Future<void> delete(String collection, String id) async {
    await (_db.delete(_db.documents)
          ..where((t) => t.collection.equals(collection) & t.id.equals(id)))
        .go();
  }

  @override
  Future<void> close() => _db.close();

  Map<String, Object?> _decode(String body) =>
      (jsonDecode(body) as Map).cast<String, Object?>();
}
