import 'package:flutter/material.dart';

/// The save region of the Correction screen (wireframe element **E29** — "Save
/// confirmed mix").
///
/// Carries the control that saves the mix as confirmed, promoting the value's
/// provenance to the confirmed tier (AC-9); that provenance then surfaces in a
/// later readout's provenance badge (AC-10), not on this screen.
///
/// This is the SCREEN-1 **shell**: the control is disabled until LOOP-6 wires
/// [CorrectionController.saveConfirmed] to it. The region keeps its [regionKey]
/// as a stable anchor for the acceptance smoke test and the behaviour phases.
class SaveRegion extends StatelessWidget {
  const SaveRegion({super.key});

  /// Stable anchor for the save region.
  static const Key regionKey = ValueKey('correction-save-region');

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // E29 Save confirmed mix — wired by LOOP-6 (AC-9). Disabled in this
        // shell.
        ElevatedButton(
          onPressed: null,
          child: Text('Save confirmed mix'),
        ),
      ],
    );
  }
}
