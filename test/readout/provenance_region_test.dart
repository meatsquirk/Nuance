import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/provenance_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';

const _coords = ColorCoordinates(lightness: 58, a: 25.27, b: 22.75);

Sample _sampleWith(Provenance provenance) =>
    Sample(name: 'A Reading', coordinates: _coords, provenance: provenance);

ReadoutController _controllerFor(Sample sample) => ReadoutController(
      sample: sample,
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      router: const AppRouter(),
    );

Future<ReadoutController> _pumpRegion(
  WidgetTester tester,
  Provenance provenance,
) async {
  final controller = _controllerFor(_sampleWith(provenance));
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ProvenanceRegion(controller: controller)),
    ),
  );
  return controller;
}

void main() {
  group('label and note mapping', () {
    test('a measured reading reads "Measured" with no note (AC-6)', () {
      const provenance = Provenance(ProvenanceTier.measured);
      expect(ProvenanceRegion.labelFor(provenance), 'Measured');
      expect(ProvenanceRegion.noteFor(provenance), isNull);
    });

    test('an estimated reading reads the unverified label and caveat (AC-7)',
        () {
      const provenance = Provenance(ProvenanceTier.estimated);
      expect(
          ProvenanceRegion.labelFor(provenance), 'Estimated — not yet verified');
      expect(ProvenanceRegion.noteFor(provenance),
          'Seeded by a model. Treat as a starting point.');
    });

    test('a calculated reading reads its bare tier word with no note', () {
      const provenance = Provenance(ProvenanceTier.calculated);
      expect(ProvenanceRegion.labelFor(provenance), 'Calculated');
      expect(ProvenanceRegion.noteFor(provenance), isNull);
    });

    test('a confirmed reading reads its bare tier word with no note', () {
      const provenance = Provenance(ProvenanceTier.confirmed);
      expect(ProvenanceRegion.labelFor(provenance), 'Confirmed');
      expect(ProvenanceRegion.noteFor(provenance), isNull);
    });
  });

  testWidgets('renders "Measured" and no caveat note for a measured reading '
      '(AC-6)', (tester) async {
    await _pumpRegion(tester, const Provenance(ProvenanceTier.measured));

    expect(
      find.descendant(
        of: find.byKey(ProvenanceRegion.regionKey),
        matching: find.text('Measured'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('not yet verified'), findsNothing);
    expect(find.textContaining('Seeded by a model'), findsNothing);
  });

  testWidgets('renders the estimated label and the seeded-value note (AC-7)',
      (tester) async {
    await _pumpRegion(tester, const Provenance(ProvenanceTier.estimated));

    expect(
      find.descendant(
        of: find.byKey(ProvenanceRegion.regionKey),
        matching: find.text('Estimated — not yet verified'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Seeded by a model. Treat as a starting point.'),
      findsOneWidget,
    );
  });

  testWidgets('announces the tier alone when there is no note (AC-6)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpRegion(tester, const Provenance(ProvenanceTier.measured));

    expect(
      tester.getSemantics(find.byKey(ProvenanceRegion.regionKey)).label,
      'Measured',
    );
    handle.dispose();
  });

  testWidgets('folds the caveat into the semantics announcement (AC-7)',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pumpRegion(tester, const Provenance(ProvenanceTier.estimated));

    expect(
      tester.getSemantics(find.byKey(ProvenanceRegion.regionKey)).label,
      'Estimated — not yet verified. '
          'Seeded by a model. Treat as a starting point.',
    );
    handle.dispose();
  });

  testWidgets('tracks the controller sample provenance', (tester) async {
    // The region reads the tier live from the controller's sample, so a measured
    // reading shows no caveat even though the fixture type is shared with AC-7.
    await _pumpRegion(tester, const Provenance(ProvenanceTier.measured));
    expect(find.text('Measured'), findsOneWidget);
    expect(find.text('Estimated — not yet verified'), findsNothing);
  });
}
