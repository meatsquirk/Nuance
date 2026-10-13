// The eyes-free semantics-only driver (bs-11, GATE-1 shell stub).
//
// `eyesFreeComplete` drives a core task using **only** the accessibility tree:
// it locates each control by its semantic label and activates it via a
// `SemanticsAction` — never by key, widget type or screen coordinate (D-6) —
// so a green run proves the task is completable by a screen-reader user. It
// lives under `integration_test/` because it drives a `WidgetTester`.
//
// GATE-1 lands the **stub only** (throws `UnimplementedError`); GATE-2 (AC-7)
// implements the walkthrough and asserts completion through the feature read
// endpoint, with a control (a required step whose control has no semantic
// label) that cannot progress.

import 'package:flutter_test/flutter_test.dart';

/// Advances a task to its terminal state by activating, in order, the control
/// carrying each semantic label in [steps] via its `SemanticsAction`, and
/// returns whether the terminal state was reached.
///
/// GATE-1 stub: throws [UnimplementedError] — implemented in GATE-2.
Future<bool> eyesFreeComplete(
  WidgetTester tester, {
  required List<String> steps,
}) async {
  throw UnimplementedError('eyesFreeComplete lands in GATE-2 (AC-7)');
}
