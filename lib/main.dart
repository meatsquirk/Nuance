import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'a11y/haptics.dart';
import 'a11y/speech.dart';
import 'app/build_app.dart';
import 'capture/source/software_capture_source.dart';
import 'color_science/color_science_impl.dart';
import 'domain/color_coordinates.dart';
import 'projects/project_source.dart';
import 'recipes/palette_source.dart';
import 'store/drift_persistent_store.dart';
import 'store/persistent_store.dart';
import 'store/source_photo_store.dart';

/// Entry point for the Paint Color Assistant application.
///
/// Opens the on-device persistent store over the application-documents
/// directory, loads the persistent palette/project sources and launches via
/// [buildApp], the single assembly entry both acceptance harnesses also use.
/// The store I/O is asynchronous, so `main` awaits [productionDependencies]
/// before the first frame; with a capture source wired the app still opens on
/// the Capture screen (bs-02), and the Palette screen (bs-06) reads the real
/// store when later navigation reaches it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(buildApp(await productionDependencies()));
}

/// The deterministic capture source the shipped app opens on (bs-02 D-2).
///
/// A software source over a fixed demo scene; the native CameraX / AVFoundation
/// sources are platform work tracked outside this pure-Dart build, wired behind
/// the same `CaptureSource` interface.
SoftwareCaptureSource demoCaptureSource() => SoftwareCaptureSource(
      const SceneSpec(
        groundTruth: ColorCoordinates(lightness: 58, a: 36, b: 34),
      ),
    );

/// Opens the shipped file-backed persistence and assembles the production
/// dependencies (bs-06 SCREEN-1, the deferred DATA-2 store wiring).
///
/// Resolves the application-documents directory (path_provider), opens the
/// SQLite-backed [DriftPersistentStore] over a file there and a
/// [FileSourcePhotoStore] beside it, builds the persistent palette/project
/// sources and loads them before assembly (the controllers read their sources
/// synchronously), then hands the loaded seams to [assembleDependencies]. The
/// platform binding lives only here; the store and sources stay pure-Dart
/// components over injected seams, so the unit suite substitutes in-memory
/// doubles and runs without a device.
Future<AppDependencies> productionDependencies() async {
  final directory = await getApplicationDocumentsDirectory();
  final store = DriftPersistentStore(
    NativeDatabase(File('${directory.path}/paint_color_assistant.sqlite')),
  );
  final sourcePhotoStore =
      FileSourcePhotoStore(Directory('${directory.path}/source_photos'));
  final paletteSource = PersistentPaletteSource(store);
  final projectSource = PersistentProjectSource(store);
  await paletteSource.load();
  await projectSource.load();
  return assembleDependencies(
    store: store,
    sourcePhotoStore: sourcePhotoStore,
    paletteSource: paletteSource,
    projectSource: projectSource,
  );
}

/// Assembles the production [AppDependencies] over the given persistence.
///
/// The pure, synchronous half of [productionDependencies], split out so the
/// wiring is testable without the path_provider platform channel: it pairs the
/// shipped stub services (the [ColorScienceImpl] stub, the no-op
/// [NoopSpeech] / [NoopHaptics] sinks) and the deterministic
/// [demoCaptureSource] (so the app opens on the Capture screen) with the
/// injected [store], [sourcePhotoStore] and the loaded [paletteSource] /
/// [projectSource] the Palette screen reads. Later features replace the stub
/// implementations behind the same [AppDependencies] seam without touching this
/// entry point.
AppDependencies assembleDependencies({
  required PersistentStore store,
  required SourcePhotoStore sourcePhotoStore,
  required PaletteSource paletteSource,
  required ProjectSource projectSource,
}) {
  return AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: const NoopSpeech(),
    haptics: const NoopHaptics(),
    captureSource: demoCaptureSource(),
    store: store,
    sourcePhotoStore: sourcePhotoStore,
    paletteSource: paletteSource,
    projectSource: projectSource,
  );
}
