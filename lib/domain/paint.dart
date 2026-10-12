import 'color_coordinates.dart';
import 'provenance.dart';

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
///
/// bs-06 (PALETTE-1, plan D-2) extends it **additively** with the painter-facing
/// identity the Palette screen lists — [brand], [line] and the paint's
/// [provenance] tier — all with safe defaults so bs-04's call sites, value
/// equality, solver maps and the AC-12 "names the paint" speech stay unchanged.
/// The provenance here is the trust tier the paint's colour carries (AC-2's
/// badge, AC-3's legend); the reviewed shipped dataset defaults each entry to
/// [ProvenanceTier.measured] (G-4), preserved on add (AC-4).
class Paint {
  /// Creates a paint. [id], [name], [medium] and [masstone] are required; the
  /// pigment index and opacity are optional (deferred-engine metadata), as are
  /// the [brand] / [line] identity and the [provenance] tier (bs-06 D-2, which
  /// defaults to [ProvenanceTier.measured]).
  const Paint({
    required this.id,
    required this.name,
    required this.medium,
    required this.masstone,
    this.pigmentIndex,
    this.opacity,
    this.brand,
    this.line,
    this.provenance = ProvenanceTier.measured,
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

  /// The manufacturer (e.g. "Winsor & Newton"), or null when unknown (bs-06).
  ///
  /// Shown as paint identity on the Palette screen (AC-2); defaults to null so
  /// bs-04's paints are unaffected.
  final String? brand;

  /// The product line (e.g. "Artists' Oil"), or null when unknown (bs-06).
  ///
  /// Shown as paint identity on the Palette screen (AC-2); defaults to null so
  /// bs-04's paints are unaffected.
  final String? line;

  /// The trust tier of this paint's colour (bs-06 D-2).
  ///
  /// Rendered as the provenance badge the Palette screen shows instead of colour
  /// alone (AC-2) and explained by the legend (AC-3). Defaults to
  /// [ProvenanceTier.measured] — the reviewed dataset's default (G-4) and a safe
  /// value for bs-04's paints, which carry no provenance of their own.
  final ProvenanceTier provenance;

  @override
  bool operator ==(Object other) =>
      other is Paint &&
      other.id == id &&
      other.name == name &&
      other.medium == medium &&
      other.masstone == masstone &&
      other.pigmentIndex == pigmentIndex &&
      other.opacity == opacity &&
      other.brand == brand &&
      other.line == line &&
      other.provenance == provenance;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        medium,
        masstone,
        pigmentIndex,
        opacity,
        brand,
        line,
        provenance,
      );

  @override
  String toString() => 'Paint($id "$name", ${medium.name}, $masstone)';
}
