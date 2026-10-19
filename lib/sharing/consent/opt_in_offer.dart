import 'dart:async';

import 'package:flutter/material.dart';

import '../sharing_read_endpoint.dart';
import '../sharing_scope.dart';
import 'sharing_consent.dart';

/// The one-time plain-language opt-in offer the painter is shown (bs-14 AC-1).
///
/// The subsystem's single user-visible surface: a labelled button carrying the
/// outcome-only [SharingConsent.offerCopy] ("help improve recipe accuracy by
/// sharing anonymous mix results"), deliberately naming no mechanism — no peers,
/// devices, syncing or a network (SI; the invisibility guarantee). Opting in
/// records consent once through the injected [ConsentStore]; the offer is then
/// never shown again (the opt-in is one-time).
///
/// It reads the current consent from the [SharingConsentReadEndpoint] and the
/// store from the [SharingScope] that `buildApp` mounts, so it reacts to the
/// opt-in live (the endpoint rebuilds when consent changes). Outside a
/// sharing-enabled tree — a bare unit tree or a build with no persistent store,
/// where neither scope is mounted — it renders nothing, so it is inert there.
class SharingOptInOffer extends StatelessWidget {
  /// Creates the opt-in offer surface.
  const SharingOptInOffer({super.key});

  /// The key the offer control carries, so the acceptance suite can find and tap
  /// it through the public widget surface (AC-1). Frozen to the string the AC-1
  /// test looks the offer up by.
  static const Key offerKey = Key('sharing-opt-in-offer');

  @override
  Widget build(BuildContext context) {
    final endpoint = SharingConsentReadEndpoint.maybeOf(context);
    final scope = SharingScope.maybeOf(context);
    // Inert outside a sharing-enabled tree, and gone once opted in — the
    // one-time offer is never re-presented after the painter has opted in.
    if (endpoint == null || scope == null || endpoint.consented) {
      return const SizedBox.shrink();
    }
    final consent = endpoint.consent;
    final store = scope.consentStore;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        key: offerKey,
        onPressed: () =>
            unawaited(store.save(consent.copyWith(consented: true))),
        child: Text(consent.offerCopy),
      ),
    );
  }
}
