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
import 'package:paint_color_assistant/readout/all_spaces_region.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/provenance_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/readout/space_definition.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';
import 'package:paint_color_assistant/readout/temperature_line.dart';
import 'package:paint_color_assistant/readout/value_region.dart';
import 'package:paint_color_assistant/readout/value_scale.dart';

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
  // The readout now shows every colour space at once (READOUT-3), so its
  // scrollable body is taller than the default 600px test surface — give the
  // tests a tall viewport so every region (down to the actions bar) is laid out.
  _useTallView(tester);
  return tester.pumpWidget(
    AppScope(
      dependencies: _deps(),
      child: MaterialApp(home: ReadoutScreen(sample: sample)),
    ),
  );
}

/// Sizes the test surface tall enough to lay out the whole readout body, so a
/// region near the bottom (the actions bar) is rendered without scrolling.
void _useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The joined text currently rendered in the all-spaces region (every colour
/// space is shown together — AC-4).
String _spaceValues(WidgetTester tester) => tester
    .widgetList<Text>(find.descendant(
        of: find.byKey(AllSpacesRegion.regionKey), matching: find.byType(Text)))
    .map((t) => t.data ?? '')
    .join(' ');

void main() {
  testWidgets('lays out every region with a stable anchor', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Readout'), findsOneWidget); // app bar title
    expect(find.byKey(NameHeader.headerKey), findsOneWidget);
    expect(find.byKey(ValueRegion.regionKey), findsOneWidget);
    expect(find.byKey(ValueRegion.heroCardKey), findsOneWidget);
    expect(find.byKey(ValueRegion.grayscaleKey), findsOneWidget);
    // READOUT-2 shells wired in behind the existing regions.
    expect(find.byKey(ValueScale.scaleKey), findsOneWidget);
    expect(find.byKey(AllSpacesRegion.regionKey), findsOneWidget);
    for (final space in ReadoutSpace.values) {
      expect(find.byKey(SpaceDefinition.nameKey(space)), findsOneWidget);
    }
    expect(find.byKey(TemperatureLine.lineKey), findsOneWidget);
    // The one-at-a-time selector is gone (READOUT-3): every space shows at once.
    expect(find.byType(SpaceSelector), findsNothing);
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

  testWidgets('shows every colour space together, with no selector (AC-4)',
      (tester) async {
    await _pumpScreen(tester);
    // Every space is labelled...
    for (final space in ReadoutSpace.values) {
      expect(find.text(SpaceSelector.labelFor(space)), findsOneWidget);
    }
    // ...and all four spaces' values are shown at once — CIELCh (degree-marked),
    // Munsell (10R), the sRGB hex and the CIELAB a*/b* — not one at a time.
    final shown = _spaceValues(tester);
    expect(shown, contains('°'), reason: 'CIELCh is shown');
    expect(shown, contains('10R'), reason: 'Munsell is shown');
    expect(shown, matches(RegExp(r'#[0-9a-fA-F]{6}')), reason: 'sRGB is shown');
    expect(shown, contains('34'), reason: 'the CIELAB b* reading is shown');
    // No one-at-a-time selector remains.
    expect(find.byType(SpaceSelector), findsNothing);
  });

  testWidgets('enables the navigation and speak actions; acknowledge only for '
      'a just-captured reading (A11Y-2)', (tester) async {
    await _pumpScreen(tester); // _sample is not just-captured
    // READOUT-6 wired the handoffs and A11Y-2 wired speak: all are live.
    for (final key in const [
      ActionsBar.compareAKey,
      ActionsBar.compareBKey,
      ActionsBar.recipesKey,
      ActionsBar.speakKey,
    ]) {
      final button = tester.widget<OutlinedButton>(find.byKey(key));
      expect(button.enabled, isTrue,
          reason: 'the action $key must be enabled');
    }
    // Nothing was just captured: no marker, and Acknowledge is disabled.
    expect(find.byKey(ActionsBar.justCapturedKey), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byKey(ActionsBar.acknowledgeKey)).enabled,
      isFalse,
      reason: 'Acknowledge is disabled when nothing was just captured',
    );
  });

  testWidgets('a just-captured reading shows the marker and enables Acknowledge '
      '(AC-12)', (tester) async {
    await _pumpScreen(
      tester,
      sample: const Sample(
        name: 'Deep Olive Green',
        coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
        provenance: Provenance(ProvenanceTier.measured),
        justCaptured: true,
      ),
    );
    expect(find.byKey(ActionsBar.justCapturedKey), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byKey(ActionsBar.acknowledgeKey)).enabled,
      isTrue,
    );

    // Acknowledging clears the marker in place. (The AC-15 swatch caption added
    // to the value region makes the scrollable readout body taller, so the
    // Acknowledge control — the last item in the ListView — can sit below the
    // 800px test viewport; scroll it into view before tapping.)
    await tester.ensureVisible(find.byKey(ActionsBar.acknowledgeKey));
    await tester.pump();
    await tester.tap(find.byKey(ActionsBar.acknowledgeKey));
    await tester.pump();
    expect(find.byKey(ActionsBar.justCapturedKey), findsNothing);
  });

  testWidgets('keeps its controller across a dependency change',
      (tester) async {
    const fresh = Sample(
      name: 'Deep Olive Green',
      coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
      provenance: Provenance(ProvenanceTier.measured),
      justCaptured: true,
    );
    _useTallView(tester);
    Widget tree(AppDependencies deps) => AppScope(
          dependencies: deps,
          child: const MaterialApp(home: ReadoutScreen(sample: fresh)),
        );
    await tester.pumpWidget(tree(_freshDeps()));
    expect(find.byKey(ActionsBar.justCapturedKey), findsOneWidget);

    // Acknowledge the capture — mutable controller state (the marker clears).
    await tester.ensureVisible(find.byKey(ActionsBar.acknowledgeKey));
    await tester.pump();
    await tester.tap(find.byKey(ActionsBar.acknowledgeKey));
    await tester.pump();
    expect(find.byKey(ActionsBar.justCapturedKey), findsNothing);

    // Push a new (distinct) scope so didChangeDependencies runs again. The
    // acknowledged state survives, proving the controller was not re-created
    // from the still-just-captured widget sample.
    await tester.pumpWidget(tree(_freshDeps()));
    await tester.pump();
    expect(find.byKey(ActionsBar.justCapturedKey), findsNothing);
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
