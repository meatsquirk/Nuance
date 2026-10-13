// AC-5 contrast check rule (bs-11, A11Y-2).
//
// The per-rule check behind `ConformanceRuleId.contrastAA`: it evaluates
// Flutter's own `textContrastGuideline` (a `MinimumTextContrastGuideline`
// pinned to `kMinimumRatioNormalText` 4.5 / `kMinimumRatioLargeText` 3.0 — the
// WCAG 2.2 AA floor, D-5) over the tree the tester is pumping and reports a
// `ConformanceRuleOutcome`.
//
// It lives under `integration_test/` (not `lib/`) because it drives a
// `WidgetTester` and depends on `package:flutter_test`. The reusable aggregate
// `runConformanceCheck` (GATE's file) composes this check — and, as the later
// A11Y phases land, the other per-rule checks — into a `ConformanceResult`.

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Evaluates the WCAG 2.2 AA text-contrast floor over the tree [tester] is
/// pumping and returns the [ConformanceRuleId.contrastAA] outcome.
///
/// Delegates to Flutter's [textContrastGuideline], which rasterises every
/// render view and checks each painted text run against its background at the
/// AA ratios (4.5:1 normal, 3:1 large — the guideline's own
/// `kMinimumRatioNormalText` / `kMinimumRatioLargeText` constants, pinned by
/// GATE-4). [screen] is accepted for signature parity with the other per-rule
/// checks; the contrast guideline is inherently tree-wide, so a test isolates
/// its subject by pumping only that subtree (the harness's control fixtures do
/// exactly this).
///
/// The guideline reads painted text through the semantics tree, so a live
/// [SemanticsHandle] must be held for the evaluation (the same thing
/// `meetsGuideline` does internally); it is disposed afterwards so semantics do
/// not leak into the next check.
Future<ConformanceRuleOutcome> checkContrastAA(
  WidgetTester tester,
  Finder screen,
) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final Evaluation result = await textContrastGuideline.evaluate(tester);
    return result.passed
        ? const ConformanceRuleOutcome.ok()
        : ConformanceRuleOutcome.fail(
            result.reason ?? 'text below the WCAG 2.2 AA contrast floor',
          );
  } finally {
    handle.dispose();
  }
}
