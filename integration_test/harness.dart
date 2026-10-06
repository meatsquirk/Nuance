// Acceptance-suite harness for bs-01 Color readout (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and pending gate the AC tests
// (ITEST-2, ITEST-3) are written against. The suite drives the *real* assembled
// app through the single production `buildApp` entry (D-6/D-7), faking only the
// platform sinks (Speech, Haptics). No colour math is faked — the real
// `ColorScienceImpl` is injected (its methods throw until COLOR-2/3, which is
// why the colour ACs stay pending until those phases land).
//
// Fixture identifiers mirror the plan's `SAMPLE_*` names, and the AC catalogue
// references them verbatim, so this file opts out of lowerCamelCase for them.
// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';

import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the fakes so an AC test only needs to import this harness.
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// ---------------------------------------------------------------------------
// Fixtures
//
// Samples are stored in canonical CIELAB (the domain's single source of truth);
// a fixture whose plan shape is given in CIELCh carries the exact polar form of
// that chroma/hue in a*/b* (a* = C·cos h, b* = C·sin h), since CIELCh is the
// polar form of CIELAB a*/b* by definition. The derived readings a scenario
// asserts (Munsell notation, the plain-language name, value/temperature words)
// are produced by the colour-science behaviour phases; the fixtures fix only the
// inputs those derivations run on.
// ---------------------------------------------------------------------------

/// Warm terracotta — CIELCh L 58, C 34, h 42°. Drives AC-1, AC-2, AC-3, AC-4,
/// AC-5, AC-8, AC-9, AC-10.
const Sample SAMPLE_TERRACOTTA = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

/// Deep olive green — the recipe target (AC-11) and, as a just-captured reading,
/// the capture subject (AC-12).
const Sample SAMPLE_OLIVE = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A cool sample — CIELCh L 55, C 34, h 250° (blue-violet). The AC-4 control: it
/// must read "cool", never "warm".
const Sample SAMPLE_COOL = Sample(
  name: 'Cool Periwinkle',
  coordinates: ColorCoordinates(lightness: 55, a: -11.63, b: -31.95),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A spectrophotometer reading — provenance Measured, no caveat note. Drives
/// AC-6, and is the AC-7 control (a measured reading shows no seeded-value note).
const Sample SAMPLE_MEASURED = Sample(
  name: 'Measured Reading',
  coordinates: ColorCoordinates(lightness: 50, a: 12, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A model-seeded, unverified value — provenance Estimated. Drives AC-7. The
/// human-facing caveat ("Seeded by a model. Treat as a starting point.") is
/// rendered by READOUT-5 from the tier, so the fixture carries the tier only.
const Sample SAMPLE_ESTIMATED = Sample(
  name: 'Estimated Reading',
  coordinates: ColorCoordinates(lightness: 62, a: 5, b: -20),
  provenance: Provenance(ProvenanceTier.estimated),
);

// ---------------------------------------------------------------------------
// Pending gate
// ---------------------------------------------------------------------------

/// Maps each still-pending AC to the behaviour phase that un-pends it.
///
/// An AC is *pending* while its key is present; the named phase un-pends it by
/// deleting the row. The default `flutter test integration_test/` skips pending
/// ACs (their bodies, which assert un-built behaviour, never run); set
/// `BS01_RUN_PENDING=1` to execute them (the red-baseline / un-pend run).
const Map<String, String> pendingACs = {
  'AC-8': 'A11Y-2',
  'AC-9': 'READOUT-6',
  'AC-10': 'READOUT-6',
  'AC-11': 'READOUT-6',
  'AC-12': 'A11Y-2',
};

/// The behaviour phases allowed to own a pending AC.
///
/// Used by the harness's own tests to reject a typo'd or stale owner in
/// [pendingACs].
const Set<String> behaviorPhases = {
  'COLOR-2',
  'COLOR-3',
  'READOUT-2',
  'READOUT-3',
  'READOUT-4',
  'READOUT-5',
  'READOUT-6',
  'A11Y-2',
};

/// Run-pending mode requested at build time via `--dart-define`.
///
/// `flutter test integration_test/` runs the tests in the app process *on the
/// device/simulator*, which does not inherit the host shell's environment — so
/// a `BS01_RUN_PENDING=1` env var set on the host never reaches [runPending]
/// there. A compile-time `--dart-define=BS01_RUN_PENDING=true` does. (The
/// `Platform.environment` path below still serves any host-process run.)
const bool _runPendingDefine =
    bool.fromEnvironment('BS01_RUN_PENDING', defaultValue: false);

/// Whether pending ACs should execute (the run-pending mode).
///
/// On-device: pass `--dart-define=BS01_RUN_PENDING=true`. Host-process runs may
/// also set the `BS01_RUN_PENDING=1` environment variable.
bool get runPending =>
    _runPendingDefine || Platform.environment['BS01_RUN_PENDING'] == '1';

/// The reason to skip [acId] in this run, or null if it should execute.
///
/// An un-pended AC (absent from [pendingACs]) always runs; a pending AC runs
/// only in run-pending mode. Because the result drives `testWidgets`' native
/// `skip`, a not-yet-built AC's body never executes in the default run — it is
/// *skipped*, never *failed*. [forceRunPending] overrides the ambient
/// [runPending] mode so the gate's own tests can assert both modes
/// deterministically without touching the environment.
String? pendingSkipReason(String acId, {bool? forceRunPending}) {
  final owner = pendingACs[acId];
  if (owner == null) return null;
  if (forceRunPending ?? runPending) return null;
  return 'pending $owner — --dart-define=BS01_RUN_PENDING=true to run';
}

/// Registers an AC acceptance test wired to the pending gate.
///
/// Used by ITEST-2/3 for every AC; skipping follows [pendingSkipReason].
void acTestWidgets(
  String acId,
  String description,
  WidgetTesterCallback body,
) {
  final reason = pendingSkipReason(acId);
  final name = reason == null
      ? '$acId: $description'
      : '$acId: $description ($reason)';
  testWidgets(name, body, skip: reason != null);
}

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one readout scenario.
///
/// Holds the recording sinks the scenario injected so the Thens can read what
/// the app drove them with (AC-8, AC-12), and exposes the `when…` actions the
/// painter takes on the Readout screen.
class ReadoutHarness {
  ReadoutHarness(this.tester, {required this.speech, required this.haptics});

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app (AC-8).
  final FakeSpeech speech;

  /// The recording haptics sink injected into the app (AC-12).
  final FakeHaptics haptics;

  /// Selects colour [space] in the selector.
  Future<void> whenSelectSpace(ReadoutSpace space) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(SpaceSelector.selectorKey),
        matching:
            find.widgetWithText(ChoiceChip, SpaceSelector.labelFor(space)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Asks to speak the whole readout.
  Future<void> whenSpeak() async {
    await tester.tap(find.byKey(ActionsBar.speakKey));
    await tester.pumpAndSettle();
  }

  /// Carries the reading into comparison [slot].
  Future<void> whenCompareAs(ComparisonSlot slot) async {
    final key = slot == ComparisonSlot.a
        ? ActionsBar.compareAKey
        : ActionsBar.compareBKey;
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  /// Starts a recipe search from the reading.
  Future<void> whenFindRecipes() async {
    await tester.tap(find.byKey(ActionsBar.recipesKey));
    await tester.pumpAndSettle();
  }

  /// Acknowledges a just-captured reading.
  Future<void> whenAcknowledge() async {
    await tester.tap(find.byKey(ActionsBar.acknowledgeKey));
    await tester.pumpAndSettle();
  }
}

/// Opens the Readout screen on [sample] in the fully assembled app.
///
/// Builds the real app via the production `buildApp` entry with the fixture
/// injected through `AppDependencies.initialSample` and the platform sinks
/// faked; colour-science is the real `ColorScienceImpl`. Returns a
/// [ReadoutHarness] over the booted app.
Future<ReadoutHarness> givenReadoutOf(
  WidgetTester tester,
  Sample sample,
) async {
  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  await tester.pumpWidget(
    buildApp(
      AppDependencies(
        colorScience: const ColorScienceImpl(),
        speech: speech,
        haptics: haptics,
        initialSample: sample,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ReadoutHarness(tester, speech: speech, haptics: haptics);
}

/// Opens the Readout screen on [sample] as a *just-captured* reading (AC-12).
///
/// bs-01 has no capture flow yet (capture is bs-02, D-1), so a capture is
/// simulated by marking the injected sample just-captured; the readout then
/// renders exactly as it would straight after a capture.
Future<ReadoutHarness> givenJustCapturedReadoutOf(
  WidgetTester tester,
  Sample sample,
) {
  return givenReadoutOf(tester, sample.copyWith(justCaptured: true));
}
