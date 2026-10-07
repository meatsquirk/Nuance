import 'package:flutter/material.dart';

import 'a11y/haptics.dart';
import 'a11y/speech.dart';
import 'app/build_app.dart';
import 'capture/source/software_capture_source.dart';
import 'color_science/color_science_impl.dart';
import 'domain/color_coordinates.dart';

/// Entry point for the Paint Color Assistant application.
///
/// Assembles the production dependencies — the [ColorScienceImpl] stub, the
/// no-op [NoopSpeech] / [NoopHaptics] platform sinks (bs-01 ships pure-Dart
/// logic with no native integration, D-1) and a deterministic
/// [SoftwareCaptureSource] (the pure-Dart capture default behind the SI
/// `CaptureSource` interface, D-2) — and launches via [buildApp], the single
/// assembly entry both acceptance harnesses also use. With a capture source
/// wired, the app opens on the Capture screen (bs-02).
void main() {
  runApp(buildApp(productionDependencies()));
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

/// The dependencies the shipped app runs with.
///
/// Exposed so `main()` stays a one-liner and the production wiring is testable
/// on its own. Later features replace the stub implementations behind the same
/// [AppDependencies] seam without touching this entry point.
AppDependencies productionDependencies() {
  return AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: const NoopSpeech(),
    haptics: const NoopHaptics(),
    captureSource: demoCaptureSource(),
  );
}
