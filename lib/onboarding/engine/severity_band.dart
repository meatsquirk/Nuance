/// The plain-language severity band shown on the result step (bs-07, AC-11).
///
/// A 0..1 severity maps to one of three bands via `AssessmentEngine.band`
/// (`assessment_engine.dart`), which delegates to [SeverityBand.forSeverity].
/// The band boundaries around the 30/60/90 slider anchors are pinned at ENGINE-7
/// (**G-4**): the cut-offs sit at the anchor midpoints.
library;

/// The severity (0..1) at or above which the band is no longer [SeverityBand.mild]
/// — the midpoint between the 30 (mild) and 60 (moderate) slider anchors (**G-4**,
/// D-5: `severity = slider/100`, so 0.45 = the 45 midpoint).
const double _moderateFloor = 0.45;

/// The severity (0..1) at or above which the band is [SeverityBand.strong] — the
/// midpoint between the 60 (moderate) and 90 (strong) slider anchors (**G-4**:
/// 0.75).
const double _strongFloor = 0.75;

/// A plain-language severity band.
///
/// Ordered least to most affected; the result step reads the band name back to
/// the painter (AC-11: "mild" / "moderate" / "strong").
enum SeverityBand {
  /// Low severity.
  mild,

  /// Mid severity.
  moderate,

  /// High severity.
  strong;

  /// Maps a 0..1 [severity] to its plain-language band under the **G-4**
  /// cut-offs (ENGINE-7): [mild] on `[0, 0.45)`, [moderate] on `[0.45, 0.75)`,
  /// [strong] on `[0.75, 1.0]`. The boundaries are half-open going up, so each
  /// anchor midpoint (0.45, 0.75) reads as the *higher* band and the mapping is
  /// monotone. Values outside 0..1 extend the end bands (negatives read [mild],
  /// above 1 reads [strong]); the pipeline clamps severity to 0..1 upstream, so
  /// this only keeps the function total.
  ///
  /// `AssessmentEngine.band` (the production engine) scores through this; the
  /// acceptance suite grades the product against its own independent
  /// `referenceBand`, never against this function.
  static SeverityBand forSeverity(double severity) {
    if (severity < _moderateFloor) return SeverityBand.mild;
    if (severity < _strongFloor) return SeverityBand.moderate;
    return SeverityBand.strong;
  }

  /// The plain-language label read back on the result step (AC-11), shown as
  /// text (never colour alone). Which severity *maps* to which band is pinned by
  /// [forSeverity] (`AssessmentEngine.band`, G-4); this is only the band's name.
  String get label {
    switch (this) {
      case SeverityBand.mild:
        return 'mild';
      case SeverityBand.moderate:
        return 'moderate';
      case SeverityBand.strong:
        return 'strong';
    }
  }
}
