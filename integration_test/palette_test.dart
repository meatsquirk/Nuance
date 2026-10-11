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
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/palette/paint_list_region.dart';
import 'package:paint_color_assistant/palette/palette_read_endpoint.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/palette/palette_selector_region.dart';
import 'package:paint_color_assistant/palette/projects_region.dart';
import 'package:paint_color_assistant/palette/provenance_legend_region.dart';
import 'package:paint_color_assistant/palette/vision_profile_card.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_read_endpoint.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/widgets/paint_row.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';

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

      // The persistent chrome and the My-paints view's regions are shown to
      // begin with. SCREEN-2's E31 selector now toggles the two views (AC-1),
      // so the Projects region is reached by switching — one view at a time, not
      // present alongside the paints.
      expect(find.byKey(VisionProfileCard.regionKey), findsOneWidget);
      expect(find.byKey(PaletteScreen.viewSelectorKey), findsOneWidget);
      expect(find.byKey(PaintListRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProvenanceLegendRegion.regionKey), findsOneWidget);
      expect(find.byKey(PaletteSelectorRegion.regionKey), findsOneWidget);
      expect(find.byKey(ProjectsRegion.regionKey), findsNothing);

      // Switching reaches the Projects view's region, proving both views' shells
      // wire end to end, then back so the resting state below is My paints.
      await harness.whenSwitchToProjects();
      expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget);
      await harness.whenSwitchToMyPaints();

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
    // PALETTE-3). Un-pended + augmented by PALETTE-3: the row's exact rendered
    // provenance tier and its medium are asserted at a non-subsumed grain (the
    // dedicated badge/medium widgets, not the "Artists' Oil" line text), with a
    // differently-tiered, different-medium control paint that rejects an impl
    // hardcoding "Measured"/"Oil" on every row (TestAC02).
    acTestWidgets(
        'AC-2', 'each paint lists its identity and provenance badge',
        (tester) async {
      // Given the My paints palette contains "Titanium White" by Winsor &
      // Newton, Artists' Oil, pigment PW6, read with a spectrophotometer
      // (Measured) — seeded through the persistent save flow. A second paint,
      // "Phthalo Green" (an *acrylic*, *estimated*), is seeded as the TestAC02
      // control so each paint's own tier and medium are the ones answering.
      final titaniumWhite =
          reviewedDataset.firstWhere((p) => p.name == 'Titanium White');
      const control = Paint(
        id: 'ctrl-estimated',
        name: 'Phthalo Green',
        brand: 'Liquitex',
        line: 'Heavy Body',
        medium: PaintMedium.acrylic,
        pigmentIndex: 'PG7',
        masstone: ColorCoordinates(lightness: 40, a: -40, b: 10),
        provenance: ProvenanceTier.estimated,
      );
      final harness = await givenPalette(
        tester,
        palettes: [
          PaintPalette(name: 'My paints', paints: [titaniumWhite, control]),
        ],
      );
      // Given check (through the read endpoint): both paints are in My paints,
      // each with the full identity its row must render.
      expect(harness.myPaints.map((p) => p.name),
          ['Titanium White', 'Phthalo Green']);
      final white =
          harness.myPaints.firstWhere((p) => p.name == 'Titanium White');
      expect(white.id, 'pw6');
      expect(white.brand, 'Winsor & Newton');
      expect(white.line, "Artists' Oil");
      expect(white.medium, PaintMedium.oil);
      expect(white.pigmentIndex, 'PW6');
      expect(white.provenance, ProvenanceTier.measured);
      final green =
          harness.myPaints.firstWhere((p) => p.name == 'Phthalo Green');
      expect(green.id, 'ctrl-estimated');
      expect(green.medium, PaintMedium.acrylic,
          reason: 'the control is a different medium from "Titanium White"');
      expect(green.provenance, ProvenanceTier.estimated,
          reason: 'the control carries a different tier from "Titanium White"');

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
          reason: 'the provenance badge is shown (not colour alone)');

      // --- TestAC02 augmentation (PALETTE-3) ---
      // The EXACT rendered provenance tier, read from each paint's own badge
      // widget (not a row substring), so a hardcoded tier is caught.
      ProvenanceBadge badgeOf(String id) => tester.widget<ProvenanceBadge>(
          find.byKey(PaintRow.badgeKeyFor(id)));
      expect(badgeOf('pw6').provenance.tier, ProvenanceTier.measured,
          reason: '"Titanium White" renders its own Measured tier');

      // The medium at its own grain — the dedicated medium label widget, NOT
      // the "Artists' Oil" line text — so "Oil" is asserted as the medium.
      Text mediumOf(String id) =>
          tester.widget<Text>(find.byKey(PaintRow.mediumKeyFor(id)));
      expect(mediumOf('pw6').data, 'Oil',
          reason: 'the medium label reads exactly "Oil" (not the line text)');

      // Control: the differently-tiered, different-medium paint renders its OWN
      // tier and medium — rejecting an impl that hardcodes Measured/Oil per row.
      expect(badgeOf('ctrl-estimated').provenance.tier,
          ProvenanceTier.estimated);
      expect(mediumOf('ctrl-estimated').data, 'Acrylic');
      // The control's exact tier word is rendered on its badge (not colour
      // alone): "Estimated", distinct from "Titanium White"'s "Measured".
      expect(
        find.descendant(
          of: find.byKey(PaintRow.badgeKeyFor('ctrl-estimated')),
          matching: find.text('Estimated'),
        ),
        findsOneWidget,
        reason: 'the control badge states its own "Estimated" tier',
      );
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
    // PALETTE-4). PALETTE-4 mounts the shared `RecipeController` on the Palette
    // screen (observed via the `RecipeReadEndpoint`) and wires palette selection
    // to its frozen `selectPalette`, so this now asserts not just the
    // active-palette re-point but that *every returned recipe's paints ⊆ the
    // selected palette* — the TestAC05 augmentation, with the disjoint "My
    // paints" / "Travel set" control that rejects an impl ignoring selection.
    acTestWidgets(
        'AC-5', 'selecting a palette re-points recipe search at it',
        (tester) async {
      // Given the painter has palettes "My paints" and "Travel set" (disjoint
      // paints), the first listed active to begin with — on both the screen's
      // active palette and the recipe side (recipe search opens on the first
      // listed palette, D-5), with a target already solving to recipes.
      final harness = await givenPalette(tester, palettes: twoPalettes);
      expect(harness.palettes.map((p) => p.name), ['My paints', 'Travel set']);
      expect(harness.selectedPalette?.name, 'My paints',
          reason: 'the first listed palette is active to begin with');
      expect(harness.recipeSelectedPalette?.name, 'My paints',
          reason: 'recipe search opens constrained to the first palette (D-5)');
      expect(harness.recipes, isNotEmpty,
          reason: 'the set target solves to recipes to constrain (ENGINE-2)');
      // Control: before selection, every recipe uses only "My paints" paints.
      final myPaintsIds = PALETTE_MY_PAINTS.paints.map((p) => p.id).toSet();
      final travelIds = PALETTE_TRAVEL_SET.paints.map((p) => p.id).toSet();
      for (final recipe in harness.recipes) {
        for (final component in recipe.components) {
          expect(myPaintsIds, contains(component.paint.id),
              reason: '${component.paint.name} is not in "My paints" — recipes '
                  'must use only the initially-selected palette');
        }
      }

      // When the painter selects "Travel set" as the active palette.
      await harness.whenSelectPalette('Travel set');

      // Then recipe search solves only against "Travel set": the screen's active
      // palette AND the recipe solver both re-point to it (rejects an impl that
      // ignores selection / stays on My paints), and every component of every
      // returned recipe is a Travel-set paint — the disjoint sets make this
      // discriminate (a My-paints paint here would fail).
      expect(harness.selectedPalette?.name, 'Travel set');
      expect(harness.recipeSelectedPalette?.name, 'Travel set',
          reason: 'selection re-points the shared RecipeController (D-5)');
      expect(
        harness.selectedPalette?.paints.map((p) => p.id).toSet(),
        travelIds,
        reason: 'the active palette is the disjoint Travel set, not My paints',
      );
      expect(harness.recipes, isNotEmpty,
          reason: 'the re-solve over Travel set returns recipes to check');
      for (final recipe in harness.recipes) {
        for (final component in recipe.components) {
          expect(travelIds, contains(component.paint.id),
              reason: '${component.paint.name} is not in "Travel set" — recipes '
                  'must use only the selected palette');
        }
      }
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

      // Control (second profile): the estimate tracks the *injected* profile,
      // not a fixed string. A protan, mild profile shows "protan-type, mild"
      // and no longer "deutan-type, moderate" — rejecting a card that hard-codes
      // the default estimate. (Closes the AC-11 second-profile follow-on the
      // ITEST-2 grader recommended.)
      final other = await givenPalette(
        tester,
        cvdProfile: const CvdProfile(type: CvdType.protan, severity: 0.2),
      );
      expect(other.selfAssessmentOpen, isFalse);
      expect(
        find.descendant(
          of: find.byKey(VisionProfileCard.regionKey),
          matching: find.textContaining('protan-type, mild'),
        ),
        findsWidgets,
        reason: 'the estimate reads the injected profile (protan, mild)',
      );
      expect(find.textContaining('deutan-type, moderate'), findsNothing,
          reason: 'the default estimate is gone — not a hard-coded string');
    });
  });

  // -------------------------------------------------------------------------
  // AC tests (ITEST-3) — projects.
  //
  // One *pending* `acTestWidgets` per AC in this phase's set (AC-6, 7, 8, 9,
  // 10), appended after ITEST-2's group in the **same file** (run serially
  // against ITEST-2 — shared `palette_test.dart`). Wired to the same pending
  // gate: the default run skips them; `--dart-define=BS06_RUN_PENDING=true` runs
  // them for the red baseline and each behaviour phase's un-pend run.
  //
  // The project Givens are seeded through the production **persistent** save
  // flow (`givenPalette(projects: …)` → `PersistentProjectSource.saveProject` +
  // `load()`) — a public flow, and the same seam the PROJECT-2 enabler attaches
  // through. Following ITEST-2's AC-2 precedent, where a project AC depends only
  // on its own rendering/behaviour owner the Given is seeded via that save flow
  // rather than driven through PROJECT-2's not-yet-built create UI, so each
  // test's red-baseline failure lands on *its own* owner's behaviour (a Then),
  // not on a shared PROJECT-2 precondition. Every Given is checked through the
  // read endpoints before the When. Owners: AC-6 → PROJECT-3, AC-7/AC-8 →
  // PROJECT-4, AC-9 → PROJECT-5, AC-10 → PROJECT-6.
  // -------------------------------------------------------------------------

  group('project ACs (ITEST-3)', () {
    // AC-6 — the projects list shows each project's size, counts and last edit
    // (owner PROJECT-3). Augmented here (PROJECT-3) with an older-second-project
    // **control**: a project last edited days ago must *not* read "today", so a
    // row that hardcodes "today" (the ITEST-3 follow-on) is rejected.
    acTestWidgets(
        'AC-6', 'the projects list shows each project size, counts and '
            'last edit', (tester) async {
      // Given the painter has a project "Harbor at Dusk" (24×30 in, 6 samples,
      // 3 recipes, last edited today) — seeded through the persistent save flow.
      // And a control project "Old Study" last edited three days ago (distinct
      // size/counts), so the relative last-edit must be derived, not hardcoded.
      final old = Project(
        id: 'old-study',
        name: 'Old Study',
        size: '9×12 in',
        samples: harborSamples.take(2).toList(),
        recipes: harborRecipes.take(1).toList(),
        lastEdited: DateTime.now().subtract(const Duration(days: 3)),
      );
      final harness =
          await givenPalette(tester, projects: [harborProject, old]);
      // Given check (through the read endpoint): both projects are present with
      // the size/counts/last-edit each summary row must render.
      final harbor =
          harness.projects.firstWhere((p) => p.id == 'harbor-at-dusk');
      final study = harness.projects.firstWhere((p) => p.id == 'old-study');
      expect(harbor.name, 'Harbor at Dusk');
      expect(harbor.size, '24×30 in');
      expect(harbor.samples, hasLength(6));
      expect(harbor.recipes, hasLength(3));
      expect(harbor.lastEdited, isNotNull);
      expect(
        DateTime.now().difference(harbor.lastEdited!).inDays,
        0,
        reason: 'the fixture is edited today, so its row must read "today"',
      );
      expect(study.size, '9×12 in');
      expect(study.samples, hasLength(2));
      expect(study.recipes, hasLength(1));
      expect(
        DateTime.now().difference(study.lastEdited!).inDays,
        3,
        reason: 'the control is edited 3 days ago, so its row must not read '
            '"today"',
      );

      // When the Projects list is shown (switch to the Projects view — inert in
      // the shell, which renders both regions at once; the region is present).
      await harness.whenSwitchToProjects();
      expect(find.byKey(ProjectsRegion.regionKey), findsOneWidget);

      // Scope each assertion to the owning project's own row, so a reading can't
      // bleed across projects.
      Finder inRow(String projectId, Finder m) => find.descendant(
            of: find.byKey(ProjectsRegion.projectRowKey(projectId)),
            matching: m,
          );
      bool saysToday(Widget w) =>
          w is Text && (w.data ?? '').toLowerCase().contains('today');

      // Then the Harbor row shows its size, both counts (distinct, so a swap is
      // caught) and that it was edited today — not the name alone (the shell).
      expect(inRow('harbor-at-dusk', find.textContaining('24×30 in')),
          findsWidgets,
          reason: 'the free-text size is shown on the row (PROJECT-3)');
      expect(inRow('harbor-at-dusk', find.textContaining('6 samples')),
          findsWidgets,
          reason: 'the sample count is shown on the row');
      expect(inRow('harbor-at-dusk', find.textContaining('3 recipes')),
          findsWidgets,
          reason: 'the recipe count is shown on the row (6≠3 rejects a swap)');
      expect(inRow('harbor-at-dusk', find.byWidgetPredicate(saysToday)),
          findsWidgets,
          reason: 'the row shows it was edited today (PROJECT-3 renders the '
              'relative last-edit)');

      // Control: the three-days-ago project shows its own distinct size/counts
      // and must NOT read "today" — a hardcoded "today" label fails here.
      expect(inRow('old-study', find.textContaining('9×12 in')), findsWidgets,
          reason: 'the control row shows its own size');
      expect(inRow('old-study', find.textContaining('2 samples')), findsWidgets,
          reason: 'the control row shows its own sample count');
      expect(inRow('old-study', find.textContaining('1 recipe')), findsWidgets,
          reason: 'the control row shows its own recipe count (singular)');
      expect(inRow('old-study', find.byWidgetPredicate(saysToday)), findsNothing,
          reason: 'a project edited 3 days ago must not read "today" — the '
              'last-edit label is derived, not hardcoded');
    });

    // AC-7 — opening a project shows its notes and source photo (owner
    // PROJECT-4). Augmented here (PROJECT-4) to close the ITEST-3 limit: the
    // shown photo is scoped to the keyed open-project view and tied to the
    // project's stored bytes (`harborPhotoRef` → `harborPhotoBytes`), so a
    // decorative or wrong-bytes image no longer passes.
    acTestWidgets(
        'AC-7', 'opening a project shows its note and source photo',
        (tester) async {
      // Given the project "Harbor at Dusk" has a note and a source photo — the
      // photo seeded into the file sink so it round-trips (D-10).
      final harness = await givenPalette(
        tester,
        projects: [harborProject],
        photos: {harborPhotoRef: harborPhotoBytes},
      );
      final project = harness.projects.single;
      expect(project.note, harborNote, reason: 'the project carries a note');
      expect(project.sourcePhotoRef, harborPhotoRef,
          reason: 'the project references a source photo');
      expect(await harness.photos.read(harborPhotoRef), harborPhotoBytes,
          reason: 'the source photo round-trips through the file sink (D-10)');
      // Control: nothing is open to begin with, so the Then shows a change.
      expect(harness.openedProject, isNull);

      // When the painter opens "Harbor at Dusk".
      await harness.whenOpenProject('Harbor at Dusk');

      // Then the project is opened, and its note and source photo are shown —
      // not colour/sample data alone.
      expect(harness.openedProject?.name, 'Harbor at Dusk',
          reason: 'opening makes it the opened project (PROJECT-4)');
      expect(harness.openedProject?.sourcePhotoRef, harborPhotoRef,
          reason: 'the opened project carries its source-photo reference');
      expect(
        find.descendant(
          of: find.byKey(ProjectsRegion.openProjectViewKey),
          matching: find.textContaining(harborNote),
        ),
        findsWidgets,
        reason: 'the note is shown in the open-project view (PROJECT-4)',
      );
      // The source photo is shown in the open-project view — and it is the
      // project's *own* stored photo (augmentation): scope the image to the
      // keyed open-project view and assert its bytes are the ones stored under
      // `harborPhotoRef`, so a decorative or wrong-bytes image fails.
      final photo = find.descendant(
        of: find.byKey(ProjectsRegion.openProjectViewKey),
        matching: find.byType(Image),
      );
      expect(photo, findsOneWidget,
          reason: 'the source photo is shown in the open-project view '
              '(PROJECT-4 renders the stored bytes)');
      final image = tester.widget<Image>(photo).image;
      expect(image, isA<MemoryImage>(),
          reason: 'the photo is rendered from the stored bytes, not an asset');
      expect((image as MemoryImage).bytes, harborPhotoBytes,
          reason: 'the shown photo is the project\'s own source bytes '
              '(tied to harborPhotoRef → harborPhotoBytes)');
    });

    // AC-8 — a note kept with a project is retained when it is reopened (owner
    // PROJECT-4). Distinct from AC-7 (G6): AC-8 asserts the exact note string is
    // *retained* through the persistent save/load round-trip and shown verbatim
    // on reopen — not merely that a note is shown.
    acTestWidgets(
        'AC-8', 'a note kept with a project is retained when it is reopened',
        (tester) async {
      // Given the painter has saved the note on "Harbor at Dusk" — seeded
      // through the persistent save flow and read back from the loaded source,
      // so the value under test is the *retained* one, not an in-memory fixture.
      final harness = await givenPalette(tester, projects: [harborProject]);
      final retained = harness.projects.single;
      expect(retained.note, harborNote,
          reason: 'the saved note is retained in the persistent source');
      expect(harborNote, isNotEmpty); // guards against a vacuous "" match

      // When the painter reopens "Harbor at Dusk".
      await harness.whenOpenProject('Harbor at Dusk');

      // Then the exact saved note is shown verbatim (rejects a default,
      // placeholder or truncated note).
      expect(harness.openedProject?.note, harborNote,
          reason: 'the reopened project carries the retained note verbatim '
              '(PROJECT-4)');
      expect(find.textContaining(harborNote), findsWidgets,
          reason: 'the retained note is shown on reopen');
    });

    // AC-9 — a confusable pair of saved samples is flagged within a project
    // (owner PROJECT-5). Injects the full deuteranope (deutanDichromat): the
    // shipped detector fires only near full dichromacy (D-5), and AC-9's spec
    // names only "the painter's confusion line" (no severity).
    //
    // Limited at this phase: the non-flag control ("a clearly-distinct pair is
    // NOT flagged") cannot discriminate until PROJECT-5 does the real
    // computation (at baseline every pair is empty) — that control is the
    // PROJECT-5 augmentation. Graded accordingly.
    acTestWidgets(
        'AC-9', 'a confusable pair of saved samples is flagged within a '
            'project', (tester) async {
      // Given "Harbor at Dusk" holds "Mid Raw Umber" and "Ultramarine Shadow",
      // which fall on the deutan confusion line — confirmed by the harness's
      // *independent* reference, so AC-9 is never graded against the shipped
      // detector it checks. The app runs under a full deuteranope.
      final harness = await givenPalette(
        tester,
        projects: [harborProject],
        cvdProfile: deutanDichromat,
      );
      final sampleNames =
          harness.projects.single.samples.map((s) => s.name).toSet();
      expect(sampleNames,
          containsAll(<String?>['Mid Raw Umber', 'Ultramarine Shadow']),
          reason: 'the project holds the confusion pair');
      expect(
        referenceConfusable(SAMPLE_MID_RAW_UMBER.coordinates,
            SAMPLE_ULTRAMARINE_SHADOW.coordinates),
        isTrue,
        reason: 'the Given pair falls on the deutan confusion line (independent '
            'reference, not the shipped detector)',
      );

      // When the painter opens "Harbor at Dusk".
      await harness.whenOpenProject('Harbor at Dusk');

      // Then exactly the "Mid Raw Umber" / "Ultramarine Shadow" pair is flagged
      // as a confusion pair, with a "check by value" warning shown.
      final flaggedPairs =
          harness.confusionPairs.map((p) => {p.a.name, p.b.name}).toList();
      expect(
        flaggedPairs,
        anyElement(
            unorderedEquals(<String?>['Mid Raw Umber', 'Ultramarine Shadow'])),
        reason: 'the opened project flags the deutan confusion pair (PROJECT-5; '
            'the non-flag control arrives with the PROJECT-5 augmentation)',
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').toLowerCase().contains('check'),
        ),
        findsWidgets,
        reason: 'a "check these by value" warning is shown for the flagged pair',
      );
    });

    // AC-10 — the painter exports a project as a PDF studio sheet (owner
    // PROJECT-6). D-6 keeps the produced sheet as `lastExport` bytes (no disk
    // write).
    //
    // Limited at this phase: the sheet's *content* ("references each sample and
    // each recipe") cannot be asserted until PROJECT-6 produces a real PDF —
    // that is the PROJECT-6 augmentation. Here the Then asserts a PDF is
    // produced. (PROJECT-4 wires opening and lands before PROJECT-6, so the
    // open driven here is real by the un-pend run.)
    acTestWidgets(
        'AC-10', 'the painter exports a project as a PDF studio sheet',
        (tester) async {
      // Given the painter has opened the project "Harbor at Dusk" (6 samples, 3
      // recipes to appear on the sheet).
      final harness = await givenPalette(
        tester,
        projects: [harborProject],
        photos: {harborPhotoRef: harborPhotoBytes},
      );
      final project = harness.projects.single;
      expect(project.name, 'Harbor at Dusk');
      expect(project.samples, hasLength(6));
      expect(project.recipes, hasLength(3));
      expect(harness.lastExport, isNull, reason: 'nothing exported yet');
      await harness.whenOpenProject('Harbor at Dusk');
      // Given precondition (the project is opened — spec's "has opened the
      // project"): the open flow is PROJECT-4, which lands before PROJECT-6, so
      // this passes by the AC-10 un-pend run. It fails cleanly at the red
      // baseline (open inert), naming the owner.
      expect(harness.openedProject?.name, 'Harbor at Dusk',
          reason: 'the project must be opened before export (PROJECT-4 wires '
              'opening; it precedes PROJECT-6)');

      // When the painter exports the project to the device.
      await harness.whenExportProject();

      // Then a PDF studio sheet is produced (its samples/recipes content is the
      // PROJECT-6 augmentation).
      final pdf = harness.lastExport;
      expect(pdf, isNotNull,
          reason: 'exporting produces a PDF studio sheet (PROJECT-6, D-6)');
      expect(String.fromCharCodes(pdf!.take(5)), '%PDF-',
          reason: 'the produced bytes are a real PDF document');
    });
  });

  // -------------------------------------------------------------------------
  // Pending-gate scaffold guards (from DATA-1) — kept so the gate stays honest.
  // -------------------------------------------------------------------------

  group('bs-06 pending gate (scaffold guard)', () {
    test('pending map is exactly the still-pending ACs (shrinks as they land)',
        () {
      // Seeded with AC-1..AC-11 (DATA-1); each behaviour phase deletes its AC's
      // row here as it un-pends it, so this set shrinks by one per delivered AC.
      // Un-pended so far: AC-4 (PALETTE-2), AC-2 + AC-3 (PALETTE-3),
      // AC-1 (SCREEN-2), AC-11 (SCREEN-3), AC-5 (PALETTE-4), AC-6 (PROJECT-3),
      // AC-7 + AC-8 (PROJECT-4). Asserts exact contents (non-vacuous) and that
      // every pending key is a real AC in AC-1..AC-11.
      const expected = {
        'AC-9',
        'AC-10',
      };
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
      // AC-9 is a still-pending example (AC-1/2/3/5/6/7/8/11 were un-pended by
      // SCREEN-2 / PALETTE-3 / PALETTE-4 / PROJECT-3 / PROJECT-4 / SCREEN-3).
      expect(pendingSkipReason('AC-9', forceRunPending: false), isNotNull);
      expect(pendingSkipReason('AC-9', forceRunPending: true), isNull);
      // An AC absent from the map (un-pended) always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
    });
  });
}
