import 'package:flutter/material.dart';

import '../onboarding_controller.dart';

/// The result step (wireframe S1.R1.E40 adjust CVD type [button], E41 severity
/// slider [input], E43 save profile [button]; AC-1, AC-10, AC-11, AC-12, AC-13).
///
/// Shows the estimated type and severity, the by-hand type control, the severity
/// slider (which doubles as the subjective self-calibration), the save control
/// and the approximate-estimate caveat. The FLOW-1 shell renders every control
/// **inert** (`onPressed`/`onChanged: null`) and a static caveat placeholder:
/// FLOW-5 assembles the estimate onto this step, FLOW-6 wires `setType`, FLOW-7
/// wires the slider (`setSeverity`/`confirmCalibration`) and the band readout
/// (ENGINE-7), FLOW-8 fills the caveat, and PROFILE-2 wires save.
class ResultStep extends StatelessWidget {
  /// Creates the result step over [controller].
  const ResultStep({required this.controller, super.key});

  /// Stable anchor for the result step.
  static const Key regionKey = ValueKey('onboarding-result-step');

  /// Stable anchor for the by-hand type control (E40).
  static const Key typeKey = ValueKey('onboarding-result-type');

  /// Stable anchor for the severity slider (E41).
  static const Key severityKey = ValueKey('onboarding-result-severity');

  /// Stable anchor for the save control (E43).
  static const Key saveKey = ValueKey('onboarding-result-save');

  /// Stable anchor for the approximate-estimate caveat area (AC-1, FLOW-8).
  static const Key caveatKey = ValueKey('onboarding-result-caveat');

  /// The controller the type / severity / save actions act on (FLOW-5..8,
  /// PROFILE-2).
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    // FLOW-5 assembles the estimate onto the controller and advances here; until
    // then (e.g. the shell / before "See my result") there is no estimate and the
    // step shows its placeholder. The severity slider reflects the estimated
    // severity on its 0..100 scale; it stays inert until FLOW-7 wires it.
    final estimate = controller.state.estimate;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (estimate == null)
          const Text('Result')
        else ...[
          Text('Estimated type: ${estimate.type.name}'),
          Text('Estimated severity: ${(estimate.severity * 100).round()}'),
        ],
        const TextButton(
          key: typeKey,
          onPressed: null,
          child: Text('Adjust type'),
        ),
        Slider(
          key: severityKey,
          value: ((estimate?.severity ?? 0) * 100).clamp(0, 100).toDouble(),
          max: 100,
          onChanged: null,
        ),
        const SizedBox(key: caveatKey),
        const TextButton(
          key: saveKey,
          onPressed: null,
          child: Text('Save profile'),
        ),
      ],
    );
  }
}
