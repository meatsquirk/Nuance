// AC-1 colour-cue + AC-2 no-bare-dot check rules (bs-11, A11Y-5).
//
// The per-rule checks behind `ConformanceRuleId.colourCue` (AC-1 — every
// colour-coded element carries a non-colour cue) and
// `ConformanceRuleId.noBareDot` (AC-2 — a status is never a bare colour dot).
// Both read the same structural fact of this app's colour vocabulary, so they
// share one traversal and return two independent [ConformanceRuleOutcome]s
// (each AC test asserts only its own id — G6).
//
// What the app encodes as "meaning in colour" is a **filled, circular colour
// dot/swatch**: `ColorChip` and `StatusBadge` draw exactly that (a
// `BoxDecoration` with `shape: BoxShape.circle` and a non-null `color`), and the
// non-compliant `control_bareDot` fixture is the same shape standing alone. A
// swatch is *compliant* when it carries a non-colour cue, which this app always
// supplies the same way: the swatch sits under a `Semantics(label: …,
// excludeSemantics: true)` node (the `ColorChip`/`StatusBadge` contract), so a
// screen reader announces the label and the colour is decorative. A swatch with
// **no** labelled `Semantics` ancestor within the checked subtree is a *bare*
// dot — colour is the only carrier — and fails.
//
// Scoped deliberately to the circular colour-dot idiom (not every coloured
// `Container`): rectangular surfaces, cards and coloured banners (e.g. the
// out-of-gamut banner, the neutral grayscale swatch) are not status dots and
// already pair their colour with text, so the rule neither flags them nor
// depends on them. Decorative rings with a border but **no fill** (the capture
// reticle) carry no colour meaning and are skipped (`color` is null).
//
// It lives under `integration_test/` (not `lib/`) because it walks a rendered
// element tree via a `WidgetTester`. The reusable aggregate `runConformanceCheck`
// composes both checks into a `ConformanceResult`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

/// Evaluates AC-1 over the subtree found by [screen]: every colour-coded
/// element must carry a non-colour cue. Fails naming the first bare colour dot.
Future<ConformanceRuleOutcome> checkColourCue(
  WidgetTester tester,
  Finder screen,
) async {
  final bare = _bareColourDots(tester, screen);
  return bare.isEmpty
      ? const ConformanceRuleOutcome.ok()
      : ConformanceRuleOutcome.fail(
          'a colour-coded element carries no non-colour cue: '
          '${_describe(bare.first)} — pair it with a label/icon '
          '(ColorChip/StatusBadge) or a labelled Semantics',
        );
}

/// Evaluates AC-2 over the subtree found by [screen]: no status is rendered as a
/// bare colour dot. Fails naming the first bare colour dot.
Future<ConformanceRuleOutcome> checkNoBareDot(
  WidgetTester tester,
  Finder screen,
) async {
  final bare = _bareColourDots(tester, screen);
  return bare.isEmpty
      ? const ConformanceRuleOutcome.ok()
      : ConformanceRuleOutcome.fail(
          'a status is drawn as a bare colour dot: ${_describe(bare.first)} — '
          'give it text/icon (StatusBadge) or a labelled Semantics',
        );
}

/// Every filled circular colour dot/swatch under [screen] that lacks a
/// non-colour cue (a labelled [Semantics] ancestor within the checked subtree).
List<Element> _bareColourDots(WidgetTester tester, Finder screen) {
  final Element root = tester.element(screen);
  final bare = <Element>[];
  void visit(Element element) {
    if (_isFilledColourDot(element.widget) && !_hasLabelledSemantics(element, root)) {
      bare.add(element);
    }
    element.visitChildren(visit);
  }

  // The found widget itself and its whole subtree.
  if (_isFilledColourDot(root.widget) && !_hasLabelledSemantics(root, root)) {
    bare.add(root);
  }
  root.visitChildren(visit);
  return bare;
}

/// Whether [widget] draws a filled circular colour dot/swatch — a
/// [BoxDecoration] with `shape: BoxShape.circle` and a non-null fill `color`.
/// A ring with only a border (no `color`) carries no colour meaning and is not
/// a dot.
bool _isFilledColourDot(Widget widget) {
  Decoration? decoration;
  if (widget is Container) {
    decoration = widget.decoration;
  } else if (widget is DecoratedBox) {
    decoration = widget.decoration;
  }
  if (decoration is! BoxDecoration) return false;
  return decoration.shape == BoxShape.circle && decoration.color != null;
}

/// Whether [element] sits under a [Semantics] with a non-empty label at or below
/// [root] — the `ColorChip`/`StatusBadge` "colour + label" contract. The walk is
/// bounded at [root] so the cue must come from within the checked subtree.
bool _hasLabelledSemantics(Element element, Element root) {
  var found = false;
  bool isLabelled(Element candidate) {
    final widget = candidate.widget;
    if (widget is Semantics) {
      final label = widget.properties.label;
      return label != null && label.isNotEmpty;
    }
    return false;
  }

  // The element may itself be the labelled node (unlikely for a dot, but cheap
  // and correct).
  if (isLabelled(element)) return true;
  element.visitAncestorElements((ancestor) {
    if (isLabelled(ancestor)) {
      found = true;
      return false;
    }
    // Stop once we reach the checked subtree's root — the cue must be inside it.
    return !identical(ancestor, root);
  });
  return found;
}

/// A short human-readable description of a bare-dot [element] for a failure
/// message — its key when it has one, else its widget type.
String _describe(Element element) {
  final key = element.widget.key;
  return key == null
      ? element.widget.runtimeType.toString()
      : '${element.widget.runtimeType} ($key)';
}
