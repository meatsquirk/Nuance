// Acceptance tests for the bs-20 Readout re-composition (ITEST-2).
//
// One *pending* integration test per readout AC — AC-1, AC-2, AC-3, AC-4, AC-5
// and AC-9 — driving the *real* assembled app through the `harness.dart`
// vocabulary (ITEST-1). Each test is written against the behaviour that un-pends
// it (its owning phase is the one named in `pendingACs`): in the default run its
// body is skipped; under `--dart-define=BS20_RUN_PENDING=true` it executes and
// must fail on a Then assertion (or a Given precondition naming its owning
// phase), never panic — the red baseline.
//
// The settings / Speak ACs (AC-6/7/8) live in the sibling `settings_test.dart`
// (ITEST-3), so the two AC-test phases stay parallel-friendly on disjoint files.
//
// Fixtures (`warmTerracotta` / `value2Sample` / `anySample`) and the keyed
// finders come verbatim from the ITEST-1 harness; this file re-asserts each
// fixture's derived Given through the public readout before its Then (G1), so no
// "value 2" / "Lightness 58" Given is assumed.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // ITEST-2 — readout re-composition (AC-1, AC-2, AC-3, AC-4, AC-5, AC-9)
  // ===========================================================================

  // AC-1 (TestAC01_HeroCard, owner READOUT-4) — the lightness value is shown in
  // a prominent *bordered card* as the *largest reading* on the screen. Rejects
  // a plain-row value with no card, and a card whose value is not the largest
  // reading.
  acTestWidgets('AC-1', 'Lightness is shown in a bordered hero card as the largest reading',
      (tester) async {
    // Given: reading "Warm Terracotta" with Lightness 58.
    //  - the sample is the one shown: its name renders on the readout;
    //  - its input Lightness is 58 (the value the Then is about).
    final harness = await givenReadoutOf(tester, warmTerracotta);
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'AC-1 Given: the terracotta sample must be the one shown');
    expect(warmTerracotta.coordinates.lightness, 58,
        reason: 'AC-1 Given: the fixture under test has Lightness 58');

    // When: the readout for the sample is shown (givenReadoutOf settled it).

    // Then: the Lightness 58 reading sits inside the keyed hero card, and that
    // card is *bordered* (not the plain row the shell renders today).
    expect(harness.heroCard, findsOneWidget,
        reason: 'AC-1: the value-hero card anchor must exist');
    final lightness58 = find.descendant(of: harness.heroCard, matching: find.text('58'));
    expect(lightness58, findsOneWidget,
        reason: 'AC-1: Lightness 58 must render inside the hero card');
    expect(
      find.ancestor(of: lightness58, matching: find.byWidgetPredicate(_isBordered)),
      findsWidgets,
      reason: 'AC-1: Lightness 58 must be shown in a bordered card, not a plain '
          'row (READOUT-4)',
    );

    // ...and it is the largest reading on the screen — strictly larger than
    // every other reading in the readout body. The name header (its prominence
    // is AC-3's concern, not a reading) and the action-bar control labels are
    // excluded; auto-covers the colour-space readings READOUT-3 renders.
    final scaffold =
        find.ancestor(of: harness.valueRegion, matching: find.byType(Scaffold)).first;
    final lightnessParas = _parasUnder(tester, harness.valueRegion)
        .where((p) => p.text.toPlainText().contains('58'))
        .toSet();
    expect(lightnessParas, isNotEmpty,
        reason: 'AC-1: Lightness 58 must render in the value region');
    final excluded = <RenderParagraph>{
      ..._parasUnderKey(tester, NameHeader.headerKey),
      ..._parasUnderKey(tester, ActionsBar.barKey),
      ...lightnessParas,
    };
    final others = _parasUnder(tester, scaffold)
        .where((p) => !excluded.contains(p))
        .toList();
    final lightnessSize = lightnessParas.map(_fontSize).reduce(math.max);
    for (final p in others) {
      expect(lightnessSize, greaterThan(_fontSize(p)),
          reason: 'AC-1: Lightness 58 must be the largest reading — larger than '
              '"${p.text.toPlainText()}" (READOUT-4)');
    }
  });

  // AC-2 (TestAC02_ValueScale, owner READOUT-5) — the Munsell value reads on a
  // labelled 0–10 scale with the sample's step marked. Rejects a bare "Munsell
  // value 2" text (no scale), and a scale with no marked step / the wrong step
  // marked.
  acTestWidgets('AC-2', 'The Munsell value reads on a 0–10 scale with value 2 marked',
      (tester) async {
    // Given: a sample with Munsell value 2 — re-asserted through the public
    // readout (the value region already shows "Munsell value N" in the shell),
    // so the "value 2" Given is checked, not assumed.
    await givenReadoutOf(tester, value2Sample);
    expect(find.text('Munsell value 2'), findsOneWidget,
        reason: 'AC-2 Given: the fixture must read Munsell value 2 on the readout');
    final harness = await givenReadoutOf(tester, value2Sample);

    // When: the readout for the sample is shown.

    // Then: a scale running 0..10 is shown — all eleven steps labelled.
    expect(harness.valueScale, findsOneWidget,
        reason: 'AC-2: the value-scale anchor must exist');
    for (var n = 0; n <= 10; n++) {
      expect(
        find.descendant(of: harness.valueScale, matching: find.text('$n')),
        findsWidgets,
        reason: 'AC-2: the scale must show the labelled step $n (0–10 scale) '
            '(READOUT-5)',
      );
    }

    // ...and the sample's position at value 2 is marked — exactly one step is
    // marked (a selected accessibility step), and it is the value-2 step.
    final marked = find.descendant(
      of: harness.valueScale,
      matching: find.byWidgetPredicate(
          (w) => w is Semantics && (w.properties.selected ?? false)),
    );
    expect(marked, findsOneWidget,
        reason: 'AC-2: exactly one step — the sample’s value — must be marked on '
            'the scale (READOUT-5)');
    final markedLabel = tester.widget<Semantics>(marked).properties.label ?? '';
    final markedText = _plainTextUnder(tester, marked);
    expect('$markedLabel $markedText', contains('2'),
        reason: 'AC-2: the marked step must be the sample’s value 2 (READOUT-5)');
  });

  // AC-3 (TestAC03_EqualSwatches, owner READOUT-4) — the displayed-colour swatch
  // is the same size as the grayscale value swatch. Rejects swatches of
  // different size (the 48×48 grayscale vs 16×16 chip the shell renders today).
  acTestWidgets('AC-3', 'The displayed-colour swatch is as large as the grayscale swatch',
      (tester) async {
    // Given: the painter is reading a sample.
    final harness = await givenReadoutOf(tester, anySample);
    expect(find.text('Any Sample'), findsOneWidget,
        reason: 'AC-3 Given: a sample must be shown on the readout');

    // When: the readout for the sample is shown.

    // Then: the two swatches render at equal width and height. The displayed
    // colour's swatch is the chip's painted square; the grayscale swatch is its
    // keyed square — both measured by their rendered box.
    expect(harness.grayscaleSwatch, findsOneWidget,
        reason: 'AC-3: the grayscale value swatch must render');
    final colourSwatch =
        find.descendant(of: harness.displayedColorChip, matching: find.byType(DecoratedBox));
    expect(colourSwatch, findsOneWidget,
        reason: 'AC-3: the displayed-colour swatch must render (one swatch, '
            'simulation off)');
    final graySize = tester.getSize(harness.grayscaleSwatch);
    final colourSize = tester.getSize(colourSwatch);
    expect(colourSize, equals(graySize),
        reason: 'AC-3: the displayed-colour swatch ($colourSize) must be the same '
            'size as the grayscale swatch ($graySize) (READOUT-4)');
  });

  // AC-4 (TestAC04_AllSpaces, owner READOUT-3) — every colour space is shown
  // together on the readout, with no selector. Rejects only one space shown, and
  // a selector left present. The values are asserted *within the all-spaces
  // region*, so a lingering selector's single space can't satisfy them.
  acTestWidgets('AC-4', 'Every colour space is shown together, with no selector',
      (tester) async {
    // Given: the painter is reading "Warm Terracotta".
    final harness = await givenReadoutOf(tester, warmTerracotta);
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'AC-4 Given: the terracotta sample must be the one shown');

    // When: the readout for the sample is shown.

    // Then: CIELCh, Munsell, sRGB (triplet + hex) and CIELAB are all present at
    // once inside the all-spaces region. Collision-safe signatures (°, 10R, a
    // hex, an r,g,b triplet, the CIELAB a*/b* of terracotta) — mutually
    // distinct, so "all four together" is unambiguous.
    final shown = _plainTextUnder(tester, harness.allSpaces);
    expect(shown, matches(RegExp(r'°|deg')),
        reason: 'AC-4: the CIELCh values must be shown (READOUT-3)');
    expect(shown, contains('10R'),
        reason: 'AC-4: the Munsell notation must be shown (READOUT-3)');
    expect(shown, matches(RegExp(r'#[0-9a-fA-F]{6}')),
        reason: 'AC-4: the sRGB hex must be shown (READOUT-3)');
    expect(shown, matches(RegExp(r'\b\d{1,3},\s*\d{1,3},\s*\d{1,3}\b')),
        reason: 'AC-4: the sRGB triplet must be shown (READOUT-3)');
    expect(shown, contains('25.27'),
        reason: 'AC-4: the CIELAB a* coordinate must be shown (READOUT-3)');
    expect(shown, contains('22.75'),
        reason: 'AC-4: the CIELAB b* coordinate must be shown (READOUT-3)');

    // ...and no colour-space selector control is present.
    expect(find.byType(SpaceSelector), findsNothing,
        reason: 'AC-4: no colour-space selector may be present (READOUT-3)');
  });

  // AC-5 (TestAC05_Definitions, owner READOUT-6) — opening a colour space's name
  // reveals a fuller plain-language definition with an example. Scenario Outline:
  // every one of the four spaces. Rejects a name that is not openable, a tap that
  // shows nothing, and a definition with no example. The "all spaces shown"
  // Given is a READOUT-3 precondition (the openable name label), checked before
  // the tap so the pending baseline fails cleanly (no zero-size tap panic).
  acTestWidgets('AC-5', 'Opening a colour space name reveals its definition and an example',
      (tester) async {
    for (final space in ReadoutSpace.values) {
      final label = SpaceSelector.labelFor(space);
      // Given: the painter is reading a sample with all colour spaces shown — the
      // space's name is shown as an openable label (READOUT-3 renders it).
      final harness = await givenReadoutOf(tester, warmTerracotta);
      expect(
        find.descendant(of: harness.spaceName(space), matching: find.textContaining(label)),
        findsOneWidget,
        reason: 'AC-5 Given: the $label space name must be shown as an openable '
            'label (READOUT-3/READOUT-6)',
      );
      // The definition is hidden until the name is opened (before/after pair).
      expect(harness.spaceDefinition(space), findsNothing,
          reason: 'AC-5: the $label definition must be hidden until its name is '
              'opened (READOUT-6)');

      // When: the painter opens the <space> name.
      await tester.tap(harness.spaceName(space));
      await tester.pumpAndSettle();

      // Then: a plain-language definition of <space> is shown, with an example.
      expect(harness.spaceDefinition(space), findsOneWidget,
          reason: 'AC-5: opening the $label name must reveal its definition '
              '(READOUT-6)');
      final definition = _plainTextUnder(tester, harness.spaceDefinition(space));
      expect(definition.trim(), isNotEmpty,
          reason: 'AC-5: the $label definition text must be non-empty (READOUT-6)');
      expect(definition.toLowerCase(), matches(RegExp(r'e\.g\.|example|for instance')),
          reason: 'AC-5: an example must accompany the $label definition '
              '(READOUT-6)');
    }
  });

  // AC-9 (TestAC09_ColorSpelling, owner READOUT-8) — the readout copy uses
  // "Color", and the word "Colour" does not appear. Rejects any British "Colour"
  // left in the readout copy (the shell renders "Displayed colour" today).
  acTestWidgets('AC-9', 'The readout copy uses "Color", not "Colour"', (tester) async {
    // Given: the painter is reading a sample.
    final harness = await givenReadoutOf(tester, warmTerracotta);
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'AC-9 Given: the terracotta sample must be the one shown');

    // When: the readout for the sample is shown.

    // Then: the readout copy (every rendered line of the readout screen) uses the
    // American "Color" and contains no "Colour"/"colour".
    final scaffold =
        find.ancestor(of: harness.valueRegion, matching: find.byType(Scaffold)).first;
    final copy = _plainTextUnder(tester, scaffold);
    expect(copy.toLowerCase(), isNot(contains('colou')),
        reason: 'AC-9: the word "Colour" must not appear in the readout copy '
            '(READOUT-8)');
    expect(copy, matches(RegExp(r'\bcolor\b', caseSensitive: false)),
        reason: 'AC-9: the readout copy must spell it "Color" (READOUT-8)');
  });
}

// ---------------------------------------------------------------------------
// Rendering helpers (ported from bs-01's readout acceptance suite)
// ---------------------------------------------------------------------------

/// All [RenderParagraph]s rendered under the widget keyed [key].
Set<RenderParagraph> _parasUnderKey(WidgetTester tester, Key key) =>
    _parasUnder(tester, find.byKey(key));

/// All [RenderParagraph]s rendered under [scope].
Set<RenderParagraph> _parasUnder(WidgetTester tester, Finder scope) => tester
    .renderObjectList<RenderParagraph>(
        find.descendant(of: scope, matching: find.byType(RichText)))
    .toSet();

/// The joined plain text of every paragraph rendered under [scope] (empty string
/// if none).
String _plainTextUnder(WidgetTester tester, Finder scope) =>
    _parasUnder(tester, scope).map((p) => p.text.toPlainText()).join(' ');

/// The effective font size of [p] (Material body default when unset).
double _fontSize(RenderParagraph p) => p.text.style?.fontSize ?? 14.0;

/// Whether [w] renders a visible border — a bordered card (AC-1): a [Container]
/// or [DecoratedBox] with a [BoxDecoration.border] or an outlined
/// [ShapeDecoration] side, or a Material [Card].
bool _isBordered(Widget w) {
  if (w is Card) return true;
  Decoration? decoration;
  if (w is Container) decoration = w.decoration;
  if (w is DecoratedBox) decoration = w.decoration;
  if (decoration is BoxDecoration) return decoration.border != null;
  if (decoration is ShapeDecoration) {
    final shape = decoration.shape;
    return shape is OutlinedBorder &&
        shape.side.width > 0 &&
        shape.side.style != BorderStyle.none;
  }
  return false;
}
