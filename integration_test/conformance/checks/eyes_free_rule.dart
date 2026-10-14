// AC-7 eyes-free operability check rule (bs-11, GATE-3).
//
// The per-rule check behind `ConformanceRuleId.eyesFree` composed into the
// aggregate `runConformanceCheck`: a screen is operable eyes-free only if the
// accessibility tree exposes at least one control a screen-reader user can both
// *land on* (a non-empty semantic label) and *activate* (a `SemanticsAction.tap`)
// — the exact per-step predicate the GATE-2 walkthrough driver `eyesFreeComplete`
// enforces (find by label, require a tap action), applied here as a
// non-destructive existence check over the screen rather than a step-by-step
// walkthrough. It never performs the action (so composing it into the aggregate
// does not mutate the screen under check), and it uses the semantics tree only —
// never a widget key, type or coordinate (D-6).
//
// This is the 8th and last `ConformanceRuleId`; until GATE-3 composed it, a
// populated `ConformanceResult` could never report `passed` (that predicate
// requires every id present), so the aggregate gate could not discriminate. The
// screen-reachability AC-7 proper (a core task reaches its terminal state via
// the driver) is covered by `TestAC07` through `eyesFreeComplete`; this rule is
// the aggregate's standing "the screen offers an eyes-free operable control"
// outcome that lets `acceptanceDecision` (GATE-3) read a complete result.
//
// It lives under `integration_test/` (not `lib/`) because it walks the semantics
// tree via a `WidgetTester` and depends on `package:flutter_test`.

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Evaluates the eyes-free rule over the subtree found by [screen] and returns
/// the [ConformanceRuleId.eyesFree] outcome.
///
/// Passes iff some semantics node at or below [screen] carries an accessible
/// name (a non-empty `label`, `tooltip` or `value`) and is activatable (reports
/// [SemanticsAction.tap]) — a screen-reader user can reach and operate it with
/// semantics alone (D-6). The
/// tap action is *not* dispatched, so the check is side-effect-free and safe to
/// run inside the aggregate over every subject. A live [SemanticsHandle] is held
/// for the walk and disposed afterwards so semantics do not leak into the next
/// check (as the sibling semantics rules do).
Future<ConformanceRuleOutcome> checkEyesFree(
  WidgetTester tester,
  Finder screen,
) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    var operable = false;
    void visit(SemanticsNode node) {
      if (operable) return;
      final SemanticsData data = node.getSemanticsData();
      // A screen reader can land on a control that carries an accessible name —
      // a `label`, a `tooltip` or a `value` (the same notion Flutter's
      // `labeledTapTargetGuideline` uses for the AC-6 rule) — and activate it
      // when it reports a `SemanticsAction.tap`. An IconButton names itself via
      // its tooltip, so a label-only check would miss it.
      final hasName = data.label.trim().isNotEmpty ||
          data.tooltip.trim().isNotEmpty ||
          data.value.trim().isNotEmpty;
      if (hasName && data.hasAction(SemanticsAction.tap)) {
        operable = true;
        return;
      }
      node.visitChildren((child) {
        visit(child);
        return !operable;
      });
    }

    visit(tester.getSemantics(screen));
    return operable
        ? const ConformanceRuleOutcome.ok()
        : ConformanceRuleOutcome.fail(
            'no control on the screen is operable eyes-free: a screen-reader '
            'user needs at least one node that carries an accessible name '
            '(label/tooltip/value) and is activatable via SemanticsAction.tap '
            '(D-6)',
          );
  } finally {
    handle.dispose();
  }
}
