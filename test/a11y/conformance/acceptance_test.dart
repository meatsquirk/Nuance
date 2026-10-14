import 'package:flutter_test/flutter_test.dart';
import 'package:paint_color_assistant/a11y/conformance/acceptance.dart';
import 'package:paint_color_assistant/a11y/conformance/conformance_result.dart';

void main() {
  group('AcceptanceDecision / WcagLevel enums', () {
    test('expose the expected values', () {
      expect(AcceptanceDecision.values, [
        AcceptanceDecision.accepted,
        AcceptanceDecision.notAccepted,
      ]);
      expect(WcagLevel.values, [WcagLevel.below, WcagLevel.aa22]);
    });
  });

  group('acceptanceDecision (GATE-3, AC-9)', () {
    // A fully-passing result: every rule id present and passing.
    final fullyPassing = ConformanceResult({
      for (final id in ConformanceRuleId.values)
        id: const ConformanceRuleOutcome.ok(),
    });

    test('accepts a fully-passing result', () {
      expect(fullyPassing.passed, isTrue);
      expect(acceptanceDecision(fullyPassing), AcceptanceDecision.accepted);
    });

    test('does not accept a result with a failing rule', () {
      final partial = ConformanceResult({
        for (final id in ConformanceRuleId.values)
          id: const ConformanceRuleOutcome.ok(),
        // One rule fails ⇒ the whole result is not accepted.
        ConformanceRuleId.tapTarget48:
            const ConformanceRuleOutcome.fail('24dp target'),
      });
      expect(partial.passed, isFalse);
      expect(acceptanceDecision(partial), AcceptanceDecision.notAccepted);
    });

    test('does not accept a partial result (not every rule ran)', () {
      // A result missing an id is not `passed`, so it is not accepted — the
      // gate never accepts an incomplete run.
      final incomplete = ConformanceResult({
        ConformanceRuleId.contrastAA: const ConformanceRuleOutcome.ok(),
      });
      expect(incomplete.passed, isFalse);
      expect(acceptanceDecision(incomplete), AcceptanceDecision.notAccepted);
    });

    test('does not accept the empty result', () {
      expect(
        acceptanceDecision(const ConformanceResult.empty()),
        AcceptanceDecision.notAccepted,
      );
    });
  });

  group('GATE-4 stub', () {
    // recordedLevel is implemented in GATE-4; until then it throws, so the
    // frozen signature compiles while AC-11 is still pending.
    test('recordedLevel throws UnimplementedError', () {
      expect(
        () => recordedLevel(const ConformanceResult.empty()),
        throwsUnimplementedError,
      );
    });
  });
}
