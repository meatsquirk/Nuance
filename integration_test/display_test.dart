// Acceptance suite for bs-08 Display, simulation and spoken output.
//
// DISPLAY-1 (scaffold) landed this runner with the pending-gate skeleton
// (`bs08/pending.dart`, all 10 ACs pending) and a scaffold guard so it cannot
// pass vacuously. ITEST-1 adds the bs-08 harness (`display_harness.dart`: the
// Given/When/Then vocabulary + fixtures + the independent reference projection)
// and here:
//   * fixture guards over `referenceProjectDichromat` + `labDistance` + the
//     display sample (never pending), so the reference the AC tests grade
//     against is itself checked; and
//   * a never-pending smoke test proving the shells wire end to end — the
//     assembled app exposes the display read endpoint, the E2 entry opens the
//     panel with all three controls (E46/E47/E48), and the one app-wide speech
//     is a `RepeatableSpeech` the readout speaks through and the panel (E50)
//     reflects.
// ITEST-2/3 register one *pending* `acTestWidgets` per AC; the behaviour phases
// un-pend each by deleting its row in `bs08/pending.dart`.
//
// Default `flutter test integration_test/display_test.dart -d <udid>` skips
// pending ACs; `--dart-define=BS08_RUN_PENDING=true` runs them (red baseline /
// un-pend run). A booted device udid is mandatory — without `-d` the run
// executes zero tests and still exits 0 (false green; carried flake).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/repeatable_speech.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/widgets/value_reading.dart';

import 'display_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-08 pending gate (scaffold guard)', () {
    test('pending map is exactly the still-pending ACs (shrinks as they land)',
        () {
      // Seeded with AC-1..AC-10 (DISPLAY-1); each behaviour phase deletes its
      // AC's row in `bs08/pending.dart` as it un-pends it, so this set shrinks
      // by one per delivered AC. Un-pended so far: AC-2 (DISPLAY-3, simulation
      // off = trichromat), AC-3 (DISPLAY-4, simulate a chosen type alongside
      // the original), AC-4 (DISPLAY-5, severity slider sets simulation
      // strength), AC-5 (DISPLAY-6, grayscale clears an active simulation) and
      // AC-6 (DISPLAY-7, value-only grayscale greys the whole app).
      // The remaining five are asserted exactly (non-vacuous).
      const unpended = {'AC-2', 'AC-3', 'AC-4', 'AC-5', 'AC-6'};
      final expected = {
        for (var i = 1; i <= 10; i++)
          if (!unpended.contains('AC-$i')) 'AC-$i',
      };
      expect(pendingACs.keys.toSet(), expected);
    });

    test('every pending AC is owned by a real behaviour phase', () {
      for (final entry in pendingACs.entries) {
        expect(
          behaviorPhases,
          contains(entry.value),
          reason: '${entry.key} owner "${entry.value}" is not a bs-08 '
              'behaviour phase',
        );
      }
    });

    test('pendingSkipReason skips a pending AC unless run-pending is forced',
        () {
      // A still-pending AC (the map is non-empty through the acceptance stage).
      // Both directions are driven by the explicit [forceRunPending] so the
      // guard is deterministic in either ambient mode — in particular it holds
      // under `--dart-define=BS08_RUN_PENDING=true` (the red-baseline run), where
      // the ambient `runPending` is true.
      final pendingAc = pendingACs.keys.first;
      expect(pendingSkipReason(pendingAc, forceRunPending: false), isNotNull,
          reason: '$pendingAc is skipped when run-pending is not forced');
      expect(pendingSkipReason(pendingAc, forceRunPending: true), isNull,
          reason: '$pendingAc runs when run-pending is forced');
      // An AC absent from the map (un-pended) always runs.
      expect(pendingSkipReason('AC-999'), isNull);
    });
  });

  group('bs-08 harness fixtures (ITEST-1 guard)', () {
    // The reference projection the AC tests grade AC-3/AC-4 against must itself
    // be correct. These guards check its model-defining properties (not its
    // outputs against the shipped projection — that would couple them), and that
    // the display sample is observable under every type.

    test('reference projection is the identity at severity 0', () {
      for (final type in CvdType.values) {
        final projected = referenceProjectDichromat(
          DISPLAY_SAMPLE_LAB,
          type,
          severity: 0,
        );
        expect(
          labDistance(DISPLAY_SAMPLE_LAB, projected),
          lessThan(1e-3),
          reason: 'severity 0 is the unaffected (trichromat) view for $type',
        );
      }
    });

    test('reference projection leaves a neutral grey near-neutral for every '
        'CvdType', () {
      const grey = ColorCoordinates(lightness: 50, a: 0, b: 0);
      for (final type in CvdType.values) {
        final projected = referenceProjectDichromat(grey, type);
        expect(projected.a.abs(), lessThan(1.0), reason: '$type: grey stays grey');
        expect(projected.b.abs(), lessThan(1.0), reason: '$type: grey stays grey');
      }
    });

    test('reference projection is idempotent at full severity (a projection '
        'onto the dichromat surface)', () {
      for (final type in CvdType.values) {
        final once = referenceProjectDichromat(DISPLAY_SAMPLE_LAB, type);
        final twice = referenceProjectDichromat(once, type);
        expect(
          labDistance(once, twice),
          lessThan(1e-2),
          reason: '$type: re-projecting an already-collapsed colour is a no-op',
        );
      }
    });

    test('reference projection clearly shifts the display sample for every '
        'CvdType', () {
      for (final type in CvdType.values) {
        final projected = referenceProjectDichromat(DISPLAY_SAMPLE_LAB, type);
        expect(
          labDistance(DISPLAY_SAMPLE_LAB, projected),
          greaterThan(3.0),
          reason: 'the display sample must visibly shift under $type so '
              'simulation is observable (AC-3/AC-4)',
        );
      }
    });

    test('reference projection handles a near-black colour (sub-knee CIELAB '
        'branch)', () {
      const nearBlack = ColorCoordinates(lightness: 2, a: 1, b: 1);
      for (final type in CvdType.values) {
        final projected = referenceProjectDichromat(nearBlack, type);
        expect(projected.lightness.isFinite, isTrue);
        expect(projected.a.isFinite, isTrue);
        expect(projected.b.isFinite, isTrue);
        // A near-black colour stays dark under projection.
        expect(projected.lightness, lessThan(20));
      }
    });

    test('labDistance is zero for identical colours and positive otherwise', () {
      expect(labDistance(DISPLAY_SAMPLE_LAB, DISPLAY_SAMPLE_LAB), 0);
      const other = ColorCoordinates(lightness: 10, a: 0, b: 0);
      expect(labDistance(DISPLAY_SAMPLE_LAB, other), greaterThan(0));
    });
  });

  group('bs-08 harness smoke (ITEST-1)', () {
    testWidgets(
        'the assembled app exposes default display settings and the E2 entry '
        'opens the panel with all three controls (E46/E47/E48 + theme)',
        (tester) async {
      final h = await givenDisplay(tester);

      // The display read endpoint is wired, reporting the shipped default view.
      expect(h.settings.simulationType, isNull);
      expect(h.settings.simulationSeverity, 1.0);
      expect(h.settings.grayscale, isFalse);
      expect(h.settings.simulationOn, isFalse);

      // The E2 entry is present on the (Readout) screen through the shared
      // chrome, and opening it reveals the panel with the three controls.
      expect(h.settingsEntry, findsOneWidget);
      expect(h.settingsPanel, findsNothing);
      await h.whenOpenSettings();
      expect(h.settingsPanel, findsOneWidget);
      expect(h.simulationSelector, findsOneWidget); // E47
      expect(h.grayscaleToggle, findsOneWidget); // E46
      expect(h.severitySlider, findsOneWidget); // E48
      expect(h.themeControl, findsOneWidget); // D-11
      await h.whenCloseSettings();
      expect(h.settingsPanel, findsNothing);
    });

    testWidgets(
        'the one app-wide speech wraps the injected sink; speaking the readout '
        'records it and the spoken-output panel (E50) reflects it',
        (tester) async {
      final h = await givenDisplay(tester);

      // One app-wide RepeatableSpeech, wrapping the injected recording sink.
      expect(h.appSpeech, isA<RepeatableSpeech>());
      expect(identical(h.appSpeech.inner, h.speech), isTrue);

      // The panel is present from the start (SPEECH-1) but inert until spoken.
      expect(h.spokenOutputPanel, findsOneWidget);
      expect(h.repeatControl, findsNothing);
      expect(h.lastSpokenText, findsNothing);
      expect(h.speech.utterances, isEmpty);

      // Speaking the readout flows through the one shared seam.
      await h.whenSpeakReading();
      expect(h.speech.utterances, hasLength(1));
      expect(h.speech.utterances.single, isNotEmpty);
      expect(h.appSpeech.lastUtterance, h.speech.utterances.single);

      // ...and the panel now reflects it (repeat control + last-spoken text).
      expect(h.repeatControl, findsOneWidget);
      expect(h.lastSpokenText, findsOneWidget);
      expect(
        tester.widget<Text>(h.lastSpokenText).data,
        h.speech.utterances.single,
      );
    });
  });

  // The display ACs (AC-1..AC-7) — one pending `acTestWidgets` each (ITEST-2).
  //
  // Skipped by default; run under `--dart-define=BS08_RUN_PENDING=true` (the
  // red-baseline run). Each is written against the *public* surface — the E2
  // panel, the shipped controls (driven through the harness `when…`), the live
  // `DisplayReadEndpoint` (`h.settings`), and the rendered display swatches
  // (`_displaySwatches` — the circular `ColorChip` swatches, graded against the
  // **independent** `referenceProjectDichromat` → the shared `toSRGB`). The
  // simulated colour is never graded against the shipped projection.
  //
  // AC-1 (open panel + three controls, SETTINGS-1 built the surface) and AC-7
  // (the reading already shows value + label, bs-01's label contract) pass at
  // baseline — recorded *green at baseline* in `modules/ITEST.md`. They stay
  // pending here: bs-08 un-pends each AC from its owning behaviour phase (per
  // the plan), so SETTINGS-2 un-pends AC-1 and DISPLAY-8 un-pends AC-7, each
  // then keeping it green + meeting coverage. AC-7 is also *limited* until a
  // swatch is rendered — DISPLAY-8 augments it to assert the simulated swatch
  // coexists with the value + label ("not colour alone"), the B-pending-DISPLAY-8
  // row in the augmentations table. AC-2..AC-6 fail at baseline on their Then (no
  // chromatic swatch is displayed yet; the grayscale filter is inert; grayscale
  // does not clear the simulation).
  group('bs-08 display ACs (ITEST-2)', () {
    acTestWidgets('AC-1', 'the painter opens the display and simulation settings',
        (tester) async {
      final h = await givenDisplay(tester);
      // Given: the painter is on a screen (a reading) with no settings shown.
      expect(h.settingsPanel, findsNothing, reason: 'Given: settings not open');
      // When: the painter opens the display and simulation settings (E2).
      await h.whenOpenSettings();
      // Then: the surface is shown with all three controls — the simulation
      // selector (E47), the value-only grayscale toggle (E46) and a theme
      // control (D-11). (Rejects a surface missing any of the three.)
      expect(h.settingsPanel, findsOneWidget);
      expect(h.simulationSelector, findsOneWidget, reason: 'E47 simulation selector');
      expect(h.grayscaleToggle, findsOneWidget, reason: 'E46 grayscale toggle');
      expect(h.themeControl, findsOneWidget, reason: 'theme control (D-11)');
    });

    acTestWidgets('AC-2',
        'with simulation off the displayed colour is the original (trichromat)',
        (tester) async {
      // Given: on a reading with the simulation off.
      final h = await givenDisplay(tester);
      expect(h.settings.simulationOn, isFalse, reason: 'Given: simulation off');
      // When: a colour is displayed (the reading renders its swatch).
      // Then: exactly one displayed swatch, equal to the original — no
      // projection, and no simulated-alongside pair while simulation is off.
      final swatches = _displaySwatches(tester);
      expect(swatches, hasLength(1),
          reason: 'sim off = one un-projected swatch (no alongside pair) — DISPLAY-3');
      expect(_colorNear(swatches.single, _displayColor(displaySample.coordinates)),
          isTrue,
          reason: 'the displayed swatch equals the original (identity path)');
    });

    acTestWidgets('AC-3',
        'the painter simulates a chosen type alongside the original',
        (tester) async {
      // Scenario Outline over its three examples (protan/deutan/tritan).
      final original = _displayColor(displaySample.coordinates);
      for (final type in const [CvdType.protan, CvdType.deutan, CvdType.tritan]) {
        final h = await givenDisplay(tester);
        // Given: the settings are open with simulation off.
        await h.whenOpenSettings();
        expect(h.settings.simulationOn, isFalse,
            reason: 'Given: sim off before selecting $type');
        // When: the painter sets the simulation to <type>.
        await h.whenSelectSimulation(type);
        expect(h.settings.simulationType, type, reason: 'selector set $type');
        await h.whenCloseSettings();
        // Then: the displayed swatch is projected for <type> AND the original is
        // shown alongside it (two distinct swatches). The three types' distinct
        // reference outputs are the control against "selector changes nothing".
        final swatches = _displaySwatches(tester);
        final simulated =
            _displayColor(referenceProjectDichromat(displaySample.coordinates, type));
        expect(swatches.length, greaterThanOrEqualTo(2),
            reason: '$type: a simulated swatch alongside the original — DISPLAY-4');
        expect(swatches.any((c) => _colorNear(c, original)), isTrue,
            reason: '$type: the original colour is shown alongside');
        expect(swatches.any((c) => _colorNear(c, simulated)), isTrue,
            reason: '$type: the simulated swatch matches referenceProjectDichromat');
      }
    });

    acTestWidgets('AC-4', 'the painter sets the simulation strength with the slider',
        (tester) async {
      final h = await givenDisplay(tester);
      // Given: the simulation is set to deutan (via the selector).
      await h.whenOpenSettings();
      await h.whenSelectSimulation(CvdType.deutan);
      expect(h.settings.simulationType, CvdType.deutan,
          reason: 'Given: deutan simulation');
      // When: the painter sets the severity to 60.
      await h.whenSetSeverity(60);
      expect(h.settings.simulationSeverity, closeTo(0.60, 0.03),
          reason: 'the 0..100 slider maps to 0..1 (D-6)');
      await h.whenCloseSettings();
      // Then: the simulated swatch is rendered at that severity (matches the
      // reference projection at 0.60) — DISPLAY-5.
      final atSixty = _displaySwatches(tester);
      final expected60 = _displayColor(referenceProjectDichromat(
          displaySample.coordinates, CvdType.deutan,
          severity: 0.60));
      expect(atSixty.any((c) => _colorNear(c, expected60)), isTrue,
          reason: 'the simulated swatch renders at severity 0.60');
      // Control: severity 0 renders the unaffected original.
      await h.whenOpenSettings();
      await h.whenSetSeverity(0);
      await h.whenCloseSettings();
      expect(
        _displaySwatches(tester).any(
            (c) => _colorNear(c, _displayColor(displaySample.coordinates))),
        isTrue,
        reason: 'severity 0 is the unaffected original',
      );
    });

    acTestWidgets('AC-5', 'turning on grayscale clears an active simulation',
        (tester) async {
      final h = await givenDisplay(tester);
      // Given: the simulation is set to deutan.
      await h.whenOpenSettings();
      await h.whenSelectSimulation(CvdType.deutan);
      expect(h.settings.simulationType, CvdType.deutan,
          reason: 'Given: deutan simulation active');
      // When: the painter turns on the value-only grayscale view.
      await h.whenSetGrayscale(on: true);
      // Then: grayscale is on AND the simulation is cleared (mutually
      // exclusive views, D-3) — DISPLAY-6.
      expect(h.settings.grayscale, isTrue, reason: 'grayscale is on');
      expect(h.settings.simulationType, isNull,
          reason: 'turning grayscale on clears the simulation');
      // Control: turning grayscale off again does not re-enable the simulation.
      await h.whenSetGrayscale(on: false);
      expect(h.settings.simulationType, isNull,
          reason: 'grayscale off leaves the simulation off (not re-enabled)');
      await h.whenCloseSettings();
    });

    acTestWidgets('AC-6', 'the value-only view greys the whole app (one root filter)',
        (tester) async {
      final h = await givenDisplay(tester);
      await h.whenOpenSettings();
      // Given: the value-only grayscale view is on.
      await h.whenSetGrayscale(on: true);
      expect(h.settings.grayscale, isTrue, reason: 'Given: grayscale on');
      await h.whenCloseSettings();
      // Then: a single root saturation-0 filter wraps the whole app (an ancestor
      // of the MaterialApp), so the camera feed, palette swatches and readings
      // are all greyed together (D-5) — not a per-reading filter. The harness
      // opens on the Readout; the camera/palette surfaces live on other screens
      // but are covered by this one root filter.
      expect(
        find.ancestor(
            of: find.byType(MaterialApp), matching: find.byType(ColorFiltered)),
        findsOneWidget,
        reason: 'the whole app is greyed by one root filter — DISPLAY-7',
      );
      // Control: with grayscale off, no app-wide filter wraps the app.
      await h.whenOpenSettings();
      await h.whenSetGrayscale(on: false);
      await h.whenCloseSettings();
      expect(
        find.ancestor(
            of: find.byType(MaterialApp), matching: find.byType(ColorFiltered)),
        findsNothing,
        reason: 'no app-wide desaturation when grayscale is off',
      );
    });

    acTestWidgets('AC-7',
        'a reading under simulation keeps its numeric value and label',
        (tester) async {
      final h = await givenDisplay(tester);
      // Given: the simulation is set to deutan.
      await h.whenOpenSettings();
      await h.whenSelectSimulation(CvdType.deutan);
      expect(h.settings.simulationType, CvdType.deutan,
          reason: 'Given: deutan simulation');
      await h.whenCloseSettings();
      // Then: the reading still shows its numeric value paired with a
      // plain-language word (not colour alone) while simulated. (DISPLAY-8
      // augments this to also assert the simulated swatch coexists with the
      // value + label, once DISPLAY-4 renders it — see the augmentations table.)
      final lightness =
          _science.lightness(displaySample.coordinates).round().toString();
      expect(
        find.byWidgetPredicate(
          (w) => w is ValueReading && w.number == lightness && w.word.isNotEmpty,
        ),
        findsOneWidget,
        reason: 'numeric value + plain-language word present under simulation',
      );
      expect(find.text(lightness), findsWidgets,
          reason: 'the numeric value is shown as text');
    });
  });

  // The spoken-output ACs (AC-8, AC-9, AC-10) — one pending `acTestWidgets`
  // each (ITEST-3). Appended below the ITEST-2 display group, sharing this file
  // but leaving that group untouched. Each drives the *public* speech surface —
  // the readout / comparison speak controls and the E50 spoken-output panel
  // (through the harness `when…`) — and reads the one injected `FakeSpeech`
  // (`h.speech`) + the panel finders, never a second sink.
  //
  // All three are expected *green at baseline*: SPEECH-1 already wired the
  // repeatable speech (`RepeatableSpeech.repeat()`), the E50 panel's repeat
  // control, and the one shared speech seam every caller resolves (readout via
  // `AppScope`, comparison via its injected `speech`). So each stays pending
  // here and its owning behaviour phase (SPEECH-2/3/4) un-pends it, keeping it
  // green and meeting coverage — the same discipline AC-1/AC-7 followed. Each
  // test is nonetheless written to discriminate: AC-8 rejects a repeat that
  // replays a different/empty utterance (control: inert before any speak); AC-9
  // rejects either path bypassing the single sink (two sinks would leave only
  // one utterance recorded); AC-10 rejects a panel that auto-dismisses on a
  // timer (control: inert, content-free, before any speak).
  group('bs-08 speech ACs (ITEST-3)', () {
    acTestWidgets('AC-8', 'the painter repeats the last spoken output',
        (tester) async {
      final h = await givenDisplay(tester);
      // Control: with nothing spoken yet the repeat is inert (no control, no
      // utterance) — so the Then below is a real replay, not an always-on pass.
      expect(h.repeatControl, findsNothing,
          reason: 'repeat is inert until something has been spoken');
      expect(h.speech.utterances, isEmpty);
      // Given: the painter has just heard a reading spoken.
      await h.whenSpeakReading();
      expect(h.speech.utterances, hasLength(1),
          reason: 'Given: exactly the one reading has been spoken');
      final spoken = h.speech.utterances.single;
      expect(spoken, isNotEmpty);
      expect(h.repeatControl, findsOneWidget,
          reason: 'the repeat control appears once something is spoken');
      // When: the painter asks to repeat it (E50).
      await h.whenRepeatLastSpoken();
      // Then: the *same* spoken output is played again — one more entry in the
      // sink, identical to the first (not a different or empty utterance).
      expect(h.speech.utterances, hasLength(2),
          reason: 'repeat speaks exactly one more utterance — SPEECH-2');
      expect(h.speech.utterances.last, spoken,
          reason: 'the repeated utterance is identical to the first');
    });

    acTestWidgets('AC-9',
        'readings and comparisons are spoken through one consistent phrasing',
        (tester) async {
      final h = await givenComparison(tester);
      // Given: spoken output is produced for a reading and for a comparison —
      // build a comparison by filling both slots through the picker (public
      // flow), so there is a comparison to speak and a reading (slot A) to open.
      await h.whenChooseSample(ComparisonSlot.a, displaySample);
      await h.whenChooseSample(ComparisonSlot.b, compareSampleB);
      expect(find.text('Slot A: ${displaySample.name}'), findsOneWidget,
          reason: 'Given: slot A holds the reading');
      expect(find.text('Slot B: ${compareSampleB.name}'), findsOneWidget,
          reason: 'Given: slot B holds the second sample (a comparison exists)');
      // The one app-wide speech wraps the single injected sink (the shared
      // service both paths must use).
      expect(identical(h.appSpeech.inner, h.speech), isTrue,
          reason: 'one shared RepeatableSpeech over the injected sink');

      // When: the comparison is spoken (E6) → recorded by the one sink.
      await h.whenSpeakComparison();
      expect(h.speech.utterances, hasLength(1),
          reason: 'the comparison was spoken through the one injected sink');
      final comparison = h.speech.utterances.single;
      expect(comparison, isNotEmpty);

      // ...and the reading is spoken: open the Readout for slot A and speak it.
      await h.whenOpenReadoutForA();
      await h.whenSpeakReading();
      // Then: both went through the ONE shared speech service — a second
      // phrasing path or a second sink would leave only one utterance here.
      // Each is a non-empty, distinct phrasing (reading vs comparison).
      expect(h.speech.utterances, hasLength(2),
          reason: 'both speak paths flow through the single shared service — SPEECH-3');
      final reading = h.speech.utterances.last;
      expect(reading, isNotEmpty);
      expect(reading, isNot(comparison),
          reason: 'the reading and the comparison are distinct spoken phrasings');
    });

    acTestWidgets('AC-10',
        'the spoken-output panel stays until the painter leaves it',
        (tester) async {
      final h = await givenDisplay(tester);
      // Control: before anything is spoken the panel is present but content-free
      // (inert), so the content asserted below is a real signal — not always-on.
      expect(h.spokenOutputPanel, findsOneWidget);
      expect(h.lastSpokenText, findsNothing);
      // Given: the painter has opened spoken output for a reading.
      await h.whenSpeakReading();
      expect(h.spokenOutputPanel, findsOneWidget);
      expect(h.lastSpokenText, findsOneWidget,
          reason: 'Given: the panel shows the spoken reading');
      final shown = tester.widget<Text>(h.lastSpokenText).data;
      // When: the painter does not act for a while (a long idle), then settle —
      // the settle point past which a timer-based dismiss would have fired.
      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      // Then: the panel is still present and still shows the same output —
      // nothing dismissed it on a timer (SPEECH-4).
      expect(h.spokenOutputPanel, findsOneWidget,
          reason: 'the panel is not auto-dismissed after a long idle');
      expect(h.lastSpokenText, findsOneWidget,
          reason: 'the spoken output stays available');
      expect(tester.widget<Text>(h.lastSpokenText).data, shown,
          reason: 'the same spoken output remains, unchanged by the idle');
    });
  });
}

/// The shared colour-space conversion (`toSRGB`) — the *same* conversion the
/// render path uses; only the dichromat **projection** (`referenceProjectDichromat`)
/// is independent, so AC-3/AC-4 never grade the shipped projection against itself.
const ColorScienceImpl _science = ColorScienceImpl();

/// The displayed sRGB [Color] of a CIELAB colour, via the shared conversion.
Color _displayColor(ColorCoordinates lab) {
  final s = _science.toSRGB(lab);
  return Color.fromARGB(255, s.red, s.green, s.blue);
}

/// The colours of every circular-decoration display swatch currently rendered.
///
/// On the Readout the only circular `BoxDecoration` swatches are `ColorChip`'s
/// (the simulation render chokepoint — the neutral grayscale-preview swatch is a
/// rectangle, and the Capture eyedropper lives on another screen), so this reads
/// the displayed / simulated swatch colours without a key the behaviour phase
/// has not defined yet. Empty until DISPLAY-3/4 render a colour swatch.
List<Color> _displaySwatches(WidgetTester tester) {
  final colors = <Color>[];
  for (final container in tester.widgetList<Container>(find.byType(Container))) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color != null) {
      colors.add(decoration.color!);
    }
  }
  return colors;
}

/// Whether two sRGB colours match within [tol] summed across the three channels
/// (each 0..1; ≈ 0.094 ≈ 24/255, so ~8 per channel) — loose enough for two
/// independent colour pipelines, tight enough that the original and a dichromat
/// projection of [displaySample] are told apart. DISPLAY-4/DISPLAY-5 may tighten
/// it against the shipped render.
bool _colorNear(Color a, Color b, {double tol = 0.094}) =>
    (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs() <= tol;
