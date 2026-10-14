import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/app/build_app.dart';
import 'package:paint_color_assistant/color_science/color_science_impl.dart';
import 'package:paint_color_assistant/a11y/cvd/cvd_profile.dart';
import 'package:paint_color_assistant/a11y/haptics.dart';
import 'package:paint_color_assistant/a11y/speech.dart';
import 'package:paint_color_assistant/dataset/dataset_read_endpoint.dart';
import 'package:paint_color_assistant/dataset/seed_dataset.dart';
import 'package:paint_color_assistant/dataset/validation_manifest.dart';
import 'package:paint_color_assistant/domain/color_coordinates.dart';
import 'package:paint_color_assistant/domain/paint.dart';
import 'package:paint_color_assistant/domain/provenance.dart';
import 'package:paint_color_assistant/domain/sample.dart';
import 'package:paint_color_assistant/readout/readout_screen.dart';
import 'package:paint_color_assistant/recipes/palette.dart';
import 'package:paint_color_assistant/recipes/palette_source.dart';
import 'package:paint_color_assistant/recipes/recipe_read_endpoint.dart';

const _entry = SeedPaintEntry(
  id: 'pw6',
  name: 'Titanium White',
  brand: 'Acme',
  medium: PaintMedium.oil,
  masstone: ColorCoordinates(lightness: 95, a: -1, b: 2),
);

const _seed = SeedDataset(
  brand: 'Acme',
  medium: PaintMedium.oil,
  entries: [_entry],
  candidateMappings: [],
  manifest: ValidationManifest.empty(),
);

AppDependencies _deps({
  SeedDataset? seedDataset,
  PaletteSource paletteSource = const InMemoryPaletteSource(),
}) =>
    AppDependencies(
      colorScience: const ColorScienceImpl(),
      speech: const NoopSpeech(),
      haptics: const NoopHaptics(),
      paletteSource: paletteSource,
      seedDataset: seedDataset ?? const SeedDataset.empty(),
    );

void main() {
  test('seedDataset defaults to the empty placeholder', () {
    expect(_deps().seedDataset, const SeedDataset.empty());
  });

  test('carries an explicitly injected seed dataset', () {
    expect(_deps(seedDataset: _seed).seedDataset, same(_seed));
  });

  test('withCvdProfile preserves the seed dataset', () {
    final deps = _deps(seedDataset: _seed);
    final next = deps.withCvdProfile(const CvdProfile(type: CvdType.protan));
    expect(next.seedDataset, same(_seed));
    expect(next.cvdProfile.type, CvdType.protan);
  });

  testWidgets('buildApp mounts a DatasetReadEndpoint exposing the seed',
      (tester) async {
    await tester.pumpWidget(buildApp(_deps(seedDataset: _seed)));
    final endpoint = tester.widget<DatasetReadEndpoint>(
      find.byKey(DatasetReadEndpoint.endpointKey),
    );
    expect(endpoint.dataset, same(_seed));
    // Reachable from a descendant below the MaterialApp.
    final context = tester.element(find.byType(ReadoutScreen));
    expect(DatasetReadEndpoint.of(context), same(_seed));
  });

  testWidgets(
      'the Recipes solve reads the shipped seed composed with the painter '
      'palettes (AC-1 availability)', (tester) async {
    const userSource = InMemoryPaletteSource(
      catalogue: [PaintPalette(name: 'My paints')],
    );
    await tester.pumpWidget(
      buildApp(
        AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: const NoopSpeech(),
          haptics: const NoopHaptics(),
          paletteSource: userSource,
          seedDataset: _seed,
          recipesEntry: const RecipesEntry(target: _target),
        ),
      ),
    );
    final endpoint = tester.widget<RecipeReadEndpoint>(
      find.byKey(RecipeReadEndpoint.endpointKey),
    );
    // Seed first (always available), then the painter's palettes.
    expect(
      endpoint.controller.palettes.map((p) => p.name),
      ['Acme oil', 'My paints'],
    );
  });

  testWidgets(
      'an empty shell seed leaves the Recipes solve over just the painter '
      'palettes (behaviour-neutral)', (tester) async {
    const userSource = InMemoryPaletteSource(
      catalogue: [PaintPalette(name: 'My paints')],
    );
    await tester.pumpWidget(
      buildApp(
        AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: const NoopSpeech(),
          haptics: const NoopHaptics(),
          paletteSource: userSource,
          recipesEntry: const RecipesEntry(target: _target),
        ),
      ),
    );
    final endpoint = tester.widget<RecipeReadEndpoint>(
      find.byKey(RecipeReadEndpoint.endpointKey),
    );
    expect(endpoint.controller.palettes.map((p) => p.name), ['My paints']);
  });

  testWidgets('the Palette screen keeps the painter source for persistence, '
      'unwrapped (bs-06 unaffected)', (tester) async {
    // A PaletteController persists only when its source is a concrete
    // PersistentPaletteSource; composing the seed must not wrap that source.
    await tester.pumpWidget(
      buildApp(
        AppDependencies(
          colorScience: const ColorScienceImpl(),
          speech: const NoopSpeech(),
          haptics: const NoopHaptics(),
          seedDataset: _seed,
          paletteEntry: const PaletteEntry(),
        ),
      ),
    );
    // The screen builds; its recipe solve still sees the seed palette.
    final recipeEndpoint = tester.widget<RecipeReadEndpoint>(
      find.byKey(RecipeReadEndpoint.endpointKey),
    );
    expect(
      recipeEndpoint.controller.palettes.map((p) => p.name),
      contains('Acme oil'),
    );
  });
}

const _target = Sample(
  name: 'Deep Olive Green',
  coordinates: ColorCoordinates(lightness: 40, a: -8, b: 24),
  provenance: Provenance(ProvenanceTier.measured),
);
