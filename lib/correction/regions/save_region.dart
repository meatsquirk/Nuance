import 'package:flutter/material.dart';

import '../correction_controller.dart';

/// The save region of the Correction screen (wireframe element **E29** — "Save
/// confirmed mix").
///
/// Carries the control that saves the mix as confirmed, promoting the value's
/// provenance to the confirmed tier (AC-9); that provenance then surfaces in a
/// later readout's provenance badge (AC-10), not on this screen.
///
/// The control is enabled once the painter has checked a swatch — there must be
/// the painter's own measured swatch to confirm (the honest-provenance rule,
/// D-8; [CorrectionController.saveConfirmed] re-enforces it) — and wired to
/// [CorrectionController.saveConfirmed]. The region keeps its [regionKey] as a
/// stable anchor for the acceptance smoke test and the behaviour phases.
class SaveRegion extends StatelessWidget {
  const SaveRegion({required this.controller, super.key});

  /// The controller the save acts on.
  final CorrectionController controller;

  /// Stable anchor for the save region.
  static const Key regionKey = ValueKey('correction-save-region');

  @override
  Widget build(BuildContext context) {
    // Nothing to confirm until the painter has photographed and checked a swatch
    // (E29 disabled in the pre-check state).
    final canSave = controller.state.hasChecked;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E29 Save confirmed mix — promotes the value to Confirmed (AC-9).
        ElevatedButton(
          onPressed: canSave ? () => controller.saveConfirmed() : null,
          child: const Text('Save confirmed mix'),
        ),
      ],
    );
  }
}
