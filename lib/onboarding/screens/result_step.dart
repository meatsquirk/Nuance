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
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Result'),
        TextButton(
          key: typeKey,
          onPressed: null,
          child: Text('Adjust type'),
        ),
        Slider(
          key: severityKey,
          value: 0,
          max: 100,
          onChanged: null,
        ),
        SizedBox(key: caveatKey),
        TextButton(
          key: saveKey,
          onPressed: null,
          child: Text('Save profile'),
        ),
      ],
    );
  }
}
