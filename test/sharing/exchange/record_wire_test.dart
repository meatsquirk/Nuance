import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/sharing/exchange/record_wire.dart';
import 'package:paint_color_assistant/sharing/record/mix_accuracy_record.dart';

MixAccuracyRecord _record({
  List<String> paints = const <String>['ti-white', 'ultramarine'],
  String brand = 'Winsor & Newton',
  String line = 'Professional',
  String medium = 'oil',
  MeasurementTier tier = MeasurementTier.instrument,
  double l = 52.17,
  double a = 12.34,
  double b = -5.67,
}) =>
    MixAccuracyRecord(
      paintCombination: PaintCombination.of(paints),
      declaredPalette: DeclaredPalette(brand: brand, line: line, medium: medium),
      measuredColour: MeasuredColour(
        lab: ColorCoordinates(lightness: l, a: a, b: b),
        lch: CielchCoordinates(lightness: l, chroma: 13.6, hue: 335.2),
      ),
      tier: tier,
    );

void main() {
  group('record wire codec (EXCHANGE-4)', () {
    test('kFrameLengthBytes is the 4-byte length prefix', () {
      expect(kFrameLengthBytes, 4);
    });

    test('recordToWire carries exactly the four record fields', () {
      final wire = recordToWire(_record());
      expect(wire.keys.toSet(),
          <String>{'paints', 'palette', 'lab', 'lch', 'tier'});
      expect(wire['paints'], <String>['ti-white', 'ultramarine']);
      expect(wire['palette'], <String, Object?>{
        'brand': 'Winsor & Newton',
        'line': 'Professional',
        'medium': 'oil',
      });
      expect((wire['lab']! as Map)['a'], 12.34);
      expect((wire['lch']! as Map)['h'], 335.2);
      expect(wire['tier'], 'instrument');
      // The map is JSON-encodable (nothing but primitives / lists / maps).
      expect(() => jsonEncode(wire), returnsNormally);
    });

    test('a record round-trips losslessly through a single frame', () {
      final original = _record();
      final decoded = decodeRecordFrames(encodeRecordFrames(<MixAccuracyRecord>[original]));
      expect(decoded, hasLength(1));
      expect(decoded.single, original);
      expect(decoded.single.contentHash, original.contentHash);
    });

    test('every measurement tier round-trips', () {
      for (final tier in MeasurementTier.values) {
        final original = _record(tier: tier);
        expect(recordFromWire(recordToWire(original)).tier, tier);
      }
    });

    test('several records round-trip in one frame stream, in order', () {
      final a = _record(paints: const <String>['a']);
      final b = _record(paints: const <String>['b'], tier: MeasurementTier.cardLess);
      final decoded = decodeRecordFrames(encodeRecordFrames(<MixAccuracyRecord>[a, b]));
      expect(decoded, <MixAccuracyRecord>[a, b]);
    });

    test('an empty record list encodes to an empty buffer and decodes to none',
        () {
      final bytes = encodeRecordFrames(const <MixAccuracyRecord>[]);
      expect(bytes, isEmpty);
      expect(decodeRecordFrames(bytes), isEmpty);
    });

    test('decodeRecordFrames rejects a trailing partial frame', () {
      final whole = encodeRecordFrames(<MixAccuracyRecord>[_record()]);
      final truncated = Uint8List.sublistView(whole, 0, whole.length - 1);
      expect(() => decodeRecordFrames(truncated), throwsFormatException);
    });
  });

  group('recordFromWire validation — only a record can be reconstructed', () {
    Uint8List frameOf(Object? json) {
      final payload = utf8.encode(jsonEncode(json));
      final header = ByteData(4)..setUint32(0, payload.length, Endian.big);
      final out = BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(payload);
      return out.toBytes();
    }

    Map<String, Object?> validWire() => recordToWire(_record());

    test('a non-object payload is rejected', () {
      expect(() => recordFromWire(<int>[1, 2, 3]), throwsFormatException);
      expect(() => decodeRecordFrames(frameOf(<int>[1, 2, 3])),
          throwsFormatException);
    });

    test('a missing / wrong-typed paints list is rejected', () {
      final wire = validWire()..['paints'] = 'not-a-list';
      expect(() => recordFromWire(wire), throwsFormatException);
    });

    test('a non-string paint id is rejected', () {
      final wire = validWire()..['paints'] = <Object?>['ok', 7];
      expect(() => recordFromWire(wire), throwsFormatException);
    });

    test('a non-object palette / lab / lch is rejected', () {
      expect(() => recordFromWire(validWire()..['palette'] = 'x'),
          throwsFormatException);
      expect(() => recordFromWire(validWire()..['lab'] = 'x'),
          throwsFormatException);
      expect(() => recordFromWire(validWire()..['lch'] = 'x'),
          throwsFormatException);
    });

    test('a non-string palette field is rejected', () {
      final wire = validWire();
      (wire['palette']! as Map)['brand'] = 42;
      expect(() => recordFromWire(wire), throwsFormatException);
    });

    test('a non-number colour component is rejected', () {
      final wire = validWire();
      (wire['lab']! as Map)['l'] = 'bright';
      expect(() => recordFromWire(wire), throwsFormatException);
    });

    test('a non-string tier is rejected', () {
      expect(() => recordFromWire(validWire()..['tier'] = 3),
          throwsFormatException);
    });

    test('an unknown tier name is rejected', () {
      expect(() => recordFromWire(validWire()..['tier'] = 'telepathy'),
          throwsFormatException);
    });
  });

  group('RecordFrameReader — chunked stream reassembly', () {
    test('an incomplete length prefix stays fully buffered', () {
      final reader = RecordFrameReader()..addBytes(<int>[0x00, 0x00]);
      expect(reader.drain(), isEmpty);
      expect(reader.pendingByteCount, 2);
    });

    test('a frame split across chunks is held until its payload arrives', () {
      final whole = encodeRecordFrames(<MixAccuracyRecord>[_record()]);
      final reader = RecordFrameReader();
      // First chunk: the header + half the payload.
      final split = whole.length - 5;
      reader.addBytes(Uint8List.sublistView(whole, 0, split));
      expect(reader.drain(), isEmpty, reason: 'payload not fully arrived');
      expect(reader.pendingByteCount, split);
      // Second chunk: the rest.
      reader.addBytes(Uint8List.sublistView(whole, split));
      final records = reader.drain();
      expect(records, hasLength(1));
      expect(reader.pendingByteCount, 0);
    });

    test('two frames coalesced in one chunk both decode, tail left buffered',
        () {
      final a = _record(paints: const <String>['a']);
      final b = _record(paints: const <String>['b']);
      final whole = encodeRecordFrames(<MixAccuracyRecord>[a, b]);
      // Append a partial third header so a tail is left over.
      final reader = RecordFrameReader()
        ..addBytes(whole)
        ..addBytes(<int>[0x00, 0x00]);
      final records = reader.drain();
      expect(records, <MixAccuracyRecord>[a, b]);
      expect(reader.pendingByteCount, 2, reason: 'the partial header tail');
    });
  });
}
