import 'package:flutter/widgets.dart';

import 'display_controller.dart';

/// Exposes the app-wide [DisplayController] to every descendant that renders
/// colour (bs-08 DISPLAY-2).
///
/// An [InheritedNotifier] over the controller, so a surface that reads it (via
/// [of] / [maybeOf]) rebuilds when the painter changes a display setting —
/// the chokepoint through which simulation (AC-2/AC-3/AC-4) and the root
/// grayscale filter (AC-6) react. `buildApp` wraps the whole app in one, above
/// the `MaterialApp`, so pushed routes read it too (mirroring `AppScope`).
class DisplayScope extends InheritedNotifier<DisplayController> {
  /// Wraps [child], exposing [controller] to the subtree and rebuilding
  /// dependents when it notifies.
  const DisplayScope({
    required DisplayController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The [DisplayController] from the nearest enclosing scope, registering the
  /// caller to rebuild on change. Throws if there is none above [context] —
  /// every surface built under `buildApp` has one.
  static DisplayController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DisplayScope>();
    assert(scope != null, 'No DisplayScope found above this widget.');
    return scope!.notifier!;
  }

  /// The [DisplayController] from the nearest enclosing scope, or null when
  /// there is none — for surfaces (such as `ColorChip`) that must also render
  /// standalone, outside the app assembly, where they fall back to the default
  /// (identity) view.
  static DisplayController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DisplayScope>()?.notifier;
}
