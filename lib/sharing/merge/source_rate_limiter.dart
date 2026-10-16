/// Bounds how many records any single source may contribute to a mapping's
/// crowd evidence, so no one source can dominate it (bs-14 AC-12; scope §6.6).
///
/// The bound is *per source*: reaching the cap for one source never starves the
/// others, so a flood from a single install cannot crowd out honest records
/// from everyone else. The limiter keys on the source id [EvidenceMerge] stamps
/// onto each [SourcedRecord].
///
/// This is the MERGE-1 shell: it freezes the signature and the default cap but
/// enforces nothing — [admit] accepts every record. MERGE-5 tracks a per-source
/// count and begins rejecting once a source reaches [maxPerSource], leaving
/// every other source unaffected.
class SourceRateLimiter {
  /// Creates a limiter capping each source at [maxPerSource] records.
  SourceRateLimiter({this.maxPerSource = defaultMaxPerSource});

  /// The provisional default per-source cap; MERGE-5 fixes the scope §6.6 value.
  static const int defaultMaxPerSource = 50;

  /// The most records any single source may contribute.
  final int maxPerSource;

  /// Whether one more record from [source] is within that source's cap.
  ///
  /// Shell: always accepts (no cap enforced, no state kept). MERGE-5 counts the
  /// records admitted per source and returns false once a source reaches
  /// [maxPerSource], without affecting any other source.
  bool admit(String source) {
    return true;
  }
}
