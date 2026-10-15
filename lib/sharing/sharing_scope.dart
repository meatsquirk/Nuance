import 'package:flutter/widgets.dart';

import 'consent/consent_store.dart';

/// The crowd-refinement subsystem's injected dependencies (bs-14 CORE-2).
///
/// A single immutable holder, mirroring `AppDependencies`: the DI seam through
/// which the sharing subsystem's services are supplied, so production and the
/// acceptance harness assemble it the same way and differ only in which
/// implementations they pass. CORE-2 populates only the [consentStore]; the
/// later shells add their services behind this one holder — RECORD-1 the record
/// builder, EXCHANGE-1 the gossip exchange, MERGE-1 the evidence merge — so new
/// dependencies reach the tree without re-threading the wiring.
@immutable
class SharingDependencies {
  /// Creates the sharing dependencies over [consentStore].
  const SharingDependencies({required this.consentStore});

  /// The write/read seam for the painter's opt-in consent (AC-1).
  final ConsentStore consentStore;
}

/// Exposes the [SharingDependencies] to descendant widgets (bs-14 CORE-2).
///
/// The sharing subsystem's DI seam, symmetric to `AppScope`: `buildApp` wraps
/// the app in one (above the `MaterialApp`, so pushed routes read it too) when a
/// persistent store is wired, and the opt-in action and background exchange read
/// their services through [of] rather than constructing them. A shell for now —
/// wiring it in is behaviour-neutral: nothing yet reads the scope, nothing opts
/// in and nothing exchanges.
class SharingScope extends InheritedWidget {
  /// Wraps [child], exposing [dependencies] to the subtree.
  const SharingScope({
    required this.dependencies,
    required super.child,
    super.key,
  });

  /// The sharing services injected by `buildApp`.
  final SharingDependencies dependencies;

  /// The [SharingDependencies] injected by the nearest enclosing [SharingScope].
  ///
  /// Throws if none is above [context]; the sharing subsystem's own surfaces are
  /// only built under a scope `buildApp` mounted.
  static SharingDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SharingScope>();
    assert(scope != null, 'No SharingScope found above this widget.');
    return scope!.dependencies;
  }

  /// The [SharingDependencies] from the nearest enclosing [SharingScope], or
  /// null when there is none above [context] — for surfaces that must also
  /// render standalone (outside the app assembly), where sharing is simply
  /// inactive.
  static SharingDependencies? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SharingScope>()?.dependencies;

  @override
  bool updateShouldNotify(SharingScope oldWidget) =>
      dependencies != oldWidget.dependencies;
}
