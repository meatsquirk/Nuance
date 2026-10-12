import 'dart:typed_data';

import 'package:paint_color_assistant/store/source_photo_store.dart';

/// A recording [SourcePhotoStore] for the bs-06 acceptance suite (ITEST-1).
///
/// The suite's single faked file sink: it stands in for the on-device
/// [FileSourcePhotoStore] (plan D-10) so a project's **source photo** is stored
/// and round-tripped without touching the filesystem, and it records every save
/// so a test can assert what infrastructure received. A project keeps only the
/// opaque [reference] this sink returns, never the pixels — exactly the
/// production contract — so these ACs assert *presence and round-trip*, not
/// pixel content.
///
/// The AC-10 PDF export is **not** routed through a file sink: plan D-6 keeps
/// the produced sheet as `ProjectController.lastExport` bytes the test reads off
/// the controller, so no disk write is involved there. Should a later phase
/// (PROJECT-6) choose to also write the PDF to a file, it can share this sink.
///
/// Bytes are copied in and out (like the production [InMemorySourcePhotoStore])
/// so a caller cannot mutate stored bytes through a reference it handed to
/// [save] or received from [read].
class FakeFileSink implements SourcePhotoStore {
  final Map<String, Uint8List> _photos = {};
  int _counter = 0;

  /// The references saved so far, in save order (test observation seam).
  final List<String> saved = [];

  /// How many [save] calls this sink has recorded.
  int get writes => saved.length;

  /// The bytes of the most recent [save], or null if nothing was saved.
  Uint8List? get lastBytes =>
      saved.isEmpty ? null : Uint8List.fromList(_photos[saved.last]!);

  /// Pre-stores [bytes] under an explicit [reference] without recording a save.
  ///
  /// Lets a scenario seed a project whose [reference] is already pinned (e.g. a
  /// fixture project that carries a known `sourcePhotoRef`) so the photo
  /// round-trips, while [writes] still counts only the saves the app itself
  /// drove through [save].
  void seed(String reference, Uint8List bytes) {
    _photos[reference] = Uint8List.fromList(bytes);
  }

  @override
  Future<String> save(Uint8List bytes) async {
    final reference = 'fake-photo-${_counter++}';
    _photos[reference] = Uint8List.fromList(bytes);
    saved.add(reference);
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
    saved.remove(reference);
  }
}
