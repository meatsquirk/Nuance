import 'package:flutter/material.dart';

import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import '../a11y/haptics.dart';
import '../a11y/speech.dart';
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
    this.cvdProfile = const CvdProfile(type: CvdType.deutan),
    this.confusionCheck = const NoopConfusionCheck(),
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

  /// The painter's colour-vision profile, read by [confusionCheck] (bs-03 D-4).
  ///
  /// Defaults to a deutan profile for bs-03's comparison scenarios; **bs-07**
  /// (CVD self-assessment) later populates it from the painter. Injected here so
  /// the confusion detector and the later simulation/daltonization features
  /// (bs-08/bs-10) all read one profile.
  final CvdProfile cvdProfile;

  /// Decides whether a compared pair is confusable for [cvdProfile] (AC-7/AC-8).
  ///
  /// Defaults to the inert [NoopConfusionCheck] so the assembled app wires the
  /// detector but flags nothing until CVD-2 supplies the dichromat projection.
  final ConfusionCheck confusionCheck;
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
/// and wires the router into a [MaterialApp] that opens on the [ReadoutScreen]
/// for [AppDependencies.initialSample]. `main.dart` and the acceptance harness
/// both construct the app through this entry, differing only in the injected
/// services and the initial sample.
Widget buildApp(AppDependencies deps) {
  return AppScope(
    dependencies: deps,
    child: MaterialApp(
      title: 'Paint Color Assistant',
      theme: ThemeData(useMaterial3: true),
      home: ReadoutScreen(sample: deps.initialSample),
    ),
  );
}
