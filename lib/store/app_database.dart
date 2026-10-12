import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// The drift database over the generic `documents` table (bs-06 DATA-2).
///
/// The store is introduced as a *shell*: it offers collection/id/JSON document
/// primitives (the `documents` table in `documents.drift`) rather than a
/// per-entity schema, so DATA-2 stays decoupled from the Paint / Project /
/// Sample shapes that PALETTE-1 and PROJECT-1 own. The table is defined in a
/// drift SQL file so this component carries no compile-time-only column getters;
/// the generated `_$AppDatabase` (in `app_database.g.dart`) implements the query
/// plumbing, and `DriftPersistentStore` is the only caller.
///
/// Constructed over an injected [QueryExecutor] so the same database runs
/// against an in-memory sqlite (tests), a temporary file (the round-trip test)
/// and — once a persistent source consumes it — the on-device application-data
/// file.
@DriftDatabase(include: {'documents.drift'})
class AppDatabase extends _$AppDatabase {
  /// Opens the database over [executor] (migrating to [schemaVersion] on open).
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
