// AC-3 font-scaling check rule (bs-11, A11Y-4).
//
// The per-rule check behind `ConformanceRuleId.fontScale200`: it re-renders the
// tree the tester is pumping at a 200% system font scale and reports a
// `ConformanceRuleOutcome` — passing when the layout reflows cleanly, failing
// when a `Row`/`Column` is forced to lay a child out beyond its own bounds.
//
// Detection is by **measurement**, not by catching the paint-time
// "A RenderFlex overflowed…" FlutterError: that error is only reported on a
// *fresh* layout pass, so scaling an already-painted tree in place does not
// re-report it reliably. Instead the rule walks the subject's render tree and,
// for every [RenderFlex], compares the summed main-axis extent of its children
// with the flex's own main-axis extent — exactly the quantity `RenderFlex`
// itself calls an overflow. This is deterministic on the in-place rescaled tree
// and, by construction, ignores the legitimate responses to bigger text:
//   * a [Wrap] (a `RenderWrap`, not a `RenderFlex`) reflows and is skipped;
//   * a scrollable (`ListView`/`SingleChildScrollView`) gives its child an
//     unbounded main axis, so the child's size equals its content and never
//     exceeds the flex extent — it scrolls, it does not overflow.
//
// The text scale is restored before the rule returns, so it never leaks into the
// next check or screen. It lives under `integration_test/` (not `lib/`) because
// it drives a `WidgetTester`. The reusable aggregate `runConformanceCheck`
// composes it.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/acceptance.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Re-renders the subtree found by [screen] at 200% font scale and returns the
/// [ConformanceRuleId.fontScale200] outcome: [ConformanceRuleOutcome.ok] when no
/// `Row`/`Column` overflows, [ConformanceRuleOutcome.fail] (naming the first
/// overflow) otherwise.
Future<ConformanceRuleOutcome> checkFontScale200(
  WidgetTester tester,
  Finder screen,
) async {
  final double previousScale = tester.platformDispatcher.textScaleFactor;
  // Swallow the paint-time "A RenderFlex overflowed…" FlutterError while scaled:
  // the verdict comes from the measurement below, and letting the report reach
  // the test binding would fail the test for the very overflow the rule is
  // deliberately exercising. Scoped to the rescale window — the only error a
  // static tree raises here is the overflow indicator — and restored in
  // `finally`.
  final FlutterExceptionHandler? previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails _) {};
  String? overflow;
  try {
    tester.platformDispatcher.textScaleFactorTestValue =
        WcagThresholds.minSupportedTextScale;
    // Two frames so the MediaQuery change rebuilds and the tree re-lays-out at
    // the larger scale before it is measured.
    await tester.pump();
    await tester.pump();
    overflow = _firstFlexOverflow(tester.renderObject(screen));
  } finally {
    tester.platformDispatcher.textScaleFactorTestValue = previousScale;
    await tester.pump();
    FlutterError.onError = previousOnError;
    // Clear any overflow error that still reached the binding, so it is not
    // re-surfaced as an unrelated failure in a later check or at teardown.
    tester.takeException();
  }
  return overflow == null
      ? const ConformanceRuleOutcome.ok()
      : ConformanceRuleOutcome.fail('layout breaks at 200% text scale: $overflow');
}

/// The first `Row`/`Column` at or under [root] whose children's combined
/// main-axis extent exceeds its own (a real overflow), or null if none does.
String? _firstFlexOverflow(RenderObject root) {
  String? found;
  void visit(RenderObject node) {
    if (found != null) return;
    if (node is RenderFlex && node.hasSize) {
      final bool horizontal = node.direction == Axis.horizontal;
      double childrenExtent = 0;
      node.visitChildren((RenderObject child) {
        if (child is RenderBox && child.hasSize) {
          childrenExtent += horizontal ? child.size.width : child.size.height;
        }
      });
      final double selfExtent =
          horizontal ? node.size.width : node.size.height;
      final double over = childrenExtent - selfExtent;
      if (over > 0.5) {
        found = 'a ${horizontal ? 'Row' : 'Column'} overflows by '
            '${over.toStringAsFixed(0)}px';
        return;
      }
    }
    node.visitChildren(visit);
  }

  visit(root);
  return found;
}
