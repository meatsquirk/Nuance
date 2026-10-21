import 'package:flutter/material.dart';

import '../app/build_app.dart';
import '../widgets/swatch_caption.dart';
import 'capture_controller.dart';
import 'capture_controls.dart';
import 'capture_current_reading.dart';
import 'capture_live_view.dart';
import 'capture_readings_list.dart';

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
///
/// bs-09 places the multi-point readings region ([CaptureReadingsList]) between
/// the live view and the controls; it is empty until points are sampled
/// (CAPTURE-4).
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
                // The live viewport takes the space above the controls; it is
                // told which poor conditions are active (bs-12 AC-9) so it can
                // surface the downgrade reasons in words.
                Expanded(
                  child: CaptureLiveView(
                    state: controller.state,
                    // bs-19 VIEW-2: paint the active source's latest frame as
                    // the live preview (the camera feed). Null on the software
                    // / no-camera fallback, which keeps the flat placeholder.
                    frame: controller.currentFrame,
                    downgradeReasons: controller.activeDowngradeReasons,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // bs-10 live reading swatch (AC-9): the colour under the
                      // reticle, routed through the shared ColorChip chokepoint
                      // so daltonization reaches the Capture screen too; absent
                      // until a colour is sampled.
                      CaptureCurrentReading(
                        sample: controller.state.currentSample,
                      ),
                      // The swatch approximation caption (bs-17 AC-15), shown
                      // once whenever the screen renders a colour swatch — i.e.
                      // when a reading has been sampled AND there is a
                      // colour-science scope to render it through (the same
                      // condition [CaptureCurrentReading] draws its live swatch
                      // under). Otherwise there is no swatch, so no caption and
                      // the layout is unchanged.
                      if (controller.state.currentSample != null &&
                          AppScope.maybeOf(context)?.colorScience != null)
                        const SwatchCaption(),
                      // bs-09 multi-point readings region (AC-3/AC-4); empty
                      // until points are sampled (CAPTURE-4).
                      CaptureReadingsList(
                        readings: controller.state.markedReadings,
                      ),
                      CaptureControls(controller: controller),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
