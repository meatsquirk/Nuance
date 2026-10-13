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

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';

import 'daltonization_harness.dart';

/// The displayed sRGB swatch a screen must show once [profile]'s remap is live:
/// [referenceDaltonize] of the known sample, in display colour. The shipped
/// `daltonize` (DALT-3) is graded against this **independent** reference (never
/// against itself), so `colorNear` must admit the agreement between the two
/// error-redistribution implementations — a tolerance the test review (G-2) and
/// DALT-3 confirm.
Color _remapOf(CvdProfile profile) =>
    displayColorOf(referenceDaltonize(SCREEN_SAMPLE_LAB, profile));

/// Asserts the known swatch currently rendered (through the shared `ColorChip`
/// chokepoint) is remapped for [profile]: a swatch matches [referenceDaltonize]
/// and none is still the original. Fails at the red baseline (identity shell
/// remap leaves every swatch at the original); passes once the real remap
/// reaches [screen].
void _expectKnownSwatchRemapped(
  WidgetTester tester,
  CvdProfile profile, {
  required String screen,
}) {
  final swatches = displaySwatches(tester);
  final remapped = _remapOf(profile);
  expect(swatches, isNotEmpty,
      reason: '$screen: the known swatch must render through the shared '
          'ColorChip chokepoint for daltonization to reach it');
  expect(swatches.any((c) => colorNear(c, remapped)), isTrue,
      reason: '$screen: the known swatch is remapped to referenceDaltonize');
  expect(swatches.every((c) => !colorNear(c, screenSwatchColor)), isTrue,
      reason: '$screen: no swatch still shows the original colour (it was '
          'remapped, not left unchanged)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-10 pending gate (scaffold guard)', () {
    test('pending map is exactly the still-pending ACs (shrinks as they land)',
        () {
      // Seeded with AC-1..AC-10 (DALT-1); each behaviour phase deletes its AC's
      // row in `bs10/pending.dart` as it un-pends it, so this set shrinks by one
      // per delivered AC. As a phase lands, add its AC to [unpended] here.
      // Un-pended so far: AC-1 (DALT-3 keystone).
      const unpended = <String>{'AC-1'};
      final expected = {
        for (var i = 1; i <= 10; i++)
          if (!unpended.contains('AC-$i')) 'AC-$i',
      };
      expect(pendingACs.keys.toSet(), expected);
      // Not vacuous: the map holds exactly the still-pending ACs (no stray or
      // missing key) — ten less the ones un-pended so far.
      expect(pendingACs, hasLength(10 - unpended.length));
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
      // (D-5) and routes through the real `daltonize` (DALT-3): the displayed
      // swatch is the remap, not the simulation projection and not the original.
      // (Before DALT-3 the shell remap was the identity, so this swatch read as
      // the original; the real remap now makes it a visible, graded change.)
      final remap = displayColorOf(
          referenceDaltonize(SCREEN_SAMPLE_LAB, h.storedProfile));
      expect(h.daltonization, isTrue);
      expect(colorNear(h.displayedColor(screenSwatchColor), remap), isTrue,
          reason: 'daltonization routes through daltonize (the real remap) and '
              'wins over the simulation');
      expect(
          colorNear(h.displayedColor(screenSwatchColor), screenSwatchColor),
          isFalse,
          reason: 'the real remap is a visible change, not the original');
      // The rendered Readout swatch agrees with the endpoint's displayed colour.
      expect(h.displayedSwatches.any((c) => colorNear(c, remap)), isTrue,
          reason: 'the rendered swatch matches the displayed remap');
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

  // The daltonization ACs (AC-1..AC-10) — one *pending* `acTestWidgets` each,
  // registered in ITEST-2. Every test is skipped in the default run and executes
  // under `--dart-define=BS10_RUN_PENDING=true` (the red-baseline run); each
  // behaviour phase un-pends its AC by deleting the row in `bs10/pending.dart`.
  // The test-review packet (ITEST-3) is assembled from these.
  group('bs-10 daltonization acceptance criteria', () {
    acTestWidgets('AC-1', 'TestAC01_RemapForType', (tester) async {
      // Scenario Outline over the painter's stored CVD type (protan, deutan,
      // tritan): daltonization remaps displayed colours for that type.
      for (final type in CvdType.values) {
        // Given: the painter's stored profile is <type> (moderate severity).
        final profile = savedProfile(type);
        final h = await givenDaltonization(tester, storedProfile: profile);
        expect(h.storedProfile.type, type,
            reason: 'AC-1 Given: the stored profile is $type');
        expect(h.daltonization, isFalse,
            reason: 'AC-1 Given: daltonization starts off');
        expect(
            displaySwatches(tester).any((c) => colorNear(c, screenSwatchColor)),
            isTrue,
            reason: 'AC-1 Given: the known swatch is shown unremapped while off');

        // When: the painter turns on daltonization (the shipped panel toggle).
        await h.whenOpenSettings();
        await h.whenSetDaltonization(on: true);
        await h.whenCloseSettings();

        // Then: displayed colours are remapped to be more distinguishable for a
        // <type> viewer — the rendered swatch is referenceDaltonize(_, <type>),
        // no longer the original. Graded per type against the independent
        // reference, so an impl that remaps the same regardless of type fails
        // for at least two of the three types.
        expect(h.daltonization, isTrue);
        _expectKnownSwatchRemapped(tester, profile, screen: 'AC-1 $type');
      }
    });

    acTestWidgets('AC-2', 'TestAC02_OffShowsOriginal', (tester) async {
      // Given: daltonization is off (the default).
      final h = await givenDaltonization(tester,
          storedProfile: savedProfile(CvdType.deutan));
      expect(h.daltonization, isFalse,
          reason: 'AC-2 Given: daltonization off by default');
      expect(h.settings.daltonization, isFalse);

      // When: colours are displayed (the Readout renders the sample's swatch).
      // Then: they are shown with their original values — the rendered swatch is
      // the stored original, and the display pipeline returns the original.
      expect(displaySwatches(tester).any((c) => colorNear(c, screenSwatchColor)),
          isTrue,
          reason: 'AC-2: the swatch is the original (unremapped) colour off');
      expect(colorNear(h.displayedColor(screenSwatchColor), screenSwatchColor),
          isTrue,
          reason: 'AC-2: the display pipeline returns the original while off');

      // LIMITED (augmented by DALT-6): with the shell's identity remap, turning
      // daltonization on cannot yet show a *different* colour, so this cannot yet
      // prove "off" differs from a real remap. DALT-6 adds the control (turning
      // it on remaps the swatch away from the original).
    });

    acTestWidgets('AC-3', 'TestAC03_LabelAndValueKept', (tester) async {
      // Given: daltonization is on, a colour-coded element (the Readout reading
      // for the known sample) is shown.
      final h = await givenDaltonization(tester,
          storedProfile: savedProfile(CvdType.deutan));
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenCloseSettings();
      expect(h.daltonization, isTrue, reason: 'AC-3 Given: daltonization on');

      // When: the colour-coded element is displayed.
      // Then: it still shows its label and numeric value, not colour alone — the
      // swatch's text label and the reading's numeric value are both present
      // alongside the swatch.
      expect(find.text('Displayed colour'), findsOneWidget,
          reason: 'AC-3: the swatch keeps its text label (never colour alone)');
      expect(find.text('55'), findsWidgets,
          reason: "AC-3: the sample's numeric lightness value is still shown");
      expect(displaySwatches(tester), isNotEmpty,
          reason: 'AC-3: the colour swatch is still rendered beside its text');

      // LIMITED (augmented by DALT-9): the label and value render regardless of
      // the remap while it is identity, so this cannot yet prove they *survive a
      // colour change*. DALT-9 adds the control (the swatch colour changed while
      // the label and numeric value stayed identical).
    });

    acTestWidgets('AC-4', 'TestAC04_ProvenanceBadgeReadable', (tester) async {
      // Given: daltonization is on, a value with provenance is shown (the known
      // sample carries a measured provenance).
      final h = await givenDaltonization(tester,
          storedProfile: savedProfile(CvdType.deutan));
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenCloseSettings();
      expect(h.daltonization, isTrue, reason: 'AC-4 Given: daltonization on');

      // When: the value's provenance is shown (the Readout's provenance region
      // states the known sample's measured tier in words).
      // Then: the provenance remains readable from its label (words), not its
      // colour — the provenance region and its tier label are present under the
      // remap.
      expect(find.byKey(const ValueKey('readout-provenance-region')),
          findsOneWidget,
          reason: 'AC-4: the provenance is shown with the reading');
      expect(find.text('Measured'), findsOneWidget,
          reason: 'AC-4: the provenance states its tier in words (readable '
              'without colour)');

      // LIMITED (augmented by DALT-10): the provenance is text-only today, so
      // this cannot yet prove the label (and the icon DALT-10 adds) *survive a
      // colour change*. DALT-10 adds the control (a provenance colour/icon is
      // remapped while its tier label stays).
    });

    acTestWidgets('AC-5', 'TestAC05_UsesStoredProfile', (tester) async {
      // Given: the stored profile is deutan-type at moderate severity.
      final moderate = savedProfile(CvdType.deutan); // severity 0.6 (moderate)
      final h = await givenDaltonization(tester, storedProfile: moderate);
      expect(h.storedProfile.type, CvdType.deutan,
          reason: 'AC-5 Given: stored type is deutan');
      expect(h.storedProfile.severity, moderate.severity,
          reason: 'AC-5 Given: stored severity is moderate');

      // When: daltonization is on.
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenCloseSettings();

      // Then: the remap is computed for deutan at moderate severity — the
      // rendered swatch is referenceDaltonize(_, deutan, moderate), using the
      // stored type AND severity.
      _expectKnownSwatchRemapped(tester, moderate, screen: 'AC-5 deutan@moderate');

      // Control: a stronger stored severity yields a different, stronger remap —
      // so the severity is really read, not a hardcoded default (rejects an impl
      // that ignores the stored severity).
      final strong = savedProfile(CvdType.deutan, severity: 0.95);
      final hStrong = await givenDaltonization(tester, storedProfile: strong);
      await hStrong.whenOpenSettings();
      await hStrong.whenSetDaltonization(on: true);
      await hStrong.whenCloseSettings();
      expect(colorNear(_remapOf(strong), _remapOf(moderate)), isFalse,
          reason: 'AC-5 control: a stronger stored severity remaps to a '
              'different colour than moderate');
      _expectKnownSwatchRemapped(tester, strong, screen: 'AC-5 deutan@strong');
    });

    acTestWidgets('AC-6', 'TestAC06_ProfileChangeRecomputes', (tester) async {
      // Given: daltonization is on for a deutan profile — the swatch is remapped
      // for deutan (this precondition holds once DALT-3's real remap and
      // DALT-11's live re-read exist; it fails here at the red baseline).
      final deutan = savedProfile(CvdType.deutan);
      final h = await givenDaltonization(tester, storedProfile: deutan);
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenCloseSettings();
      expect(h.daltonization, isTrue, reason: 'AC-6 Given: daltonization on');
      _expectKnownSwatchRemapped(tester, deutan, screen: 'AC-6 before (deutan)');

      // When: the painter's stored profile changes to protan (saved through the
      // real CvdProfileStore write-side).
      final protan = savedProfile(CvdType.protan);
      await h.whenSaveProfile(protan);

      // Then: the remap is recomputed for protan — the rendered swatch is now
      // referenceDaltonize(_, protan) (rejects an impl that reads the profile
      // once at build and never re-reads it on a saved change).
      _expectKnownSwatchRemapped(tester, protan, screen: 'AC-6 after (protan)');
    });

    acTestWidgets('AC-7', 'TestAC07_DistinctFromSimulation', (tester) async {
      // Given: both daltonization and simulation are available (deutan profile),
      // simulation off.
      final profile = savedProfile(CvdType.deutan);
      final h = await givenDaltonization(tester, storedProfile: profile);
      expect(h.settings.simulationOn, isFalse,
          reason: 'AC-7 Given: simulation off');

      // When: the painter turns daltonization on.
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenCloseSettings();
      expect(h.daltonization, isTrue);

      // The remap must actually move the colour (precondition for "aids
      // distinction"; the real remap is DALT-3, consumed by DALT-5) — it fails
      // here at the red baseline where the shell remap is identity.
      final displayed = h.displayedColor(screenSwatchColor);
      expect(colorNear(displayed, screenSwatchColor), isFalse,
          reason: 'AC-7: daltonization remaps the colour (not the identity '
              'shell)');

      // Then: colours are remapped to aid distinction, not shown as the painter
      // perceives them — the remapped swatch is NOT the dichromat projection
      // (simulation) of the same colour + profile (rejects "daltonize by
      // simulating").
      final simulated = displayColorOf(referenceProjectDichromat(
          SCREEN_SAMPLE_LAB, CvdType.deutan,
          severity: profile.severity));
      expect(colorNear(displayed, simulated), isFalse,
          reason: 'AC-7: the remap differs from the simulation projection — it '
              'aids distinction, it does not show perception');
    });

    acTestWidgets('AC-8', 'TestAC08_StoredValuesUnchanged', (tester) async {
      // Given: a sample has stored colour values (the known sample on the
      // Readout); its displayed swatch while daltonization is off is the stored
      // original.
      final h = await givenDaltonization(tester,
          storedProfile: savedProfile(CvdType.deutan));
      expect(displaySwatches(tester).any((c) => colorNear(c, screenSwatchColor)),
          isTrue,
          reason: 'AC-8 Given: the stored colour renders as the original off');

      // When: daltonization remaps its displayed colour (turn it on), then the
      // painter turns it back off.
      await h.whenOpenSettings();
      await h.whenSetDaltonization(on: true);
      await h.whenSetDaltonization(on: false);
      await h.whenCloseSettings();

      // Then: the stored colour values are unchanged — with daltonization off
      // again the swatch is once more the original, so the remap wrote nothing
      // back to the stored sample (rejects a remap that persists the transformed
      // colour).
      expect(displaySwatches(tester).any((c) => colorNear(c, screenSwatchColor)),
          isTrue,
          reason: 'AC-8: turning the remap off restores the original — storage '
              'was never overwritten');

      // LIMITED (augmented by DALT-7): while the remap is identity, the "on"
      // state does not differ from "off", so this cannot yet prove the round-trip
      // is real. DALT-7 adds the control (while on, the swatch did change — so
      // the restore is a genuine round-trip, not a no-op).
    });

    acTestWidgets('AC-9', 'TestAC09_EveryScreen', (tester) async {
      // Given: daltonization is on for a deutan profile, and the known swatch is
      // surfaced on each of the capture, readout and palette screens.
      // Daltonization is seeded on the live display controller (its public toggle
      // is exercised by AC-1/AC-2); here the focus is that the remap reaches
      // *every* screen through the one shared chokepoint — not one screen only.
      final profile = savedProfile(CvdType.deutan);
      const on = DisplaySettings(daltonization: true);

      // When/Then: on the Readout.
      final readout = await givenDaltonization(tester,
          storedProfile: profile, initialSettings: on);
      expect(readout.daltonization, isTrue,
          reason: 'AC-9 Given: daltonization on (readout)');
      _expectKnownSwatchRemapped(tester, profile, screen: 'AC-9 readout');

      // On the Capture screen.
      final capture = await givenDaltonizationOnCapture(tester,
          storedProfile: profile, initialSettings: on);
      expect(capture.daltonization, isTrue,
          reason: 'AC-9 Given: daltonization on (capture)');
      _expectKnownSwatchRemapped(tester, profile, screen: 'AC-9 capture');

      // On the Palette screen (rejects a remap wired into one screen only).
      final palette = await givenDaltonizationOnPalette(tester,
          storedProfile: profile, initialSettings: on);
      expect(palette.daltonization, isTrue,
          reason: 'AC-9 Given: daltonization on (palette)');
      _expectKnownSwatchRemapped(tester, profile, screen: 'AC-9 palette');
    });

    acTestWidgets('AC-10', 'TestAC10_NoProfileNeedsAssessment', (tester) async {
      // Given: no CVD profile has been saved (the store is empty).
      final h = await givenDaltonization(tester, storedProfile: noProfile);
      expect(await h.profileStore.count(), 0,
          reason: 'AC-10 Given: no profile saved (store empty)');

      // When: the painter opens the daltonization control.
      await h.whenOpenSettings();
      expect(h.noProfileRegion, findsOneWidget,
          reason: 'AC-10: the daltonization control shows its no-profile region');

      // Then: it reports that a self-assessment is needed before colours can be
      // remapped (rejects a control that silently offers a remap against the
      // const default, or reports nothing).
      expect(
        find.descendant(
          of: h.noProfileRegion,
          matching:
              find.textContaining(RegExp('self-assessment', caseSensitive: false)),
        ),
        findsWidgets,
        reason: 'AC-10: the no-profile region reports a self-assessment is needed',
      );

      // Control: with a saved profile the no-profile message is absent (the
      // control only prompts when nothing is saved, and the remap is available).
      final saved = await givenDaltonization(tester,
          storedProfile: savedProfile(CvdType.deutan));
      await saved.whenOpenSettings();
      expect(
        find.descendant(
          of: saved.noProfileRegion,
          matching:
              find.textContaining(RegExp('self-assessment', caseSensitive: false)),
        ),
        findsNothing,
        reason: 'AC-10 control: with a profile saved there is no self-assessment '
            'prompt',
      );
    });
  });
}
