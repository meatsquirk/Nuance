// bs-18 acceptance suite — Projects-region AC (ITEST-3): AC-9 the projects as
// cards with pill actions (owner ORG-2).
//
// The Projects region is the Palette screen's second view: pump the real Palette
// screen (`pumpScreen(palette)`, wired with the fixture project), switch to the
// Projects view through the E31 view selector, and read the design-system
// treatment off the pumped tree. Pending; red at baseline (project entries are
// bare GestureDetector/Column rows, actions are ad-hoc `TextButton`s).
//
// SCOPE NOTE for the ITEST-5 / G-2 review (see ITEST.md): the scenario names
// "open and create-project" actions, but `projects_region.dart` has no
// create-project control — its two actions are Open (E33, `openProjectKey`) and
// Export (E34, `exportKey`). This test asserts both real actions become pills;
// the reviewer confirms whether a create-project action is in AC-9's scope.
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/palette/projects_region.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-9 — Projects as cards with pill actions (owner ORG-2)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-9',
      'TestAC09_Projects: each project entry sits in a surface card and the open '
      '& export project actions render as pills', (tester) async {
    // GIVEN the painter switches the Palette screen to its Projects view (E31
    // view selector) — the fixture project entry renders. Tapping by label text
    // is robust to the selector's own future pill swap.
    await pumpScreen(tester, VisualScreen.palette);
    final projectsTab = find.descendant(
      of: find.byKey(PaletteScreen.viewSelectorKey),
      matching: find.text('Projects'),
    );
    expect(projectsTab, findsOneWidget,
        reason: 'Given: the Projects view selector is present');
    await tester.tap(projectsTab);
    await tester.pumpAndSettle();
    expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget,
        reason: 'Given: the Projects region renders');
    final projectRow = find.byKey(ProjectsRegion.projectRowKey('proj-harbor'));
    expect(projectRow, findsOneWidget,
        reason: 'Given: the fixture project entry renders');

    // WHEN the projects list renders.

    // THEN the project entry sits in a surface card (rejects an entry left as a
    // bare ListTile / Column row).
    expect(
      find.ancestor(of: projectRow, matching: find.byType(SurfaceCard)),
      findsOneWidget,
      reason: 'the project entry sits inside a SurfaceCard',
    );

    // THEN the open and export project actions render as design-system pills,
    // not the ad-hoc TextButtons they are today (rejects an action left ad-hoc).
    expectPill(tester, ProjectsRegion.openProjectKey,
        reason: 'the open-project action renders as a PillButton');
    expectPill(tester, ProjectsRegion.exportKey,
        reason: 'the export-project action renders as a PillButton');
  });
}
