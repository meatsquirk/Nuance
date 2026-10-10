// Acceptance suite for bs-05 Mix-correction loop.
//
// ITEST-1 lands the harness scaffold here: a never-pending smoke test proving
// the shells wire end to end (the real app boots to the Correction screen and
// renders every region in its unchecked start state), plus guard tests so the
// scaffold cannot pass vacuously — the pending map must cover exactly the 10 ACs
// each owned by a real behaviour phase, the fakes must record, the fixtures must
// carry the coordinates their scenarios assume (the target's L/C/h, the owned
// palette, a well-formed current mix, and four scenes whose distance from the
// target is pinned against the independent reference), and that reference ΔE00
// must match Sharma et al.'s published CIEDE2000 test data.
//
// ITEST-2 and ITEST-3 register one *pending* `acTestWidgets` per AC in this
// file; the behaviour phases un-pend each by deleting its row in
// `bs05/pending.dart`. Default `flutter test integration_test/correction_test.dart`
// skips pending ACs; `--dart-define=BS05_RUN_PENDING=true` runs them.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/correction/correction_read_endpoint.dart';
import 'package:paint_color_assistant/correction/regions/check_region.dart';
import 'package:paint_color_assistant/correction/regions/correction_region.dart';
import 'package:paint_color_assistant/correction/regions/difference_region.dart';
import 'package:paint_color_assistant/correction/regions/rephotograph_region.dart';
import 'package:paint_color_assistant/correction/regions/save_region.dart';
import 'package:paint_color_assistant/correction/regions/speak_region.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';

import 'correction_harness.dart';

double _chroma(ColorCoordinates c) => math.sqrt(c.a * c.a + c.b * c.b);

double _hueDeg(ColorCoordinates c) {
  var h = math.atan2(c.b, c.a) * 180.0 / math.pi;
  if (h < 0) h += 360.0;
  return h;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'smoke: the assembled app boots to the Correction screen showing every '
    'region in its unchecked start state',
    (tester) async {
      final harness = await givenCorrection(tester);

      // Booted to the Correction route over the injected target / current mix.
      expect(find.widgetWithText(AppBar, 'Correction'), findsOneWidget);
      expect(find.byKey(CorrectionReadEndpoint.endpointKey), findsOneWidget);

      // Every region anchor the AC finders and behaviour phases rely on.
      expect(find.byKey(CheckRegion.regionKey), findsOneWidget);
      expect(find.byKey(DifferenceRegion.regionKey), findsOneWidget);
      expect(find.byKey(CorrectionRegion.regionKey), findsOneWidget);
      expect(find.byKey(SpeakRegion.regionKey), findsOneWidget);
      expect(find.byKey(RephotographRegion.regionKey), findsOneWidget);
      expect(find.byKey(SaveRegion.regionKey), findsOneWidget);

      // The target render the check region (and the Recipes → correction handoff)
      // relies on.
      expect(find.text('Correction target: Deep Olive Green'), findsOneWidget);

      // Opened correcting the injected mix toward the injected target, with
      // nothing checked, compared, corrected or saved yet, and nothing spoken.
      // (ITEST-1 writes this snapshot against the shell; the behaviour phases
      // move it — LOOP-3 fills the swatch/difference, CORRECT-* the readings,
      // LOOP-6 the saved provenance — and refine this snapshot if the opened
      // state changes.)
      expect(harness.state.target, SAMPLE_DEEP_OLIVE);
      expect(harness.state.currentMix, RECIPE_DEEP_OLIVE);
      expect(harness.state.mixedSwatch, isNull);
      expect(harness.state.difference, isNull);
      expect(harness.state.correction, isNull);
      expect(harness.state.savedProvenance, isNull);
      expect(harness.state.hasChecked, isFalse);
      expect(harness.speech.utterances, isEmpty);
    },
  );

  group('pending gate', () {
    // Un-pended by the behaviour phases so far: none (ITEST-1 is the harness
    // scaffold; all 10 ACs were seeded pending in LOOP-1). Each behaviour phase
    // adds its AC here as it deletes the row in `bs05/pending.dart`: LOOP-3 →
    // AC-1; CORRECT-2 → AC-2, AC-3; CORRECT-3 → AC-4, AC-5; CORRECT-4 → AC-6;
    // LOOP-4 → AC-7; LOOP-5 → AC-8; LOOP-6 → AC-9, AC-10.
    const unpended = <String>{};

    test(
      'pending map is the exact complement of the un-pended ACs across all 10, '
      'each owned by a real behaviour phase',
      () {
        for (var n = 1; n <= 10; n++) {
          final ac = 'AC-$n';
          expect(
            pendingACs.containsKey(ac),
            !unpended.contains(ac),
            reason: unpended.contains(ac)
                ? '$ac is un-pended and must not be in the pending map'
                : '$ac must still have a pending entry',
          );
        }
        expect(pendingACs.length, 10 - unpended.length);
        for (final entry in pendingACs.entries) {
          expect(
            behaviorPhases,
            contains(entry.value),
            reason: '${entry.key} names unknown phase "${entry.value}"',
          );
        }
      },
    );

    test(
        'the gate skips every pending AC by default and runs it in run-pending '
        'mode', () {
      expect(pendingACs, isNotEmpty,
          reason: 'the harness scaffold seeds the pending map (LOOP-1)');
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

    test('FakeHaptics counts each confirmation', () async {
      final haptics = FakeHaptics();
      expect(haptics.confirmations, 0);
      await haptics.confirm();
      await haptics.confirm();
      expect(haptics.confirmations, 2);
    });
  });

  group('fixtures carry the coordinates their scenarios assume', () {
    test('Deep Olive Green recovers its C 24 / h 93 (the target reading)', () {
      // AC-2/AC-3 reason about the target at L 42, C 24, h 93; the fixture
      // derives C/h from a*/b*, so it must carry those polar values.
      expect(SAMPLE_DEEP_OLIVE.coordinates.lightness, 42);
      expect(_chroma(SAMPLE_DEEP_OLIVE.coordinates), closeTo(24, 0.05));
      expect(_hueDeg(SAMPLE_DEEP_OLIVE.coordinates), closeTo(93, 0.1));
    });

    test('the target starts estimated so a confirm is a real promotion (AC-9)',
        () {
      // AC-9 promotes the target to `confirmed` only on the painter's own
      // photographed swatch (D-8); if it already were confirmed the promotion
      // would be vacuous. The honest-provenance start is a pre-confirmed tier.
      expect(SAMPLE_DEEP_OLIVE.provenance.tier, isNot(ProvenanceTier.confirmed),
          reason: 'the target must start pre-confirmed so AC-9 is a real change');
    });

    test('"My paints" lists the five named paints (AC-4/AC-5 name two)', () {
      expect(
        PALETTE_MY_PAINTS.paints.map((p) => p.name).toList(),
        containsAll(<String>[
          'Titanium White',
          'Yellow Ochre',
          'Ivory Black',
          'Ultramarine Blue',
          'Venetian Red',
        ]),
      );
      expect(PALETTE_MY_PAINTS.paints.length, 5);
    });

    test('RECIPE_DEEP_OLIVE is a well-formed current mix over "My paints"', () {
      // The correction perturbs this mix's parts (AC-4/AC-5), so it must be a
      // real recipe: acrylic (recipes never span media), every component drawn
      // from the selected palette, positive parts summing to 1 by volume, and a
      // predicted colour the forward model produced.
      expect(RECIPE_DEEP_OLIVE.medium, PaintMedium.acrylic);
      expect(RECIPE_DEEP_OLIVE.components, isNotEmpty);
      final paletteIds = PALETTE_MY_PAINTS.paints.map((p) => p.id).toSet();
      var sum = 0.0;
      for (final c in RECIPE_DEEP_OLIVE.components) {
        expect(paletteIds, contains(c.paint.id),
            reason: '${c.paint.name} must be a paint from "My paints"');
        expect(c.partsFraction, greaterThan(0),
            reason: '${c.paint.name} must carry a positive parts share');
        sum += c.partsFraction;
      }
      expect(sum, closeTo(1.0, 1e-9),
          reason: 'parts by volume are shares that sum to 1');
      expect(RECIPE_DEEP_OLIVE.predictedColor.lightness, inInclusiveRange(0, 100),
          reason: 'the forward model predicts a plausible CIELAB colour');
    });

    test('the scenes sit at the distances and directions their ACs assume', () {
      final target = SAMPLE_DEEP_OLIVE.coordinates;
      final dOff = referenceDeltaE00(SCENE_OFF.groundTruth, target);
      final dClose = referenceDeltaE00(SCENE_CLOSE.groundTruth, target);
      final dCloser = referenceDeltaE00(SCENE_CLOSER.groundTruth, target);
      final dOchre = referenceDeltaE00(SCENE_OCHRE_TRACE.groundTruth, target);

      // SCENE_OFF: noticeably off — too dark by exactly 6 and shifted toward
      // green (a higher hue angle than the target's 93°). This pins the AC-3
      // "too dark by 6" / "toward green" geometry.
      expect(dOff, greaterThan(kToleranceDeltaE00),
          reason: 'SCENE_OFF is beyond tolerance ("noticeably off")');
      expect(target.lightness - SCENE_OFF.groundTruth.lightness, closeTo(6, 1e-9),
          reason: 'SCENE_OFF reads too dark by 6 (L 36 vs the target L 42)');
      expect(_hueDeg(SCENE_OFF.groundTruth), greaterThan(_hueDeg(target)),
          reason: 'SCENE_OFF is shifted toward green (hue above the target)');

      // SCENE_CLOSE: within tolerance (AC-6; the AC-2 "very close" control).
      expect(dClose, lessThanOrEqualTo(kToleranceDeltaE00),
          reason: 'SCENE_CLOSE sits within ΔE00 tolerance (within-tolerance)');

      // SCENE_CLOSER: a genuine improvement over SCENE_OFF (AC-8 re-photograph)
      // that is still beyond tolerance, so the verdict improves without yet
      // reaching "very close".
      expect(dCloser, lessThan(dOff),
          reason: 'SCENE_CLOSER is closer to the target than SCENE_OFF');
      expect(dCloser, greaterThan(kToleranceDeltaE00),
          reason: 'SCENE_CLOSER is still beyond tolerance (a step, not a match)');

      // SCENE_OCHRE_TRACE: short of the target's yellow (lower b*), a small gap
      // (beyond tolerance but well inside SCENE_OFF) whose fix is a touch of
      // Yellow Ochre (AC-5).
      expect(SCENE_OCHRE_TRACE.groundTruth.b, lessThan(target.b),
          reason: 'SCENE_OCHRE_TRACE is short of the target yellow (needs ochre)');
      expect(dOchre, greaterThan(kToleranceDeltaE00),
          reason: 'SCENE_OCHRE_TRACE is beyond tolerance, so a correction is due');
      expect(dOchre, lessThan(dOff),
          reason: 'SCENE_OCHRE_TRACE is a small gap (a touch, not a big off)');
    });
  });

  group('referenceDeltaE00 matches Sharma et al. published CIEDE2000 data', () {
    // The independent authority AC-2 grades the product's ΔE00 against; a wrong
    // reference (CIE76 / CIE94 / a sign slip in the hue-rotation term) fails
    // these. Published pairs from Sharma, Wu & Dalal (2005).
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
          SAMPLE_DEEP_OLIVE.coordinates,
          SAMPLE_DEEP_OLIVE.coordinates,
        ),
        closeTo(0, 1e-9),
      );
    });
  });

  // =========================================================================
  // ITEST-2 — AC tests for AC-1, AC-7, AC-8, AC-9, AC-10 (the check /
  // loop / provenance ACs) are appended here.
  // ITEST-3 — AC tests for AC-2, AC-3, AC-4, AC-5, AC-6 (the difference /
  // correction detail ACs) are appended below the ITEST-2 group.
  //
  // One *pending* acTestWidgets per AC: skipped in the default run, executed
  // under --dart-define=BS05_RUN_PENDING=true, un-pended by its owning behaviour
  // phase. Each drives the real assembled app through `correction_harness.dart`
  // and asserts through the public surface (rendered text + the
  // CorrectionReadEndpoint state seam + the FakeSpeech log). Keep the two groups
  // disjoint.
  // =========================================================================
}
