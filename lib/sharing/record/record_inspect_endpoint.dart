import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'mix_accuracy_record.dart';

/// A read-only observation seam over the record builder's output, for the bs-14
/// acceptance suite (RECORD-1).
///
/// Mirrors the sibling read endpoints (`SharingConsentReadEndpoint`,
/// `CvdProfileReadEndpoint`): an [InheritedWidget] the suite finds by its
/// [endpointKey] to read what the UI does not surface — the single [prepared]
/// record built from the painter's current mix (null when nothing shareable was
/// built) and the selected [shareSet] that would actually be exchanged.
///
/// The redaction (AC-4) and no-palette-exclusion (AC-5) assertions read these:
/// AC-4 checks the [prepared] record carries nothing personal even when app
/// state holds projects, samples and a profile; AC-5 checks a record with no
/// declared palette never reaches the [shareSet]. Both are empty/null in the
/// shell — the builder prepares nothing — until the RECORD behaviour phases.
class RecordInspectEndpoint extends InheritedWidget {
  /// Wraps [child], exposing the [prepared] record and the [shareSet].
  const RecordInspectEndpoint({
    this.prepared,
    this.shareSet = const <MixAccuracyRecord>[],
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('record-inspect-endpoint');

  /// The record prepared from the painter's current mix, or null when nothing
  /// shareable was built. Null in the shell.
  final MixAccuracyRecord? prepared;

  /// The records selected for sharing — after the no-palette exclusion (AC-5).
  /// Empty in the shell.
  final List<MixAccuracyRecord> shareSet;

  /// The nearest enclosing endpoint above [context]. Throws if there is none.
  static RecordInspectEndpoint of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<RecordInspectEndpoint>();
    assert(endpoint != null, 'No RecordInspectEndpoint found above this widget.');
    return endpoint!;
  }

  /// The nearest enclosing endpoint above [context], or null when there is none
  /// — for trees that mount no record inspection.
  static RecordInspectEndpoint? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RecordInspectEndpoint>();

  @override
  bool updateShouldNotify(RecordInspectEndpoint oldWidget) =>
      prepared != oldWidget.prepared ||
      !listEquals(shareSet, oldWidget.shareSet);
}
