import 'package:flutter/material.dart';

import '../../a11y/cvd/cvd_profile.dart';
import '../engine/severity_band.dart';
import '../onboarding_controller.dart';

/// The result step (wireframe S1.R1.E40 adjust CVD type [button], E41 severity
/// slider [input], E43 save profile [button]; AC-1, AC-10, AC-11, AC-12, AC-13).
///
/// Shows the estimated type and severity, the by-hand type control, the severity
/// slider (which doubles as the subjective self-calibration), the
/// simulated-versus-original colour pair, the plain-language band readout, the
/// save control and the approximate-estimate caveat. The FLOW-1 shell rendered
/// every control **inert** (`onPressed`/`onChanged: null`) and a static caveat
/// placeholder: FLOW-5 assembles the estimate onto this step, **FLOW-6 wires the
/// by-hand type picker (one choice per `CvdType`) onto `setType`**, ENGINE-7
/// makes the severity slider move and reads its value back as a band (AC-11),
/// **FLOW-7 keeps that chosen severity as the subjective self-calibration
/// (`setSeverity`/`confirmCalibration`) and shows the simulated/original pair**,
/// FLOW-8 fills the caveat, and PROFILE-2 wires save.
///
/// A pure [StatelessWidget] over the controller: the chosen severity lives on the
/// controller as [OnboardingState.calibratedSeverity] (FLOW-7), not in view-local
/// state, so the slider, the pair and the band all read it back and re-render
/// when the controller notifies (the host wraps this in a `ListenableBuilder`).
class ResultStep extends StatelessWidget {
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

  /// Stable anchor for the simulated-versus-original colour pair (E41, FLOW-7)
  /// — shown alongside the slider; both swatches re-render as the severity moves.
  static const Key pairKey = ValueKey('onboarding-result-pair');

  /// Stable anchor for the *original* swatch of the pair (AC-12).
  static const Key pairOriginalKey = ValueKey('onboarding-result-pair-original');

  /// Stable anchor for the *simulated* swatch of the pair (AC-12) — the one that
  /// collapses toward the original as the painter raises the severity.
  static const Key pairSimulatedKey =
      ValueKey('onboarding-result-pair-simulated');

  /// Stable anchor for the plain-language band readout (AC-11).
  static const Key bandKey = ValueKey('onboarding-result-band');

  /// Stable anchor for the save control (E43).
  static const Key saveKey = ValueKey('onboarding-result-save');

  /// Stable anchor for the approximate-estimate caveat area (AC-1, FLOW-8).
  static const Key caveatKey = ValueKey('onboarding-result-caveat');

  /// A representative colour whose confusable partner the painter calibrates
  /// against (E41). bs-07 shows an *illustrative* stand-in: the simulated swatch
  /// collapses toward this original as the severity rises. The real per-channel
  /// CVD projection lives behind `ConfusionCheck` and arrives with the display
  /// simulation / daltonization features (bs-08 / bs-10); bs-07 only needs the
  /// pair to re-render with the slider so the painter can self-calibrate.
  static const Color _pairOriginal = Color(0xFF4CAF50);

  /// The illustrative "simulated" colour for [severity] (0..1): the original
  /// blended toward a neutral grey in proportion to the severity, so a stronger
  /// severity makes the pair look more alike (the collapse the painter dials in).
  static Color _simulatedColour(double severity) =>
      Color.lerp(_pairOriginal, const Color(0xFF9E9E9E),
          severity.clamp(0.0, 1.0))!;

  /// The controller the type / severity / save actions act on (FLOW-5..8,
  /// PROFILE-2).
  final OnboardingController controller;

  /// The by-hand type picker (E40): one choice per [CvdType], wrapped under
  /// [typeKey]. When [enabled] each choice overrides the estimate's type via
  /// `setType`; before the estimate is assembled the choices are inert.
  Widget _typePicker({required bool enabled}) {
    return Wrap(
      key: typeKey,
      spacing: 8,
      children: [
        for (final type in CvdType.values)
          TextButton(
            key: typeChoiceKey(type),
            onPressed: enabled ? () => controller.setType(type) : null,
            child: Text(type.name),
          ),
      ],
    );
  }

  /// The simulated-versus-original pair (E41): two swatches side by side. The
  /// simulated one collapses toward the original as [severity] rises, so the
  /// painter raises the slider until "the pair stops looking different to them"
  /// (AC-12).
  Widget _simulatedPair(double severity) {
    Widget swatch(Key key, Color colour, String label) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(key: key, width: 48, height: 48, color: colour),
            Text(label),
          ],
        );
    return Row(
      key: pairKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        swatch(pairOriginalKey, _pairOriginal, 'Original'),
        const SizedBox(width: 8),
        swatch(pairSimulatedKey, _simulatedColour(severity), 'Simulated'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // FLOW-5 assembles the estimate onto the controller and advances here; until
    // then (e.g. the shell / before "See my result") there is no estimate and the
    // step shows its placeholder with the slider inert.
    final estimate = controller.state.estimate;
    if (estimate == null) {
      return Column(
        key: regionKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Result'),
          // No estimate to adjust yet (shell / before "See my result"), so the
          // type choices are present but inert.
          _typePicker(enabled: false),
          Slider(
            key: severityKey,
            value: 0,
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

    // The severity the painter is currently on: their kept self-calibration once
    // they have moved the slider (FLOW-7), else the assembled estimate. The
    // slider, the simulated/original pair and the band all read this one value,
    // so moving the slider re-renders them together. Dragging keeps the value
    // live via `setSeverity`; releasing finalises it via `confirmCalibration`
    // (which keeps the estimate's severity if the slider was never moved).
    final severity = controller.state.calibratedSeverity ?? estimate.severity;
    final SeverityBand band = controller.engine.band(severity);
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estimated type: ${estimate.type.name}'),
        Text('Estimated severity: ${(estimate.severity * 100).round()}'),
        // The by-hand override (E40): tapping a choice sets the estimate's type
        // to it regardless of what the tiers computed (AC-10).
        _typePicker(enabled: true),
        _simulatedPair(severity),
        Slider(
          key: severityKey,
          value: (severity * 100).clamp(0, 100).toDouble(),
          max: 100,
          onChanged: (value) => controller.setSeverity(value / 100),
          onChangeEnd: (_) => controller.confirmCalibration(),
        ),
        Text('Severity band: ${band.label}', key: bandKey),
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
