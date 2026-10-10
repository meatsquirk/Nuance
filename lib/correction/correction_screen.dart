import 'package:flutter/material.dart';

import 'correction_controller.dart';
import 'regions/check_region.dart';
import 'regions/correction_region.dart';
import 'regions/difference_region.dart';
import 'regions/rephotograph_region.dart';
import 'regions/save_region.dart';
import 'regions/speak_region.dart';

/// The Correction screen: the single surface the painter corrects a mixed colour
/// toward its target through (wireframe S?.R?, elements E26–E29 plus the
/// difference / correction / provenance readings).
///
/// A pure view over the [CorrectionController] it is given (owned by
/// `CorrectionHomeScreen`, which also wraps this subtree in the
/// `CorrectionReadEndpoint` the acceptance suite observes), mirroring bs-04's
/// `RecipesScreen`. It lays out every region in loop order — check (E26), the
/// difference and correction readings, speak (E27), re-photograph (E28) and save
/// (E29) — so the acceptance finders and the behaviour phases have stable
/// anchors (`<Region>.regionKey`).
///
/// This SCREEN-1 **shell** renders the check region's target line (bound to the
/// controller) and otherwise placeholders and disabled controls; each region's
/// real reading and each action land in its behaviour phase (LOOP-3/4/5/6,
/// CORRECT-2/3/4). The screen rebuilds on the controller's notifications so those
/// phases surface state as it moves.
class CorrectionScreen extends StatelessWidget {
  const CorrectionScreen({required this.controller, super.key});

  /// The controller every region reads and (later) acts on.
  final CorrectionController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Correction')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CheckRegion(controller: controller),
                const SizedBox(height: 12),
                const DifferenceRegion(),
                const SizedBox(height: 12),
                const CorrectionRegion(),
                const SizedBox(height: 12),
                const SpeakRegion(),
                const SizedBox(height: 12),
                const RephotographRegion(),
                const SizedBox(height: 12),
                const SaveRegion(),
              ],
            );
          },
        ),
      ),
    );
  }
}
