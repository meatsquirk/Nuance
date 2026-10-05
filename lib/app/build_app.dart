import 'package:flutter/material.dart';

import '../a11y/haptics.dart';
import '../a11y/speech.dart';
import '../color_science/color_science.dart';
import 'router.dart';

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
  });

  /// Derives every presentable form of a sample's colour (COLOR stub for now).
  final ColorScience colorScience;

  /// Spoken output sink (A11Y stub for now; faked in the acceptance suite).
  final Speech speech;

  /// Haptic feedback sink (A11Y stub for now; faked in the acceptance suite).
  final Haptics haptics;

  /// Typed navigation into the comparison / recipes destinations.
  final AppRouter router;
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
/// and wires the router into a [MaterialApp] that opens on the Readout route.
/// For this shell phase the Readout destination is the [_ReadoutPlaceholder]
/// below; READOUT-1 replaces it with the real Readout screen behind this same
/// entry, so neither `main.dart` nor the acceptance harness changes.
Widget buildApp(AppDependencies deps) {
  return AppScope(
    dependencies: deps,
    child: MaterialApp(
      title: 'Paint Color Assistant',
      theme: ThemeData(useMaterial3: true),
      home: const _ReadoutPlaceholder(),
    ),
  );
}

/// The bs-01 placeholder for the Readout route, replaced by READOUT-1.
///
/// It exists so [buildApp] opens on the Readout destination now; it renders only
/// a marker so there is a route to launch to before the real screen lands.
class _ReadoutPlaceholder extends StatelessWidget {
  const _ReadoutPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Readout'),
      ),
    );
  }
}
