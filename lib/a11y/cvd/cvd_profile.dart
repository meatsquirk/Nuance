/// The painter's colour-vision profile — which confusion class, and how strong.
///
/// Introduced **here** (bs-03, D-4) as the minimal shape the comparison needs:
/// a [type] (the dichromacy class) and a [severity] (0 none … 1 full
/// dichromat). It is injected app-wide via `AppDependencies.cvdProfile` and read
/// by the [ConfusionCheck] detector (`confusion_check.dart`) when deciding
/// whether a pair is confusable (AC-7, AC-8).
///
/// bs-03 does not *populate* the profile from the painter — **bs-07** (CVD
/// self-assessment) later writes the measured type/severity into this same
/// value type, and **bs-08/bs-10** (display simulation, daltonization) reuse the
/// same profile and the projection behind [ConfusionCheck] (SI D10: the CVD
/// model stays behind an interface). Keeping it minimal now makes bs-07 a
/// *populate-the-profile* change rather than a schema rebuild.
library;

/// The dichromacy class a [CvdProfile] describes.
///
/// The three classic confusion axes; severity is carried separately on
/// [CvdProfile.severity]. bs-07 chooses the value; bs-08/bs-10 reuse it.
enum CvdType {
  /// Red-weak/blind (L-cone) confusion.
  protan,

  /// Green-weak/blind (M-cone) confusion — the default profile for bs-03's
  /// scenarios (D-4).
  deutan,

  /// Blue-weak/blind (S-cone) confusion.
  tritan,
}

/// A colour-vision profile: a [type] and a [severity].
///
/// A value type with value equality (so injected profiles compare by content,
/// not identity). The default [severity] is full dichromacy (1), the clearest
/// case for the dichromat projection in [ConfusionCheck]; bs-07 replaces it with
/// the painter's assessed value.
class CvdProfile {
  const CvdProfile({required this.type, this.severity = 1.0});

  /// The dichromacy class (D-4).
  final CvdType type;

  /// How strongly the painter is affected: 0 (unaffected) to 1 (full
  /// dichromat). bs-07 populates the measured value; defaults to 1.
  final double severity;

  @override
  bool operator ==(Object other) =>
      other is CvdProfile && other.type == type && other.severity == severity;

  @override
  int get hashCode => Object.hash(type, severity);

  @override
  String toString() => 'CvdProfile(${type.name}, severity $severity)';
}
