import 'package:flutter/foundation.dart';

import '../domain/sample.dart';
import '../recipes/engine/mixing_engine.dart';
import '../store/source_photo_store.dart';
import 'project.dart';
import 'project_source.dart';
import 'project_summary.dart';

/// A pair of a project's saved samples flagged as confusable for the painter's
/// colour-vision profile (bs-06 AC-9).
///
/// The shape the open-project view renders as a "check these by value" warning
/// and the acceptance suite reads off [ProjectController.confusionPairs].
/// PROJECT-5 fills the list by iterating the opened project's sample pairs
/// through the injected bs-03 `DichromatConfusionCheck` (D-4); the shell exposes
/// the shape only (always empty).
typedef ConfusionPair = ({Sample a, Sample b});

/// The Projects screen's state: the painter's projects, the opened project, the
/// confusion pairs flagged within it and the last export it produced (bs-06
/// PROJECT-1).
///
/// A [ChangeNotifier] over a [ProjectSource], mirroring the bs-04
/// `RecipeController` and bs-06 `PaletteController` patterns. PROJECT-1 shipped
/// the state and the reads; **PROJECT-2** (this enabler) adds the create and
/// attach flows that make a project real through public calls: [createProject]
/// starts one, and [attachSamples] / [attachRecipes] / [setSize] / [saveNote] /
/// [attachSourcePhoto] accrue its contents, each stamping [Project.lastEdited]
/// and persisting through [PersistentProjectSource.saveProject] so the change
/// survives a restart (an in-memory source keeps it in memory only, like
/// `PaletteController`). The remaining observables stay shell state until their
/// phase: **PROJECT-4** (this phase) opens a project's note and photo
/// (AC-7/AC-8) through [openProject]; PROJECT-5 fills [confusionPairs] (AC-9);
/// PROJECT-6 produces [lastExport] (AC-10). No CVD, recipe or export math is
/// done here.
class ProjectController extends ChangeNotifier {
  /// Creates the controller over [source], reading the projects it lists once at
  /// construction (a fresh install's source is empty — the shell default).
  ///
  /// Mirrors `PaletteController`: the source's listing seeds the mutable working
  /// list the create/attach flows extend, and [source] is kept so those flows
  /// can persist through it when it is a [PersistentProjectSource]. A persistent
  /// source is [PersistentProjectSource.load]ed before the controller is built.
  ProjectController({required ProjectSource source})
      : _source = source,
        _projects = [...source.projects()];

  final ProjectSource _source;

  List<Project> _projects;

  Project? _openedProject;

  /// The painter's projects, in listing order (read-only). AC-6 renders each
  /// one's size, counts and last edit; PROJECT-3 computes that summary.
  List<Project> get projects => List<Project>.unmodifiable(_projects);

  /// The painter's projects as list-row summaries (AC-6): each project's size,
  /// saved-sample and recipe counts and a relative last-edited label, in the
  /// same order as [projects]. The Projects region renders these (PROJECT-3).
  List<ProjectSummary> get projectSummaries =>
      [for (final project in _projects) ProjectSummary.of(project)];

  /// The project currently opened in the open-project view (AC-7/AC-8), or null
  /// when none is open (the state before any [openProject] call).
  ///
  /// [openProject] sets it to the live working-list project, so its note and
  /// source-photo reference are the retained ones (AC-8: a note saved on a
  /// project is shown again when it is reopened).
  Project? get openedProject => _openedProject;

  /// The confusable sample pairs flagged within the opened project (AC-9), or an
  /// empty list when none are (the shell's state). PROJECT-5 computes these.
  List<ConfusionPair> get confusionPairs => const [];

  /// The bytes of the most recent PDF studio sheet exported from a project
  /// (AC-10), or null when nothing has been exported (the shell's state).
  /// PROJECT-6 produces it through a faked file sink in tests.
  Uint8List? get lastExport => null;

  /// Opens the project identified by [projectId] into the open-project view
  /// (AC-7/AC-8), making it the [openedProject] and notifying listeners.
  ///
  /// The opened project is taken from the controller's live working list, so a
  /// project seeded or edited through the persistent save flow is reopened with
  /// its retained note and source-photo reference (AC-8). Throws a [StateError]
  /// when no project carries [projectId].
  void openProject(String projectId) {
    final project = _projects.firstWhere(
      (project) => project.id == projectId,
      orElse: () =>
          throw StateError('no project with id "$projectId" to open'),
    );
    _openedProject = project;
    notifyListeners();
  }

  /// Creates a new project [id]/[name] (optionally with a free-text [size],
  /// G-4), stamps it edited now, appends it to [projects] and persists it.
  ///
  /// Returns the created project so the caller can accrue contents onto it
  /// through the attach flows. Listeners are notified so the Projects list
  /// re-renders.
  Future<Project> createProject({
    required String id,
    required String name,
    String? size,
  }) async {
    final project = Project(
      id: id,
      name: name,
      size: size,
      lastEdited: DateTime.now(),
    );
    _projects = [..._projects, project];
    await _persist(project);
    notifyListeners();
    return project;
  }

  /// Appends [samples] to the saved samples of the project identified by
  /// [projectId] and persists the change (AC-6/AC-9 build from these).
  Future<Project> attachSamples(String projectId, List<Sample> samples) =>
      _mutate(projectId,
          (project) => project.copyWith(samples: [...project.samples, ...samples]));

  /// Appends [recipes] to the saved recipes of the project identified by
  /// [projectId] and persists the change (AC-6/AC-10 reference these).
  Future<Project> attachRecipes(String projectId, List<Recipe> recipes) =>
      _mutate(projectId,
          (project) => project.copyWith(recipes: [...project.recipes, ...recipes]));

  /// Sets the free-text [size] of the project identified by [projectId] (G-4)
  /// and persists the change (AC-6 renders it).
  Future<Project> setSize(String projectId, String size) =>
      _mutate(projectId, (project) => project.copyWith(size: size));

  /// Saves the working [note] on the project identified by [projectId] and
  /// persists it so it is retained across a reopen (AC-7/AC-8).
  Future<Project> saveNote(String projectId, String note) =>
      _mutate(projectId, (project) => project.copyWith(note: note));

  /// Stores the source-photo [bytes] in [photos] and records the returned
  /// reference on the project identified by [projectId] (D-10), persisting the
  /// change (AC-7). The project keeps only the reference, never the pixels.
  Future<Project> attachSourcePhoto(
    String projectId,
    SourcePhotoStore photos,
    Uint8List bytes,
  ) async {
    final reference = await photos.save(bytes);
    return _mutate(
        projectId, (project) => project.copyWith(sourcePhotoRef: reference));
  }

  /// Applies [change] to the project identified by [projectId], re-stamps its
  /// [Project.lastEdited], persists it and notifies listeners.
  ///
  /// Throws a [StateError] when no project carries [projectId] (a create flow
  /// must precede an attach).
  Future<Project> _mutate(
    String projectId,
    Project Function(Project project) change,
  ) async {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index < 0) {
      throw StateError('no project with id "$projectId" to attach to');
    }
    final updated = change(_projects[index]).copyWith(lastEdited: DateTime.now());
    _projects = [..._projects]..[index] = updated;
    await _persist(updated);
    notifyListeners();
    return updated;
  }

  /// Persists [project] when the source can (a [PersistentProjectSource] — the
  /// production and acceptance wiring); an in-memory source keeps the working
  /// list in memory only, like `PaletteController`.
  Future<void> _persist(Project project) async {
    final source = _source;
    if (source is PersistentProjectSource) {
      await source.saveProject(project);
    }
  }
}
