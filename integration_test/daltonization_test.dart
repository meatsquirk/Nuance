// Acceptance suite for bs-10 Daltonization and colour-distinction aids.
//
// DALT-1 (scaffold) seeded the pending-gate skeleton (`bs10/pending.dart`, all
// 10 ACs pending). ITEST-1 adds the bs-10 harness (`daltonization_harness.dart`:
// the Given/When/Then vocabulary + fixtures + the independent reference remap)
// and here:
//   * scaffold guards over the pending gate, so it cannot pass vacuously (the
//     pending map is exactly the 10 still-pending ACs; every owner is a real
//     behaviour phase; the gate skips pending by default and runs them under
//     run-pending);
//   * fixture guards over `referenceDaltonize` + `displayColorOf` + the screen
//     sample, so the reference the AC tests grade against is itself checked
//     (its model-defining properties, not its outputs against the shipped
//     `daltonize` — that would couple them); and
//   * a never-pending smoke test proving the shells wire end to end — the
//     assembled app exposes the display read endpoint, the panel toggle reaches
//     the controller (daltonization flips), the one display chokepoint routes
//     the swatch through `daltonize` when daltonization is on (winning over an
//     active simulation, D-5), and the profile store is reachable (a saved
//     profile persists; an empty store reports none).
// ITEST-2/3 register one *pending* `acTestWidgets` per AC; the behaviour phases
// un-pend each by deleting its row in `bs10/pending.dart`.
//
// Default `flutter test integration_test/daltonization_test.dart -d <udid>`
// skips pending ACs; `--dart-define=BS10_RUN_PENDING=true` runs them (red
// baseline / un-pend run). A booted device udid is mandatory — without `-d` the
// run executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

import 'daltonization_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-10 pending gate (scaffold guard)', () {
    test('pending map is exactly the still-pending ACs (shrinks as they land)',
        () {
      // Seeded with AC-1..AC-10 (DALT-1); each behaviour phase deletes its AC's
      // row in `bs10/pending.dart` as it un-pends it, so this set shrinks by one
      // per delivered AC. Nothing is un-pended yet (no behaviour phase has run —
      // every AC is still pending), so the expected set is all ten. As a phase
      // lands, add its AC to [unpended] here.
      const unpended = <String>{};
      final expected = {
        for (var i = 1; i <= 10; i++)
          if (!unpended.contains('AC-$i')) 'AC-$i',
      };
      expect(pendingACs.keys.toSet(), expected);
      // Not vacuous: the map holds exactly the ten ACs (no stray or missing key).
      expect(pendingACs, hasLength(10));
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-10 '
              'behaviour phase',
        );
      }
    });

    test('the gate skips a pending AC by default and runs it under run-pending',
        () {
      // Every AC is pending, so in default mode each is skipped (its body never
      // runs) and in run-pending mode each runs. Both directions use the
      // explicit [forceRunPending] so the guard is deterministic in either
      // ambient mode — in particular under `--dart-define=BS10_RUN_PENDING=true`
      // (the red-baseline run). This fails if an AC were silently un-pended, or
      // if the gate inverted to run a pending AC in the default run.
      expect(pendingACs, isNotEmpty,
          reason: 'bs-10 behaviour is unbuilt; every AC is still pending');
      for (final ac in pendingACs.keys) {
        expect(pendingSkipReason(ac, forceRunPending: false), isNotNull,
            reason: '$ac is pending and must be skipped in the default run');
        expect(pendingSkipReason(ac, forceRunPending: true), isNull,
            reason: '$ac must run in run-pending mode');
      }
      // An AC absent from the map (un-pended) always runs, in either mode.
      expect(pendingSkipReason('AC-999', forceRunPending: false), isNull);
      expect(pendingSkipReason('AC-999', forceRunPending: true), isNull);
      // The ambient path (used by acTestWidgets) agrees with the current mode.
      expect(
        pendingSkipReason('AC-1'),
        pendingSkipReason('AC-1', forceRunPending: runPending),
      );
    });
  });

  group('bs-10 harness fixtures (ITEST-1 guard)', () {
    // The reference remap the AC tests grade AC-1/AC-5 against must itself be
    // correct. These guards check its model-defining properties (not its outputs
    // against the shipped `daltonize` — that would couple them), and that the
    // screen sample is observably remapped under every type.

    test('reference remap is the identity at severity 0', () {
      for (final type in CvdType.values) {
        final remapped =
            referenceDaltonize(SCREEN_SAMPLE_LAB, CvdProfile(type: type, severity: 0));
        expect(
          labDistance(SCREEN_SAMPLE_LAB, remapped),
          lessThan(1e-9),
          reason: 'severity 0 is an unaffected painter — no remap for $type',
        );
      }
    });

    test('reference remap leaves a neutral grey near-neutral for every CvdType',
        () {
      const grey = ColorCoordinates(lightness: 50, a: 0, b: 0);
      for (final type in CvdType.values) {
        final remapped = referenceDaltonize(grey, CvdProfile(type: type));
        // A grey has no chroma for the dichromat to lose, so there is nothing to
        // redistribute: the remap leaves it (near-)grey.
        expect(remapped.a.abs(), lessThan(1.5), reason: '$type: grey stays grey');
        expect(remapped.b.abs(), lessThan(1.5), reason: '$type: grey stays grey');
      }
    });

    test('reference remap preserves lightness (a chroma-redistribution aid)', () {
      for (final type in CvdType.values) {
        final remapped = referenceDaltonize(SCREEN_SAMPLE_LAB, CvdProfile(type: type));
        expect(
          (remapped.lightness - SCREEN_SAMPLE_LAB.lightness).abs(),
          lessThan(1e-9),
          reason: '$type: daltonization redistributes chroma, not luminance',
        );
      }
    });

    test('reference remap clearly shifts the screen sample for every CvdType',
        () {
      for (final type in CvdType.values) {
        final remapped = referenceDaltonize(SCREEN_SAMPLE_LAB, CvdProfile(type: type));
        expect(
          labDistance(SCREEN_SAMPLE_LAB, remapped),
          greaterThan(1.0),
          reason: 'the screen sample must visibly remap under $type so the aid '
              'is observable (AC-1)',
        );
      }
    });

    test('reference remap is distinct from the simulation projection for every '
        'CvdType', () {
      // Daltonization aids distinction; simulation shows perception (AC-7). The
      // reference remap must therefore land somewhere other than the dichromat
      // projection of the same colour — a reference that collapsed the colour
      // the way the projection does could never grade AC-7.
      for (final type in CvdType.values) {
        final remapped = referenceDaltonize(SCREEN_SAMPLE_LAB, CvdProfile(type: type));
        final projected = referenceProjectDichromat(SCREEN_SAMPLE_LAB, type);
        expect(
          labDistance(remapped, projected),
          greaterThan(1.0),
          reason: '$type: the remap must differ from the perceived (simulated) '
              'colour (AC-7)',
        );
      }
    });

    test('a stronger severity yields a stronger remap for every CvdType', () {
      // AC-5's control relies on this: a stored profile at a higher severity
      // must push a confusable colour further than a lower one.
      for (final type in CvdType.values) {
        final mild = referenceDaltonize(
            SCREEN_SAMPLE_LAB, CvdProfile(type: type, severity: 0.3));
        final strong = referenceDaltonize(
            SCREEN_SAMPLE_LAB, CvdProfile(type: type, severity: 0.9));
        expect(
          labDistance(SCREEN_SAMPLE_LAB, strong),
          greaterThan(labDistance(SCREEN_SAMPLE_LAB, mild)),
          reason: '$type: a stronger severity remaps further (AC-5 control)',
        );
      }
    });

    test('reference remap handles a near-black colour (sub-knee CIELAB branch)',
        () {
      const nearBlack = ColorCoordinates(lightness: 2, a: 1, b: 1);
      for (final type in CvdType.values) {
        final remapped = referenceDaltonize(nearBlack, CvdProfile(type: type));
        expect(remapped.lightness.isFinite, isTrue);
        expect(remapped.a.isFinite, isTrue);
        expect(remapped.b.isFinite, isTrue);
      }
    });

    test('displayColorOf is opaque and round-trips the screen swatch', () {
      final c = displayColorOf(SCREEN_SAMPLE_LAB);
      expect(c.a, 1.0, reason: 'displayed swatches are fully opaque');
      // The exported convenience equals the recomputed colour (no hidden state).
      expect(colorNear(c, screenSwatchColor), isTrue);
    });

    test('colorNear separates the original from a real remap of the sample', () {
      // The tolerance must admit the sRGB round-trip rounding yet reject a real
      // remap — otherwise an AC-1 "it changed" assertion could never fail.
      expect(colorNear(screenSwatchColor, screenSwatchColor), isTrue);
      final remapped = displayColorOf(
          referenceDaltonize(SCREEN_SAMPLE_LAB, const CvdProfile(type: CvdType.deutan)));
      expect(colorNear(screenSwatchColor, remapped), isFalse,
          reason: 'a full-strength remap is outside the round-trip tolerance');
    });
  });

  group('bs-10 harness smoke (ITEST-1)', () {
    testWidgets(
        'the assembled app exposes default display settings and the panel toggle '
        'reaches the controller (daltonization flips)', (tester) async {
      final h = await givenDaltonization(tester);

      // The display read endpoint is wired, reporting daltonization off by
      // default (DALT-2) — the shipped view remaps nothing until asked.
      expect(h.daltonization, isFalse);
      expect(h.settings.daltonization, isFalse);

      // The E2 entry opens the panel, which carries the bs-10 toggle (CONTROL-1)
      // and the keyed no-saved-profile region.
      expect(h.settingsEntry, findsOneWidget);
      expect(h.settingsPanel, findsNothing);
      await h.whenOpenSettings();
      expect(h.settingsPanel, findsOneWidget);
      expect(h.daltonizationToggle, findsOneWidget);
      expect(h.noProfileRegion, findsOneWidget);

      // Toggling on reaches DisplayController.setDaltonization → the live
      // endpoint reports it on; toggling off returns it. (Rejects a toggle that
      // never reaches the controller.)
      await h.whenSetDaltonization(on: true);
      expect(h.daltonization, isTrue);
      await h.whenSetDaltonization(on: false);
      expect(h.daltonization, isFalse);
    });

    testWidgets(
        'the one display chokepoint routes the swatch through daltonize when on '
        '(winning over an active simulation)', (tester) async {
      // Start with a simulation active (the stored type) and daltonization off:
      // the chokepoint is transforming the swatch via the simulation branch.
      final h = await givenDaltonization(
        tester,
        storedProfile: savedProfile(CvdType.deutan),
        initialSettings: DisplaySettings(simulationType: CvdType.deutan),
      );
      expect(h.settings.simulationOn, isTrue, reason: 'Given: simulation on');
      expect(h.daltonization, isFalse, reason: 'Given: daltonization off');
      // The simulation moves the colour, so the displayed swatch is not the
      // original — the chokepoint is live.
      expect(colorNear(h.displayedColor(screenSwatchColor), screenSwatchColor),
          isFalse,
          reason: 'the simulation branch transforms the swatch');

      // Turn daltonization on through the panel.
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenCloseSettings();

      // The daltonization branch now wins over the still-active simulation
      // (D-5) and routes through `daltonize`, which is identity in this shell —
      // so the displayed swatch is the original again, not the projection. This
      // proves the chokepoint calls `daltonize` (and that daltonization takes
      // precedence); the *real* remap (a visible change) is DALT-3's pending AC.
      expect(h.daltonization, isTrue);
      expect(colorNear(h.displayedColor(screenSwatchColor), screenSwatchColor),
          isTrue,
          reason: 'daltonization routes through daltonize (identity) and wins '
              'over the simulation');
      // The rendered Readout swatch agrees with the endpoint's displayed colour.
      expect(h.displayedSwatches.any((c) => colorNear(c, screenSwatchColor)),
          isTrue,
          reason: 'the rendered swatch matches the displayed colour');
    });

    testWidgets('the profile store is reachable: a saved profile persists, an '
        'empty store reports none', (tester) async {
      // A saved profile: the store holds exactly one, loading the saved value,
      // and it is the profile the chokepoint reads.
      final saved = await givenDaltonization(
        tester,
        storedProfile: savedProfile(CvdType.protan, severity: 0.4),
      );
      expect(await saved.profileStore.count(), 1);
      expect(await saved.profileStore.load(),
          const CvdProfile(type: CvdType.protan, severity: 0.4));
      expect(saved.storedProfile,
          const CvdProfile(type: CvdType.protan, severity: 0.4));

      // No saved profile ([noProfile]): the store is empty and the app falls
      // back to the const default (bs-07 D-3). Clearing a saved profile returns
      // the store to that empty state through the production contract.
      final empty = await givenDaltonization(tester, storedProfile: noProfile);
      expect(await empty.profileStore.count(), 0);
      expect(await empty.profileStore.load(), isNull);
      expect(empty.storedProfile, const CvdProfile(type: CvdType.deutan));

      await saved.whenClearProfile();
      expect(await saved.profileStore.count(), 0,
          reason: 'clearing removes the saved profile (AC-10 setup)');
    });
  });

  // The daltonization ACs (AC-1..AC-10) — one pending `acTestWidgets` each —
  // are registered in ITEST-2 (and the test-review packet assembled in ITEST-3).
  // They stay out of this phase so ITEST-1 lands the harness + smoke alone.
}
