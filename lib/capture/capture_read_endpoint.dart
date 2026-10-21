import 'package:flutter/widgets.dart';

import 'camera_permission.dart';
import 'capture_controller.dart';
import 'source/capture_source.dart';

/// Exposes the live [CaptureController] to the acceptance tests.
///
/// The Capture screen wraps its subtree in one of these so a test can read the
/// observable [CaptureState] — and, through [CaptureController.source], the
/// fake's known ground-truth scene — for the Thens the rendered UI does not
/// surface directly (the sampled / committed colour value, `framesAveraged`,
/// the accuracy tier). It is a test observation seam, not a UI control: production
/// screens read the controller they own, not this endpoint.
///
/// Find it in a pumped tree with `find.byType(CaptureReadEndpoint)` (or reach
/// the nearest one from a descendant via [of]); its [endpointKey] marks it for a
/// direct `find.byKey` lookup.
class CaptureReadEndpoint extends InheritedWidget {
  const CaptureReadEndpoint({
    required this.controller,
    required super.child,
    super.key,
  });

  /// A stable key the acceptance suite can find the endpoint by.
  static const Key endpointKey = Key('capture-read-endpoint');

  /// The controller whose [CaptureController.state] and
  /// [CaptureController.source] the tests observe.
  final CaptureController controller;

  /// Which source is driving the capture now — the live
  /// [CaptureSourceKind.camera] or the [CaptureSourceKind.software] fallback
  /// (bs-19 AC-1 / AC-7 / AC-8).
  ///
  /// The production source selection (PERM-2/PERM-3) is hidden behind the
  /// `AppDependencies.captureSource` seam; this surfaces the active source's
  /// own [CaptureSource.kind] so a test can assert the selection without
  /// reaching into the assembly.
  CaptureSourceKind get activeSourceKind => controller.source.kind;

  /// The resolved camera-permission state (bs-19 AC-7), read from the live
  /// [CaptureState.cameraPermission]. Inert ([CameraPermissionState.undetermined])
  /// until PERM-2 requests permission.
  CameraPermissionState get permissionState => controller.state.cameraPermission;

  /// The [CaptureController] exposed by the nearest enclosing endpoint above
  /// [context]. Throws if there is none (every Capture screen provides one).
  static CaptureController of(BuildContext context) {
    final endpoint =
        context.dependOnInheritedWidgetOfExactType<CaptureReadEndpoint>();
    assert(endpoint != null, 'No CaptureReadEndpoint found above this widget.');
    return endpoint!.controller;
  }

  @override
  bool updateShouldNotify(CaptureReadEndpoint oldWidget) =>
      controller != oldWidget.controller;
}
