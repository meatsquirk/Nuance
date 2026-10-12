import 'package:flutter/widgets.dart';

import 'display_controller.dart';
import 'display_settings.dart';

/// Exposes the live [DisplayController] — and through it the current
/// [DisplaySettings] — to the acceptance tests (bs-08 DISPLAY-2).
///
/// `buildApp` wraps the app in one (mirroring bs-06's `PaletteReadEndpoint`) so
/// a test can observe the display state the rendered UI does not surface as text
/// — which type is simulated, at what severity, and whether grayscale is on
/// (AC-2..AC-7). It is a test observation seam, not a UI control: production
/// surfaces read `DisplayScope`, not this endpoint.
///
/// Find it with `find.byKey(DisplayReadEndpoint.endpointKey)`, or reach the
/// nearest one from a descendant via [of].
class DisplayReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const DisplayReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('display-read-endpoint');

  /// The controller whose state the tests observe.
  final DisplayController controller;

  /// The current display settings (convenience for [controller].settings).
  DisplaySettings get settings => controller.settings;

  /// The [DisplayController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every app assembly provides one).
  static DisplayController of(BuildContext context) {
    final endpoint = context
        .dependOnInheritedWidgetOfExactType<DisplayReadEndpoint>();
    assert(endpoint != null, 'No DisplayReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(DisplayReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
