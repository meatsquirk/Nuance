/// The accessibility-conformance result model (bs-11, GATE-1 shell).
///
/// Pure domain — **no `flutter_test` / `flutter` import** — so it can live in
/// `lib/` and be read by production code and by any feature's acceptance gate
/// alike (D-3: the conformance check is a reusable artifact). The per-screen
/// *check* that populates a [ConformanceResult] from a rendered widget tree is
/// the test-support `runConformanceCheck` in
/// `integration_test/conformance/conformance_check.dart`; this file is only the
/// value types it produces and the two pure verdicts over it
/// ([acceptanceDecision] / [recordedLevel] live in `acceptance.dart`).
///
/// GATE-1 lands the **types only**: the enum, the per-rule outcome, and the
/// aggregate with its [ConformanceResult.passed] predicate. The rules
/// themselves are implemented per AC in the A11Y module (A11Y-2..7) and the two
/// GATE behaviour phases (GATE-2/3/4), which compose their outcomes into a
/// populated result through `runConformanceCheck`.
library;

/// The automated conformance rules bs-11 checks (plan interface; D-5 pins the
/// WCAG 2.2 AA thresholds behind them).
///
/// One id per automated AC rule. **AC-10 (manual eyes-free walkthrough) and
/// AC-12 (on-device VoiceOver-vs-TalkBack parity) are deliberately absent** —
/// they are pure-manual gates (D-2), performed and recorded by the reviewer at
/// SIGNOFF-1, never automated rules.
enum ConformanceRuleId {
  /// AC-1 — status is conveyed by more than hue alone (a colour cue is paired
  /// with an icon/label/shape).
  colourCue,

  /// AC-2 — no information is carried by a bare colour dot/swatch with no
  /// text or icon alternative.
  noBareDot,

  /// AC-3 — the layout survives 200% font scaling without clipping or loss of
  /// function.
  fontScale200,

  /// AC-4 — interactive targets meet the 48dp minimum.
  tapTarget48,

  /// AC-5 — text / essential graphics meet the AA contrast floor.
  contrastAA,

  /// AC-6 — every interactive control carries a meaningful semantic label.
  meaningfulLabel,

  /// AC-7 — a core task can be completed eyes-free (semantics + actions only).
  eyesFree,

  /// AC-8 — nothing auto-dismisses / imposes a time limit.
  noTimeout,
}

/// The outcome of a single [ConformanceRuleId] on one checked screen: whether
/// it [pass]ed, and a human-readable [detail] (the offending widget, the
/// measured value, or an all-clear note).
///
/// A value type with content equality so results compare by content, not
/// identity (mirrors [CvdProfile]'s discipline in `cvd/cvd_profile.dart`).
class ConformanceRuleOutcome {
  const ConformanceRuleOutcome({required this.pass, this.detail = ''});

  /// A passing outcome with no detail — the common all-clear case.
  const ConformanceRuleOutcome.ok() : pass = true, detail = '';

  /// A failing outcome; [detail] names what broke the rule.
  const ConformanceRuleOutcome.fail(this.detail) : pass = false;

  /// Whether the rule held on the checked screen.
  final bool pass;

  /// Why — the offending element or measured value on a failure, an optional
  /// note on a pass.
  final String detail;

  @override
  bool operator ==(Object other) =>
      other is ConformanceRuleOutcome &&
      other.pass == pass &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(pass, detail);

  @override
  String toString() =>
      'ConformanceRuleOutcome(${pass ? 'pass' : 'fail'}, "$detail")';
}

/// The aggregate result of running every automated rule over a screen: an
/// immutable map [ConformanceRuleId] → [ConformanceRuleOutcome].
///
/// [passed] is the gate predicate — **true iff every [ConformanceRuleId] has an
/// outcome and all of them passed**. Requiring completeness (not merely "every
/// outcome present passed") makes a partial or empty result read as *not*
/// conformant, which is the correct baseline: the GATE-1 stub
/// `runConformanceCheck` returns [ConformanceResult.empty], so an acceptance
/// test fails its Then until the real rules populate every id (GATE-3).
class ConformanceResult {
  /// Builds a result from rule outcomes. The map is copied and frozen so the
  /// result is immutable regardless of the caller's map.
  ConformanceResult(Map<ConformanceRuleId, ConformanceRuleOutcome> outcomes)
    : _outcomes = Map.unmodifiable(outcomes);

  /// The empty / all-absent result — no rule has run yet. [passed] is false
  /// (no id has an outcome). This is what the GATE-1 stub check returns.
  const ConformanceResult.empty() : _outcomes = const {};

  final Map<ConformanceRuleId, ConformanceRuleOutcome> _outcomes;

  /// The outcome recorded for [id], or null if the rule did not run.
  ConformanceRuleOutcome? outcomeFor(ConformanceRuleId id) => _outcomes[id];

  /// The rules that ran and failed (order follows [ConformanceRuleId.values]).
  Iterable<ConformanceRuleId> get failing => ConformanceRuleId.values.where(
    (id) => _outcomes[id]?.pass == false,
  );

  /// True iff every [ConformanceRuleId] has an outcome and all passed.
  bool get passed =>
      ConformanceRuleId.values.every((id) => _outcomes[id]?.pass ?? false);

  @override
  bool operator ==(Object other) {
    if (other is! ConformanceResult) return false;
    if (other._outcomes.length != _outcomes.length) return false;
    for (final id in _outcomes.keys) {
      if (other._outcomes[id] != _outcomes[id]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _outcomes.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'ConformanceResult($_outcomes)';
}
