import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/sharing/exchange/local_network_io.dart';
import 'package:paint_color_assistant/sharing/exchange/local_network_transport.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/exchange/record_wire.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

MixAccuracyRecord _record(String paint) => MixAccuracyRecord(
      paintCombination: PaintCombination.of(<String>[paint]),
      declaredPalette: const DeclaredPalette(
          brand: 'W&N', line: 'Pro', medium: 'oil'),
      measuredColour: const MeasuredColour(
        lab: ColorCoordinates(lightness: 50, a: 1, b: 2),
        lch: CielchCoordinates(lightness: 50, chroma: 3, hue: 90),
      ),
      tier: MeasurementTier.cardLess,
    );

PeerAddress _addr(String session, {int port = 7000}) => PeerAddress(
      sessionId: session,
      host: InternetAddress('127.0.0.1'),
      port: port,
    );

class _FakeDiscoverer implements LanDiscoverer {
  _FakeDiscoverer(this._result);
  final List<PeerAddress> _result;
  Duration? lastWindow;

  @override
  Future<List<PeerAddress>> discover(Duration window) async {
    lastWindow = window;
    return _result;
  }
}

class _ThrowingDiscoverer implements LanDiscoverer {
  @override
  Future<List<PeerAddress>> discover(Duration window) async =>
      throw const SocketException('no network');
}

class _FakeLink implements RecordLink {
  _FakeLink({this.toReceive = const <int>[], this.throwOnOffer = false,
      this.throwOnReceive = false});
  final List<int> toReceive;
  final bool throwOnOffer;
  final bool throwOnReceive;
  final List<({PeerAddress peer, Uint8List frames})> offered = [];

  @override
  Future<void> offer(PeerAddress peer, Uint8List frames) async {
    if (throwOnOffer) throw const SocketException('refused');
    offered.add((peer: peer, frames: frames));
  }

  @override
  Future<Uint8List> receive(PeerAddress peer) async {
    if (throwOnReceive) throw const SocketException('refused');
    return Uint8List.fromList(toReceive);
  }
}

void main() {
  group('LocalNetworkTransport.discover', () {
    test('maps discovered addresses to opaque peers', () async {
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A'), _addr('B')]),
        link: _FakeLink(),
      );
      final peers = await transport.discover();
      expect(peers.map((p) => p.id), <String>['A', 'B']);
    });

    test('collapses duplicate advertisements of the same session id', () async {
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(
            <PeerAddress>[_addr('A', port: 1), _addr('A', port: 2), _addr('B')]),
        link: _FakeLink(),
      );
      final peers = await transport.discover();
      expect(peers.map((p) => p.id), <String>['A', 'B']);
    });

    test('a discovery failure is silent — no peer (D-5)', () async {
      final transport = LocalNetworkTransport(
        discoverer: _ThrowingDiscoverer(),
        link: _FakeLink(),
      );
      expect(await transport.discover(), isEmpty);
    });

    test('passes the configured discovery window to the discoverer', () async {
      final discoverer = _FakeDiscoverer(const <PeerAddress>[]);
      final transport = LocalNetworkTransport(
        discoverer: discoverer,
        link: _FakeLink(),
        discoveryWindow: const Duration(milliseconds: 250),
      );
      await transport.discover();
      expect(discoverer.lastWindow, const Duration(milliseconds: 250));
    });

    test('defaults the discovery window to two seconds', () {
      expect(LocalNetworkTransport(
        discoverer: _FakeDiscoverer(const <PeerAddress>[]),
        link: _FakeLink(),
      ).discoveryWindow, const Duration(seconds: 2));
    });
  });

  group('LocalNetworkTransport.offer', () {
    test('offers a discovered peer exactly the encoded record frames', () async {
      final link = _FakeLink();
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A')]),
        link: link,
      );
      await transport.discover();
      final records = <MixAccuracyRecord>[_record('x'), _record('y')];
      await transport.offer(const Peer('A'), records);
      expect(link.offered, hasLength(1));
      expect(link.offered.single.peer.sessionId, 'A');
      // What crossed is exactly the record serialization, decodable back.
      expect(decodeRecordFrames(link.offered.single.frames), records);
    });

    test('does nothing for an unknown (undiscovered) peer', () async {
      final link = _FakeLink();
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(const <PeerAddress>[]),
        link: link,
      );
      await transport.discover();
      await transport.offer(const Peer('ghost'), <MixAccuracyRecord>[_record('x')]);
      expect(link.offered, isEmpty);
    });

    test('does nothing when there is nothing to offer', () async {
      final link = _FakeLink();
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A')]),
        link: link,
      );
      await transport.discover();
      await transport.offer(const Peer('A'), const <MixAccuracyRecord>[]);
      expect(link.offered, isEmpty);
    });

    test('a delivery failure is silent (D-5)', () async {
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A')]),
        link: _FakeLink(throwOnOffer: true),
      );
      await transport.discover();
      await expectLater(
        transport.offer(const Peer('A'), <MixAccuracyRecord>[_record('x')]),
        completes,
      );
    });
  });

  group('LocalNetworkTransport.receive', () {
    test('decodes the record frames a peer offers back', () async {
      final records = <MixAccuracyRecord>[_record('p'), _record('q')];
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A')]),
        link: _FakeLink(toReceive: encodeRecordFrames(records)),
      );
      await transport.discover();
      expect(await transport.receive(const Peer('A')), records);
    });

    test('returns nothing for an unknown peer', () async {
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(const <PeerAddress>[]),
        link: _FakeLink(),
      );
      await transport.discover();
      expect(await transport.receive(const Peer('ghost')), isEmpty);
    });

    test('a receive failure yields nothing (D-5)', () async {
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A')]),
        link: _FakeLink(throwOnReceive: true),
      );
      await transport.discover();
      expect(await transport.receive(const Peer('A')), isEmpty);
    });

    test('a malformed (non-record) payload yields nothing — the boundary holds',
        () async {
      final transport = LocalNetworkTransport(
        discoverer: _FakeDiscoverer(<PeerAddress>[_addr('A')]),
        link: _FakeLink(toReceive: const <int>[0xDE, 0xAD, 0xBE, 0xEF, 0x01]),
      );
      await transport.discover();
      expect(await transport.receive(const Peer('A')), isEmpty);
    });
  });

  group('production default seams', () {
    test('an unconfigured transport uses the real local-network I/O seams', () {
      // Construct the default (real) transport — no I/O happens until a round is
      // triggered. This exercises the `?? const Multicast… / SocketRecordLink`
      // fallbacks.
      expect(LocalNetworkTransport(), isA<PeerTransport>());
    });

    test('the real I/O seams construct (bodies verified on-device, D-3)', () {
      // Runtime (non-const) construction so the generative const constructors are
      // exercised, not only canonicalised. Their socket/multicast method bodies
      // are the owner-accepted manual gap (sign-off walkthrough).
      expect(MulticastLanDiscoverer(), isA<LanDiscoverer>());
      expect(SocketRecordLink(), isA<RecordLink>());
    });

    test('the discovery group is an administratively-scoped multicast address',
        () {
      // Referencing the discovery constants evaluates them (they are read only
      // from the socket path otherwise), so the only uncovered lines in the I/O
      // file are the genuine socket/multicast statements (the D-3 manual gap).
      expect(kDiscoveryGroup.address, '239.14.77.14');
      expect(kDiscoveryGroup.type, InternetAddressType.IPv4);
      expect(kDiscoveryPort, 51477);
      expect(kBeaconTag, 'bs14-mixshare/1');
    });
  });
}
