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
    testWidgets('renders under a Palette app bar with every region resolvable',
        (tester) async {
      await _pump(
        tester,
        palette: _paletteController(),
        project: _projectController(),
      );

      expect(find.widgetWithText(AppBar, 'Palette'), findsOneWidget);
      // Every keyed region is present in the shell (both views at once).
      expect(find.byKey(VisionProfileCard.regionKey), findsOneWidget);
      expect(find.byKey(PaletteScreen.viewSelectorKey), findsOneWidget);
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsOneWidget);
      expect(find.byKey(PaletteSelectorRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget);
    });

    testWidgets('the still-inert E30/E33/E34 controls have no action',
        (tester) async {
      await _pump(
        tester,
        palette: _paletteController(),
        project: _projectController(),
      );

      // E32 Add paint is wired by PALETTE-2 (AC-4) — exercised by the add-paint
      // tests below; the rest stay inert until their behaviour phases.
      for (final key in [
        VisionProfileCard.retakeKey,
        ProjectsRegion.openProjectKey,
        ProjectsRegion.exportKey,
      ]) {
        final button = tester.widget<TextButton>(find.byKey(key));
        expect(button.onPressed, isNull, reason: '$key must be inert');
      }
      // E32 Add paint is now active.
      final addPaint =
          tester.widget<TextButton>(find.byKey(PaintListRegion.addPaintKey));
      expect(addPaint.onPressed, isNotNull,
          reason: 'PALETTE-2 wires the add-paint control (AC-4)');
      // E31 selector segments are inert too.
      final segments = tester.widgetList<TextButton>(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.byType(TextButton),
        ),
      );
      expect(segments, isNotEmpty);
      expect(segments.every((b) => b.onPressed == null), isTrue);
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

      expect(find.text('No paints yet'), findsOneWidget);
      expect(find.text('No palettes yet'), findsOneWidget);
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

      // Paint-list region shows the paint name.
      expect(find.text('Titanium White'), findsOneWidget);
      // Palette-selector marks the active (first) palette and lists the other.
      expect(find.text('My paints (active)'), findsOneWidget);
      expect(find.text('Travel set'), findsOneWidget);
      // Projects region lists the project.
      expect(find.text('Harbor at Dusk'), findsOneWidget);
    });
  });
}
