import 'package:flutter/material.dart';

import '../../a11y/cvd/cvd_profile.dart';
import '../engine/severity_band.dart';
import '../onboarding_controller.dart';

/// The result step (wireframe S1.R1.E40 adjust CVD type [button], E41 severity
/// slider [input], E43 save profile [button]; AC-1, AC-10, AC-11, AC-12, AC-13).
///
/// Shows the estimated type and severity, the by-hand type control, the severity
/// slider (which doubles as the subjective self-calibration), the plain-language
/// band readout, the save control and the approximate-estimate caveat. The
/// FLOW-1 shell rendered every control **inert** (`onPressed`/`onChanged: null`)
/// and a static caveat placeholder: FLOW-5 assembles the estimate onto this
/// step, **FLOW-6 wires the by-hand type picker (one choice per `CvdType`) onto
/// `setType`**, ENGINE-7 makes the severity slider move and
/// reads its value back as a band (AC-11)**, FLOW-7 keeps that chosen severity
/// as the subjective self-calibration (`setSeverity`/`confirmCalibration`) and
/// shows the simulated/original pair, FLOW-8 fills the caveat, and PROFILE-2
/// wires save.
class ResultStep extends StatefulWidget {
  /// Creates the result step over [controller].
  const ResultStep({required this.controller, super.key});

  /// Stable anchor for the result step.
  static const Key regionKey = ValueKey('onboarding-result-step');

  /// Stable anchor for the by-hand type control group (E40) — the `Wrap`
  /// holding one choice per [CvdType].
  static const Key typeKey = ValueKey('onboarding-result-type');

  /// Stable anchor for the by-hand type choice for [type] (E40, FLOW-6). The
  /// painter taps one to override the estimated type; the driver selects a
  /// specific type through this key (AC-10).
  static Key typeChoiceKey(CvdType type) =>
      ValueKey('onboarding-result-type-${type.name}');

  /// Stable anchor for the severity slider (E41).
  static const Key severityKey = ValueKey('onboarding-result-severity');

  /// Stable anchor for the plain-language band readout (AC-11).
  static const Key bandKey = ValueKey('onboarding-result-band');

  /// Stable anchor for the save control (E43).
  static const Key saveKey = ValueKey('onboarding-result-save');

  /// Stable anchor for the approximate-estimate caveat area (AC-1, FLOW-8).
  static const Key caveatKey = ValueKey('onboarding-result-caveat');

  /// The controller the type / severity / save actions act on (FLOW-5..8,
  /// PROFILE-2).
  final OnboardingController controller;

  @override
  State<ResultStep> createState() => _ResultStepState();
}

class _ResultStepState extends State<ResultStep> {
  /// The severity (0..1) the slider is currently showing, or null until the
  /// painter has moved it — until then the slider sits at the assembled
  /// estimate's severity. This is a view-local working value: ENGINE-7 only
  /// reads it back as a band (AC-11). FLOW-7 keeps it as the controller's
  /// `calibratedSeverity` (AC-12); no save happens here.
  double? _working;

  /// The by-hand type picker (E40): one choice per [CvdType], wrapped under
  /// [ResultStep.typeKey]. When [enabled] each choice overrides the estimate's
  /// type via `setType`; before the estimate is assembled the choices are inert.
  Widget _typePicker({required bool enabled}) {
    return Wrap(
      key: ResultStep.typeKey,
      spacing: 8,
      children: [
        for (final type in CvdType.values)
          TextButton(
            key: ResultStep.typeChoiceKey(type),
            onPressed: enabled ? () => widget.controller.setType(type) : null,
            child: Text(type.name),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // FLOW-5 assembles the estimate onto the controller and advances here; until
    // then (e.g. the shell / before "See my result") there is no estimate and the
    // step shows its placeholder with the slider inert.
    final estimate = widget.controller.state.estimate;
    if (estimate == null) {
      return Column(
        key: ResultStep.regionKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Result'),
          // No estimate to adjust yet (shell / before "See my result"), so the
          // type choices are present but inert.
          _typePicker(enabled: false),
          Slider(
            key: ResultStep.severityKey,
            value: 0,
            max: 100,
            onChanged: null,
          ),
          const SizedBox(key: ResultStep.caveatKey),
          const TextButton(
            key: ResultStep.saveKey,
            onPressed: null,
            child: Text('Save profile'),
          ),
        ],
      );
    }

    // The slider shows the severity the painter is currently on — the assembled
    // estimate until they move it — on the 0..100 scale (D-5). Its value is read
    // back through the engine into a plain-language band (AC-11, G-4): moving the
    // slider across the mild/moderate/strong anchors re-renders the band text.
    final severity = _working ?? estimate.severity;
    final SeverityBand band = widget.controller.engine.band(severity);
    return Column(
      key: ResultStep.regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estimated type: ${estimate.type.name}'),
        Text('Estimated severity: ${(estimate.severity * 100).round()}'),
        // The by-hand override (E40): tapping a choice sets the estimate's type
        // to it regardless of what the tiers computed (AC-10).
        _typePicker(enabled: true),
        Slider(
          key: ResultStep.severityKey,
          value: (severity * 100).clamp(0, 100).toDouble(),
          max: 100,
          onChanged: (value) => setState(() => _working = value / 100),
        ),
        Text('Severity band: ${band.label}', key: ResultStep.bandKey),
        const SizedBox(key: ResultStep.caveatKey),
        const TextButton(
          key: ResultStep.saveKey,
          onPressed: null,
          child: Text('Save profile'),
        ),
      ],
    );
  }
}
