import 'package:flutter/material.dart';

import '../projects/project_controller.dart';
import 'paint_list_region.dart';
import 'palette_controller.dart';
import 'palette_selector_region.dart';
import 'projects_region.dart';
import 'provenance_legend_region.dart';
import 'vision_profile_card.dart';

/// The Palette screen: the single surface the painter manages their paints and
/// projects on (wireframe S1.R1, elements E30–E34).
///
/// A pure view over the [paletteController] and [projectController] it is given
/// (owned by `PaletteHomeScreen`, which also wraps this subtree in the
/// `PaletteReadEndpoint` / `ProjectReadEndpoint` the acceptance suite observes),
/// mirroring bs-04's `RecipesScreen`. It lays out every region — the
/// vision-profile card (E30), the My paints / Projects view selector (E31), the
/// paint list (E32), the provenance legend, the palette selector and the
/// projects list (E33/E34) — so the acceptance finders and the behaviour phases
/// have stable anchors.
///
/// This shell renders placeholders and inert controls with **both** views'
/// regions present at once, so every region key resolves; SCREEN-2 makes the
/// E31 selector toggle between the My-paints and Projects views (AC-1), and each
/// region's real reading and action land in its behaviour phase (PALETTE-2..4,
/// PROJECT-3..6, SCREEN-3).
class PaletteScreen extends StatelessWidget {
  const PaletteScreen({
    required this.paletteController,
    required this.projectController,
    super.key,
  });

  /// Stable anchor for the E31 My paints / Projects view selector (SCREEN-2
  /// wires the toggle, AC-1).
  static const Key viewSelectorKey = ValueKey('palette-view-selector');

  /// The paints/palettes controller the My-paints view regions read.
  final PaletteController paletteController;

  /// The projects controller the Projects view region reads.
  final ProjectController projectController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Palette')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([paletteController, projectController]),
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const VisionProfileCard(),
                const SizedBox(height: 12),
                // E31 Paints or projects selector — wired by SCREEN-2 (AC-1).
                // Present but inert in this shell.
                Row(
                  key: viewSelectorKey,
                  children: const [
                    TextButton(onPressed: null, child: Text('My paints')),
                    TextButton(onPressed: null, child: Text('Projects')),
                  ],
                ),
                const SizedBox(height: 12),
                PaintListRegion(controller: paletteController),
                const SizedBox(height: 12),
                const ProvenanceLegendRegion(),
                const SizedBox(height: 12),
                PaletteSelectorRegion(controller: paletteController),
                const SizedBox(height: 12),
                ProjectsRegion(controller: projectController),
              ],
            );
          },
        ),
      ),
    );
  }
}
