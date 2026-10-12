import '../a11y/cvd/confusion_check.dart';
import '../a11y/cvd/cvd_profile.dart';
import 'project.dart';
import 'project_controller.dart';

/// Flags each unordered pair of a project's saved samples that the painter with
/// colour-vision [profile] cannot tell apart (bs-06 AC-9).
///
/// Pure glue over bs-03's injected [ConfusionCheck] (the shipped
/// `DichromatConfusionCheck`, D-4/D-5) — it iterates the opened project's
/// [Project.samples] pairwise and keeps the pairs [check] reports
/// [ConfusionCheck.confusable] for [profile]. **No new CVD math:** the
/// projection and the ΔE00 metric live behind [check]; this only enumerates the
/// candidate pairs. The open-project view renders the result as a "check these
/// by value" warning and the acceptance suite reads it off
/// [ProjectController.confusionPairs].
///
/// Pairs are returned in the project's sample order (outer index first), each a
/// [ConfusionPair] record of the two samples; the list is empty when no pair
/// collapses (or the project holds fewer than two samples).
List<ConfusionPair> flagConfusionPairs(
  Project project,
  ConfusionCheck check,
  CvdProfile profile,
) {
  final samples = project.samples;
  final pairs = <ConfusionPair>[];
  for (var i = 0; i < samples.length; i++) {
    for (var j = i + 1; j < samples.length; j++) {
      final a = samples[i];
      final b = samples[j];
      if (check.confusable(a.coordinates, b.coordinates, profile)) {
        pairs.add((a: a, b: b));
      }
    }
  }
  return pairs;
}
