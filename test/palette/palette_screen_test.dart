import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/palette/paint_dataset.dart';
import 'package:paint_color_assistant/palette/paint_list_region.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/palette/palette_selector_region.dart';
import 'package:paint_color_assistant/palette/projects_region.dart';
import 'package:paint_color_assistant/palette/provenance_legend_region.dart';
import 'package:paint_color_assistant/palette/vision_profile_card.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_controller.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

PaletteController _paletteController({List<PaintPalette> catalogue = const []}) =>
    PaletteController(source: InMemoryPaletteSource(catalogue: catalogue));

ProjectController _projectController({List<Project> catalogue = const []}) =>
    ProjectController(source: InMemoryProjectSource(catalogue: catalogue));

Future<void> _pump(
  WidgetTester tester, {
  required PaletteController palette,
  required ProjectController project,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: PaletteScreen(
        paletteController: palette,
        projectController: project,
      ),
    ),
  );
}

void main() {
  group('PaletteScreen (shell)', () {
    testWidgets('renders under a Palette app bar showing the My-paints view',
        (tester) async {
      await _pump(
        tester,
        palette: _paletteController(),
        project: _projectController(),
      );

      expect(find.widgetWithText(AppBar, 'Palette'), findsOneWidget);
      // The persistent chrome and the My-paints view's regions are shown to
      // begin with; the Projects region is reached by the E31 toggle (AC-1).
      expect(find.byKey(VisionProfileCard.regionKey), findsOneWidget);
      expect(find.byKey(PaletteScreen.viewSelectorKey), findsOneWidget);
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsOneWidget);
      expect(find.byKey(PaletteSelectorRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsNothing);
    });

    testWidgets(
        'AC-1: the E31 selector toggles between the My-paints and Projects '
        'views, one visible at a time', (tester) async {
      await _pump(
        tester,
        palette: _paletteController(),
        project: _projectController(),
      );

      Future<void> tapSegment(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byKey(PaletteScreen.viewSelectorKey),
            matching: find.widgetWithText(TextButton, label),
          ),
        );
        await tester.pumpAndSettle();
      }

      // Given the My-paints view is shown to begin with.
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsNothing);

      // When switching to Projects, the projects list is shown instead of the
      // paints (and the other My-paints regions go with them).
      await tapSegment('Projects');
      expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget);
      expect(find.byKey(PaintListRegion.regionKey), findsNothing);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsNothing);
      expect(find.byKey(PaletteSelectorRegion.regionKey), findsNothing);

      // Control: switching back restores My paints and hides Projects, so the
      // view changes both ways (not a one-way or stuck toggle).
      await tapSegment('My paints');
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsOneWidget);
      expect(find.byKey(PaletteSelectorRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsNothing);
    });

    testWidgets('the still-inert E30/E33/E34 controls have no action',
        (tester) async {
      await _pump(
        tester,
        palette: _paletteController(),
        project: _projectController(),
      );

      // E30 Retake (SCREEN-3) stays inert in the My-paints view; it is always
      // shown.
      expect(
        tester.widget<TextButton>(find.byKey(VisionProfileCard.retakeKey))
            .onPressed,
        isNull,
        reason: 'E30 retake stays inert until SCREEN-3',
      );
      // E32 Add paint is now active (PALETTE-2, AC-4).
      final addPaint =
          tester.widget<TextButton>(find.byKey(PaintListRegion.addPaintKey));
      expect(addPaint.onPressed, isNotNull,
          reason: 'PALETTE-2 wires the add-paint control (AC-4)');
      // E31 selector segments are now wired (SCREEN-2, AC-1): each toggles a
      // view.
      final segments = tester.widgetList<TextButton>(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.byType(TextButton),
        ),
      );
      expect(segments, isNotEmpty);
      expect(segments.every((b) => b.onPressed != null), isTrue,
          reason: 'SCREEN-2 wires the E31 view selector (AC-1)');

      // E33 Open / E34 Export stay inert in the Projects view (their behaviour
      // phases wire them); reach them by the E31 toggle.
      await tester.tap(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.widgetWithText(TextButton, 'Projects'),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in [
        ProjectsRegion.openProjectKey,
        ProjectsRegion.exportKey,
      ]) {
        final button = tester.widget<TextButton>(find.byKey(key));
        expect(button.onPressed, isNull, reason: '$key must be inert');
      }
    });

    testWidgets(
        'AC-4: tapping Add paint opens the reviewed-dataset picker and '
        'choosing a paint adds it to My paints with provenance preserved',
        (tester) async {
      final ultramarine =
          kReviewedPaints.firstWhere((p) => p.name == 'Ultramarine Blue');
      final palette = _paletteController(
        catalogue: [
          PaintPalette(name: PaletteController.myPaintsName),
        ],
      );
      final project = _projectController();
      await _pump(tester, palette: palette, project: project);

      // Given: My paints is empty to begin with.
      expect(palette.myPaints, isEmpty);
      expect(find.text('No paints yet'), findsOneWidget);

      // When: open the picker (E32) — it offers the reviewed dataset paints.
      await tester.tap(find.byKey(PaintListRegion.addPaintKey));
      await tester.pumpAndSettle();
      expect(find.byKey(PaintListRegion.datasetPickerKey), findsOneWidget);
      // The reviewed dataset is offered to choose from (top entries visible).
      expect(find.text('Titanium White'), findsWidgets);
      expect(find.text('Ultramarine Blue'), findsWidgets);

      // When: choose "Ultramarine Blue".
      await tester.tap(find.text('Ultramarine Blue').last);
      await tester.pumpAndSettle();

      // Then: the picker closed and the exact dataset paint is in My paints.
      expect(find.byKey(PaintListRegion.datasetPickerKey), findsNothing);
      expect(palette.myPaints, [ultramarine]);
      expect(palette.myPaints.single.provenance, ultramarine.provenance);
      // The new paint renders in the list, replacing the empty-state text.
      expect(find.text('No paints yet'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(PaintListRegion.regionKey),
          matching: find.text('Ultramarine Blue'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('empty state shows the placeholders', (tester) async {
      await _pump(
        tester,
        palette: _paletteController(),
        project: _projectController(),
      );

      // My-paints view placeholders.
      expect(find.text('No paints yet'), findsOneWidget);
      expect(find.text('No palettes yet'), findsOneWidget);
      // The projects placeholder lives in the Projects view (reached via E31).
      await tester.tap(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.widgetWithText(TextButton, 'Projects'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No projects yet'), findsOneWidget);
    });

    testWidgets('seeded state lists paints, palettes and projects',
        (tester) async {
      final titaniumWhite =
          kReviewedPaints.firstWhere((p) => p.name == 'Titanium White');
      final palette = _paletteController(
        catalogue: [
          PaintPalette(
            name: PaletteController.myPaintsName,
            paints: [titaniumWhite],
          ),
          const PaintPalette(name: 'Travel set'),
        ],
      );
      final project = _projectController(
        catalogue: [const Project(id: 'p1', name: 'Harbor at Dusk')],
      );

      await _pump(tester, palette: palette, project: project);

      // My-paints view: the paint-list region shows the paint name and the
      // palette-selector marks the active (first) palette and lists the other.
      expect(find.text('Titanium White'), findsOneWidget);
      expect(find.text('My paints (active)'), findsOneWidget);
      expect(find.text('Travel set'), findsOneWidget);
      // Projects view (reached via E31): the projects region lists the project.
      // Under SCREEN-2 the two views are mutually exclusive, so the project is
      // reached by switching views (not by scrolling a single combined list).
      await tester.tap(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.widgetWithText(TextButton, 'Projects'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Harbor at Dusk'), findsOneWidget);
    });
  });
}
