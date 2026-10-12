import 'package:flutter/widgets.dart';

import 'project_controller.dart';

/// Exposes the live [ProjectController] to the acceptance tests (bs-06).
///
/// The Palette screen's Projects view wraps its subtree in one of these
/// (mirroring bs-04's `RecipeReadEndpoint` and bs-06's `PaletteReadEndpoint`) so
/// a test can observe [ProjectController.projects], [ProjectController.openedProject],
/// [ProjectController.confusionPairs] and [ProjectController.lastExport] — the
/// Thens the rendered UI does not surface directly (e.g. AC-9's flagged pair,
/// AC-10's produced PDF). It is a test observation seam, not a UI control:
/// production screens read the controller they own, not this endpoint. SCREEN-1
/// mounts it over the Projects view.
///
/// Find it in a pumped tree with `find.byType(ProjectReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class ProjectReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [controller] to the subtree.
  const ProjectReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('project-read-endpoint');

  /// The controller whose state the tests observe.
  final ProjectController controller;

  /// The [ProjectController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Projects view provides one).
  static ProjectController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<ProjectReadEndpoint>();
    assert(endpoint != null, 'No ProjectReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(ProjectReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
