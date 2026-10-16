/// Bounds how many records any single source may contribute to a mapping's
/// crowd evidence, so no one source can dominate it (bs-14 AC-12; scope §6.6).
///
/// The bound is *per source*: reaching the cap for one source never starves the
/// others, so a flood from a single install cannot crowd out honest records
/// from everyone else. The limiter keys on the source id [EvidenceMerge] stamps
/// onto each [SourcedRecord].
///
/// A limiter instance is stateful — it counts the records it has admitted per
/// source — so it bounds a whole stream, not a single call. [EvidenceMerge]
/// creates one per ingest (seeded with the peer points already in the log) so
/// the cap holds across the append-only log's growth.
class SourceRateLimiter {
  /// Creates a limiter capping each source at [maxPerSource] records.
  SourceRateLimiter({this.maxPerSource = defaultMaxPerSource});

  /// The per-source cap (scope §6.6 names no number, so this is the fixed bound:
  /// generous enough for honest contributors, tight enough to blunt a flood).
  static const int defaultMaxPerSource = 50;

  /// The most records any single source may contribute.
  final int maxPerSource;

  /// How many records each source has had admitted so far.
  final Map<String, int> _acceptedPerSource = <String, int>{};

  /// Whether one more record from [source] is within that source's cap.
  ///
  /// Returns true and counts the admission while [source] is below
  /// [maxPerSource]; once it has reached the cap, returns false and counts
  /// nothing. Because the count is kept per source, a source reaching its cap
  /// leaves every other source's budget untouched — a flood from one source can
  /// neither be averaged into another's nor starve it (AC-12).
  bool admit(String source) {
    final int accepted = _acceptedPerSource[source] ?? 0;
    if (accepted >= maxPerSource) {
      return false;
    }
    _acceptedPerSource[source] = accepted + 1;
    return true;
  }
}
