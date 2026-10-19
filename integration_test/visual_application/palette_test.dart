// bs-18 acceptance suite — Palette-screen AC (ITEST-3): AC-8 the paints,
// provenance and add action as design-system components (owner ORG-1).
//
// Pumps the real Palette screen (`pumpScreen(palette)`, wired with the fixture's
// three mixed-provenance paints) and reads the design-system treatment off the
// pumped tree. Pending; red at baseline on the add-from-dataset action (an
// ad-hoc `TextButton` today). The paint rows + per-row provenance badges are
// ALREADY on the design system (`PaintRow` → `ProvenanceBadge`, partly swapped),
// so this test asserts their present side here; the exhaustive "old add button
// absent" sweep is the pre-seeded TestAC08 → ORG-1 augmentation (ITEST.md).
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/palette/paint_list_region.dart';
import 'package:paint_color_assistant/widgets/paint_row.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-8 — Palette paints, provenance and add action (owner ORG-1)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-8',
      'TestAC08_Palette: each paint row renders through the design-system '
      'row+badge and the add-from-dataset action is a pill, not an ad-hoc button',
      (tester) async {
    // GIVEN the Palette screen open on the fixture palette — the paint list
    // renders its three paints and the add-from-dataset action.
    await pumpScreen(tester, VisualScreen.palette);
    expect(find.byKey(PaintListRegion.regionKey), findsOneWidget,
        reason: 'Given: the paint list region renders');
    const paintIds = <String>['pw6', 'py43', 'pbk9'];
    for (final id in paintIds) {
      expect(find.byKey(PaintRow.rowKeyFor(id)), findsOneWidget,
          reason: 'Given: the $id paint row renders');
    }
    expect(find.byKey(PaintListRegion.addPaintKey), findsOneWidget,
        reason: 'Given: the add-from-dataset action renders');

    // WHEN the paint list renders.

    // THEN each paint row carries its per-row ProvenanceBadge glyph-and-border
    // (rejects a row with no provenance badge).
    for (final id in paintIds) {
      expect(
        find.descendant(
          of: find.byKey(PaintRow.rowKeyFor(id)),
          matching: find.byType(ProvenanceBadge),
        ),
        findsOneWidget,
        reason: 'the $id paint row carries a ProvenanceBadge',
      );
    }

    // THEN the add-from-dataset action renders as a design-system pill, not the
    // ad-hoc TextButton it is today (rejects the add action left ad-hoc).
    expectPill(tester, PaintListRegion.addPaintKey,
        reason: 'the add-from-dataset action renders as a PillButton');
  });
}
