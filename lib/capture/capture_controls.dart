import 'package:flutter/material.dart';

import 'capture_controller.dart';

/// The Capture screen's control surface: the wireframe buttons E15–E21.
///
/// It lays out every control as a findable, labelled button so the acceptance
/// harness and the behaviour phases have stable anchors. The controls whose
/// behaviour is a [CaptureController] action are wired to it (E15 dismiss, E16
/// lock, E17 calibrate, E20 capture, E21 value-only). E21 drives
/// [CaptureController.toggleValueOnly] and reads "✓ Value" while value-only is
/// on, "Value" while off (AC-10).
///
/// E18 (the sampling-radius selector) offers the 1 / 5 / 21 px options, each
/// driving [CaptureController.setRadius] and marking the selected radius (AC-3);
/// E19 (import a gallery photo) is wired to [CaptureController.importPhoto] in
/// SOURCE-3.
///
/// bs-09 adds three more controls as findable placeholders bound to the
/// controller's deferred stubs: a torch toggle (AC-1/AC-2), a "sample points"
/// action (AC-3) and a "send to comparison" action (AC-5). Each throws
/// [UnimplementedError] until its behaviour phase (CAPTURE-3/4/5) un-defers it;
/// SCREEN-1 only fixes the keys and the wiring.
class CaptureControls extends StatelessWidget {
  const CaptureControls({required this.controller, super.key});

  /// Stable anchor for E15 — dismiss the low-light warning.
  static const Key dismissWarningKey = ValueKey('capture-e15-dismiss-warning');

  /// Stable anchor for E16 — lock exposure / white balance / focus.
  static const Key lockKey = ValueKey('capture-e16-lock');

  /// Stable anchor for E17 — calibrate against a reference card.
  static const Key calibrateKey = ValueKey('capture-e17-calibrate');

  /// Stable anchor for E18 — the sampling-radius selector (wraps the 1 / 5 /
  /// 21 px options).
  static const Key radiusKey = ValueKey('capture-e18-radius');

  /// The sampling radii the E18 selector offers, in px (AC-3; 5 px is D-7's
  /// default).
  static const List<int> radiusOptionsPx = [1, 5, 21];

  /// Stable anchor for the [radiusPx] option within E18, so the harness and the
  /// painter can select a specific radius.
  static Key radiusOptionKey(int radiusPx) =>
      ValueKey('capture-e18-radius-$radiusPx');

  /// Stable anchor for E19 — import a gallery photo (wired in SOURCE-3).
  static const Key importKey = ValueKey('capture-e19-import');

  /// Stable anchor for E20 — capture (commit) the sample.
  static const Key captureKey = ValueKey('capture-e20-capture');

  /// Stable anchor for E21 — the value-only grayscale preview toggle.
  static const Key valueOnlyKey = ValueKey('capture-e21-value-only');

  /// Stable anchor for the torch toggle (bs-09 AC-1, AC-2). Wired to
  /// [CaptureController.turnTorchOn] / [CaptureController.turnTorchOff]
  /// (behaviour deferred to CAPTURE-3).
  static const Key torchKey = ValueKey('capture-torch');

  /// Stable anchor for the "sample marked points" action (bs-09 AC-3). Wired to
  /// [CaptureController.sampleMarkedPoints] (behaviour deferred to CAPTURE-4).
  static const Key samplePointsKey = ValueKey('capture-sample-points');

  /// Stable anchor for the "send to comparison" action (bs-09 AC-5). Wired to
  /// [CaptureController.sendPairToComparison] (behaviour deferred to CAPTURE-5).
  static const Key sendToComparisonKey = ValueKey('capture-send-to-comparison');

  /// The controller whose actions the wired controls drive.
  final CaptureController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // E15–E17, E20, E21: wired to the controller action (deferred until
        // each action's behaviour phase un-defers it).
        TextButton(
          key: dismissWarningKey,
          onPressed: controller.dismissWarning,
          child: const Text('Dismiss warning'),
        ),
        TextButton(
          key: lockKey,
          onPressed: controller.lock,
          child: const Text('Lock AE · AWB · AF'),
        ),
        TextButton(
          key: calibrateKey,
          onPressed: controller.calibrate,
          child: const Text('Calibrate'),
        ),
        TextButton(
          key: captureKey,
          onPressed: controller.commit,
          child: const Text('Capture'),
        ),
        TextButton(
          key: valueOnlyKey,
          onPressed: controller.toggleValueOnly,
          // E21 reads "✓ Value" while the value-only grayscale preview is on,
          // "Value" while off (AC-10).
          child: Text(controller.state.valueOnly ? '✓ Value' : 'Value'),
        ),
        // E18: the sampling-radius selector — one option per radius, the
        // selected one marked (AC-3).
        Row(
          key: radiusKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Radius'),
            for (final radiusPx in radiusOptionsPx)
              TextButton(
                key: radiusOptionKey(radiusPx),
                onPressed: () => controller.setRadius(radiusPx),
                child: Text(
                  controller.state.radiusPx == radiusPx
                      ? '✓ $radiusPx px'
                      : '$radiusPx px',
                ),
              ),
          ],
        ),
        // E19: imports a gallery photo and samples its point P (SOURCE-3).
        TextButton(
          key: importKey,
          onPressed: controller.importPhoto,
          child: const Text('Import photo'),
        ),
        // bs-09 torch toggle (AC-1, AC-2): reflects state.torchOn and drives the
        // torch on / off. The mechanism and the colour-temperature warning land
        // in CAPTURE-3 — the stub throws until then.
        TextButton(
          key: torchKey,
          onPressed: controller.state.torchOn
              ? controller.turnTorchOff
              : controller.turnTorchOn,
          child: Text(controller.state.torchOn ? '✓ Torch' : 'Torch'),
        ),
        // bs-09 multi-point sampling (AC-3): samples the current frame at every
        // marked point. Behaviour lands in CAPTURE-4; the stub throws until then.
        TextButton(
          key: samplePointsKey,
          onPressed: controller.sampleMarkedPoints,
          child: const Text('Sample points'),
        ),
        // bs-09 send-to-comparison (AC-5): hands a pair of readings to the
        // comparison. Reading selection and the behaviour land in CAPTURE-5; the
        // index pair here is a shell placeholder and the stub throws until then.
        TextButton(
          key: sendToComparisonKey,
          onPressed: () => controller.sendPairToComparison(0, 1),
          child: const Text('Send to comparison'),
        ),
      ],
    );
  }
}
