import 'package:flutter/widgets.dart';

import 'seed_dataset.dart';
import 'validation_manifest.dart';

/// Exposes the loaded shipped [SeedDataset] — and its [ValidationManifest] — to
/// the acceptance tests (bs-13 SEED).
///
/// `buildApp` wraps the app in one (mirroring bs-08's `DisplayReadEndpoint`) so
/// the suite can observe the shipped seed the rendered UI does not surface as
/// text: the optical entries and their provenance origins (AC-1/AC-2), the
/// accepted-vs-rejected ingest result (AC-4), the one-brand/one-medium scope
/// (AC-11) and the ship-gate manifest (AC-5/AC-6). It is a test observation
/// seam, not a UI control.
///
/// Find it with `find.byKey(DatasetReadEndpoint.endpointKey)`, or reach the
/// nearest one from a descendant via [of].
class DatasetReadEndpoint extends InheritedWidget {
  /// Wraps [child], exposing [dataset] to the subtree.
  const DatasetReadEndpoint({
    required this.dataset,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('dataset-read-endpoint');

  /// The shipped seed dataset the tests observe (empty in the SEED-2 shell).
  final SeedDataset dataset;

  /// The dataset's Phase-0.5 validation manifest (convenience).
  ValidationManifest get manifest => dataset.manifest;

  /// The [SeedDataset] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every app assembly provides one).
  static SeedDataset of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<DatasetReadEndpoint>();
    assert(endpoint != null, 'No DatasetReadEndpoint found above this widget.');
    return endpoint!.dataset;
  }

  /// The [SeedDataset] from the nearest enclosing endpoint, or null when there
  /// is none above [context] (a surface rendered outside the app assembly).
  static SeedDataset? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DatasetReadEndpoint>()?.dataset;

  @override
  bool updateShouldNotify(DatasetReadEndpoint oldWidget) =>
      dataset != oldWidget.dataset;
}
