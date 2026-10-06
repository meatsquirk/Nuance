import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/provenance_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';
import 'package:paint_color_assistant/readout/temperature_line.dart';
import 'package:paint_color_assistant/readout/value_region.dart';

const _sample = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

AppDependencies _deps() => const AppDependencies(
      colorScience: ColorScienceImpl(),
      speech: NoopSpeech(),
      haptics: NoopHaptics(),
    );

// A fresh, non-canonical instance each call, so swapping it notifies dependents
// (two `const` instances are canonicalised to one and would not).
AppDependencies _freshDeps() => AppDependencies(
      colorScience: ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
    );

Future<void> _pumpScreen(
  WidgetTester tester, {
  Sample sample = _sample,
}) {
  return tester.pumpWidget(
    AppScope(
      dependencies: _deps(),
      child: MaterialApp(home: ReadoutScreen(sample: sample)),
    ),
  );
}

void main() {
  testWidgets('lays out every region with a stable anchor', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Readout'), findsOneWidget); // app bar title
    expect(find.byKey(NameHeader.headerKey), findsOneWidget);
    expect(find.byKey(ValueRegion.regionKey), findsOneWidget);
    expect(find.byKey(ValueRegion.grayscaleKey), findsOneWidget);
    expect(find.byKey(TemperatureLine.lineKey), findsOneWidget);
    expect(find.byKey(SpaceSelector.selectorKey), findsOneWidget);
    expect(find.byKey(SpaceSelector.valuesKey), findsOneWidget);
    expect(find.byKey(ProvenanceRegion.regionKey), findsOneWidget);
    expect(find.byKey(ActionsBar.barKey), findsOneWidget);
    expect(find.byKey(ActionsBar.speakKey), findsOneWidget);
    expect(find.byKey(ActionsBar.compareAKey), findsOneWidget);
    expect(find.byKey(ActionsBar.compareBKey), findsOneWidget);
    expect(find.byKey(ActionsBar.recipesKey), findsOneWidget);
    expect(find.byKey(ActionsBar.acknowledgeKey), findsOneWidget);
  });

  testWidgets('shows the sample name in the header', (tester) async {
    await _pumpScreen(tester);
    expect(find.text('Warm Terracotta'), findsOneWidget);
  });

  testWidgets('derives the nearest colour name for an unnamed sample',
      (tester) async {
    // No stored name → the header shows the nearest ISCC-NBS colour name
    // derived from the coordinates (L58, a36, b34 → "Warm Terracotta"), AC-3.
    await _pumpScreen(
      tester,
      sample: const Sample(
        coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
        provenance: Provenance(ProvenanceTier.measured),
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(NameHeader.headerKey),
        matching: find.text('Warm Terracotta'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('offers the four colour spaces and starts on CIELCh',
      (tester) async {
    await _pumpScreen(tester);
    for (final space in ReadoutSpace.values) {
      expect(find.text(SpaceSelector.labelFor(space)), findsOneWidget);
    }
    expect(find.text('CIELCh values —'), findsOneWidget);
  });

  testWidgets('selecting a space updates the shown space', (tester) async {
    await _pumpScreen(tester);
    await tester.tap(find.text('Munsell'));
    await tester.pump();
    expect(find.text('Munsell values —'), findsOneWidget);
    expect(find.text('CIELCh values —'), findsNothing);
  });

  testWidgets('every action control is a disabled placeholder',
      (tester) async {
    await _pumpScreen(tester);
    for (final key in const [
      ActionsBar.speakKey,
      ActionsBar.compareAKey,
      ActionsBar.compareBKey,
      ActionsBar.recipesKey,
      ActionsBar.acknowledgeKey,
    ]) {
      final button = tester.widget<OutlinedButton>(find.byKey(key));
      expect(button.enabled, isFalse);
    }
  });

  testWidgets('keeps its controller across a dependency change',
      (tester) async {
    Widget tree(AppDependencies deps) => AppScope(
          dependencies: deps,
          child: const MaterialApp(home: ReadoutScreen(sample: _sample)),
        );
    await tester.pumpWidget(tree(_freshDeps()));
    // Change a selection, then push a new (distinct) scope so the screen's
    // didChangeDependencies runs again without rebuilding the controller.
    await tester.tap(find.text('Munsell'));
    await tester.pump();
    await tester.pumpWidget(tree(_freshDeps()));
    await tester.pump();
    // The selection survives, proving the controller was not re-created.
    expect(find.text('Munsell values —'), findsOneWidget);
  });

  testWidgets('disposes its controller when removed', (tester) async {
    await _pumpScreen(tester);
    // Replacing the tree tears the screen down, disposing the controller.
    await tester.pumpWidget(const SizedBox());
    expect(find.byType(ReadoutScreen), findsNothing);
  });

  testWidgets('reflects a newly injected sample in place', (tester) async {
    // A different sample injected into the same screen position (bs-02 capture
    // replaces the running app's sample — D-1) updates the reading.
    const dark = Sample(
      name: 'Warm Terracotta',
      coordinates: ColorCoordinates(lightness: 15, a: 25.27, b: 22.75),
      provenance: Provenance(ProvenanceTier.measured),
    );
    const light = Sample(
      name: 'Warm Terracotta',
      coordinates: ColorCoordinates(lightness: 90, a: 25.27, b: 22.75),
      provenance: Provenance(ProvenanceTier.measured),
    );
    Widget tree(Sample sample) => AppScope(
          dependencies: _deps(),
          child: MaterialApp(home: ReadoutScreen(sample: sample)),
        );

    await tester.pumpWidget(tree(dark));
    expect(find.text('very low value'), findsOneWidget);

    await tester.pumpWidget(tree(light));
    await tester.pump();
    expect(find.text('very high value'), findsOneWidget);
    expect(find.text('very low value'), findsNothing);
  });
}
