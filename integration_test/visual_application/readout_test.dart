// bs-18 acceptance suite — Readout-screen AC (ITEST-2): AC-5 the regions as
// cards with mono eyebrows and a speak FAB.
//
// Pumps the real Readout — the opening Capture destination's body on the nav
// shell (`pumpShell`, reading `aReading`) — and reads the design-system
// treatment off the pumped tree. Owner READ-3; pending and red at baseline
// (regions are bare Padding/Column, no mono eyebrows, speak is an
// OutlinedButton).
//
// AC ids mirror the plan's `AC-n` names verbatim.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:paint_color_assistant/readout/name_header.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';
import 'package:paint_color_assistant/readout/value_region.dart';

import 'harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------------------
  // AC-5 — Readout regions as cards + mono eyebrows + speak FAB (owner READ-3)
  // ------------------------------------------------------------------------
  acTestWidgets('AC-5',
      'TestAC05_Readout: value/name/space regions sit in surface cards with '
      'uppercase mono eyebrows, and speak is the accent SpeakButton FAB',
      (tester) async {
    // GIVEN the Readout open on a reading (the shell's opening Capture body).
    final h = await pumpShell(tester);
    const regionKeys = <Key>[
      NameHeader.headerKey,
      ValueRegion.regionKey,
      SpaceSelector.selectorKey,
    ];
    for (final key in regionKeys) {
      expect(find.byKey(key), findsOneWidget,
          reason: 'Given: the ${_name(key)} region renders');
    }

    // WHEN the reading renders (the pump settles).

    // THEN the value, colour-name and colour-space regions each sit in a
    // surface card, and that card carries the region's uppercase mono eyebrow
    // (rejects a region left as a bare Column; a hardcoded eyebrow).
    for (final key in regionKeys) {
      final card = find.ancestor(
        of: find.byKey(key),
        matching: find.byType(SurfaceCard),
      );
      expect(card, findsOneWidget,
          reason: 'the ${_name(key)} region sits inside a SurfaceCard');
      expect(
        find.descendant(of: card, matching: find.byType(MonoLabel)),
        findsWidgets,
        reason: 'the ${_name(key)} card carries a mono eyebrow',
      );
    }

    // THEN there is one mono eyebrow per region (each region names its field).
    expect(h.monoLabels, findsAtLeastNWidgets(regionKeys.length));

    // THEN the speak action renders as the round accent floating speak button
    // (rejects leaving speak a plain IconButton / OutlinedButton).
    expect(h.speakButtons, findsOneWidget,
        reason: 'speak renders as the SpeakButton FAB');
  });
}

/// A readable name for a region key, for failure messages.
String _name(Key key) {
  if (key == NameHeader.headerKey) return 'colour-name';
  if (key == ValueRegion.regionKey) return 'value';
  if (key == SpaceSelector.selectorKey) return 'colour-space';
  return '$key';
}
