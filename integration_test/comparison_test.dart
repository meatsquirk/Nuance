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

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/compare/actions_bar.dart';
import 'package:paint_color_assistant/compare/comparison_read_endpoint.dart';
import 'package:paint_color_assistant/compare/confusion_region.dart';
import 'package:paint_color_assistant/compare/difference_region.dart';
import 'package:paint_color_assistant/compare/slots_region.dart';
import 'package:paint_color_assistant/compare/statement_region.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

import 'comparison_harness.dart';

double _chroma(ColorCoordinates c) => math.sqrt(c.a * c.a + c.b * c.b);

double _hueDeg(ColorCoordinates c) {
  var h = math.atan2(c.b, c.a) * 180.0 / math.pi;
  if (h < 0) h += 360.0;
  return h;
}

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
}
