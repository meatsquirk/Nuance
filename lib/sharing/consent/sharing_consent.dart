import 'package:flutter/foundation.dart';

/// The painter's crowd-refinement consent and the plain-language offer they are
/// shown (bs-14 AC-1).
///
/// An immutable value, the one piece of sharing state the painter ever acts on:
/// a single opt-in, phrased only in terms of the outcome ("help improve recipe
/// accuracy by sharing anonymous mix results"). It deliberately carries no
/// network vocabulary — no peers, devices, syncing or network — because the
/// whole subsystem is invisible to the painter (SI; the invisibility guarantee
/// is asserted through `SharingConsentReadEndpoint.userFacingSharingSurfaces`).
///
/// The default is **not opted in** ([consented] `false`): nothing is shared, and
/// no exchange runs, until the painter opts in once (CORE-3). Persisted through
/// the [ConsentStore]; a shell value for now (CORE-2) — no opt-in action exists
/// yet, so the app only ever holds this not-consented default.
@immutable
class SharingConsent {
  /// Creates a consent value; defaults to the not-opted-in state with the
  /// standard [defaultOfferCopy].
  const SharingConsent({
    this.consented = false,
    this.offerCopy = defaultOfferCopy,
  });

  /// The exact plain-language offer the painter is shown once (AC-1).
  ///
  /// Frozen as the spec's wording verbatim ("help improve recipe accuracy by
  /// sharing anonymous mix results") — outcome-only, naming no mechanism. The
  /// AC-1 acceptance test asserts the offered copy equals this string.
  static const String defaultOfferCopy =
      'help improve recipe accuracy by sharing anonymous mix results';

  /// The one ongoing, mechanism-free signal the subsystem ever shows the painter
  /// once they have opted in (AC-2): that their recipes get better over time.
  ///
  /// Names an *outcome*, never a mechanism — no peers, devices, syncing or a
  /// network — so it passes the invisibility guarantee the
  /// `SharingConsentReadEndpoint.userFacingSharingSurfaces` inventory enforces.
  /// `_SharingRoot` surfaces exactly this (and nothing else) in the opted-in
  /// state, in place of the pre-opt-in offer (CORE-4).
  static const String recipesImproveSignal = 'Your recipes improve over time.';

  /// Whether the painter has opted in to crowd-refinement (default `false`).
  final bool consented;

  /// The plain-language offer copy presented to the painter (AC-1).
  final String offerCopy;

  /// A copy of this consent with [consented] and/or [offerCopy] replaced.
  ///
  /// The opt-in action (CORE-3) records consent by flipping [consented] to
  /// `true` through this, leaving the offer copy unchanged.
  SharingConsent copyWith({bool? consented, String? offerCopy}) =>
      SharingConsent(
        consented: consented ?? this.consented,
        offerCopy: offerCopy ?? this.offerCopy,
      );

  @override
  bool operator ==(Object other) =>
      other is SharingConsent &&
      other.consented == consented &&
      other.offerCopy == offerCopy;

  @override
  int get hashCode => Object.hash(consented, offerCopy);

  @override
  String toString() =>
      'SharingConsent(consented: $consented, offerCopy: "$offerCopy")';
}
