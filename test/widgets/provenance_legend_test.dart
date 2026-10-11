import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/widgets/provenance_legend.dart';

void main() {
  group('ProvenanceLegend', () {
    testWidgets('renders all four confidence tiers by their exact spec strings',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ProvenanceLegend())),
      );

      // One keyed entry per tier, each by its exact AC-3 wording.
      expect(
        tester
            .widget<Text>(
                find.byKey(ProvenanceLegend.entryKeyFor(ProvenanceTier.measured)))
            .data,
        'Measured',
      );
      expect(
        tester
            .widget<Text>(find
                .byKey(ProvenanceLegend.entryKeyFor(ProvenanceTier.calculated)))
            .data,
        'Calculated',
      );
      expect(
        tester
            .widget<Text>(find
                .byKey(ProvenanceLegend.entryKeyFor(ProvenanceTier.estimated)))
            .data,
        'Estimated — not yet verified',
      );
      expect(
        tester
            .widget<Text>(find
                .byKey(ProvenanceLegend.entryKeyFor(ProvenanceTier.confirmed)))
            .data,
        'Confirmed — you measured this',
      );

      // Exactly the four tiers, no more.
      expect(find.byType(Text), findsNWidgets(ProvenanceTier.values.length));
    });

    test('legendText gives each tier its exact spec string', () {
      expect(ProvenanceLegend.legendText(ProvenanceTier.measured), 'Measured');
      expect(
          ProvenanceLegend.legendText(ProvenanceTier.calculated), 'Calculated');
      expect(ProvenanceLegend.legendText(ProvenanceTier.estimated),
          'Estimated — not yet verified');
      expect(ProvenanceLegend.legendText(ProvenanceTier.confirmed),
          'Confirmed — you measured this');
    });
  });
}
