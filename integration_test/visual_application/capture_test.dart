// bs-18 acceptance suite — Capture-screen ACs (ITEST-2): AC-3 the controls as
// design-system components, AC-4 the live warnings stacking without overlap.
//
// Both pump the real Capture screen through the harness (`pumpScreen(capture)`,
// wired with `aReading`'s scene) and read the design-system treatment off the
// pumped tree. AC-3 owner is READ-1, AC-4 owner is READ-2; both are pending and
// red at baseline (ad-hoc buttons; fixed overlapping warning banners).
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/capture/capture_controls.dart';
import 'package:paint_color_assistant/capture/capture_live_view.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-3 — Capture controls render as design-system components (owner READ-1)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-3',
      'TestAC03_CaptureControls: shutter is the 88px round button, actions are '
      'pills, torch/import are design-system controls', (tester) async {
    // GIVEN the Capture screen open on aReading — its controls render.
    final h = await pumpScreen(tester, VisualScreen.capture);
    expect(find.byKey(CaptureControls.captureKey), findsOneWidget,
        reason: 'Given: the capture (shutter) action renders');
    expect(find.byKey(CaptureControls.torchKey), findsOneWidget,
        reason: 'Given: the torch control renders');
    expect(find.byKey(CaptureControls.importKey), findsOneWidget,
        reason: 'Given: the import-photo control renders');

    // WHEN the controls render (the pump settles).

    // THEN the capture action renders as the round 88px shutter button (rejects
    // leaving it a small ad-hoc text/elevated button).
    final shutterSize = tester.getSize(find.byKey(CaptureControls.captureKey));
    expect(shutterSize.width, closeTo(88, 4),
        reason: 'the shutter is ~88px wide');
    expect(shutterSize.height, closeTo(88, 4),
        reason: 'the shutter is ~88px tall (a round 88px button)');

    // THEN the primary actions render as design-system pills.
    expect(h.pillButtons, findsWidgets,
        reason: 'the capture actions include design-system PillButtons');

    // THEN the torch and import controls are design-system controls, not the
    // ad-hoc TextButton/ElevatedButton they are today (rejects un-swapped
    // actions). READ-1 extends this to the "ad-hoc absent" sweep over every
    // capture control (augmentation).
    for (final key in [CaptureControls.torchKey, CaptureControls.importKey]) {
      expect(find.byKey(key), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(TextButton)),
        findsNothing,
        reason: 'the control at $key is not an ad-hoc TextButton',
      );
      // The key itself must not sit on an ad-hoc button.
      final widgetAtKey = tester.widget(find.byKey(key));
      expect(widgetAtKey, isNot(isA<TextButton>()));
      expect(widgetAtKey, isNot(isA<ElevatedButton>()));
    }

    // AUGMENTATION (READ-1): the present/size checks above catch the shutter
    // and the torch/import Rejects, but every *other* capture control was an
    // ad-hoc TextButton too (dismiss/lock/calibrate/value-only/radius options/
    // sample/send). Sweep them all — no capture control may remain a bare
    // TextButton or ElevatedButton. Discriminates the full swap: it fails
    // against the pre-READ-1 tree, where these were all TextButtons.
    final sweepKeys = <Key>[
      CaptureControls.dismissWarningKey,
      CaptureControls.lockKey,
      CaptureControls.calibrateKey,
      CaptureControls.importKey,
      CaptureControls.valueOnlyKey,
      CaptureControls.captureKey,
      CaptureControls.torchKey,
      CaptureControls.samplePointsKey,
      CaptureControls.sendToComparisonKey,
      for (final r in CaptureControls.radiusOptionsPx)
        CaptureControls.radiusOptionKey(r),
    ];
    for (final key in sweepKeys) {
      final keyed = find.byKey(key);
      expect(keyed, findsOneWidget, reason: '$key renders');
      final widgetAtKey = tester.widget(keyed);
      expect(widgetAtKey, isNot(isA<TextButton>()),
          reason: '$key is not an ad-hoc TextButton');
      expect(widgetAtKey, isNot(isA<ElevatedButton>()),
          reason: '$key is not an ad-hoc ElevatedButton');
      expect(find.descendant(of: keyed, matching: find.byType(TextButton)),
          findsNothing,
          reason: '$key has no ad-hoc TextButton inside');
    }

    // THEN the action controls (not the toggles or the round shutter) render as
    // design-system pills.
    for (final key in [
      CaptureControls.dismissWarningKey,
      CaptureControls.lockKey,
      CaptureControls.calibrateKey,
      CaptureControls.importKey,
      CaptureControls.samplePointsKey,
      CaptureControls.sendToComparisonKey,
    ]) {
      expectPill(tester, key);
    }
  });

  // ------------------------------------------------------------------------
  // AC-4 — the live warnings stack without overlapping (owner READ-2)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-4',
      'TestAC04_CaptureWarnings: the live warning banners over the viewfinder '
      'do not overlap at 200% text scale', (tester) async {
    // The overlap the fix (D-6) addresses manifests when the text grows: the
    // fixed-offset Positioned banners collide. bs-11 fixes 200% as the a11y text
    // floor, so measure there. Reset on teardown.
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // GIVEN the Capture screen showing more than one live warning/reading over
    // the viewfinder — the stability, lock and accuracy readings are always
    // live, so ≥2 banners are present.
    await pumpScreen(tester, VisualScreen.capture);
    const bannerKeys = <Key>[
      CaptureLiveView.stabilityKey,
      CaptureLiveView.lockIndicatorKey,
      CaptureLiveView.accuracyKey,
    ];
    final present = <Key>[
      for (final key in bannerKeys)
        if (find.byKey(key).evaluate().isNotEmpty) key,
    ];
    expect(present.length, greaterThanOrEqualTo(2),
        reason: 'Given: more than one live warning banner is shown');

    // WHEN the warnings render over the viewfinder (at 200% text scale).

    // THEN no banner's rect intersects another's — each reads as its own banner
    // (rejects the current same-origin overlapping Positioned banners).
    final rects = {
      for (final key in present) key: tester.getRect(find.byKey(key)),
    };
    for (var i = 0; i < present.length; i++) {
      for (var j = i + 1; j < present.length; j++) {
        final a = present[i];
        final b = present[j];
        expect(
          rects[a]!.overlaps(rects[b]!),
          isFalse,
          reason: 'the $a banner (${rects[a]}) must not overlap the $b banner '
              '(${rects[b]})',
        );
      }
    }
  });
}
