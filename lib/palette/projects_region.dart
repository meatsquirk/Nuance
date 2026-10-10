import 'package:flutter/material.dart';

import '../projects/project_controller.dart';

/// The projects region of the Palette screen's Projects view (wireframe S1.R1 —
/// the projects list body, elements E33 Open project and E34 Export to device).
///
/// Lists the painter's projects, read from [ProjectController.projects], and
/// offers the open (E33) and export (E34) controls. This shell renders each
/// project by name with an empty-state placeholder, and both controls are
/// present but inert: the list summary (size/counts/last edit, AC-6) lands in
/// PROJECT-3, opening a project (AC-7/AC-8) in PROJECT-4, and PDF export (AC-10)
/// in PROJECT-6. The region keeps its [regionKey] and the controls their
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

  /// The controller supplying the painter's projects.
  final ProjectController controller;

  @override
  Widget build(BuildContext context) {
    final projects = controller.projects;
    return Column(
      key: regionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Projects', style: Theme.of(context).textTheme.titleMedium),
        if (projects.isEmpty)
          const Text('No projects yet')
        else
          for (final project in projects) Text(project.name),
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
