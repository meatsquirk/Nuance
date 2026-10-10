import 'color_coordinates.dart';

/// The binder a [Paint] is ground in (bs-04 D-3).
///
/// A recipe never spans media (engine-design cross-medium rule), and the
/// wet→dry transform (AC-10) differs per medium — oil shifts less than acrylic
/// (D-11) — so each paint and each [recipe]'s medium is carried explicitly.
enum PaintMedium {
  /// Acrylic — a larger wet→dry shift (D-11).
  acrylic,

  /// Oil — a smaller wet→dry shift (D-11).
  oil,
}

/// A single paint the painter owns, the atom the mixing engine solves over.
///
/// Carries a masstone CIELAB (the colour of the paint at full strength) and its
/// [medium] (bs-04 D-3). Measured Kubelka–Munk K/S data is deferred to the
/// measured-pigment engine (`docs/custom-mixing-engine-design.md`); the v1
/// subtractive engine (D-2) needs only the masstone and the medium. The optional
/// [pigmentIndex] (e.g. "PW6") and [opacity] are carried for that later engine
/// and for presentation; they do not affect the v1 solve.
///
/// Value-equal and `const`-constructible so palettes and recipes compare by
/// content, not identity.
class Paint {
  /// Creates a paint. [id], [name], [medium] and [masstone] are required; the
  /// pigment index and opacity are optional (deferred-engine metadata).
  const Paint({
    required this.id,
    required this.name,
    required this.medium,
    required this.masstone,
    this.pigmentIndex,
    this.opacity,
  });

  /// Stable identity of the paint within a palette (keys the solver's maps).
  final String id;

  /// The painter-facing name (e.g. "Titanium White"), spoken by AC-12.
  final String name;

  /// The binder the paint is ground in (D-3); recipes never mix media.
  final PaintMedium medium;

  /// The paint's masstone — its CIELAB colour at full strength (D-3).
  final ColorCoordinates masstone;

  /// The Colour Index pigment code (e.g. "PW6"), or null when unknown.
  ///
  /// Carried for the deferred measured-pigment engine and for presentation; the
  /// v1 subtractive solve ignores it.
  final String? pigmentIndex;

  /// Hiding power on 0 (transparent) … 1 (fully opaque), or null when unknown.
  ///
  /// Carried for the deferred measured-pigment engine; the v1 solve ignores it.
  final double? opacity;

  @override
  bool operator ==(Object other) =>
      other is Paint &&
      other.id == id &&
      other.name == name &&
      other.medium == medium &&
      other.masstone == masstone &&
      other.pigmentIndex == pigmentIndex &&
      other.opacity == opacity;

  @override
  int get hashCode =>
      Object.hash(id, name, medium, masstone, pigmentIndex, opacity);

  @override
  String toString() => 'Paint($id "$name", ${medium.name}, $masstone)';
}
