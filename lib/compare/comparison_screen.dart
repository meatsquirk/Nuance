import 'package:flutter/material.dart';

import '../app/app_top_bar.dart';
import '../widgets/speak_button.dart';
import '../widgets/surface_card.dart';
import 'actions_bar.dart';
import 'comparison_controller.dart';
import 'confusion_region.dart';
import 'difference_region.dart';
import 'slots_region.dart';
import 'statement_region.dart';

/// The Comparison screen: the single surface the painter compares two samples
/// through (wireframe S1.R1, elements E3–E8 and the sample picker E49).
///
/// A pure view over the [ComparisonController] it is given (owned by
/// [ComparisonHomeScreen], which also wraps this subtree in the
/// `ComparisonReadEndpoint` the acceptance suite observes). It lays out every
/// region — the two slots, the overall difference, the relational statement, the
/// confusion warning and the actions bar — so the acceptance finders and the
/// behaviour phases have stable anchors. This shell renders placeholders and
/// disabled controls; each region's real reading and each action land in their
/// behaviour phase.
class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({required this.controller, super.key});

  /// The controller every region reads and (later) acts on.
  final ComparisonController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
          title: 'Comparison', themeToggle: ThemeToggleButton()),
      // Speak is the wireframe's round accent floating speak button (AC-6): an
      // always-visible FAB, not an in-scroll control, so it reads and activates
      // without scrolling. Its key is the shared [ComparisonActionsBar.speakKey]
      // anchor and its label is unchanged, so the spoken-output siblings still
      // land on and drive it. It is enabled only once there is a comparison to
      // speak (both slots set), so it rebuilds with the controller's state.
      floatingActionButton: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SpeakButton(
          key: ComparisonActionsBar.speakKey,
          onPressed: controller.state.comparison != null
              ? () => controller.speak()
              : null,
          semanticLabel: 'Speak whole comparison',
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SlotsRegion(controller: controller),
                const SizedBox(height: 12),
                _carded(DifferenceRegion(controller: controller)),
                const SizedBox(height: 12),
                _carded(StatementRegion(controller: controller)),
                const SizedBox(height: 12),
                ConfusionRegion(controller: controller),
                const SizedBox(height: 16),
                ComparisonActionsBar(controller: controller),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lays a comparison [region] inside a [SurfaceCard] — the wireframe's carded
/// reading treatment (AC-6). The region keeps its own key, so the card sits
/// *above* the region's anchor (the acceptance finders read the card as the
/// region's ancestor). The difference and statement regions already render their
/// own field heading, so no mono eyebrow is added here.
Widget _carded(Widget region) => SurfaceCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: region,
      ),
    );
