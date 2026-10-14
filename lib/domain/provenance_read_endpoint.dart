import 'provenance.dart';
import 'provenance_derivation.dart';
import 'sample.dart';

/// A read-only observation seam over one value's provenance, for the bs-13
/// acceptance suite.
///
/// The ACs for runtime provenance (AC-7 tier-by-origin, AC-8 append-only
/// evidence, AC-9 promotion on a measured swatch, AC-10 opinions never promote)
/// are pure-domain facts about a [Sample]'s evidence, so this seam is plain
/// Dart — not a widget — and simply exposes what the rendered UI does not
/// surface as text: the [evidence] behind the value and the [derivedTier] the
/// [ProvenanceDerivation] reports for it. It is a test observation seam, not a
/// UI control, and performs no mutation.
class ProvenanceReadEndpoint {
  /// Observes [sample], deriving its tier through [derivation] (the shared
  /// const instance by default).
  const ProvenanceReadEndpoint(
    this.sample, {
    this.derivation = const ProvenanceDerivation(),
  });

  /// The value being observed.
  final Sample sample;

  /// The derivation rule used to read [derivedTier].
  final ProvenanceDerivation derivation;

  /// The append-only evidence list behind the value (order preserved).
  List<EvidencePoint> get evidence => sample.evidence;

  /// The tier derived from the value's [evidence], falling back to the stored
  /// [Provenance.tier] when no evidence contributes (shell: always the stored
  /// tier — see [ProvenanceDerivation]).
  ProvenanceTier get derivedTier =>
      derivation.tierFor(sample.evidence, fallback: sample.provenance.tier);
}
