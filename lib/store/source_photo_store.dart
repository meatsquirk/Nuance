import 'dart:io';
import 'dart:typed_data';

/// Stores a project's source photo as bytes and hands back an opaque reference
/// (bs-06 DATA-2, plan D-10).
///
/// A project keeps only the *reference* this store returns, not the pixels; the
/// photo bytes live wherever the implementation puts them (an on-device file,
/// or memory in tests). These ACs never assert pixel content — only that a
/// saved photo is present and round-trips — so the shipped [FileSourcePhotoStore]
/// and the test [InMemorySourcePhotoStore] back the same contract and the
/// pixels stay out of the deterministic suite.
abstract interface class SourcePhotoStore {
  /// Stores [bytes] and returns the reference to retrieve them by.
  Future<String> save(Uint8List bytes);

  /// The bytes previously saved under [reference], or null if none exist.
  Future<Uint8List?> read(String reference);

  /// Whether a photo is stored under [reference].
  Future<bool> exists(String reference);

  /// Removes the photo stored under [reference]; a no-op if it is absent.
  Future<void> delete(String reference);
}

/// A [SourcePhotoStore] that writes each photo to a file under [directory]
/// (the shipped on-device sink).
///
/// [directory] is injected rather than resolved internally so the store is
/// testable over a temporary directory; the production wiring passes the
/// application-documents directory when the first persistent source consumes it
/// (PALETTE-1/PROJECT-1). References are the stored file names; [read] / [exists]
/// / [delete] resolve them back under [directory].
class FileSourcePhotoStore implements SourcePhotoStore {
  /// Creates a store writing photos into [directory] (created on first [save]).
  FileSourcePhotoStore(this.directory);

  /// The directory each photo file is written into.
  final Directory directory;

  int _counter = 0;

  @override
  Future<String> save(Uint8List bytes) async {
    await directory.create(recursive: true);
    final reference =
        'photo_${DateTime.now().microsecondsSinceEpoch}_${_counter++}';
    await _fileFor(reference).writeAsBytes(bytes, flush: true);
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async {
    final file = _fileFor(reference);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String reference) async => _fileFor(reference).exists();

  @override
  Future<void> delete(String reference) async {
    final file = _fileFor(reference);
    if (file.existsSync()) await file.delete();
  }

  File _fileFor(String reference) =>
      File('${directory.path}${Platform.pathSeparator}$reference');
}

/// An in-memory [SourcePhotoStore] holding photo bytes in a map (the test
/// double, D-10).
///
/// The persistence-free sink the acceptance harness and unit tests use so the
/// photo pixels never touch the filesystem. Bytes are copied in and out so a
/// caller cannot mutate stored bytes through a reference it handed to [save] or
/// received from [read].
class InMemorySourcePhotoStore implements SourcePhotoStore {
  final Map<String, Uint8List> _photos = {};
  int _counter = 0;

  @override
  Future<String> save(Uint8List bytes) async {
    final reference = 'photo_${_counter++}';
    _photos[reference] = Uint8List.fromList(bytes);
    return reference;
  }

  @override
  Future<Uint8List?> read(String reference) async {
    final bytes = _photos[reference];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<bool> exists(String reference) async => _photos.containsKey(reference);

  @override
  Future<void> delete(String reference) async {
    _photos.remove(reference);
  }
}
