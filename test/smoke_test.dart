import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/capture/source/camera_capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/main.dart' as app;
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';
import 'package:paint_color_assistant/store/source_photo_store.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
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

/// A camera-plugin substitute returning a fixed camera list, so `main.dart`'s
/// bs-19 PERM-5 startup probe (`availableCameras()`) resolves as pure Dart
/// under host `flutter test` — no device, and no platform-channel round trip
/// that a `testWidgets` fake-async zone would never pump. An empty list models
/// a no-camera host, so the shipped assembly opens on the software scene, the
/// same default these smoke tests assert.
class _FakeCameraPlatform extends CameraPlatform with MockPlatformInterfaceMixin {
  _FakeCameraPlatform(this.cameras);

  final List<CameraDescription> cameras;

  @override
  Future<List<CameraDescription>> availableCameras() async => cameras;
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pca_smoke_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    CameraPlatform.instance = _FakeCameraPlatform(const <CameraDescription>[]);
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
    // bs-06 PROJECT-6: the PDF export is delivered through the production
    // `printing` share wrapper (AC-10).
    expect(deps.pdfShareSink, same(app.sharePdfToDevice));
    // bs-07 PROFILE-1 (D-3): with no cvdProfile passed, assembly defaults to the
    // deutan profile — behaviour unchanged until the painter saves an assessment.
    expect(deps.cvdProfile, const CvdProfile(type: CvdType.deutan));
  });

  test('assembleDependencies opens on the live camera when one is present', () {
    // bs-19 PERM-5 (§9 production activation): with the device probe reporting a
    // camera (hasCamera true), the shipped assembly selects the real
    // CameraCaptureSource so the app opens on the live feed. The Capture host
    // then prompts for access (AC-7) and falls back on denial. hasCamera
    // defaults false, so every existing assembly and the acceptance harness
    // keep the software scene (asserted above).
    final deps = app.assembleDependencies(
      store: InMemoryPersistentStore(),
      sourcePhotoStore: InMemorySourcePhotoStore(),
      paletteSource: const InMemoryPaletteSource(),
      projectSource: const InMemoryProjectSource(),
      hasCamera: true,
    );
    expect(deps.captureSource, isA<CameraCaptureSource>());
  });

  test('sharePdfToDevice hands the exported bytes to the printing share sheet',
      () async {
    // bs-06 PROJECT-6 (AC-10): the single platform call for PDF export. The
    // `printing` plugin's `net.nfet.printing` method channel is mocked so the
    // real share path runs under host `flutter test` without a device popup,
    // mirroring the path_provider fake above.
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('net.nfet.printing');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 1; // non-zero → shared
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final bytes = Uint8List.fromList(const [1, 2, 3, 4]);

    await app.sharePdfToDevice(bytes, 'Harbor at Dusk.pdf');

    expect(calls, hasLength(1));
    expect(calls.single.method, 'sharePdf');
    final args = calls.single.arguments as Map;
    expect(args['doc'], bytes);
    expect(args['name'], 'Harbor at Dusk.pdf');
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
    // bs-07 PROFILE-1 (D-3): the saved profile is loaded at assembly; a fresh
    // store has none, so it falls back to the deutan default.
    expect(deps.cvdProfile, const CvdProfile(type: CvdType.deutan));
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
