import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/store/drift_persistent_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

/// Exercises the [PersistentStore] contract against a freshly-built store.
///
/// Run against every implementation so the in-memory double and the shipped
/// drift store are held to the same behaviour (DATA-2's interface-contract
/// approach).
void runContractTests(String name, Future<PersistentStore> Function() build) {
  group('$name — PersistentStore contract', () {
    late PersistentStore store;

    setUp(() async => store = await build());
    tearDown(() async => store.close());

    test('get returns null for an absent document', () async {
      expect(await store.get('paints', 'missing'), isNull);
    });

    test('put then get round-trips a JSON-shaped document', () async {
      await store.put('paints', 'p1', {
        'name': 'Cadmium Red',
        'opacity': 0.8,
        'tags': ['warm', 'opaque'],
        'discontinued': false,
        'line': null,
      });
      expect(await store.get('paints', 'p1'), {
        'name': 'Cadmium Red',
        'opacity': 0.8,
        'tags': ['warm', 'opaque'],
        'discontinued': false,
        'line': null,
      });
    });

    test('put replaces an existing document under the same id', () async {
      await store.put('paints', 'p1', {'name': 'first'});
      await store.put('paints', 'p1', {'name': 'second'});
      expect(await store.get('paints', 'p1'), {'name': 'second'});
      expect((await store.list('paints')).length, 1);
    });

    test('list is empty for an unknown collection', () async {
      expect(await store.list('projects'), isEmpty);
    });

    test('list returns every document in ascending id order', () async {
      await store.put('paints', 'c', {'n': 3});
      await store.put('paints', 'a', {'n': 1});
      await store.put('paints', 'b', {'n': 2});
      final docs = await store.list('paints');
      expect(docs.map((d) => d.id), ['a', 'b', 'c']);
      expect(docs.map((d) => d.data['n']), [1, 2, 3]);
    });

    test('collections are isolated from one another', () async {
      await store.put('paints', 'x', {'k': 'paint'});
      await store.put('projects', 'x', {'k': 'project'});
      expect((await store.get('paints', 'x'))!['k'], 'paint');
      expect((await store.get('projects', 'x'))!['k'], 'project');
    });

    test('delete removes a stored document', () async {
      await store.put('paints', 'p1', {'name': 'x'});
      await store.delete('paints', 'p1');
      expect(await store.get('paints', 'p1'), isNull);
      expect(await store.list('paints'), isEmpty);
    });

    test('delete of an absent document is a no-op', () async {
      await store.delete('paints', 'missing');
      expect(await store.list('paints'), isEmpty);
    });

    test('stored data is copied in — later mutation does not leak', () async {
      final data = <String, Object?>{'name': 'x'};
      await store.put('paints', 'p1', data);
      data['name'] = 'mutated';
      expect((await store.get('paints', 'p1'))!['name'], 'x');
    });

    test('returned data is copied out — mutating it does not leak', () async {
      await store.put('paints', 'p1', {'name': 'x'});
      final got = (await store.get('paints', 'p1'))!;
      got['name'] = 'mutated';
      expect((await store.get('paints', 'p1'))!['name'], 'x');
    });
  });
}

void main() {
  runContractTests('InMemoryPersistentStore', () async => InMemoryPersistentStore());
  runContractTests('DriftPersistentStore.memory', () async => DriftPersistentStore.memory());

  group('DriftPersistentStore over a file executor', () {
    late Directory dir;
    tearDown(() async {
      if (dir.existsSync()) await dir.delete(recursive: true);
    });

    test('persists documents across store instances on the same file', () async {
      dir = await Directory.systemTemp.createTemp('bs06_store_');
      final file = File('${dir.path}/app.db');

      final first = DriftPersistentStore(NativeDatabase(file));
      await first.put('projects', 'proj1', {'size': '24×30 in'});
      await first.close();

      final second = DriftPersistentStore(NativeDatabase(file));
      expect(await second.get('projects', 'proj1'), {'size': '24×30 in'});
      await second.close();
    });
  });
}
