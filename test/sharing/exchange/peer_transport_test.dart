import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';

import '_support.dart';

void main() {
  group('Peer', () {
    test('is value-equal on its opaque id', () {
      expect(const Peer('a'), const Peer('a'));
      expect(const Peer('a').hashCode, const Peer('a').hashCode);
      expect(const Peer('a') == const Peer('b'), isFalse);
      expect(const Peer('a') == Object(), isFalse);
    });

    test('toString names the id', () {
      expect(const Peer('phone-7').toString(), 'Peer(phone-7)');
    });
  });

  group('PeerTransport (via a fake)', () {
    test('discover returns the reachable peers', () async {
      final transport = FakePeerTransport(peers: const [Peer('a'), Peer('b')]);
      expect(await transport.discover(), const [Peer('a'), Peer('b')]);
      expect(transport.discoverCalls, 1);
    });

    test('offer and receive honour the interface', () async {
      final transport = FakePeerTransport();
      await transport.offer(const Peer('a'), [record('x')]);
      expect(await transport.receive(const Peer('a')), isEmpty);
    });
  });
}
