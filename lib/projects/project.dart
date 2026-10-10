import '../domain/sample.dart';
import '../recipes/engine/mixing_engine.dart';

/// A painting project the painter keeps: a named body of work with the saved
/// samples and recipes gathered for it, a free-text [size], a working [note], a
/// reference to its source photo and the time it was [lastEdited] (bs-06 D-8).
///
/// The aggregate the Projects view lists (AC-6) and the open-project view shows
/// (AC-7/AC-8), the scope the confusion check iterates (AC-9) and the PDF studio
/// sheet is exported from (AC-10). It reuses the bs-01/03 [Sample] and the bs-04
/// [Recipe] rather than re-modelling them, and keeps only a *reference* to the
/// source photo — the pixels live in the `SourcePhotoStore`, never in the
/// project (D-10). [size] is free text (e.g. `24×30 in`) per G-4, not a
/// structured measurement.
///
/// An entity (identified by [id], like [Sample]), so it carries a [copyWith] for
/// the PROJECT-2 attach flows but no value equality — two projects with the same
/// contents are still different projects. PROJECT-1 ships the shape; the
/// behaviour that creates one and attaches to it is the PROJECT-2 enabler.
class Project {
  /// Creates a project. [id] and [name] are required; everything a project
  /// accrues over its life defaults to absent/empty so a just-created project is
  /// a valid, near-empty [Project].
  const Project({
    required this.id,
    required this.name,
    this.size,
    this.samples = const [],
    this.recipes = const [],
    this.note,
    this.sourcePhotoRef,
    this.lastEdited,
  });

  /// Stable identity of the project (keys its stored document; names may repeat).
  final String id;

  /// The painter-facing project name (e.g. "Harbor at Dusk"), shown in the list.
  final String name;

  /// The project's physical size as free text (e.g. `24×30 in`), or null when
  /// unset (G-4: free text, not structured units).
  final String? size;

  /// The samples saved to this project, in listing order (reuses bs-01/03
  /// [Sample]); empty until samples are attached (PROJECT-2).
  final List<Sample> samples;

  /// The recipes saved to this project, in listing order (reuses bs-04
  /// [Recipe]); empty until recipes are attached (PROJECT-2).
  final List<Recipe> recipes;

  /// The painter's working note for the project (AC-7/AC-8), or null when none.
  final String? note;

  /// The reference the `SourcePhotoStore` returns for the project's source photo
  /// (D-10), or null when no photo is attached. Never the pixels themselves.
  final String? sourcePhotoRef;

  /// When the project was last edited (AC-6's "last edit"), or null until it is
  /// first stamped (PROJECT-2 sets it on each change).
  final DateTime? lastEdited;

  /// Returns a copy of this project with the given fields replaced.
  ///
  /// The attach flows (PROJECT-2) build the next project state from the current
  /// one through this; passing nothing returns an equivalent project. Nullable
  /// fields cannot be cleared through [copyWith] (a null argument keeps the
  /// current value) — the shell has no clear flow, and none is needed yet.
  Project copyWith({
    String? id,
    String? name,
    String? size,
    List<Sample>? samples,
    List<Recipe>? recipes,
    String? note,
    String? sourcePhotoRef,
    DateTime? lastEdited,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      samples: samples ?? this.samples,
      recipes: recipes ?? this.recipes,
      note: note ?? this.note,
      sourcePhotoRef: sourcePhotoRef ?? this.sourcePhotoRef,
      lastEdited: lastEdited ?? this.lastEdited,
    );
  }

  @override
  String toString() =>
      'Project($id "$name", ${samples.length} samples, '
      '${recipes.length} recipes)';
}
