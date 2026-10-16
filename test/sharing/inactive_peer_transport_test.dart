import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/sharing/exchange/peer_transport.dart';
import 'package:paint_color_assistant/sharing/inactive_peer_transport.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

void main() {
  group('InactivePeerTransport (CORE-4)', () {
    const transport = InactivePeerTransport();

    test('discover reaches no peer', () async {
      expect(await transport.discover(), isEmpty);
    });

    test('offer is an inert no-op (never reached — no peer)', () async {
      // Defined for completeness; a round short-circuits before offering because
      // discover() finds no one. Calling it directly must not throw.
      await expectLater(
        transport.offer(const Peer('nobody'), const <MixAccuracyRecord>[]),
        completes,
      );
    });

    test('receive returns nothing', () async {
      expect(await transport.receive(const Peer('nobody')), isEmpty);
    });

    test('accepts a runtime Peer handle', () async {
      // A non-const Peer (its id built at runtime) so the generative const
      // constructor is exercised at runtime, not only canonicalised at compile
      // time — the "const-ctor reads 0" coverage gotcha.
      final peer = Peer(_runtimeId());
      expect(peer.id, 'nobody');
      expect(await transport.receive(peer), isEmpty);
    });
  });
}

/// A runtime-computed id, so `Peer(_runtimeId())` is not a const expression.
String _runtimeId() => 'nobody';
