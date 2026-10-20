import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
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
import 'package:paint_color_assistant/store/source_photo_store.dart';
import 'package:paint_color_assistant/widgets/pill_button.dart';

PaletteController _paletteController({List<PaintPalette> catalogue = const []}) =>
    PaletteController(source: InMemoryPaletteSource(catalogue: catalogue));

ProjectController _projectController({
  List<Project> catalogue = const [],
  ConfusionCheck confusionCheck = const DichromatConfusionCheck(),
}) =>
    ProjectController(
      source: InMemoryProjectSource(catalogue: catalogue),
      confusionCheck: confusionCheck,
    );

/// A [ConfusionCheck] that flags exactly the listed unordered coordinate pairs,
/// so the open-project view's confusion warning can be exercised without
/// bs-03's CVD math (that is acceptance-tested against the real detector).
class _StubConfusionCheck implements ConfusionCheck {
  const _StubConfusionCheck(this._flagged);

  final Set<Set<ColorCoordinates>> _flagged;

  @override
  bool confusable(ColorCoordinates a, ColorCoordinates b, CvdProfile profile) =>
      _flagged.any((pair) => pair.length == 2 && pair.containsAll([a, b]));
}

Sample _sample(String name, double lightness) => Sample(
      name: name,
      coordinates: ColorCoordinates(lightness: lightness, a: 0, b: 0),
      provenance: const Provenance(ProvenanceTier.measured),
    );

Future<void> _pump(
  WidgetTester tester, {
  required PaletteController palette,
  required ProjectController project,
  SourcePhotoStore? photos,
}) {
  return tester.pumpWidget(
    // PaletteScreen reads the injected CvdProfile / router from the enclosing
    // AppScope (SCREEN-3 wires the vision-profile card), as the real assembly
    // does; the suite's default deutan profile and router suffice here. The
    // open-project view reads the source-photo store from the same scope
    // (PROJECT-4), so a photo test injects one here.
    AppScope(
      dependencies: AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: const NoopSpeech(),
        haptics: const NoopHaptics(),
        sourcePhotoStore: photos,
      ),
      child: MaterialApp(
        home: PaletteScreen(
          paletteController: palette,
          projectController: project,
        ),
      ),
    ),
  );
}

/// A [SourcePhotoStore] whose [read] always returns [_bytes] (or null when none),
/// so the open-project view's photo path can be exercised without the filesystem.
class _StubPhotos implements SourcePhotoStore {
  _StubPhotos(this._bytes);

  final Uint8List? _bytes;

  @override
  Future<Uint8List?> read(String reference) async => _bytes;

  @override
  Future<String> save(Uint8List bytes) async => 'ref';

  @override
  Future<bool> exists(String reference) async => _bytes != null;

  @override
  Future<void> delete(String reference) async {}
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

    testWidgets(
        'E30/E31/E32/E33 controls are wired; E34 export activates once a '
        'project is open and produces the sheet', (tester) async {
      final project = _projectController(
        catalogue: const [Project(id: 'p1', name: 'Harbor at Dusk')],
      );
      await _pump(
        tester,
        palette: _paletteController(),
        project: project,
      );

      // E32 Add paint is now active (PALETTE-2, AC-4). bs-18 ORG-1 swapped the
      // ad-hoc `TextButton` for the design-system `PillButton` (AC-8), so read
      // its wiring off the pill.
      final addPaint =
          tester.widget<PillButton>(find.byKey(PaintListRegion.addPaintKey));
      expect(addPaint.onPressed, isNotNull,
          reason: 'PALETTE-2 wires the add-paint control (AC-4)');
      // E30 Retake the self-assessment is now active (SCREEN-3, AC-11); also a
      // `PillButton` after the ORG-1 swap (AC-8).
      final retake =
          tester.widget<PillButton>(find.byKey(VisionProfileCard.retakeKey));
      expect(retake.onPressed, isNotNull,
          reason: 'SCREEN-3 wires the retake control (AC-11)');
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

      // E33 Open is now wired (PROJECT-4, AC-7/AC-8); reach it by the E31
      // toggle. E34 Export is inert until a project is open — the open project
      // is what is exported (PROJECT-6, AC-10).
      await tester.tap(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.widgetWithText(TextButton, 'Projects'),
        ),
      );
      await tester.pumpAndSettle();
      // bs-18 ORG-2 swapped the ad-hoc open/export `TextButton`s for the
      // design-system `PillButton` (AC-9), so read their wiring off the pills.
      final open =
          tester.widget<PillButton>(find.byKey(ProjectsRegion.openProjectKey));
      expect(open.onPressed, isNotNull,
          reason: 'PROJECT-4 wires the open-project control (AC-7/AC-8), active '
              'when a project exists');
      expect(
          tester
              .widget<PillButton>(find.byKey(ProjectsRegion.exportKey))
              .onPressed,
          isNull,
          reason: 'E34 export is inert while no project is open');

      // Open the project, then E34 Export activates and produces the sheet.
      await tester.tap(find.byKey(ProjectsRegion.openProjectKey));
      await tester.pumpAndSettle();
      final export =
          tester.widget<PillButton>(find.byKey(ProjectsRegion.exportKey));
      expect(export.onPressed, isNotNull,
          reason: 'PROJECT-6 wires E34 export once a project is open (AC-10)');
      expect(project.lastExport, isNull, reason: 'nothing exported yet');

      await tester.tap(find.byKey(ProjectsRegion.exportKey));
      await tester.pumpAndSettle();
      final pdf = project.lastExport;
      expect(pdf, isNotNull,
          reason: 'tapping E34 exports the opened project as a PDF (AC-10)');
      expect(String.fromCharCodes(pdf!.take(5)), '%PDF-');
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

    testWidgets(
        'AC-6: a project row shows its size, counts and relative last edit',
        (tester) async {
      final project = _projectController(
        catalogue: [
          Project(
            id: 'harbor-at-dusk',
            name: 'Harbor at Dusk',
            size: '24×30 in',
            lastEdited: DateTime.now(),
          ),
        ],
      );
      await _pump(tester, palette: _paletteController(), project: project);

      // Reach the Projects view (E31), then scope to the project's own row.
      await tester.tap(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.widgetWithText(TextButton, 'Projects'),
        ),
      );
      await tester.pumpAndSettle();

      Finder inRow(Finder m) => find.descendant(
            of: find.byKey(ProjectsRegion.projectRowKey('harbor-at-dusk')),
            matching: m,
          );
      // The detail line carries the free-text size and both (zero) counts; a
      // separate line carries the relative last edit.
      expect(inRow(find.textContaining('24×30 in')), findsOneWidget);
      expect(inRow(find.textContaining('0 samples')), findsOneWidget);
      expect(inRow(find.textContaining('0 recipes')), findsOneWidget);
      expect(inRow(find.text('Edited today')), findsOneWidget);
    });
  });

  group('open-project view (PROJECT-4)', () {
    Future<void> pumpProjects(
      WidgetTester tester, {
      required ProjectController project,
      SourcePhotoStore? photos,
    }) async {
      await _pump(
          tester, palette: _paletteController(), project: project, photos: photos);
      await tester.tap(
        find.descendant(
          of: find.byKey(PaletteScreen.viewSelectorKey),
          matching: find.widgetWithText(TextButton, 'Projects'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
        'AC-7/AC-8: tapping a project row opens it, showing its note and its '
        'own source photo', (tester) async {
      final bytes = Uint8List.fromList(const [1, 2, 3, 4]);
      const note = 'Keep the hull and wall values 2 steps apart.';
      final project = _projectController(
        catalogue: const [
          Project(
            id: 'harbor-at-dusk',
            name: 'Harbor at Dusk',
            note: note,
            sourcePhotoRef: 'harbor-source-photo',
          ),
        ],
      );
      await pumpProjects(tester, project: project, photos: _StubPhotos(bytes));

      // No project is open to begin with.
      expect(project.openedProject, isNull);
      expect(find.byKey(ProjectsRegion.openProjectViewKey), findsNothing);

      // Tapping the project's row opens it (E33, AC-7).
      await tester.tap(find.byKey(ProjectsRegion.projectRowKey('harbor-at-dusk')));
      await tester.pumpAndSettle();

      expect(project.openedProject?.name, 'Harbor at Dusk');
      final view = find.byKey(ProjectsRegion.openProjectViewKey);
      expect(view, findsOneWidget);
      // The note is shown in the open-project view.
      expect(find.descendant(of: view, matching: find.text(note)),
          findsOneWidget);
      // The source photo is shown, rendered from the project's own stored bytes.
      final photo =
          find.descendant(of: view, matching: find.byType(Image));
      expect(photo, findsOneWidget);
      final image = tester.widget<Image>(photo).image;
      expect(image, isA<MemoryImage>());
      expect((image as MemoryImage).bytes, bytes);
    });

    testWidgets(
        'the E33 Open control opens the first project (AC-7)', (tester) async {
      final project = _projectController(
        catalogue: const [Project(id: 'p1', name: 'Harbor at Dusk')],
      );
      await pumpProjects(tester, project: project);

      await tester.tap(find.byKey(ProjectsRegion.openProjectKey));
      await tester.pumpAndSettle();

      expect(project.openedProject?.id, 'p1');
    });

    testWidgets(
        'an opened project with no note and no photo shows the view without '
        'either', (tester) async {
      final project = _projectController(
        catalogue: const [Project(id: 'p1', name: 'Untitled')],
      );
      await pumpProjects(tester, project: project);

      await tester.tap(find.byKey(ProjectsRegion.projectRowKey('p1')));
      await tester.pumpAndSettle();

      final view = find.byKey(ProjectsRegion.openProjectViewKey);
      expect(view, findsOneWidget);
      expect(find.descendant(of: view, matching: find.byType(Image)),
          findsNothing);
    });

    testWidgets(
        'an opened project whose photo bytes are absent shows no image',
        (tester) async {
      final project = _projectController(
        catalogue: const [
          Project(id: 'p1', name: 'Harbor', sourcePhotoRef: 'missing'),
        ],
      );
      await pumpProjects(tester, project: project, photos: _StubPhotos(null));

      await tester.tap(find.byKey(ProjectsRegion.projectRowKey('p1')));
      await tester.pumpAndSettle();

      final view = find.byKey(ProjectsRegion.openProjectViewKey);
      expect(view, findsOneWidget);
      expect(find.descendant(of: view, matching: find.byType(Image)),
          findsNothing);
    });

    testWidgets(
        'AC-9: an opened project with a confusable pair shows a check-by-value '
        'warning naming the pair', (tester) async {
      final umber = _sample('Mid Raw Umber', 42);
      final shadow = _sample('Ultramarine Shadow', 43);
      final hull = _sample('Hull Red', 80);
      final project = _projectController(
        catalogue: [
          Project(
            id: 'p1',
            name: 'Harbor at Dusk',
            samples: [umber, shadow, hull],
          ),
        ],
        confusionCheck: _StubConfusionCheck({
          {umber.coordinates, shadow.coordinates},
        }),
      );
      await pumpProjects(tester, project: project);

      await tester.tap(find.byKey(ProjectsRegion.projectRowKey('p1')));
      await tester.pumpAndSettle();

      final view = find.byKey(ProjectsRegion.openProjectViewKey);
      // A "check these by value" warning is shown for the flagged pair.
      expect(
        find.descendant(
          of: view,
          matching: find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').toLowerCase().contains('check'),
          ),
        ),
        findsOneWidget,
      );
      // The flagged pair is named; the clearly-distinct Hull Red is not paired.
      expect(
        find.descendant(
          of: view,
          matching: find.text('Mid Raw Umber and Ultramarine Shadow'),
        ),
        findsOneWidget,
      );
      expect(find.descendant(of: view, matching: find.textContaining('Hull Red')),
          findsNothing);
    });
  });
}
