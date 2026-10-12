import 'package:flutter/widgets.dart';

import 'palette_controller.dart';

/// Exposes the live [PaletteController] to the acceptance tests (bs-06).
///
/// The Palette screen wraps its subtree in one of these (mirroring bs-04's
/// `RecipeReadEndpoint`) so a test can observe [PaletteController.palettes],
/// [PaletteController.selectedPalette] and [PaletteController.myPaints] — the
/// Thens the rendered list does not surface directly (e.g. AC-4's "added with
/// its dataset provenance preserved", AC-5's active palette). It is a test
/// observation seam, not a UI control: production screens read the controller
/// they own, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(PaletteReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class PaletteReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const PaletteReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('palette-read-endpoint');

  /// The controller whose state the tests observe.
  final PaletteController controller;

  /// The [PaletteController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Palette screen provides one).
  static PaletteController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<PaletteReadEndpoint>();
    assert(endpoint != null, 'No PaletteReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(PaletteReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
