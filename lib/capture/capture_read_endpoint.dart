import 'package:flutter/widgets.dart';

import 'capture_controller.dart';

/// Exposes the live [CaptureController] to the acceptance tests.
///
/// The Capture screen wraps its subtree in one of these so a test can read the
/// observable [CaptureState] — and, through [CaptureController.source], the
/// fake's known ground-truth scene — for the Thens the rendered UI does not
/// surface directly (the sampled / committed colour value, `framesAveraged`,
/// the accuracy tier). It is a test observation seam, not a UI control: production
/// screens read the controller they own, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(CaptureReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class CaptureReadEndpoint extends InheritedWidget {
  const CaptureReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('capture-read-endpoint');

  /// The controller whose [CaptureController.state] and
  /// [CaptureController.source] the tests observe.
  final CaptureController controller;

  /// The [CaptureController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Capture screen provides one).
  static CaptureController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<CaptureReadEndpoint>();
    assert(endpoint != null, 'No CaptureReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(CaptureReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
