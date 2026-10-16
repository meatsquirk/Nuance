import 'dart:convert';

/// A deterministic content hash over a record's canonical serialized form.
///
/// bs-14 collapses byte-identical mix-accuracy records at exchange (D-7): two
/// painters who measure the same mix of the same paints to the same rounded
/// colour produce the *same* [contentHashOf] value, so the gossip layer can
/// dedup them with a seen-set keyed by this hash. Distinct measurements — a
/// different paint set, palette or rounded colour — differ, so the hash never
/// collapses genuinely different evidence.
///
/// The repo has no `crypto` dependency and the record never leaves the device
/// as a security token, so a dependency-free FNV-1a over the canonical bytes is
/// enough: it is stable across runs and isolates (unlike [Object.hashCode],
/// which Dart does not promise to keep stable), and that stability is what the
/// seen-set relies on.
String contentHashOf(String canonical) {
  // FNV-1a, 64-bit. The VM wraps integer arithmetic mod 2^64, which is exactly
  // the modular behaviour FNV-1a is defined over.
  const int fnvOffsetBasis = 0xcbf29ce484222325;
  const int fnvPrime = 0x100000001b3;

  var hash = fnvOffsetBasis;
  for (final byte in utf8.encode(canonical)) {
    hash ^= byte;
    hash = hash * fnvPrime;
  }
  // Format as unsigned 64-bit hex. `hash` is a signed 64-bit int, so its top
  // bit being set would make `toRadixString(16)` emit a leading '-'; splitting
  // into two 32-bit halves renders both unsigned and fixes the width at 16.
  final hi = (hash >> 32) & 0xFFFFFFFF;
  final lo = hash & 0xFFFFFFFF;
  return hi.toRadixString(16).padLeft(8, '0') +
      lo.toRadixString(16).padLeft(8, '0');
}
