// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Documents extends Table with TableInfo<Documents, Document> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Documents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [collection, id, body];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Document> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collection, id};
  @override
  Document map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Document(
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  Documents createAlias(String alias) {
    return Documents(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(collection, id)'];
  @override
  bool get dontWriteConstraints => true;
}

class Document extends DataClass implements Insertable<Document> {
  final String collection;
  final String id;
  final String body;
  const Document({
    required this.collection,
    required this.id,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection'] = Variable<String>(collection);
    map['id'] = Variable<String>(id);
    map['body'] = Variable<String>(body);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      collection: Value(collection),
      id: Value(id),
      body: Value(body),
    );
  }

  factory Document.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Document(
      collection: serializer.fromJson<String>(json['collection']),
      id: serializer.fromJson<String>(json['id']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collection': serializer.toJson<String>(collection),
      'id': serializer.toJson<String>(id),
      'body': serializer.toJson<String>(body),
    };
  }

  Document copyWith({String? collection, String? id, String? body}) => Document(
    collection: collection ?? this.collection,
    id: id ?? this.id,
    body: body ?? this.body,
  );
  Document copyWithCompanion(DocumentsCompanion data) {
    return Document(
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Document(')
          ..write('collection: $collection, ')
          ..write('id: $id, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collection, id, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Document &&
          other.collection == this.collection &&
          other.id == this.id &&
          other.body == this.body);
}

class DocumentsCompanion extends UpdateCompanion<Document> {
  final Value<String> collection;
  final Value<String> id;
  final Value<String> body;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.collection = const Value.absent(),
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String collection,
    required String id,
    required String body,
    this.rowid = const Value.absent(),
  }) : collection = Value(collection),
       id = Value(id),
       body = Value(body);
  static Insertable<Document> custom({
    Expression<String>? collection,
    Expression<String>? id,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collection != null) 'collection': collection,
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? collection,
    Value<String>? id,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      collection: collection ?? this.collection,
      id: id ?? this.id,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('collection: $collection, ')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Documents documents = Documents(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [documents];
}

typedef $DocumentsCreateCompanionBuilder = DocumentsCompanion Function({
  required String collection,
  required String id,
  required String body,
  Value<int> rowid,
});
typedef $DocumentsUpdateCompanionBuilder = DocumentsCompanion Function({
  Value<String> collection,
  Value<String> id,
  Value<String> body,
  Value<int> rowid,
});

class $DocumentsFilterComposer extends Composer<_$AppDatabase, Documents> {
  $DocumentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );
}

class $DocumentsOrderingComposer extends Composer<_$AppDatabase, Documents> {
  $DocumentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DocumentsAnnotationComposer extends Composer<_$AppDatabase, Documents> {
  $DocumentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);
}

class $DocumentsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Documents,
          Document,
          $DocumentsFilterComposer,
          $DocumentsOrderingComposer,
          $DocumentsAnnotationComposer,
          $DocumentsCreateCompanionBuilder,
          $DocumentsUpdateCompanionBuilder,
          (Document, BaseReferences<_$AppDatabase, Documents, Document>),
          Document,
          PrefetchHooks Function()
        > {
  $DocumentsTableManager(_$AppDatabase db, Documents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DocumentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DocumentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DocumentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collection = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                collection: collection,
                id: id,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collection,
                required String id,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                collection: collection,
                id: id,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Documents, Document>(table),
                  BaseReferences<_$AppDatabase, Documents, Document>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DocumentsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Documents,
      Document,
      $DocumentsFilterComposer,
      $DocumentsOrderingComposer,
      $DocumentsAnnotationComposer,
      $DocumentsCreateCompanionBuilder,
      $DocumentsUpdateCompanionBuilder,
      (Document, BaseReferences<_$AppDatabase, Documents, Document>),
      Document,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $DocumentsTableManager get documents =>
      $DocumentsTableManager(_db, _db.documents);
}
