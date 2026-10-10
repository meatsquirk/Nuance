import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/store/source_photo_store.dart';

/// Exercises the [SourcePhotoStore] contract against every implementation.
void runPhotoContractTests(
  String name,
  Future<SourcePhotoStore> Function() build,
) {
  group('$name — SourcePhotoStore contract', () {
    late SourcePhotoStore store;
    setUp(() async => store = await build());

    test('save then read round-trips the bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final ref = await store.save(bytes);
      expect(await store.read(ref), bytes);
      expect(await store.exists(ref), isTrue);
    });

    test('read of an unknown reference is null', () async {
      expect(await store.read('missing'), isNull);
    });

    test('exists is false for an unknown reference', () async {
      expect(await store.exists('missing'), isFalse);
    });

    test('distinct saves get distinct references', () async {
      final a = await store.save(Uint8List.fromList([1]));
      final b = await store.save(Uint8List.fromList([2]));
      expect(a, isNot(b));
      expect(await store.read(a), Uint8List.fromList([1]));
      expect(await store.read(b), Uint8List.fromList([2]));
    });

    test('delete removes the stored photo', () async {
      final ref = await store.save(Uint8List.fromList([9]));
      await store.delete(ref);
      expect(await store.exists(ref), isFalse);
      expect(await store.read(ref), isNull);
    });

    test('delete of an unknown reference is a no-op', () async {
      await store.delete('missing');
      expect(await store.exists('missing'), isFalse);
    });

    test('saved bytes are copied — mutating the source does not leak', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final ref = await store.save(bytes);
      bytes[0] = 99;
      expect((await store.read(ref))!.first, 1);
    });
  });
}

void main() {
  Directory? fileDir;
  tearDown(() async {
    if (fileDir != null && fileDir!.existsSync()) {
      await fileDir!.delete(recursive: true);
    }
    fileDir = null;
  });

  runPhotoContractTests('InMemorySourcePhotoStore',
      () async => InMemorySourcePhotoStore());

  runPhotoContractTests('FileSourcePhotoStore', () async {
    fileDir = await Directory.systemTemp.createTemp('bs06_photos_');
    // Point at a not-yet-created subdirectory so `save` creates it (D-10).
    return FileSourcePhotoStore(Directory('${fileDir!.path}/photos'));
  });

  test('FileSourcePhotoStore creates its directory on first save', () async {
    final root = await Directory.systemTemp.createTemp('bs06_photos2_');
    fileDir = root;
    final sub = Directory('${root.path}/nested/photos');
    expect(sub.existsSync(), isFalse);
    final store = FileSourcePhotoStore(sub);
    await store.save(Uint8List.fromList([7]));
    expect(sub.existsSync(), isTrue);
  });
}
