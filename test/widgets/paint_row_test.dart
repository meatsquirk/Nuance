import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';
import 'package:paint_color_assistant/widgets/paint_row.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';

Future<void> _pump(WidgetTester tester, Paint paint, {Color? swatchColor}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: PaintRow(paint: paint, swatchColor: swatchColor)),
    ),
  );
}

void main() {
  group('PaintRow', () {
    const fullOil = Paint(
      id: 'pw6',
      name: 'Titanium White',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PW6',
      masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
    );

    testWidgets('renders the full identity, dedicated medium label and badge',
        (tester) async {
      await _pump(tester, fullOil);

      // Name on its own line.
      expect(find.text('Titanium White'), findsOneWidget);
      // Identity line: brand · line · pigment index, in that order.
      expect(find.text("Winsor & Newton · Artists' Oil · PW6"), findsOneWidget);
      // Medium at its own grain — a dedicated keyed widget reading exactly "Oil"
      // (not the "Artists' Oil" line text).
      final medium =
          tester.widget<Text>(find.byKey(PaintRow.mediumKeyFor('pw6')));
      expect(medium.data, 'Oil');
      // Provenance badge states the tier (defaults to measured).
      final badge =
          tester.widget<ProvenanceBadge>(find.byKey(PaintRow.badgeKeyFor('pw6')));
      expect(badge.provenance.tier, ProvenanceTier.measured);
      // The whole row carries its stable anchor key.
      expect(find.byKey(PaintRow.rowKeyFor('pw6')), findsOneWidget);
    });

    testWidgets(
        'an acrylic paint with no brand/line/pigment shows no identity line and '
        'the "Acrylic" medium + its own tier', (tester) async {
      const bare = Paint(
        id: 'pg7',
        name: 'Phthalo Green',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 40, a: -40, b: 10),
        provenance: ProvenanceTier.estimated,
      );
      await _pump(tester, bare);

      expect(find.text('Phthalo Green'), findsOneWidget);
      // No identity line is rendered when brand/line/pigment are all absent.
      expect(
        find.descendant(
          of: find.byKey(PaintRow.rowKeyFor('pg7')),
          matching: find.byType(Text),
        ),
        findsNWidgets(3), // name, medium, and the badge's single tier label
      );
      final medium =
          tester.widget<Text>(find.byKey(PaintRow.mediumKeyFor('pg7')));
      expect(medium.data, 'Acrylic');
      final badge =
          tester.widget<ProvenanceBadge>(find.byKey(PaintRow.badgeKeyFor('pg7')));
      expect(badge.provenance.tier, ProvenanceTier.estimated);
    });

    testWidgets(
        'given a swatchColor, the name renders through a ColorChip carrying '
        'the paint name as its label (bs-10 AC-9)', (tester) async {
      await _pump(tester, fullOil, swatchColor: const Color(0xFF0A8043));

      // The name is routed through a keyed ColorChip swatch, so daltonization
      // remaps it at the shared chokepoint; its label is the paint name.
      final chip =
          tester.widget<ColorChip>(find.byKey(PaintRow.swatchKeyFor('pw6')));
      expect(chip.label, 'Titanium White');
      expect(chip.color, const Color(0xFF0A8043));
      // The name is shown exactly once (through the chip, not also as a plain
      // header Text).
      expect(find.text('Titanium White'), findsOneWidget);
    });

    test('mediumLabel maps each medium to its painter-facing word', () {
      expect(PaintRow.mediumLabel(PaintMedium.oil), 'Oil');
      expect(PaintRow.mediumLabel(PaintMedium.acrylic), 'Acrylic');
    });
  });
}
