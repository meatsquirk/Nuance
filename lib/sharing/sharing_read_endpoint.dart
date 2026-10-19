import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consent/sharing_consent.dart';

/// A read-only observation seam over the painter-facing sharing surface, for the
/// bs-14 acceptance suite (CORE-2).
///
/// Mirrors the sibling read endpoints (`CvdProfileReadEndpoint`,
/// `DisplayReadEndpoint`): an [InheritedWidget] the suite finds by its
/// [endpointKey] to read what the rendered UI does not surface as text — the
/// current [consent] (the offer copy and whether the painter has opted in) and
/// the **inventory of every user-visible sharing surface** the subsystem
/// exposes ([userFacingSharingSurfaces]).
///
/// The invisibility guarantee (AC-1) is asserted against that inventory: it must
/// never name peers, devices, syncing or a network. It is empty in the shell —
/// the subsystem shows the painter nothing — and the AC-1/AC-2 behaviour phases
/// keep it empty of those network concepts even once opt-in and the background
/// exchange exist (the only ever-permitted signal is "recipes improve over
/// time", which names no mechanism).
class SharingConsentReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [consent] and the [userFacingSharingSurfaces]
  /// inventory to the subtree.
  const SharingConsentReadEndpoint({
    required this.consent,
    this.userFacingSharingSurfaces = const <String>[],
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('sharing-consent-read-endpoint');

  /// The painter's current sharing consent (offer copy + opt-in state).
  final SharingConsent consent;

  /// Every user-visible sharing surface the subsystem exposes.
  ///
  /// Must stay empty of network concepts (peers, devices, syncing, a network) —
  /// the invisibility guarantee reads this. Empty in the shell.
  final List<String> userFacingSharingSurfaces;

  /// Whether the painter has opted in (AC-1).
  bool get consented => consent.consented;

  /// The plain-language offer copy presented to the painter (AC-1).
  String get offerCopy => consent.offerCopy;

  /// The nearest enclosing endpoint above [context]. Throws if there is none
  /// (every sharing-aware surface under `buildApp` has one).
  static SharingConsentReadEndpoint of(BuildContext context) {
    final endpoint = context
        .dependOnInheritedWidgetOfExactType<SharingConsentReadEndpoint>();
    assert(
      endpoint != null,
      'No SharingConsentReadEndpoint found above this widget.',
    );
    return endpoint!;
  }

  /// The nearest enclosing endpoint above [context], or null when there is none
  /// — for surfaces that also render in trees with no sharing mounted.
  static SharingConsentReadEndpoint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SharingConsentReadEndpoint>();

  @override
  bool updateShouldNotify(SharingConsentReadEndpoint oldWidget) =>
      consent != oldWidget.consent ||
      !listEquals(userFacingSharingSurfaces, oldWidget.userFacingSharingSurfaces);
}
