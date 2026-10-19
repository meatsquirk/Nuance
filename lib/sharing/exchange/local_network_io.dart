import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'local_network_transport.dart';

/// The real `dart:io` local-network I/O behind [LocalNetworkTransport]
/// (bs-14 EXCHANGE-4) — mDNS/Bonjour-style multicast discovery and a direct TCP
/// record link.
///
/// **This file is the sanctioned off-device path (D-4, G-4).** It is the one
/// place bs-12's `offDeviceSenders` guard exempts, and the bs-14 boundary guard
/// asserts that the only thing it ever writes to or reads from a socket is a
/// `MixAccuracyRecord` serialization (the record frames built by
/// `encodeRecordFrames` and decoded by `RecordFrameReader`) — nothing personal
/// and no other type crosses.
///
/// **Coverage / manual gap (D-3).** The orchestration that uses these seams
/// (`LocalNetworkTransport`) is fully unit-tested over fakes. The socket and
/// multicast calls *here* cannot run deterministically off-device (they need a
/// real LAN and a second install), so their method bodies are the named,
/// owner-accepted manual gap: verified by the sign-off on-device walkthrough,
/// not by the automated suite. The constructors are const and trivial so
/// constructing the production default is coverable.
///
/// The symmetric server side — a device advertising its own presence beacon and
/// serving its shareable records to a connecting peer — is wired on the device
/// in the walkthrough; this file provides the discovering/connecting half the
/// frozen [PeerTransport] client interface needs.

/// The administratively-scoped multicast group the app advertises on. A private
/// (239.0.0.0/8) group, not the reserved mDNS group, so the beacons never clash
/// with the OS's own mDNS/Bonjour traffic.
final InternetAddress kDiscoveryGroup = InternetAddress('239.14.77.14');

/// The UDP port presence beacons are multicast on.
const int kDiscoveryPort = 51477;

/// The beacon protocol tag, so a stray datagram on the group is ignored.
const String kBeaconTag = 'bs14-mixshare/1';

/// mDNS/Bonjour-style presence discovery over administratively-scoped multicast.
class MulticastLanDiscoverer implements LanDiscoverer {
  /// Creates the discoverer.
  const MulticastLanDiscoverer();

  @override
  Future<List<PeerAddress>> discover(Duration window) async {
    final RawDatagramSocket socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      kDiscoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    final List<PeerAddress> peers = <PeerAddress>[];
    try {
      socket.joinMulticast(kDiscoveryGroup);
      socket.multicastLoopback = false;
      // Prompt any listening peer to announce itself.
      socket.send(utf8.encode('$kBeaconTag;query'), kDiscoveryGroup,
          kDiscoveryPort);
      final Completer<void> done = Completer<void>();
      final Timer timer = Timer(window, () {
        if (!done.isCompleted) done.complete();
      });
      final StreamSubscription<RawSocketEvent> sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final Datagram? datagram = socket.receive();
        if (datagram == null) return;
        final PeerAddress? peer = _parseBeacon(datagram);
        if (peer != null) peers.add(peer);
      });
      await done.future;
      timer.cancel();
      await sub.cancel();
    } finally {
      socket.close();
    }
    return peers;
  }

  /// Parses an announce beacon (`<tag>;announce;<sessionId>;<port>`) into a
  /// [PeerAddress], or null when the datagram is not a well-formed announce.
  PeerAddress? _parseBeacon(Datagram datagram) {
    final String text = utf8.decode(datagram.data, allowMalformed: true);
    final List<String> parts = text.split(';');
    if (parts.length != 4 || parts[0] != kBeaconTag || parts[1] != 'announce') {
      return null;
    }
    final int? port = int.tryParse(parts[3]);
    if (port == null) return null;
    return PeerAddress(
      sessionId: parts[2],
      host: datagram.address,
      port: port,
    );
  }
}

/// A direct TCP record link: connects to a peer, pushing or pulling only record
/// frames.
class SocketRecordLink implements RecordLink {
  /// Creates the link.
  const SocketRecordLink();

  @override
  Future<void> offer(PeerAddress peer, Uint8List frames) async {
    // The push endpoint: write only record frames, then close. Nothing but the
    // record serialization crosses (the push/fetch distinction is by endpoint
    // on the device, not by any extra byte on the wire).
    final Socket socket = await Socket.connect(peer.host, peer.port);
    try {
      socket.add(frames);
      await socket.flush();
    } finally {
      await socket.close();
    }
  }

  @override
  Future<Uint8List> receive(PeerAddress peer) async {
    // The fetch endpoint: the peer streams its record frames on connect; collect
    // them whole and hand them back for the transport to decode through the one
    // record-only path.
    final Socket socket = await Socket.connect(peer.host, peer.port);
    final BytesBuilder raw = BytesBuilder(copy: false);
    try {
      await for (final Uint8List chunk in socket) {
        raw.add(chunk);
      }
    } finally {
      await socket.close();
    }
    return raw.toBytes();
  }
}
