import 'package:flutter/widgets.dart';

import 'comparison_controller.dart';

/// Exposes the live [ComparisonController] to the acceptance tests.
///
/// The Comparison screen wraps its subtree in one of these (mirroring bs-02's
/// `CaptureReadEndpoint`) so a test can observe the [ComparisonController.state]
/// — the two slots, the derived [difference] reading (ΔE00, verdict, the three
/// decomposition lines) and the [confusable] flag — for the Thens the rendered
/// UI does not surface directly. It is a test observation seam, not a UI
/// control: production screens read the controller they own, not this endpoint.
/// Kept above the Readout push (AC-10/AC-11) so a test reading state after
/// navigating away still finds it.
///
/// Find it in a pumped tree with `find.byType(ComparisonReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class ComparisonReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const ComparisonReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('comparison-read-endpoint');

  /// The controller whose [ComparisonController.state] the tests observe.
  final ComparisonController controller;

  /// The [ComparisonController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Comparison screen provides one).
  static ComparisonController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<ComparisonReadEndpoint>();
    assert(endpoint != null,
        'No ComparisonReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(ComparisonReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
