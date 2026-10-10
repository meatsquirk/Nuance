import 'package:flutter/widgets.dart';

import 'recipe_controller.dart';

/// Exposes the live [RecipeController] to the acceptance tests.
///
/// The Recipes screen wraps its subtree in one of these (mirroring bs-03's
/// `ComparisonReadEndpoint`) so a test can observe the [RecipeController.state]
/// — the target, the selected palette, the ordered recipes, the wet/dry mode and
/// the manual-entry error — for the Thens the rendered UI does not surface
/// directly. It is a test observation seam, not a UI control: production screens
/// read the controller they own, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(RecipeReadEndpoint)` (or reach the
/// nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class RecipeReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const RecipeReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('recipe-read-endpoint');

  /// The controller whose [RecipeController.state] the tests observe.
  final RecipeController controller;

  /// The [RecipeController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Recipes screen provides one).
  static RecipeController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<RecipeReadEndpoint>();
    assert(endpoint != null, 'No RecipeReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(RecipeReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
