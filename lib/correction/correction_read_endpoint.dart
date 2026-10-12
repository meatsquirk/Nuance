import 'package:flutter/widgets.dart';

import 'correction_controller.dart';

/// Exposes the live [CorrectionController] to the acceptance tests.
///
/// The Correction screen wraps its subtree in one of these (mirroring bs-04's
/// `RecipeReadEndpoint`) so a test can observe the [CorrectionController.state]
/// — the target, the current mix, the photographed swatch, the difference, the
/// correction and the saved provenance — for the Thens the rendered UI does not
/// surface directly. It is a test observation seam, not a UI control: production
/// screens read the controller they own, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(CorrectionReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class CorrectionReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const CorrectionReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('correction-read-endpoint');

  /// The controller whose [CorrectionController.state] the tests observe.
  final CorrectionController controller;

  /// The [CorrectionController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Correction screen provides one).
  static CorrectionController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<CorrectionReadEndpoint>();
    assert(endpoint != null, 'No CorrectionReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(CorrectionReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
