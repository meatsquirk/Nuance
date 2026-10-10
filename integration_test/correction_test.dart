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
import 'package:paint_color_assistant/app/router.dart';
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
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/provenance_region.dart';
import 'package:paint_color_assistant/recipes/engine/subtractive_engine.dart';

import 'correction_harness.dart';

double _chroma(ColorCoordinates c) => math.sqrt(c.a * c.a + c.b * c.b);

double _hueDeg(ColorCoordinates c) {
  var h = math.atan2(c.b, c.a) * 180.0 / math.pi;
  if (h < 0) h += 360.0;
  return h;
}

/// The painter later opens the saved value's full readout (AC-10): pushes the
/// real `router.toReadout` route onto the running app's navigator, which sits
/// under the app's `AppScope`, so the pushed [ReadoutScreen] reads the same
/// injected services. The confirmed [sample] comes from the public save surface,
/// so this is "the value is shown in a later readout", not a hand-built screen.
Future<void> _showInLaterReadout(WidgetTester tester, Sample sample) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  await navigator.push(const AppRouter().toReadout(sample));
  await tester.pumpAndSettle();
}

/// The concatenated non-empty [Text] under [regionKey] (the rendered words a
/// painter reads in that region), for asserting a region's plain-language output.
String _plainTextUnder(WidgetTester tester, Key regionKey) => tester
    .widgetList<Text>(
      find.descendant(of: find.byKey(regionKey), matching: find.byType(Text)),
    )
    .map((t) => t.data ?? '')
    .where((s) => s.isNotEmpty)
    .join(' ');

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

  group('ITEST-2 — AC-1, AC-7, AC-8, AC-9, AC-10 (check / loop / provenance)',
      () {
    acTestWidgets(
        'AC-1',
        'TestAC01_CheckPhotographsAndCompares — checking photographs the '
            'swatch and compares it to the target', (tester) async {
      // Given: the Correction screen open on Deep Olive Green + its current
      // mix, the physical swatch reading SCENE_OFF, nothing checked yet.
      final h = await givenCorrection(tester, scene: SCENE_OFF);
      expect(h.state.target, SAMPLE_DEEP_OLIVE,
          reason: 'AC-1 Given: correcting toward Deep Olive Green');
      expect(h.state.mixedSwatch, isNull,
          reason: 'AC-1 Given: no swatch photographed yet');
      expect(h.state.difference, isNull,
          reason: 'AC-1 Given: no comparison yet');
      expect(find.widgetWithText(ElevatedButton, 'Check my mix'), findsOneWidget,
          reason: 'AC-1 Given: the E26 check control is present');

      // When: the painter checks the mix (E26).
      await h.whenCheck(); // LOOP-3 wires CorrectionController.checkMix

      // Then: the swatch was photographed as a *measured* sample, and compared
      // to the target — a difference whose ΔE00 is the real swatch→target
      // distance (graded against the independent reference), not zero (which
      // would be the target compared with itself).
      final swatch = h.state.mixedSwatch;
      expect(swatch, isA<Sample>(),
          reason: 'AC-1: the check photographs the swatch (LOOP-3)');
      expect(swatch!.provenance.tier, ProvenanceTier.measured,
          reason: 'AC-1: the photographed swatch is a measured reading');
      final diff = h.state.difference;
      expect(diff, isNotNull,
          reason: 'AC-1: the swatch is compared to the target (LOOP-3)');
      expect(
          diff!.deltaE00,
          closeTo(
              referenceDeltaE00(
                  swatch.coordinates, SAMPLE_DEEP_OLIVE.coordinates),
              0.1),
          reason: 'AC-1: the stated distance is the swatch→target ΔE00');
      expect(diff.deltaE00, greaterThan(kToleranceDeltaE00),
          reason: 'AC-1: SCENE_OFF is a real off-reading, not target vs itself');
    });

    acTestWidgets(
        'AC-7',
        'TestAC07_SpeakCorrection — the painter hears the difference and the '
            'paints to add spoken', (tester) async {
      // Given: a checked SCENE_OFF mix with a computed correction, and nothing
      // spoken yet.
      final h = await givenCorrection(tester, scene: SCENE_OFF);
      await h.whenCheck();
      final correction = h.state.correction;
      expect(correction, isNotNull,
          reason: 'AC-7 Given: a correction has been computed for the swatch '
              '(LOOP-4 speaks the check+correct result)');
      expect(correction!.isEmpty, isFalse,
          reason: 'AC-7 Given: SCENE_OFF needs a non-empty correction to speak');
      final diff = h.state.difference;
      expect(diff, isNotNull, reason: 'AC-7 Given: a difference is shown');
      expect(h.speech.utterances, isEmpty,
          reason: 'AC-7 Given: nothing is spoken before the painter asks');

      // When: the painter asks to speak the correction (E27).
      await h.whenSpeakCorrection(); // LOOP-4

      // Then: exactly one utterance, stating the difference (its verdict) and
      // each paint to add.
      expect(h.speech.utterances, hasLength(1),
          reason: 'AC-7: one spoken utterance for the correction (LOOP-4)');
      final spoken = h.speech.utterances.single;
      expect(spoken, contains(diff!.verdict),
          reason: 'AC-7: the spoken output states the difference');
      for (final add in correction.additions) {
        expect(spoken, contains(add.paint.name),
            reason: 'AC-7: the spoken output names each paint to add '
                '(${add.paint.name})');
      }
    });

    acTestWidgets(
        'AC-8',
        'TestAC08_RephotographRechecks — re-photographing re-checks the swatch '
            'against the target', (tester) async {
      // Given: a first-checked SCENE_OFF mix showing a difference/verdict.
      final h = await givenCorrection(tester, scene: SCENE_OFF);
      await h.whenCheck();
      final before = h.state.difference;
      expect(before, isNotNull,
          reason: 'AC-8 Given: the first check shows a difference '
              '(LOOP-5 re-runs that check)');
      final beforeDelta = before!.deltaE00;

      // The painter applied the correction; the physical swatch now reads
      // closer (SCENE_CLOSER — still beyond tolerance, so a genuine step).
      h.source.rephotographAs(SCENE_CLOSER);

      // When: the painter re-photographs the swatch (E28).
      await h.whenRephotograph(); // LOOP-5

      // Then: a new swatch is measured from the new scene and re-compared, and
      // the distance/verdict improve (not stale, not a no-op).
      final after = h.state.difference;
      expect(after, isNotNull,
          reason: 'AC-8: the re-photograph re-compares to the target (LOOP-5)');
      expect(h.state.mixedSwatch!.coordinates.lightness,
          closeTo(SCENE_CLOSER.groundTruth.lightness, 1.0),
          reason: 'AC-8: the swatch was re-measured from the new scene');
      expect(after!.deltaE00, lessThan(beforeDelta),
          reason: 'AC-8: the re-checked distance is smaller than before');
    });

    acTestWidgets(
        'AC-9',
        'TestAC09_SaveConfirmed — saving a satisfactory mix promotes the value '
            'to Confirmed by the painter', (tester) async {
      // Given: a checked, within-tolerance mix for Deep Olive Green — the
      // painter's own measured swatch, on a target not already confirmed.
      final h = await givenCorrection(tester, scene: SCENE_CLOSE);
      await h.whenCheck();
      final swatch = h.state.mixedSwatch;
      expect(swatch, isA<Sample>(),
          reason: 'AC-9 Given: a photographed swatch (LOOP-6 saves the checked '
              'mix)');
      expect(swatch!.provenance.tier, ProvenanceTier.measured,
          reason: "AC-9 Given: the swatch is the painter's own measured "
              'reading');
      expect(h.state.difference?.withinTolerance, isTrue,
          reason: 'AC-9 Given: the mix is satisfactory (within tolerance)');
      expect(h.state.target.provenance.tier, isNot(ProvenanceTier.confirmed),
          reason: 'AC-9 Given: the target is not already Confirmed');

      // When: the painter saves the mix as confirmed (E29).
      await h.whenSaveConfirmed(); // LOOP-6

      // Then: the value is promoted to Confirmed — you measured this, with a
      // note recording it was confirmed after the painter photographed their
      // own swatch, and the measured swatch is kept as evidence and persisted.
      final saved = h.state.savedProvenance;
      expect(saved, isNotNull,
          reason: 'AC-9: saving records the promoted provenance (LOOP-6)');
      expect(saved!.tier, ProvenanceTier.confirmed,
          reason: 'AC-9: promoted to the Confirmed tier');
      // Robust to G-4(d) (the confirmed phrasing may live in the label or the
      // note): the painter-facing provenance conveys self-measurement.
      final rendered = '${saved.label} ${saved.note ?? ''}';
      expect(rendered, contains('Confirmed'),
          reason: 'AC-9: the value reads as Confirmed');
      expect(rendered, contains('you measured this'),
          reason: 'AC-9: the value reads "Confirmed — you measured this"');
      expect(saved.note, isNotNull,
          reason: 'AC-9: a note records how it was confirmed');
      expect(saved.note, contains('photograph'),
          reason: 'AC-9: the note records it was confirmed after the painter '
              'photographed their own swatch');
      final held = h.controller.savedSamples
          .where((s) => s.name == SAMPLE_DEEP_OLIVE.name)
          .toList();
      expect(held, isNotEmpty,
          reason: 'AC-9: the confirmed sample is persisted to the SampleSource '
              '(LOOP-6)');
      expect(held.single.provenance.tier, ProvenanceTier.confirmed,
          reason: 'AC-9: the persisted sample carries the Confirmed tier');
      expect(held.single.evidence.map((e) => e.coordinates),
          contains(swatch.coordinates),
          reason: 'AC-9: the measured swatch is appended as evidence');

      // Control (honest-provenance rule, D-8): saving without a photographed
      // swatch does not promote anything.
      final h2 = await givenCorrection(tester, scene: SCENE_CLOSE);
      await h2.whenSaveConfirmed(); // no check first
      expect(h2.state.savedProvenance, isNull,
          reason: 'AC-9 control: no promotion without the painter photographing '
              'their own swatch');
    });

    acTestWidgets(
        'AC-10',
        'TestAC10_ConfirmedInReadout — a confirmed value carries its Confirmed '
            'provenance into a later readout', (tester) async {
      // Given: the painter saved a confirmed mix for Deep Olive Green (AC-9
      // flow), so the SampleSource holds the confirmed value.
      final h = await givenCorrection(tester, scene: SCENE_CLOSE);
      await h.whenCheck();
      await h.whenSaveConfirmed();
      final held = h.controller.savedSamples
          .where((s) =>
              s.name == SAMPLE_DEEP_OLIVE.name &&
              s.provenance.tier == ProvenanceTier.confirmed)
          .toList();
      expect(held, isNotEmpty,
          reason: 'AC-10 Given: a confirmed Deep Olive Green mix is saved '
              '(LOOP-6)');
      final confirmed = held.single;

      // When: that value is shown in a later readout (router.toReadout).
      await _showInLaterReadout(tester, confirmed);

      // Then: the later Readout's provenance region carries the Confirmed
      // phrasing and its note — not the pre-confirmation provenance.
      expect(find.widgetWithText(AppBar, 'Readout'), findsOneWidget,
          reason: 'AC-10: a later Readout is shown');
      final provenanceText =
          _plainTextUnder(tester, ProvenanceRegion.regionKey);
      expect(provenanceText, contains('Confirmed'),
          reason: 'AC-10: the readout states Confirmed, not the old tier');
      expect(provenanceText, contains('you measured this'),
          reason: 'AC-10: the readout carries the "you measured this" phrasing');
    });
  });

  group(
      'ITEST-3 — AC-2, AC-3, AC-4, AC-5, AC-6 (difference / correction detail)',
      () {
    acTestWidgets(
        'AC-2',
        'TestAC02_DeltaEAndVerdict — the difference is a ΔE00 with a plain '
            'verdict', (tester) async {
      // Given: a checked SCENE_OFF mix, so a difference reading is shown. The
      // reading is CORRECT-2's output; until then `whenCheck` is inert (LOOP-3),
      // so this precondition fails cleanly at the red baseline.
      final h = await givenCorrection(tester, scene: SCENE_OFF);
      await h.whenCheck(); // CORRECT-2 computes the difference reading
      final diff = h.state.difference;
      expect(diff, isNotNull,
          reason: 'AC-2 Given: the checked mix shows a difference (CORRECT-2)');
      final swatch = h.state.mixedSwatch;
      expect(swatch, isA<Sample>(),
          reason: 'AC-2 Given: a photographed swatch to compare');

      // When: the comparison is shown.
      // Then: the stated ΔE00 is the real swatch→target distance (graded against
      // the independent reference), and the plain verdict "noticeably off" is
      // rendered in the difference region (G-4b).
      expect(
          diff!.deltaE00,
          closeTo(
              referenceDeltaE00(
                  swatch!.coordinates, SAMPLE_DEEP_OLIVE.coordinates),
              0.1),
          reason: 'AC-2: the difference states the swatch→target ΔE00');
      expect(diff.verdict, 'noticeably off',
          reason: 'AC-2: a beyond-tolerance mix reads "noticeably off" (G-4b)');
      final shown = _plainTextUnder(tester, DifferenceRegion.regionKey);
      expect(shown, contains('noticeably off'),
          reason: 'AC-2: the verdict is rendered on the difference body');

      // LIMITED (augmented by CORRECT-4): one off-reading cannot show the verdict
      // *tracks* distance (a constant "noticeably off" would also pass here). The
      // decisive within-tolerance control ("very close") needs CORRECT-4's
      // tolerance verdict, so it is the TestAC02 augmentation. Grade: B pending
      // CORRECT-4.
    });

    acTestWidgets(
        'AC-3',
        'TestAC03_ValueLeadingDecomposition — the difference is decomposed and '
            'leads with value for a CVD painter', (tester) async {
      // Given: the SCENE_OFF checked mix (measured too dark, hue toward green vs
      // the target). The decomposition is CORRECT-2's; inert until then.
      final h = await givenCorrection(tester, scene: SCENE_OFF);
      await h.whenCheck(); // CORRECT-2 computes the value-leading decomposition
      final diff = h.state.difference;
      expect(diff, isNotNull,
          reason: 'AC-3 Given: the checked mix shows a difference (CORRECT-2)');
      final swatch = h.state.mixedSwatch;
      expect(swatch, isA<Sample>(),
          reason: 'AC-3 Given: a photographed swatch to decompose');

      // When: the comparison is shown.
      // Then: the leading reading is value ("too dark by N"), then hue ("toward
      // green") — value first for a CVD painter (D-5).
      final expectedDarkBy =
          (SAMPLE_DEEP_OLIVE.coordinates.lightness - swatch!.coordinates.lightness)
              .round();
      expect(expectedDarkBy, greaterThan(0),
          reason: 'AC-3 Given: SCENE_OFF really is darker than the target');
      expect(diff!.valueReading.toLowerCase(), contains('dark'),
          reason: 'AC-3: states "too dark" (not "too light") — the right sign');
      expect(diff.valueReading, contains('$expectedDarkBy'),
          reason: 'AC-3: states "too dark by $expectedDarkBy" (the L* gap)');
      expect(diff.hueReading.toLowerCase(), contains('green'),
          reason: 'AC-3: the hue reading is "shifted toward green"');

      // Value leads hue in the rendered body (the CVD-first ordering, D-5).
      final shown = _plainTextUnder(tester, DifferenceRegion.regionKey);
      final valueAt = shown.toLowerCase().indexOf('dark');
      final hueAt = shown.toLowerCase().indexOf('green');
      expect(valueAt, greaterThanOrEqualTo(0),
          reason: 'AC-3: the value reading is rendered');
      expect(hueAt, greaterThan(valueAt),
          reason: 'AC-3: value leads, hue follows (value-first for a CVD '
              'painter)');
    });

    acTestWidgets(
        'AC-4',
        'TestAC04_ConcreteCorrection — a concrete correction names the paint '
            'and the amount to add', (tester) async {
      // Given: the SCENE_OFF checked mix + RECIPE_DEEP_OLIVE + "My paints". The
      // correction is CORRECT-3's; inert until then.
      final h = await givenCorrection(tester, scene: SCENE_OFF);
      await h.whenCheck(); // CORRECT-3 computes the concrete correction
      final correction = h.state.correction;
      expect(correction, isNotNull,
          reason: 'AC-4 Given: the checked mix yields a correction (CORRECT-3)');
      expect(correction!.isEmpty, isFalse,
          reason: 'AC-4 Given: SCENE_OFF is off enough to need a correction');

      // When: the correction is shown.
      // Then: it names Titanium White (the "too dark" fix) with a positive
      // amount, rendered, and every addition is drawn from the owned palette.
      final whiteAdds =
          correction.additions.where((a) => a.paint.name == 'Titanium White');
      expect(whiteAdds, hasLength(1),
          reason: 'AC-4: the correction names Titanium White to lift the value');
      expect(whiteAdds.single.parts, greaterThan(0),
          reason: 'AC-4: a positive amount of white to add (≈ one part more)');
      final shown = _plainTextUnder(tester, CorrectionRegion.regionKey);
      expect(shown, contains('Titanium White'),
          reason: 'AC-4: the paint to add is rendered');
      final paletteIds = PALETTE_MY_PAINTS.paints.map((p) => p.id).toSet();
      for (final a in correction.additions) {
        expect(paletteIds, contains(a.paint.id),
            reason: 'AC-4: ${a.paint.name} must be a paint from "My paints"');
      }

      // In-test forward-model control (D-10): applying the suggested additions to
      // the current mix and re-running the real forward model must move the
      // prediction *closer* to the target — rejecting a darkening paint or an
      // addition that increases ΔE00. K/S mixing is scale-invariant, so comparing
      // the base mix against base+additions reads the true physical effect.
      const engine = SubtractiveMixingEngine();
      final target = SAMPLE_DEEP_OLIVE.coordinates;
      final baseParts = <Paint, double>{
        for (final c in RECIPE_DEEP_OLIVE.components) c.paint: c.partsFraction,
      };
      final before = referenceDeltaE00(engine.forward(baseParts), target);
      final adjusted = Map<Paint, double>.from(baseParts);
      for (final a in correction.additions) {
        adjusted[a.paint] = (adjusted[a.paint] ?? 0) + a.parts;
      }
      final after = referenceDeltaE00(engine.forward(adjusted), target);
      expect(after, lessThan(before),
          reason: 'AC-4: adding the correction moves the forward-predicted mix '
              'closer to the target (not a darkening/ΔE-increasing paint)');
    });

    acTestWidgets(
        'AC-5',
        'TestAC05_TouchOf — a small correction is expressed as "a touch of"',
        (tester) async {
      // Given: a checked SCENE_OCHRE_TRACE mix whose best correction is a
      // sub-trace Yellow Ochre addition. The correction is CORRECT-3's; inert
      // until then.
      final h = await givenCorrection(tester, scene: SCENE_OCHRE_TRACE);
      await h.whenCheck(); // CORRECT-3 computes the trace correction
      final correction = h.state.correction;
      expect(correction, isNotNull,
          reason: 'AC-5 Given: the checked mix yields a correction (CORRECT-3)');
      expect(correction!.isEmpty, isFalse,
          reason: 'AC-5 Given: SCENE_OCHRE_TRACE needs a small correction');
      final ochre =
          correction.additions.where((a) => a.paint.name == 'Yellow Ochre');
      expect(ochre, hasLength(1),
          reason: 'AC-5 Given: the fix is a Yellow Ochre addition');
      expect(ochre.single.parts, lessThan(0.02),
          reason: 'AC-5 Given: the ochre addition is sub-trace (< 2% by volume, '
              'the G-4c trace threshold)');

      // When: the correction is shown.
      // Then: the ochre adjustment renders "a touch of" + a technique note — not
      // a measured part, and not silently dropped.
      expect(ochre.single.isTrace, isTrue,
          reason: 'AC-5: the sub-trace addition is flagged a trace');
      expect(ochre.single.techniqueNote, isNotNull,
          reason: 'AC-5: a technique note accompanies the trace (D-7)');
      final shown = _plainTextUnder(tester, CorrectionRegion.regionKey);
      expect(shown.toLowerCase(), contains('a touch of'),
          reason: 'AC-5: the trace renders "a touch of", not a numeric part');
      expect(shown, contains('Yellow Ochre'),
          reason: 'AC-5: the touch names Yellow Ochre');
    });

    acTestWidgets(
        'AC-6',
        'TestAC06_WithinTolerance — a mix already within tolerance needs no '
            'correction', (tester) async {
      // Given: a checked SCENE_CLOSE mix sitting within ΔE00 tolerance of the
      // target. The within-tolerance verdict/suppression is CORRECT-4's; inert
      // until then.
      final h = await givenCorrection(tester, scene: SCENE_CLOSE);
      await h.whenCheck(); // CORRECT-4 sets within-tolerance + suppresses
      final diff = h.state.difference;
      expect(diff, isNotNull,
          reason: 'AC-6 Given: the checked mix shows a difference (CORRECT-4)');
      final swatch = h.state.mixedSwatch;
      expect(swatch, isA<Sample>(),
          reason: 'AC-6 Given: a photographed swatch to judge');
      expect(
          referenceDeltaE00(
              swatch!.coordinates, SAMPLE_DEEP_OLIVE.coordinates),
          lessThanOrEqualTo(kToleranceDeltaE00),
          reason: 'AC-6 Given: SCENE_CLOSE sits within ΔE00 2 of the target');

      // When: the comparison is shown (settle point: the check completed and the
      // screen rendered its within-tolerance state).
      // Then: the mix reads "very close", is flagged within tolerance, and NO
      // correction is offered — the correction region names no paint to add.
      expect(diff!.withinTolerance, isTrue,
          reason: 'AC-6: the mix is flagged within tolerance');
      expect(diff.verdict, 'very close',
          reason: 'AC-6: a within-tolerance mix reads "very close" (G-4b)');
      final correction = h.state.correction;
      expect(correction == null || correction.isEmpty, isTrue,
          reason: 'AC-6: no correction is suggested within tolerance');
      final correctionShown = _plainTextUnder(tester, CorrectionRegion.regionKey);
      for (final p in PALETTE_MY_PAINTS.paints) {
        expect(correctionShown, isNot(contains(p.name)),
            reason: 'AC-6: no paint to add (${p.name}) is rendered within '
                'tolerance');
      }
      final diffShown = _plainTextUnder(tester, DifferenceRegion.regionKey);
      expect(diffShown, contains('very close'),
          reason: 'AC-6: "very close" is rendered on the difference body');
    });
  });
}
