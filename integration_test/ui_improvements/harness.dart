// Acceptance-suite harness for bs-20 UI improvements (ITEST-1).
//
// The Given/When/Then vocabulary and fixtures the AC tests (ITEST-2, ITEST-3)
// are written against. The suite drives the *real* assembled app through the
// single production `buildApp` entry (D-7): it opens on bs-01's Readout for the
// injected [sample], with an app-wide [DisplayController] reachable so a
// scenario can read the shipped accessibility-features toggle (AC-6) and turn
// it on to reveal the Speak control (AC-7/AC-8). Only the leaf platform sinks
// are faked — bs-01's recording `FakeSpeech` / `FakeHaptics` and the default
// `AppRouter` — and the fixture sample is supplied; no colour maths is faked
// (the real `ColorScienceImpl` derives every reading the readout shows).
//
// The pending gate (all 9 ACs → owning phase) lives in `pending.dart`; this
// harness re-exports it (and the fakes) so an AC test imports only this file.
//
// Fixture identifiers mirror the master plan's names, and the AC catalogue
// references them verbatim; this file opts out of lowerCamelCase for the CIELAB
// constant the terracotta fixture is built from.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';
import 'package:paint_color_assistant/readout/all_spaces_region.dart';
import 'package:paint_color_assistant/readout/readout_controller.dart';
import 'package:paint_color_assistant/readout/space_definition.dart';
import 'package:paint_color_assistant/readout/value_region.dart';
import 'package:paint_color_assistant/readout/value_scale.dart';
import 'package:paint_color_assistant/widgets/color_chip.dart';

import '../fakes/fake_haptics.dart';
import '../fakes/fake_speech.dart';

// Re-export the pending gate and the fakes (which live one level up, at
// `integration_test/fakes/`) so an AC test imports only this harness.
// [ReadoutSpace] is re-exported too, since the AC-4 / AC-5 tests name each
// colour space.
export '../fakes/fake_haptics.dart';
export '../fakes/fake_speech.dart';
export 'pending.dart';
export 'package:paint_color_assistant/readout/readout_controller.dart'
    show ReadoutSpace;

// ---------------------------------------------------------------------------
// Fixtures
//
// Samples are stored in canonical CIELAB (the domain's single source of truth);
// the derived readings a scenario asserts (Munsell notation, value word, the
// colour-space values) are produced by the real `ColorScienceImpl` from these
// coordinates — the fixtures fix only the inputs those derivations run on.
// ---------------------------------------------------------------------------

/// Warm terracotta — the bs-01 sample (CIELAB L 58, a 25.27, b 22.75, which the
/// real engine reads as Munsell 10R 5.5/6). Drives AC-1 (hero card), AC-4 (all
/// spaces shown together), AC-5 (opening a space name) and AC-9 ("Color" copy).
const Sample warmTerracotta = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A low-value sample whose Munsell value reads **2** — the AC-2 scale-marking
/// fixture.
///
/// Munsell value is a pure function of lightness (ASTM D1535, half-step
/// rounded): CIELAB L 20 maps to value ≈ 1.98, which rounds to 2.0, so the 0–10
/// scale marks the step at 2. A small chroma keeps it a real colour (not a
/// neutral). The AC-2 test (READOUT-5) re-asserts the fixture's value through
/// the public readout before marking the scale, so the "value 2" Given is
/// checked, not assumed.
const Sample value2Sample = Sample(
  name: 'Deep Shadow',
  coordinates: ColorCoordinates(lightness: 20, a: 8, b: 8),
  provenance: Provenance(ProvenanceTier.measured),
);

/// A plain mid sample — the AC-3 (equal-size swatches) and AC-7/AC-8 (Speak
/// visibility) fixture, where the exact colour does not matter, only that the
/// readout renders a real reading with both swatches and the actions bar.
const Sample anySample = Sample(
  name: 'Any Sample',
  coordinates: ColorCoordinates(lightness: 50, a: 10, b: 10),
  provenance: Provenance(ProvenanceTier.measured),
);

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one bs-20 readout/settings scenario.
///
/// Holds the recording [speech] / [haptics] sinks and the app-wide [controller]
/// the scenario injected, and exposes the `when…` actions the painter takes
/// (open the display settings panel, turn accessibility features on) plus the
/// keyed finders the Thens anchor on — the readout regions from the READOUT-2
/// shells and the accessibility toggle from the A11Y-1 shell.
///
/// Where a region's *behaviour* lands in a later phase, the finder still
/// resolves (the shell renders a keyed placeholder — READOUT-2 / A11Y-1), so an
/// AC test written now fails cleanly at the red baseline on its Then (the
/// render the behaviour phase adds), not on a missing widget.
class UiHarness {
  /// Creates the driver over the booted app; [speech] / [haptics] / [controller]
  /// are the instances [givenReadoutOf] injected so the Thens can read them.
  UiHarness(
    this.tester, {
    required this.speech,
    required this.haptics,
    required this.controller,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app. The readout's "Speak this
  /// readout" control speaks through it once accessibility features reveal it
  /// (AC-7/AC-8).
  final FakeSpeech speech;

  /// The recording haptic sink injected into the app.
  final FakeHaptics haptics;

  /// The app-wide display controller injected into the app, so a Then can read
  /// the live settings directly and a When can turn accessibility features on.
  /// It is the same controller the shipped settings panel drives.
  final DisplayController controller;

  /// The live display settings every surface reads (read straight off the
  /// injected [controller] — the one source of truth the panel also drives).
  DisplaySettings get settings => controller.settings;

  // --- Readout finders (keyed anchors from the READOUT-2 shells) ------------

  /// The value region (lightness + grayscale + displayed colour).
  Finder get valueRegion => find.byKey(ValueRegion.regionKey);

  /// The value-hero card anchor (AC-1).
  Finder get heroCard => find.byKey(ValueRegion.heroCardKey);

  /// The grayscale preview swatch (one half of the AC-3 equal-size pair).
  Finder get grayscaleSwatch => find.byKey(ValueRegion.grayscaleKey);

  /// The displayed-colour swatch — the single [ColorChip] in the value region
  /// (the other half of the AC-3 equal-size pair).
  Finder get displayedColorChip => find.descendant(
        of: valueRegion,
        matching: find.byType(ColorChip),
      );

  /// The 0–10 Munsell value scale anchor (AC-2).
  Finder get valueScale => find.byKey(ValueScale.scaleKey);

  /// The all-colour-spaces region anchor (AC-4).
  Finder get allSpaces => find.byKey(AllSpacesRegion.regionKey);

  /// The tappable name anchor for colour [space] (AC-5).
  Finder spaceName(ReadoutSpace space) =>
      find.byKey(SpaceDefinition.nameKey(space));

  /// The revealed definition (+ example) anchor for colour [space] (AC-5).
  Finder spaceDefinition(ReadoutSpace space) =>
      find.byKey(SpaceDefinition.definitionKey(space));

  /// The "Speak this readout" control (AC-7/AC-8) — present on the readout only
  /// once accessibility features reveal it (READOUT-7).
  Finder get speakControl => find.byKey(ActionsBar.speakKey);

  // --- Settings finders (the A11Y-1 shell, via the app-wide chrome) ---------

  /// The open-display-settings entry the shared chrome shows on every screen.
  Finder get settingsEntry => find.byKey(DisplaySettingsButton.openKey);

  /// The settings panel surface (shown only while open).
  Finder get settingsPanel => find.byKey(DisplaySettingsScreen.panelKey);

  /// The bs-20 accessibility-features toggle (AC-6).
  Finder get accessibilityToggle =>
      find.byKey(DisplaySettingsScreen.accessibilityFeaturesKey);

  // --- When actions ---------------------------------------------------------

  /// Opens the display settings panel from the current screen (the entry the
  /// shared chrome shows on every screen), so the Thens can read the
  /// accessibility-features toggle (AC-6).
  Future<void> whenOpenSettings() async {
    await tester.tap(settingsEntry);
    await tester.pumpAndSettle();
  }

  /// Closes the settings panel, returning to the screen underneath.
  Future<void> whenCloseSettings() async {
    await tester.tap(find.byKey(DisplaySettingsScreen.closeKey));
    await tester.pumpAndSettle();
  }

  /// Turns the accessibility-features set [on] through the app-wide controller
  /// and re-pumps (AC-7/AC-8).
  ///
  /// Drives the same `DisplayController.setAccessibilityFeatures` the shipped
  /// panel toggle drives, so the readout sees the live flag through
  /// `DisplayScope` exactly as it would from the panel. A no-op when already in
  /// the requested state, so a scenario reaches the state it names regardless of
  /// where it started.
  Future<void> whenSetAccessibilityFeatures({required bool on}) async {
    if (settings.accessibilityFeatures == on) return;
    controller.setAccessibilityFeatures(on);
    await tester.pumpAndSettle();
  }
}

/// Opens the fully assembled app on the Readout for [sample], ready for a bs-20
/// readout/settings scenario.
///
/// Builds the real app via the single production `buildApp` entry (D-7) with the
/// recording [FakeSpeech] / [FakeHaptics] sinks, the real `ColorScienceImpl` and
/// an injected [DisplayController] seeded with [initialSettings] — so a scenario
/// can start with accessibility features already on, and the Thens can read the
/// live controller. No entry marker is set, so the app opens on bs-01's Readout
/// for [sample] (the screen every bs-20 readout AC acts on). Returns a
/// [UiHarness] over the booted app.
///
/// A fresh app is pumped each call (a `SizedBox` first) so a repeated
/// `givenReadoutOf` in one test does not reuse the previous screen's `State`
/// (mirrors the sibling bs harnesses).
Future<UiHarness> givenReadoutOf(
  WidgetTester tester,
  Sample sample, {
  DisplaySettings initialSettings = const DisplaySettings(),
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final controller = DisplayController(initialSettings: initialSettings);
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    initialSample: sample,
    displayController: controller,
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return UiHarness(
    tester,
    speech: speech,
    haptics: haptics,
    controller: controller,
  );
}
