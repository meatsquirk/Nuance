import 'exchange/peer_transport.dart';
import 'record/mix_accuracy_record.dart';

/// A [PeerTransport] that reaches no peer (bs-14 CORE-4).
///
/// The production default the background exchange runs over until the real
/// local-network transport (EXCHANGE-4) is sanctioned under G-4 and wired in.
/// [discover] finds no one, so a triggered gossip round short-circuits to the
/// AC-7 "no peer ⇒ no exchange" no-op and nothing ever crosses the device
/// boundary — the one off-device actor stays inert, honouring bs-12's
/// no-off-device-path guard while G-4 is unresolved. [offer] and [receive] are
/// never reached (there is no peer to reach) but are defined for completeness.
///
/// EXCHANGE-4 replaces this default with the mDNS/Bonjour + socket impl; the
/// silent-exchange wiring in `_SharingRoot` is unchanged by that swap.
class InactivePeerTransport implements PeerTransport {
  /// Creates the inert transport.
  const InactivePeerTransport();

  @override
  Future<List<Peer>> discover() async => const <Peer>[];

  @override
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records) async {}

  @override
  Future<List<MixAccuracyRecord>> receive(Peer peer) async =>
      const <MixAccuracyRecord>[];
}
