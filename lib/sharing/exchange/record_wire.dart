import 'dart:convert';
import 'dart:typed_data';

import '../../domain/color_coordinates.dart';
import '../record/mix_accuracy_record.dart';

/// The wire serialization and framing for the one thing bs-14 ever sends over
/// the network: a [MixAccuracyRecord] (D-4, G-4 boundary).
///
/// This module is deliberately pure — no `dart:io`, no sockets — so the whole of
/// it is unit-tested and the boundary guard can assert that *only* a
/// [MixAccuracyRecord] serialization crosses [PeerTransport]
/// ([LocalNetworkTransport] writes nothing to the wire but the bytes
/// [encodeRecordFrames] produces, and reads records back only through
/// [RecordFrameReader]). The actual mDNS/socket I/O lives in
/// `local_network_transport.dart`; it moves these bytes and nothing else.
///
/// **Format.** Each record is a small JSON object carrying exactly the record's
/// four fields — the sorted paint ids, the declared palette, the measured colour
/// in CIELAB *and* CIELCh, and the measurement tier — and nothing about the
/// painter. The JSON is UTF-8 encoded and prefixed with a 4-byte big-endian
/// length, so several records stream over one socket and a reader can split them
/// back out of an arbitrarily chunked byte stream. The serialization is
/// *lossless* (unlike [MixAccuracyRecord.canonicalForm], which rounds for the
/// content hash): a decoded record is value-equal to the one that was encoded,
/// so a received record merges and re-hashes identically on the far device.

/// The JSON keys of a wire record. A decoded object missing any of them, or
/// carrying anything else in a field, is rejected ([recordFromWire]) — the
/// structural half of "only a record crosses".
const String _kPaints = 'paints';
const String _kPalette = 'palette';
const String _kLab = 'lab';
const String _kLch = 'lch';
const String _kTier = 'tier';

/// The number of bytes the length prefix occupies before each record payload.
const int kFrameLengthBytes = 4;

/// The wire-object form of [record] — a JSON-encodable map of its four fields.
///
/// Exposed for the boundary guard and tests; [encodeRecordFrames] uses it to
/// build the payload bytes.
Map<String, Object?> recordToWire(MixAccuracyRecord record) {
  final ColorCoordinates lab = record.measuredColour.lab;
  final CielchCoordinates lch = record.measuredColour.lch;
  return <String, Object?>{
    _kPaints: List<String>.of(record.paintCombination.paintIds),
    _kPalette: <String, Object?>{
      'brand': record.declaredPalette.brand,
      'line': record.declaredPalette.line,
      'medium': record.declaredPalette.medium,
    },
    _kLab: <String, Object?>{
      'l': lab.lightness,
      'a': lab.a,
      'b': lab.b,
    },
    _kLch: <String, Object?>{
      'l': lch.lightness,
      'c': lch.chroma,
      'h': lch.hue,
    },
    _kTier: record.tier.name,
  };
}

/// Reconstructs a [MixAccuracyRecord] from its wire-object [json], or throws a
/// [FormatException] when [json] is not a well-formed record object.
///
/// Every field is validated (present, right shape, right type); anything that is
/// not a record object this rejects, so a peer cannot push some other type over
/// the one sanctioned boundary — the structural guarantee the bs-14 boundary
/// guard rests on.
MixAccuracyRecord recordFromWire(Object? json) {
  if (json is! Map) {
    throw const FormatException('wire record is not a JSON object');
  }
  final paints = _requireList(json, _kPaints);
  final palette = _requireMap(json, _kPalette);
  final lab = _requireMap(json, _kLab);
  final lch = _requireMap(json, _kLch);
  final tierName = _requireString(json, _kTier);
  final tier = MeasurementTier.values
      .where((MeasurementTier t) => t.name == tierName)
      .toList();
  if (tier.isEmpty) {
    throw FormatException('unknown measurement tier "$tierName"');
  }
  return MixAccuracyRecord(
    paintCombination: PaintCombination(
      List<String>.unmodifiable(<String>[
        for (final Object? id in paints) _asString(id, _kPaints),
      ]),
    ),
    declaredPalette: DeclaredPalette(
      brand: _requireString(palette, 'brand'),
      line: _requireString(palette, 'line'),
      medium: _requireString(palette, 'medium'),
    ),
    measuredColour: MeasuredColour(
      lab: ColorCoordinates(
        lightness: _requireNum(lab, 'l'),
        a: _requireNum(lab, 'a'),
        b: _requireNum(lab, 'b'),
      ),
      lch: CielchCoordinates(
        lightness: _requireNum(lch, 'l'),
        chroma: _requireNum(lch, 'c'),
        hue: _requireNum(lch, 'h'),
      ),
    ),
    tier: tier.single,
  );
}

/// Encodes [records] into a single frame stream: each record's UTF-8 JSON
/// prefixed with its 4-byte big-endian byte length. Returns an empty buffer for
/// an empty [records].
Uint8List encodeRecordFrames(Iterable<MixAccuracyRecord> records) {
  final BytesBuilder out = BytesBuilder(copy: false);
  for (final MixAccuracyRecord record in records) {
    final List<int> payload = utf8.encode(jsonEncode(recordToWire(record)));
    final ByteData header = ByteData(kFrameLengthBytes)
      ..setUint32(0, payload.length, Endian.big);
    out.add(header.buffer.asUint8List());
    out.add(payload);
  }
  return out.toBytes();
}

/// Decodes every complete record frame in [bytes] at once (the whole buffer must
/// hold only complete frames). Convenience over [RecordFrameReader] for callers
/// that already have the full byte buffer.
List<MixAccuracyRecord> decodeRecordFrames(List<int> bytes) {
  final RecordFrameReader reader = RecordFrameReader()..addBytes(bytes);
  final List<MixAccuracyRecord> records = reader.drain();
  if (reader.pendingByteCount != 0) {
    throw const FormatException('trailing bytes are not a complete frame');
  }
  return records;
}

/// Reassembles length-prefixed record frames from an arbitrarily chunked byte
/// stream (a socket delivers bytes in pieces that do not line up with frames).
///
/// Feed each chunk through [addBytes]; [drain] returns every record whose frame
/// has fully arrived and leaves any partial trailing frame buffered for the next
/// chunk. [pendingByteCount] is how many buffered bytes have not yet formed a
/// complete frame.
class RecordFrameReader {
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  /// Bytes received but not yet consumed into a complete frame.
  int get pendingByteCount => _buffer.length;

  /// Appends [chunk] to the internal buffer.
  void addBytes(List<int> chunk) => _buffer.add(chunk);

  /// Returns every record whose complete frame is now buffered, consuming those
  /// frames; partial trailing bytes stay buffered.
  List<MixAccuracyRecord> drain() {
    Uint8List bytes = _buffer.toBytes();
    final List<MixAccuracyRecord> records = <MixAccuracyRecord>[];
    var offset = 0;
    while (bytes.length - offset >= kFrameLengthBytes) {
      final int length = ByteData.sublistView(bytes, offset, offset + kFrameLengthBytes)
          .getUint32(0, Endian.big);
      final int payloadStart = offset + kFrameLengthBytes;
      if (bytes.length - payloadStart < length) {
        break; // the payload has not fully arrived yet
      }
      final Uint8List payload =
          Uint8List.sublistView(bytes, payloadStart, payloadStart + length);
      records.add(recordFromWire(jsonDecode(utf8.decode(payload))));
      offset = payloadStart + length;
    }
    // Keep only the unconsumed tail.
    _buffer.clear();
    if (offset < bytes.length) {
      _buffer.add(Uint8List.sublistView(bytes, offset));
    }
    return records;
  }
}

// ---------------------------------------------------------------------------
// Field validators — each rejects a malformed wire object with a FormatException
// so nothing but a well-formed record can be reconstructed.
// ---------------------------------------------------------------------------

List<Object?> _requireList(Map<Object?, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! List) {
    throw FormatException('field "$key" is not a list');
  }
  return value;
}

Map<Object?, Object?> _requireMap(Map<Object?, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! Map) {
    throw FormatException('field "$key" is not an object');
  }
  return value;
}

String _requireString(Map<Object?, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! String) {
    throw FormatException('field "$key" is not a string');
  }
  return value;
}

double _requireNum(Map<Object?, Object?> json, String key) {
  final Object? value = json[key];
  if (value is! num) {
    throw FormatException('field "$key" is not a number');
  }
  return value.toDouble();
}

String _asString(Object? value, String key) {
  if (value is! String) {
    throw FormatException('element of "$key" is not a string');
  }
  return value;
}
