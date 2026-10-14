// Acceptance-suite harness for bs-10 Daltonization and colour-distinction aids
// (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and independent reference the AC
// tests (ITEST-2, ITEST-3) are written against. The suite drives the *real*
// assembled app through the single production `buildApp` entry (bs-01 D-7): a
// scenario assembles the app with the painter's stored colour-vision profile
// and an app-wide [DisplayController], turns daltonization on through the
// shipped settings toggle (CONTROL-1), and observes the result through the
// rendered swatch and the [DisplayReadEndpoint] (`daltonization` +
// `displayedColor`, DALT-2). Only the platform sinks are faked (bs-01's
// `FakeSpeech`/`FakeHaptics`) and the on-device store is an
// [InMemoryPersistentStore] behind the production `PersistentStore` contract
// (bs-07's fixture pattern); no colour-vision maths is faked — the real
// `daltonize` / `displayedSwatchColor` render path is exercised.
//
// The remap (AC-1/AC-5) is graded against [referenceDaltonize], an
// **independent** in-harness error-redistribution remap built on bs-08's
// equally independent [referenceProjectDichromat] (imported here), so the
// shipped `daltonize` is never graded against itself — the same discipline
// bs-03/bs-04/bs-08 used for the confusion check, ΔE00 and the simulation.
// AC-7's "distinct from simulation" contrast uses the shipped projection
// (`projectDichromat`) directly, since there the two shipped transforms are
// compared to each other.
//
// The pending gate (all 10 ACs → owning phase) lives in `bs10/pending.dart`
// (seeded in DALT-1); this harness re-exports it (and the fakes) so an AC test
// imports only this file. bs-08's `display_harness.dart` is *not* re-exported —
// it carries bs-08's own pending gate (`bs08/pending.dart`), whose names would
// collide with bs-10's — so [referenceProjectDichromat] and [labDistance] are
// imported from it with a `show` clause instead.
//
// Fixture identifiers mirror the plan's names, and the AC catalogue references
// them verbatim, so this file opts out of lowerCamelCase for the CIELAB
// constant.
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/capture/source/capture_source.dart';
import 'package:paint_color_assistant/capture/source/software_capture_source.dart';
import 'package:paint_color_assistant/color_science/color_science.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_read_endpoint.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/space_selector.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/store/cvd_profile_store.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';
import 'package:paint_color_assistant/widgets/provenance_badge.dart';

// The independent dichromat projection (and its cheap CIELAB distance) bs-08's
// ITEST-1 built, reused unchanged as the basis for bs-10's independent remap.
// Imported with `show` (not re-exported) so bs-08's pending gate — which
// `display_harness.dart` re-exports — does not collide with bs-10's.
import 'display_harness.dart' show referenceProjectDichromat;

import 'fakes/fake_capture_source.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate and the fakes so an AC test only needs to import
// this harness.
export 'bs10/pending.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';
// Re-export the independent projection + distance so an AC test (AC-7's
// contrast, the reference guards) imports only this harness.
export 'display_harness.dart' show labDistance, referenceProjectDichromat;

// ---------------------------------------------------------------------------
// Fixtures
//
// Colours are stored in canonical CIELAB (the domain's single source of truth).
// The AC tests render [screenSample] through the real app and grade the
// remapped swatch against [referenceDaltonize] of its CIELAB.
// ---------------------------------------------------------------------------

/// The CIELAB of the known chromatic swatch the daltonization scenarios render
/// ([screenSample]'s colour).
///
/// Reuses bs-08's proven display sample — a mid-lightness, muted
/// **yellow-green/olive** (L 55 / a −25 / b 30) that stays inside the sRGB gamut
/// for every dichromat projection yet **shifts clearly** under each type
/// (protan/deutan Δ ≈ 16, tritan Δ ≈ 71). The clear shift is what makes the
/// remap observable: [referenceDaltonize] redistributes exactly the chroma the
/// projection collapses, so a sample the projection barely moves would barely
/// remap. The harness guard `reference remap clearly shifts the screen sample
/// for every CvdType` asserts the shift against [referenceDaltonize].
const ColorCoordinates SCREEN_SAMPLE_LAB =
    ColorCoordinates(lightness: 55, a: -25, b: 30);

/// The known chromatic sample the app opens the Readout on for the daltonization
/// scenarios — carries [SCREEN_SAMPLE_LAB] with a measured provenance.
///
/// A measured-provenance [Sample] so the Readout renders a real reading (value,
/// label, swatch, provenance badge) the remap transforms (AC-1..AC-5), never
/// removing the label/value (AC-3) or the provenance badge's label/icon (AC-4).
/// The *same* sample is the one AC-9 surfaces on capture, readout and palette —
/// the "known swatch" remapped on every screen.
const Sample screenSample = Sample(
  name: 'Screen Swatch',
  coordinates: SCREEN_SAMPLE_LAB,
  provenance: Provenance(ProvenanceTier.measured),
);

/// The Capture scene that surfaces the known swatch on the **Capture** screen
/// for AC-9 — a noise-free software scene whose ground truth is
/// [SCREEN_SAMPLE_LAB], so the capture live-view reading is the same known
/// colour the Readout and Palette render. [givenDaltonizationOnCapture] builds a
/// [FakeCaptureSource] over it, opening `buildApp` on the Capture screen (D-7).
const SceneSpec captureScene = SceneSpec(groundTruth: SCREEN_SAMPLE_LAB);

/// A single paint carrying the known swatch's colour as its masstone — the swatch
/// the **Palette** screen renders for AC-9.
const Paint screenPaint = Paint(
  id: 'screen-swatch',
  name: 'Screen Swatch',
  medium: PaintMedium.oil,
  masstone: SCREEN_SAMPLE_LAB,
);

/// The one-paint palette [givenDaltonizationOnPalette] seeds so the Palette
/// screen surfaces exactly the known swatch ([screenPaint]) — the colour AC-9
/// asserts is remapped on the palette screen, same as on capture and readout.
const PaintPalette screenPalette =
    PaintPalette(name: 'Screen palette', paints: [screenPaint]);

/// The painter's stored colour-vision profile a scenario persists (AC-1/5/6/7).
///
/// A convenience constructor mirroring the plan's `savedProfile(type, severity)`
/// name: [givenDaltonization] persists the returned profile through the real
/// [CvdProfileStore] write-side (so a saved profile exists) and injects it as
/// `AppDependencies.cvdProfile`, the one profile the daltonization chokepoint
/// reads (D-3). [severity] defaults to a moderate 0.6 so the AC-5 control
/// (`savedProfile(deutan, strong)`) can show a *stronger* remap against it.
CvdProfile savedProfile(CvdType type, {double severity = 0.6}) =>
    CvdProfile(type: type, severity: severity);

/// The no-saved-profile store state (AC-10): pass as [givenDaltonization]'s
/// `storedProfile` to assemble over an **empty** [CvdProfileStore].
///
/// With nothing saved the app falls back to the const default profile (bs-07
/// D-3), so the daltonization control must consult the store — not the injected
/// `cvdProfile` — to know a profile was actually saved (D-4). The harness
/// exposes that store as [DaltonizationHarness.profileStore].
const CvdProfile? noProfile = null;

// ---------------------------------------------------------------------------
// Independent reference remap
//
// A standalone error-redistribution daltonization the AC tests grade the
// product's remapped swatch against, so AC-1/AC-5 never check the shipped
// `daltonize` against itself. It is built on bs-08's [referenceProjectDichromat]
// (itself independent of the shipped projection): the dichromat view is the
// colour the painter cannot tell from its confusers, so the chroma lost to that
// collapse is the signal to redistribute. This reference rotates that lost
// chroma 90° in the a*/b* plane and adds it back, scaled by severity — pushing
// confusable colours apart (distinction) rather than collapsing them
// (perception), which is precisely how daltonization differs from simulation
// (AC-7). It preserves lightness (daltonization is a chroma-redistribution aid)
// and is the identity at severity 0 (an unaffected painter needs no remap).
//
// This is one plausible transcription of the error-redistribution idea (bs-10
// D-2); the shipped `daltonize` (DALT-3) may use a different matrix, so the two
// are separate implementations and a mistyped coefficient in either is caught
// by the mismatch rather than mirrored. Test-only reference code; the shipped
// remap is `lib/a11y/cvd/daltonize.dart`'s `daltonize`.
// ---------------------------------------------------------------------------

/// The distinguishing remap of [original] for a painter with [profile] — the
/// **independent** reference AC-1/AC-5 grade the shipped `daltonize` against.
///
/// Redistributes the chroma the painter loses to their dichromacy (the
/// difference between [original] and its full [referenceProjectDichromat] view)
/// onto the orthogonal a*/b* axis, scaled by [CvdProfile.severity] and
/// preserving lightness. The identity at severity 0; a larger severity pushes a
/// confusable colour further from where it sat.
ColorCoordinates referenceDaltonize(ColorCoordinates original, CvdProfile profile) {
  final severity = profile.severity.clamp(0.0, 1.0);
  if (severity == 0) return original;
  // The painter's full dichromat view — the colour they cannot distinguish from
  // its confusers.
  final seen = referenceProjectDichromat(original, profile.type, severity: 1.0);
  // The chroma lost to that collapse (the confusion-axis error), in CIELAB.
  final lostA = original.a - seen.a;
  final lostB = original.b - seen.b;
  // Redistribute the lost chroma onto the orthogonal axis (a 90° rotation in the
  // a*/b* plane) so confusable colours are pushed apart, scaled by severity,
  // luminance preserved.
  return ColorCoordinates(
    lightness: original.lightness,
    a: original.a + severity * lostB,
    b: original.b - severity * lostA,
  );
}

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

/// The shared colour-space conversion (`labToSrgb`) — the *same* conversion the
/// render path and the shipped `daltonizeColor` bridge use; only the dichromat
/// **projection** behind [referenceDaltonize] is independent, so AC-1/AC-5 never
/// grade the shipped remap against itself.
const ColorScienceImpl _science = ColorScienceImpl();

/// The displayed sRGB [Color] of a CIELAB colour, via the shared conversion —
/// the colour `ColorChip` paints for a swatch carrying [lab].
Color displayColorOf(ColorCoordinates lab) {
  final SRGBColor s = _science.toSRGB(lab);
  return Color.fromARGB(255, s.red, s.green, s.blue);
}

/// The original (un-remapped) sRGB swatch colour the Readout renders for
/// [screenSample] — what `displayedColor` returns while daltonization is off,
/// and what the remapped swatch is graded against for a change.
final Color screenSwatchColor = displayColorOf(SCREEN_SAMPLE_LAB);

/// Whether two sRGB colours match within [tol] summed across the three channels
/// (each 0..1; 0.05 ≈ 13/255, ~4 per channel) — loose enough for the
/// sRGB→CIELAB→sRGB round-trip rounding in `daltonizeColor` (measured 0 for the
/// screen sample), tight enough to tell the original from a real remap of
/// [screenSample] for **every** CvdType.
///
/// Tightened from the scaffold's 0.094 by DALT-3 (the latitude this doc reserved
/// for the behaviour phases): the shipped remap — identical to
/// [referenceDaltonize] to the 8-bit swatch — shifts the sample ≈0.078 under
/// protan, ≈0.106 under deutan and ≈0.510 under tritan, so the scaffold's 0.094
/// could not separate the **protan** remap from the original (0.078 < 0.094),
/// defeating the "it changed" half of AC-1/AC-2's contract. 0.05 sits above the
/// round-trip rounding and below the smallest real remap, so all three register
/// as changed while an unremapped swatch still reads as the original.
bool colorNear(Color a, Color b, {double tol = 0.05}) =>
    (a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs() <= tol;

/// The colours of every circular-decoration display swatch currently rendered.
///
/// `ColorChip` is the shared display chokepoint, and it draws each swatch as a
/// circular `BoxDecoration` (the only circular decorations on the Readout), so
/// this reads the displayed / remapped swatch colours without a key the
/// behaviour phase has not defined. With daltonization on and simulation off,
/// one swatch per chip (the remapped colour); the original-alongside pair only
/// appears when a *simulation* is on (bs-08 AC-3), not under daltonization.
List<Color> displaySwatches(WidgetTester tester) {
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

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one bs-10 daltonization scenario.
///
/// Holds the recording [speech]/[haptics] sinks and the app-wide [controller]
/// the scenario injected, plus the [profileStore] (and its [backing]) the
/// scenario persists the painter's profile through, and [storedProfile] — the
/// profile the daltonization chokepoint reads (the saved one, or the const
/// default when none was saved). It exposes the `when…` actions the painter
/// takes (open the settings panel, toggle daltonization, save/clear the stored
/// profile) and the read seams for the Thens: [settings]/[daltonization] over
/// the live [DisplayReadEndpoint], [displayedColor] for the effective displayed
/// swatch colour, [displayedSwatches] for the rendered swatches, and finders for
/// the daltonization toggle and the no-saved-profile region.
///
/// Where a control's *behaviour* lands in a later phase, the `when…` still
/// drives the real shipped control (the toggle is wired — CONTROL-1; the
/// chokepoint routes through `daltonize` — DALT-2), so an AC test written now
/// fails cleanly at the red baseline on its Then (the remap DALT-3 adds), not on
/// a missing widget.
class DaltonizationHarness {
  /// Creates the driver over the booted app; the instances [givenDaltonization]
  /// injected so the Thens can read them.
  DaltonizationHarness(
    this.tester, {
    required this.speech,
    required this.haptics,
    required this.controller,
    required this.profileStore,
    required this.backing,
    required this.storedProfile,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app.
  final FakeSpeech speech;

  /// The recording haptic sink injected into the app.
  final FakeHaptics haptics;

  /// The app-wide display controller injected into the app — the same
  /// controller the [DisplayReadEndpoint] exposes and the shipped toggle drives.
  final DisplayController controller;

  /// The profile store (over [backing]) the scenario persists the painter's
  /// profile through — the write-side bs-07 ships (`save`) and the read-side the
  /// Thens observe (`load`/`count`), the way the AC-10 control must consult the
  /// store rather than the injected profile (D-4). The in-app read endpoint over
  /// this store is wired by CONTROL-2; for now the harness reads it directly.
  final CvdProfileStore profileStore;

  /// The persistent store backing [profileStore] — exposed so [whenClearProfile]
  /// can remove the saved document through the same contract production uses.
  final InMemoryPersistentStore backing;

  /// The profile the daltonization chokepoint reads for this scenario: the saved
  /// profile [givenDaltonization] persisted, or the const default (bs-07 D-3)
  /// when the store was left empty ([noProfile]). The Thens pass it to
  /// [displayedColor] and grade against `referenceDaltonize(_, storedProfile)`.
  final CvdProfile storedProfile;

  /// The live display settings behind every colour surface, read through the
  /// acceptance [DisplayReadEndpoint] the app wraps its tree in.
  DisplaySettings get settings => _endpoint.settings;

  /// Whether the display-only daltonization remap is on (AC-1/AC-2), read
  /// through the live endpoint.
  bool get daltonization => _endpoint.daltonization;

  /// The swatch colour the app displays for a true [original] under the current
  /// settings, for the scenario's [storedProfile] — the effective displayed
  /// colour, read through the one shared chokepoint the render path uses
  /// (AC-1/AC-2). With daltonization off it is [original]; with it on it is the
  /// remapped colour (identity until DALT-3).
  Color displayedColor(Color original) =>
      _endpoint.displayedColor(original, storedProfile);

  /// The colours of every circular display swatch currently rendered (the
  /// `ColorChip` chokepoint's swatches — AC-1/AC-9).
  List<Color> get displayedSwatches => displaySwatches(tester);

  /// The live acceptance endpoint exposing the display state and the effective
  /// displayed colour.
  DisplayReadEndpoint get _endpoint => tester
      .widget<DisplayReadEndpoint>(find.byKey(DisplayReadEndpoint.endpointKey));

  /// The open-display-settings entry (E2) the shared chrome shows on every
  /// screen — the daltonization toggle lives in the panel it opens.
  Finder get settingsEntry => find.byKey(DisplaySettingsButton.openKey);

  /// The settings panel surface (shown only while open).
  Finder get settingsPanel => find.byKey(DisplaySettingsScreen.panelKey);

  /// The bs-10 daltonization on/off toggle inside the open panel (CONTROL-1),
  /// wired to [DisplayController.setDaltonization].
  Finder get daltonizationToggle =>
      find.byKey(DisplaySettingsScreen.daltonizationKey);

  /// The bs-10 no-saved-profile region inside the open panel (CONTROL-1) — an
  /// empty placeholder now; CONTROL-2 (AC-10) fills it.
  Finder get noProfileRegion =>
      find.byKey(DisplaySettingsScreen.noProfileRegionKey);

  /// The provenance badge rendered for the reading (AC-4) — present on the
  /// Readout, carrying [screenSample]'s provenance label.
  Finder get provenanceBadge => find.byType(ProvenanceBadge);

  /// The Readout's numeric colour reading for the selected space (AC-8) — a
  /// public read of the sample's **stored** colour values as rendered text
  /// (`SpaceSelector.valuesKey`).
  ///
  /// It is derived from the stored `Sample.coordinates` only — never from the
  /// display remap, which transforms the swatch colour alone — so a daltonized
  /// render must leave it unchanged. AC-8 captures it off and asserts it holds
  /// while the remap is on (the stored values are untouched) with the swatch as
  /// the control that the display did change.
  String get storedValuesText =>
      tester.widget<Text>(find.byKey(SpaceSelector.valuesKey)).data!;

  /// Opens the display and simulation settings panel from the current screen
  /// (the E2 entry the shared chrome shows on every screen).
  Future<void> whenOpenSettings() async {
    await tester.tap(settingsEntry);
    await tester.pumpAndSettle();
  }

  /// Closes the settings panel, returning to the screen underneath.
  Future<void> whenCloseSettings() async {
    await tester.tap(find.byKey(DisplaySettingsScreen.closeKey));
    await tester.pumpAndSettle();
  }

  /// Turns daltonization [on] through the shipped panel toggle (CONTROL-1). The
  /// panel must be open ([whenOpenSettings]).
  ///
  /// Taps the toggle only when it is not already in the requested state, so a
  /// scenario reaches the state it names regardless of where it started.
  Future<void> whenSetDaltonization({required bool on}) async {
    if (daltonization == on) return;
    await tester.tap(daltonizationToggle);
    await tester.pumpAndSettle();
  }

  /// Persists [profile] as the painter's stored profile through the real
  /// [CvdProfileStore] write-side (AC-6) — the public save bs-07 ships.
  ///
  /// This writes the store only; it does **not** reconfigure the live
  /// `AppDependencies.cvdProfile` the already-built chokepoint reads, so a remap
  /// recomputes off a saved change only once DALT-11 wires the store listener —
  /// which is exactly what the pending AC-6 test asserts (and fails on at the
  /// red baseline).
  Future<void> whenSaveProfile(CvdProfile profile) async {
    await profileStore.save(profile);
    await tester.pumpAndSettle();
  }

  /// Clears the stored profile through the same persistence contract production
  /// uses, leaving the store empty (`hasSavedProfile` false — AC-10).
  Future<void> whenClearProfile() async {
    await backing.delete(CvdProfileStore.collection, CvdProfileStore.documentId);
    await tester.pumpAndSettle();
  }
}

/// Opens the fully assembled app on the Readout for [sample], ready for a bs-10
/// daltonization scenario.
///
/// Builds the real app via the single production `buildApp` entry with the
/// recording [FakeSpeech]/[FakeHaptics] sinks, the real `ColorScienceImpl`, an
/// injected [DisplayController] seeded with [initialSettings] (so a scenario can
/// start with a simulation already chosen, and the Thens can read the live
/// controller), and an [InMemoryPersistentStore] behind the production
/// [CvdProfileStore]. When [storedProfile] is non-null it is persisted through
/// that store (a saved profile exists) and loaded as the app's
/// `AppDependencies.cvdProfile`; [noProfile] leaves the store empty, so the app
/// falls back to the const default profile (bs-07 D-3) while the store reports
/// no saved profile (AC-10). No entry marker is set, so the app opens on bs-01's
/// Readout for [sample]. Returns a [DaltonizationHarness] over the booted app.
Future<DaltonizationHarness> givenDaltonization(
  WidgetTester tester, {
  Sample sample = screenSample,
  CvdProfile? storedProfile = const CvdProfile(type: CvdType.deutan, severity: 0.6),
  DisplaySettings initialSettings = const DisplaySettings(),
}) =>
    _assembleDaltonization(
      tester,
      storedProfile: storedProfile,
      initialSettings: initialSettings,
      initialSample: sample,
    );

/// Opens the assembled app on the **Capture** screen with the known swatch
/// ([captureScene]) in the live view — the second of AC-9's three screens.
///
/// A capture source is present, so `buildApp` opens on the Capture screen (D-7).
/// The live feed is a continuous stream, so this mounts with a bounded run of
/// frames rather than `pumpAndSettle` (which would spin on the feed — the
/// convention `givenCaptureOf` follows). [initialSettings] seeds the display
/// state (AC-9 passes `daltonization: true`), so the Thens read the remapped
/// swatch directly without tapping the on-screen toggle — whose `pumpAndSettle`
/// would likewise hang on the live feed.
Future<DaltonizationHarness> givenDaltonizationOnCapture(
  WidgetTester tester, {
  CvdProfile? storedProfile = const CvdProfile(type: CvdType.deutan, severity: 0.6),
  DisplaySettings initialSettings = const DisplaySettings(),
}) =>
    _assembleDaltonization(
      tester,
      storedProfile: storedProfile,
      initialSettings: initialSettings,
      captureSource: FakeCaptureSource(captureScene),
      settle: _SettleMode.framesOnly,
    );

/// Opens the assembled app on the **Palette** screen showing the known swatch
/// ([screenPalette]) — the third of AC-9's three screens.
///
/// A palette entry is present (and no capture/comparison/recipes entry), so
/// `buildApp` opens on the Palette home screen (D-7) over a one-paint catalogue
/// whose single paint's masstone is [SCREEN_SAMPLE_LAB].
Future<DaltonizationHarness> givenDaltonizationOnPalette(
  WidgetTester tester, {
  CvdProfile? storedProfile = const CvdProfile(type: CvdType.deutan, severity: 0.6),
  DisplaySettings initialSettings = const DisplaySettings(),
}) =>
    _assembleDaltonization(
      tester,
      storedProfile: storedProfile,
      initialSettings: initialSettings,
      paletteEntry: const PaletteEntry(),
      paletteSource: const InMemoryPaletteSource(catalogue: [screenPalette]),
    );

/// How [_assembleDaltonization] drives the first frames after mounting: the
/// usual `pumpAndSettle`, or a bounded run of frames for a screen whose live
/// feed never goes idle (Capture).
enum _SettleMode { pumpAndSettle, framesOnly }

/// Assembles the real app through `buildApp` for a daltonization scenario,
/// shared by [givenDaltonization] (Readout), [givenDaltonizationOnCapture] and
/// [givenDaltonizationOnPalette]. The entry fields ([initialSample],
/// [captureSource], [paletteEntry], [paletteSource]) select which screen
/// `buildApp` opens on (its entry precedence, D-7).
Future<DaltonizationHarness> _assembleDaltonization(
  WidgetTester tester, {
  required CvdProfile? storedProfile,
  required DisplaySettings initialSettings,
  Sample initialSample = screenSample,
  CaptureSource? captureSource,
  PaletteEntry? paletteEntry,
  PaletteSource paletteSource = const InMemoryPaletteSource(),
  _SettleMode settle = _SettleMode.pumpAndSettle,
}) async {
  // Open a fresh app each time, so a repeated `given…` in one test does not
  // reuse the previous screen's State (mirrors the other bs harnesses).
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final backing = InMemoryPersistentStore();
  final profileStore = CvdProfileStore(backing);
  if (storedProfile != null) {
    await profileStore.save(storedProfile);
  }
  // The profile the pipeline reads (bs-07 D-3): the saved profile, or the const
  // default when the store is empty — exactly what production's `loadCvdProfile`
  // resolves at startup.
  final injectedProfile = await loadCvdProfile(profileStore);
  final controller = DisplayController(
    defaultSimulationType: injectedProfile.type,
    initialSettings: initialSettings,
  );
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    cvdProfile: injectedProfile,
    initialSample: initialSample,
    captureSource: captureSource,
    paletteEntry: paletteEntry,
    paletteSource: paletteSource,
    store: backing,
    displayController: controller,
  );
  await tester.pumpWidget(buildApp(deps));
  switch (settle) {
    case _SettleMode.pumpAndSettle:
      await tester.pumpAndSettle();
    case _SettleMode.framesOnly:
      // The Capture live feed never goes idle, so advance a bounded run of
      // frames (enough for the first sample to render) instead of spinning in
      // `pumpAndSettle`.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
  }
  return DaltonizationHarness(
    tester,
    speech: speech,
    haptics: haptics,
    controller: controller,
    profileStore: profileStore,
    backing: backing,
    storedProfile: injectedProfile,
  );
}
