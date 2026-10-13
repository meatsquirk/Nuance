// The reusable accessibility-conformance check (bs-11, GATE-1 shell stub).
//
// `runConformanceCheck` is the single test-support entry every feature's
// acceptance gate imports (D-3): it runs the automated bs-11 rules over a
// rendered screen and aggregates their outcomes into a `ConformanceResult`.
// It lives under `integration_test/` (not `lib/`) because it drives a
// `WidgetTester` and depends on `package:flutter_test`.
//
// GATE-1 landed the **stub** (returned `ConformanceResult.empty` — no rule had
// run). Each A11Y/GATE behaviour phase then composes its per-rule `check<Rule>`
// into the aggregate below as it lands (A11Y-2 contrast first); GATE-3 (AC-9)
// is the barrier that asserts every [ConformanceRuleId] is present and
// implements the pure-domain `acceptanceDecision` over the full result.

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

import 'checks/contrast.dart';

/// Runs every automated conformance rule landed so far over the screen found by
/// [screen] in the tree [tester] is pumping, and returns the aggregate
/// [ConformanceResult].
///
/// The result grows one rule per behaviour phase:
///   * A11Y-2 — [ConformanceRuleId.contrastAA] (text meets the WCAG 2.2 AA floor)
///   * A11Y-3..7 / GATE-2 add their rules here as they land
///
/// GATE-3 then asserts the map holds every [ConformanceRuleId] (so a partial or
/// empty aggregate reads as *not* `passed`). Until then `passed` is false for
/// any screen — but a per-rule AC test reads only `outcomeFor(itsRuleId)`, so
/// each AC un-pends independently as its rule lands.
Future<ConformanceResult> runConformanceCheck(
  WidgetTester tester,
  Finder screen,
) async {
  final outcomes = <ConformanceRuleId, ConformanceRuleOutcome>{
    // A11Y-2 — AC-5: WCAG 2.2 AA text contrast (textContrastGuideline).
    ConformanceRuleId.contrastAA: await checkContrastAA(tester, screen),
  };
  return ConformanceResult(outcomes);
}
