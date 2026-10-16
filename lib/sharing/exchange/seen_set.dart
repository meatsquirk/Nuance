import '../record/mix_accuracy_record.dart';

/// Remembers which records this device has already seen, keyed by
/// [MixAccuracyRecord.contentHash] (bs-14 EXCHANGE-1).
///
/// The gossip layer uses it to dedup: a record whose content hash has been seen
/// before — whether the device built it, offered it or received it in an earlier
/// round — is dropped rather than re-exchanged (D-7). Keying on the content hash
/// (not object identity) means two byte-identical records from different peers
/// collapse to one, which is exactly the de-duplication the exchange relies on.
class SeenSet {
  final Set<String> _hashes = <String>{};

  /// The number of distinct content hashes remembered.
  int get length => _hashes.length;

  /// Whether [record]'s content hash has already been seen.
  bool contains(MixAccuracyRecord record) =>
      _hashes.contains(record.contentHash);

  /// Records [record] as seen, returning true when its content hash was newly
  /// added and false when it was already present (a dedup drop).
  bool register(MixAccuracyRecord record) => _hashes.add(record.contentHash);
}
