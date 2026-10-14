// AC-6 meaningful-label check rule (bs-11, A11Y-6).
//
// The per-rule check behind `ConformanceRuleId.meaningfulLabel`: every
// interactive control must expose a non-empty screen-reader label, so a screen
// reader announces *what each control does* rather than an anonymous "button".
// It delegates to Flutter's own `labeledTapTargetGuideline` — the same
// delegate-to-the-authoritative-guideline shape the sibling rules use
// (`checkTapTarget48` → the tap-target guidelines, `checkContrastAA` → the
// contrast guideline). `labeledTapTargetGuideline` walks the semantics tree and
// fails any node that has a tap/long-press action, is not a text field and is
// not merged/hidden, yet carries neither a `label` nor a `tooltip`. That is
// exactly AC-6's "every interactive control carries a meaningful semantic
// label": an `IconButton` with a `tooltip`, a `Semantics(label:…)` wrapper, or a
// control whose child text is merged up all satisfy it; an `IconButton` with no
// tooltip/label (the `control_unlabelled` fixture) fails it.
//
// It lives under `integration_test/` (not `lib/`) because it drives a
// `WidgetTester` and depends on `package:flutter_test`. The reusable aggregate
// `runConformanceCheck` composes this check into a `ConformanceResult`.

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Evaluates AC-6 over the tree [tester] is pumping and returns the
/// [ConformanceRuleId.meaningfulLabel] outcome.
///
/// Delegates to Flutter's [labeledTapTargetGuideline]: every tappable semantic
/// node must carry a non-empty `label` or `tooltip`. [screen] is accepted for
/// signature parity with the other per-rule checks; the guideline is inherently
/// tree-wide, so a test isolates its subject by pumping only that subtree (the
/// harness's control fixtures do exactly this, while a real-screen sweep checks
/// the whole assembled app).
///
/// The guideline reads tappable nodes through the semantics tree, so a live
/// [SemanticsHandle] must be held for the evaluation (as `checkTapTarget48`
/// does); it is disposed afterwards so semantics do not leak into the next
/// check.
Future<ConformanceRuleOutcome> checkMeaningfulLabel(
  WidgetTester tester,
  Finder screen,
) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    final Evaluation labelled = await labeledTapTargetGuideline.evaluate(tester);
    return labelled.passed
        ? const ConformanceRuleOutcome.ok()
        : ConformanceRuleOutcome.fail(
            labelled.reason ??
                'an interactive control has no meaningful semantic label',
          );
  } finally {
    handle.dispose();
  }
}
