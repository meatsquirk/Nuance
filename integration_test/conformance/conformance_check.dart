// The reusable accessibility-conformance check (bs-11, GATE-1 shell stub).
//
// `runConformanceCheck` is the single test-support entry every feature's
// acceptance gate imports (D-3): it runs the automated bs-11 rules over a
// rendered screen and aggregates their outcomes into a `ConformanceResult`.
// It lives under `integration_test/` (not `lib/`) because it drives a
// `WidgetTester` and depends on `package:flutter_test`.
//
// GATE-1 lands the **stub only**: it returns `ConformanceResult.empty` (no rule
// has run), so stage-3 acceptance tests compile against the frozen signature
// and fail on their Then at the red baseline. GATE-3 (AC-9) composes the A11Y
// per-rule `check<Rule>` functions (A11Y-2..7) here into a populated result.

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Runs every automated conformance rule over the screen found by [screen] in
/// the tree [tester] is pumping, and returns the aggregate [ConformanceResult].
///
/// GATE-1 stub: returns [ConformanceResult.empty] (all rules absent ⇒ not
/// `passed`). GATE-3 composes the real per-rule checks.
Future<ConformanceResult> runConformanceCheck(
  WidgetTester tester,
  Finder screen,
) async {
  return const ConformanceResult.empty();
}
