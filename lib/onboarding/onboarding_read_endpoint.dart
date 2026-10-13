import 'package:flutter/widgets.dart';

import 'onboarding_controller.dart';

/// Exposes the live [OnboardingController] to the acceptance tests.
///
/// The onboarding host wraps its subtree in one of these (mirroring bs-03's
/// `ComparisonReadEndpoint` and bs-06's palette endpoints) so a test can observe
/// the [OnboardingController.state] — the step index, the lighting flags, the
/// starting prior, the screening / arrangement / threshold results, the
/// assembled estimate, the subjective calibration and the saved flag — plus the
/// [OnboardingController.steps] / [OnboardingController.stepTotal] for the
/// progress Thens the rendered UI does not surface directly. It is a test
/// observation seam, not a UI control: the screens read the controller they are
/// given, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(OnboardingReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class OnboardingReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const OnboardingReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('onboarding-read-endpoint');

  /// The controller whose [OnboardingController.state] the tests observe.
  final OnboardingController controller;

  /// The [OnboardingController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every onboarding host provides one).
  static OnboardingController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<OnboardingReadEndpoint>();
    assert(
      endpoint != null,
      'No OnboardingReadEndpoint found above this widget.',
    );
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(OnboardingReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
