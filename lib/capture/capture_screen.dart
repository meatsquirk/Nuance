import 'package:flutter/material.dart';

import 'capture_controller.dart';
import 'capture_controls.dart';
import 'capture_live_view.dart';

/// The Capture screen: the single surface a painter captures a colour through
/// (wireframe S1.R1, elements E15–E21).
///
/// It binds to a [CaptureController] and lays out the live viewport (feed,
/// centre eyedropper, stability / accuracy / warning readings — [CaptureLiveView])
/// over the control surface (E15–E21 — [CaptureControls]), rebuilding on every
/// state change through a [ListenableBuilder]. This SCREEN-1 shell renders every
/// region as a findable placeholder bound to [CaptureController.state]; each
/// region's real behaviour lands in its behaviour phase (sampling SOURCE-2/3,
/// lock/accuracy/commit CAPTURE-3..6, eyedropper + radius SCREEN-2, value-only
/// SCREEN-3). The controller ownership and the acceptance read endpoint stay
/// with [CaptureHomeScreen] above this screen.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({required this.controller, super.key});

  /// The controller this screen reads and drives.
  final CaptureController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return Column(
              children: [
                // The live viewport takes the space above the controls.
                Expanded(child: CaptureLiveView(state: controller.state)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CaptureControls(controller: controller),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
