/// How much to trust a committed capture, as a first-class label distinct from
/// bs-01 [Provenance] (D-3).
///
/// Provenance (SI D9) records *where* a reading came from; accuracy records *how
/// confident* the capture itself is. The two are separate honesty signals and a
/// committed `Sample` carries both. Poor light or a card-less capture
/// **downgrades** the accuracy label — it never fails the capture (SI
/// Reliability + the NFR accuracy table). Each tier names the ΔE00 it promises
/// the reading stays within of ground truth, so "within ΔE N" is a numeric
/// check the acceptance tests make, not just label text (D-4).
enum CaptureAccuracy {
  /// A card-less reading: within ΔE00 [maxDeltaE] (8) of ground truth. The
  /// default tier, and the floor a low-light capture is downgraded to (AC-6).
  approximate,

  /// A reference-card-calibrated reading: within ΔE00 [maxDeltaE] (3) of ground
  /// truth. The upgraded tier a calibration earns (AC-8).
  calibrated;

  /// The user-facing label for this tier (shown as text, never colour alone).
  String get label {
    switch (this) {
      case CaptureAccuracy.approximate:
        return 'Approximate';
      case CaptureAccuracy.calibrated:
        return 'Calibrated';
    }
  }

  /// The ΔE00 the reading is promised to stay within of ground truth at this
  /// tier — the numeric bound the accuracy acceptance tests assert against.
  double get maxDeltaE {
    switch (this) {
      case CaptureAccuracy.approximate:
        return 8;
      case CaptureAccuracy.calibrated:
        return 3;
    }
  }
}
