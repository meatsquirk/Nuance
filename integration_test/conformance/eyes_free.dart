// The eyes-free semantics-only driver (bs-11, GATE-2 — AC-7).
//
// `eyesFreeComplete` drives a core task using **only** the accessibility tree:
// it locates each control by its semantic label and activates it via a
// `SemanticsAction` — never by key, widget type or screen coordinate (D-6) —
// so a green run proves the task is completable by a screen-reader user. It
// lives under `integration_test/` because it drives a `WidgetTester`, and is a
// reusable artifact any feature's eyes-free AC can import.
//
// GATE-1 landed the stub (threw `UnimplementedError`); GATE-2 implements the
// walkthrough: for each step it finds the control by label, confirms the
// screen reader can activate it (a `tap` action) and performs that action,
// returning whether every step was reachable and operated by semantics alone.

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// Advances a task to its terminal state by activating, in order, the control
/// carrying each semantic label in [steps] via its `SemanticsAction.tap`, and
/// returns whether the terminal state was reached.
///
/// The driver is strictly semantics-only (D-6): a step succeeds only if the
/// accessibility tree exposes a node with that label **and** that node reports
/// a `tap` action (so a screen-reader user could both land on it and activate
/// it). The action is dispatched through the semantics owner exactly as
/// assistive technology does — never a widget-type, key or coordinate tap.
///
/// Returns `true` once every step has been located and activated (the task
/// completed eyes-free), or `false` as soon as a step's label is absent from
/// the tree or its node is not activatable — the honest "a screen-reader user
/// cannot get past this step" signal. Semantics are enabled for the duration
/// and released afterwards so the driver works standalone and leaves no handle
/// behind.
Future<bool> eyesFreeComplete(
  WidgetTester tester, {
  required List<String> steps,
}) async {
  final SemanticsHandle handle = tester.ensureSemantics();
  try {
    for (final String label in steps) {
      // A screen-reader user can only land on a control the accessibility tree
      // exposes by label. No such node ⇒ the task cannot progress eyes-free,
      // and the driver must not fall back to coordinates or widget position
      // (D-6) — so it stops here.
      final Finder control = find.bySemanticsLabel(label);
      if (control.evaluate().isEmpty) {
        return false;
      }
      // Resolve the (possibly merged) semantics node behind that label.
      final SemanticsNode node = tester.semantics.find(control);
      // Operable eyes-free only if the screen reader can activate it: a
      // labelled-but-inert node (no tap action) is not a passable step.
      if (!node.getSemanticsData().hasAction(SemanticsAction.tap)) {
        return false;
      }
      // Activate through the SemanticsAction, exactly as a screen reader does.
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
    }
    // Every step was located and activated by semantics alone ⇒ the core task
    // reached its terminal state eyes-free.
    return true;
  } finally {
    handle.dispose();
  }
}
