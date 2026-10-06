// Acceptance tests for the bs-01 Readout screen (ITEST-2, ITEST-3).
//
// One pending test per acceptance criterion, driving the *real* assembled app
// through the harness vocabulary. Each test is written against the behaviour
// that un-pends it (its owning phase is in `pendingACs`): in the default run the
// body is skipped; under `BS01_RUN_PENDING=1` it executes and must fail on a
// Then (or a Given precondition naming its owning phase), never panic.
//
// Split into two regions so ITEST-2 and ITEST-3 stay parallel-friendly on one
// file:
//   * ITEST-2 — readout display: AC-1..AC-7 (this region).
//   * ITEST-3 — speak / navigation / just-captured: AC-8..AC-12 (added by
//     ITEST-3 inside `main`, below the display group).
//
// Fixture identifiers (`SAMPLE_*`) come verbatim from the plan, so this file
// opts out of lowerCamelCase for the local input samples it builds too.
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/provenance_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';
import 'package:paint_color_assistant/readout/temperature_line.dart';
import 'package:paint_color_assistant/readout/value_region.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // ITEST-2 — readout display (AC-1..AC-7)
  // ===========================================================================

  // AC-1 — Lightness is the prominent value reading, with a grayscale preview
  // and the Munsell value beside it.
  acTestWidgets('AC-1', 'Lightness is the largest reading, with grayscale + Munsell value',
      (tester) async {
    // Given: reading "Warm Terracotta" with Lightness 58.
    //  - the sample is loaded: its name renders on the readout (public surface);
    //  - its input Lightness is 58 (the value the Then is about).
    final harness = await givenReadoutOf(tester, SAMPLE_TERRACOTTA);
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'AC-1 Given: the terracotta sample must be the one shown');
    expect(SAMPLE_TERRACOTTA.coordinates.lightness, 58,
        reason: 'AC-1 Given: the fixture under test has Lightness 58');

    // When: the readout is shown (givenReadoutOf settled it).

    // Then: a grayscale preview accompanies the value (present in the shell —
    // stays present), the Lightness 58 reading is shown in the value region with
    // the Munsell value 5.5 beside it, and the Lightness is the largest reading
    // on the screen (name header excluded — AC-3 owns the name's prominence).
    expect(find.byKey(ValueRegion.grayscaleKey), findsOneWidget,
        reason: 'AC-1: a grayscale preview must accompany the value');

    final valueRegion = find.byKey(ValueRegion.regionKey);
    final lightnessParas = _paragraphsUnder(tester, ValueRegion.regionKey)
        .where((p) => p.text.toPlainText().contains('58'))
        .toSet();
    expect(lightnessParas, isNotEmpty,
        reason: 'AC-1: Lightness 58 must render in the value region (READOUT-2)');
    expect(
      find.descendant(of: valueRegion, matching: find.textContaining('5.5')),
      findsWidgets,
      reason: 'AC-1: the Munsell value 5.5 must be shown beside the Lightness '
          '(COLOR-2/READOUT-2)',
    );

    // "largest reading": strictly larger than every other reading rendered in
    // the body (all RichText under the ListView except the name header and the
    // action-bar control labels). This auto-covers the colour-space readings
    // once READOUT-4 renders them, so the pre-seeded augmentation adds nothing.
    final body = find.byType(ListView);
    final excluded = <RenderParagraph>{
      ..._paragraphsUnder(tester, NameHeader.headerKey),
      ..._paragraphsUnder(tester, ActionsBar.barKey),
      ...lightnessParas,
    };
    final others = _paragraphsUnder2(tester, body)
        .where((p) => !excluded.contains(p))
        .toList();
    final lightnessSize = lightnessParas.map(_fontSize).reduce(math.max);
    for (final p in others) {
      expect(lightnessSize, greaterThan(_fontSize(p)),
          reason: 'AC-1: Lightness 58 must be larger than the reading '
              '"${p.text.toPlainText()}"');
    }

    // Opening the readout speaks nothing (guards against a side-effecting shell).
    expect(harness.speech.utterances, isEmpty);
  });

  // AC-2 — The numeric Lightness is paired with a plain-language value word, and
  // the word tracks the Lightness (controls: a dark sample and a light sample).
  acTestWidgets('AC-2', 'A plain-language value word accompanies the Lightness number',
      (tester) async {
    // Given: a sample with Lightness 58.
    await givenReadoutOf(tester, SAMPLE_TERRACOTTA);
    expect(SAMPLE_TERRACOTTA.coordinates.lightness, 58,
        reason: 'AC-2 Given: the fixture under test has Lightness 58');
    final valueRegion = find.byKey(ValueRegion.regionKey);

    // When: the value reading is shown.
    // Then: a value word such as "middle value" accompanies the number.
    expect(
      find.descendant(
          of: valueRegion,
          matching: find.textContaining(RegExp('middle', caseSensitive: false))),
      findsWidgets,
      reason: 'AC-2: a "middle value" word must accompany Lightness 58 '
          '(COLOR-3/READOUT-2)',
    );

    // Control: the word is derived from the Lightness, not a constant. A dark
    // sample reads "low/dark", a light sample reads "high" — and neither reads
    // "middle". (Same hue/provenance as terracotta; only L changes.)
    Sample sampleAtLightness(double l) => Sample(
          name: SAMPLE_TERRACOTTA.name,
          coordinates: ColorCoordinates(
            lightness: l,
            a: SAMPLE_TERRACOTTA.coordinates.a,
            b: SAMPLE_TERRACOTTA.coordinates.b,
          ),
          provenance: SAMPLE_TERRACOTTA.provenance,
        );

    await givenReadoutOf(tester, sampleAtLightness(15));
    final darkWord = _plainTextUnder(tester, ValueRegion.regionKey).toLowerCase();
    expect(darkWord, matches(RegExp(r'\b(low|dark)\b')),
        reason: 'AC-2 control: a dark sample (L15) reads "low/dark value"');
    expect(darkWord, isNot(contains('middle')),
        reason: 'AC-2 control: a dark sample does not read "middle value"');

    await givenReadoutOf(tester, sampleAtLightness(90));
    final lightWord = _plainTextUnder(tester, ValueRegion.regionKey).toLowerCase();
    expect(lightWord, contains('high'),
        reason: 'AC-2 control: a light sample (L90) reads "high value"');
    expect(lightWord, isNot(contains('middle')),
        reason: 'AC-2 control: a light sample does not read "middle value"');
  });

  // AC-3 — The sample's nearest colour name is shown large at the top. The name
  // must be *derived* from the coordinates (the sample carries no name), so a
  // shell that echoes `Sample.name` fails.
  acTestWidgets('AC-3', 'The nearest colour name is shown large at the top',
      (tester) async {
    // Given: a sample whose nearest named colour is "Warm Terracotta" — same
    // coordinates as the terracotta fixture, but with no stored name, so the
    // name can only come from the nearest-name derivation (COLOR-3/READOUT-3).
    final unnamed = Sample(
      coordinates: SAMPLE_TERRACOTTA.coordinates,
      provenance: SAMPLE_TERRACOTTA.provenance,
    );
    expect(unnamed.name, isNull,
        reason: 'AC-3 Given: the sample carries no name — the name is derived');
    await givenReadoutOf(tester, unnamed);
    expect(find.text('Unnamed sample'), findsOneWidget,
        reason: 'AC-3 Given: the shell shows no stored name for this sample');

    // When: the readout is shown.
    // Then: the derived name "Warm Terracotta" is shown in the name header, at
    // the top of the readout, larger than (≥) every other text on the screen.
    expect(
      find.descendant(
          of: find.byKey(NameHeader.headerKey),
          matching: find.text('Warm Terracotta')),
      findsOneWidget,
      reason: 'AC-3: the derived name "Warm Terracotta" must be in the header '
          '(COLOR-3/READOUT-3)',
    );

    // Top of the readout: the name header sits above the value region.
    expect(
      tester.getTopLeft(find.byKey(NameHeader.headerKey)).dy,
      lessThan(tester.getTopLeft(find.byKey(ValueRegion.regionKey)).dy),
      reason: 'AC-3: the name must be at the top of the readout',
    );

    // Largest: the name's font size is ≥ every other reading in the body.
    final nameParas = _paragraphsUnder(tester, NameHeader.headerKey).toSet();
    final nameSize = nameParas.map(_fontSize).reduce(math.max);
    final others = _paragraphsUnder2(tester, find.byType(ListView))
        .where((p) => !nameParas.contains(p));
    for (final p in others) {
      expect(nameSize, greaterThanOrEqualTo(_fontSize(p)),
          reason: 'AC-3: the name must be at least as large as the reading '
              '"${p.text.toPlainText()}"');
    }
  });

  // AC-4 — Temperature is stated in words relative to a neutral: a warm sample
  // (hue 42°) reads "warm"; the cool control (hue ~250°) reads "cool", not warm.
  acTestWidgets('AC-4', 'A warm sample is described as "warm" in words',
      (tester) async {
    // Given: a sample at hue 42°.
    await givenReadoutOf(tester, SAMPLE_TERRACOTTA);
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'AC-4 Given: the warm terracotta sample is shown');
    expect(_hueDegrees(SAMPLE_TERRACOTTA.coordinates), closeTo(42, 0.5),
        reason: 'AC-4 Given: the fixture under test is at hue ~42°');

    // When: the readout is shown.
    // Then: the temperature is stated as the word "warm", not as a hue angle.
    final warm = _plainTextUnder(tester, TemperatureLine.lineKey).toLowerCase();
    expect(warm, contains('warm'),
        reason: 'AC-4: the temperature must be stated as "warm" (READOUT-3)');
    expect(warm, isNot(contains('42')),
        reason: 'AC-4: the temperature must be a word, not the hue angle 42');

    // Control: a cool sample (hue ~250°) reads "cool", never "warm" — proving
    // the word is derived from hue, not always "warm".
    expect(_hueDegrees(SAMPLE_COOL.coordinates), closeTo(250, 1),
        reason: 'AC-4 control: the cool fixture is at hue ~250°');
    await givenReadoutOf(tester, SAMPLE_COOL);
    final cool = _plainTextUnder(tester, TemperatureLine.lineKey).toLowerCase();
    expect(cool, contains('cool'),
        reason: 'AC-4 control: a hue-250° sample reads "cool"');
    expect(cool, isNot(contains('warm')),
        reason: 'AC-4 control: a cool sample is not described as "warm"');
  });

  // AC-5 — The readout is available in several colour spaces, one at a time:
  // selecting a space shows that space's values and hides the other three.
  acTestWidgets('AC-5', 'Selecting a colour space shows it and hides the others',
      (tester) async {
    // Given: reading the sample "Warm Terracotta".
    await givenReadoutOf(tester, SAMPLE_TERRACOTTA);
    expect(find.text('Warm Terracotta'), findsOneWidget,
        reason: 'AC-5 Given: the terracotta sample is shown');

    // Each space's expected values (`shown` from the spec's Examples) and a
    // collision-safe signature used to prove exclusivity. The four signatures
    // ('°', '10R', '#', '25.27') are mutually non-substring and none is a
    // substring of an sRGB hex, so "space Y no longer shown" is unambiguous.
    final spaces = <_SpaceCase>[
      _SpaceCase(
        space: ReadoutSpace.cielch,
        present: [RegExp('58'), RegExp('34'), RegExp('42'), RegExp(r'°|deg')],
        signature: RegExp(r'°|deg'),
      ),
      _SpaceCase(
        space: ReadoutSpace.munsell,
        present: [RegExp('10R'), RegExp(r'5\.5/6')],
        signature: RegExp('10R'),
      ),
      _SpaceCase(
        space: ReadoutSpace.srgb,
        present: [RegExp(r'#[0-9a-fA-F]{6}')],
        signature: RegExp(r'#[0-9a-fA-F]{6}'),
      ),
      _SpaceCase(
        space: ReadoutSpace.cielab,
        present: [RegExp('58'), RegExp(r'25\.27'), RegExp(r'22\.75')],
        signature: RegExp(r'25\.27'),
      ),
    ];

    // When: the painter selects each space in turn.
    // Then: that space's values are shown and the other three are not.
    for (final sel in spaces) {
      await (await givenReadoutOf(tester, SAMPLE_TERRACOTTA))
          .whenSelectSpace(sel.space);
      final shown = _plainTextUnder(tester, SpaceSelector.valuesKey);
      for (final pattern in sel.present) {
        expect(shown, matches(pattern),
            reason: 'AC-5: ${SpaceSelector.labelFor(sel.space)} must show '
                '${pattern.pattern} (READOUT-4)');
      }
      for (final other in spaces) {
        if (other.space == sel.space) continue;
        expect(shown, isNot(matches(other.signature)),
            reason: 'AC-5: with ${SpaceSelector.labelFor(sel.space)} selected, '
                '${SpaceSelector.labelFor(other.space)} must no longer be shown');
      }
    }
  });

  // AC-6 — A measured value carries the provenance "Measured" (and not the
  // estimated badge/note — the control against AC-7).
  acTestWidgets('AC-6', 'A measured value is badged "Measured"', (tester) async {
    // Given: a sample read with a spectrophotometer (provenance Measured).
    await givenReadoutOf(tester, SAMPLE_MEASURED);
    expect(find.text('Measured Reading'), findsOneWidget,
        reason: 'AC-6 Given: the measured sample is shown');
    expect(SAMPLE_MEASURED.provenance.tier, ProvenanceTier.measured,
        reason: 'AC-6 Given: the fixture under test is Measured provenance');

    // When: the readout is shown.
    // Then: the provenance region carries "Measured" — and not the Estimated
    // badge or its seeded-value note (so it does not badge everything alike).
    final prov = _plainTextUnder(tester, ProvenanceRegion.regionKey);
    expect(prov, contains('Measured'),
        reason: 'AC-6: a measured value is badged "Measured" (READOUT-5)');
    expect(prov, isNot(contains('not yet verified')),
        reason: 'AC-6 control: a measured value is not badged Estimated');
    expect(prov, isNot(contains('Seeded by a model')),
        reason: 'AC-6 control: a measured value carries no seeded-value note');
  });

  // AC-7 — An unverified seeded value is badged "Estimated — not yet verified"
  // with the seeded-value note (control: a measured value shows no such note).
  acTestWidgets('AC-7', 'An estimated value is badged Estimated with a caveat note',
      (tester) async {
    // Given: a value seeded by a model and not yet verified (Estimated).
    await givenReadoutOf(tester, SAMPLE_ESTIMATED);
    expect(find.text('Estimated Reading'), findsOneWidget,
        reason: 'AC-7 Given: the estimated sample is shown');
    expect(SAMPLE_ESTIMATED.provenance.tier, ProvenanceTier.estimated,
        reason: 'AC-7 Given: the fixture under test is Estimated provenance');

    // When: the readout is shown.
    // Then: the provenance carries "Estimated — not yet verified" and the note
    // "Seeded by a model. Treat as a starting point." is shown.
    final prov = _plainTextUnder(tester, ProvenanceRegion.regionKey);
    expect(prov, contains('Estimated'),
        reason: 'AC-7: an estimated value is badged "Estimated" (READOUT-5)');
    expect(prov, contains('not yet verified'),
        reason: 'AC-7: the estimate is labelled "not yet verified" (READOUT-5)');
    expect(prov, contains('Seeded by a model. Treat as a starting point.'),
        reason: 'AC-7: the seeded-value note is shown (READOUT-5)');

    // Control: a measured value shows no seeded-value note — so the note is tied
    // to the Estimated tier, not shown on every reading.
    await givenReadoutOf(tester, SAMPLE_MEASURED);
    final measured = _plainTextUnder(tester, ProvenanceRegion.regionKey);
    expect(measured, isNot(contains('Seeded by a model')),
        reason: 'AC-7 control: a measured value shows no seeded-value note');
  });

  // ===========================================================================
  // ITEST-3 — speak / navigation / just-captured (AC-8..AC-12)
  // (added here by ITEST-3; ∥ with the display group above)
  // ===========================================================================
}

// ---------------------------------------------------------------------------
// Rendering helpers
// ---------------------------------------------------------------------------

/// All [RenderParagraph]s rendered under the widget keyed [key] (including the
/// paragraph of a keyed `Text` itself, since its `RichText` is a descendant).
Set<RenderParagraph> _paragraphsUnder(WidgetTester tester, Key key) =>
    _paragraphsUnder2(tester, find.byKey(key));

/// All [RenderParagraph]s rendered under [scope].
Set<RenderParagraph> _paragraphsUnder2(WidgetTester tester, Finder scope) =>
    tester
        .renderObjectList<RenderParagraph>(
            find.descendant(of: scope, matching: find.byType(RichText)))
        .toSet();

/// The joined plain text of every paragraph rendered under the widget keyed
/// [key] (empty string if none).
String _plainTextUnder(WidgetTester tester, Key key) =>
    _paragraphsUnder(tester, key).map((p) => p.text.toPlainText()).join(' ');

/// The effective font size of [p] (falls back to the Material body default when
/// a paragraph inherits an unset size).
double _fontSize(RenderParagraph p) => p.text.style?.fontSize ?? 14.0;

/// The CIELCh hue angle (degrees, 0–360) of CIELAB [c] — `atan2(b*, a*)`.
double _hueDegrees(ColorCoordinates c) {
  final deg = math.atan2(c.b, c.a) * 180 / math.pi;
  return deg < 0 ? deg + 360 : deg;
}

/// One colour-space row for the AC-5 selector test: the space, the value
/// patterns that must be [present] once selected, and the collision-safe
/// [signature] that must be absent while another space is selected.
class _SpaceCase {
  _SpaceCase({required this.space, required this.present, required this.signature});

  final ReadoutSpace space;
  final List<RegExp> present;
  final RegExp signature;
}
