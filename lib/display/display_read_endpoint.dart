import 'package:flutter/widgets.dart';

import '../a11y/cvd/cvd_profile.dart';
import 'color_simulation.dart';
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

  /// Whether the display-only daltonization remap is on (bs-10), surfaced for
  /// the acceptance suite the way [settings] surfaces simulation/grayscale.
  bool get daltonization => settings.daltonization;

  /// The swatch colour the app displays for a true [original], for a painter
  /// with [profile], under the current [settings] — the effective displayed
  /// colour the acceptance suite observes (bs-10 AC-1/AC-2).
  ///
  /// Routes through the one shared [displayedSwatchColor] chokepoint, so a test
  /// reads exactly the colour `ColorChip` paints: the daltonization remap when
  /// it is on, the simulation otherwise (identity while both views are off).
  Color displayedColor(Color original, CvdProfile profile) =>
      displayedSwatchColor(original, settings, profile);

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
