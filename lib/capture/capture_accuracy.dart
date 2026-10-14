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

/// A poor-capture condition that AC-9 requires be surfaced honestly: a reading
/// taken under it carries a **downgraded** stated accuracy (never returned as
/// trustworthy), with this reason named in words so the painter knows *why*
/// (spec AC-9 Reliability; plan bs-12 D-5).
///
/// The spec names three conditions — poor lighting **or** unlocked exposure
/// **or** a missing reference card. Today only [lowLight] drives a downgrade
/// (via [CaptureState.lowLightWarning]); [exposureUnlocked] and
/// [missingReferenceCard] went unenforced (a card-less `calibrate()` was a
/// silent no-op). This enum is the first-class representation of all three —
/// the *label inputs* the reliability fix acts on.
///
/// **QUALITY-1 (shell) only makes the conditions representable.** The controller
/// reports which hold through [CaptureController.activeDowngradeReasons]; it does
/// **not yet** let them change a committed reading — wiring the downgrade /
/// approximate label at commit is QUALITY-2's trigger. Each reason carries the
/// user-facing [label] that surface shows (never colour alone — the bs-01 label
/// contract).
enum AccuracyDowngradeReason {
  /// The scene is too dimly lit for the normal tier (spec AC-6) — already a
  /// trigger today, listed here so all three poor conditions share one shape.
  lowLight('Low light — reading may be approximate'),

  /// Auto-exposure / white-balance / focus were **not** locked together when the
  /// reading committed, so it had not settled (the AC-9 gap: unlocked exposure
  /// was never downgraded).
  exposureUnlocked('Exposure not locked — reading may be approximate'),

  /// No reference card was in view to normalise against, so the reading could
  /// not be calibrated (the AC-9 gap: a missing card was a silent no-op).
  missingReferenceCard('No reference card — reading may be approximate');

  const AccuracyDowngradeReason(this.label);

  /// The user-facing reason text, shown as words alongside the downgraded
  /// [CaptureAccuracy.approximate] tier (never colour alone).
  final String label;
}
