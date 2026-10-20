// bs-18 acceptance suite — Palette-screen AC (ITEST-3): AC-8 the paints,
// provenance and add action as design-system components (owner ORG-1).
//
// Pumps the real Palette screen (`pumpScreen(palette)`, wired with the fixture's
// three mixed-provenance paints) and reads the design-system treatment off the
// pumped tree. Un-pended by ORG-1, which swapped the add-from-dataset action from
// the ad-hoc `TextButton` to a `PillButton`. The paint rows + per-row provenance
// badges were ALREADY on the design system (`PaintRow` → `ProvenanceBadge`, partly
// swapped), so this test asserts their present side here; the "old add button
// absent" sweep — the pre-seeded TestAC08 → ORG-1 augmentation (ITEST.md) — is
// now made below (closed by ORG-1).
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
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

    // AUGMENTATION (TestAC08 → ORG-1, pre-seeded in ITEST-3): the old ad-hoc
    // add button is *gone* — no `TextButton` labelled "Add paint" survives the
    // swap. This discriminates the pre-ORG-1 tree, where the add action was
    // exactly that `TextButton`; the E31 view selector's own
    // "My paints"/"Projects" `TextButton`s (ORG-1 leaves the selector stock)
    // carry different labels, so the sweep stays tight to the add action.
    expect(find.widgetWithText(TextButton, 'Add paint'), findsNothing,
        reason: 'the old ad-hoc add-paint TextButton is gone (ORG-1 swap)');
  });
}
