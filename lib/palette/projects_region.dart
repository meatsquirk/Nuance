import 'package:flutter/material.dart';

import '../projects/project_controller.dart';
import '../projects/project_summary.dart';

/// The projects region of the Palette screen's Projects view (wireframe S1.R1 —
/// the projects list body, elements E33 Open project and E34 Export to device).
///
/// Lists the painter's projects, read from [ProjectController.projectSummaries],
/// and offers the open (E33) and export (E34) controls. Each row shows the
/// project's name, its size and saved-sample/recipe counts and a relative
/// last-edited label (AC-6, PROJECT-3), with an empty-state placeholder. The
/// open (E33) and export (E34) controls are present but inert: opening a project
/// (AC-7/AC-8) lands in PROJECT-4 and PDF export (AC-10) in PROJECT-6. The region
/// keeps its [regionKey], each row its [projectRowKey], and the controls their
/// [openProjectKey] / [exportKey] so the acceptance finders and those behaviour
/// phases have stable anchors.
class ProjectsRegion extends StatelessWidget {
  const ProjectsRegion({required this.controller, super.key});

  /// Stable anchor for the projects region (AC-1 toggles its presence; AC-6).
  static const Key regionKey = ValueKey('palette-projects-region');

  /// Stable anchor for the E33 open-project control (wired by PROJECT-4).
  static const Key openProjectKey = ValueKey('palette-open-project-button');

  /// Stable anchor for the E34 export control (wired by PROJECT-6, AC-10).
  static const Key exportKey = ValueKey('palette-export-project-button');

  /// Stable per-row anchor, so a Then can scope to one project's summary row
  /// (AC-6 asserts the last-edit label of a specific project, not the list).
  static Key projectRowKey(String projectId) =>
      ValueKey('palette-project-row-$projectId');

  /// The controller supplying the painter's projects.
  final ProjectController controller;

  @override
  Widget build(BuildContext context) {
    final summaries = controller.projectSummaries;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Projects', style: Theme.of(context).textTheme.titleMedium),
        if (summaries.isEmpty)
          const Text('No projects yet')
        else
          for (final summary in summaries) _ProjectRow(summary: summary),
        Row(
          children: [
            // E33 Open project — wired by PROJECT-4 (AC-7/AC-8). Inert here.
            TextButton(
              key: openProjectKey,
              onPressed: null,
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
      ],
    );
  }
}

/// One project's summary row (AC-6): the name, a detail line of size and counts,
/// and a relative last-edit label when the project has been edited.
class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.summary});

  final ProjectSummary summary;

  @override
  Widget build(BuildContext context) {
    final detail = <String>[
      if (summary.size != null) summary.size!,
      summary.sampleCountLabel,
      summary.recipeCountLabel,
    ].join(' · ');
    return Padding(
      key: ProjectsRegion.projectRowKey(summary.id),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.name),
          Text(detail),
          if (summary.lastEditedLabel != null) Text(summary.lastEditedLabel!),
        ],
      ),
    );
  }
}
