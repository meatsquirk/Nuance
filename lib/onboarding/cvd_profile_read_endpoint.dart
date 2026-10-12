import 'package:flutter/widgets.dart';

import '../store/cvd_profile_store.dart';

/// Exposes the [CvdProfileStore] to the acceptance tests (bs-07 PROFILE-1).
///
/// Mirrors bs-06's `ProjectReadEndpoint` / bs-04's `RecipeReadEndpoint`: a test
/// observation seam, not a UI control. The onboarding host (FLOW-1) wraps its
/// subtree in one of these so a test can read the persisted profile and its
/// [CvdProfileStore.count] — asserting AC-13's "exactly one profile written"
/// and its fields — without reaching into the storage engine. Production screens
/// read the store they own, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(CvdProfileReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class CvdProfileReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [store] to the subtree.
  const CvdProfileReadEndpoint({
    required this.store,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('cvd-profile-read-endpoint');

  /// The profile store whose persisted profile and count the tests observe.
  final CvdProfileStore store;

  /// The [CvdProfileStore] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every onboarding host provides one).
  static CvdProfileStore of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<CvdProfileReadEndpoint>();
    assert(
      endpoint != null,
      'No CvdProfileReadEndpoint found above this widget.',
    );
    return endpoint!.store;
  }

  @override
  bool updateShouldNotify(CvdProfileReadEndpoint oldWidget) =>
      store != oldWidget.store;
}
