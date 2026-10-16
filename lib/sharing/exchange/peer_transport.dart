import 'package:flutter/foundation.dart';

import '../record/mix_accuracy_record.dart';

/// An opaque handle to a peer reachable on the local network right now (bs-14
/// EXCHANGE-1).
///
/// A peer is identified only by a transient, per-session [id] the transport
/// assigns — never an account, a stable device identifier or a network address
/// the caller could store or correlate. Two [Peer]s are equal when their ids
/// match, so the gossip layer can key a round by the peer it talked to without
/// learning anything about who that peer is.
@immutable
class Peer {
  /// Creates a peer handle from its transport-assigned [id].
  const Peer(this.id);

  /// The transport-assigned, per-session identifier. Opaque to the gossip layer.
  final String id;

  @override
  bool operator ==(Object other) => other is Peer && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Peer($id)';
}

/// The single off-device actor in bs-14 — the one boundary a mix-accuracy record
/// ever crosses (D-4), and the one bs-12 network exception the EXCHANGE module
/// reconciles under G-4.
///
/// It is deliberately small and account-free: [discover] finds the peers
/// reachable right now on the local network, [offer] hands a peer the records it
/// is missing, and [receive] returns the records a peer is offering. Only
/// [MixAccuracyRecord] serializations ever cross it; nothing personal and no
/// other type does. The acceptance suite supplies an in-process loopback fake;
/// EXCHANGE-4 supplies the real mDNS/Bonjour + socket implementation.
abstract interface class PeerTransport {
  /// The peers reachable on the local network at this moment, or an empty list
  /// when none is — best-effort, never surfacing "no peer" as an error (D-5).
  Future<List<Peer>> discover();

  /// Hands [peer] the [records] it is missing. Best-effort from the caller's
  /// point of view; a delivery failure is silent (D-5).
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records);

  /// The records [peer] is currently offering, or an empty list when it offers
  /// nothing.
  Future<List<MixAccuracyRecord>> receive(Peer peer);
}
