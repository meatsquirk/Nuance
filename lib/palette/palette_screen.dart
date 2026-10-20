import 'package:flutter/material.dart';

import '../app/app_top_bar.dart';
import '../app/build_app.dart';
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
/// The E31 selector toggles between the My-paints view (paint list, provenance
/// legend, palette selector) and the Projects view (projects list), with one
/// visible at a time (AC-1); each region's real reading and action land in its
/// behaviour phase (PALETTE-2..4, PROJECT-3..6, SCREEN-3).
class PaletteScreen extends StatefulWidget {
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
  State<PaletteScreen> createState() => _PaletteScreenState();
}

/// Which of the two mutually-exclusive E31 views is showing (AC-1).
enum _PaletteView { myPaints, projects }

class _PaletteScreenState extends State<PaletteScreen> {
  /// The view E31 is currently showing; My paints to begin with.
  _PaletteView _view = _PaletteView.myPaints;

  void _show(_PaletteView view) => setState(() => _view = view);

  @override
  Widget build(BuildContext context) {
    final showMyPaints = _view == _PaletteView.myPaints;
    return Scaffold(
      appBar: const AppTopBar(title: 'Palette', themeToggle: ThemeToggleButton()),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge(
              [widget.paletteController, widget.projectController]),
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // E30 vision-profile card — reads the injected CvdProfile and
                // router from the enclosing AppScope (SCREEN-3, AC-11).
                VisionProfileCard(
                  profile: AppScope.of(context).cvdProfile,
                  router: AppScope.of(context).router,
                ),
                const SizedBox(height: 12),
                // E31 Paints or projects selector — toggles which view is
                // shown, one at a time (AC-1). A `Wrap` (not a `Row`) so the two
                // buttons reflow onto a second line instead of overflowing at
                // 200% font scale (AC-3); one line at the default scale.
                Wrap(
                  key: PaletteScreen.viewSelectorKey,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _show(_PaletteView.myPaints),
                      child: const Text('My paints'),
                    ),
                    TextButton(
                      onPressed: () => _show(_PaletteView.projects),
                      child: const Text('Projects'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // The two views are shown *instead of* each other (AC-1): the
                // My-paints regions, or the projects list, never both at once.
                if (showMyPaints) ...[
                  PaintListRegion(controller: widget.paletteController),
                  const SizedBox(height: 12),
                  const ProvenanceLegendRegion(),
                  const SizedBox(height: 12),
                  PaletteSelectorRegion(controller: widget.paletteController),
                ] else
                  ProjectsRegion(controller: widget.projectController),
              ],
            );
          },
        ),
      ),
    );
  }
}
