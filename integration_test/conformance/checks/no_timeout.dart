// AC-8 no-timeout check rule (bs-11, A11Y-7).
//
// The per-rule check behind `ConformanceRuleId.noTimeout`: nothing on the
// screen may auto-dismiss or impose a time limit (WCAG 2.2 "Enough Time" / SI
// Accessibility). A screen-reader user must never be raced off a message before
// they have read it, so the SI's accessible notice (`AccessibleNotice`) never
// self-dismisses; the non-conformant pattern is a `SnackBar` (or any surface)
// shown on a finite `Duration` timer that removes itself unbidden.
//
// Detection is **by re-render**, not by catching a live surface at an arbitrary
// instant: a transient notice is raised through a post-frame callback and then
// removed by its own timer, so by the time a check runs the surface may already
// be gone (a reading taken after the auto-dismiss window would wrongly read as
// clean). The rule therefore re-renders the subject (marking it needs-build and
// pumping a bounded number of frames) so any notice raised on render is present
// during the check, then flags a `SnackBar` in the rendered tree: a `SnackBar`
// is inherently timed — its `duration` is a finite `Duration` that schedules
// its own removal — so its presence is the violation, whereas an
// `AccessibleNotice` (no timer) is not a `SnackBar` and is never flagged.
//
// Like `checkMeaningfulLabel`, the check is inherently tree-wide: a test
// isolates its subject by pumping only that subtree (the harness control
// fixtures do exactly this; a real-screen sweep checks the whole assembled
// app), so [screen] is accepted for signature parity and used as the re-render
// root. It lives under `integration_test/` (not `lib/`) because it drives a
// `WidgetTester`. The reusable aggregate `runConformanceCheck` composes it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Re-renders the subtree found by [screen] and returns the
/// [ConformanceRuleId.noTimeout] outcome: [ConformanceRuleOutcome.fail] (naming
/// the offending surface) when the render produces a timed `SnackBar`,
/// [ConformanceRuleOutcome.ok] otherwise.
Future<ConformanceRuleOutcome> checkNoTimeout(
  WidgetTester tester,
  Finder screen,
) async {
  // Re-render the subject so a notice raised via a post-frame callback is
  // present during the check, even if an earlier settle already let it
  // auto-dismiss. Bounded pumps (not `pumpAndSettle`) so a screen with a
  // steady-state animation cannot hang the check: one frame to run the
  // post-frame callback that raises the notice, one to admit it to the tree,
  // and a frame past the entrance animation so it has rendered.
  tester.element(screen).markNeedsBuild();
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  final Finder snackBars = find.byType(SnackBar);
  for (final Element element in snackBars.evaluate()) {
    final SnackBar snackBar = element.widget as SnackBar;
    return ConformanceRuleOutcome.fail(
      'a SnackBar auto-dismisses after ${snackBar.duration} — route transient '
      'surfaces through AccessibleNotice (no timer) so a screen-reader user is '
      'not raced off the message',
    );
  }
  return const ConformanceRuleOutcome.ok();
}
