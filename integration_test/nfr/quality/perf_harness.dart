// bs-12 performance harness (QUALITY-1 scaffold).
//
// test-support for the performance ACs (AC-3 a reading settles with a visible
// indicator; AC-4 a recipe search returns 3–5 ranked candidates). Performance
// is **hybrid** (plan bs-12 D-3): CI asserts the *mechanism* (an indicator
// appears and the reading reaches STABLE; the search returns 3–5 candidates)
// plus a **generous regression budget** — a wall-clock ceiling that catches
// pathological regressions on the simulator, explicitly **not** the
// target-hardware "~1–2s" figure (that, and the AC-5 live-preview frame rate,
// are owner on-device evidence recorded at SIGNOFF-1 under G-3).
//
// QUALITY-1 lays the timing signatures and the budget/candidate-count
// constants; [measure] times an async body under a `Stopwatch` and reports it
// against a budget, so ITEST-1's smoke test gets a populated probe. QUALITY-5
// drives a real commit / recipe search through `buildApp` under [measure] and
// asserts the mechanism + the budget.
//
// This is test-support only — no `lib/` product code (plan bs-12 D-7).

/// The generous CI ceiling for a reading to settle and commit (AC-3).
///
/// A *regression* budget — orders of magnitude above the target-hardware
/// ~1–2s — so it fails only on a pathological slowdown on the sim, never
/// standing in for the device figure (plan bs-12 D-3).
const Duration kCaptureSettleCiBudget = Duration(seconds: 10);

/// The generous CI ceiling for a recipe search to return candidates (AC-4).
/// See [kCaptureSettleCiBudget] — a regression ceiling, not the device figure.
const Duration kRecipeSearchCiBudget = Duration(seconds: 10);

/// The fewest ranked candidates a recipe search must return (AC-4).
const int kMinTopCandidates = 3;

/// The most ranked candidates a recipe search may return (AC-4).
const int kMaxTopCandidates = 5;

/// True when [count] is the 3–5 ranked candidates AC-4 requires.
bool isTopCandidateCount(int count) =>
    count >= kMinTopCandidates && count <= kMaxTopCandidates;

/// The outcome of one timed performance probe: how long [label] took against
/// its [budget].
class PerfProbe {
  const PerfProbe({
    required this.label,
    required this.elapsed,
    required this.budget,
  });

  /// What was timed (e.g. "capture-settle", "recipe-search").
  final String label;

  /// How long the timed body took.
  final Duration elapsed;

  /// The CI regression budget it was measured against.
  final Duration budget;

  /// Whether the body finished within its CI budget.
  bool get withinBudget => elapsed <= budget;

  @override
  String toString() => 'PerfProbe($label: ${elapsed.inMilliseconds}ms '
      '${withinBudget ? '≤' : '>'} ${budget.inMilliseconds}ms)';
}

/// Times async bodies under a `Stopwatch` and reports them against a CI budget.
///
/// Stateless. QUALITY-5 wraps a real commit / recipe search in [measure] and
/// asserts [PerfProbe.withinBudget]; QUALITY-1's smoke call passes an empty body
/// to prove the probe is populated.
class PerfHarness {
  const PerfHarness();

  /// Times [body] and returns a [PerfProbe] of its elapsed time vs [budget].
  Future<PerfProbe> measure(
    String label,
    Duration budget,
    Future<void> Function() body,
  ) async {
    final stopwatch = Stopwatch()..start();
    await body();
    stopwatch.stop();
    return PerfProbe(label: label, elapsed: stopwatch.elapsed, budget: budget);
  }
}
