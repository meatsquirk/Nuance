import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/main.dart' as app;
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';
import 'package:paint_color_assistant/store/source_photo_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A path_provider substitute returning a per-test temporary directory, so
/// `main.dart`'s production store wiring (which resolves the application-
/// documents directory) runs under host `flutter test` without a device.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pca_smoke_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('assembleDependencies wires the shipped stub implementations', () {
    final deps = app.assembleDependencies(
      store: InMemoryPersistentStore(),
      sourcePhotoStore: InMemorySourcePhotoStore(),
      paletteSource: const InMemoryPaletteSource(),
      projectSource: const InMemoryProjectSource(),
    );
    expect(deps.colorScience, isA<ColorScienceImpl>());
    expect(deps.speech, isA<NoopSpeech>());
    expect(deps.haptics, isA<NoopHaptics>());
    // bs-02: the shipped app wires a software capture source, so it opens on
    // the Capture screen (D-2).
    expect(deps.captureSource, isA<SoftwareCaptureSource>());
    // bs-06 SCREEN-1: the store, photo sink and persistent sources are wired.
    expect(deps.store, isA<InMemoryPersistentStore>());
    expect(deps.sourcePhotoStore, isA<InMemorySourcePhotoStore>());
    expect(deps.paletteSource, isA<InMemoryPaletteSource>());
    expect(deps.projectSource, isA<InMemoryProjectSource>());
  });

  test('productionDependencies opens the file-backed store and loads it',
      () async {
    final deps = await app.productionDependencies();
    // The real file-backed store and source-photo sink are wired (bs-06
    // SCREEN-1 deferred store wiring), and the persistent sources loaded.
    expect(deps.store, isNotNull);
    expect(deps.sourcePhotoStore, isNotNull);
    expect(deps.paletteSource.palettes(), isEmpty);
    expect(deps.projectSource.projects(), isEmpty);
    expect(deps.captureSource, isA<SoftwareCaptureSource>());
  });

  testWidgets('main() boots the app to the Capture route', (tester) async {
    // Exercises the main() entry point so the scaffold has full line coverage.
    // bs-02's entry is unchanged: with a capture source wired, the app opens on
    // the Capture screen rather than bs-01's Readout (build_app D-2). bs-06
    // SCREEN-1 made main() async (it opens the store first).
    await app.main();
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Capture'), findsOneWidget);
  });
}
