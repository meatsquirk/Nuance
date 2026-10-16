import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../domain/color_coordinates.dart';
import '../../domain/provenance.dart';
import '../../domain/sample.dart';

/// A snapshot of one mapping's crowd-refined state, for the bs-14 acceptance
/// suite (MERGE-1).
///
/// Carries the derived [value], its source-tagged [evidence] log (each point's
/// [EvidencePoint.source] and [EvidencePoint.kind] are what the merge/refine
/// assertions read), and the derived [tier] with its user-facing [label]. The
/// merge ACs read this to check records are appended and tagged (AC-10), that
/// the estimate rejects outliers (AC-8/AC-11), and that the tier and label stay
/// "Estimated — not yet verified" however much crowd evidence accrues (AC-9).
@immutable
class MappingEvidenceView {
  /// Creates a view of one mapping's refined [value], [evidence], [tier] and
  /// user-facing [label].
  const MappingEvidenceView({
    required this.value,
    this.evidence = const <EvidencePoint>[],
    this.tier = ProvenanceTier.estimated,
    this.label = 'Estimated — not yet verified',
  });

  /// The mapping's derived value in canonical CIELAB.
  final ColorCoordinates value;

  /// The source-tagged evidence behind the value, newest appended last (AC-10).
  final List<EvidencePoint> evidence;

  /// The derived provenance tier — never above Estimated for crowd evidence.
  final ProvenanceTier tier;

  /// The full user-facing qualifier for [tier].
  final String label;

  @override
  bool operator ==(Object other) =>
      other is MappingEvidenceView &&
      other.value == value &&
      listEquals(other.evidence, evidence) &&
      other.tier == tier &&
      other.label == label;

  @override
  int get hashCode => Object.hash(value, Object.hashAll(evidence), tier, label);

  @override
  String toString() =>
      'MappingEvidenceView($value, ${evidence.length} evidence, $label)';
}

/// A read-only observation seam over one mapping's crowd-refined state, for the
/// bs-14 acceptance suite (MERGE-1).
///
/// Mirrors the sibling read endpoints (`RecordInspectEndpoint`,
/// `ExchangeOutcomeEndpoint`): an [InheritedWidget] the suite finds by its
/// [endpointKey] to read what the UI never surfaces — the mapping's derived
/// value, its source-tagged evidence log and its derived tier/label. [view] is
/// null in the shell — no mapping is refined — until the MERGE behaviour phases
/// populate it.
class MappingEvidenceEndpoint extends InheritedWidget {
  /// Wraps [child], exposing the observed mapping [view].
  const MappingEvidenceEndpoint({
    this.view,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('mapping-evidence-endpoint');

  /// The observed mapping's refined state, or null when none is observed.
  final MappingEvidenceView? view;

  /// The nearest enclosing endpoint above [context]. Throws if there is none.
  static MappingEvidenceEndpoint of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<MappingEvidenceEndpoint>();
    assert(
      endpoint != null,
      'No MappingEvidenceEndpoint found above this widget.',
    );
    return endpoint!;
  }

  /// The nearest enclosing endpoint above [context], or null when there is none
  /// — for trees that mount no mapping observation.
  static MappingEvidenceEndpoint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MappingEvidenceEndpoint>();

  @override
  bool updateShouldNotify(MappingEvidenceEndpoint oldWidget) =>
      view != oldWidget.view;
}
