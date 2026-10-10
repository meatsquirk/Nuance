// Acceptance suite for bs-06 Palette and projects.
//
// DATA-1 (scaffold) landed the runner target with the pending-gate skeleton
// (`bs06/pending.dart`, all 11 ACs pending) and the integrity guards so the
// scaffold cannot pass vacuously. ITEST-1 adds the harness
// (`palette_harness.dart` — Given/When/Then vocabulary + fixtures + the
// independent deutan reference), a never-pending **smoke test** proving the
// shells wire end to end (the real app boots to the Palette screen and renders
// every region), and **fixture guards** so a later AC test can rely on the
// fixtures (the reviewed dataset carries the AC-2/AC-4 paints; the two palettes
// are disjoint; the Harbor project has the counts/note/photo its ACs assume;
// exactly one harbor sample pair is confusable for a deutan, graded against the
// harness's own independent projection; the file sink records).
//
// ITEST-2/3 register one *pending* `acTestWidgets` per AC here; the behaviour
// phases un-pend each by deleting its row in `bs06/pending.dart`. Default
// `flutter test integration_test/palette_test.dart -d <udid>` skips pending ACs;
// `--dart-define=BS06_RUN_PENDING=true` runs them (red baseline / un-pend run).
// A booted device udid is mandatory — without `-d` the run executes zero tests
// and still exits 0 (false green; carried flake).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/cvd/confusion_check.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/palette/paint_list_region.dart';
import 'package:paint_color_assistant/palette/palette_read_endpoint.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/palette/palette_selector_region.dart';
import 'package:paint_color_assistant/palette/projects_region.dart';
import 'package:paint_color_assistant/palette/provenance_legend_region.dart';
import 'package:paint_color_assistant/palette/vision_profile_card.dart';
import 'package:paint_color_assistant/projects/project_read_endpoint.dart';

import 'palette_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  // Smoke: the shells wire end to end (never pending).
  // -------------------------------------------------------------------------

  testWidgets(
    'smoke: the assembled app boots to the Palette screen showing every region',
    (tester) async {
      final harness = await givenPalette(tester);

      // Booted to the Palette route with both read endpoints mounted.
      expect(find.widgetWithText(AppBar, 'Palette'), findsOneWidget);
      expect(find.byKey(PaletteReadEndpoint.endpointKey), findsOneWidget);
      expect(find.byKey(ProjectReadEndpoint.endpointKey), findsOneWidget);

      // Every region anchor the AC finders and behaviour phases rely on — both
      // views' regions are present at once in the shell (SCREEN-1).
      expect(find.byKey(VisionProfileCard.regionKey), findsOneWidget);
      expect(find.byKey(PaletteScreen.viewSelectorKey), findsOneWidget);
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsOneWidget);
      expect(find.byKey(PaletteSelectorRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget);

      // Opened empty (no seeds): the shell's resting state, read through the
      // endpoints the ACs observe. Nothing spoken, no haptics, no navigation.
      expect(harness.myPaints, isEmpty);
      expect(harness.palettes, isEmpty);
      expect(harness.selectedPalette, isNull);
      expect(harness.projects, isEmpty);
      expect(harness.openedProject, isNull);
      expect(harness.confusionPairs, isEmpty);
      expect(harness.lastExport, isNull);
      expect(harness.selfAssessmentOpen, isFalse);
      expect(harness.speech.utterances, isEmpty);
      expect(harness.haptics.confirmations, 0);
    },
  );

  testWidgets(
    'smoke: seeded sources are read back through the endpoints',
    (tester) async {
      final harness = await givenPalette(
        tester,
        palettes: twoPalettes,
        projects: [harborProject],
        photos: {harborPhotoRef: harborPhotoBytes},
      );

      // The persistent sources, seeded through their public save flows and
      // loaded before assembly, surface through the controllers.
      expect(harness.palettes.map((p) => p.name), ['My paints', 'Travel set']);
      expect(harness.selectedPalette?.name, 'My paints'); // the first listed
      expect(harness.myPaints.map((p) => p.name),
          containsAll(<String>['Titanium White', 'Raw Umber']));
      expect(harness.projects.map((p) => p.name), ['Harbor at Dusk']);

      // The seeded source photo round-trips through the file sink, with no save
      // driven by the app itself.
      expect(await harness.photos.read(harborPhotoRef), harborPhotoBytes);
      expect(harness.photos.writes, 0);
    },
  );

  // -------------------------------------------------------------------------
  // Fixture guards (plain tests; always run) — no vacuous AC passes later.
  // -------------------------------------------------------------------------

  group('fixtures', () {
    test('reviewedDataset carries the AC-2 and AC-4 paints', () {
      final white = reviewedDataset.firstWhere((p) => p.name == 'Titanium White');
      expect(white.brand, 'Winsor & Newton');
      expect(white.line, "Artists' Oil");
      expect(white.medium, PaintMedium.oil);
      expect(white.pigmentIndex, 'PW6');
      expect(white.provenance, ProvenanceTier.measured);
      expect(
        reviewedDataset.any((p) => p.name == 'Ultramarine Blue'),
        isTrue,
        reason: 'AC-4 adds "Ultramarine Blue" from the reviewed dataset',
      );
    });

    test('twoPalettes are named "My paints"/"Travel set" and disjoint', () {
      expect(twoPalettes.map((p) => p.name), ['My paints', 'Travel set']);
      expect(PALETTE_MY_PAINTS.paints, isNotEmpty);
      expect(PALETTE_TRAVEL_SET.paints, isNotEmpty);
      final myIds = PALETTE_MY_PAINTS.paints.map((p) => p.id).toSet();
      final travelIds = PALETTE_TRAVEL_SET.paints.map((p) => p.id).toSet();
      expect(
        myIds.intersection(travelIds),
        isEmpty,
        reason: 'disjoint paints let AC-5 reveal which palette a solve used',
      );
    });

    test('harborProject has the counts, note and photo AC-6..AC-10 assume', () {
      final p = harborProject;
      expect(p.name, 'Harbor at Dusk');
      expect(p.size, '24×30 in');
      expect(p.samples.length, 6);
      expect(p.recipes.length, 3);
      expect(p.note, harborNote);
      expect(p.sourcePhotoRef, harborPhotoRef);
      expect(p.lastEdited, isNotNull);
      // 6 samples ≠ 3 recipes, so an AC-6 impl that swaps the counts is caught.
      expect(p.samples.length == p.recipes.length, isFalse);
    });

    test('exactly one harbor sample pair is confusable for a deutan (AC-9)', () {
      const shipped = DichromatConfusionCheck();
      final flagged = <String>{};
      for (var i = 0; i < harborSamples.length; i++) {
        for (var j = i + 1; j < harborSamples.length; j++) {
          final a = harborSamples[i], b = harborSamples[j];
          final byShipped =
              shipped.confusable(a.coordinates, b.coordinates, deutanDichromat);
          final byReference =
              referenceConfusable(a.coordinates, b.coordinates);
          // The shipped detector and the harness's independent projection agree
          // on every pair, so AC-9 is never graded against the detector it
          // checks.
          expect(byShipped, byReference,
              reason: 'shipped vs independent disagree on '
                  '"${a.name}"/"${b.name}"');
          if (byShipped) flagged.add('${a.name}/${b.name}');
        }
      }
      expect(flagged, {'Mid Raw Umber/Ultramarine Shadow'});
    });

    test('the confusion pair is a deutan collapse, not a plain near-match', () {
      const shipped = DichromatConfusionCheck();
      final a = SAMPLE_MID_RAW_UMBER.coordinates;
      final b = SAMPLE_ULTRAMARINE_SHADOW.coordinates;
      // Clearly different to normal vision (AC-9's "others can tell them apart").
      expect(referenceDeltaE00(a, b), greaterThan(10.0));
      // Flagged for the full deutan, but NOT for the moderate AC-11 profile —
      // the shipped detector fires only near full dichromacy (why AC-9 injects
      // deutanDichromat, not deutanModerate).
      expect(shipped.confusable(a, b, deutanDichromat), isTrue);
      expect(shipped.confusable(a, b, deutanModerate), isFalse);
      // Control: a clearly-distinct pair is never flagged.
      expect(
        shipped.confusable(a, SAMPLE_HULL_RED.coordinates, deutanDichromat),
        isFalse,
      );
    });

    test('the vision-profile fixtures are the deutan profiles their ACs name',
        () {
      expect(deutanModerate.type, CvdType.deutan);
      expect(deutanModerate.severity, 0.6); // AC-11 "moderate"
      expect(deutanDichromat.type, CvdType.deutan);
      expect(deutanDichromat.severity, 1.0); // AC-9 full collapse
    });

    test('FakeFileSink records saves and round-trips; seed does not count',
        () async {
      final sink = FakeFileSink();
      expect(sink.writes, 0);
      sink.seed('seeded', harborPhotoBytes);
      expect(sink.writes, 0, reason: 'seed() pre-stores without a save');
      expect(await sink.read('seeded'), harborPhotoBytes);

      final ref = await sink.save(harborPhotoBytes);
      expect(sink.writes, 1);
      expect(sink.saved, [ref]);
      expect(await sink.read(ref), harborPhotoBytes);
    });
  });

  // -------------------------------------------------------------------------
  // Pending-gate scaffold guards (from DATA-1) — kept so the gate stays honest.
  // -------------------------------------------------------------------------

  group('bs-06 pending gate (scaffold guard)', () {
    test('pending map covers exactly AC-1..AC-11', () {
      final expected = {for (var i = 1; i <= 11; i++) 'AC-$i'};
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-06 '
              'behaviour phase',
        );
      }
    });

    test('pendingSkipReason skips a pending AC by default, runs it when forced',
        () {
      expect(pendingSkipReason('AC-1'), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An AC absent from the map (un-pended) always runs.
      expect(pendingSkipReason('AC-999'), isNull);
    });
  });
}
