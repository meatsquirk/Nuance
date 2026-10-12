import 'project.dart';

/// A read-model of one [Project] for a row of the Projects list (bs-06 AC-6):
/// the project's name, its free-text [size], its saved-sample and recipe counts
/// and a relative "last edited" label.
///
/// PROJECT-1 shipped [Project]; PROJECT-2 made one real through the create/attach
/// flows; **PROJECT-3** (this phase) derives this summary off a project so the
/// Projects region can render each row's size, counts and last edit rather than
/// the shell's name alone. It holds no widgets and does no persistence — a pure
/// projection, so the relative label is computed against an injected [now] (its
/// only non-determinism) and every branch is unit-testable without a clock.
class ProjectSummary {
  /// Creates a summary from already-computed fields (used by [of] and tests).
  const ProjectSummary({
    required this.id,
    required this.name,
    required this.size,
    required this.sampleCount,
    required this.recipeCount,
    required this.lastEditedLabel,
  });

  /// Derives the summary of [project] relative to [now] (defaults to the current
  /// time — the only non-determinism, injected so tests pin the last-edit label).
  factory ProjectSummary.of(Project project, {DateTime? now}) {
    return ProjectSummary(
      id: project.id,
      name: project.name,
      size: project.size,
      sampleCount: project.samples.length,
      recipeCount: project.recipes.length,
      lastEditedLabel:
          _lastEditedLabel(project.lastEdited, now ?? DateTime.now()),
    );
  }

  /// The project's stable id (keys its row).
  final String id;

  /// The painter-facing project name.
  final String name;

  /// The project's free-text size (e.g. `24×30 in`), or null when unset (G-4).
  final String? size;

  /// The number of samples saved to the project.
  final int sampleCount;

  /// The number of recipes saved to the project.
  final int recipeCount;

  /// The relative "last edited" label (e.g. "Edited today"), or null when the
  /// project has never been stamped (a just-shelled project).
  final String? lastEditedLabel;

  /// The sample count as a pluralised phrase ("1 sample", "6 samples").
  String get sampleCountLabel => _plural(sampleCount, 'sample');

  /// The recipe count as a pluralised phrase ("1 recipe", "3 recipes").
  String get recipeCountLabel => _plural(recipeCount, 'recipe');

  static String _plural(int count, String noun) =>
      count == 1 ? '1 $noun' : '$count ${noun}s';

  /// Formats [lastEdited] relative to [now] at calendar-day granularity, so a
  /// project edited at any time today reads "today" regardless of the clock.
  static String? _lastEditedLabel(DateTime? lastEdited, DateTime now) {
    if (lastEdited == null) return null;
    final editedDay =
        DateTime(lastEdited.year, lastEdited.month, lastEdited.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(editedDay).inDays;
    if (days <= 0) return 'Edited today';
    if (days == 1) return 'Edited yesterday';
    return 'Edited $days days ago';
  }
}
