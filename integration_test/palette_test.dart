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
import 'package:paint_color_assistant/recipes/palette.dart';

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
  // AC tests (ITEST-2) — paints, palette, vision card.
  //
  // One *pending* `acTestWidgets` per AC in this phase's set (AC-1, 2, 3, 4, 5,
  // 11), wired to the pending gate: the default run skips them (suite stays
  // green); `--dart-define=BS06_RUN_PENDING=true` runs them for the red baseline
  // and, as each behaviour phase lands, its un-pend run. Every Given is built
  // through a public flow — seeded through the persistent save flows in
  // `givenPalette`, or driven by an E-control `when…` — then checked before the
  // When; the When goes through a real control; the Then asserts tightly enough
  // that a wrong implementation fails. Owners: AC-1 → SCREEN-2, AC-2/AC-3 →
  // PALETTE-3, AC-4 → PALETTE-2, AC-5 → PALETTE-4, AC-11 → SCREEN-3.
  // -------------------------------------------------------------------------

  group('palette ACs (ITEST-2)', () {
    // AC-1 — switch between the My paints and Projects views (owner SCREEN-2).
    acTestWidgets('AC-1', 'switch between the My paints and Projects views',
        (tester) async {
      // Given the Palette screen is showing My paints.
      final harness = await givenPalette(tester, palettes: twoPalettes);
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget,
          reason: 'the My paints view is shown to begin with');

      // When the painter switches to Projects.
      await harness.whenSwitchToProjects();

      // Then the saved projects are shown *instead of* the paints: the Projects
      // region is present AND the paint list is gone (not both at once).
      expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget,
          reason: 'the Projects view is shown after switching');
      expect(find.byKey(PaintListRegion.regionKey), findsNothing,
          reason: 'the paints are hidden — shown *instead of*, not alongside '
              '(rejects a toggle that shows both; SCREEN-2)');

      // Control: switching back restores My paints and hides Projects, so the
      // reading is shown to change both ways (not a one-way or stuck toggle).
      await harness.whenSwitchToMyPaints();
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsNothing);
    });

    // AC-2 — each paint lists its identity and provenance badge (owner
    // PALETTE-3). Limited at this phase: the badge can only be asserted as
    // present/"Measured" until PALETTE-3 renders the real tier — the exact-tier
    // control (a differently-tiered paint) is the PALETTE-3 augmentation. Graded
    // *B pending PALETTE-3*.
    acTestWidgets(
        'AC-2', 'each paint lists its identity and provenance badge',
        (tester) async {
      // Given the My paints palette contains "Titanium White" by Winsor &
      // Newton, Artists' Oil, pigment PW6, read with a spectrophotometer
      // (Measured) — seeded through the persistent save flow.
      final titaniumWhite =
          reviewedDataset.firstWhere((p) => p.name == 'Titanium White');
      final harness = await givenPalette(
        tester,
        palettes: [
          PaintPalette(name: 'My paints', paints: [titaniumWhite]),
        ],
      );
      // Given check (through the read endpoint): the paint is in My paints with
      // the full identity the row must render.
      expect(harness.myPaints.map((p) => p.name), ['Titanium White']);
      final white = harness.myPaints.single;
      expect(white.brand, 'Winsor & Newton');
      expect(white.line, "Artists' Oil");
      expect(white.medium, PaintMedium.oil);
      expect(white.pigmentIndex, 'PW6');
      expect(white.provenance, ProvenanceTier.measured);

      // When the My paints list is shown (it is, after givenPalette).
      // Then "Titanium White" is listed with its brand, line, medium and
      // pigment index, AND carries the provenance "Measured" — not colour alone.
      Finder inPaintList(Finder m) => find.descendant(
            of: find.byKey(PaintListRegion.regionKey),
            matching: m,
          );
      expect(inPaintList(find.textContaining('Titanium White')), findsWidgets);
      expect(inPaintList(find.textContaining('Winsor & Newton')), findsWidgets,
          reason: 'the brand is shown on the row');
      expect(inPaintList(find.textContaining("Artists' Oil")), findsWidgets,
          reason: 'the line is shown on the row');
      expect(inPaintList(find.textContaining('Oil')), findsWidgets,
          reason: 'the medium is shown on the row');
      expect(inPaintList(find.textContaining('PW6')), findsWidgets,
          reason: 'the pigment index is shown on the row');
      expect(inPaintList(find.textContaining('Measured')), findsWidgets,
          reason: 'the provenance badge is shown (not colour alone) — '
              'PALETTE-3 adds the exact-tier control via its augmentation');
    });

    // AC-3 — the provenance legend explains the four confidence tiers (owner
    // PALETTE-3).
    acTestWidgets(
        'AC-3', 'the provenance legend explains the four confidence tiers',
        (tester) async {
      // Given the My paints list is shown with the legend region present.
      final harness = await givenPalette(tester, palettes: twoPalettes);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsOneWidget);
      // (reference the harness so the lint does not flag it unused)
      expect(harness.myPaints, isNotEmpty);

      // When the provenance legend is shown.
      // Then it explains all four tiers, by their exact spec strings.
      Finder inLegend(Finder m) => find.descendant(
            of: find.byKey(ProvenanceLegendRegion.regionKey),
            matching: m,
          );
      expect(inLegend(find.textContaining('Measured')), findsWidgets);
      expect(inLegend(find.textContaining('Calculated')), findsWidgets);
      expect(inLegend(find.textContaining('Estimated — not yet verified')),
          findsWidgets);
      expect(inLegend(find.textContaining('Confirmed — you measured this')),
          findsWidgets);
    });

    // AC-4 — add a paint by choosing from the shipped dataset (owner PALETTE-2).
    acTestWidgets(
        'AC-4', 'add a paint by choosing from the shipped dataset',
        (tester) async {
      // Given the painter is adding a paint to the My paints palette — My paints
      // starts empty so the add is observable.
      final harness = await givenPalette(
        tester,
        palettes: const [PaintPalette(name: 'My paints')],
      );
      expect(harness.myPaints, isEmpty);
      await harness.whenAddPaint();
      // Given precondition (PALETTE-2 wires the E32 picker): the reviewed
      // dataset is offered, listing "Ultramarine Blue" to choose.
      expect(
        find.textContaining('Ultramarine Blue'),
        findsWidgets,
        reason: 'the add-paint flow must offer the reviewed dataset to choose '
            'from (PALETTE-2 wires E32, AC-4)',
      );

      // When the painter chooses "Ultramarine Blue" from the reviewed dataset.
      await tester.tap(find.textContaining('Ultramarine Blue').first);
      await tester.pumpAndSettle();

      // Then it is added to the palette with its dataset provenance preserved —
      // the exact reviewed-dataset paint, not a free-hand or blanked value.
      final ultramarine =
          reviewedDataset.firstWhere((p) => p.name == 'Ultramarine Blue');
      final added =
          harness.myPaints.where((p) => p.name == 'Ultramarine Blue');
      expect(added, hasLength(1), reason: 'Ultramarine Blue is added');
      expect(added.single, equals(ultramarine),
          reason: 'the exact dataset paint is added — provenance, pigment index '
              'and masstone preserved (rejects a free-hand/blanked value)');
      expect(added.single.provenance, ultramarine.provenance,
          reason: 'dataset provenance preserved on add');
    });

    // AC-5 — selecting a palette makes recipes solve against it (owner
    // PALETTE-4). Limited at this phase: no recipe surface is mounted on the
    // Palette screen until PALETTE-4, so only the active-palette re-point is
    // asserted here; the "every recipe's paints ⊆ the selected palette" control
    // is the PALETTE-4 augmentation. Graded *B pending PALETTE-4*.
    acTestWidgets(
        'AC-5', 'selecting a palette re-points recipe search at it',
        (tester) async {
      // Given the painter has palettes "My paints" and "Travel set" (disjoint
      // paints), the first listed active to begin with.
      final harness = await givenPalette(tester, palettes: twoPalettes);
      expect(harness.palettes.map((p) => p.name), ['My paints', 'Travel set']);
      expect(harness.selectedPalette?.name, 'My paints',
          reason: 'the first listed palette is active to begin with');

      // When the painter selects "Travel set" as the active palette.
      await harness.whenSelectPalette('Travel set');

      // Then recipe search solves only against "Travel set": the active palette
      // re-points to it (rejects an impl that ignores selection / stays on My
      // paints). The "recipes ⊆ Travel set" control arrives with PALETTE-4.
      expect(harness.selectedPalette?.name, 'Travel set');
      expect(
        harness.selectedPalette?.paints.map((p) => p.id).toSet(),
        PALETTE_TRAVEL_SET.paints.map((p) => p.id).toSet(),
        reason: 'the active palette is the disjoint Travel set, not My paints',
      );
    });

    // AC-11 — the vision-profile card shows the current estimate and opens the
    // self-assessment (owner SCREEN-3).
    acTestWidgets(
        'AC-11', 'the vision-profile card shows the estimate and opens '
            'the self-assessment',
        (tester) async {
      // Given the painter's vision profile is estimated as deutan-type, moderate
      // (the suite default `deutanModerate`).
      final harness = await givenPalette(tester);
      expect(find.byKey(VisionProfileCard.regionKey), findsOneWidget);
      expect(harness.selfAssessmentOpen, isFalse,
          reason: 'the self-assessment is not open to begin with');

      // Then the current estimate is shown on the card.
      expect(
        find.descendant(
          of: find.byKey(VisionProfileCard.regionKey),
          matching: find.textContaining('deutan-type, moderate'),
        ),
        findsWidgets,
        reason: 'the card shows the current estimate "deutan-type, moderate" '
            '(SCREEN-3 reads the injected CvdProfile)',
      );

      // When the painter chooses to retake the self-assessment from the card.
      await harness.whenRetakeAssessment();

      // Then the CVD self-assessment is opened.
      expect(harness.selfAssessmentOpen, isTrue,
          reason: 'retake navigates to the CVD self-assessment entry '
              '(SCREEN-3, bs-07 placeholder route)');
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
      // Assert both modes deterministically via `forceRunPending`, not the
      // ambient `runPending`: this guard runs in *both* the default and the
      // run-pending passes, and a pending AC's default-skip is null-reason only
      // when not forced. (Reading the ambient mode made this fail under
      // --dart-define=BS06_RUN_PENDING=true; ITEST-2 records the fix.)
      expect(pendingSkipReason('AC-1', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
      // An AC absent from the map (un-pended) always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
    });
  });
}
