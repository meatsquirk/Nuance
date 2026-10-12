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
import 'package:paint_color_assistant/domain/color_coordinates.dart';

import 'display_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('bs-08 pending gate (scaffold guard)', () {
    test('pending map covers exactly AC-1..AC-10', () {
      final expected = {for (var i = 1; i <= 10; i++) 'AC-$i'};
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

    test('pendingSkipReason skips a pending AC by default, runs it when forced',
        () {
      expect(pendingSkipReason('AC-1'), isNotNull);
      expect(pendingSkipReason('AC-1', forceRunPending: true), isNull);
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
}
