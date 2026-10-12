// Acceptance-suite harness for bs-08 Display, simulation and spoken output
// (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and independent reference the AC
// tests (ITEST-2, ITEST-3) are written against. The suite drives the *real*
// assembled app through the single production `buildApp` entry (D-7): it opens
// on bs-01's Readout for the injected [displaySample], with the app-wide
// [DisplayController] and the [RepeatableSpeech] wrapping a recording
// [FakeSpeech] both reachable, so a scenario sets the display settings through
// the shipped panel (E2 → E46/E47/E48) and observes the result through the
// rendered tree and the [DisplayReadEndpoint]. Only the platform sinks are
// faked (bs-01's `FakeSpeech`/`FakeHaptics`); no colour-vision maths is faked —
// the real `simulateColor` / `projectDichromat` render path is exercised, and a
// scenario's expected simulated colour is graded against
// [referenceProjectDichromat], an **independent** in-harness Viénot dichromat
// projection, so the shipped projection is never graded against itself
// (the same discipline bs-03/bs-04 used for the confusion check and ΔE00).
//
// The pending gate (all 10 ACs → owning phase) lives in `bs08/pending.dart`
// (seeded in DISPLAY-1); this harness re-exports it (and the fakes) so an AC
// test imports only this file.
//
// Fixture identifiers mirror the plan's names, and the AC catalogue references
// them verbatim, so this file opts out of lowerCamelCase for the CIELAB
// constants.
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/repeatable_speech.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/app/router.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/display/display_controller.dart';
import 'package:paint_color_assistant/display/display_read_endpoint.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/display/settings_screen.dart';
import 'package:paint_color_assistant/display/spoken_output_panel.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/actions_bar.dart';

import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate and the fakes so an AC test only needs to import
// this harness.
export 'bs08/pending.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';
// AC-9 drives the two comparison slots through the picker; re-export the slot
// enum so an AC test imports only this harness.
export 'package:paint_color_assistant/app/router.dart' show ComparisonSlot;

// ---------------------------------------------------------------------------
// Fixtures
//
// Colours are stored in canonical CIELAB (the domain's single source of truth).
// The AC tests render [displaySample] through the real app and grade the
// simulated swatch against [referenceProjectDichromat] of its CIELAB.
// ---------------------------------------------------------------------------

/// The CIELAB of the known chromatic swatch the display scenarios render
/// ([displaySample]'s colour).
///
/// Chosen deliberately: a mid-lightness, muted **yellow-green/olive** (L 55 /
/// a −25 / b 30, sRGB ≈ (105, 142, 78)) that is clearly **non-grey** (so
/// grayscale is observable, AC-5/AC-6) and clearly **shifts under each dichromat
/// projection** while staying inside the sRGB gamut for all three
/// (protan/deutan Δ ≈ 16, tritan Δ ≈ 71 — simulation is observable for every
/// type, AC-3/AC-4). A warm, high-chroma colour was rejected because the Viénot
/// tritan projection sends it far out of gamut (a clamped corner makes a poor
/// swatch to grade). The harness guard `reference projection shifts the display
/// sample for every CvdType` asserts the shift against [referenceProjectDichromat].
const ColorCoordinates DISPLAY_SAMPLE_LAB =
    ColorCoordinates(lightness: 55, a: -25, b: 30);

/// The known chromatic sample the app opens the Readout on for the display
/// scenarios — carries [DISPLAY_SAMPLE_LAB].
///
/// A measured-provenance [Sample] so the Readout renders a real reading (value,
/// label, swatch) the simulation / grayscale views transform (AC-2..AC-7) and
/// the readout can be spoken (AC-8/AC-9).
const Sample displaySample = Sample(
  name: 'Display Swatch',
  coordinates: DISPLAY_SAMPLE_LAB,
  provenance: Provenance(ProvenanceTier.measured),
);

/// The painter's injected colour-vision profile the settings default from
/// (D-2) — a full deutan, matching `AppDependencies`' shipped default.
///
/// The settings panel pre-selects this type when simulation is first turned on
/// (the AC-3/AC-4 default path), and the painter may still choose any type.
const CvdProfile cvdProfileFixture = CvdProfile(type: CvdType.deutan);

/// A second known saved sample the AC-9 comparison fills its **B** slot from
/// (slot A takes [displaySample]).
///
/// A distinct colour (a cool blue-violet, clearly apart from [displaySample]'s
/// olive) so the pair yields a real comparison and its spoken phrasing differs
/// from the single reading's — the AC-9 Then asserts the two spoken utterances
/// are distinct, both recorded by the one injected sink.
const Sample compareSampleB = Sample(
  name: 'Compare Swatch',
  coordinates: ColorCoordinates(lightness: 45, a: 20, b: -35),
  provenance: Provenance(ProvenanceTier.measured),
);

// ---------------------------------------------------------------------------
// Independent reference dichromat projection
//
// A standalone Viénot 1999 / Brettel–Viénot–Mollon dichromat simulation the AC
// tests grade the product's simulated swatch against, so AC-3/AC-4 never check
// the shipped `projectDichromat` against itself. It mirrors the shipped
// pipeline (CIELAB → XYZ → linear sRGB → LMS → drop the missing cone onto the
// surviving plane → blend by severity → back to CIELAB) but is a separate
// transcription: the colour-space and LMS↔RGB matrices are written here as
// literal published constants (the shipped file instead inverts its matrices at
// run time), so a mistyped coefficient in either implementation is caught by
// the mismatch rather than mirrored. This is test-only reference code; the
// shipped projection is `lib/a11y/cvd/confusion_check.dart`'s `projectDichromat`.
// ---------------------------------------------------------------------------

/// CIELAB white point (D65), the same reference white the domain uses.
const double _xn = 0.95047, _yn = 1.0, _zn = 1.08883;

/// The CIE L*a*b* linearity knee (t³ threshold on the forward transform).
const double _labEpsilon = 0.008856;

/// Linear sRGB (D65) → CIE XYZ.
const List<List<double>> _rgbToXyz = [
  [0.4124564, 0.3575761, 0.1804375],
  [0.2126729, 0.7151522, 0.0721750],
  [0.0193339, 0.1191920, 0.9503041],
];

/// CIE XYZ → linear sRGB (the literal inverse of [_rgbToXyz]).
const List<List<double>> _xyzToRgb = [
  [3.2404542, -1.5371385, -0.4985314],
  [-0.9692660, 1.8760108, 0.0415560],
  [0.0556434, -0.2040259, 1.0572252],
];

/// Linear sRGB → LMS (Viénot 1999).
const List<List<double>> _rgbToLms = [
  [17.8824, 43.5161, 4.11935],
  [3.45565, 27.1554, 3.86714],
  [0.0299566, 0.184309, 1.46709],
];

/// LMS → linear sRGB (the literal inverse of [_rgbToLms], Viénot 1999).
const List<List<double>> _lmsToRgb = [
  [0.0809444479, -0.130504409, 0.116721066],
  [-0.0102485335, 0.0540193266, -0.113614708],
  [-0.000365296938, -0.00412161469, 0.693511405],
];

/// The LMS cone-drop plane for protan (reconstructs L from M and S).
const List<List<double>> _protanPlane = [
  [0.0, 2.02344, -2.52581],
  [0.0, 1.0, 0.0],
  [0.0, 0.0, 1.0],
];

/// The LMS cone-drop plane for deutan (reconstructs M from L and S).
const List<List<double>> _deutanPlane = [
  [1.0, 0.0, 0.0],
  [0.494207, 0.0, 1.24827],
  [0.0, 0.0, 1.0],
];

/// The LMS cone-drop plane for tritan (reconstructs S from L and M).
const List<List<double>> _tritanPlane = [
  [1.0, 0.0, 0.0],
  [0.0, 1.0, 0.0],
  [-0.395913, 0.801109, 0.0],
];

/// How colour [original] appears to a painter with dichromacy [type] at
/// [severity] — the **independent** reference projection AC-3/AC-4 grade against.
///
/// Numerically equivalent to the shipped `projectDichromat` (same Viénot model)
/// but a separate implementation, so it discriminates a transcription bug in
/// either. [severity] blends between the original colour (0 — unaffected) and
/// the full dichromat projection (1); it defaults to 1 (full), the clearest
/// case, matching [CvdProfile]'s default.
ColorCoordinates referenceProjectDichromat(
  ColorCoordinates original,
  CvdType type, {
  double severity = 1.0,
}) {
  final lms = _apply(_rgbToLms, _apply(_xyzToRgb, _labToXyz(original)));
  final projected = _apply(_planeFor(type), lms);
  final blended = <double>[
    for (var i = 0; i < 3; i++) lms[i] + severity * (projected[i] - lms[i]),
  ];
  return _xyzToLab(_apply(_rgbToXyz, _apply(_lmsToRgb, blended)));
}

/// The cone-drop plane for dichromacy [type].
List<List<double>> _planeFor(CvdType type) {
  switch (type) {
    case CvdType.protan:
      return _protanPlane;
    case CvdType.deutan:
      return _deutanPlane;
    case CvdType.tritan:
      return _tritanPlane;
  }
}

/// Multiplies 3×3 matrix [m] by 3-vector [v].
List<double> _apply(List<List<double>> m, List<double> v) => [
      for (final row in m) row[0] * v[0] + row[1] * v[1] + row[2] * v[2],
    ];

/// CIELAB → CIE XYZ (D65), on the 0..1 Y scale.
List<double> _labToXyz(ColorCoordinates c) {
  final fy = (c.lightness + 16) / 116;
  final fx = fy + c.a / 500;
  final fz = fy - c.b / 200;
  double inverse(double t) {
    final cubed = t * t * t;
    return cubed > _labEpsilon ? cubed : (t - 16 / 116) / 7.787;
  }

  return [_xn * inverse(fx), _yn * inverse(fy), _zn * inverse(fz)];
}

/// CIE XYZ (D65) → CIELAB.
ColorCoordinates _xyzToLab(List<double> xyz) {
  double forward(double t) =>
      t > _labEpsilon ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  final fx = forward(xyz[0] / _xn);
  final fy = forward(xyz[1] / _yn);
  final fz = forward(xyz[2] / _zn);
  return ColorCoordinates(
    lightness: 116 * fy - 16,
    a: 500 * (fx - fy),
    b: 200 * (fy - fz),
  );
}

/// The straight-line CIELAB distance between [a] and [b].
///
/// A cheap reference distance the harness guards and the AC tests use to say
/// "clearly shifted" / "within tolerance" without pulling in the shipped ΔE00
/// metric (which bs-04 graded against its own reference). Not a perceptual
/// metric — just √(ΔL² + Δa² + Δb²).
double labDistance(ColorCoordinates a, ColorCoordinates b) {
  final dl = a.lightness - b.lightness;
  final da = a.a - b.a;
  final db = a.b - b.b;
  return math.sqrt(dl * dl + da * da + db * db);
}

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one bs-08 display/speech scenario.
///
/// Holds the recording [speech] sink and [haptics] the scenario injected and the
/// app-wide [controller] it injected, and exposes the `when…` actions the
/// painter takes (open the settings panel, choose a simulation, set the
/// severity, toggle grayscale, speak the readout, repeat the last spoken
/// output) plus the read seams for the Thens: [settings] over the live
/// [DisplayReadEndpoint], [appSpeech] for the one shared [RepeatableSpeech], and
/// finders for the panel controls (E46/E47/E48), the spoken-output panel (E50)
/// and the readout speak control.
///
/// Where a control's *behaviour* lands in a later phase, the `when…` still
/// drives the real shipped control (the setter is already wired — SETTINGS-1),
/// so an AC test written now fails cleanly at the red baseline on its Then (the
/// render the behaviour phase adds), not on a missing widget.
class DisplayHarness {
  /// Creates the driver over the booted app; [speech]/[haptics]/[controller]
  /// are the instances [givenDisplay] injected so the Thens can read them.
  DisplayHarness(
    this.tester, {
    required this.speech,
    required this.haptics,
    required this.controller,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording inner speech sink injected into the app (every utterance the
  /// one app-wide [RepeatableSpeech] delegates to lands here — AC-8/AC-9).
  final FakeSpeech speech;

  /// The recording haptic sink injected into the app.
  final FakeHaptics haptics;

  /// The app-wide display controller injected into the app, so a Then can read
  /// the live settings directly (it is the same controller the
  /// [DisplayReadEndpoint] exposes and the shipped panel drives).
  final DisplayController controller;

  /// The live display settings behind every colour surface, read through the
  /// acceptance [DisplayReadEndpoint] the app wraps its tree in.
  DisplaySettings get settings => tester
      .widget<DisplayReadEndpoint>(find.byKey(DisplayReadEndpoint.endpointKey))
      .settings;

  /// The one app-wide [RepeatableSpeech] every speak path flows through (AC-9),
  /// read from the [SpeechScope] above the spoken-output panel. Its `inner` is
  /// [speech], so a Then can assert both the shared wrapper and the recorded
  /// utterances.
  RepeatableSpeech get appSpeech =>
      SpeechScope.of(tester.element(find.byKey(SpokenOutputPanel.panelKey)));

  /// The spoken-output panel surface (E50) — always present (SPEECH-1), so AC-10
  /// can assert it survives a long pump.
  Finder get spokenOutputPanel => find.byKey(SpokenOutputPanel.panelKey);

  /// The repeat-last-spoken control (E50), present only once something has been
  /// spoken.
  Finder get repeatControl => find.byKey(SpokenOutputPanel.repeatKey);

  /// The last-spoken text shown in the panel (E50), present only once something
  /// has been spoken.
  Finder get lastSpokenText => find.byKey(SpokenOutputPanel.lastSpokenKey);

  /// The open-display-settings entry (E2) the shared chrome shows on every
  /// screen (AC-1).
  Finder get settingsEntry => find.byKey(DisplaySettingsButton.openKey);

  /// The settings panel surface (shown only while open).
  Finder get settingsPanel => find.byKey(DisplaySettingsScreen.panelKey);

  /// The CVD simulation selector region (E47).
  Finder get simulationSelector =>
      find.byKey(DisplaySettingsScreen.simulationKey);

  /// The value-only grayscale toggle (E46).
  Finder get grayscaleToggle => find.byKey(DisplaySettingsScreen.grayscaleKey);

  /// The simulation-severity slider (E48).
  Finder get severitySlider => find.byKey(DisplaySettingsScreen.severityKey);

  /// The theme control shown in the panel (D-11, presentation only).
  Finder get themeControl => find.byKey(DisplaySettingsScreen.themeKey);

  /// Opens the display and simulation settings panel from the current screen
  /// (the E2 entry the shared chrome shows on every screen — AC-1).
  Future<void> whenOpenSettings() async {
    await tester.tap(find.byKey(DisplaySettingsButton.openKey));
    await tester.pumpAndSettle();
  }

  /// Closes the settings panel, returning to the screen underneath.
  Future<void> whenCloseSettings() async {
    await tester.tap(find.byKey(DisplaySettingsScreen.closeKey));
    await tester.pumpAndSettle();
  }

  /// Chooses the simulation [type] in the open panel (null ⇔ the off/trichromat
  /// option — E47). The panel must be open.
  ///
  /// Drives the real shipped selector, whose setter is wired (SETTINGS-1); the
  /// *render* consequence lands in DISPLAY-3/4, so an AC test's Then (the
  /// projected swatch) is what fails at the red baseline, not this tap.
  Future<void> whenSelectSimulation(CvdType? type) async {
    await tester.tap(find.byKey(DisplaySettingsScreen.simulationOptionKey(type)));
    await tester.pumpAndSettle();
  }

  /// Sets the simulation severity to [percent] (0..100) by dragging the E48
  /// slider to that fraction of its track. The panel must be open.
  ///
  /// The drag lands the slider within a pixel of the target, so a Then should
  /// assert the resulting `simulationSeverity` within a small tolerance rather
  /// than exact equality. ITEST-2 may refine the interaction if the shipped
  /// slider needs it.
  Future<void> whenSetSeverity(double percent) async {
    final box = tester.renderObject<RenderBox>(severitySlider);
    final topLeft = tester.getTopLeft(severitySlider);
    // Sliders inset their track by the thumb radius; drag across the usable
    // width so 0 and 100 are reachable.
    const padding = 24.0;
    final usable = box.size.width - 2 * padding;
    final dx = topLeft.dx + padding + usable * (percent / 100).clamp(0.0, 1.0);
    final dy = topLeft.dy + box.size.height / 2;
    await tester.tapAt(Offset(dx, dy));
    await tester.pumpAndSettle();
  }

  /// Turns the value-only grayscale view [on] (E46). The panel must be open.
  ///
  /// Taps the toggle only when it is not already in the requested state, so a
  /// scenario reaches the state it names regardless of where it started.
  Future<void> whenSetGrayscale({required bool on}) async {
    if (settings.grayscale == on) return;
    await tester.tap(grayscaleToggle);
    await tester.pumpAndSettle();
  }

  /// Speaks the current readout through the one app-wide speech (the readout's
  /// "Speak this readout" control — AC-8/AC-9). The Readout must be the current
  /// screen (the default [givenDisplay] entry); close the settings panel first.
  Future<void> whenSpeakReading() async {
    await tester.tap(find.byKey(ActionsBar.speakKey));
    await tester.pumpAndSettle();
  }

  /// Asks the spoken-output panel to repeat the last spoken output (E50 — AC-8).
  ///
  /// Inert until something has been spoken (the control is absent), so
  /// `warnIfMissed` is off and a Then checks what — if anything — was replayed.
  Future<void> whenRepeatLastSpoken() async {
    await tester.tap(repeatControl, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Fills comparison [slot] with [sample] through the saved-sample picker
  /// (E3/E5 open the E49 dialog; the painter chooses a sample) — the public flow
  /// that builds a comparison on the [givenComparison] screen (AC-9). [sample]
  /// must be one of the booted `sampleSource`'s saved samples.
  Future<void> whenChooseSample(ComparisonSlot slot, Sample sample) async {
    await tester.tap(find.text(
        slot == ComparisonSlot.a ? 'Choose sample A' : 'Choose sample B'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SimpleDialogOption, sample.name!));
    await tester.pumpAndSettle();
  }

  /// Speaks the whole comparison through the one app-wide speech (E6 — AC-9).
  ///
  /// The "Speak whole comparison" control is enabled only when both slots are
  /// filled, so a scenario fills them with [whenChooseSample] first.
  Future<void> whenSpeakComparison() async {
    await tester.tap(find.text('Speak whole comparison'));
    await tester.pumpAndSettle();
  }

  /// Opens the full Readout for the sample in comparison slot A (E7), so the
  /// carried reading can then be spoken through the same shared speech (AC-9).
  Future<void> whenOpenReadoutForA() async {
    await tester.tap(find.text('Open readout for A'));
    await tester.pumpAndSettle();
  }
}

/// Opens the fully assembled app on the Readout for [sample], ready for a bs-08
/// display/speech scenario.
///
/// Builds the real app via the single production `buildApp` entry (D-7) with the
/// recording [FakeSpeech]/[FakeHaptics] sinks, the real `ColorScienceImpl`, the
/// painter's [cvdProfile] and an injected [DisplayController] seeded with
/// [initialSettings] (so a scenario can start with a simulation already chosen,
/// and the Thens can read the live controller). No display entry marker is set,
/// so the app opens on bs-01's Readout for [sample] — the screen the simulation,
/// grayscale and spoken-output views all act on. Returns a [DisplayHarness] over
/// the booted app.
Future<DisplayHarness> givenDisplay(
  WidgetTester tester, {
  Sample sample = displaySample,
  CvdProfile cvdProfile = cvdProfileFixture,
  DisplaySettings initialSettings = const DisplaySettings(),
}) async {
  // Open a fresh app each time, so a repeated `givenDisplay` in one test does
  // not reuse the previous screen's State (mirrors the other bs harnesses).
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final controller = DisplayController(
    defaultSimulationType: cvdProfile.type,
    initialSettings: initialSettings,
  );
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    cvdProfile: cvdProfile,
    initialSample: sample,
    displayController: controller,
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return DisplayHarness(
    tester,
    speech: speech,
    haptics: haptics,
    controller: controller,
  );
}

/// Opens the assembled app on the **Comparison** screen (AC-9) with
/// [savedSamples] available to the picker, through the one production
/// `buildApp` entry (the `comparisonEntry` + a seeded `sampleSource`, exactly
/// as bs-03 enters comparison).
///
/// A scenario fills both slots through the picker ([DisplayHarness.whenChooseSample]),
/// speaks the whole comparison ([DisplayHarness.whenSpeakComparison]), then opens
/// a slot's Readout ([DisplayHarness.whenOpenReadoutForA]) and speaks the reading
/// ([DisplayHarness.whenSpeakReading]) — both paths flowing through the one
/// injected [FakeSpeech], which is the single shared service AC-9 verifies.
/// Returns a [DisplayHarness] over the booted app (the same speech/panel seams
/// as [givenDisplay], since the chrome is app-wide).
Future<DisplayHarness> givenComparison(
  WidgetTester tester, {
  List<Sample> savedSamples = const [displaySample, compareSampleB],
  CvdProfile cvdProfile = cvdProfileFixture,
}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final speech = FakeSpeech();
  final haptics = FakeHaptics();
  final controller = DisplayController(defaultSimulationType: cvdProfile.type);
  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    cvdProfile: cvdProfile,
    sampleSource: InMemorySampleSource(samples: savedSamples),
    comparisonEntry: const ComparisonEntry(),
    displayController: controller,
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return DisplayHarness(
    tester,
    speech: speech,
    haptics: haptics,
    controller: controller,
  );
}
