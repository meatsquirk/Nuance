// Acceptance suite for bs-03 Relative comparison.
//
// ITEST-1 lands the harness scaffold here: a never-pending smoke test proving
// the shells wire end to end (the real app boots to the Comparison screen and
// renders all five regions), plus guard tests so the scaffold cannot pass
// vacuously — the pending map must cover exactly the 12 ACs each owned by a
// real behaviour phase, the fakes must record, the fixtures must carry the LCh
// coordinates their scenarios assume, and the independent reference ΔE00 must
// match Sharma et al.'s published CIEDE2000 test data.
//
// ITEST-2 and ITEST-3 register one *pending* `acTestWidgets` per AC in this
// file; the behaviour phases un-pend each by deleting its row in
// `bs03/pending.dart`. Default `flutter test integration_test/comparison_test.dart`
// skips pending ACs; `--dart-define=BS03_RUN_PENDING=true` runs them.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/compare/actions_bar.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/confusion_region.dart';
import 'package:paint_color_assistant/compare/difference_region.dart';
import 'package:paint_color_assistant/compare/slots_region.dart';
import 'package:paint_color_assistant/compare/statement_region.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/readout/name_header.dart';

import 'comparison_harness.dart';

double _chroma(ColorCoordinates c) => math.sqrt(c.a * c.a + c.b * c.b);

double _hueDeg(ColorCoordinates c) {
  var h = math.atan2(c.b, c.a) * 180.0 / math.pi;
  if (h < 0) h += 360.0;
  return h;
}

/// The joined plain text of every paragraph rendered under the widget keyed
/// [key] (empty string if none) — used to read a comparison region's text
/// regardless of how many `Text`s it is split across.
String _plainTextUnder(WidgetTester tester, Key key) => tester
    .renderObjectList<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    )
    .map((p) => p.text.toPlainText())
    .join(' ');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to the Comparison screen showing every region',
    (tester) async {
      final harness = await givenComparison(tester);

      // Booted to the Comparison route over the injected catalogue.
      expect(find.text('Comparison'), findsOneWidget); // app-bar title
      expect(
        find.byKey(ComparisonReadEndpoint.endpointKey),
        findsOneWidget,
      );

      // Every region anchor the AC finders and behaviour phases rely on.
      expect(find.byKey(SlotsRegion.regionKey), findsOneWidget);
      expect(find.byKey(DifferenceRegion.regionKey), findsOneWidget);
      expect(find.byKey(StatementRegion.regionKey), findsOneWidget);
      expect(find.byKey(ConfusionRegion.regionKey), findsOneWidget);
      expect(find.byKey(ComparisonActionsBar.regionKey), findsOneWidget);

      // Opened on the picker with no pair chosen: both slots empty, no reading,
      // not confusable, and nothing spoken.
      expect(harness.state.slotA, isNull);
      expect(harness.state.slotB, isNull);
      expect(harness.state.hasBothSlots, isFalse);
      expect(harness.state.comparison, isNull);
      expect(harness.state.confusable, isFalse);
      expect(harness.speech.utterances, isEmpty);
    },
  );

  group('pending gate', () {
    // No AC is un-pended yet (ITEST-1 only seeds the gate); the pending map is
    // therefore the full set of 12. This set grows — i.e. this literal shrinks
    // — one behaviour phase at a time as each un-pends its AC.
    const unpended = <String>{};

    test(
      'pending map is the exact complement of the un-pended ACs across all 12, '
      'each owned by a real behaviour phase',
      () {
        for (var n = 1; n <= 12; n++) {
          final ac = 'AC-$n';
          expect(
            pendingACs.containsKey(ac),
            !unpended.contains(ac),
            reason: unpended.contains(ac)
                ? '$ac is un-pended and must not be in the pending map'
                : '$ac must still have a pending entry',
          );
        }
        expect(pendingACs.length, 12 - unpended.length);
        for (final entry in pendingACs.entries) {
          expect(
            behaviorPhases,
            contains(entry.value),
            reason: '${entry.key} names unknown phase "${entry.value}"',
          );
        }
      },
    );

    test('the gate skips every pending AC by default and runs it in run-pending '
        'mode', () {
      for (final ac in pendingACs.keys) {
        expect(
          pendingSkipReason(ac, forceRunPending: false),
          isNotNull,
          reason: '$ac is pending and must be skipped in the default run',
        );
        expect(
          pendingSkipReason(ac, forceRunPending: true),
          isNull,
          reason: '$ac must execute in run-pending mode (the red baseline)',
        );
      }
      // An AC absent from the map always runs, in either mode — the un-pended
      // end state each behaviour phase moves its AC toward.
      expect(pendingSkipReason('AC-unmapped', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-unmapped', forceRunPending: true), isNull);
      // The ambient path (used by acTestWidgets) agrees with the current mode.
      expect(
        pendingSkipReason('AC-1'),
        pendingSkipReason('AC-1', forceRunPending: runPending),
      );
    });
  });

  group('fakes record what the app drives them with', () {
    test('FakeSpeech appends each utterance in order', () async {
      final speech = FakeSpeech();
      await speech.speak('first');
      await speech.speak('second');
      expect(speech.utterances, ['first', 'second']);
    });
  });

  group('fixtures carry the coordinates their scenarios assume', () {
    test('the catalogue lists the five named saved samples', () {
      expect(
        CATALOGUE.map((s) => s.name).toList(),
        containsAll(<String>[
          'Warm Terracotta',
          'Raw Sienna Light',
          'Mid Raw Umber',
          'Ultramarine Shadow',
          'Terracotta Tint',
        ]),
      );
      expect(CATALOGUE.length, 5);
    });

    test('the terracotta / sienna LCh coordinates recover their C and h', () {
      // AC-1/AC-2 render "L 58, C 34, h 42" / "L 70, C 25, h 60"; the slot
      // derives C/h from a*/b*, so the fixtures must carry those polar values.
      expect(SAMPLE_A_TERRACOTTA.coordinates.lightness, 58);
      expect(_chroma(SAMPLE_A_TERRACOTTA.coordinates), closeTo(34, 0.05));
      expect(_hueDeg(SAMPLE_A_TERRACOTTA.coordinates), closeTo(42, 0.1));

      expect(SAMPLE_B_SIENNA.coordinates.lightness, 70);
      expect(_chroma(SAMPLE_B_SIENNA.coordinates), closeTo(25, 0.05));
      expect(_hueDeg(SAMPLE_B_SIENNA.coordinates), closeTo(60, 0.1));
    });

    test('SAMPLE_A_PRIME shares the terracotta hue angle (AC-6 "Same hue")', () {
      // AC-6 needs a partner at the *same* hue (42°) but a different lightness
      // and chroma, so only the hue dimension reads "Same hue".
      expect(_hueDeg(SAMPLE_A_PRIME.coordinates), closeTo(42, 0.1));
      expect(
        _hueDeg(SAMPLE_A_PRIME.coordinates),
        closeTo(_hueDeg(SAMPLE_A_TERRACOTTA.coordinates), 0.1),
      );
      expect(
        SAMPLE_A_PRIME.coordinates.lightness,
        isNot(SAMPLE_A_TERRACOTTA.coordinates.lightness),
      );
      expect(
        _chroma(SAMPLE_A_PRIME.coordinates),
        isNot(closeTo(_chroma(SAMPLE_A_TERRACOTTA.coordinates), 1.0)),
      );
    });

    test('the off-line control pair is clearly different to normal vision '
        '(AC-8)', () {
      // The AC-8 control: terracotta vs sienna are plainly distinct, so a
      // confusion warning on them would be wrong. (The exact literal is G-4.)
      expect(
        referenceDeltaE00(
          SAMPLE_A_TERRACOTTA.coordinates,
          SAMPLE_B_SIENNA.coordinates,
        ),
        greaterThan(10),
      );
    });
  });

  group('referenceDeltaE00 matches Sharma et al. published CIEDE2000 data', () {
    // The independent authority AC-4/AC-7 grade the product's ΔE00 against; a
    // wrong reference (CIE76 / CIE94 / a sign slip in the hue-rotation term)
    // fails these. Published pairs from Sharma, Wu & Dalal (2005).
    const cases = <List<double>>[
      // L1, a1, b1, L2, a2, b2, expected ΔE00
      [50, 2.6772, -79.7751, 50, 0, -82.7485, 2.0425],
      [50, -1.3802, -84.2814, 50, 0, -82.7485, 1.0000],
      [50, 0, 0, 50, -1, 2, 2.3669],
      [50, 2.4900, -0.0010, 50, -2.4900, 0.0009, 7.1792],
      [2.0776, 0.0795, -1.1350, 0.9033, -0.0636, -0.5514, 0.9082],
    ];

    test('each published pair', () {
      for (final c in cases) {
        final got = referenceDeltaE00(
          ColorCoordinates(lightness: c[0], a: c[1], b: c[2]),
          ColorCoordinates(lightness: c[3], a: c[4], b: c[5]),
        );
        expect(got, closeTo(c[6], 1e-3),
            reason: 'ΔE00 for $c should be ${c[6]}');
      }
    });

    test('a sample compared with itself is zero', () {
      expect(
        referenceDeltaE00(
          SAMPLE_A_TERRACOTTA.coordinates,
          SAMPLE_A_TERRACOTTA.coordinates,
        ),
        closeTo(0, 1e-9),
      );
    });
  });

  // ===========================================================================
  // ITEST-2 — selection / swap / open-readout / invite (AC-1,2,3,10,11,12)
  // ===========================================================================
  //
  // One *pending* test per AC, driving the real assembled app through the
  // harness vocabulary. The default run skips these; under
  // `--dart-define=BS03_RUN_PENDING=true` they execute (the red baseline) and
  // must fail on a Then — or a Given precondition naming the phase that builds
  // it — never panic. Each un-pends when its owning phase deletes its row in
  // `bs03/pending.dart` (AC-1/2/12 → COMPARE-3, AC-3 → COMPARE-5, AC-10/11 →
  // COMPARE-6). Selection (COMPARE-3) is the first behaviour every other Given
  // here builds on, so until it lands these fail at the "picker lists the
  // sample" precondition. (ITEST-3 adds AC-4..AC-9 below this group.)

  // AC-1 — Choosing a saved sample as A fills slot A with the sample *and* its
  // L/C/h reading (E3 → picker E49). The numbers are part of the Then, so a slot
  // that shows only the name fails.
  acTestWidgets('AC-1',
      'Choosing sample A fills slot A with the sample and its L/C/h',
      (tester) async {
    // Given: Comparison open on the catalogue, slot A empty, and the picker
    // lists the saved samples to choose from (opened from Choose sample A).
    final h = await givenComparison(tester);
    expect(h.state.slotA, isNull, reason: 'AC-1 Given: slot A starts empty');
    await h.whenOpenPicker(ComparisonSlot.a);
    for (final sample in CATALOGUE) {
      expect(find.text(sample.name!), findsWidgets,
          reason: 'AC-1 Given: the picker must list the saved sample '
              '"${sample.name}" (COMPARE-3 drives E49)');
    }

    // When: the painter chooses "Warm Terracotta" as sample A.
    await tester.tap(find.text('Warm Terracotta').last);
    await tester.pumpAndSettle();

    // Then: the pick populates slot A (and only slot A) with Warm Terracotta,
    // and slot A shows the name together with "L 58, C 34, h 42 degrees".
    expect(h.state.slotA?.name, 'Warm Terracotta',
        reason: 'AC-1: choosing A populates slot A with Warm Terracotta '
            '(COMPARE-3)');
    expect(h.state.slotB, isNull,
        reason: 'AC-1: choosing A does not fill slot B');
    final slots = _plainTextUnder(tester, SlotsRegion.regionKey);
    expect(slots, contains('Slot A: Warm Terracotta'),
        reason: 'AC-1: slot A shows the sample name (COMPARE-3)');
    expect(slots, contains('L 58, C 34, h 42 degrees'),
        reason: 'AC-1: slot A shows "L 58, C 34, h 42 degrees" — the name '
            'without the numbers is not enough (COMPARE-3)');
  });

  // AC-2 — Choosing a saved sample as B fills slot B with the sample and its
  // L/C/h, leaving slot A unchanged (so the B pick does not land in slot A).
  acTestWidgets('AC-2',
      'Choosing sample B fills slot B with the sample and its L/C/h',
      (tester) async {
    // Given: sample A is "Warm Terracotta", chosen through the AC-1 flow.
    final h = await givenComparison(tester);
    await h.whenChooseA('Warm Terracotta');
    expect(h.state.slotA?.name, 'Warm Terracotta',
        reason: 'AC-2 Given: slot A is Warm Terracotta via the selection flow '
            '(COMPARE-3)');
    expect(h.state.slotB, isNull,
        reason: 'AC-2 Given: slot B is still empty before the B pick');

    // When: the painter chooses "Raw Sienna Light" as sample B.
    await h.whenChooseB('Raw Sienna Light');

    // Then: slot B holds Raw Sienna Light with its L/C/h, and slot A is
    // unchanged (the B pick did not land in slot A).
    expect(h.state.slotB?.name, 'Raw Sienna Light',
        reason: 'AC-2: choosing B populates slot B (COMPARE-3)');
    expect(h.state.slotA?.name, 'Warm Terracotta',
        reason: 'AC-2: the B pick does not overwrite slot A (COMPARE-3)');
    final slots = _plainTextUnder(tester, SlotsRegion.regionKey);
    expect(slots, contains('Slot B: Raw Sienna Light'),
        reason: 'AC-2: slot B shows the sample name (COMPARE-3)');
    expect(slots, contains('L 70, C 25, h 60 degrees'),
        reason: 'AC-2: slot B shows "L 70, C 25, h 60 degrees" (COMPARE-3)');
  });

  // AC-3 — Swapping exchanges the two samples and re-expresses the relational
  // statement from the new A to the new B. The direction word must flip
  // ("Lighter by 12" → "Darker by 12"): a swap that relabels the slots but
  // leaves the statement, or that no-ops, fails.
  acTestWidgets('AC-3',
      'Swapping exchanges the samples and re-expresses the difference',
      (tester) async {
    // Given: A = Warm Terracotta, B = Raw Sienna Light, with the statement
    // present and reading A→B ("Lighter by 12", L 58 → L 70 — DIFF-3).
    final h = await givenComparison(tester);
    await h.whenChooseA('Warm Terracotta');
    await h.whenChooseB('Raw Sienna Light');
    expect(h.state.slotA?.name, 'Warm Terracotta',
        reason: 'AC-3 Given: slot A is Warm Terracotta (COMPARE-3)');
    expect(h.state.slotB?.name, 'Raw Sienna Light',
        reason: 'AC-3 Given: slot B is Raw Sienna Light (COMPARE-3)');
    expect(_plainTextUnder(tester, StatementRegion.regionKey),
        contains('Lighter by 12'),
        reason: 'AC-3 Given: the A→B statement reads "Lighter by 12" (DIFF-3)');

    // When: the painter swaps A and B.
    await h.whenSwap();

    // Then: the slots are exchanged and the statement is re-expressed new-A →
    // new-B — now "Darker by 12" (L 70 → L 58), no longer "Lighter by 12".
    expect(h.state.slotA?.name, 'Raw Sienna Light',
        reason: 'AC-3: slot A becomes Raw Sienna Light after the swap '
            '(COMPARE-5)');
    expect(h.state.slotB?.name, 'Warm Terracotta',
        reason: 'AC-3: slot B becomes Warm Terracotta after the swap '
            '(COMPARE-5)');
    expect(_plainTextUnder(tester, SlotsRegion.regionKey),
        contains('Slot A: Raw Sienna Light'),
        reason: 'AC-3: slot A renders the swapped sample (COMPARE-5)');
    final statement = _plainTextUnder(tester, StatementRegion.regionKey);
    expect(statement, contains('Darker by 12'),
        reason: 'AC-3: the statement re-expresses new-A → new-B — "Darker by '
            '12" (COMPARE-5)');
    expect(statement, isNot(contains('Lighter by 12')),
        reason: 'AC-3: the statement must change direction, not stay "Lighter '
            'by 12" (rejects a swap that relabels the slots but leaves the '
            'statement)');
  });

  // AC-10 — Opening the readout for A navigates to the Readout screen showing
  // sample A (E7). Control pair with AC-11 (which proves B): an impl that always
  // opens one slot fails exactly one of the pair.
  acTestWidgets('AC-10',
      'Opening the readout for A shows the Readout for sample A',
      (tester) async {
    // Given: sample A is "Warm Terracotta", on the Comparison screen.
    final h = await givenComparison(tester);
    await h.whenChooseA('Warm Terracotta');
    expect(h.state.slotA?.name, 'Warm Terracotta',
        reason: 'AC-10 Given: slot A is Warm Terracotta (COMPARE-3)');
    expect(find.text('Readout'), findsNothing,
        reason: 'AC-10 Given: the painter starts on Comparison, not Readout');

    // When: the painter opens the readout for sample A.
    await h.whenOpenReadout(ComparisonSlot.a);

    // Then: the Readout screen is shown for "Warm Terracotta" (its name in the
    // readout header), not for sample B or the wrong sample.
    expect(find.text('Readout'), findsOneWidget,
        reason: 'AC-10: the Readout screen is shown (COMPARE-6 wires '
            'toReadout)');
    expect(
      find.descendant(
        of: find.byKey(NameHeader.headerKey),
        matching: find.text('Warm Terracotta'),
      ),
      findsOneWidget,
      reason: 'AC-10: the Readout is shown for Warm Terracotta (COMPARE-6)',
    );
  });

  // AC-11 — Opening the readout for B navigates to the Readout screen showing
  // sample B (E8). Control pair with AC-10.
  acTestWidgets('AC-11',
      'Opening the readout for B shows the Readout for sample B',
      (tester) async {
    // Given: sample B is "Raw Sienna Light", on the Comparison screen.
    final h = await givenComparison(tester);
    await h.whenChooseB('Raw Sienna Light');
    expect(h.state.slotB?.name, 'Raw Sienna Light',
        reason: 'AC-11 Given: slot B is Raw Sienna Light (COMPARE-3)');
    expect(find.text('Readout'), findsNothing,
        reason: 'AC-11 Given: the painter starts on Comparison, not Readout');

    // When: the painter opens the readout for sample B.
    await h.whenOpenReadout(ComparisonSlot.b);

    // Then: the Readout screen is shown for "Raw Sienna Light".
    expect(find.text('Readout'), findsOneWidget,
        reason: 'AC-11: the Readout screen is shown (COMPARE-6 wires '
            'toReadout)');
    expect(
      find.descendant(
        of: find.byKey(NameHeader.headerKey),
        matching: find.text('Raw Sienna Light'),
      ),
      findsOneWidget,
      reason: 'AC-11: the Readout is shown for Raw Sienna Light (COMPARE-6)',
    );
  });

  // AC-12 — With sample A chosen but no sample B, no relational statement is
  // shown and the screen invites the painter to choose sample B (an enabled
  // choose-B affordance). A statement computed against one sample, or a missing
  // invite, fails.
  acTestWidgets('AC-12', 'With no second sample, the comparison invites one',
      (tester) async {
    // Given: sample A is "Warm Terracotta" and no sample B has been chosen.
    final h = await givenComparison(tester);
    await h.whenChooseA('Warm Terracotta');
    expect(h.state.slotA?.name, 'Warm Terracotta',
        reason: 'AC-12 Given: slot A is Warm Terracotta (COMPARE-3)');
    expect(h.state.slotB, isNull,
        reason: 'AC-12 Given: no sample B has been chosen');

    // When: the Comparison screen is shown (givenComparison settled it).

    // Then: no relational statement is shown — a single sample yields no
    // reading — and an enabled choose-sample-B invite is on the screen.
    expect(h.state.hasBothSlots, isFalse,
        reason: 'AC-12: with one slot empty there is no pair');
    expect(h.state.comparison, isNull,
        reason: 'AC-12: no relational reading is derived from one sample');
    final statement = _plainTextUnder(tester, StatementRegion.regionKey);
    for (final word in const [
      'Lighter',
      'Darker',
      'saturated',
      'shifted',
      'Same',
    ]) {
      expect(statement, isNot(contains(word)),
          reason: 'AC-12: no relational-statement line ("$word") is shown with '
              'only one sample');
    }
    final chooseB = find.widgetWithText(TextButton, 'Choose sample B');
    expect(chooseB, findsWidgets,
        reason: 'AC-12: a choose-sample-B control is on the screen');
    expect(tester.widget<TextButton>(chooseB.first).enabled, isTrue,
        reason: 'AC-12: the screen invites choosing sample B — the choose-B '
            'control is enabled (COMPARE-3)');
  });
}
