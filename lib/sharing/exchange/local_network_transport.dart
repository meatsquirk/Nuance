import 'dart:io';
import 'dart:typed_data';

import '../record/mix_accuracy_record.dart';
import 'local_network_io.dart';
import 'peer_transport.dart';
import 'record_wire.dart';

/// A peer found on the local network, with the transport-level address its
/// records are fetched from / offered to.
///
/// The [sessionId] is the opaque, per-session id surfaced to the gossip layer as
/// [Peer.id] (never an account or a stable device id); [host] and [port] are the
/// socket address the [RecordLink] uses and are never shown to the gossip layer.
class PeerAddress {
  /// Creates an address for the peer advertising [sessionId] at [host]:[port].
  const PeerAddress({
    required this.sessionId,
    required this.host,
    required this.port,
  });

  /// The opaque, per-session id (becomes [Peer.id]).
  final String sessionId;

  /// The peer's socket host.
  final InternetAddress host;

  /// The peer's socket port.
  final int port;
}

/// Discovers peers advertising the bs-14 service on the local network.
///
/// The real implementation ([MulticastLanDiscoverer]) uses mDNS/Bonjour-style
/// multicast; the acceptance/unit tests inject a fake that returns a scripted
/// list, so [LocalNetworkTransport]'s orchestration is exercised without real
/// I/O.
abstract interface class LanDiscoverer {
  /// The peers advertising within [window]; empty when none is reachable.
  Future<List<PeerAddress>> discover(Duration window);
}

/// Moves record frames to and from a discovered peer over a direct socket.
///
/// The real implementation ([SocketRecordLink]) opens a TCP connection; the
/// tests inject a fake. Only the bytes [encodeRecordFrames] produces ever cross
/// [offer], and [receive] hands back only what [RecordFrameReader] decoded — the
/// wire carries nothing but [MixAccuracyRecord] serializations (G-4 boundary).
abstract interface class RecordLink {
  /// Hands [peer] the already-framed record [frames]. Best-effort (D-5).
  Future<void> offer(PeerAddress peer, Uint8List frames);

  /// The record frames [peer] is currently offering, as raw bytes.
  Future<Uint8List> receive(PeerAddress peer);
}

/// The real [PeerTransport] (bs-14 EXCHANGE-4): local-network discovery + a
/// direct socket link, carrying only [MixAccuracyRecord] serializations.
///
/// It is the single off-device actor and the one bs-12 network exception
/// (D-4, G-4): no server, no account, no stored addressing — it discovers peers
/// on the local network right now, offers each the records it is missing and
/// takes back what it is offered, and is best-effort throughout (a discovery or
/// socket failure is swallowed, never surfaced, D-5). The gossip diff/dedup lives
/// in `GossipExchange`; this type only moves bytes.
///
/// It delegates the actual mDNS/socket I/O to the injected [LanDiscoverer] /
/// [RecordLink] seams (defaulting to the real [MulticastLanDiscoverer] /
/// [SocketRecordLink]); the acceptance and unit suites inject fakes, so this
/// orchestration is fully covered while the platform discovery/socket path is
/// verified by the on-device sign-off walkthrough (D-3).
class LocalNetworkTransport implements PeerTransport {
  /// Creates the transport over the given discovery / link seams.
  LocalNetworkTransport({
    LanDiscoverer? discoverer,
    RecordLink? link,
    this.discoveryWindow = const Duration(seconds: 2),
  })  : _discoverer = discoverer ?? const MulticastLanDiscoverer(),
        _link = link ?? const SocketRecordLink();

  final LanDiscoverer _discoverer;
  final RecordLink _link;

  /// How long [discover] listens for peer advertisements before returning.
  final Duration discoveryWindow;

  /// The address each discovered session id was last reached at. Rebuilt every
  /// [discover]; [offer] / [receive] resolve a [Peer] back to its address
  /// through it, so the opaque [Peer] never carries a network address.
  final Map<String, PeerAddress> _addressBySession = <String, PeerAddress>{};

  @override
  Future<List<Peer>> discover() async {
    final List<PeerAddress> addresses;
    try {
      addresses = await _discoverer.discover(discoveryWindow);
    } catch (_) {
      return const <Peer>[]; // best-effort — a discovery failure is silent (D-5)
    }
    _addressBySession.clear();
    final List<Peer> peers = <Peer>[];
    for (final PeerAddress address in addresses) {
      // Keep the first address seen for a session id; collapse duplicate
      // advertisements of the same peer to one Peer.
      if (_addressBySession.containsKey(address.sessionId)) {
        continue;
      }
      _addressBySession[address.sessionId] = address;
      peers.add(Peer(address.sessionId));
    }
    return peers;
  }

  @override
  Future<void> offer(Peer peer, List<MixAccuracyRecord> records) async {
    final PeerAddress? address = _addressBySession[peer.id];
    if (address == null || records.isEmpty) {
      return; // unknown peer or nothing to offer — nothing crosses
    }
    try {
      await _link.offer(address, encodeRecordFrames(records));
    } catch (_) {
      // Best-effort delivery: a socket failure is silent (D-5).
    }
  }

  @override
  Future<List<MixAccuracyRecord>> receive(Peer peer) async {
    final PeerAddress? address = _addressBySession[peer.id];
    if (address == null) {
      return const <MixAccuracyRecord>[];
    }
    try {
      final Uint8List bytes = await _link.receive(address);
      return decodeRecordFrames(bytes);
    } catch (_) {
      // A socket failure or a malformed/non-record payload yields nothing — a
      // peer cannot push anything but a well-formed record across the boundary.
      return const <MixAccuracyRecord>[];
    }
  }
}
