import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app/build_app.dart';
import '../projects/project.dart';
import '../projects/project_controller.dart';
import '../projects/project_summary.dart';
import '../store/source_photo_store.dart';

/// The projects region of the Palette screen's Projects view (wireframe S1.R1 —
/// the projects list body, elements E33 Open project and E34 Export to device).
///
/// Lists the painter's projects, read from [ProjectController.projectSummaries],
/// and offers the open (E33) and export (E34) controls. Each row shows the
/// project's name, its size and saved-sample/recipe counts and a relative
/// last-edited label (AC-6, PROJECT-3). Tapping a project row — or the E33 Open
/// control, which opens the first project — opens it into the open-project view
/// (AC-7/AC-8, PROJECT-4): the opened project's note and source photo are shown
/// below the list. The E34 export control stays inert until PDF export lands
/// (AC-10, PROJECT-6). The region keeps its [regionKey], each row its
/// [projectRowKey], the open-project view its [openProjectViewKey], and the
/// controls their [openProjectKey] / [exportKey] so the acceptance finders and
/// those behaviour phases have stable anchors.
class ProjectsRegion extends StatelessWidget {
  const ProjectsRegion({required this.controller, super.key});

  /// Stable anchor for the projects region (AC-1 toggles its presence; AC-6).
  static const Key regionKey = ValueKey('palette-projects-region');

  /// Stable anchor for the E33 open-project control (wired by PROJECT-4).
  static const Key openProjectKey = ValueKey('palette-open-project-button');

  /// Stable anchor for the E34 export control (wired by PROJECT-6, AC-10).
  static const Key exportKey = ValueKey('palette-export-project-button');

  /// Stable anchor for the open-project view that shows the opened project's
  /// note and source photo (AC-7/AC-8), so a Then can scope the shown photo to
  /// this view rather than any image on the screen.
  static const Key openProjectViewKey = ValueKey('palette-open-project-view');

  /// Stable per-row anchor, so a Then can scope to one project's summary row
  /// (AC-6 asserts the last-edit label of a specific project, not the list) and
  /// the open flow can target the tapped project by id (AC-7/AC-8).
  static Key projectRowKey(String projectId) =>
      ValueKey('palette-project-row-$projectId');

  /// The controller supplying the painter's projects.
  final ProjectController controller;

  @override
  Widget build(BuildContext context) {
    final summaries = controller.projectSummaries;
    final opened = controller.openedProject;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Projects', style: Theme.of(context).textTheme.titleMedium),
        if (summaries.isEmpty)
          const Text('No projects yet')
        else
          for (final summary in summaries)
            _ProjectRow(
              summary: summary,
              onOpen: () => controller.openProject(summary.id),
            ),
        Row(
          children: [
            // E33 Open project — opens the first project (PROJECT-4, AC-7/AC-8).
            // A painter also opens a specific project by tapping its row above;
            // this primary control is inert only when there are no projects.
            TextButton(
              key: openProjectKey,
              onPressed: summaries.isEmpty
                  ? null
                  : () => controller.openProject(summaries.first.id),
              child: const Text('Open project'),
            ),
            // E34 Export to device — wired by PROJECT-6 (AC-10). Inert here.
            TextButton(
              key: exportKey,
              onPressed: null,
              child: const Text('Export'),
            ),
          ],
        ),
        // The open-project view (AC-7/AC-8): the opened project's note and
        // source photo, shown below the list once a project is opened.
        if (opened != null)
          _OpenProjectView(
            project: opened,
            photos: AppScope.of(context).sourcePhotoStore,
            confusionPairs: controller.confusionPairs,
          ),
      ],
    );
  }
}

/// One project's summary row (AC-6): the name, a detail line of size and counts,
/// and a relative last-edit label when the project has been edited.
///
/// Tapping the row opens the project (E33, AC-7/AC-8) via [onOpen].
class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.summary, required this.onOpen});

  final ProjectSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final detail = <String>[
      if (summary.size != null) summary.size!,
      summary.sampleCountLabel,
      summary.recipeCountLabel,
    ].join(' · ');
    return GestureDetector(
      key: ProjectsRegion.projectRowKey(summary.id),
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.name),
            Text(detail),
            if (summary.lastEditedLabel != null) Text(summary.lastEditedLabel!),
          ],
        ),
      ),
    );
  }
}

/// The open-project view (AC-7/AC-8): shows the opened [project]'s note and its
/// source photo.
///
/// The note is rendered verbatim (AC-8 asserts the retained note is shown on
/// reopen). The source photo is loaded from [photos] by the project's
/// [Project.sourcePhotoRef] — the project keeps only the reference, never the
/// pixels (D-10) — and rendered as an [Image] once its bytes are read. The photo
/// is omitted when the project carries no reference or no photo store is wired.
class _OpenProjectView extends StatelessWidget {
  const _OpenProjectView({
    required this.project,
    required this.photos,
    required this.confusionPairs,
  });

  final Project project;
  final SourcePhotoStore? photos;

  /// The project's saved-sample pairs flagged as confusable for the painter
  /// (AC-9); each is shown under a "check these by value" warning.
  final List<ConfusionPair> confusionPairs;

  @override
  Widget build(BuildContext context) {
    final note = project.note;
    final reference = project.sourcePhotoRef;
    final store = photos;
    return Column(
      key: ProjectsRegion.openProjectViewKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(project.name, style: Theme.of(context).textTheme.titleSmall),
        if (note != null) Text(note),
        if (reference != null && store != null)
          _SourcePhoto(store: store, reference: reference),
        // AC-9: pairs that look identical to the painter are flagged to check
        // by value. Shown only when at least one pair collapses.
        if (confusionPairs.isNotEmpty) ...[
          const Text('Check these by value — they may look identical to you:'),
          for (final pair in confusionPairs)
            Text('${pair.a.name} and ${pair.b.name}'),
        ],
      ],
    );
  }
}

/// Loads and renders the opened project's source photo from [store] by
/// [reference], once its bytes are read (AC-7).
class _SourcePhoto extends StatelessWidget {
  const _SourcePhoto({required this.store, required this.reference});

  final SourcePhotoStore store;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: store.read(reference),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return const SizedBox.shrink();
        // The suite's placeholder photo bytes are not a decodable image (D-10:
        // these ACs assert presence, not pixels), so a decode failure is
        // swallowed rather than thrown — the [Image] widget is still shown.
        return Image.memory(bytes,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink());
      },
    );
  }
}
