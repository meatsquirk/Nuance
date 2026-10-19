// Fixtures for the bs-18 visual-application acceptance suite (ITEST-1).
//
// The six fixtures the AC catalogue names verbatim (master plan fixture table):
// enough real domain data, built from the shipped domain types, for each screen
// to render its regions so the per-AC swap tests (ITEST-2/3/4) can assert the
// design-system wrapper is **present** and the superseded ad-hoc widget
// **absent** (D-3). bs-18 is presentation-only (D-2): these fixtures fix only
// the *inputs* each screen renders from — no behaviour, number or semantic.
//
// Samples and paint masstones are stored in canonical CIELAB (the domain's
// single source of truth), mirroring the sibling harnesses' fixtures. The
// composite fixtures are small immutable holders that also expose the in-memory
// source the matching `AppDependencies` entry is wired with, so an AC-test phase
// injects one line (`paletteSource: aPalette.paletteSource`) rather than
// re-building the source.

import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/compare/sample_source.dart';
import 'package:paint_color_assistant/display/display_settings.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/onboarding/onboarding_steps.dart';
import 'package:paint_color_assistant/projects/project.dart';
import 'package:paint_color_assistant/projects/project_source.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';

// ---------------------------------------------------------------------------
// aReading — one captured sample, for Readout / Capture
// ---------------------------------------------------------------------------

/// One captured sample with L*a*b* + colour name + measured provenance — the
/// subject the Readout (AC-5) and the Capture scene (AC-3/AC-4) render. The warm
/// terracotta the shipped app demos (`demoSample`), kept here so the suite's
/// reading is independent of production's default.
const Sample aReading = Sample(
  name: 'Warm Terracotta',
  coordinates: ColorCoordinates(lightness: 58, a: 36, b: 34),
  provenance: Provenance(ProvenanceTier.measured),
);

// ---------------------------------------------------------------------------
// aComparison — A and B samples + the picker catalogue, for Compare
// ---------------------------------------------------------------------------

/// The A/B pair (plus the saved-sample catalogue the picker lists) a Compare
/// scenario renders (AC-6). The relational difference and the plain-language
/// statement are derived by the real comparison engine from these two samples;
/// the fixture fixes only the pair the screen lays out as A and B.
class ComparisonFixture {
  const ComparisonFixture({required this.a, required this.b});

  /// Slot A — warm terracotta (CIELCh L 58 / C 34 / h 42°).
  final Sample a;

  /// Slot B — a lighter raw sienna (CIELCh L 70 / C 25 / h 60°), clearly
  /// different from [a] so the diff rows have something to state.
  final Sample b;

  /// The two samples as the picker's catalogue, so each slot can be chosen by
  /// name through the public flow.
  List<Sample> get catalogue => [a, b];

  /// The in-memory catalogue the Compare entry's `sampleSource` is wired with.
  SampleSource get sampleSource => InMemorySampleSource(samples: catalogue);
}

/// The Compare fixture: two distinct named earth tones over a two-entry picker.
const ComparisonFixture aComparison = ComparisonFixture(
  a: Sample(
    name: 'Warm Terracotta',
    coordinates: ColorCoordinates(lightness: 58, a: 25.27, b: 22.75),
    provenance: Provenance(ProvenanceTier.measured),
  ),
  b: Sample(
    name: 'Raw Sienna Light',
    coordinates: ColorCoordinates(lightness: 70, a: 12.50, b: 21.65),
    provenance: Provenance(ProvenanceTier.measured),
  ),
);

// ---------------------------------------------------------------------------
// recipesForTarget — a mixing target + owned palette, for Recipes
// ---------------------------------------------------------------------------

/// A mixing target and the owned palette a Recipes scenario solves over (AC-7).
///
/// [target] is reachable from [palette], so the real engine returns ranked
/// recipes for the recipe-row card test; [outOfGamutTarget] is not, so the same
/// palette drives the out-of-gamut note case — the two targets over one palette
/// give the AC the "≥2 recipes incl. one out-of-gamut" the fixture table names.
class RecipesFixture {
  const RecipesFixture({
    required this.target,
    required this.outOfGamutTarget,
    required this.palette,
  });

  /// A warm near-neutral deep umber reachable from [palette] → ranked recipes.
  final Sample target;

  /// A high-chroma green-cyan no earthy palette can reach → the gamut note.
  final Sample outOfGamutTarget;

  /// The owned paints the solver is constrained to.
  final PaintPalette palette;

  /// The in-memory catalogue the Recipes entry's `paletteSource` is wired with.
  PaletteSource get paletteSource => InMemoryPaletteSource(catalogue: [palette]);
}

/// The Recipes fixture: a reachable deep-umber target and an out-of-gamut
/// turquoise control over an earthy four-paint palette.
const RecipesFixture recipesForTarget = RecipesFixture(
  target: Sample(
    name: 'Deep Umber',
    coordinates: ColorCoordinates(lightness: 33, a: 0, b: 12),
    provenance: Provenance(ProvenanceTier.measured),
  ),
  outOfGamutTarget: Sample(
    name: 'Vivid Turquoise',
    coordinates: ColorCoordinates(lightness: 72, a: -38, b: -14),
    provenance: Provenance(ProvenanceTier.measured),
  ),
  palette: PaintPalette(
    name: 'Studio earths',
    paints: [
      Paint(
        id: 'pw6',
        name: 'Titanium White',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
        pigmentIndex: 'PW6',
      ),
      Paint(
        id: 'py43',
        name: 'Yellow Ochre',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 62, a: 12, b: 44),
        pigmentIndex: 'PY43',
      ),
      Paint(
        id: 'pbk9',
        name: 'Ivory Black',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 20, a: 0, b: 1),
        pigmentIndex: 'PBk9',
      ),
      Paint(
        id: 'pb29',
        name: 'Ultramarine Blue',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 32, a: 10, b: -45),
        pigmentIndex: 'PB29',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// aPalette — >=3 paints of mixed provenance, for Palette
// ---------------------------------------------------------------------------

/// The painter's palette a Palette scenario renders (AC-8): at least three
/// paints whose provenance tiers differ, so every row must carry its own
/// provenance badge and the sweep sees more than one badge kind.
class PaletteFixture {
  const PaletteFixture({required this.palette});

  /// The named palette the screen lists.
  final PaintPalette palette;

  /// The paints in listing order.
  List<Paint> get paints => palette.paints;

  /// The in-memory catalogue the Palette entry's `paletteSource` is wired with.
  PaletteSource get paletteSource => InMemoryPaletteSource(catalogue: [palette]);
}

/// The Palette fixture: three paints spanning measured / estimated (dataset-
/// seeded) / confirmed (painter-confirmed) provenance.
const PaletteFixture aPalette = PaletteFixture(
  palette: PaintPalette(
    name: 'My paints',
    paints: [
      Paint(
        id: 'pw6',
        name: 'Titanium White',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 96, a: -0.5, b: 2.5),
        pigmentIndex: 'PW6',
        provenance: ProvenanceTier.measured,
      ),
      Paint(
        id: 'py43',
        name: 'Yellow Ochre',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 62, a: 12, b: 44),
        pigmentIndex: 'PY43',
        provenance: ProvenanceTier.estimated,
      ),
      Paint(
        id: 'pbk9',
        name: 'Ivory Black',
        medium: PaintMedium.acrylic,
        masstone: ColorCoordinates(lightness: 20, a: 0, b: 1),
        pigmentIndex: 'PBk9',
        provenance: ProvenanceTier.confirmed,
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// aProject — one saved project with a name + notes, for Projects
// ---------------------------------------------------------------------------

/// One saved project the Projects view lists (AC-9): a named project with a
/// working note and a free-text size, enough for the entry card to render its
/// title and metadata.
class ProjectFixture {
  const ProjectFixture({required this.project});

  /// The saved project.
  final Project project;

  /// The in-memory catalogue the Palette entry's `projectSource` is wired with.
  ProjectSource get projectSource => InMemoryProjectSource(catalogue: [project]);
}

/// The Projects fixture: one named project with a note and a size.
const ProjectFixture aProject = ProjectFixture(
  project: Project(
    id: 'proj-harbor',
    name: 'Harbor at Dusk',
    size: '24×30 in',
    note: 'Mixing the warm greys of the sky at golden hour.',
  ),
);

// ---------------------------------------------------------------------------
// anOnboardingStep — one onboarding step mid-flow + a Display settings snapshot
// ---------------------------------------------------------------------------

/// One onboarding step mid-flow plus a Display settings snapshot, for the CFG
/// screens (AC-10). [stepIndex] is a genuine interior step (not first or last)
/// of [defaultOnboardingSteps], so the step's next/back controls both exist; the
/// [displaySettings] snapshot has a simulation active so the Display panel's
/// view controls have a non-default state to render.
class OnboardingFixture {
  const OnboardingFixture({
    required this.step,
    required this.stepIndex,
    required this.displaySettings,
  });

  /// The step the onboarding host is on (mid-flow).
  final OnboardingStep step;

  /// Its index into [defaultOnboardingSteps] — an interior step.
  final int stepIndex;

  /// The Display settings the config screen renders through.
  final DisplaySettings displaySettings;
}

/// The CFG fixture: the third of the four onboarding steps ("Vision tests"),
/// over a moderate-deutan simulation Display snapshot.
const OnboardingFixture anOnboardingStep = OnboardingFixture(
  step: OnboardingStep('Vision tests'),
  stepIndex: 2,
  displaySettings: DisplaySettings(
    simulationType: CvdType.deutan,
    simulationSeverity: 0.6,
  ),
);
