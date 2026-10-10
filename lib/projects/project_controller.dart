import 'package:flutter/foundation.dart';

import '../domain/sample.dart';
import 'project.dart';
import 'project_source.dart';

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
/// A [ChangeNotifier] skeleton over a [ProjectSource], mirroring the bs-04
/// `RecipeController` and bs-06 `PaletteController` patterns. PROJECT-1 ships the
/// state and reads only: [projects] comes from the injected source and the other
/// observables are the empty/absent shell state. The behaviour lands in the
/// PROJECT phases: PROJECT-2 (the enabler) creates a project and attaches
/// samples/recipes/a note/a photo through [PersistentProjectSource.saveProject];
/// PROJECT-3 computes the list summary (AC-6); PROJECT-4 opens a project's note
/// and photo (AC-7/AC-8); PROJECT-5 fills [confusionPairs] (AC-9); PROJECT-6
/// produces [lastExport] (AC-10). No CVD, recipe or export math is done here.
class ProjectController extends ChangeNotifier {
  /// Creates the controller over [source], reading the projects it lists once at
  /// construction (a fresh install's source is empty — the shell default).
  ///
  /// Mirrors `PaletteController`: the source is read into [_projects] here rather
  /// than kept, so a persistent source is [PersistentProjectSource.load]ed before
  /// the controller is built. PROJECT-2+ drive refresh after a save.
  ProjectController({required ProjectSource source})
      : _projects = source.projects();

  final List<Project> _projects;

  /// The painter's projects, in listing order (read-only). AC-6 renders each
  /// one's size, counts and last edit; PROJECT-3 computes that summary.
  List<Project> get projects => List<Project>.unmodifiable(_projects);

  /// The project currently opened in the open-project view (AC-7/AC-8), or null
  /// when none is open. PROJECT-4 drives opening; the shell has none open.
  Project? get openedProject => null;

  /// The confusable sample pairs flagged within the opened project (AC-9), or an
  /// empty list when none are (the shell's state). PROJECT-5 computes these.
  List<ConfusionPair> get confusionPairs => const [];

  /// The bytes of the most recent PDF studio sheet exported from a project
  /// (AC-10), or null when nothing has been exported (the shell's state).
  /// PROJECT-6 produces it through a faked file sink in tests.
  Uint8List? get lastExport => null;
}
