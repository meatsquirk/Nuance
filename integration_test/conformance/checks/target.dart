// AC-4 tap-target check rule (bs-11, A11Y-3).
//
// The per-rule check behind `ConformanceRuleId.tapTarget48`: it evaluates
// Flutter's own tap-target guidelines over the tree the tester is pumping and
// reports a `ConformanceRuleOutcome`. The 48dp floor (D-5) is enforced by
// requiring **both** the Android guideline (`androidTapTargetGuideline`, a
// `MinimumTapTargetGuideline` at 48×48) **and** the iOS guideline
// (`iOSTapTargetGuideline`, 44×44) to hold: the Android 48dp bound is the
// stricter (binding) one, so combining them with `&&` enforces the 48dp floor
// on every platform, not merely each platform's native minimum.
//
// It lives under `integration_test/` (not `lib/`) because it drives a
// `WidgetTester` and depends on `package:flutter_test`. The reusable aggregate
// `runConformanceCheck` (GATE's file) composes this check — and, as the other
// A11Y phases land, the remaining per-rule checks — into a `ConformanceResult`.

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Evaluates the 48dp tap-target floor over the tree [tester] is pumping and
/// returns the [ConformanceRuleId.tapTarget48] outcome.
///
/// Delegates to Flutter's [androidTapTargetGuideline] (48×48) and
/// [iOSTapTargetGuideline] (44×44) and combines them with
/// [Evaluation.operator +] (`passed` is `&&`, reasons concatenated): every
/// tappable semantic node must clear **both**, so the Android 48dp minimum is
/// the effective floor on all platforms (D-5). [screen] is accepted for
/// signature parity with the other per-rule checks; the guidelines are
/// inherently tree-wide, so a test isolates its subject by pumping only that
/// subtree (the harness's control fixtures do exactly this).
///
/// Each guideline reads tappable nodes through the semantics tree, so a live
/// [SemanticsHandle] must be held for the evaluation (the same thing
/// `meetsGuideline` does internally); it is disposed afterwards so semantics do
/// not leak into the next check.
Future<ConformanceRuleOutcome> checkTapTarget48(
  WidgetTester tester,
  Finder screen,
) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final Evaluation android = await androidTapTargetGuideline.evaluate(tester);
    final Evaluation ios = await iOSTapTargetGuideline.evaluate(tester);
    final Evaluation combined = android + ios;
    return combined.passed
        ? const ConformanceRuleOutcome.ok()
        : ConformanceRuleOutcome.fail(
            combined.reason ?? 'an interactive target is below the 48dp minimum',
          );
  } finally {
    handle.dispose();
  }
}
