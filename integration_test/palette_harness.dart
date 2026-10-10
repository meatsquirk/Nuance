// Acceptance-suite harness for bs-06 Palette and projects (ITEST-1).
//
// The Given/When/Then vocabulary, fixtures and independent confusion reference
// the AC tests (ITEST-2, ITEST-3) are written against. The suite drives the
// *real* assembled app through the single production `buildApp` entry with a
// `PaletteEntry` (SCREEN-1): a `PaletteController` over the injected
// `PaletteSource` and a `ProjectController` over the injected `ProjectSource`,
// both wrapped in the read endpoints the suite observes. Everything is real
// except the platform/infrastructure sinks — `FakeSpeech`/`FakeHaptics`
// (bs-01), the `FakeFileSink` source-photo store (D-10) and the in-memory
// `InMemoryPersistentStore` behind the persistent sources (DATA-2). No colour,
// ΔE00 or confusion math is faked: the shipped `ColorScienceImpl` and
// `DichromatConfusionCheck` run, and AC-9's confusion fixtures are graded
// against this harness's *own* independent deutan projection (reused from the
// bs-03 comparison harness) so the detector is never graded against itself.
//
// The pending gate (all 11 ACs → owning phase) lives in `bs06/pending.dart`
// (seeded in DATA-1); this harness re-exports it so an AC test imports only this
// file.
//
// Fixture identifiers mirror the plan's `reviewedDataset` / `twoPalettes` /
// `harborProject` / `deutanModerate` names and the paint/sample `*` constants,
// which the AC catalogue references verbatim, so this file opts out of
// lowerCamelCase for the SCREAMING_CASE sample/paint constants.
// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/palette/paint_dataset.dart';
import 'package:paint_color_assistant/palette/paint_list_region.dart';
import 'package:paint_color_assistant/palette/palette_controller.dart';
import 'package:paint_color_assistant/palette/palette_read_endpoint.dart';
import 'package:paint_color_assistant/palette/palette_screen.dart';
import 'package:paint_color_assistant/palette/palette_selector_region.dart';
import 'package:paint_color_assistant/palette/projects_region.dart';
import 'package:paint_color_assistant/palette/self_assessment_entry_screen.dart';
import 'package:paint_color_assistant/palette/vision_profile_card.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_controller.dart';
import 'package:paint_color_assistant/projects/project_read_endpoint.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/engine/mixing_engine.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/store/persistent_store.dart';

import 'fakes/fake_file_sink.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_speech.dart';

// Re-export the pending gate and the fakes so an AC test only needs to import
// this harness.
export 'bs06/pending.dart';
export 'fakes/fake_file_sink.dart';
export 'fakes/fake_haptics.dart';
export 'fakes/fake_speech.dart';

// Reuse bs-03's independent deutan projection so AC-9 is never graded against
// the shipped `DichromatConfusionCheck` (the one the product uses). These are
// the bs-03 comparison harness's test-only reference ΔE00s; re-exported so an
// AC test imports only this harness.
export 'comparison_harness.dart'
    show referenceDeltaE00, referenceDeutanProjectedDeltaE00;
import 'comparison_harness.dart'
    show referenceDeltaE00, referenceDeutanProjectedDeltaE00;

// ---------------------------------------------------------------------------
// Vision-profile fixtures
//
// The injected `CvdProfile` is app-wide, but AC-9 and AC-11 need different
// profiles and each scenario builds a *fresh* app, so the suite injects the one
// each scenario names:
//
// * AC-11 renders the estimate "deutan-type, moderate", so [deutanModerate]
//   carries a mid severity (0.6). This is also the suite's default profile.
// * AC-9 needs the sample pair to actually collapse under the shipped detector.
//   The shipped `DichromatConfusionCheck` flags a pair only when its projected
//   ΔE00 is below 3.0 (D-5), which a *moderate* deficiency never reaches — the
//   detector by design fires only near full dichromacy. AC-9's spec names only
//   "the painter's confusion line" (no severity), so AC-9 injects
//   [deutanDichromat] (a full deuteranope), under which [SAMPLE_MID_RAW_UMBER] /
//   [SAMPLE_ULTRAMARINE_SHADOW] genuinely collapse (verified in `palette_test`).
// ---------------------------------------------------------------------------

/// The AC-11 estimate "deutan-type, moderate" — a mid-severity deuteranomaly.
/// Also the suite's default injected profile.
const CvdProfile deutanModerate = CvdProfile(type: CvdType.deutan, severity: 0.6);

/// A full deuteranope (severity 1.0) — the profile AC-9's confusion pair
/// collapses under, since the shipped detector fires only near full dichromacy.
const CvdProfile deutanDichromat = CvdProfile(type: CvdType.deutan);

// ---------------------------------------------------------------------------
// Reviewed dataset fixture (AC-2, AC-4)
// ---------------------------------------------------------------------------

/// The reviewed paints the painter may add from — the shipped [kReviewedPaints]
/// the real `PaletteController` offers (no free-hand, plan D-3).
///
/// Includes "Titanium White" (Winsor & Newton, Artists' Oil, PW6, Measured)
/// for AC-2 and "Ultramarine Blue" for AC-4; `palette_test` guards their
/// presence and identity so the AC tests can rely on them.
const List<Paint> reviewedDataset = kReviewedPaints;

// ---------------------------------------------------------------------------
// Palette fixtures (AC-5) — two disjoint named palettes
// ---------------------------------------------------------------------------

/// "My paints" — the painter's default palette (the canonical name the
/// `PaletteController` surfaces as [PaletteController.myPaints]). Earthy
/// oils, disjoint from [PALETTE_TRAVEL_SET] by paint id so a solve reveals which
/// palette was active (AC-5).
const PaintPalette PALETTE_MY_PAINTS = PaintPalette(
  name: 'My paints',
  paints: [
    Paint(
      id: 'pw6',
      name: 'Titanium White',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PW6',
      masstone: ColorCoordinates(lightness: 96, a: 0, b: 2),
    ),
    Paint(
      id: 'py42',
      name: 'Yellow Ochre',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PY42',
      masstone: ColorCoordinates(lightness: 60, a: 12, b: 46),
    ),
    Paint(
      id: 'pbr7',
      name: 'Raw Umber',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PBr7',
      masstone: ColorCoordinates(lightness: 32, a: 8, b: 18),
    ),
    Paint(
      id: 'pbk9',
      name: 'Ivory Black',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PBk9',
      masstone: ColorCoordinates(lightness: 12, a: 0, b: 1),
    ),
  ],
);

/// "Travel set" — a second named palette with paints **disjoint** from
/// [PALETTE_MY_PAINTS] (no shared id), so selecting it re-points a solve to a
/// visibly different paint set (AC-5).
const PaintPalette PALETTE_TRAVEL_SET = PaintPalette(
  name: 'Travel set',
  paints: [
    Paint(
      id: 'pb29',
      name: 'Ultramarine Blue',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PB29',
      masstone: ColorCoordinates(lightness: 32, a: 18, b: -52),
    ),
    Paint(
      id: 'py35',
      name: 'Cadmium Yellow',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PY35',
      masstone: ColorCoordinates(lightness: 82, a: 8, b: 78),
    ),
    Paint(
      id: 'pr108',
      name: 'Cadmium Red',
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      pigmentIndex: 'PR108',
      masstone: ColorCoordinates(lightness: 48, a: 60, b: 40),
    ),
  ],
);

/// The AC-5 fixture: "My paints" and "Travel set", in listing order (so the
/// initially-selected palette is "My paints", the catalogue's first).
const List<PaintPalette> twoPalettes = [PALETTE_MY_PAINTS, PALETTE_TRAVEL_SET];

// ---------------------------------------------------------------------------
// Project fixtures (AC-6..AC-10)
// ---------------------------------------------------------------------------

/// "Mid Raw Umber" — one half of the AC-9 deutan confusion pair (D-4).
///
/// A warm dark reddish-brown (CIELAB (42, 16, 18)). It and
/// [SAMPLE_ULTRAMARINE_SHADOW] differ mainly on the red↔green (a\*) axis a
/// deuteranope collapses, so for [deutanDichromat] the pair looks identical
/// (projected ΔE00 ≈ 0.8) while others see them 22 ΔE00 apart.
const Sample SAMPLE_MID_RAW_UMBER = Sample(
  name: 'Mid Raw Umber',
  coordinates: ColorCoordinates(lightness: 42, a: 16, b: 18),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Ultramarine Shadow" — the other half of the AC-9 deutan confusion pair.
///
/// A dark cool earth (CIELAB (44, −6, 20)): the opposite-signed a\* against
/// [SAMPLE_MID_RAW_UMBER] places the pair on the deutan confusion line.
const Sample SAMPLE_ULTRAMARINE_SHADOW = Sample(
  name: 'Ultramarine Shadow',
  coordinates: ColorCoordinates(lightness: 44, a: -6, b: 20),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Harbor Sky" — a clearly-distinct blue, not confusable with any other harbor
/// sample (one of AC-9's non-flag controls).
const Sample SAMPLE_HARBOR_SKY = Sample(
  name: 'Harbor Sky',
  coordinates: ColorCoordinates(lightness: 70, a: -4, b: -22),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Hull Red" — a saturated warm red; the clearest AC-9 control against
/// [SAMPLE_MID_RAW_UMBER] (a deuteranope still tells them apart).
const Sample SAMPLE_HULL_RED = Sample(
  name: 'Hull Red',
  coordinates: ColorCoordinates(lightness: 40, a: 42, b: 28),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Warm Sand" — a light muted yellow harbor sample (no confusion).
const Sample SAMPLE_WARM_SAND = Sample(
  name: 'Warm Sand',
  coordinates: ColorCoordinates(lightness: 78, a: 4, b: 24),
  provenance: Provenance(ProvenanceTier.measured),
);

/// "Deep Shadow" — a very dark near-neutral harbor sample (no confusion).
const Sample SAMPLE_DEEP_SHADOW = Sample(
  name: 'Deep Shadow',
  coordinates: ColorCoordinates(lightness: 25, a: 2, b: 4),
  provenance: Provenance(ProvenanceTier.measured),
);

/// The six samples saved to [harborProject] (AC-6's "6 samples").
///
/// Exactly one pair — [SAMPLE_MID_RAW_UMBER] / [SAMPLE_ULTRAMARINE_SHADOW] — is
/// confusable for [deutanDichromat] (verified in `palette_test`); every other
/// pair is a non-flag control for AC-9.
const List<Sample> harborSamples = [
  SAMPLE_MID_RAW_UMBER,
  SAMPLE_ULTRAMARINE_SHADOW,
  SAMPLE_HARBOR_SKY,
  SAMPLE_HULL_RED,
  SAMPLE_WARM_SAND,
  SAMPLE_DEEP_SHADOW,
];

Paint _oil(String id, String name, ColorCoordinates masstone) => Paint(
      id: id,
      name: name,
      brand: 'Winsor & Newton',
      line: "Artists' Oil",
      medium: PaintMedium.oil,
      masstone: masstone,
    );

/// The three recipes saved to [harborProject] (AC-6's "3 recipes"; AC-10's PDF
/// references each one).
///
/// Plausible two-paint oil mixes — the harness does not re-run the solver for
/// fixtures, so these carry pinned predicted colours / ΔE00 / verdicts rather
/// than engine output.
final List<Recipe> harborRecipes = [
  Recipe(
    medium: PaintMedium.oil,
    components: [
      RecipeComponent(
        paint: _oil('py42', 'Yellow Ochre',
            const ColorCoordinates(lightness: 60, a: 12, b: 46)),
        partsFraction: 0.6,
      ),
      RecipeComponent(
        paint: _oil('pbk9', 'Ivory Black',
            const ColorCoordinates(lightness: 12, a: 0, b: 1)),
        partsFraction: 0.4,
      ),
    ],
    predictedColor: const ColorCoordinates(lightness: 42, a: 16, b: 18),
    deltaE00: 1.8,
    verdict: 'very close',
  ),
  Recipe(
    medium: PaintMedium.oil,
    components: [
      RecipeComponent(
        paint: _oil('pw6', 'Titanium White',
            const ColorCoordinates(lightness: 96, a: 0, b: 2)),
        partsFraction: 0.7,
      ),
      RecipeComponent(
        paint: _oil('pbr7', 'Raw Umber',
            const ColorCoordinates(lightness: 32, a: 8, b: 18)),
        partsFraction: 0.3,
      ),
    ],
    predictedColor: const ColorCoordinates(lightness: 78, a: 4, b: 24),
    deltaE00: 2.4,
    verdict: 'close',
  ),
  Recipe(
    medium: PaintMedium.oil,
    components: [
      RecipeComponent(
        paint: _oil('pb29', 'Ultramarine Blue',
            const ColorCoordinates(lightness: 32, a: 18, b: -52)),
        partsFraction: 0.5,
      ),
      RecipeComponent(
        paint: _oil('pbk9', 'Ivory Black',
            const ColorCoordinates(lightness: 12, a: 0, b: 1)),
        partsFraction: 0.5,
      ),
    ],
    predictedColor: const ColorCoordinates(lightness: 25, a: 2, b: 4),
    deltaE00: 3.1,
    verdict: 'close',
  ),
];

/// The note kept with [harborProject] (AC-7, AC-8).
const String harborNote = 'Keep the hull and wall values 2 steps apart.';

/// The reference [harborProject]'s source photo is stored under in the suite's
/// [FakeFileSink] (AC-7). `givenPalette` seeds the bytes under this reference so
/// the photo round-trips.
const String harborPhotoRef = 'harbor-source-photo';

/// Placeholder bytes for [harborProject]'s source photo. These ACs never assert
/// pixel content (D-10) — only that a photo is present and round-trips.
final Uint8List harborPhotoBytes = Uint8List.fromList(const [1, 2, 3, 4]);

/// "Harbor at Dusk" — the AC-6..AC-10 project fixture.
///
/// Size "24×30 in" (free text, G-4), 6 saved [harborSamples], 3 [harborRecipes],
/// the [harborNote], a source photo ([harborPhotoRef]) and last edited today.
/// The plan builds it via the PROJECT-2 enabler's attach flows; where a test
/// only needs it present it can be seeded directly through `givenPalette`'s
/// `projects`, and the ITEST-3 Givens that require the PROJECT-2 flow assert a
/// precondition naming PROJECT-2.
Project get harborProject => Project(
      id: 'harbor-at-dusk',
      name: 'Harbor at Dusk',
      size: '24×30 in',
      samples: harborSamples,
      recipes: harborRecipes,
      note: harborNote,
      sourcePhotoRef: harborPhotoRef,
      lastEdited: DateTime.now(),
    );

// ---------------------------------------------------------------------------
// Given / When / Then vocabulary
// ---------------------------------------------------------------------------

/// A driver over the assembled app for one palette/projects scenario.
///
/// Exposes the live [PaletteController] / [ProjectController] (through the read
/// endpoints the home screen mounts) for the Thens the rendered UI does not
/// surface directly — the painter's palettes and active palette, the projects
/// list, the opened project, the flagged confusion pairs and the last export —
/// plus the recording [speech] / [haptics] sinks and the [photos] file sink.
///
/// Every `when…` drives a **real** control on the Palette screen. In the
/// SCREEN-1 shell those controls are inert (`onPressed: null`) and the regions
/// render placeholders, so a `when…` names the behaviour phase that wires it and
/// either taps with `warnIfMissed: false` (an inert control absorbs no pointer)
/// or asserts a precondition that fails cleanly at the red baseline (naming the
/// owner) rather than panicking.
class PaletteHarness {
  PaletteHarness(
    this.tester, {
    required this.speech,
    required this.haptics,
    required this.photos,
  });

  /// The widget tester driving the real UI surface.
  final WidgetTester tester;

  /// The recording speech sink injected into the app.
  final FakeSpeech speech;

  /// The recording haptics sink injected into the app.
  final FakeHaptics haptics;

  /// The suite's source-photo file sink (AC-7/AC-10 infrastructure, D-10).
  final FakeFileSink photos;

  /// The live palette controller, read through the [PaletteReadEndpoint] the
  /// home screen wraps its subtree in.
  PaletteController get paletteController => tester
      .widget<PaletteReadEndpoint>(
          find.byKey(PaletteReadEndpoint.endpointKey))
      .controller;

  /// The live project controller, read through the [ProjectReadEndpoint].
  ProjectController get projectController => tester
      .widget<ProjectReadEndpoint>(
          find.byKey(ProjectReadEndpoint.endpointKey))
      .controller;

  /// The painter's palettes, in listing order (AC-5).
  List<PaintPalette> get palettes => paletteController.palettes;

  /// The active palette recipes solve against (AC-5), or null.
  PaintPalette? get selectedPalette => paletteController.selectedPalette;

  /// The paints in the "My paints" palette the list view shows (AC-2/AC-4).
  List<Paint> get myPaints => paletteController.myPaints;

  /// The painter's projects, in listing order (AC-6).
  List<Project> get projects => projectController.projects;

  /// The project currently open in the open-project view (AC-7/AC-8), or null.
  Project? get openedProject => projectController.openedProject;

  /// The confusable sample pairs flagged within the opened project (AC-9).
  List<ConfusionPair> get confusionPairs => projectController.confusionPairs;

  /// The bytes of the most recent exported PDF studio sheet (AC-10), or null.
  Uint8List? get lastExport => projectController.lastExport;

  /// Switches the view selector (E31) to Projects (AC-1).
  ///
  /// Inert until SCREEN-2; the disabled control absorbs no pointer, so
  /// `warnIfMissed` is off.
  Future<void> whenSwitchToProjects() async {
    await tester.tap(
      find.descendant(
        of: find.byKey(PaletteScreen.viewSelectorKey),
        matching: find.widgetWithText(TextButton, 'Projects'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Switches the view selector (E31) back to My paints (AC-1).
  Future<void> whenSwitchToMyPaints() async {
    await tester.tap(
      find.descendant(
        of: find.byKey(PaletteScreen.viewSelectorKey),
        matching: find.widgetWithText(TextButton, 'My paints'),
      ),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Opens the add-paint-from-dataset flow (E32, AC-4). Inert until PALETTE-2.
  Future<void> whenAddPaint() async {
    await tester.tap(
      find.byKey(PaintListRegion.addPaintKey),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Selects the palette named [name] as the active palette (AC-5).
  ///
  /// The selector (E32 region) renders the palettes but has no select action
  /// until PALETTE-4; the precondition names that owner if the option is not
  /// offered, so an AC-5 test written now fails cleanly at the red baseline.
  Future<void> whenSelectPalette(String name) async {
    final option = find.descendant(
      of: find.byKey(PaletteSelectorRegion.regionKey),
      matching: find.text(name),
    );
    expect(
      option,
      findsWidgets,
      reason: 'the palette selector must offer "$name" to select it '
          '(PALETTE-4 wires selection, AC-5)',
    );
    await tester.tap(option.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Opens the project named [name] from the Projects list (E33, AC-7/AC-8).
  ///
  /// Inert until PROJECT-4 wires the open control; `warnIfMissed` is off.
  Future<void> whenOpenProject(String name) async {
    await tester.tap(
      find.byKey(ProjectsRegion.openProjectKey),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Exports the opened project to the device (E34, AC-10). Inert until
  /// PROJECT-6.
  Future<void> whenExportProject() async {
    await tester.tap(
      find.byKey(ProjectsRegion.exportKey),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Chooses "retake the self-assessment" on the vision-profile card (E30,
  /// AC-11). Inert until SCREEN-3; `warnIfMissed` is off.
  Future<void> whenRetakeAssessment() async {
    await tester.tap(
      find.byKey(VisionProfileCard.retakeKey),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
  }

  /// Whether the bs-07 CVD self-assessment entry screen is open (AC-11's "the
  /// self-assessment is opened"). SCREEN-3 wires the navigation.
  bool get selfAssessmentOpen =>
      find.byKey(SelfAssessmentEntryScreen.screenKey).evaluate().isNotEmpty;
}

/// Whether [a] and [b] are a confusion pair for [profile], by the harness's
/// **own** independent deutan projection (not the shipped detector).
///
/// Mirrors the shipped predicate's two tests (D-5) — clearly different to normal
/// vision, identical after the dichromat projection — but computed via bs-03's
/// independent reference ΔE00s, so AC-9 is never graded against the detector it
/// checks. Deutan-only (the only axis bs-06 exercises).
bool referenceConfusable(ColorCoordinates a, ColorCoordinates b) =>
    referenceDeltaE00(a, b) >= 10.0 &&
    referenceDeutanProjectedDeltaE00(a, b) < 3.0;

/// Opens the Palette screen in the fully assembled app (SCREEN-1 entry).
///
/// Builds the real app via the production `buildApp` entry with a [PaletteEntry]
/// wired: a `PaletteController` over the injected palettes and a
/// `ProjectController` over the injected projects, both read through the
/// endpoints the suite observes. The sources are the production **persistent**
/// sources over a shared [InMemoryPersistentStore] (so the behaviour phases'
/// write flows persist and round-trip through the same interface production
/// uses); [palettes], [projects] and [savedSamples] are seeded through those
/// sources' public save flows and loaded before assembly. The source photo sink
/// is the recording [FakeFileSink], pre-seeded with [photos] (reference →
/// bytes). The platform sinks are faked and the colour / confusion math is real.
///
/// Returns a [PaletteHarness] over the booted app.
Future<PaletteHarness> givenPalette(
  WidgetTester tester, {
  List<PaintPalette> palettes = const [],
  List<Project> projects = const [],
  List<Sample> savedSamples = const [],
  Map<String, Uint8List> photos = const {},
  CvdProfile cvdProfile = deutanModerate,
}) async {
  // Open a *fresh* app each time so a repeated `givenPalette` in one test
  // disposes the prior `PaletteHomeScreen` State (whose controllers are built
  // once in didChangeDependencies) rather than reusing its sources.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();

  final store = InMemoryPersistentStore();

  final paletteSource = PersistentPaletteSource(store);
  for (final palette in palettes) {
    await paletteSource.savePalette(palette);
  }
  await paletteSource.load();

  final projectSource = PersistentProjectSource(store);
  for (final project in projects) {
    await projectSource.saveProject(project);
  }
  await projectSource.load();

  final sampleSource = PersistentSampleSource(store);
  for (var i = 0; i < savedSamples.length; i++) {
    final sample = savedSamples[i];
    await sampleSource.saveSample(sample.name ?? 'sample-$i', sample);
  }
  await sampleSource.load();

  final photoSink = FakeFileSink();
  photos.forEach(photoSink.seed);

  final speech = FakeSpeech();
  final haptics = FakeHaptics();

  final deps = AppDependencies(
    colorScience: const ColorScienceImpl(),
    speech: speech,
    haptics: haptics,
    cvdProfile: cvdProfile,
    paletteSource: paletteSource,
    projectSource: projectSource,
    sampleSource: sampleSource,
    store: store,
    sourcePhotoStore: photoSink,
    paletteEntry: const PaletteEntry(),
  );
  await tester.pumpWidget(buildApp(deps));
  await tester.pumpAndSettle();
  return PaletteHarness(tester, speech: speech, haptics: haptics, photos: photoSink);
}
