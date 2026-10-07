import 'package:flutter/material.dart';

import '../a11y/haptics.dart';
import '../a11y/speech.dart';
import '../capture/capture_controller.dart';
import '../capture/capture_read_endpoint.dart';
import '../capture/capture_screen.dart';
import '../capture/source/capture_source.dart';
import '../color_science/color_science.dart';
import '../domain/color_coordinates.dart';
import '../domain/provenance.dart';
import '../domain/sample.dart';
import '../readout/readout_screen.dart';
import 'router.dart';

/// The sample the shipped bs-01 app opens the Readout screen on.
///
/// bs-01 ships the reading surface before capture exists (capture is bs-02,
/// D-1), so there is no painter-supplied sample yet. This fixed sample gives the
/// Readout a subject to render until bs-02 wires capture into
/// [AppDependencies.initialSample]. It is a plain [Sample] (canonical CIELAB +
/// provenance) with no derived values pre-computed — every presentable form is
/// derived by the COLOR behaviour phases from these coordinates.
const Sample demoSample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

/// The app-wide services assembled once at startup and injected down the tree.
///
/// A single immutable holder so production (`main.dart`) and the acceptance
/// harness (ITEST-1) construct the app the same way, differing only in which
/// implementations they pass — the harness swaps the faked platform sinks
/// ([Speech], [Haptics]) and a test [ColorScience] while reusing [buildApp].
class AppDependencies {
  const AppDependencies({
    required this.colorScience,
    required this.speech,
    required this.haptics,
    this.router = const AppRouter(),
    this.initialSample = demoSample,
    this.captureSource,
  });

  /// Derives every presentable form of a sample's colour (COLOR stub for now).
  final ColorScience colorScience;

  /// Spoken output sink (A11Y stub for now; faked in the acceptance suite).
  final Speech speech;

  /// Haptic feedback sink (A11Y stub for now; faked in the acceptance suite).
  final Haptics haptics;

  /// Typed navigation into the comparison / recipes destinations.
  final AppRouter router;

  /// The sample the app opens the Readout screen on.
  ///
  /// bs-01 has no capture yet (D-1), so production defaults to [demoSample]; the
  /// acceptance harness injects a fixture here to read each scenario's sample
  /// through this same [buildApp] entry (capture replaces it in bs-02).
  final Sample initialSample;

  /// The capture source the app opens the Capture screen on, or null to open on
  /// the Readout (bs-02 D-2).
  ///
  /// When present, [buildApp] launches to the Capture screen reading from this
  /// source and capture commits navigate to the Readout (D-5); when null the app
  /// opens on the Readout for [initialSample], preserving bs-01's entry. The
  /// shipped app injects a [CaptureSource]; the bs-02 acceptance harness injects
  /// a fake with a known ground-truth scene.
  final CaptureSource? captureSource;
}

/// Exposes the app-wide [AppDependencies] to descendant widgets.
///
/// The Readout screen and its controller (READOUT-1) read the injected services
/// through [AppScope.of] rather than constructing them, so the same screen runs
/// unchanged against the production stubs and the acceptance suite's fakes.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  /// The services injected at the root by [buildApp].
  final AppDependencies dependencies;

  /// The [AppDependencies] injected by the nearest enclosing [AppScope].
  ///
  /// Throws if no [AppScope] is above [context]; every screen built by
  /// [buildApp] has one.
  static AppDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget.');
    return scope!.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}

/// Builds the root widget of the Paint Color Assistant.
///
/// The single production assembly entry (D-7): it injects [deps] via [AppScope]
/// and wires the router into a [MaterialApp]. The app opens on the Capture
/// screen when a [AppDependencies.captureSource] is injected (bs-02), and
/// otherwise on the [ReadoutScreen] for [AppDependencies.initialSample]
/// (bs-01's entry). `main.dart` and both acceptance harnesses construct the app
/// through this entry, differing only in the injected services, the initial
/// sample and the capture source.
Widget buildApp(AppDependencies deps) {
  return AppScope(
    dependencies: deps,
    child: MaterialApp(
      title: 'Paint Color Assistant',
      theme: ThemeData(useMaterial3: true),
      home: deps.captureSource == null
          ? ReadoutScreen(sample: deps.initialSample)
          : const CaptureHomeScreen(),
    ),
  );
}

/// The Capture screen the app opens on when a capture source is wired (bs-02).
///
/// It owns the [CaptureController] over the injected
/// [AppDependencies.captureSource] and wraps its subtree in a
/// [CaptureReadEndpoint] so the acceptance suite can observe the capture state.
/// The screen body is the SCREEN-1 [CaptureScreen] scaffold — the wireframe
/// regions E15–E21, the eyedropper and the stability indicator, bound to the
/// controller; the controller ownership and the endpoint wiring stay here.
class CaptureHomeScreen extends StatefulWidget {
  const CaptureHomeScreen({super.key});

  @override
  State<CaptureHomeScreen> createState() => _CaptureHomeScreenState();
}

class _CaptureHomeScreenState extends State<CaptureHomeScreen> {
  CaptureController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once, over the capture source injected above.
    if (_controller == null) {
      final source = AppScope.of(context).captureSource!;
      _controller = CaptureController(source: source);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CaptureReadEndpoint(
      key: CaptureReadEndpoint.endpointKey,
      controller: _controller!,
      child: CaptureScreen(controller: _controller!),
    );
  }
}
