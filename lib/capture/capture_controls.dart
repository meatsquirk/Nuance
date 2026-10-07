import 'package:flutter/material.dart';

import 'capture_controller.dart';

/// The Capture screen's control surface: the wireframe buttons E15–E21.
///
/// SCREEN-1 shell — it lays out every control as a findable, labelled button so
/// the acceptance harness and the behaviour phases have stable anchors. The
/// controls whose behaviour is a [CaptureController] action already on the
/// shell surface are wired to it now (E15 dismiss, E16 lock, E17 calibrate,
/// E20 capture, E21 value-only): each action still throws until its behaviour
/// phase un-defers it, exactly as the controller shell declares, so the button
/// is present and wired before the behaviour lands and no behaviour phase has to
/// re-touch this file to reach the controller.
///
/// The two controls with no single-call action yet are rendered as disabled
/// placeholders: E18 (the sampling-radius selector) is built out with its 1 / 5
/// / 21 px options in SCREEN-2, and E19 (import a gallery photo) is wired to its
/// import flow in SOURCE-3.
class CaptureControls extends StatelessWidget {
  const CaptureControls({required this.controller, super.key});

  /// Stable anchor for E15 — dismiss the low-light warning.
  static const Key dismissWarningKey = ValueKey('capture-e15-dismiss-warning');

  /// Stable anchor for E16 — lock exposure / white balance / focus.
  static const Key lockKey = ValueKey('capture-e16-lock');

  /// Stable anchor for E17 — calibrate against a reference card.
  static const Key calibrateKey = ValueKey('capture-e17-calibrate');

  /// Stable anchor for E18 — the sampling-radius selector (built in SCREEN-2).
  static const Key radiusKey = ValueKey('capture-e18-radius');

  /// Stable anchor for E19 — import a gallery photo (wired in SOURCE-3).
  static const Key importKey = ValueKey('capture-e19-import');

  /// Stable anchor for E20 — capture (commit) the sample.
  static const Key captureKey = ValueKey('capture-e20-capture');

  /// Stable anchor for E21 — the value-only grayscale preview toggle.
  static const Key valueOnlyKey = ValueKey('capture-e21-value-only');

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
          child: const Text('Value'),
        ),
        // E18, E19: placeholders enabled by their behaviour phase (SCREEN-2 /
        // SOURCE-3).
        const TextButton(
          key: radiusKey,
          onPressed: null,
          child: Text('Radius'),
        ),
        const TextButton(
          key: importKey,
          onPressed: null,
          child: Text('Import photo'),
        ),
      ],
    );
  }
}
