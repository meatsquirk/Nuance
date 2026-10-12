/// The plain-language severity band shown on the result step (bs-07, AC-11).
///
/// A 0..1 severity maps to one of three bands via `AssessmentEngine.band`
/// (`assessment_engine.dart`); the band boundaries around the 30/60/90 anchors
/// are pinned at ENGINE-7 (**pending G-4**). This file holds only the band
/// vocabulary so the shells and the result UI can reference it now.
library;

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

  /// The plain-language label read back on the result step (AC-11), shown as
  /// text (never colour alone). Which severity *maps* to which band is pinned
  /// separately at ENGINE-7 (`AssessmentEngine.band`, pending G-4); this is only
  /// the band's name.
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
