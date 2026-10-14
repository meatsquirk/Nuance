import 'package:flutter/widgets.dart';

import '../store/cvd_profile_store.dart';

/// Exposes the [CvdProfileStore] to a subtree (bs-07 PROFILE-1; bs-10 CONTROL-2).
///
/// Mirrors bs-06's `ProjectReadEndpoint` / bs-04's `RecipeReadEndpoint`: an
/// observation seam. The onboarding host (FLOW-1) wraps its subtree in a *keyed*
/// one (its [endpointKey]) so the acceptance suite can read the persisted
/// profile and its [CvdProfileStore.count] — asserting AC-13's "exactly one
/// profile written" and its fields — without reaching into the storage engine.
///
/// bs-10 (CONTROL-2) also mounts one at the app root (`buildApp`), **unkeyed**,
/// so the daltonization settings control can consult [CvdProfileStore.hasSavedProfile]
/// and prompt for a self-assessment when nothing has been saved (AC-10). It is
/// left unkeyed so the self-assessment suite's `find.byKey(endpointKey)` still
/// resolves to exactly the onboarding host's keyed endpoint.
///
/// Find the keyed endpoint with `find.byKey(endpointKey)`, or reach the nearest
/// store above a descendant via [of] (asserts one is present) or [maybeOf]
/// (null when none is — for surfaces that must also render standalone).
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

  /// The [CvdProfileStore] from the nearest enclosing endpoint above [context],
  /// or null when there is none — for surfaces (such as the daltonization
  /// control, bs-10 AC-10) that also render in trees with no profile store
  /// mounted, where they fall back to showing no prompt.
  static CvdProfileStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CvdProfileReadEndpoint>()?.store;

  @override
  bool updateShouldNotify(CvdProfileReadEndpoint oldWidget) =>
      store != oldWidget.store;
}
