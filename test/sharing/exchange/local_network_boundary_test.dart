// bs-14 boundary guard (EXCHANGE-4, G-4).
//
// The owner sanctioned exactly one off-device path (D-4, G-4): bs-14's
// consented, record-only, local-network peer transport. bs-12's `offDeviceSenders`
// scan exempts the one file that performs the socket / multicast I/O
// (`lib/sharing/exchange/local_network_io.dart`). This guard holds that
// exemption honest by asserting, both as a codec property and as a source-level
// invariant, that **only a `MixAccuracyRecord` serialization ever crosses
// `PeerTransport`** — nothing personal, no other type.
//
// It reads the `lib/` source through `dart:io` on the host VM (cwd = repo root),
// the same way the bs-12 source guard does.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/sharing/exchange/record_wire.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

import '../../../integration_test/nfr/guards/source_guard.dart';

const String _ioFile = 'lib/sharing/exchange/local_network_io.dart';
const String _transportFile = 'lib/sharing/exchange/local_network_transport.dart';

MixAccuracyRecord _record() => MixAccuracyRecord(
      paintCombination: PaintCombination.of(const <String>['a', 'b']),
      declaredPalette: const DeclaredPalette(
          brand: 'W&N', line: 'Pro', medium: 'oil'),
      measuredColour: const MeasuredColour(
        lab: ColorCoordinates(lightness: 51.2, a: -3.4, b: 7.8),
        lch: CielchCoordinates(lightness: 51.2, chroma: 8.5, hue: 113.6),
      ),
      tier: MeasurementTier.referenceCard,
    );

void main() {
  group('bs-14 boundary: only a record serialization crosses', () {
    test('the record serialization round-trips losslessly', () {
      final original = _record();
      final decoded = decodeRecordFrames(
          encodeRecordFrames(<MixAccuracyRecord>[original]));
      expect(decoded.single, original,
          reason: 'a received record must be value-equal to the sent one');
    });

    test('a non-record payload cannot be reconstructed', () {
      expect(() => recordFromWire(<String, Object?>{'arbitrary': 'blob'}),
          throwsFormatException);
    });
  });

  group('bs-14 boundary: the sanctioned off-device path is exactly one file', () {
    test('the allow-list names only the local-network I/O file', () {
      expect(sanctionedOffDevicePathFiles, <String>{_ioFile});
    });

    test('the lib/ off-device sweep is empty with the sanctioned file present',
        () {
      // The real sweep stays green: the one sanctioned egress is exempt, every
      // other would still be flagged.
      expect(offDeviceSenders(), isEmpty,
          reason: 'only the sanctioned local-network path may send off-device');
    });

    test('the exemption guards a real egress (the file genuinely sends)', () {
      final source = File(_ioFile).readAsStringSync();
      expect(source, contains('Socket.connect'),
          reason: 'the sanctioned file must actually open a socket');
      expect(source, contains('RawDatagramSocket.bind'),
          reason: 'the sanctioned file must actually discover over multicast');
    });

    test('the sanctioned file serializes nothing — it moves only record bytes',
        () {
      final source = File(_ioFile).readAsStringSync();
      // No serialization lives here: the only serialization is record_wire's
      // record-only codec, so the bytes this file moves can only be record
      // frames handed to it as an opaque Uint8List.
      for (final forbidden in const <String>['jsonEncode', 'jsonDecode', 'toJson']) {
        expect(source.contains(forbidden), isFalse,
            reason: 'the sanctioned file must not serialize anything ($forbidden)');
      }
    });

    test('the transport offers only encoded record frames over the link', () {
      final source = File(_transportFile).readAsStringSync();
      expect(source, contains('_link.offer(address, encodeRecordFrames(records))'),
          reason: 'the only bytes offered to a peer are a record serialization');
    });
  });
}
