import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  testWidgets('renders the tier label as text', (tester) async {
    await _pump(
      tester,
      const ProvenanceBadge(provenance: Provenance(ProvenanceTier.measured)),
    );
    expect(find.text('Measured'), findsOneWidget);
  });

  testWidgets('renders the note beneath the label when present', (tester) async {
    await _pump(
      tester,
      const ProvenanceBadge(
        provenance: Provenance(
          ProvenanceTier.estimated,
          note: 'Seeded by a model. Treat as a starting point.',
        ),
      ),
    );
    expect(find.text('Estimated'), findsOneWidget);
    expect(
      find.text('Seeded by a model. Treat as a starting point.'),
      findsOneWidget,
    );
  });

  testWidgets('shows no note when the provenance has none', (tester) async {
    await _pump(
      tester,
      const ProvenanceBadge(provenance: Provenance(ProvenanceTier.measured)),
    );
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('announces label only when there is no note', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const ProvenanceBadge(provenance: Provenance(ProvenanceTier.measured)),
    );
    expect(tester.getSemantics(find.byType(ProvenanceBadge)).label, 'Measured');
    handle.dispose();
  });

  testWidgets('folds the note into the semantics announcement', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const ProvenanceBadge(
        provenance: Provenance(ProvenanceTier.estimated, note: 'Not verified.'),
      ),
    );
    expect(
      tester.getSemantics(find.byType(ProvenanceBadge)).label,
      'Estimated. Not verified.',
    );
    handle.dispose();
  });
}
