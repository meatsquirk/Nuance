/// Where a colour reading came from, and how much to trust it.
///
/// Every [Provenance] is carried, non-null, by a `Sample` (SI D9): the tier is
/// enforced in the domain model, not as a UI policy. Later features (bs-14
/// peer-to-peer) append evidence without changing this shape.
enum ProvenanceTier {
  /// Read from an instrument (e.g. a spectrophotometer).
  measured,

  /// Derived by calculation from other measured values.
  calculated,

  /// Seeded by a model and not yet verified.
  estimated,

  /// Confirmed by the painter.
  confirmed,
}

/// The provenance of a colour reading: a [tier] and an optional human-facing
/// [note] (e.g. the "seeded by a model" caveat shown with an estimate).
class Provenance {
  const Provenance(this.tier, {this.note});

  /// The trust tier of the reading.
  final ProvenanceTier tier;

  /// Optional note shown alongside the badge.
  final String? note;

  /// The user-facing label for [tier].
  String get label {
    switch (tier) {
      case ProvenanceTier.measured:
        return 'Measured';
      case ProvenanceTier.calculated:
        return 'Calculated';
      case ProvenanceTier.estimated:
        return 'Estimated';
      case ProvenanceTier.confirmed:
        return 'Confirmed';
    }
  }

  @override
  bool operator ==(Object other) =>
      other is Provenance && other.tier == tier && other.note == note;

  @override
  int get hashCode => Object.hash(tier, note);

  @override
  String toString() =>
      'Provenance($label${note == null ? '' : ', $note'})';
}
