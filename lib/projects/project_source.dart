import '../compare/sample_source.dart';
import '../domain/color_coordinates.dart';
import '../domain/paint.dart';
import '../domain/provenance.dart';
import '../recipes/engine/mixing_engine.dart';
import '../store/persistent_store.dart';
import 'project.dart';

/// The painter's projects (bs-06 D-8).
///
/// A minimal read-only seam over the saved projects, mirroring bs-03's
/// `SampleSource` and bs-04's `PaletteSource`: the Projects view reads the list
/// through this interface rather than from a store, so the screen stays
/// independent of persistence. bs-06 ships the in-memory [InMemoryProjectSource]
/// for the shell and the acceptance harness, and the persistent
/// [PersistentProjectSource] backed by DATA's store for the real app.
abstract interface class ProjectSource {
  /// The painter's projects, in listing order.
  List<Project> projects();
}

/// An in-memory [ProjectSource] over a fixed list of projects.
///
/// The shell default: an **empty** catalogue (`const InMemoryProjectSource()`),
/// so the Projects view assembles with no projects. The acceptance harness
/// constructs one seeded with a named project; the list is exposed read-only so
/// callers cannot mutate the catalogue through [projects].
class InMemoryProjectSource implements ProjectSource {
  /// Creates a catalogue over [catalogue] (empty by default).
  const InMemoryProjectSource({this.catalogue = const []});

  /// The projects this catalogue holds, in listing order.
  final List<Project> catalogue;

  @override
  List<Project> projects() => List<Project>.unmodifiable(catalogue);
}

/// A [ProjectSource] persisted through the on-device [PersistentStore] (bs-06
/// D-1).
///
/// The write-side bs-06 adds for projects: each project is stored as one JSON
/// document keyed by its [Project.id] in the store's [collection]. The Projects
/// view reads the list synchronously through [projects], so the persisted
/// catalogue is held in an in-memory cache that [load] populates from the store
/// once at startup; [saveProject] is the create/replace the PROJECT behaviour
/// phases drive (the PROJECT-2 enabler creates a project and attaches samples,
/// recipes, a note and a photo to it). The project↔JSON mapping lives here (it
/// reuses the sample mapping from `sample_source.dart`), so the store stays a
/// generic document store (DATA-2) that knows nothing of the project schema.
class PersistentProjectSource implements ProjectSource {
  /// Creates a source over [store]; call [load] before the catalogue is read.
  PersistentProjectSource(this._store);

  /// The store collection the project documents live in.
  static const String collection = 'projects';

  final PersistentStore _store;

  List<Project> _cache = const [];

  /// Loads the stored projects into the in-memory cache [projects] serves.
  ///
  /// Must be awaited before the (synchronous) [projects] is read. Safe to call
  /// again to refresh after a write.
  Future<void> load() async {
    final docs = await _store.list(collection);
    _cache = [for (final doc in docs) _projectFromJson(doc.data)];
  }

  @override
  List<Project> projects() => List<Project>.unmodifiable(_cache);

  /// Persists [project] (create or replace, keyed by its id) and refreshes the
  /// cache so a later [projects] read reflects the write.
  Future<void> saveProject(Project project) async {
    await _store.put(collection, project.id, _projectToJson(project));
    await load();
  }
}

/// Serialises [project] to the JSON-shaped map the store persists.
Map<String, Object?> _projectToJson(Project project) => {
      'id': project.id,
      'name': project.name,
      'size': project.size,
      'samples': [for (final sample in project.samples) sampleToJson(sample)],
      'recipes': [for (final recipe in project.recipes) _recipeToJson(recipe)],
      'note': project.note,
      'sourcePhotoRef': project.sourcePhotoRef,
      'lastEdited': project.lastEdited?.toIso8601String(),
    };

/// Reconstructs a [Project] from a stored document [json].
Project _projectFromJson(Map<String, Object?> json) {
  final lastEdited = json['lastEdited'] as String?;
  return Project(
    id: json['id'] as String,
    name: json['name'] as String,
    size: json['size'] as String?,
    samples: [
      for (final sample in json['samples'] as List)
        sampleFromJson((sample as Map).cast<String, Object?>()),
    ],
    recipes: [
      for (final recipe in json['recipes'] as List)
        _recipeFromJson((recipe as Map).cast<String, Object?>()),
    ],
    note: json['note'] as String?,
    sourcePhotoRef: json['sourcePhotoRef'] as String?,
    lastEdited: lastEdited == null ? null : DateTime.parse(lastEdited),
  );
}

/// Serialises [recipe] to a JSON-shaped map (the medium as its name; the
/// predicted colour as its three CIELAB coordinates; each component's paint via
/// [_paintToJson]).
Map<String, Object?> _recipeToJson(Recipe recipe) => {
      'medium': recipe.medium.name,
      'components': [
        for (final component in recipe.components)
          {
            'paint': _paintToJson(component.paint),
            'partsFraction': component.partsFraction,
            'isTrace': component.isTrace,
            'techniqueNote': component.techniqueNote,
          },
      ],
      'predictedColor': _coordsToJson(recipe.predictedColor),
      'deltaE00': recipe.deltaE00,
      'verdict': recipe.verdict,
      'outOfGamut': recipe.outOfGamut,
      'muddying': recipe.muddying,
    };

/// Reconstructs a [Recipe] from a stored document [json].
Recipe _recipeFromJson(Map<String, Object?> json) => Recipe(
      medium: PaintMedium.values.byName(json['medium'] as String),
      components: [
        for (final component in json['components'] as List)
          _componentFromJson((component as Map).cast<String, Object?>()),
      ],
      predictedColor:
          _coordsFromJson((json['predictedColor'] as Map).cast<String, Object?>()),
      deltaE00: (json['deltaE00'] as num).toDouble(),
      verdict: json['verdict'] as String?,
      outOfGamut: json['outOfGamut'] as bool,
      muddying: json['muddying'] as bool,
    );

/// Reconstructs a [RecipeComponent] from a stored document [json].
RecipeComponent _componentFromJson(Map<String, Object?> json) => RecipeComponent(
      paint: _paintFromJson((json['paint'] as Map).cast<String, Object?>()),
      partsFraction: (json['partsFraction'] as num).toDouble(),
      isTrace: json['isTrace'] as bool,
      techniqueNote: json['techniqueNote'] as String?,
    );

/// Serialises [paint] to a JSON-shaped map (enums as their names; the masstone
/// as its three CIELAB coordinates).
Map<String, Object?> _paintToJson(Paint paint) => {
      'id': paint.id,
      'name': paint.name,
      'medium': paint.medium.name,
      'masstone': _coordsToJson(paint.masstone),
      'pigmentIndex': paint.pigmentIndex,
      'opacity': paint.opacity,
      'brand': paint.brand,
      'line': paint.line,
      'provenance': paint.provenance.name,
    };

/// Reconstructs a [Paint] from a stored document [json].
Paint _paintFromJson(Map<String, Object?> json) => Paint(
      id: json['id'] as String,
      name: json['name'] as String,
      medium: PaintMedium.values.byName(json['medium'] as String),
      masstone: _coordsFromJson((json['masstone'] as Map).cast<String, Object?>()),
      pigmentIndex: json['pigmentIndex'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble(),
      brand: json['brand'] as String?,
      line: json['line'] as String?,
      provenance: ProvenanceTier.values.byName(json['provenance'] as String),
    );

/// Serialises CIELAB [coords] to a `{l, a, b}` map.
Map<String, Object?> _coordsToJson(ColorCoordinates coords) => {
      'l': coords.lightness,
      'a': coords.a,
      'b': coords.b,
    };

/// Reconstructs [ColorCoordinates] from a `{l, a, b}` map.
ColorCoordinates _coordsFromJson(Map<String, Object?> json) => ColorCoordinates(
      lightness: (json['l'] as num).toDouble(),
      a: (json['a'] as num).toDouble(),
      b: (json['b'] as num).toDouble(),
    );
